package db

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/expomadeinworld/madeinworld/auth-service/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

// Database holds the database connection pool
type Database struct {
	Pool *pgxpool.Pool
}

// Config holds database configuration
type Config struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
}

// NewDatabase creates a new database connection
func NewDatabase() (*Database, error) {
	config := getConfigFromEnv()

	// Build connection string
	var connStr string
	if config.Password == "" {
		connStr = fmt.Sprintf(
			"host=%s port=%d user=%s dbname=%s sslmode=%s",
			config.Host,
			config.Port,
			config.User,
			config.DBName,
			config.SSLMode,
		)
	} else {
		connStr = fmt.Sprintf(
			"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
			config.Host,
			config.Port,
			config.User,
			config.Password,
			config.DBName,
			config.SSLMode,
		)
	}

	// Configure connection pool
	poolConfig, err := pgxpool.ParseConfig(connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	// Set pool settings
	poolConfig.MaxConns = 30
	poolConfig.MinConns = 5
	poolConfig.MaxConnLifetime = time.Hour
	poolConfig.MaxConnIdleTime = time.Minute * 30

	// Create connection pool
	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Test the connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("Auth service successfully connected to database")

	// Initialize database schema
	db := &Database{Pool: pool}
	if err := db.InitSchema(ctx); err != nil {
		return nil, fmt.Errorf("failed to initialize database schema: %w", err)
	}

	return db, nil
}

// Close closes the database connection pool
func (db *Database) Close() {
	if db.Pool != nil {
		db.Pool.Close()
		log.Println("Auth service database connection pool closed")
	}
}

// Health checks if the database is healthy
func (db *Database) Health(ctx context.Context) error {
	return db.Pool.Ping(ctx)
}

// InitSchema verifies the users table exists (it should already exist)
func (db *Database) InitSchema(ctx context.Context) error {
	// Check if users table exists with expected schema
	query := `
		SELECT column_name, data_type
		FROM information_schema.columns
		WHERE table_name = 'users' AND table_schema = 'public'
		ORDER BY ordinal_position;
	`

	rows, err := db.Pool.Query(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to check users table schema: %w", err)
	}
	defer rows.Close()

	var columns []string
	for rows.Next() {
		var columnName, dataType string
		if err := rows.Scan(&columnName, &dataType); err != nil {
			return fmt.Errorf("failed to scan column info: %w", err)
		}
		columns = append(columns, columnName)
	}

	if len(columns) == 0 {
		return fmt.Errorf("users table does not exist")
	}

	log.Printf("Found users table with columns: %v", columns)
	log.Println("Database schema verified successfully")
	return nil
}

// CreateUser creates a new user with hashed password
func (db *Database) CreateUser(ctx context.Context, req models.SignupRequest) (*models.User, error) {
	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Insert user into database
	var user models.User
	query := `
		INSERT INTO users (username, email, password_hash, phone, first_name, last_name)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, username, email, password_hash, phone, first_name, last_name, created_at, updated_at
	`

	err = db.Pool.QueryRow(ctx, query, req.Username, req.Email, string(hashedPassword), req.Phone, req.FirstName, req.LastName).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.Phone,
		&user.FirstName,
		&user.LastName,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// GetUserByEmail retrieves a user by email
func (db *Database) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	query := `
		SELECT id, username, email, password_hash, phone, first_name, last_name, created_at, updated_at
		FROM users
		WHERE email = $1
	`

	err := db.Pool.QueryRow(ctx, query, email).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.Phone,
		&user.FirstName,
		&user.LastName,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	return &user, nil
}

// ValidatePassword checks if the provided password matches the stored hash
func (db *Database) ValidatePassword(hashedPassword, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
}

// getConfigFromEnv reads database configuration from environment variables
func getConfigFromEnv() Config {
	config := Config{
		Host:     getEnv("DB_HOST", "localhost"),
		User:     getEnv("DB_USER", "madeinworld_admin"),
		Password: getEnv("DB_PASSWORD", ""),
		DBName:   getEnv("DB_NAME", "madeinworld_db"),
		SSLMode:  getEnv("DB_SSLMODE", "prefer"),
	}

	// Parse port
	portStr := getEnv("DB_PORT", "5432")
	port, err := strconv.Atoi(portStr)
	if err != nil {
		log.Printf("Invalid DB_PORT value: %s, using default 5432", portStr)
		port = 5432
	}
	config.Port = port

	return config
}

// getEnv gets an environment variable with a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

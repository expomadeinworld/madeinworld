package db

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
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

// NewDatabase creates a new database connection with retry logic for serverless databases
func NewDatabase() (*Database, error) {
	return NewDatabaseWithRetry(5, time.Second)
}

// NewDatabaseWithRetry creates a new database connection with configurable retry logic
func NewDatabaseWithRetry(maxRetries int, initialDelay time.Duration) (*Database, error) {
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
	poolConfig.MinConns = 0
	poolConfig.MaxConnLifetime = time.Hour
	poolConfig.MaxConnIdleTime = 5 * time.Minute
	// Prefer simple protocol to be Neon pooler friendly
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol

	origHost := poolConfig.ConnConfig.Host

	// Force IPv4 when available by resolving the host to an A record and dialing that IP directly.
	// Falls back to dual stack if no IPv4 is available. Preserve TLS SNI/ServerName with the original host.
	poolConfig.ConnConfig.DialFunc = func(ctx context.Context, network, address string) (net.Conn, error) {
		// address is typically "host:port". Resolve to prefer IPv4, otherwise fall back to first IP (likely IPv6).
		host, port, err := net.SplitHostPort(address)
		if err != nil || host == "" || port == "" {
			// Fallback to original host if split fails
			host = origHost
			port = "5432"
		}

		// Lookup all IPs and prefer IPv4
		ips, err := net.DefaultResolver.LookupIPAddr(ctx, host)
		if err == nil {
			for _, ipa := range ips {
				if ipv4 := ipa.IP.To4(); ipv4 != nil {
					return (&net.Dialer{}).DialContext(ctx, "tcp4", net.JoinHostPort(ipv4.String(), port))
				}
			}
			// No IPv4 found: try first IP (likely IPv6) with tcp
			if len(ips) > 0 {
				return (&net.Dialer{}).DialContext(ctx, "tcp", net.JoinHostPort(ips[0].IP.String(), port))
			}
		}
		// DNS lookup failed: fall back to provided address with tcp4 to keep behavior
		return (&net.Dialer{}).DialContext(ctx, "tcp4", address)
	}
	if poolConfig.ConnConfig.TLSConfig != nil && poolConfig.ConnConfig.TLSConfig.ServerName == "" {
		poolConfig.ConnConfig.TLSConfig.ServerName = origHost
	}

	// Attempt to connect with retry logic for serverless databases (e.g., Neon cold start)
	var pool *pgxpool.Pool
	var lastErr error

	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("[ORDER-DB] Connection attempt %d/%d to database %s@%s:%d",
			attempt, maxRetries, config.User, config.Host, config.Port)

		// Create connection pool
		pool, err = pgxpool.NewWithConfig(context.Background(), poolConfig)
		if err != nil {
			lastErr = fmt.Errorf("failed to create connection pool: %w", err)
			log.Printf("[ORDER-DB] Failed to create pool (attempt %d): %v", attempt, err)
			if attempt < maxRetries {
				delay := time.Duration(attempt-1) * initialDelay
				log.Printf("[ORDER-DB] Retrying in %v...", delay)
				time.Sleep(delay)
			}
			continue
		}

		// Test the connection with timeout
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err = pool.Ping(ctx)
		cancel()

		if err == nil {
			log.Printf("[ORDER-DB] Successfully connected to database on attempt %d", attempt)
			break
		}

		// Connection failed, clean up pool and retry
		lastErr = fmt.Errorf("failed to ping database: %w", err)
		log.Printf("[ORDER-DB] Connection failed (attempt %d): %v", attempt, err)
		pool.Close()
		pool = nil

		if attempt < maxRetries {
			// Exponential backoff: 1s, 2s, 4s, 8s, 16s
			delay := initialDelay * time.Duration(1<<(attempt-1))
			log.Printf("[ORDER-DB] Retrying in %v...", delay)
			time.Sleep(delay)
		}
	}

	if pool == nil {
		return nil, fmt.Errorf("failed to connect to database after %d attempts: %w", maxRetries, lastErr)
	}

	// Initialize database schema with retry-aware context
	db := &Database{Pool: pool}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := db.InitSchema(ctx); err != nil {
		log.Printf("[ORDER-DB] Warning: Failed to initialize database schema: %v", err)
		// Don't fail here - schema might be initialized later
	}

	log.Println("[ORDER-DB] Database connection established successfully")
	return db, nil
}

// Close closes the database connection pool
func (db *Database) Close() {
	if db.Pool != nil {
		db.Pool.Close()
		log.Println("Order service database connection pool closed")
	}
}

// Health checks if the database is healthy
func (db *Database) Health(ctx context.Context) error {
	return db.Pool.Ping(ctx)
}

// InitSchema verifies the required tables exist
func (db *Database) InitSchema(ctx context.Context) error {
	// Check if required tables exist
	requiredTables := []string{"carts", "orders", "order_items", "products", "users"}

	for _, tableName := range requiredTables {
		query := `
			SELECT EXISTS (
				SELECT FROM information_schema.tables 
				WHERE table_schema = 'public' 
				AND table_name = $1
			);
		`

		var exists bool
		err := db.Pool.QueryRow(ctx, query, tableName).Scan(&exists)
		if err != nil {
			return fmt.Errorf("failed to check table %s: %w", tableName, err)
		}

		if !exists {
			return fmt.Errorf("required table %s does not exist", tableName)
		}
	}

	log.Println("Order service database schema verified successfully")
	return nil
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

//go:build ignore
// +build ignore

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Config struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
}

func main() {
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

	// Create connection pool
	pool, err := pgxpool.New(context.Background(), connStr)
	if err != nil {
		log.Fatalf("Failed to create connection pool: %v", err)
	}
	defer pool.Close()

	ctx := context.Background()

	// Test connection
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("Connected to database successfully!")

	// Check cart table structure
	fmt.Println("\n=== Cart Table Structure ===")
	structureQuery := `
		SELECT column_name, data_type, is_nullable, column_default
		FROM information_schema.columns
		WHERE table_name = 'carts'
		ORDER BY ordinal_position;
	`

	rows, err := pool.Query(ctx, structureQuery)
	if err != nil {
		log.Fatalf("Failed to query cart table structure: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var columnName, dataType, isNullable string
		var columnDefault *string
		err := rows.Scan(&columnName, &dataType, &isNullable, &columnDefault)
		if err != nil {
			log.Fatalf("Failed to scan row: %v", err)
		}

		defaultVal := "NULL"
		if columnDefault != nil {
			defaultVal = *columnDefault
		}

		fmt.Printf("Column: %s, Type: %s, Nullable: %s, Default: %s\n",
			columnName, dataType, isNullable, defaultVal)
	}

	// Find user Sole
	fmt.Println("\n=== Finding User Sole ===")
	userQuery := `
		SELECT id, email, username, first_name, last_name
		FROM users
		WHERE email = 'solesong2003@gmail.com' OR email ILIKE '%sole%'
		LIMIT 5;
	`

	userRows, err := pool.Query(ctx, userQuery)
	if err != nil {
		log.Fatalf("Failed to query users: %v", err)
	}
	defer userRows.Close()

	var userID string
	for userRows.Next() {
		var id, email string
		var username, firstName, lastName *string
		err := userRows.Scan(&id, &email, &username, &firstName, &lastName)
		if err != nil {
			log.Fatalf("Failed to scan user row: %v", err)
		}

		fmt.Printf("User ID: %s, Email: %s, Username: %v, Name: %v %v\n",
			id, email, username, firstName, lastName)

		if email == "solesong2003@gmail.com" {
			userID = id
		}
	}

	var cartQuery string
	if userID == "" {
		fmt.Println("User Sole not found, checking all cart data...")

		// Check all cart data
		fmt.Println("\n=== All Cart Data (first 10 rows) ===")
		cartQuery = `
			SELECT c.*, u.email
			FROM carts c
			LEFT JOIN users u ON c.user_id = u.id
			LIMIT 10;
		`
	} else {
		fmt.Printf("\n=== Cart Data for User Sole (ID: %s) ===\n", userID)
		cartQuery = fmt.Sprintf(`
			SELECT c.*, u.email, p.title as product_title
			FROM carts c
			LEFT JOIN users u ON c.user_id = u.id
			LEFT JOIN products p ON c.product_id = p.product_uuid
			WHERE c.user_id = '%s';
		`, userID)
	}

	cartRows, err := pool.Query(ctx, cartQuery)
	if err != nil {
		log.Fatalf("Failed to query cart data: %v", err)
	}
	defer cartRows.Close()

	fmt.Println("Cart data:")
	for cartRows.Next() {
		// Get column descriptions
		fieldDescriptions := cartRows.FieldDescriptions()
		values := make([]interface{}, len(fieldDescriptions))
		valuePtrs := make([]interface{}, len(fieldDescriptions))

		for i := range values {
			valuePtrs[i] = &values[i]
		}

		err := cartRows.Scan(valuePtrs...)
		if err != nil {
			log.Fatalf("Failed to scan cart row: %v", err)
		}

		fmt.Print("Row: ")
		for i, field := range fieldDescriptions {
			fmt.Printf("%s=%v ", field.Name, values[i])
		}
		fmt.Println()
	}
}

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

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

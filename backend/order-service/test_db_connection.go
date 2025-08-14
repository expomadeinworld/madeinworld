//go:build ignore
// +build ignore

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Get database configuration
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "madeinworld_admin")
	password := getEnv("DB_PASSWORD", "madeinworld_password_2024")
	dbname := getEnv("DB_NAME", "madeinworld_db")
	sslmode := getEnv("DB_SSLMODE", "prefer")

	fmt.Printf("Testing database connection with:\n")
	fmt.Printf("  Host: %s\n", host)
	fmt.Printf("  Port: %s\n", port)
	fmt.Printf("  User: %s\n", user)
	fmt.Printf("  Database: %s\n", dbname)
	fmt.Printf("  SSL Mode: %s\n", sslmode)
	fmt.Printf("  Password: %s\n", maskPassword(password))
	fmt.Println()

	// Build connection string
	var connStr string
	if password == "" {
		connStr = fmt.Sprintf(
			"host=%s port=%s user=%s dbname=%s sslmode=%s",
			host, port, user, dbname, sslmode,
		)
	} else {
		connStr = fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
			host, port, user, password, dbname, sslmode,
		)
	}

	fmt.Printf("Connection string: %s\n\n", maskConnectionString(connStr))

	// Test connection
	fmt.Println("Attempting to connect...")

	poolConfig, err := pgxpool.ParseConfig(connStr)
	if err != nil {
		log.Fatalf("Failed to parse database config: %v", err)
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		log.Fatalf("Failed to create connection pool: %v", err)
	}
	defer pool.Close()

	// Test ping
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("✅ Database connection successful!")

	// Test required tables
	fmt.Println("\nChecking required tables...")
	requiredTables := []string{"users", "products", "carts", "orders", "cart_items", "order_items"}

	for _, table := range requiredTables {
		var exists bool
		query := `
			SELECT EXISTS (
				SELECT FROM information_schema.tables
				WHERE table_schema = 'public'
				AND table_name = $1
			);
		`

		err := pool.QueryRow(ctx, query, table).Scan(&exists)
		if err != nil {
			fmt.Printf("❌ Error checking table %s: %v\n", table, err)
		} else if exists {
			fmt.Printf("✅ Table %s exists\n", table)
		} else {
			fmt.Printf("❌ Table %s does not exist\n", table)
		}
	}

	// Check if carts table has mini_app_type column
	fmt.Println("\nChecking cart table schema...")
	var hasColumn bool
	columnQuery := `
		SELECT EXISTS (
			SELECT FROM information_schema.columns
			WHERE table_schema = 'public'
			AND table_name = 'carts'
			AND column_name = 'mini_app_type'
		);
	`

	err = pool.QueryRow(ctx, columnQuery).Scan(&hasColumn)
	if err != nil {
		fmt.Printf("❌ Error checking mini_app_type column: %v\n", err)
	} else if hasColumn {
		fmt.Printf("✅ carts table has mini_app_type column\n")
	} else {
		fmt.Printf("❌ carts table missing mini_app_type column - migration needed\n")
	}

	fmt.Println("\n🎉 Database connection test completed!")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func maskPassword(password string) string {
	if password == "" {
		return "(empty)"
	}
	if len(password) <= 4 {
		return "****"
	}
	return password[:2] + "****" + password[len(password)-2:]
}

func maskConnectionString(connStr string) string {
	// Simple masking for password in connection string
	if !contains(connStr, "password=") {
		return connStr
	}

	// Find password part and mask it
	parts := []string{}
	for _, part := range splitString(connStr, " ") {
		if startsWith(part, "password=") {
			parts = append(parts, "password=****")
		} else {
			parts = append(parts, part)
		}
	}
	return joinString(parts, " ")
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[len(s)-len(substr):] == substr ||
		len(s) > len(substr) && findSubstring(s, substr) >= 0
}

func findSubstring(s, substr string) int {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}

func startsWith(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}

func splitString(s, sep string) []string {
	if s == "" {
		return []string{}
	}

	var result []string
	start := 0

	for i := 0; i <= len(s)-len(sep); i++ {
		if s[i:i+len(sep)] == sep {
			result = append(result, s[start:i])
			start = i + len(sep)
			i += len(sep) - 1
		}
	}
	result = append(result, s[start:])
	return result
}

func joinString(parts []string, sep string) string {
	if len(parts) == 0 {
		return ""
	}
	if len(parts) == 1 {
		return parts[0]
	}

	result := parts[0]
	for i := 1; i < len(parts); i++ {
		result += sep + parts[i]
	}
	return result
}

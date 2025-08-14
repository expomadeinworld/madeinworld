package db

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net"
	"os"
	"time"

	"github.com/lib/pq"
)

// Force IPv4 dialing for lib/pq connections via a custom Dialer
// This preserves the DNS hostname in config while ensuring tcp4 is used
type ipv4Dialer struct{}

func (ipv4Dialer) Dial(network, address string) (net.Conn, error) {
	return (&net.Dialer{}).Dial("tcp4", address)
}

func (ipv4Dialer) DialTimeout(network, address string, timeout time.Duration) (net.Conn, error) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	return (&net.Dialer{}).DialContext(ctx, "tcp4", address)
}

// Database represents the database connection
type Database struct {
	DB *sql.DB
}

// NewDatabase creates a new database connection
func NewDatabase() (*Database, error) {
	// Get database configuration from environment variables
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "localhost"
	}

	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}

	user := os.Getenv("DB_USER")
	if user == "" {
		user = "madeinworld_admin"
	}

	password := os.Getenv("DB_PASSWORD")
	// Password can be empty for local development

	dbname := os.Getenv("DB_NAME")
	if dbname == "" {
		dbname = "madeinworld_db"
	}

	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable"
	}

	// Create connection string
	var connStr string
	if password == "" {
		connStr = fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s",
			host, port, user, dbname, sslmode)
	} else {
		connStr = fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
			host, port, user, password, dbname, sslmode)
	}

	// Open database connection
	connector, err := pq.NewConnector(connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to build pq connector: %w", err)
	}
	connector.Dialer(ipv4Dialer{})
	db := sql.OpenDB(connector)

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	log.Printf("Successfully connected to database: %s@%s:%s/%s", user, host, port, dbname)

	return &Database{DB: db}, nil
}

// Close closes the database connection
func (d *Database) Close() error {
	if d.DB != nil {
		return d.DB.Close()
	}
	return nil
}

// Health checks if the database connection is healthy
func (d *Database) Health() error {
	return d.DB.Ping()
}

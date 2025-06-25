package db

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/expomadeinworld/madeinworld/catalog-service/internal/models"
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

// NewDatabase creates a new database connection
func NewDatabase() (*Database, error) {
	config := getConfigFromEnv()

	// Build connection string
	connStr := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host,
		config.Port,
		config.User,
		config.Password,
		config.DBName,
		config.SSLMode,
	)

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

	log.Println("Successfully connected to database")

	return &Database{Pool: pool}, nil
}

// Close closes the database connection pool
func (db *Database) Close() {
	if db.Pool != nil {
		db.Pool.Close()
		log.Println("Database connection pool closed")
	}
}

// Health checks if the database is healthy
func (db *Database) Health(ctx context.Context) error {
	return db.Pool.Ping(ctx)
}

// =================================================================================
// NEW FUNCTIONS FOR WRITING DATA
// =================================================================================

// CreateProduct inserts a new product into the database and returns its ID.
// This function assumes your `products` table has an auto-incrementing `product_id`.
func (db *Database) CreateProduct(ctx context.Context, product models.Product) (int, error) {
	var productID int
	query := `
        INSERT INTO products 
            (sku, title, description_short, description_long, manufacturer_id, store_type, main_price, strikethrough_price, is_active, is_featured) 
        VALUES 
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
        RETURNING product_id
    `
	err := db.Pool.QueryRow(ctx, query,
		product.SKU,
		product.Title,
		product.DescriptionShort,
		product.DescriptionLong,
		product.ManufacturerID,
		product.StoreType,
		product.MainPrice,
		product.StrikethroughPrice,
		product.IsActive,
		product.IsFeatured,
	).Scan(&productID)

	if err != nil {
		return 0, fmt.Errorf("failed to insert product: %w", err)
	}

	return productID, nil
}

// AddImageURLToProduct links an S3 image URL to a product in the product_images table.
func (db *Database) AddImageURLToProduct(ctx context.Context, productID int, imageURL string) error {
	query := `
        INSERT INTO product_images (product_id, image_url, display_order)
        VALUES ($1, $2, (
            SELECT COALESCE(MAX(display_order), 0) + 1 
            FROM product_images 
            WHERE product_id = $1
        ))
    `
	_, err := db.Pool.Exec(ctx, query, productID, imageURL)

	if err != nil {
		return fmt.Errorf("failed to insert product image: %w", err)
	}
	return nil
}

// ReplaceProductImage replaces the primary image for a product (deletes existing, adds new)
func (db *Database) ReplaceProductImage(ctx context.Context, productID int, imageURL string) error {
	// Start a transaction to ensure atomicity
	tx, err := db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Delete existing images for this product
	_, err = tx.Exec(ctx, "DELETE FROM product_images WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to delete existing images: %w", err)
	}

	// Insert the new image as the primary image (display_order = 1)
	_, err = tx.Exec(ctx,
		"INSERT INTO product_images (product_id, image_url, display_order) VALUES ($1, $2, 1)",
		productID, imageURL)
	if err != nil {
		return fmt.Errorf("failed to insert new image: %w", err)
	}

	// Commit the transaction
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// UpdateProduct updates an existing product in the database
func (db *Database) UpdateProduct(ctx context.Context, productID int, product models.Product) error {
	query := `
        UPDATE products
        SET
            sku = $2,
            title = $3,
            description_short = $4,
            description_long = $5,
            manufacturer_id = $6,
            store_type = $7,
            main_price = $8,
            strikethrough_price = $9,
            is_active = $10,
            is_featured = $11,
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = $1
    `
	result, err := db.Pool.Exec(ctx, query,
		productID,
		product.SKU,
		product.Title,
		product.DescriptionShort,
		product.DescriptionLong,
		product.ManufacturerID,
		product.StoreType,
		product.MainPrice,
		product.StrikethroughPrice,
		product.IsActive,
		product.IsFeatured,
	)

	if err != nil {
		return fmt.Errorf("failed to update product: %w", err)
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("product with ID %d not found", productID)
	}

	return nil
}

// DeleteProduct soft deletes a product by setting is_active to false
func (db *Database) DeleteProduct(ctx context.Context, productID int) error {
	query := `
        UPDATE products
        SET
            is_active = false,
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = $1 AND is_active = true
    `
	result, err := db.Pool.Exec(ctx, query, productID)

	if err != nil {
		return fmt.Errorf("failed to delete product: %w", err)
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("product with ID %d not found or already deleted", productID)
	}

	return nil
}

// HardDeleteProduct permanently removes a product from the database
// Use with caution - this is irreversible
func (db *Database) HardDeleteProduct(ctx context.Context, productID int) error {
	// Start a transaction to ensure data consistency
	tx, err := db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Delete product images first (foreign key constraint)
	_, err = tx.Exec(ctx, "DELETE FROM product_images WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to delete product images: %w", err)
	}

	// Delete product category mappings
	_, err = tx.Exec(ctx, "DELETE FROM product_category_mapping WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to delete product category mappings: %w", err)
	}

	// Delete inventory records
	_, err = tx.Exec(ctx, "DELETE FROM inventory WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to delete inventory records: %w", err)
	}

	// Finally delete the product
	result, err := tx.Exec(ctx, "DELETE FROM products WHERE product_id = $1", productID)
	if err != nil {
		return fmt.Errorf("failed to delete product: %w", err)
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		return fmt.Errorf("product with ID %d not found", productID)
	}

	// Commit the transaction
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// =================================================================================
// HELPER FUNCTIONS FOR CONFIG
// =================================================================================

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

	// Validate required fields
	if config.Password == "" {
		log.Fatal("DB_PASSWORD environment variable is required")
	}

	return config
}

// getEnv gets an environment variable with a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

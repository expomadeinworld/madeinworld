package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/expomadeinworld/madeinworld/catalog-service/internal/db"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Initialize database connection
	database, err := db.NewDatabase()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// First, check current store types
	fmt.Println("=== Current Store Types ===")
	rows, err := database.Pool.Query(ctx, "SELECT store_id, name, type FROM stores ORDER BY store_id")
	if err != nil {
		log.Fatalf("Failed to query stores: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var storeID int
		var name, storeType string
		if err := rows.Scan(&storeID, &name, &storeType); err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}
		fmt.Printf("Store %d: %s - Type: %s\n", storeID, name, storeType)
	}

	// Update store types from English to Chinese values
	fmt.Println("\n=== Updating Store Types ===")
	updateQuery := `
		UPDATE stores
		SET type = CASE
			WHEN type = 'Unmanned' THEN '无人商店'
			WHEN type = '无人门店' THEN '无人商店'  -- Update old naming
			WHEN type = 'Retail' THEN '展销商店'
			WHEN type = 'Warehouse' THEN '无人仓店'
			WHEN type = 'Exhibition' THEN '展销商城'
			ELSE type  -- Keep existing value if already correct
		END
		WHERE type IN ('Unmanned', 'Retail', 'Warehouse', 'Exhibition', '无人门店')
	`

	result, err := database.Pool.Exec(ctx, updateQuery)
	if err != nil {
		log.Fatalf("Failed to update stores: %v", err)
	}

	rowsAffected := result.RowsAffected()
	fmt.Printf("Updated %d store records\n", rowsAffected)

	// Also update products table to match
	fmt.Println("\n=== Updating Product Store Types ===")
	productUpdateQuery := `
		UPDATE products
		SET store_type = CASE
			WHEN store_type = 'Unmanned' THEN '无人商店'
			WHEN store_type = '无人门店' THEN '无人商店'  -- Update old naming
			WHEN store_type = 'Retail' THEN '展销商店'
			WHEN store_type = 'Warehouse' THEN '无人仓店'
			WHEN store_type = 'Exhibition' THEN '展销商城'
			ELSE store_type  -- Keep existing value if already correct
		END
		WHERE store_type IN ('Unmanned', 'Retail', 'Warehouse', 'Exhibition', '无人门店')
	`

	productResult, err := database.Pool.Exec(ctx, productUpdateQuery)
	if err != nil {
		log.Fatalf("Failed to update products: %v", err)
	}

	productRowsAffected := productResult.RowsAffected()
	fmt.Printf("Updated %d product records\n", productRowsAffected)

	// Verify the changes
	fmt.Println("\n=== Updated Store Types ===")
	rows2, err := database.Pool.Query(ctx, "SELECT store_id, name, type FROM stores ORDER BY store_id")
	if err != nil {
		log.Fatalf("Failed to query stores: %v", err)
	}
	defer rows2.Close()

	for rows2.Next() {
		var storeID int
		var name, storeType string
		if err := rows2.Scan(&storeID, &name, &storeType); err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}
		fmt.Printf("Store %d: %s - Type: %s\n", storeID, name, storeType)
	}

	// Verify products
	fmt.Println("\n=== Updated Product Store Types ===")
	rows3, err := database.Pool.Query(ctx, "SELECT product_id, title, store_type FROM products ORDER BY product_id")
	if err != nil {
		log.Fatalf("Failed to query products: %v", err)
	}
	defer rows3.Close()

	for rows3.Next() {
		var productID int
		var title, storeType string
		if err := rows3.Scan(&productID, &title, &storeType); err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}
		fmt.Printf("Product %d: %s - Store Type: %s\n", productID, title, storeType)
	}

	fmt.Println("\n=== Store Type Fix Complete ===")
}

package api

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings" // IMPORT THIS PACKAGE
	"time"

	"github.com/expomadeinworld/madeinworld/catalog-service/internal/db"
	"github.com/expomadeinworld/madeinworld/catalog-service/internal/models"
	"github.com/gin-gonic/gin"
)

// Handler holds the database connection and provides HTTP handlers
type Handler struct {
	db *db.Database
}

// NewHandler creates a new handler instance
func NewHandler(database *db.Database) *Handler {
	return &Handler{db: database}
}

// GetProducts handles GET /products
func (h *Handler) GetProducts(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Parse query parameters
	storeType := c.Query("store_type")
	featured := c.Query("featured")
	storeID := c.Query("store_id")

	// Build the query
	query := `
		SELECT 
			p.product_id, p.sku, p.title, p.description_short, p.description_long,
			p.manufacturer_id, p.store_type, p.main_price, p.strikethrough_price,
			p.is_active, p.is_featured, p.created_at, p.updated_at
		FROM products p
		WHERE p.is_active = true
	`

	args := []interface{}{}
	argIndex := 1

	// Add store type filter
	if storeType != "" {
		query += fmt.Sprintf(" AND p.store_type = $%d", argIndex)
		// FIX: Capitalize the input to match the PostgreSQL ENUM
		args = append(args, strings.Title(storeType))
		argIndex++
	}

	// Add featured filter
	if featured == "true" {
		query += fmt.Sprintf(" AND p.is_featured = $%d", argIndex)
		args = append(args, true)
		argIndex++
	}

	query += " ORDER BY p.product_id"

	// Execute query
	rows, err := h.db.Pool.Query(ctx, query, args...)
	if err != nil {
		log.Printf("Error querying products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}
	defer rows.Close()

	var products []models.Product

	for rows.Next() {
		var product models.Product
		err := rows.Scan(
			&product.ID,
			&product.SKU,
			&product.Title,
			&product.DescriptionShort,
			&product.DescriptionLong,
			&product.ManufacturerID,
			&product.StoreType,
			&product.MainPrice,
			&product.StrikethroughPrice,
			&product.IsActive,
			&product.IsFeatured,
			&product.CreatedAt,
			&product.UpdatedAt,
		)
		if err != nil {
			log.Printf("Error scanning product: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan product"})
			return
		}

		// Get product images
		images, err := h.getProductImages(ctx, product.ID)
		if err != nil {
			log.Printf("Error getting product images for product %d: %v", product.ID, err)
			// Continue without images rather than failing
			product.ImageUrls = []string{}
		} else {
			product.ImageUrls = images
		}

		// Get product categories
		categories, err := h.getProductCategories(ctx, product.ID)
		if err != nil {
			log.Printf("Error getting product categories for product %d: %v", product.ID, err)
			// Continue without categories rather than failing
			product.CategoryIds = []string{}
		} else {
			product.CategoryIds = categories
		}

		// Get stock quantity for unmanned stores
		if product.StoreType == models.StoreTypeUnmanned {
			stockQuantity, err := h.getProductStock(ctx, product.ID, storeID)
			if err != nil {
				log.Printf("Error getting stock for product %d: %v", product.ID, err)
				// Continue without stock info rather than failing
			} else {
				product.StockQuantity = stockQuantity
			}
		}

		products = append(products, product)
	}

	if err := rows.Err(); err != nil {
		log.Printf("Error iterating products: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process products"})
		return
	}

	c.JSON(http.StatusOK, products)
}

// GetProduct handles GET /products/:id
func (h *Handler) GetProduct(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	idStr := c.Param("id")
	productID, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	query := `
		SELECT 
			p.product_id, p.sku, p.title, p.description_short, p.description_long,
			p.manufacturer_id, p.store_type, p.main_price, p.strikethrough_price,
			p.is_active, p.is_featured, p.created_at, p.updated_at
		FROM products p
		WHERE p.product_id = $1 AND p.is_active = true
	`

	var product models.Product
	err = h.db.Pool.QueryRow(ctx, query, productID).Scan(
		&product.ID,
		&product.SKU,
		&product.Title,
		&product.DescriptionShort,
		&product.DescriptionLong,
		&product.ManufacturerID,
		&product.StoreType,
		&product.MainPrice,
		&product.StrikethroughPrice,
		&product.IsActive,
		&product.IsFeatured,
		&product.CreatedAt,
		&product.UpdatedAt,
	)

	if err != nil {
		log.Printf("Error querying product %d: %v", productID, err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	// Get product images
	images, err := h.getProductImages(ctx, product.ID)
	if err != nil {
		log.Printf("Error getting product images for product %d: %v", product.ID, err)
		product.ImageUrls = []string{}
	} else {
		product.ImageUrls = images
	}

	// Get product categories
	categories, err := h.getProductCategories(ctx, product.ID)
	if err != nil {
		log.Printf("Error getting product categories for product %d: %v", product.ID, err)
		product.CategoryIds = []string{}
	} else {
		product.CategoryIds = categories
	}

	// Get stock quantity for unmanned stores
	if product.StoreType == models.StoreTypeUnmanned {
		storeID := c.Query("store_id")
		stockQuantity, err := h.getProductStock(ctx, product.ID, storeID)
		if err != nil {
			log.Printf("Error getting stock for product %d: %v", product.ID, err)
		} else {
			product.StockQuantity = stockQuantity
		}
	}

	c.JSON(http.StatusOK, product)
}

// GetCategories handles GET /categories
func (h *Handler) GetCategories(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	storeType := c.Query("store_type")

	query := `
		SELECT category_id, name, store_type_association, created_at, updated_at
		FROM product_categories
	`

	args := []interface{}{}
	if storeType != "" {
		query += " WHERE store_type_association = $1 OR store_type_association = 'All'"
		// FIX: Capitalize the input to match the PostgreSQL ENUM
		args = append(args, strings.Title(storeType))
	}

	query += " ORDER BY category_id"

	rows, err := h.db.Pool.Query(ctx, query, args...)
	if err != nil {
		log.Printf("Error querying categories: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}
	defer rows.Close()

	var categories []models.Category

	for rows.Next() {
		var category models.Category
		err := rows.Scan(
			&category.ID,
			&category.Name,
			&category.StoreTypeAssociation,
			&category.CreatedAt,
			&category.UpdatedAt,
		)
		if err != nil {
			log.Printf("Error scanning category: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan category"})
			return
		}

		categories = append(categories, category)
	}

	c.JSON(http.StatusOK, categories)
}

// GetStores handles GET /stores
func (h *Handler) GetStores(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	storeType := c.Query("type")

	query := `
		SELECT store_id, name, city, address, latitude, longitude, type, is_active, created_at, updated_at
		FROM stores
		WHERE is_active = true
	`

	args := []interface{}{}
	if storeType != "" {
		query += " AND type = $1"
		// FIX: Capitalize the input to match the PostgreSQL ENUM
		args = append(args, strings.Title(storeType))
	}

	query += " ORDER BY store_id"

	rows, err := h.db.Pool.Query(ctx, query, args...)
	if err != nil {
		log.Printf("Error querying stores: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stores"})
		return
	}
	defer rows.Close()

	var stores []models.Store

	for rows.Next() {
		var store models.Store
		err := rows.Scan(
			&store.ID,
			&store.Name,
			&store.City,
			&store.Address,
			&store.Latitude,
			&store.Longitude,
			&store.Type,
			&store.IsActive,
			&store.CreatedAt,
			&store.UpdatedAt,
		)
		if err != nil {
			log.Printf("Error scanning store: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan store"})
			return
		}

		stores = append(stores, store)
	}

	c.JSON(http.StatusOK, stores)
}

// Health handles GET /health
func (h *Handler) Health(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := h.db.Health(ctx); err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"status": "unhealthy",
			"error":  "Database connection failed",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().UTC(),
		"service":   "catalog-service",
	})
}

// Helper functions

func (h *Handler) getProductImages(ctx context.Context, productID int) ([]string, error) {
	query := `
		SELECT image_url 
		FROM product_images 
		WHERE product_id = $1 
		ORDER BY display_order
	`

	rows, err := h.db.Pool.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var images []string
	for rows.Next() {
		var imageURL string
		if err := rows.Scan(&imageURL); err != nil {
			return nil, err
		}
		images = append(images, imageURL)
	}

	return images, rows.Err()
}

func (h *Handler) getProductCategories(ctx context.Context, productID int) ([]string, error) {
	query := `
		SELECT CAST(pcm.category_id AS TEXT)
		FROM product_category_mapping pcm
		WHERE pcm.product_id = $1
		ORDER BY pcm.category_id
	`

	rows, err := h.db.Pool.Query(ctx, query, productID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []string
	for rows.Next() {
		var categoryID string
		if err := rows.Scan(&categoryID); err != nil {
			return nil, err
		}
		categories = append(categories, categoryID)
	}

	return categories, rows.Err()
}

func (h *Handler) getProductStock(ctx context.Context, productID int, storeID string) (*int, error) {
	// If no store ID specified, get stock from first available store
	query := `
		SELECT quantity 
		FROM inventory 
		WHERE product_id = $1
	`

	args := []interface{}{productID}

	if storeID != "" {
		storeIDInt, err := strconv.Atoi(storeID)
		if err == nil {
			query += " AND store_id = $2"
			args = append(args, storeIDInt)
		}
	}

	query += " LIMIT 1"

	var quantity int
	err := h.db.Pool.QueryRow(ctx, query, args...).Scan(&quantity)
	if err != nil {
		// Return nil instead of an error if no rows are found
		if err.Error() == "no rows in result set" {
			return nil, nil
		}
		return nil, err
	}

	return &quantity, nil
}

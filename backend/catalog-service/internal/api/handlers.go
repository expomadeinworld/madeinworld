package api

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
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

// =================================================================================
// NEW HANDLERS FOR CREATING AND UPDATING DATA
// =================================================================================

// CreateProduct handles POST /products
func (h *Handler) CreateProduct(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	var newProduct models.Product
	if err := c.ShouldBindJSON(&newProduct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Call the database function to insert the product
	productID, err := h.db.CreateProduct(ctx, newProduct)
	if err != nil {
		log.Printf("Failed to create product in DB: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"product_id": productID})
}

// UploadProductImage handles POST /products/:id/image
func (h *Handler) UploadProductImage(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 30*time.Second) // Longer timeout for uploads
	defer cancel()

	// --- 1. Get and Validate Product ID from URL ---
	idStr := c.Param("id")
	productID, err := strconv.Atoi(idStr)
	if err != nil {
		log.Printf("Invalid product ID format: %s", idStr)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID format"})
		return
	}

	// --- 2. Get File from Form ---
	fileHeader, err := c.FormFile("productImage") // "productImage" is the name of the form field.
	if err != nil {
		log.Printf("Missing productImage form field: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'productImage' form field"})
		return
	}

	// Validate file size (max 10MB)
	if fileHeader.Size > 10*1024*1024 {
		log.Printf("File too large: %d bytes", fileHeader.Size)
		c.JSON(http.StatusBadRequest, gin.H{"error": "File size exceeds 10MB limit"})
		return
	}

	// Validate file type
	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/gif":  true,
		"image/webp": true,
	}

	// Open the file to check content type
	file, err := fileHeader.Open()
	if err != nil {
		log.Printf("Failed to open uploaded file: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open uploaded file"})
		return
	}
	defer file.Close()

	// Read first 512 bytes to detect content type
	buffer := make([]byte, 512)
	_, err = file.Read(buffer)
	if err != nil {
		log.Printf("Failed to read file content: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file content"})
		return
	}

	// Reset file pointer
	file.Seek(0, 0)

	// Detect content type
	contentType := http.DetectContentType(buffer)
	if !allowedTypes[contentType] {
		log.Printf("Invalid file type: %s", contentType)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only images are allowed"})
		return
	}

	// Try S3 upload first, fallback to local storage if AWS is not configured
	imageURL, err := h.uploadToS3(ctx, productID, fileHeader, file)
	if err != nil {
		log.Printf("S3 upload failed, falling back to local storage: %v", err)
		// Fallback to local storage for development
		imageURL, err = h.uploadToLocal(productID, fileHeader, file)
		if err != nil {
			log.Printf("Local upload also failed: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload file"})
			return
		}
	}

	// --- Save to Database (Replace existing image) ---
	if err := h.db.ReplaceProductImage(ctx, productID, imageURL); err != nil {
		log.Printf("Failed to save image URL to DB: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "File uploaded but failed to update product record"})
		return
	}

	// --- Return Success Response ---
	c.JSON(http.StatusCreated, gin.H{"image_url": imageURL})
}

// UpdateProduct handles PUT /products/:id
func (h *Handler) UpdateProduct(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	// Get product ID from URL
	idStr := c.Param("id")
	productID, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID format"})
		return
	}

	// Parse request body
	var updatedProduct models.Product
	if err := c.ShouldBindJSON(&updatedProduct); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Update the product in the database
	if err := h.db.UpdateProduct(ctx, productID, updatedProduct); err != nil {
		log.Printf("Failed to update product %d: %v", productID, err)
		if err.Error() == fmt.Sprintf("product with ID %d not found", productID) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update product"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":    "Product updated successfully",
		"product_id": productID,
	})
}

// DeleteProduct handles DELETE /products/:id
func (h *Handler) DeleteProduct(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	// Get product ID from URL
	idStr := c.Param("id")
	productID, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID format"})
		return
	}

	// Check if hard delete is requested (query parameter)
	hardDelete := c.Query("hard") == "true"

	if hardDelete {
		// Perform hard delete (permanent removal)
		if err := h.db.HardDeleteProduct(ctx, productID); err != nil {
			log.Printf("Failed to hard delete product %d: %v", productID, err)
			if err.Error() == fmt.Sprintf("product with ID %d not found", productID) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete product"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message":    "Product permanently deleted",
			"product_id": productID,
		})
	} else {
		// Perform soft delete (set is_active = false)
		if err := h.db.DeleteProduct(ctx, productID); err != nil {
			log.Printf("Failed to delete product %d: %v", productID, err)
			if err.Error() == fmt.Sprintf("product with ID %d not found or already deleted", productID) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Product not found or already deleted"})
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete product"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message":    "Product deleted successfully",
			"product_id": productID,
		})
	}
}

// =================================================================================
// EXISTING HANDLERS (Unchanged)
// =================================================================================

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
	miniAppType := c.Query("mini_app_type")
	includeSubcategories := c.Query("include_subcategories") == "true"

	query := `
        SELECT category_id, name, store_type_association, mini_app_association, created_at, updated_at
        FROM product_categories
    `

	args := []interface{}{}
	argIndex := 1
	conditions := []string{}

	if storeType != "" {
		conditions = append(conditions, fmt.Sprintf("(store_type_association = $%d OR store_type_association = 'All')", argIndex))
		args = append(args, strings.Title(storeType))
		argIndex++
	}

	if miniAppType != "" {
		conditions = append(conditions, fmt.Sprintf("$%d = ANY(mini_app_association)", argIndex))
		args = append(args, miniAppType)
		argIndex++
	}

	if len(conditions) > 0 {
		query += " WHERE " + strings.Join(conditions, " AND ")
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
			&category.MiniAppAssociation,
			&category.CreatedAt,
			&category.UpdatedAt,
		)
		if err != nil {
			log.Printf("Error scanning category: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan category"})
			return
		}

		// Load subcategories if requested
		if includeSubcategories {
			subcategories, err := h.getSubcategoriesForCategory(ctx, category.ID)
			if err != nil {
				log.Printf("Error loading subcategories for category %d: %v", category.ID, err)
				// Continue without subcategories rather than failing
			} else {
				category.Subcategories = subcategories
			}
		}

		categories = append(categories, category)
	}

	c.JSON(http.StatusOK, categories)
}

// Helper function to get subcategories for a category
func (h *Handler) getSubcategoriesForCategory(ctx context.Context, categoryID int) ([]models.Subcategory, error) {
	query := `
        SELECT subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at
        FROM subcategories
        WHERE parent_category_id = $1 AND is_active = true
        ORDER BY display_order, subcategory_id
    `

	rows, err := h.db.Pool.Query(ctx, query, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subcategories []models.Subcategory

	for rows.Next() {
		var subcategory models.Subcategory
		err := rows.Scan(
			&subcategory.ID,
			&subcategory.ParentCategoryID,
			&subcategory.Name,
			&subcategory.ImageURL,
			&subcategory.DisplayOrder,
			&subcategory.IsActive,
			&subcategory.CreatedAt,
			&subcategory.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		subcategories = append(subcategories, subcategory)
	}

	return subcategories, nil
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

// uploadToS3 uploads file to AWS S3 bucket
func (h *Handler) uploadToS3(ctx context.Context, productID int, fileHeader *multipart.FileHeader, file multipart.File) (string, error) {
	// Reset file pointer
	file.Seek(0, 0)

	// Set up AWS S3 Client
	awsProfile := "madeinworld-frankfurt"
	cfg, err := config.LoadDefaultConfig(ctx, config.WithSharedConfigProfile(awsProfile))
	if err != nil {
		return "", fmt.Errorf("failed to load AWS config with profile %s: %w", awsProfile, err)
	}
	s3Client := s3.NewFromConfig(cfg)

	// Upload to S3
	bucketName := "madeinworld-product-images-admin"
	objectKey := fmt.Sprintf("products/%d/%d%s", productID, time.Now().UnixNano(), filepath.Ext(fileHeader.Filename))

	_, err = s3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: &bucketName,
		Key:    &objectKey,
		Body:   file,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Construct URL
	imageURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", bucketName, cfg.Region, objectKey)
	return imageURL, nil
}

// uploadToLocal uploads file to local storage for development
func (h *Handler) uploadToLocal(productID int, fileHeader *multipart.FileHeader, file multipart.File) (string, error) {
	// Reset file pointer
	file.Seek(0, 0)

	// Create uploads directory if it doesn't exist
	uploadsDir := "./uploads/products"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create uploads directory: %w", err)
	}

	// Generate unique filename
	ext := filepath.Ext(fileHeader.Filename)
	filename := fmt.Sprintf("%d_%d%s", productID, time.Now().UnixNano(), ext)
	filePath := filepath.Join(uploadsDir, filename)

	// Create the file
	dst, err := os.Create(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer dst.Close()

	// Copy file content
	if _, err := io.Copy(dst, file); err != nil {
		return "", fmt.Errorf("failed to save file: %w", err)
	}

	// Return URL for local development
	imageURL := fmt.Sprintf("http://localhost:8080/uploads/products/%s", filename)
	return imageURL, nil
}

// GetSubcategories handles GET /categories/:id/subcategories
func (h *Handler) GetSubcategories(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	categoryID := c.Param("id")

	query := `
        SELECT subcategory_id, parent_category_id, name, image_url, display_order, is_active, created_at, updated_at
        FROM subcategories
        WHERE parent_category_id = $1 AND is_active = true
        ORDER BY display_order, subcategory_id
    `

	rows, err := h.db.Pool.Query(ctx, query, categoryID)
	if err != nil {
		log.Printf("Error querying subcategories: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch subcategories"})
		return
	}
	defer rows.Close()

	var subcategories []models.Subcategory

	for rows.Next() {
		var subcategory models.Subcategory
		err := rows.Scan(
			&subcategory.ID,
			&subcategory.ParentCategoryID,
			&subcategory.Name,
			&subcategory.ImageURL,
			&subcategory.DisplayOrder,
			&subcategory.IsActive,
			&subcategory.CreatedAt,
			&subcategory.UpdatedAt,
		)
		if err != nil {
			log.Printf("Error scanning subcategory: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to scan subcategory"})
			return
		}

		subcategories = append(subcategories, subcategory)
	}

	c.JSON(http.StatusOK, subcategories)
}

// CreateSubcategory handles POST /categories/:id/subcategories
func (h *Handler) CreateSubcategory(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	categoryID := c.Param("id")

	var newSubcategory models.Subcategory
	if err := c.ShouldBindJSON(&newSubcategory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Set the parent category ID from URL parameter
	newSubcategory.ParentCategoryID, _ = strconv.Atoi(categoryID)

	query := `
        INSERT INTO subcategories (parent_category_id, name, image_url, display_order, is_active)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING subcategory_id, created_at, updated_at
    `

	var subcategoryID int
	var createdAt, updatedAt time.Time
	err := h.db.Pool.QueryRow(ctx, query,
		newSubcategory.ParentCategoryID,
		newSubcategory.Name,
		newSubcategory.ImageURL,
		newSubcategory.DisplayOrder,
		newSubcategory.IsActive,
	).Scan(&subcategoryID, &createdAt, &updatedAt)

	if err != nil {
		log.Printf("Failed to create subcategory in DB: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create subcategory"})
		return
	}

	newSubcategory.ID = subcategoryID
	newSubcategory.CreatedAt = createdAt
	newSubcategory.UpdatedAt = updatedAt

	c.JSON(http.StatusCreated, newSubcategory)
}

// UpdateSubcategory handles PUT /subcategories/:id
func (h *Handler) UpdateSubcategory(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	subcategoryID := c.Param("id")

	var updatedSubcategory models.Subcategory
	if err := c.ShouldBindJSON(&updatedSubcategory); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	query := `
        UPDATE subcategories
        SET name = $2, image_url = $3, display_order = $4, is_active = $5, updated_at = CURRENT_TIMESTAMP
        WHERE subcategory_id = $1
        RETURNING updated_at
    `

	var updatedAt time.Time
	err := h.db.Pool.QueryRow(ctx, query,
		subcategoryID,
		updatedSubcategory.Name,
		updatedSubcategory.ImageURL,
		updatedSubcategory.DisplayOrder,
		updatedSubcategory.IsActive,
	).Scan(&updatedAt)

	if err != nil {
		log.Printf("Failed to update subcategory in DB: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update subcategory"})
		return
	}

	updatedSubcategory.UpdatedAt = updatedAt
	c.JSON(http.StatusOK, updatedSubcategory)
}

// DeleteSubcategory handles DELETE /subcategories/:id
func (h *Handler) DeleteSubcategory(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	subcategoryID := c.Param("id")

	query := `DELETE FROM subcategories WHERE subcategory_id = $1`

	result, err := h.db.Pool.Exec(ctx, query, subcategoryID)
	if err != nil {
		log.Printf("Failed to delete subcategory from DB: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete subcategory"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Subcategory not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Subcategory deleted successfully"})
}

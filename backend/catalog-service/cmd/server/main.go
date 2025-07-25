package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/expomadeinworld/madeinworld/catalog-service/internal/api"
	"github.com/expomadeinworld/madeinworld/catalog-service/internal/db"
	"github.com/gin-gonic/gin"
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

	// Initialize handlers
	handler := api.NewHandler(database)

	// Set up Gin router
	router := setupRouter(handler)

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Set up graceful shutdown
	go func() {
		log.Printf("Starting server on port %s", port)
		if err := router.Run(":" + port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
}

func setupRouter(handler *api.Handler) *gin.Engine {
	// Set Gin mode based on environment
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Add middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())

	// Serve uploaded files for local development
	router.Static("/uploads", "./uploads")

	// Health check endpoint
	router.GET("/health", handler.Health)

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Product endpoints
		v1.GET("/products", handler.GetProducts)
		v1.GET("/products/:id", handler.GetProduct)
		// --- NEW ROUTES ---
		v1.POST("/products", handler.CreateProduct)
		v1.PUT("/products/:id", handler.UpdateProduct)
		v1.DELETE("/products/:id", handler.DeleteProduct)
		v1.POST("/products/:id/image", handler.UploadProductImage)
		v1.POST("/products/:id/images", handler.UploadProductImages)
		v1.GET("/products/:id/images", handler.GetProductImages)
		v1.PUT("/products/:id/images/reorder", handler.ReorderProductImages)
		v1.DELETE("/products/:id/images/:image_id", handler.DeleteProductImage)
		v1.PUT("/products/:id/images/:image_id/primary", handler.SetPrimaryImage)

		// Category endpoints
		v1.GET("/categories", handler.GetCategories)
		v1.POST("/categories", handler.CreateCategory)
		v1.PUT("/categories/:id", handler.UpdateCategory)
		v1.DELETE("/categories/:id", handler.DeleteCategory)
		v1.GET("/categories/:id/subcategories", handler.GetSubcategories)
		v1.POST("/categories/:id/subcategories", handler.CreateSubcategory)

		// Subcategory endpoints
		v1.PUT("/subcategories/:id", handler.UpdateSubcategory)
		v1.DELETE("/subcategories/:id", handler.DeleteSubcategory)
		v1.POST("/subcategories/:id/image", handler.UploadSubcategoryImage)

		// Store endpoints
		v1.GET("/stores", handler.GetStores)
		v1.POST("/stores", handler.CreateStore)
		v1.PUT("/stores/:id", handler.UpdateStore)
		v1.DELETE("/stores/:id", handler.DeleteStore)
		v1.POST("/stores/:id/image", handler.UploadStoreImage)
	}

	// Root endpoint for basic info
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service": "catalog-service",
			"version": "1.0.0",
			"status":  "running",
		})
	})

	return router
}

// corsMiddleware adds CORS headers to allow cross-origin requests
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, X-Admin-Request")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

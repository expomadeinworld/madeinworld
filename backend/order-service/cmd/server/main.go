package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/expomadeinworld/madeinworld/order-service/internal/api"
	"github.com/expomadeinworld/madeinworld/order-service/internal/db"
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
	port := os.Getenv("ORDER_PORT")
	if port == "" {
		port = "8082" // Different port from auth and catalog services
	}

	// Set up graceful shutdown
	go func() {
		log.Printf("Starting order service on port %s", port)
		if err := router.Run(":" + port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down order service...")
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

	// Health check endpoint
	router.GET("/health", handler.Health)

	// API routes with JWT protection
	apiGroup := router.Group("/api")
	apiGroup.Use(api.AuthMiddleware())
	{
		// Cart endpoints - mini-app specific
		apiGroup.GET("/cart/:mini_app_type", handler.GetCart)
		apiGroup.POST("/cart/:mini_app_type/add", handler.AddToCart)
		apiGroup.PUT("/cart/:mini_app_type/update", handler.UpdateCartItem)
		apiGroup.DELETE("/cart/:mini_app_type/remove/:product_id", handler.RemoveFromCart)

		// Order endpoints - mini-app specific
		apiGroup.POST("/orders/:mini_app_type", handler.CreateOrder)
		apiGroup.GET("/orders/:mini_app_type", handler.GetOrders)

		// Specific order endpoint (different path to avoid conflict)
		apiGroup.GET("/order/:order_id", handler.GetOrder)
	}

	// Admin API routes with authentication and admin middleware
	adminGroup := router.Group("/api/admin")
	adminGroup.Use(api.AuthMiddleware())
	adminGroup.Use(api.AdminMiddleware())
	{
		// Order management endpoints
		adminGroup.GET("/orders", handler.GetAdminOrders)
		adminGroup.GET("/orders/:order_id", handler.GetAdminOrder)
		adminGroup.PUT("/orders/:order_id/status", handler.UpdateOrderStatus)
		adminGroup.DELETE("/orders/:order_id", handler.DeleteOrder)
		adminGroup.POST("/orders/bulk-update", handler.BulkUpdateOrders)

		// Cart management endpoints
		adminGroup.GET("/carts", handler.GetAdminCarts)
		adminGroup.GET("/carts/:cart_id", handler.GetAdminCart)
		adminGroup.PUT("/carts/:cart_id/items", handler.UpdateAdminCartItem)
		adminGroup.DELETE("/carts/:cart_id", handler.DeleteAdminCart)

		// Statistics endpoints
		adminGroup.GET("/orders/statistics", handler.GetOrderStatistics)
		adminGroup.GET("/carts/statistics", handler.GetCartStatistics)
	}

	// Root endpoint for basic info
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service": "order-service",
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

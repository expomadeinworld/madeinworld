package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/expomadeinworld/madeinworld/auth-service/internal/api"
	"github.com/expomadeinworld/madeinworld/auth-service/internal/db"
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
	port := os.Getenv("AUTH_PORT")
	if port == "" {
		port = "8081" // Different port from catalog service
	}

	// Set up graceful shutdown
	go func() {
		log.Printf("Starting auth service on port %s", port)
		if err := router.Run(":" + port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down auth service...")
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

	// API routes
	auth := router.Group("/api/auth")
	{
		auth.POST("/signup", handler.Signup)
		auth.POST("/login", handler.Login)
	}

	// Protected routes for testing JWT validation
	protected := router.Group("/api/protected")
	protected.Use(api.AuthMiddleware())
	{
		protected.GET("/profile", handler.GetProfile)
	}

	// Root endpoint for basic info
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service": "auth-service",
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
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

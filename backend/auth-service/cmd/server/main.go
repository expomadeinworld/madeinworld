package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/expomadeinworld/madeinworld/auth-service/internal/api"
	"github.com/expomadeinworld/madeinworld/auth-service/internal/db"
	"github.com/expomadeinworld/madeinworld/auth-service/internal/services"
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

	// Initialize user verification schema
	if err := database.InitUserSchema(context.Background()); err != nil {
		log.Fatalf("Failed to initialize user schema: %v", err)
	}

	// Initialize handlers
	handler := api.NewHandler(database)

	// Initialize cleanup service (runs every 30 minutes)
	cleanupService := services.NewCleanupService(database, 30)
	cleanupService.Start()
	defer cleanupService.Stop()

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

	// Liveness and readiness endpoints
	// /live returns 200 if the process is running (no DB checks)
	router.GET("/live", func(c *gin.Context) { c.Status(200) })
	// /ready performs DB checks (what /health used to do)
	router.GET("/ready", handler.Health)
	// Keep /health for backward compatibility (same as /ready)
	router.GET("/health", handler.Health)

	// API routes
	auth := router.Group("/api/auth")
	{
		// Legacy password-based authentication (will be deprecated)
		auth.POST("/signup", handler.Signup)
		auth.POST("/login", handler.Login)

		// New passwordless authentication for users
		auth.POST("/send-verification", handler.UserSendVerification)
		auth.POST("/verify-code", handler.UserVerifyCode)

		// Token refresh
		auth.POST("/refresh", handler.Refresh)

		// Admin email verification routes (separate endpoints)
		auth.POST("/admin/send-verification", handler.AdminSendVerification)
		auth.POST("/admin/verify-code", handler.AdminVerifyCode)
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

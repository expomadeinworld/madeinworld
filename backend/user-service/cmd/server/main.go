package main

import (
	"log"
	"os"

	"user-service/internal/api"
	"user-service/internal/db"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file if it exists
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Ensure all log output goes to stdout so App Runner captures it in Application Logs
	log.SetOutput(os.Stdout)

	log.Printf("User Service starting (GIT_SHA=%s BUILD_TIME=%s)", os.Getenv("GIT_SHA"), os.Getenv("BUILD_TIME"))

	// TEMP DEBUG: print DB env vars (password masked) at startup
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	mask := func(s string) string {
		if s == "" {
			return "(empty)"
		}
		rs := []rune(s)
		n := len(rs)
		if n <= 8 {
			return "****"
		}
		return string(rs[:4]) + "****" + string(rs[n-4:])
	}
	log.Printf("[TEMP-DEBUG] DB env -> host=%s user=%s password=%s", dbHost, dbUser, mask(dbPass))

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
	port := os.Getenv("USER_PORT")
	if port == "" {
		port = "8083" // Different port from other services
	}

	log.Printf("Starting user service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
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
	router.Use(api.CORSMiddleware())

	// Health and readiness endpoints (no auth required)
	router.GET("/live", func(c *gin.Context) { c.Status(200) })
	router.GET("/ready", handler.Health)
	router.GET("/health", handler.Health)

	// Admin API routes with authentication and admin middleware
	adminGroup := router.Group("/api/admin")
	adminGroup.Use(api.AuthMiddleware())
	adminGroup.Use(api.AdminMiddleware())
	{
		// User management endpoints
		adminGroup.GET("/users", handler.GetUsers)
		adminGroup.POST("/users", handler.CreateUser)
		adminGroup.GET("/users/analytics", handler.GetUserAnalytics)
		adminGroup.GET("/users/:user_id", handler.GetUser)
		adminGroup.PUT("/users/:user_id", handler.UpdateUser)
		adminGroup.DELETE("/users/:user_id", handler.DeleteUser)
		adminGroup.POST("/users/:user_id/status", handler.UpdateUserStatus)
		adminGroup.POST("/users/bulk-update", handler.BulkUpdateUsers)
	}

	return router
}

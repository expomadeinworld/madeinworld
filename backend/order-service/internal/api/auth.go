package api

import (
	"net/http"
	"os"
	"strings"

	"github.com/expomadeinworld/madeinworld/order-service/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware validates JWT tokens
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Authorization header required",
				Message: "Please provide a valid authorization token",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		tokenParts := strings.Split(authHeader, " ")
		if len(tokenParts) != 2 || tokenParts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid authorization format",
				Message: "Authorization header must be in format 'Bearer <token>'",
			})
			c.Abort()
			return
		}

		tokenString := tokenParts[1]

		// Parse and validate token
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "your-secret-key-change-this-in-production"
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Error:   "Invalid token",
				Message: "The provided token is invalid or expired",
			})
			c.Abort()
			return
		}

		// Extract claims
		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			c.Set("user_id", claims["user_id"])
			c.Set("email", claims["email"])
		}

		c.Next()
	}
}

// GetUserID extracts user ID from the JWT token claims
func GetUserID(c *gin.Context) (string, bool) {
	userID, exists := c.Get("user_id")
	if !exists {
		return "", false
	}

	userIDStr, ok := userID.(string)
	return userIDStr, ok
}

// ValidateMiniAppType validates and returns the mini-app type from URL parameter
func ValidateMiniAppType(c *gin.Context) (models.MiniAppType, bool) {
	miniAppTypeStr := c.Param("mini_app_type")
	miniAppType := models.MiniAppType(miniAppTypeStr)

	if !miniAppType.IsValid() {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "Invalid mini-app type",
			Message: "Mini-app type must be one of: RetailStore, UnmannedStore, ExhibitionSales, GroupBuying",
		})
		return "", false
	}

	return miniAppType, true
}

// AdminMiddleware ensures the user has admin privileges
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if this is an admin request
		isAdminRequest := c.GetHeader("X-Admin-Request") == "true"
		if !isAdminRequest {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Error:   "Admin access required",
				Message: "This endpoint requires admin privileges",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

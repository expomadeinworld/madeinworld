package models

import (
	"time"
)

// MiniAppType represents the type of mini-app
type MiniAppType string

const (
	MiniAppTypeRetailStore     MiniAppType = "RetailStore"
	MiniAppTypeUnmannedStore   MiniAppType = "UnmannedStore"
	MiniAppTypeExhibitionSales MiniAppType = "ExhibitionSales"
	MiniAppTypeGroupBuying     MiniAppType = "GroupBuying"
)

// IsValid checks if the mini-app type is valid
func (m MiniAppType) IsValid() bool {
	switch m {
	case MiniAppTypeRetailStore, MiniAppTypeUnmannedStore, MiniAppTypeExhibitionSales, MiniAppTypeGroupBuying:
		return true
	default:
		return false
	}
}

// RequiresStore returns true if the mini-app type requires a store_id
func (m MiniAppType) RequiresStore() bool {
	return m == MiniAppTypeUnmannedStore || m == MiniAppTypeExhibitionSales
}

// OrderStatus represents the status of an order
type OrderStatus string

const (
	OrderStatusPending    OrderStatus = "pending"
	OrderStatusConfirmed  OrderStatus = "confirmed"
	OrderStatusProcessing OrderStatus = "processing"
	OrderStatusShipped    OrderStatus = "shipped"
	OrderStatusDelivered  OrderStatus = "delivered"
	OrderStatusCancelled  OrderStatus = "cancelled"
)

// Cart represents a user's cart for a specific mini-app
// Note: In the existing DB, each cart entry represents one product (no separate cart_items table)
type Cart struct {
	ID          string      `json:"id" db:"id"`
	UserID      string      `json:"user_id" db:"user_id"`
	ProductID   string      `json:"product_id" db:"product_id"`
	Quantity    int         `json:"quantity" db:"quantity"`
	MiniAppType MiniAppType `json:"mini_app_type" db:"mini_app_type"`
	Product     *Product    `json:"product,omitempty"` // Populated when needed
	CreatedAt   time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at" db:"updated_at"`
}

// CartResponse represents the response format for cart operations
type CartResponse struct {
	Items []Cart `json:"items"`
}

// CartItem represents an item in a cart (for compatibility)
type CartItem struct {
	ID        string    `json:"id" db:"id"`
	ProductID string    `json:"product_id" db:"product_id"`
	Quantity  int       `json:"quantity" db:"quantity"`
	Product   *Product  `json:"product,omitempty"` // Populated when needed
	AddedAt   time.Time `json:"added_at" db:"created_at"`
}

// Order represents a completed order
type Order struct {
	ID          string      `json:"id" db:"id"`
	UserID      string      `json:"user_id" db:"user_id"`
	MiniAppType MiniAppType `json:"mini_app_type" db:"mini_app_type"`
	TotalAmount float64     `json:"total_amount" db:"total_amount"`
	Status      OrderStatus `json:"status" db:"status"`
	Items       []OrderItem `json:"items"`
	CreatedAt   time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at" db:"updated_at"`
}

// OrderItem represents an item in an order
type OrderItem struct {
	ID         string   `json:"id" db:"id"`
	OrderID    string   `json:"order_id" db:"order_id"`
	ProductID  string   `json:"product_id" db:"product_id"`
	Quantity   int      `json:"quantity" db:"quantity"`
	UnitPrice  float64  `json:"unit_price" db:"unit_price"`
	TotalPrice float64  `json:"total_price" db:"total_price"`
	Product    *Product `json:"product,omitempty"` // Populated when needed
}

// Product represents a product (simplified for order service)
type Product struct {
	ID                   string  `json:"id" db:"id"`
	SKU                  string  `json:"sku" db:"sku"`
	Title                string  `json:"title" db:"title"`
	MainPrice            float64 `json:"main_price" db:"main_price"`
	StockLeft            int     `json:"stock_left" db:"stock_left"`
	MinimumOrderQuantity int     `json:"minimum_order_quantity" db:"minimum_order_quantity"`
	IsActive             bool    `json:"is_active" db:"is_active"`
}

// DisplayStock returns the stock quantity with buffer applied (actual - 5)
func (p *Product) DisplayStock() int {
	displayStock := p.StockLeft - 5
	if displayStock < 0 {
		displayStock = 0
	}
	return displayStock
}

// HasStock returns true if the product has stock available for display
func (p *Product) HasStock() bool {
	return p.DisplayStock() > 0
}

// Request/Response models

// AddToCartRequest represents a request to add an item to cart
type AddToCartRequest struct {
	ProductID string `json:"product_id" binding:"required"`
	Quantity  int    `json:"quantity" binding:"required,min=1"`
	StoreID   *int   `json:"store_id,omitempty"` // Required for location-based mini-apps
}

// UpdateCartItemRequest represents a request to update cart item quantity
type UpdateCartItemRequest struct {
	ProductID string `json:"product_id" binding:"required"`
	Quantity  int    `json:"quantity" binding:"required,min=0"` // 0 means remove
}

// CreateOrderRequest represents a request to create an order
type CreateOrderRequest struct {
	StoreID *int `json:"store_id,omitempty"` // Required for location-based mini-apps
}

// ErrorResponse represents an error response
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

// SuccessResponse represents a success response
type SuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

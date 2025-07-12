package api

import (
	"context"
	"fmt"

	"github.com/expomadeinworld/madeinworld/order-service/internal/models"
)

// getCartItems gets all cart items for a user and mini-app type
func (h *Handler) getCartItems(ctx context.Context, userID string, miniAppType models.MiniAppType) ([]models.Cart, error) {
	query := `
		SELECT
			c.id, c.user_id, c.product_id, c.quantity, c.mini_app_type, c.created_at, c.updated_at,
			p.product_uuid, p.sku, p.title, p.main_price, p.stock_left,
			p.minimum_order_quantity, p.is_active
		FROM carts c
		JOIN products p ON c.product_id = p.product_uuid
		WHERE c.user_id = $1 AND c.mini_app_type = $2
		ORDER BY c.created_at DESC
	`

	rows, err := h.db.Pool.Query(ctx, query, userID, string(miniAppType))
	if err != nil {
		return nil, fmt.Errorf("failed to query cart items: %w", err)
	}
	defer rows.Close()

	var items []models.Cart
	for rows.Next() {
		var item models.Cart
		var product models.Product

		err := rows.Scan(
			&item.ID,
			&item.UserID,
			&item.ProductID,
			&item.Quantity,
			&item.MiniAppType,
			&item.CreatedAt,
			&item.UpdatedAt,
			&product.ID,
			&product.SKU,
			&product.Title,
			&product.MainPrice,
			&product.StockLeft,
			&product.MinimumOrderQuantity,
			&product.IsActive,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan cart item: %w", err)
		}

		item.Product = &product
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating cart items: %w", err)
	}

	return items, nil
}

// getProduct retrieves a product by ID (using UUID)
func (h *Handler) getProduct(ctx context.Context, productID string) (*models.Product, error) {
	var product models.Product
	query := `
		SELECT product_uuid, sku, title, main_price, stock_left, minimum_order_quantity, is_active
		FROM products
		WHERE product_uuid = $1
	`

	err := h.db.Pool.QueryRow(ctx, query, productID).Scan(
		&product.ID,
		&product.SKU,
		&product.Title,
		&product.MainPrice,
		&product.StockLeft,
		&product.MinimumOrderQuantity,
		&product.IsActive,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get product: %w", err)
	}

	return &product, nil
}

// addItemToCart adds an item to the cart or updates quantity if it already exists
func (h *Handler) addItemToCart(ctx context.Context, userID string, miniAppType models.MiniAppType, productID string, quantity int) error {
	// Check if item already exists in cart
	var existingQuantity int
	checkQuery := `
		SELECT quantity FROM carts 
		WHERE user_id = $1 AND mini_app_type = $2 AND product_id = $3
	`

	err := h.db.Pool.QueryRow(ctx, checkQuery, userID, string(miniAppType), productID).Scan(&existingQuantity)

	if err == nil {
		// Item exists, update quantity
		updateQuery := `
			UPDATE carts 
			SET quantity = quantity + $1, updated_at = CURRENT_TIMESTAMP
			WHERE user_id = $2 AND mini_app_type = $3 AND product_id = $4
		`
		_, err = h.db.Pool.Exec(ctx, updateQuery, quantity, userID, string(miniAppType), productID)
		if err != nil {
			return fmt.Errorf("failed to update cart item quantity: %w", err)
		}
	} else {
		// Item doesn't exist, insert new
		insertQuery := `
			INSERT INTO carts (user_id, mini_app_type, product_id, quantity)
			VALUES ($1, $2, $3, $4)
		`
		_, err = h.db.Pool.Exec(ctx, insertQuery, userID, string(miniAppType), productID, quantity)
		if err != nil {
			return fmt.Errorf("failed to add item to cart: %w", err)
		}
	}

	return nil
}

// updateCartItemQuantity updates the quantity of an existing cart item
func (h *Handler) updateCartItemQuantity(ctx context.Context, userID string, miniAppType models.MiniAppType, productID string, quantity int) error {
	updateQuery := `
		UPDATE carts 
		SET quantity = $1, updated_at = CURRENT_TIMESTAMP
		WHERE user_id = $2 AND mini_app_type = $3 AND product_id = $4
	`

	result, err := h.db.Pool.Exec(ctx, updateQuery, quantity, userID, string(miniAppType), productID)
	if err != nil {
		return fmt.Errorf("failed to update cart item quantity: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("cart item not found")
	}

	return nil
}

// removeItemFromCart removes an item from the cart
func (h *Handler) removeItemFromCart(ctx context.Context, userID string, miniAppType models.MiniAppType, productID string) error {
	deleteQuery := `
		DELETE FROM carts 
		WHERE user_id = $1 AND mini_app_type = $2 AND product_id = $3
	`

	result, err := h.db.Pool.Exec(ctx, deleteQuery, userID, string(miniAppType), productID)
	if err != nil {
		return fmt.Errorf("failed to remove cart item: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("cart item not found")
	}

	return nil
}

// validateStockForCartAddition checks if adding quantity to cart would exceed available stock
func (h *Handler) validateStockForCartAddition(ctx context.Context, userID string, miniAppType models.MiniAppType, productID string, additionalQuantity int) error {
	// Get current quantity in cart for this product
	var currentQuantity int
	checkQuery := `
		SELECT COALESCE(quantity, 0) FROM carts 
		WHERE user_id = $1 AND mini_app_type = $2 AND product_id = $3
	`

	err := h.db.Pool.QueryRow(ctx, checkQuery, userID, string(miniAppType), productID).Scan(&currentQuantity)
	if err != nil {
		// If no existing item, current quantity is 0
		currentQuantity = 0
	}

	// Get product details
	product, err := h.getProduct(ctx, productID)
	if err != nil {
		return fmt.Errorf("failed to get product: %w", err)
	}

	// Check if product is active
	if !product.IsActive {
		return fmt.Errorf("product is not active")
	}

	// Calculate total quantity after addition
	totalQuantity := currentQuantity + additionalQuantity

	// Check against display stock (actual stock - 5 buffer)
	if totalQuantity > product.DisplayStock() {
		return fmt.Errorf("insufficient stock: requested %d, available %d (including current cart: %d)",
			totalQuantity, product.DisplayStock(), currentQuantity)
	}

	return nil
}

// clearCart removes all items from a user's cart for a specific mini-app
func (h *Handler) clearCart(ctx context.Context, userID string, miniAppType models.MiniAppType) error {
	deleteQuery := `DELETE FROM carts WHERE user_id = $1 AND mini_app_type = $2`
	_, err := h.db.Pool.Exec(ctx, deleteQuery, userID, string(miniAppType))
	if err != nil {
		return fmt.Errorf("failed to clear cart: %w", err)
	}
	return nil
}

// validateCartStockBeforeOrder validates all cart items have sufficient stock before order creation
func (h *Handler) validateCartStockBeforeOrder(ctx context.Context, cartItems []models.Cart) error {
	for _, item := range cartItems {
		// Refresh product data to get latest stock
		product, err := h.getProduct(ctx, item.ProductID)
		if err != nil {
			return fmt.Errorf("failed to get product %s: %w", item.ProductID, err)
		}

		// Check if product is still active
		if !product.IsActive {
			return fmt.Errorf("product '%s' is no longer available", product.Title)
		}

		// Check stock availability
		if item.Quantity > product.DisplayStock() {
			return fmt.Errorf("insufficient stock for product '%s': requested %d, available %d",
				product.Title, item.Quantity, product.DisplayStock())
		}

		// Update the product reference in cart item for accurate pricing
		item.Product = product
	}

	return nil
}

// createOrder creates a new order with items
func (h *Handler) createOrder(ctx context.Context, userID string, miniAppType models.MiniAppType, storeID *int, totalAmount float64, cartItems []models.Cart) (*models.Order, error) {
	// Start transaction
	tx, err := h.db.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Create order
	var order models.Order
	orderQuery := `
		INSERT INTO orders (user_id, mini_app_type, total_amount, status)
		VALUES ($1, $2, $3, $4)
		RETURNING id, user_id, mini_app_type, total_amount, status, created_at, updated_at
	`

	err = tx.QueryRow(ctx, orderQuery, userID, string(miniAppType), totalAmount, string(models.OrderStatusPending)).Scan(
		&order.ID,
		&order.UserID,
		&order.MiniAppType,
		&order.TotalAmount,
		&order.Status,
		&order.CreatedAt,
		&order.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create order: %w", err)
	}

	// Create order items
	var orderItems []models.OrderItem
	for _, cartItem := range cartItems {
		unitPrice := cartItem.Product.MainPrice
		totalPrice := float64(cartItem.Quantity) * unitPrice

		var orderItem models.OrderItem
		itemQuery := `
			INSERT INTO order_items (order_id, product_id, quantity, price)
			VALUES ($1, $2, $3, $4)
			RETURNING id, order_id, product_id, quantity, price
		`

		err = tx.QueryRow(ctx, itemQuery, order.ID, cartItem.ProductID, cartItem.Quantity, totalPrice).Scan(
			&orderItem.ID,
			&orderItem.OrderID,
			&orderItem.ProductID,
			&orderItem.Quantity,
			&orderItem.TotalPrice,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to create order item: %w", err)
		}

		orderItem.UnitPrice = unitPrice
		orderItem.Product = cartItem.Product
		orderItems = append(orderItems, orderItem)
	}

	// Commit transaction
	if err = tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	order.Items = orderItems
	return &order, nil
}

// getUserOrders retrieves all orders for a user and mini-app type
func (h *Handler) getUserOrders(ctx context.Context, userID string, miniAppType models.MiniAppType) ([]models.Order, error) {
	query := `
		SELECT id, user_id, mini_app_type, total_amount, status, created_at, updated_at
		FROM orders
		WHERE user_id = $1 AND mini_app_type = $2
		ORDER BY created_at DESC
	`

	rows, err := h.db.Pool.Query(ctx, query, userID, string(miniAppType))
	if err != nil {
		return nil, fmt.Errorf("failed to query orders: %w", err)
	}
	defer rows.Close()

	var orders []models.Order
	for rows.Next() {
		var order models.Order
		err := rows.Scan(
			&order.ID,
			&order.UserID,
			&order.MiniAppType,
			&order.TotalAmount,
			&order.Status,
			&order.CreatedAt,
			&order.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan order: %w", err)
		}

		// Get order items
		items, err := h.getOrderItems(ctx, order.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to get order items: %w", err)
		}
		order.Items = items

		orders = append(orders, order)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating orders: %w", err)
	}

	return orders, nil
}

// getOrderByID retrieves a specific order by ID (with user validation)
func (h *Handler) getOrderByID(ctx context.Context, orderID string, userID string) (*models.Order, error) {
	var order models.Order
	query := `
		SELECT id, user_id, mini_app_type, total_amount, status, created_at, updated_at
		FROM orders
		WHERE id = $1 AND user_id = $2
	`

	err := h.db.Pool.QueryRow(ctx, query, orderID, userID).Scan(
		&order.ID,
		&order.UserID,
		&order.MiniAppType,
		&order.TotalAmount,
		&order.Status,
		&order.CreatedAt,
		&order.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	// Get order items
	items, err := h.getOrderItems(ctx, order.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get order items: %w", err)
	}
	order.Items = items

	return &order, nil
}

// getOrderItems retrieves all items for an order with product details
func (h *Handler) getOrderItems(ctx context.Context, orderID string) ([]models.OrderItem, error) {
	query := `
		SELECT
			oi.id, oi.order_id, oi.product_id, oi.quantity, oi.price,
			p.product_uuid, p.sku, p.title, p.main_price, p.stock_left,
			p.minimum_order_quantity, p.is_active
		FROM order_items oi
		JOIN products p ON oi.product_id = p.product_uuid
		WHERE oi.order_id = $1
		ORDER BY oi.id
	`

	rows, err := h.db.Pool.Query(ctx, query, orderID)
	if err != nil {
		return nil, fmt.Errorf("failed to query order items: %w", err)
	}
	defer rows.Close()

	var items []models.OrderItem
	for rows.Next() {
		var item models.OrderItem
		var product models.Product

		err := rows.Scan(
			&item.ID,
			&item.OrderID,
			&item.ProductID,
			&item.Quantity,
			&item.TotalPrice,
			&product.ID,
			&product.SKU,
			&product.Title,
			&product.MainPrice,
			&product.StockLeft,
			&product.MinimumOrderQuantity,
			&product.IsActive,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan order item: %w", err)
		}

		item.Product = &product
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating order items: %w", err)
	}

	return items, nil
}

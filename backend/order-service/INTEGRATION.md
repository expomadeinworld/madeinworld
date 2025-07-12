# Order Service Integration Guide

## Overview

The Order Service implements mini-app specific cart and order management for the Made in World application. It provides JWT-protected endpoints with proper mini-app isolation and real-time stock verification.

## Key Features Implemented

### ✅ Mini-App Isolation
- **Separate carts per mini-app**: Each user has isolated carts for RetailStore, UnmannedStore, ExhibitionSales, and GroupBuying
- **Database schema**: Added `mini_app_type` field to carts and orders tables
- **API endpoints**: All endpoints require mini-app type parameter for proper isolation

### ✅ Stock Management
- **Display stock logic**: Shows actual stock - 5 buffer to maintain inventory buffer
- **Real-time verification**: Stock checked during all cart operations and order creation
- **Comprehensive validation**: Considers existing cart contents when adding new items
- **Error handling**: Proper error messages for insufficient stock scenarios

### ✅ JWT Authentication
- **Protected endpoints**: All API endpoints require valid JWT tokens
- **User isolation**: Users can only access their own carts and orders
- **Integration**: Reuses JWT validation logic from auth service

### ✅ Location-Based Mini-Apps
- **Store validation**: UnmannedStore and ExhibitionSales require store_id
- **Database support**: Orders table supports nullable store_id for non-location-based mini-apps
- **API validation**: Proper validation of store requirements per mini-app type

## Database Changes

### New Fields Added
```sql
-- Carts table
ALTER TABLE carts ADD COLUMN mini_app_type VARCHAR(50) NOT NULL DEFAULT 'RetailStore';

-- Orders table  
ALTER TABLE orders ADD COLUMN mini_app_type VARCHAR(50) NOT NULL DEFAULT 'RetailStore';
ALTER TABLE orders ALTER COLUMN store_id DROP NOT NULL; -- Now nullable
```

### Indexes Created
```sql
CREATE INDEX idx_carts_user_mini_app ON carts(user_id, mini_app_type);
CREATE INDEX idx_orders_user_mini_app ON orders(user_id, mini_app_type);
CREATE INDEX idx_orders_user_mini_app_store ON orders(user_id, mini_app_type, store_id);
```

## API Endpoints

### Cart Management
- `GET /api/cart/{mini_app_type}` - Get user's cart for specific mini-app
- `POST /api/cart/{mini_app_type}/add` - Add product to cart with stock validation
- `PUT /api/cart/{mini_app_type}/update` - Update cart item quantity
- `DELETE /api/cart/{mini_app_type}/remove/{product_id}` - Remove item from cart

### Order Management
- `POST /api/orders/{mini_app_type}` - Create order from cart with stock verification
- `GET /api/orders/{mini_app_type}` - Get user's orders for specific mini-app
- `GET /api/orders/{order_id}` - Get specific order details

### Health Check
- `GET /health` - Service health monitoring

## Integration Requirements

### 1. Database Setup
```bash
# Apply migration
psql -h localhost -U madeinworld_admin -d madeinworld_db \
  -f database/migrations/001_add_mini_app_type_to_carts_orders.sql
```

### 2. Service Dependencies
- **Auth Service**: Must be running on port 8081 for JWT validation
- **PostgreSQL**: Database with Made in World schema
- **Environment**: Proper JWT_SECRET configuration (must match auth service)

### 3. Environment Configuration
```bash
# Required environment variables
ORDER_PORT=8082
DB_HOST=localhost
DB_PORT=5432
DB_USER=madeinworld_admin
DB_PASSWORD=your_password
DB_NAME=madeinworld_db
JWT_SECRET=your_jwt_secret  # Must match auth service
```

## Stock Verification Logic

### Display Stock Calculation
```go
func (p *Product) DisplayStock() int {
    displayStock := p.StockLeft - 5  // 5 item buffer
    if displayStock < 0 {
        displayStock = 0
    }
    return displayStock
}
```

### Validation Points
1. **Add to Cart**: Validates product exists, is active, meets MOQ, and has sufficient stock
2. **Update Cart**: Validates new quantity doesn't exceed available stock
3. **Create Order**: Re-validates all cart items before order creation

## Mini-App Specific Behavior

### RetailStore & GroupBuying
- No store_id required
- Standard cart and order operations
- No location-based filtering

### UnmannedStore & ExhibitionSales  
- store_id required in all requests
- Orders filtered by store_id
- Location-based product filtering (if implemented in catalog service)

## Error Handling

### Common Error Scenarios
- **401 Unauthorized**: Invalid or missing JWT token
- **400 Bad Request**: Invalid mini-app type, missing store_id, insufficient stock
- **404 Not Found**: Product not found, order not found
- **500 Internal Server Error**: Database connection issues, transaction failures

### Stock-Related Errors
```json
{
  "error": "Insufficient stock",
  "message": "Only 3 items available"
}
```

## Testing

### Automated Tests
```bash
# Run endpoint tests
./test_endpoints.sh
```

### Manual Testing
```bash
# Health check
curl http://localhost:8082/health

# Test with JWT token
curl -H "Authorization: Bearer $JWT_TOKEN" \
  http://localhost:8082/api/cart/RetailStore
```

## Deployment

### Docker
```bash
./build.sh docker
docker run -p 8082:8082 madeinworld/order-service:latest
```

### Kubernetes
```bash
kubectl apply -f kubernetes/
```

## Monitoring

### Health Checks
- Endpoint: `/health`
- Database connectivity verification
- Service status reporting

### Logging
- Structured JSON logging
- Request/response logging
- Error tracking
- Performance metrics

## Next Steps

1. **Integration Testing**: Test with actual auth service and database
2. **Load Testing**: Verify performance under concurrent requests
3. **Monitoring Setup**: Implement metrics collection and alerting
4. **Documentation**: Update API documentation with examples
5. **Frontend Integration**: Connect with Flutter app cart functionality

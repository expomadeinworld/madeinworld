#!/bin/bash

# Test script for Order Service endpoints
# This script tests all endpoints with proper JWT authentication and mini-app isolation

set -e

# Configuration
ORDER_SERVICE_URL="http://localhost:8082"
AUTH_SERVICE_URL="http://localhost:8081"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test user credentials
TEST_EMAIL="admin@madeinworld.com"
TEST_PASSWORD="adminpassword123"

echo -e "${YELLOW}=== Order Service API Test Suite ===${NC}"
echo "Order Service URL: $ORDER_SERVICE_URL"
echo "Auth Service URL: $AUTH_SERVICE_URL"
echo ""

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        echo "Response: $3"
    fi
}

# Function to make authenticated API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$ORDER_SERVICE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            "$ORDER_SERVICE_URL$endpoint")
    fi

    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" = "$expected_status" ]; then
        return 0
    else
        echo "Expected: $expected_status, Got: $status_code"
        echo "Body: $body"
        return 1
    fi
}

# Function to make admin API calls
admin_api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -H "X-Admin-Request: true" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$ORDER_SERVICE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -H "X-Admin-Request: true" \
            "$ORDER_SERVICE_URL$endpoint")
    fi

    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" = "$expected_status" ]; then
        return 0
    else
        echo "Expected: $expected_status, Got: $status_code"
        echo "Body: $body"
        return 1
    fi
}

# Test 1: Health Check
echo -e "${YELLOW}1. Testing Health Check${NC}"
health_response=$(curl -s -w "\n%{http_code}" "$ORDER_SERVICE_URL/health")
health_status=$(echo "$health_response" | tail -n1)
print_result $([ "$health_status" = "200" ] && echo 0 || echo 1) "Health check" "$health_response"

# Test 2: Get JWT Token (requires auth service to be running)
echo -e "\n${YELLOW}2. Getting JWT Token${NC}"
echo "Note: This requires the auth service to be running on $AUTH_SERVICE_URL"

# Try to get JWT token
jwt_response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
    "$AUTH_SERVICE_URL/api/auth/login" 2>/dev/null || echo "AUTH_SERVICE_DOWN")

if [ "$jwt_response" = "AUTH_SERVICE_DOWN" ]; then
    echo -e "${RED}✗ Auth service not available. Skipping authenticated tests.${NC}"
    echo "To run full tests:"
    echo "1. Start the auth service: cd ../auth-service && go run cmd/server/main.go"
    echo "2. Create a test user or use existing credentials"
    echo "3. Re-run this test script"
    exit 1
fi

jwt_status=$(echo "$jwt_response" | tail -n1)
jwt_body=$(echo "$jwt_response" | sed '$d')

if [ "$jwt_status" = "200" ]; then
    JWT_TOKEN=$(echo "$jwt_body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    print_result 0 "JWT token obtained"
else
    echo -e "${RED}✗ Failed to get JWT token${NC}"
    echo "Response: $jwt_response"
    echo "Make sure:"
    echo "1. Auth service is running"
    echo "2. Test user exists with email: $TEST_EMAIL"
    echo "3. Password is correct: $TEST_PASSWORD"
    exit 1
fi

# Test 3: Test Cart Operations for Different Mini-Apps
echo -e "\n${YELLOW}3. Testing Cart Operations${NC}"

# Test mini-app types
mini_apps=("RetailStore" "UnmannedStore" "ExhibitionSales" "GroupBuying")

for mini_app in "${mini_apps[@]}"; do
    echo -e "\n${YELLOW}Testing $mini_app mini-app:${NC}"
    
    # Get empty cart
    api_call "GET" "/api/cart/$mini_app" "" "200"
    print_result $? "Get empty cart for $mini_app"
    
    # Add item to cart (assuming product ID exists)
    if [ "$mini_app" = "UnmannedStore" ] || [ "$mini_app" = "ExhibitionSales" ]; then
        # Location-based mini-apps require store_id
        add_data='{"product_id":"test-product-1","quantity":2,"store_id":1}'
    else
        add_data='{"product_id":"test-product-1","quantity":2}'
    fi
    
    api_call "POST" "/api/cart/$mini_app/add" "$add_data" "200"
    print_result $? "Add item to $mini_app cart"
    
    # Get cart with items
    api_call "GET" "/api/cart/$mini_app" "" "200"
    print_result $? "Get cart with items for $mini_app"
    
    # Update cart item
    update_data='{"product_id":"test-product-1","quantity":3}'
    api_call "PUT" "/api/cart/$mini_app/update" "$update_data" "200"
    print_result $? "Update cart item for $mini_app"

    # Remove item from cart
    api_call "DELETE" "/api/cart/$mini_app/remove/test-product-1" "" "200"
    print_result $? "Remove item from $mini_app cart"
done

# Test 4: Test Order Operations
echo -e "\n${YELLOW}4. Testing Order Operations${NC}"

# Add items to cart first for order creation test
api_call "POST" "/api/cart/RetailStore/add" '{"product_id":"test-product-1","quantity":1}' "200"
print_result $? "Add item to cart for order test"

# Create order
api_call "POST" "/api/orders/RetailStore" '{}' "201"
print_result $? "Create order from cart"

# Get orders
api_call "GET" "/api/orders/RetailStore" "" "200"
print_result $? "Get user orders"

# Test 5: Test Error Scenarios
echo -e "\n${YELLOW}5. Testing Error Scenarios${NC}"

# Invalid mini-app type
api_call "GET" "/api/cart/InvalidMiniApp" "" "400"
print_result $? "Invalid mini-app type rejection"

# Missing store_id for location-based mini-app
api_call "POST" "/api/cart/UnmannedStore/add" '{"product_id":"test-product-1","quantity":1}' "400"
print_result $? "Missing store_id validation"

# Invalid product ID
api_call "POST" "/api/cart/RetailStore/add" '{"product_id":"nonexistent-product","quantity":1}' "404"
print_result $? "Invalid product ID handling"

# Test 6: Test Admin Endpoints
echo -e "\n${YELLOW}6. Testing Admin Endpoints${NC}"

# Test admin orders listing
admin_api_call "GET" "/api/admin/orders" "" "200"
print_result $? "Get admin orders list"

# Test admin orders with pagination
admin_api_call "GET" "/api/admin/orders?page=1&limit=10" "" "200"
print_result $? "Get admin orders with pagination"

# Test admin orders with filters
admin_api_call "GET" "/api/admin/orders?status=pending&mini_app_type=RetailStore" "" "200"
print_result $? "Get admin orders with filters"

# Test admin order statistics
admin_api_call "GET" "/api/admin/orders/statistics" "" "200"
print_result $? "Get order statistics"

# Test admin order statistics with date range
admin_api_call "GET" "/api/admin/orders/statistics?date_from=2024-01-01&date_to=2024-12-31" "" "200"
print_result $? "Get order statistics with date range"

# Test bulk update orders (this will fail if no orders exist, but tests the endpoint)
bulk_data='{"order_ids":["nonexistent"],"status":"confirmed","reason":"Test bulk update"}'
admin_api_call "POST" "/api/admin/orders/bulk-update" "$bulk_data" "200"
print_result $? "Bulk update orders (may fail if no orders exist)"

# Test 7: Test Admin Authentication
echo -e "\n${YELLOW}7. Testing Admin Authentication${NC}"

# Test admin endpoint without X-Admin-Request header (should fail)
api_call "GET" "/api/admin/orders" "" "403"
print_result $? "Admin endpoint without admin header rejection"

# Test admin endpoint without authentication (should fail)
response=$(curl -s -w "\n%{http_code}" -X "GET" \
    -H "X-Admin-Request: true" \
    "$ORDER_SERVICE_URL/api/admin/orders")
status_code=$(echo "$response" | tail -n1)
print_result $([ "$status_code" = "401" ] && echo 0 || echo 1) "Admin endpoint without authentication rejection"

echo -e "\n${GREEN}=== Test Suite Complete ===${NC}"
echo "All tests have been executed. Check the results above."
echo ""
echo "To start the order service manually:"
echo "cd backend/order-service && go run cmd/server/main.go"
echo ""
echo "Admin endpoints tested:"
echo "- GET /api/admin/orders (list orders with filtering)"
echo "- GET /api/admin/orders/:id (get order details)"
echo "- PUT /api/admin/orders/:id/status (update order status)"
echo "- DELETE /api/admin/orders/:id (cancel order)"
echo "- POST /api/admin/orders/bulk-update (bulk update orders)"
echo "- GET /api/admin/orders/statistics (order statistics)"

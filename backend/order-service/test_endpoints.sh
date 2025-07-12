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
TEST_EMAIL="test@madeinworld.com"
TEST_PASSWORD="testpassword123"

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
    body=$(echo "$response" | head -n -1)
    
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
jwt_body=$(echo "$jwt_response" | head -n -1)

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
    
    # Add item to cart (assuming product ID 1 exists)
    if [ "$mini_app" = "UnmannedStore" ] || [ "$mini_app" = "ExhibitionSales" ]; then
        # Location-based mini-apps require store_id
        add_data='{"product_id":1,"quantity":2,"store_id":1}'
    else
        add_data='{"product_id":1,"quantity":2}'
    fi
    
    api_call "POST" "/api/cart/$mini_app/add" "$add_data" "200"
    print_result $? "Add item to $mini_app cart"
    
    # Get cart with items
    api_call "GET" "/api/cart/$mini_app" "" "200"
    print_result $? "Get cart with items for $mini_app"
    
    # Update cart item
    update_data='{"product_id":1,"quantity":3}'
    api_call "PUT" "/api/cart/$mini_app/update" "$update_data" "200"
    print_result $? "Update cart item for $mini_app"
    
    # Remove item from cart
    api_call "DELETE" "/api/cart/$mini_app/remove/1" "" "200"
    print_result $? "Remove item from $mini_app cart"
done

# Test 4: Test Order Operations
echo -e "\n${YELLOW}4. Testing Order Operations${NC}"

# Add items to cart first for order creation test
api_call "POST" "/api/cart/RetailStore/add" '{"product_id":1,"quantity":1}' "200"
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
api_call "POST" "/api/cart/UnmannedStore/add" '{"product_id":1,"quantity":1}' "400"
print_result $? "Missing store_id validation"

# Invalid product ID
api_call "POST" "/api/cart/RetailStore/add" '{"product_id":99999,"quantity":1}' "404"
print_result $? "Invalid product ID handling"

echo -e "\n${GREEN}=== Test Suite Complete ===${NC}"
echo "All tests have been executed. Check the results above."
echo ""
echo "To start the order service manually:"
echo "cd backend/order-service && go run cmd/server/main.go"

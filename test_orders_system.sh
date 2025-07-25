#!/bin/bash

# Comprehensive Orders Management System Test Suite
# Tests both backend API endpoints and frontend E2E functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORDER_SERVICE_URL="http://localhost:8082"
AUTH_SERVICE_URL="http://localhost:8081"
ADMIN_PANEL_URL="http://localhost:3000"

echo -e "${BLUE}=== Made in World Orders Management System Test Suite ===${NC}"
echo "Order Service URL: $ORDER_SERVICE_URL"
echo "Auth Service URL: $AUTH_SERVICE_URL"
echo "Admin Panel URL: $ADMIN_PANEL_URL"
echo ""

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        if [ -n "$3" ]; then
            echo "  Details: $3"
        fi
    fi
}

# Function to check service health
check_service_health() {
    local service_name=$1
    local service_url=$2
    local health_endpoint=$3
    
    echo -e "${YELLOW}Checking $service_name health...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" "$service_url$health_endpoint" 2>/dev/null || echo "SERVICE_DOWN")
    
    if [ "$response" = "SERVICE_DOWN" ]; then
        echo -e "${RED}✗ $service_name is not running${NC}"
        return 1
    fi
    
    status_code=$(echo "$response" | tail -n1)
    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✓ $service_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ $service_name health check failed (status: $status_code)${NC}"
        return 1
    fi
}

# Function to run backend API tests
run_backend_tests() {
    echo -e "\n${YELLOW}=== Running Backend API Tests ===${NC}"
    
    # Check if order service test script exists
    if [ -f "backend/order-service/test_endpoints.sh" ]; then
        echo "Running order service endpoint tests..."
        cd backend/order-service
        chmod +x test_endpoints.sh
        ./test_endpoints.sh
        cd ../..
        print_result $? "Backend API tests"
    else
        echo -e "${RED}✗ Order service test script not found${NC}"
        return 1
    fi
}

# Function to run frontend E2E tests
run_frontend_tests() {
    echo -e "\n${YELLOW}=== Running Frontend E2E Tests ===${NC}"
    
    # Check if admin panel and Playwright are set up
    if [ -d "admin-panel/tests" ]; then
        echo "Running Playwright E2E tests..."
        cd admin-panel
        
        # Check if Playwright is installed
        if [ ! -d "node_modules/@playwright" ]; then
            echo "Installing Playwright..."
            npm install @playwright/test
            npx playwright install
        fi
        
        # Run orders management tests
        echo "Running orders management E2E tests..."
        npx playwright test tests/orders-management.spec.js --reporter=line
        test_result=$?
        
        cd ..
        print_result $test_result "Frontend E2E tests"
        return $test_result
    else
        echo -e "${RED}✗ Admin panel test directory not found${NC}"
        return 1
    fi
}

# Function to test integration between services
test_integration() {
    echo -e "\n${YELLOW}=== Testing Service Integration ===${NC}"
    
    # Test that admin panel can connect to order service
    echo "Testing admin panel to order service connection..."
    
    # Check if admin panel is running
    admin_response=$(curl -s -w "\n%{http_code}" "$ADMIN_PANEL_URL" 2>/dev/null || echo "ADMIN_DOWN")
    
    if [ "$admin_response" = "ADMIN_DOWN" ]; then
        echo -e "${RED}✗ Admin panel is not running${NC}"
        echo "  Start with: cd admin-panel && npm start"
        return 1
    fi
    
    admin_status=$(echo "$admin_response" | tail -n1)
    if [ "$admin_status" = "200" ]; then
        print_result 0 "Admin panel is accessible"
    else
        print_result 1 "Admin panel accessibility check failed"
        return 1
    fi
    
    # Test order statistics endpoint (used by dashboard)
    echo "Testing order statistics endpoint..."
    stats_response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer dummy-token-for-development" \
        -H "X-Admin-Request: true" \
        "$ORDER_SERVICE_URL/api/admin/orders/statistics" 2>/dev/null || echo "STATS_FAILED")
    
    if [ "$stats_response" = "STATS_FAILED" ]; then
        print_result 1 "Order statistics endpoint test failed"
        return 1
    fi
    
    stats_status=$(echo "$stats_response" | tail -n1)
    if [ "$stats_status" = "200" ]; then
        print_result 0 "Order statistics endpoint working"
    else
        print_result 1 "Order statistics endpoint failed (status: $stats_status)"
        return 1
    fi
}

# Function to generate test report
generate_report() {
    echo -e "\n${BLUE}=== Test Summary Report ===${NC}"
    echo "Test execution completed at: $(date)"
    echo ""
    echo "Services tested:"
    echo "- Order Service (Backend API)"
    echo "- Admin Panel (Frontend)"
    echo "- Service Integration"
    echo ""
    echo "Test coverage includes:"
    echo "- Admin authentication and authorization"
    echo "- Order listing with filtering and pagination"
    echo "- Order details retrieval"
    echo "- Order status updates (single and bulk)"
    echo "- Order statistics and dashboard integration"
    echo "- Frontend user interface functionality"
    echo "- Error handling and edge cases"
    echo ""
}

# Main test execution
main() {
    echo -e "${YELLOW}Starting comprehensive test suite...${NC}"
    
    # Step 1: Check service health
    echo -e "\n${YELLOW}=== Step 1: Service Health Checks ===${NC}"
    
    order_service_healthy=0
    auth_service_healthy=0
    
    check_service_health "Order Service" "$ORDER_SERVICE_URL" "/health" || order_service_healthy=1
    check_service_health "Auth Service" "$AUTH_SERVICE_URL" "/health" || auth_service_healthy=1
    
    if [ $order_service_healthy -ne 0 ]; then
        echo -e "${RED}Order service is required for testing. Please start it first:${NC}"
        echo "cd backend/order-service && go run cmd/server/main.go"
        exit 1
    fi
    
    if [ $auth_service_healthy -ne 0 ]; then
        echo -e "${YELLOW}Warning: Auth service is not running. Some tests may fail.${NC}"
        echo "To start: cd backend/auth-service && go run cmd/server/main.go"
    fi
    
    # Step 2: Run backend tests
    backend_result=0
    run_backend_tests || backend_result=1
    
    # Step 3: Run frontend tests
    frontend_result=0
    run_frontend_tests || frontend_result=1
    
    # Step 4: Test integration
    integration_result=0
    test_integration || integration_result=1
    
    # Step 5: Generate report
    generate_report
    
    # Final result
    total_failures=$((backend_result + frontend_result + integration_result))
    
    if [ $total_failures -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
        echo -e "${GREEN}Orders Management System is fully functional.${NC}"
        exit 0
    else
        echo -e "${RED}❌ $total_failures test suite(s) failed.${NC}"
        echo -e "${RED}Please check the errors above and fix the issues.${NC}"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backend-only    Run only backend API tests"
    echo "  --frontend-only   Run only frontend E2E tests"
    echo "  --integration-only Run only integration tests"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --backend-only     # Run only backend tests"
    echo "  $0 --frontend-only    # Run only frontend tests"
}

# Parse command line arguments
case "${1:-}" in
    --backend-only)
        echo -e "${YELLOW}Running backend tests only...${NC}"
        check_service_health "Order Service" "$ORDER_SERVICE_URL" "/health" || exit 1
        run_backend_tests
        ;;
    --frontend-only)
        echo -e "${YELLOW}Running frontend tests only...${NC}"
        run_frontend_tests
        ;;
    --integration-only)
        echo -e "${YELLOW}Running integration tests only...${NC}"
        test_integration
        ;;
    --help)
        show_help
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

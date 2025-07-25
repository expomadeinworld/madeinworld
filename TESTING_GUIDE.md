# Orders Management System Testing Guide

This guide covers comprehensive testing for the Made in World Orders Management System, including backend API endpoints and frontend E2E functionality.

## Overview

The testing suite includes:
- **Backend API Tests**: Order service admin endpoints
- **Frontend E2E Tests**: Admin panel orders management UI
- **Integration Tests**: Service communication and data flow
- **Performance Tests**: Load and response time validation

## Prerequisites

### Required Services
1. **Order Service** (Port 8082)
   ```bash
   cd backend/order-service
   go run cmd/server/main.go
   ```

2. **Auth Service** (Port 8081) - Optional but recommended
   ```bash
   cd backend/auth-service
   go run cmd/server/main.go
   ```

3. **Admin Panel** (Port 3000)
   ```bash
   cd admin-panel
   npm start
   ```

### Test Dependencies
- Go 1.23+ (for backend tests)
- Node.js 18+ (for frontend tests)
- Playwright (automatically installed)
- PostgreSQL database with test data

## Quick Start

### Run All Tests
```bash
./test_orders_system.sh
```

### Run Specific Test Suites
```bash
# Backend API tests only
./test_orders_system.sh --backend-only

# Frontend E2E tests only
./test_orders_system.sh --frontend-only

# Integration tests only
./test_orders_system.sh --integration-only
```

## Test Coverage

### Backend API Tests (`backend/order-service/test_endpoints.sh`)

#### Admin Endpoints Tested:
- `GET /api/admin/orders` - List orders with filtering
- `GET /api/admin/orders/:id` - Get order details
- `PUT /api/admin/orders/:id/status` - Update order status
- `DELETE /api/admin/orders/:id` - Cancel order
- `POST /api/admin/orders/bulk-update` - Bulk status updates
- `GET /api/admin/orders/statistics` - Order statistics

#### Authentication Tests:
- JWT token validation
- Admin header requirement (`X-Admin-Request: true`)
- Unauthorized access rejection

#### Filter and Pagination Tests:
- Status filtering (pending, confirmed, processing, shipped, delivered, cancelled)
- Mini-app type filtering (RetailStore, UnmannedStore, ExhibitionSales, GroupBuying)
- Date range filtering
- Search functionality
- Pagination controls

### Frontend E2E Tests (`admin-panel/tests/orders-management.spec.js`)

#### UI Component Tests:
- Orders table display and columns
- Filter controls functionality
- Search input behavior
- Pagination controls

#### User Interaction Tests:
- Order details modal opening/closing
- Bulk selection and updates
- Status change workflows
- Error handling and validation

#### Data Integration Tests:
- Real statistics display (replacing mock data)
- Filter state persistence
- Navigation between pages
- Admin access validation

## Test Data Requirements

### Database Setup
Ensure your test database contains:
- Sample users with different roles
- Products across all mini-app types
- Orders in various statuses
- Store locations for location-based mini-apps

### Sample Test Data
```sql
-- Sample orders for testing
INSERT INTO orders (user_id, mini_app_type, total_amount, status, store_id) VALUES
('test-user-1', 'RetailStore', 25.99, 'pending', NULL),
('test-user-2', 'UnmannedStore', 45.50, 'confirmed', 1),
('test-user-3', 'ExhibitionSales', 78.25, 'processing', 2),
('test-user-4', 'GroupBuying', 120.00, 'shipped', NULL);
```

## Running Individual Tests

### Backend API Tests
```bash
cd backend/order-service
chmod +x test_endpoints.sh
./test_endpoints.sh
```

### Frontend E2E Tests
```bash
cd admin-panel
npx playwright test tests/orders-management.spec.js
```

### Specific Playwright Tests
```bash
# Run with UI mode for debugging
npx playwright test tests/orders-management.spec.js --ui

# Run specific test
npx playwright test tests/orders-management.spec.js -g "should display orders list"

# Run with detailed reporting
npx playwright test tests/orders-management.spec.js --reporter=html
```

## Debugging Failed Tests

### Backend Test Failures
1. **Service Not Running**: Ensure order-service is running on port 8082
2. **Database Connection**: Check PostgreSQL connection and schema
3. **Authentication Issues**: Verify JWT secret matches between services
4. **Missing Test Data**: Ensure database has sample orders and users

### Frontend Test Failures
1. **Admin Panel Not Running**: Start with `npm start` in admin-panel directory
2. **Network Issues**: Check if backend services are accessible
3. **Element Not Found**: UI may have changed, update selectors
4. **Timing Issues**: Increase wait times for slow-loading components

### Common Issues and Solutions

#### "Auth service not available"
```bash
# Start auth service
cd backend/auth-service
go run cmd/server/main.go
```

#### "No orders found for testing"
```bash
# Add sample orders to database
psql -d madeinworld_db -f database/sample_orders.sql
```

#### "Admin panel not accessible"
```bash
# Install dependencies and start
cd admin-panel
npm install
npm start
```

## Test Environment Configuration

### Environment Variables
```bash
# Order Service
ORDER_PORT=8082
DB_HOST=localhost
DB_PORT=5432
DB_USER=madeinworld_admin
DB_PASSWORD=your_password
DB_NAME=madeinworld_db
JWT_SECRET=your_jwt_secret

# Auth Service
AUTH_PORT=8081
JWT_SECRET=your_jwt_secret  # Must match order service
```

### Test Configuration Files
- `backend/order-service/.env` - Backend service configuration
- `admin-panel/.env` - Frontend environment variables
- `playwright.config.js` - Playwright test configuration

## Continuous Integration

### GitHub Actions Setup
```yaml
name: Orders Management Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Go
        uses: actions/setup-go@v3
        with:
          go-version: 1.23
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
      - name: Run Tests
        run: ./test_orders_system.sh
```

## Performance Testing

### Load Testing
```bash
# Test order listing endpoint
ab -n 100 -c 10 -H "Authorization: Bearer token" -H "X-Admin-Request: true" \
   http://localhost:8082/api/admin/orders

# Test statistics endpoint
ab -n 50 -c 5 -H "Authorization: Bearer token" -H "X-Admin-Request: true" \
   http://localhost:8082/api/admin/orders/statistics
```

### Response Time Benchmarks
- Order listing: < 500ms for 1000 orders
- Order details: < 200ms
- Statistics calculation: < 1000ms
- Bulk updates: < 2000ms for 100 orders

## Troubleshooting

### Test Execution Issues
1. **Permission Denied**: Run `chmod +x test_orders_system.sh`
2. **Port Conflicts**: Check if services are running on correct ports
3. **Database Errors**: Verify database connection and schema
4. **Browser Issues**: Update Playwright browsers with `npx playwright install`

### Getting Help
- Check service logs for detailed error messages
- Review test output for specific failure points
- Ensure all prerequisites are met
- Verify test data exists in database

## Contributing

When adding new tests:
1. Follow existing test patterns and naming conventions
2. Add both positive and negative test cases
3. Include proper error handling tests
4. Update this documentation with new test coverage
5. Ensure tests are idempotent and can run multiple times

## Test Reports

Test results are available in:
- Console output (real-time)
- `admin-panel/test-results/` (Playwright HTML reports)
- `admin-panel/playwright-report/` (Detailed test reports)

View HTML reports:
```bash
cd admin-panel
npx playwright show-report
```

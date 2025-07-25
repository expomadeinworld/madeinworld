# User Service

The User Service is a Go-based microservice that provides comprehensive user management functionality for the Made in World admin panel. It handles user CRUD operations, role management, and user analytics with JWT authentication.

## Features

- **User Management**: Complete CRUD operations for user accounts
- **Role Management**: Handle user roles (Customer, Admin, Manufacturer, 3PL, Partner)
- **User Analytics**: Track user statistics, registration trends, and activity
- **Admin Authentication**: JWT-protected endpoints for admin access only
- **Search & Filtering**: Advanced user search and filtering capabilities
- **Bulk Operations**: Bulk user status updates and notifications
- **Health Checks**: Service health monitoring endpoint

## API Endpoints

### User Management Endpoints

#### GET /api/admin/users
Get all users with pagination, search, and filtering.

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `search` - Search term (searches name, email, phone)
- `role` - Filter by user role
- `status` - Filter by user status (active/inactive)
- `sort` - Sort field (created_at, last_login, full_name)
- `order` - Sort order (asc/desc)

#### GET /api/admin/users/{user_id}
Get specific user details including order history and statistics.

#### PUT /api/admin/users/{user_id}
Update user information (admin only).

#### DELETE /api/admin/users/{user_id}
Soft delete user account (admin only).

#### POST /api/admin/users/{user_id}/status
Update user status (active/inactive/suspended).

#### GET /api/admin/users/analytics
Get user analytics and statistics.

#### POST /api/admin/users/bulk-update
Perform bulk operations on multiple users.

### Health Check
- `GET /health` - Service health monitoring

## Database Schema

The service uses the existing `users` table:

```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    avatar_url VARCHAR(500),
    role user_role NOT NULL DEFAULT 'Customer',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## Setup Instructions

### Prerequisites
- Go 1.23 or later
- PostgreSQL database with Made in World schema
- Auth service running (for JWT validation)
- Environment variables configured

### Running the Service

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and JWT secret
   ```

2. **Start the service:**
   ```bash
   go mod tidy
   go run cmd/server/main.go
   ```

3. **Verify startup:**
   ```bash
   curl http://localhost:8083/health
   ```

### Testing the API

1. **Get JWT token from auth service:**
   ```bash
   JWT_TOKEN=$(curl -s -X POST \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@example.com","password":"password"}' \
     http://localhost:8081/api/auth/login | jq -r '.token')
   ```

2. **Test user listing:**
   ```bash
   curl -H "Authorization: Bearer $JWT_TOKEN" \
        -H "X-Admin-Request: true" \
        http://localhost:8083/api/admin/users
   ```

## Integration with Admin Panel

The service integrates with the React-based admin panel through:
- RESTful API endpoints
- JWT authentication
- Standardized response formats
- Error handling and validation
- CORS support for web requests

## Security Considerations

- All admin endpoints require valid JWT tokens
- Admin role verification for sensitive operations
- Input validation and sanitization
- SQL injection protection through parameterized queries
- Rate limiting and request validation
- Comprehensive audit logging for admin actions

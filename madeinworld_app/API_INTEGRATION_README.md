# Made in World App - API Integration Guide

This document describes the transition from mock data to live API integration for the Made in World Flutter application.

## Overview

The app has been successfully refactored to use live data from the deployed Catalog Service instead of the previous mock data service. This enables real-time product information, inventory tracking, and dynamic content management.

## Changes Made

### 1. New API Service (`lib/data/services/api_service.dart`)

- **Purpose**: Replaces `mock_data_service.dart` with HTTP-based API calls
- **Features**:
  - Fetches products with filtering (store type, featured status, store-specific inventory)
  - Retrieves categories with store type associations
  - Gets store information and locations
  - Comprehensive error handling with custom `ApiException`
  - Configurable timeouts and retry mechanisms

### 2. Updated Data Models

**Product Model** (`lib/data/models/product.dart`):
- Enhanced `fromJson` to handle integer IDs from API (converted to strings for compatibility)
- Improved case-insensitive enum parsing
- Better null safety for arrays

**Category Model** (`lib/data/models/category.dart`):
- Updated to handle API response format
- Case-insensitive store type association parsing

**Store Model** (`lib/data/models/store.dart`):
- Integer ID conversion for API compatibility
- Enhanced type parsing

### 3. UI Updates with FutureBuilder Pattern

**HomeScreen** (`lib/presentation/screens/main/home_screen.dart`):
- Replaced direct mock data calls with `FutureBuilder<List<Product>>`
- Added loading, error, and empty states for featured products
- Retry functionality for failed API calls
- Graceful error handling with user-friendly messages

**UnmannedStoreScreen** (`lib/presentation/screens/mini_apps/unmanned_store/unmanned_store_screen.dart`):
- Implemented `FutureBuilder` for both categories and products
- Combined API calls using `Future.wait()` for efficiency
- Category filtering works with live data
- Loading and error states for better UX

**RetailStoreScreen** (`lib/presentation/screens/mini_apps/retail_store/retail_store_screen.dart`):
- Similar FutureBuilder implementation as unmanned store
- Retail-specific product and category filtering
- Consistent error handling across mini-apps

### 4. Configuration Management

**API Configuration** (`lib/core/config/api_config.dart`):
- Centralized API endpoint configuration
- Environment-specific base URLs (development, staging, production)
- Easy switching between local development and deployed services
- Debug information for troubleshooting

### 5. Dependencies

**Added to `pubspec.yaml`**:
```yaml
http: ^1.1.0  # For HTTP API calls
```

## Configuration

### Setting the API Base URL

1. **For Development** (local testing):
   ```dart
   // In lib/core/config/api_config.dart
   static const bool _isDevelopment = true;
   static const String _devBaseUrl = 'http://localhost:8080';
   ```

2. **For Production** (deployed service):
   ```dart
   // In lib/core/config/api_config.dart
   static const bool _isDevelopment = false;
   static const String _prodBaseUrl = 'http://your-loadbalancer-url.com';
   ```

3. **Update with actual LoadBalancer URL**:
   After deploying the Catalog Service to EKS, get the LoadBalancer URL:
   ```bash
   kubectl get service catalog-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```
   Then update `_prodBaseUrl` in the configuration.

## API Endpoints Used

The Flutter app now calls these Catalog Service endpoints:

- `GET /api/v1/products` - Get all products with optional filtering
  - Query params: `store_type`, `featured`, `store_id`
- `GET /api/v1/products/:id` - Get specific product
- `GET /api/v1/categories` - Get categories with optional store type filtering
- `GET /api/v1/stores` - Get stores with optional type filtering
- `GET /health` - Service health check

## Error Handling

### API Exception Types
- **Network errors**: No internet connection
- **HTTP errors**: 4xx/5xx status codes
- **Parsing errors**: Invalid JSON response
- **Timeout errors**: Request timeout exceeded

### User Experience
- **Loading states**: Circular progress indicators during API calls
- **Error states**: User-friendly error messages with retry buttons
- **Empty states**: Appropriate messaging when no data is available
- **Graceful degradation**: App continues to function even if some API calls fail

## Testing the Integration

### 1. Local Development
```bash
# Start the Go service locally
cd backend/catalog-service
go run cmd/server/main.go

# Update API config to use localhost
# Set _isDevelopment = true in api_config.dart

# Run Flutter app
cd madeinworld_app
flutter run
```

### 2. Production Testing
```bash
# Update API config with production URL
# Set _isDevelopment = false in api_config.dart
# Update _prodBaseUrl with actual LoadBalancer URL

# Build and test
flutter run --release
```

### 3. Health Check
The app includes a health check method to verify API connectivity:
```dart
final apiService = ApiService();
bool isHealthy = await apiService.checkHealth();
```

## Data Flow

### Before (Mock Data)
```
UI → MockDataService → Static Data → UI
```

### After (Live API)
```
UI → ApiService → HTTP Request → Catalog Service → PostgreSQL → Response → UI
```

## Performance Considerations

### Caching Strategy
- **Future caching**: API calls are cached in `Future` variables during widget lifecycle
- **Refresh mechanism**: Pull-to-refresh or retry buttons trigger new API calls
- **State management**: Consider implementing Provider or Riverpod for global state management

### Optimization Opportunities
1. **Implement caching**: Add local storage for frequently accessed data
2. **Pagination**: For large product lists
3. **Image optimization**: Lazy loading and caching for product images
4. **Offline support**: Cache critical data for offline viewing

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if Catalog Service is running
   - Verify base URL in configuration
   - Ensure network connectivity

2. **CORS Errors** (Web platform)
   - Catalog Service includes CORS headers
   - Check browser developer tools for specific errors

3. **Parsing Errors**
   - Verify API response format matches model expectations
   - Check for null values in required fields

4. **Timeout Issues**
   - Increase timeout duration in `ApiService`
   - Check network latency to service

### Debug Information
```dart
// Print API configuration
print(ApiConfig.debugInfo);

// Enable HTTP logging (add to main.dart)
import 'package:http/http.dart' as http;
// Add logging interceptor for debugging
```

## Next Steps

### Immediate
1. **Deploy infrastructure**: Follow Terraform deployment guide
2. **Update API URL**: Set production LoadBalancer URL in configuration
3. **Test end-to-end**: Verify all features work with live data

### Future Enhancements
1. **Authentication**: Add user authentication and JWT tokens
2. **Real-time updates**: WebSocket integration for live inventory updates
3. **Offline support**: Local database with sync capabilities
4. **Performance monitoring**: Add analytics and crash reporting
5. **Push notifications**: Integration with notification service

## Migration Checklist

- [x] Create API service with HTTP client
- [x] Update data models for API compatibility
- [x] Implement FutureBuilder in HomeScreen
- [x] Update UnmannedStoreScreen with live data
- [x] Update RetailStoreScreen with live data
- [x] Add error handling and loading states
- [x] Create configuration management
- [x] Add retry mechanisms
- [x] Remove mock data service dependencies
- [ ] Deploy backend infrastructure
- [ ] Update production API URL
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] User acceptance testing

## Support

For issues related to:
- **Backend API**: Check Catalog Service logs and health endpoint
- **Flutter integration**: Review API service error handling and network connectivity
- **Data inconsistencies**: Verify database schema and API response format

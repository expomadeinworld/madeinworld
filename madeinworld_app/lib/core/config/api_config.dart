/// API Configuration for Made in World App
///
/// This file contains configuration settings for the API service.
/// Update the base URL here when deploying to different environments.
library;

class ApiConfig {
  // Development/Testing Configuration
  static const String _devBaseUrl = 'http://localhost:8080';

  // Production Configuration (commented out for local development)
  // Update this with your actual LoadBalancer URL after deployment
  static const String _prodBaseUrl = 'https://api.expomadeinworld.com';

  // Current environment - change this for different builds
  // Set to true to use local development server (localhost:8080)
  // Set to false to use production server (api.expomadeinworld.com)
  static const bool _isDevelopment = true;
  
  /// Get the current base URL based on environment
  static String get baseUrl => _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  
  /// API version path
  static const String apiVersion = '/api/v1';
  
  /// Full API base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  /// Health check timeout
  static const Duration healthTimeout = Duration(seconds: 10);
  
  /// Common HTTP headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Update configuration for different environments
  static void setEnvironment({required bool isDevelopment}) {
    // This would require a more sophisticated approach in a real app
    // For now, manually change _isDevelopment above
  }
  
  /// Get configuration info for debugging
  static Map<String, dynamic> get debugInfo => {
    'baseUrl': baseUrl,
    'apiBaseUrl': apiBaseUrl,
    'isDevelopment': _isDevelopment,
    'timeout': timeout.inSeconds,
  };
}

/// Environment-specific configurations
class EnvironmentConfig {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  /// Configuration for different environments
  static const Map<String, String> baseUrls = {
    development: 'http://localhost:8080',
    staging: 'http://staging-loadbalancer-url.com',
    production: 'http://production-loadbalancer-url.com',
  };
  
  /// Get base URL for specific environment
  static String getBaseUrl(String environment) {
    return baseUrls[environment] ?? baseUrls[development]!;
  }
}

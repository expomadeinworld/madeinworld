import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../../core/enums/store_type.dart';


class ApiService {
  // Base URL for the catalog service
  // This will be the ALB URL created by the Kubernetes ingress
  // Replace with actual ALB URL after deployment: kubectl get ingress
  static const String _baseUrl = 'https://api.madeinworld.com';
  static const String _apiVersion = '/api/v1';

  // Timeout duration for HTTP requests
  static const Duration _timeout = Duration(seconds: 30);

  // HTTP client instance
  static final http.Client _client = http.Client();

  /// Fetches all products from the API
  /// 
  /// [storeType] - Filter products by store type (optional)
  /// [featured] - Filter only featured products (optional)
  /// [storeId] - Get stock for specific store (optional, for unmanned stores)
  Future<List<Product>> fetchProducts({
    StoreType? storeType,
    bool? featured,
    String? storeId,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      
      if (storeType != null) {
        queryParams['store_type'] = storeType.toString().split('.').last;
      }
      
      if (featured != null) {
        queryParams['featured'] = featured.toString();
      }
      
      if (storeId != null) {
        queryParams['store_id'] = storeId;
      }

      // Build URI
      final uri = Uri.parse('$_baseUrl$_apiVersion/products')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make HTTP request
      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Product.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch products: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on http.ClientException {
      throw ApiException('Network error occurred', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  /// Fetches a specific product by ID
  /// 
  /// [productId] - The ID of the product to fetch
  /// [storeId] - Get stock for specific store (optional, for unmanned stores)
  Future<Product> fetchProduct(String productId, {String? storeId}) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (storeId != null) {
        queryParams['store_id'] = storeId;
      }

      // Build URI
      final uri = Uri.parse('$_baseUrl$_apiVersion/products/$productId')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make HTTP request
      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Product.fromJson(json);
      } else if (response.statusCode == 404) {
        throw ApiException('Product not found', 404);
      } else {
        throw ApiException(
          'Failed to fetch product: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on http.ClientException {
      throw ApiException('Network error occurred', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  /// Fetches all categories from the API
  /// 
  /// [storeType] - Filter categories by store type association (optional)
  Future<List<Category>> fetchCategories({StoreType? storeType}) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (storeType != null) {
        queryParams['store_type'] = storeType.toString().split('.').last;
      }

      // Build URI
      final uri = Uri.parse('$_baseUrl$_apiVersion/categories')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make HTTP request
      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Category.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch categories: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on http.ClientException {
      throw ApiException('Network error occurred', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  /// Fetches all stores from the API
  /// 
  /// [storeType] - Filter stores by type (optional)
  Future<List<Store>> fetchStores({StoreType? storeType}) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (storeType != null) {
        queryParams['type'] = storeType.toString().split('.').last;
      }

      // Build URI
      final uri = Uri.parse('$_baseUrl$_apiVersion/stores')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make HTTP request
      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Store.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch stores: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on http.ClientException {
      throw ApiException('Network error occurred', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  /// Checks the health of the API service
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to get common HTTP headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Dispose the HTTP client
  static void dispose() {
    _client.close();
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Configuration class for API settings
class ApiConfig {
  static String baseUrl = 'https://api.madeinworld.com';
  
  /// Update the base URL for the API service
  static void setBaseUrl(String url) {
    baseUrl = url;
  }
  
  /// Get the current base URL
  static String getBaseUrl() {
    return baseUrl;
  }
}

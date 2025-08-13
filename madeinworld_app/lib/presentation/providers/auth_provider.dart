import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';

/// Authentication provider for managing user authentication state
class AuthProvider extends ChangeNotifier {
  // Secure storage for JWT tokens
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Auth service instance
  final AuthService _authService = AuthService();

  // Current authentication state
  AuthState _state = const AuthState.unknown();

  /// Get current authentication state
  AuthState get state => _state;

  /// Get current user (null if not authenticated)
  User? get user => _state.user;

  /// Get current token (null if not authenticated)
  String? get token => _state.token;

  /// Check if user is authenticated
  bool get isAuthenticated => _state.isAuthenticated;

  /// Check if authentication is loading
  bool get isLoading => _state.isLoading;

  /// Check if user is unauthenticated
  bool get isUnauthenticated => _state.isUnauthenticated;

  /// Get error message if any
  String? get errorMessage => _state.errorMessage;

  /// Initialize authentication state on app startup
  Future<void> initialize() async {
    debugPrint('AuthProvider: Initializing authentication state...');
    
    _updateState(const AuthState.loading());

    try {
      // Check if we have a stored token
      final storedToken = await _secureStorage.read(key: _tokenKey);
      
      if (storedToken == null) {
        debugPrint('AuthProvider: No stored token found');
        _updateState(const AuthState.unauthenticated());
        return;
      }

      debugPrint('AuthProvider: Found stored token, validating...');

      // Validate the stored token
      await _authService.validateToken(storedToken);
      
      // Get stored user data
      final storedUserJson = await _secureStorage.read(key: _userKey);
      if (storedUserJson == null) {
        debugPrint('AuthProvider: No stored user data found');
        await _clearStoredAuth();
        _updateState(const AuthState.unauthenticated());
        return;
      }

      // Parse stored user data from JSON
      final userData = json.decode(storedUserJson) as Map<String, dynamic>;
      final user = User.fromJson(userData);

      debugPrint('AuthProvider: Token validation successful for user: ${user.email}');
      
      _updateState(AuthState.authenticated(user: user, token: storedToken));
    } catch (e) {
      debugPrint('AuthProvider: Token validation failed: $e');
      await _clearStoredAuth();
      _updateState(const AuthState.unauthenticated());
    }
  }

  /// Send verification code to email (passwordless authentication)
  Future<void> sendVerificationCode(String email) async {
    debugPrint('AuthProvider: Sending verification code to email: $email');

    _updateState(const AuthState.loading());

    try {
      await _authService.sendVerificationCode(email);

      debugPrint('AuthProvider: Verification code sent successfully to: $email');

      // Return to unauthenticated state but without error (waiting for code verification)
      _updateState(const AuthState.unauthenticated());
    } catch (e) {
      debugPrint('AuthProvider: Failed to send verification code: $e');
      _updateState(AuthState.unauthenticated(errorMessage: e.toString()));
      // Re-throw the exception so the UI can handle it
      rethrow;
    }
  }

  /// Verify email code and authenticate user (passwordless authentication)
  Future<void> verifyEmailCode(String email, String code) async {
    debugPrint('AuthProvider: Verifying code for email: $email');

    _updateState(const AuthState.loading());

    try {
      final response = await _authService.verifyEmailCode(email, code);

      // Store authentication data
      await _storeAuthData(response.token, response.user);

      debugPrint('AuthProvider: Email verification successful for user: ${response.user.email}');

      _updateState(AuthState.authenticated(
        user: response.user,
        token: response.token,
      ));
    } catch (e) {
      debugPrint('AuthProvider: Email verification failed: $e');
      _updateState(AuthState.unauthenticated(errorMessage: e.toString()));
      // Re-throw the exception so the UI can handle it
      rethrow;
    }
  }

  /// Sign up a new user (DEPRECATED - use email verification instead)
  @Deprecated('Use sendVerificationCode and verifyEmailCode instead')
  Future<void> signup({
    required String username,
    required String email,
    required String password,
    String? phone,
    String? firstName,
    String? lastName,
  }) async {
    debugPrint('AuthProvider: Starting signup for email: $email (DEPRECATED)');

    _updateState(const AuthState.loading());

    try {
      final request = SignupRequest(
        username: username,
        email: email,
        password: password,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );

      final response = await _authService.signup(request);

      // Store authentication data
      await _storeAuthData(response.token, response.user);

      debugPrint('AuthProvider: Signup successful for user: ${response.user.email}');

      _updateState(AuthState.authenticated(
        user: response.user,
        token: response.token,
      ));
    } catch (e) {
      debugPrint('AuthProvider: Signup failed: $e');
      _updateState(AuthState.unauthenticated(errorMessage: e.toString()));
    }
  }

  /// Log in an existing user (DEPRECATED - use email verification instead)
  @Deprecated('Use sendVerificationCode and verifyEmailCode instead')
  Future<void> login({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthProvider: Starting login for email: $email (DEPRECATED)');

    _updateState(const AuthState.loading());

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);

      // Store authentication data
      await _storeAuthData(response.token, response.user);

      debugPrint('AuthProvider: Login successful for user: ${response.user.email}');

      _updateState(AuthState.authenticated(
        user: response.user,
        token: response.token,
      ));
    } catch (e) {
      debugPrint('AuthProvider: Login failed: $e');
      _updateState(AuthState.unauthenticated(errorMessage: e.toString()));
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    debugPrint('AuthProvider: Logging out user');
    
    _updateState(const AuthState.loading());
    
    try {
      await _clearStoredAuth();
      _updateState(const AuthState.unauthenticated());
      debugPrint('AuthProvider: Logout successful');
    } catch (e) {
      debugPrint('AuthProvider: Logout error: $e');
      // Even if clearing storage fails, we should still log out
      _updateState(const AuthState.unauthenticated());
    }
  }

  /// Clear any error messages
  void clearError() {
    if (_state.errorMessage != null) {
      _updateState(_state.copyWith(errorMessage: null));
    }
  }

  /// Store authentication data securely
  Future<void> _storeAuthData(String token, User user) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userKey, value: json.encode(user.toJson()));
      debugPrint('AuthProvider: Authentication data stored successfully');
    } catch (e) {
      debugPrint('AuthProvider: Failed to store auth data: $e');
      throw Exception('Failed to store authentication data');
    }
  }

  /// Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
      debugPrint('AuthProvider: Stored authentication data cleared');
    } catch (e) {
      debugPrint('AuthProvider: Failed to clear auth data: $e');
    }
  }

  /// Update authentication state and notify listeners
  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
    debugPrint('AuthProvider: State updated to: ${newState.status}');
  }


}

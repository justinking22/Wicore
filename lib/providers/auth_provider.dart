import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, needsConfirmation }

class AuthService with ChangeNotifier {
  final String _baseUrl;
  AuthStatus _authStatus = AuthStatus.unknown;
  Map<String, dynamic>? _userData;
  String? _token;
  String? _confirmationEmail;

  // Constructor with base URL
  AuthService({required String baseUrl}) : _baseUrl = baseUrl;

  // Getters
  AuthStatus get authStatus => _authStatus;
  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;
  String? get confirmationEmail => _confirmationEmail;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  // INITIALIZATION
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccessToken = prefs.getString('access_token');
    final savedRefreshToken = prefs.getString('refresh_token');
    final expirationString = prefs.getString('token_expiration');
    final username = prefs.getString('username');
    final id = prefs.getString('id');

    if (savedAccessToken != null) {
      // Check if token is expired
      if (expirationString != null) {
        final expirationTime = DateTime.parse(expirationString);
        if (DateTime.now().isAfter(expirationTime)) {
          // Token expired, try to refresh it
          if (savedRefreshToken != null && savedRefreshToken.isNotEmpty) {
            final refreshResult = await _refreshToken(savedRefreshToken);
            if (refreshResult) {
              return; // Successfully refreshed
            }
          }

          // Failed to refresh, clear tokens
          await _clearAuthData();
          _authStatus = AuthStatus.unauthenticated;
          notifyListeners();
          return;
        }
      }

      // Token exists and is not expired
      _token = savedAccessToken;
      _userData = {
        'username': username,
        'id': id,
        'accessToken': savedAccessToken,
        'refreshToken': savedRefreshToken,
      };
      _authStatus = AuthStatus.authenticated;
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  void clearConfirmationState() {
    _confirmationEmail = null;
    if (_authStatus == AuthStatus.needsConfirmation) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // AUTHENTICATION METHODS
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData['data'] != null) {
          final data = responseData['data'];
          final code = responseData['code'];
          final String? id = data['id'];

          if (kDebugMode) {
            print('SignUp Response: $data');
          }

          // Save user ID to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id', id ?? '');

          // Check if account needs confirmation
          final isConfirmed = data['confirmed'] == true;

          if (!isConfirmed) {
            _authStatus = AuthStatus.needsConfirmation;
            _confirmationEmail = email;
            notifyListeners();

            return {
              'success': true,
              'requiresConfirmation': true,
              'message':
                  'Account created successfully. Please check your email for confirmation code.',
              'code': code,
              'userId': data['id'],
            };
          } else {
            return {
              'success': true,
              'requiresConfirmation': false,
              'message': 'Account created successfully. Please sign in.',
              'code': code,
              'userId': data['id'],
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response from server - no data received',
            'code': responseData['code'],
          };
        }
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Registration failed - invalid data provided',
          'code': responseData['code'],
          'errors': responseData['errors'],
        };
      } else if (response.statusCode == 409) {
        return {
          'success': false,
          'message': 'An account with this email already exists',
          'code': responseData['code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'code': responseData['code'],
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during signup: $e');
      }
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null) {
          final data = responseData['data'];

          if (kDebugMode) {
            print('Login Response: $data');
          }

          final accessToken = data['accessToken'];
          final refreshToken = data['refreshToken'];
          final expiresIn = data['expiresIn'];
          final username = data['username'];

          if (accessToken != null) {
            // Save authentication data to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('access_token', accessToken);
            await prefs.setString('refresh_token', refreshToken ?? '');
            await prefs.setInt('expires_in', expiresIn ?? 43200);
            await prefs.setString('username', username ?? '');

            // Calculate and save expiration time
            final expirationTime = DateTime.now().add(
              Duration(seconds: expiresIn ?? 43200),
            );
            await prefs.setString(
              'token_expiration',
              expirationTime.toIso8601String(),
            );

            // Set internal auth state
            _token = accessToken;
            _userData = {
              'username': username,
              'id': username,
              'accessToken': accessToken,
              'refreshToken': refreshToken,
              'expiresIn': expiresIn,
            };
            _authStatus = AuthStatus.authenticated;
            notifyListeners();

            if (kDebugMode) {
              print('✅ Login successful, tokens saved');
              print('Access Token: ${accessToken.substring(0, 20)}...');
              print(
                'Refresh Token: ${refreshToken?.substring(0, 20) ?? 'none'}...',
              );
              print('Expires in: $expiresIn seconds');
            }

            return {
              'success': true,
              'message': 'Login successful',
              'data': data,
              'code': responseData['code'],
            };
          } else {
            return {
              'success': false,
              'message': 'No access token received from server',
              'code': responseData['code'],
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid response from server - no data received',
            'code': responseData['code'],
          };
        }
      } else if (response.statusCode == 401) {
        final message = responseData['message'] ?? 'Invalid email or password';
        final code = responseData['code'];

        // Check if account needs confirmation
        if (message.toLowerCase().contains('confirm') ||
            message.toLowerCase().contains('verification') ||
            message.toLowerCase().contains('not confirmed')) {
          _confirmationEmail = email;
          _authStatus = AuthStatus.needsConfirmation;
          notifyListeners();

          return {
            'success': false,
            'requiresConfirmation': true,
            'message': message,
            'code': code,
          };
        }

        return {'success': false, 'message': message, 'code': code};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
          'code': responseData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> signOut() async {
    try {
      // Call logout endpoint if available
      if (_token != null) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/auth/logout'),
            headers: {
              'Authorization': 'Bearer $_token',
              'Content-Type': 'application/json',
            },
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error calling logout endpoint: $e');
          }
        }
      }

      // Clear local auth state
      await _clearAuthData();
      _authStatus = AuthStatus.unauthenticated; // Don't set to unknown
      notifyListeners();

      if (kDebugMode) {
        print('✅ Signed out successfully');
      }

      return {'success': true, 'message': 'Signed out successfully'};
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
      // Even on error, clear local state
      await _clearAuthData();
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();

      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // PASSWORD RESET METHODS
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _confirmationEmail = email;
        notifyListeners();

        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Password reset code sent to your email',
          'code': responseData['code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send reset code',
          'code': responseData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting password reset: $e');
      }
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> resendConfirmationCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-confirmation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _confirmationEmail = email;
        notifyListeners();

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Confirmation code sent to $email',
          'code': responseData['code'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to resend confirmation code',
          'code': responseData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resending confirmation code: $e');
      }
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> confirmResetPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
          'confirmationCode': confirmationCode,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _confirmationEmail = null;
        notifyListeners();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
          'code': responseData['code'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
          'code': responseData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming password reset: $e');
      }
      return {
        'success': false,
        'message': 'Network error occurred. Please try again.',
      };
    }
  }

  // TOKEN MANAGEMENT METHODS
  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refreshtoken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['data'] != null) {
          final data = responseData['data'];
          final newAccessToken = data['accessToken'];
          final newRefreshToken = data['refreshToken'];
          final expiresIn = data['expiresIn'];

          if (newAccessToken != null) {
            // Save new tokens
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('access_token', newAccessToken);
            if (newRefreshToken != null) {
              await prefs.setString('refresh_token', newRefreshToken);
            }
            await prefs.setInt('expires_in', expiresIn ?? 43200);

            // Calculate and save new expiration time
            final expirationTime = DateTime.now().add(
              Duration(seconds: expiresIn ?? 43200),
            );
            await prefs.setString(
              'token_expiration',
              expirationTime.toIso8601String(),
            );

            // Update internal state
            _token = newAccessToken;
            _authStatus = AuthStatus.authenticated;

            if (kDebugMode) {
              print('✅ Token refreshed successfully');
            }

            return true;
          }
        }
      }

      if (kDebugMode) {
        print('❌ Failed to refresh token');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
      return false;
    }
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_in');
    await prefs.remove('username');
    await prefs.remove('id');
    await prefs.remove('token_expiration');

    _token = null;
    _userData = null;
  }

  // API REQUEST METHOD
  Future<Map<String, dynamic>> makeAuthenticatedRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    if (_token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    // Check if token is expired and try to refresh
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString('token_expiration');
    if (expirationString != null) {
      final expirationTime = DateTime.parse(expirationString);
      if (DateTime.now().isAfter(expirationTime)) {
        final refreshToken = prefs.getString('refresh_token');
        if (refreshToken != null) {
          final refreshResult = await _refreshToken(refreshToken);
          if (!refreshResult) {
            return {
              'success': false,
              'message': 'Authentication expired. Please sign in again.',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Authentication expired. Please sign in again.',
          };
        }
      }
    }

    try {
      Uri uri = Uri.parse('$_baseUrl/$endpoint');

      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;

      final headers = {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

      // Make HTTP request based on method
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        default:
          return {
            'success': false,
            'message': 'Unsupported HTTP method: $method',
          };
      }

      // Handle 401 responses
      if (response.statusCode == 401) {
        final refreshToken = prefs.getString('refresh_token');
        if (refreshToken != null) {
          final refreshResult = await _refreshToken(refreshToken);
          if (refreshResult) {
            // Retry the request with new token
            return await makeAuthenticatedRequest(
              endpoint: endpoint,
              method: method,
              body: body,
              queryParams: queryParams,
            );
          }
        }

        // Failed to refresh, clear auth data but don't set to unknown
        await _clearAuthData();
        _authStatus = AuthStatus.unauthenticated; // Changed from unknown
        notifyListeners();

        return {
          'success': false,
          'message': 'Authentication expired. Please sign in again.',
          'statusCode': response.statusCode,
        };
      }
      // Parse response body
      dynamic responseData;
      if (response.body.isNotEmpty) {
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          responseData = response.body;
        }
      }

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error making authenticated request: $e');
      }
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:Wicore/repository/auth_repository.dart';
import 'package:Wicore/services/config_service.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_api_client.dart';
import '../services/token_storage_service.dart';
import '../models/user_model.dart';
import '../models/sign_up_response_model.dart';
import '../models/sign_in_response_model.dart';
import '../models/refresh_token_response_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/resend_confirmation_response_model.dart';
import '../models/change_password_response_model.dart';

// Basic Dio provider without auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

// Token refresh manager to handle proactive token refresh
class TokenRefreshManager {
  Timer? _refreshTimer;
  final TokenStorageService _tokenStorage;
  final VoidCallback _onRefreshNeeded;

  TokenRefreshManager(this._tokenStorage, this._onRefreshNeeded);

  void startTokenRefreshTimer() {
    _cancelTimer();
    _scheduleNextRefresh();
  }

  void _cancelTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _scheduleNextRefresh() async {
    try {
      // Use the stored expiryDate from TokenStorageService
      final expiryDate = await _tokenStorage.getTokenExpiryDate();
      if (expiryDate == null) {
        if (kDebugMode)
          print('🔄 No expiry date found, cannot schedule refresh');
        return;
      }

      final now = DateTime.now();
      final expiry = DateTime.parse(expiryDate);

      // Schedule refresh 2 minutes before expiry, but at least 30 seconds from now
      final refreshTime = expiry.subtract(const Duration(minutes: 2));
      final timeUntilRefresh = refreshTime.difference(now);

      if (kDebugMode) {
        print('🔄 Token refresh scheduling:');
        print('   Current time: $now');
        print('   Token expires: $expiry');
        print('   Refresh scheduled for: $refreshTime');
        print('   Time until refresh: ${timeUntilRefresh.inMinutes} minutes');
      }

      if (timeUntilRefresh.inSeconds > 30) {
        if (kDebugMode) {
          print(
            '🔄 Scheduling token refresh in ${timeUntilRefresh.inMinutes} minutes',
          );
        }

        _refreshTimer = Timer(timeUntilRefresh, () {
          if (kDebugMode) print('🔄 Proactive token refresh triggered');
          _onRefreshNeeded();
        });
      } else if (timeUntilRefresh.inSeconds > 0) {
        // Token expires soon, refresh immediately
        if (kDebugMode) print('🔄 Token expires soon, refreshing immediately');
        _onRefreshNeeded();
      } else {
        if (kDebugMode)
          print('🔄 Token already expired, refresh needed immediately');
        _onRefreshNeeded();
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling token refresh: $e');
    }
  }

  void dispose() {
    _cancelTimer();
  }
}

// Authenticated Dio provider with improved interceptors
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = ref.watch(baseUrlProvider);

  // Set base URL
  dio.options.baseUrl = baseUrl;

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Add auth interceptor with improved refresh token logic
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only add token for non-auth endpoints
        if (!options.path.contains('/auth/')) {
          final token = await _getValidAccessToken(tokenStorage);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // If we can't get a valid token, this request will likely fail
            if (kDebugMode)
              print('⚠️ No valid access token available for request');
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          if (kDebugMode) print('🔄 401 error, attempting token refresh');

          // Try to get a valid access token (this will handle refresh if needed)
          final token = await _getValidAccessToken(
            tokenStorage,
            forceRefresh: true,
          );

          if (token != null) {
            if (kDebugMode) print('🔄 Got new token, retrying request');

            // Retry original request with new token
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final cloneReq = await dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              handler.resolve(cloneReq);
              return;
            } catch (e) {
              if (kDebugMode) print('Retry request failed: $e');
            }
          } else {
            if (kDebugMode)
              print('🔄 Failed to refresh token, clearing auth state');
            // If all refresh attempts failed, clear tokens
            await tokenStorage.clearTokens();
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

// Enhanced helper function to get valid access token with better error handling
Future<String?> _getValidAccessToken(
  TokenStorageService tokenStorage, {
  bool forceRefresh = false,
}) async {
  try {
    final currentToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();

    if (currentToken == null || refreshToken == null) {
      if (kDebugMode) print('🔄 No stored tokens found');
      return null;
    }

    // Check if refresh token is expired first (most critical check)
    final isRefreshTokenExpired = await tokenStorage.isRefreshTokenExpired();
    if (isRefreshTokenExpired) {
      if (kDebugMode)
        print('🔄 Refresh token expired, need to re-authenticate');
      await tokenStorage.clearTokens();
      return null;
    }

    // Check if access token is expired or force refresh is requested
    final isAccessTokenExpired = await tokenStorage.isTokenExpired();

    if (!isAccessTokenExpired && !forceRefresh) {
      return currentToken;
    }

    if (kDebugMode) {
      print(
        '🔄 Access token ${isAccessTokenExpired ? 'expired' : 'refresh forced'}',
      );
    }

    // Attempt to refresh the access token
    final newToken = await _refreshAccessToken(tokenStorage, refreshToken);

    if (newToken == null) {
      if (kDebugMode) print('🔄 Token refresh failed, clearing tokens');
      await tokenStorage.clearTokens();
    }

    return newToken;
  } catch (e) {
    if (kDebugMode) print('Error getting valid access token: $e');
    return null;
  }
}

// Enhanced helper function to refresh access token with better error handling
Future<String?> _refreshAccessToken(
  TokenStorageService tokenStorage,
  String refreshToken,
) async {
  try {
    // Create a separate dio instance for refresh to avoid circular calls
    final refreshDio = Dio();
    final baseUrl = ConfigService().getPrimaryApiEndpoint();

    if (kDebugMode) print('🔄 Attempting to refresh access token');

    final response = await refreshDio.post(
      '$baseUrl/auth/refreshtoken',
      data: {'refreshToken': refreshToken},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200 && response.data['data'] != null) {
      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String?;
      final expiresIn = data['expiresIn'] as int?;
      final username = data['username'] as String?;

      if (newAccessToken == null || expiresIn == null || username == null) {
        if (kDebugMode)
          print('🔄 ❌ Missing required fields in refresh response');
        return null;
      }

      // Use the specific refresh method for your server response format
      await tokenStorage.saveRefreshTokens(
        accessToken: newAccessToken,
        expiresInSeconds: expiresIn,
        username: username,
      );

      if (kDebugMode) {
        print('🔄 ✅ Token refresh successful');
        print('🔄 ✅ New access token: ${newAccessToken.substring(0, 20)}...');
        print('🔄 ✅ Converted expiresIn ($expiresIn s) to ISO format');
        print('🔄 ✅ Kept existing refresh token');
      }
      return newAccessToken;
    } else {
      if (kDebugMode) {
        print('🔄 ❌ Token refresh failed - invalid response');
        print('Response status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) print('🔄 ❌ Token refresh failed: $e');
    return null;
  }
}

// Helper function to extract expiry from JWT token
String? _extractExpiryFromJWT(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');

    final decoded = utf8.decode(base64.decode(payload));
    final payloadMap = jsonDecode(decoded);
    final exp = payloadMap['exp'] as int?;

    if (exp != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expiryDate.toIso8601String();
    }
  } catch (e) {
    if (kDebugMode) print('Error extracting expiry from JWT: $e');
  }
  return null;
}

// Base URL provider
final baseUrlProvider = Provider<String>((ref) {
  return '${ConfigService().getPrimaryApiEndpoint()}';
});

// API client provider (uses basic dio for auth endpoints)
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  return AuthApiClient(dio, baseUrl: baseUrl);
});

// Token storage provider
final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(authApiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient, tokenStorage);
});

// Enhanced Auth state notifier with proactive token refresh
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;
  late final TokenRefreshManager _refreshManager;

  AuthNotifier(this._repository, this._tokenStorage)
    : super(const AuthState(status: AuthStatus.unknown)) {
    _refreshManager = TokenRefreshManager(
      _tokenStorage,
      _handleProactiveRefresh,
    );
    _init();
  }

  @override
  void dispose() {
    _refreshManager.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final storedData = await _repository.getStoredAuthData();

      if (storedData?.accessToken != null) {
        // Check if refresh token is expired first
        final isRefreshTokenExpired =
            await _tokenStorage.isRefreshTokenExpired();

        if (isRefreshTokenExpired) {
          if (kDebugMode) print('🔐 Refresh token expired during init');
          state = const AuthState(status: AuthStatus.unauthenticated);
          return;
        }

        // Check if access token is expired
        final isAccessTokenExpired = await _repository.isTokenExpired();

        if (isAccessTokenExpired) {
          if (kDebugMode)
            print('🔐 Access token expired, refreshing during init');
          final refreshResult = await _repository.refreshToken();

          if (refreshResult.isSuccess &&
              refreshResult.data?.accessToken != null) {
            final userData = UserData(
              accessToken: refreshResult.data!.accessToken,
              refreshToken: refreshResult.data!.refreshToken,
              expiryDate: refreshResult.data!.expiryDate,
              username: refreshResult.data!.username,
              id: storedData?.id,
            );

            state = AuthState(
              status: AuthStatus.authenticated,
              userData: userData,
              token: refreshResult.data!.accessToken,
            );

            // Start the proactive refresh timer
            _refreshManager.startTokenRefreshTimer();
          } else {
            if (kDebugMode) print('🔐 Token refresh failed during init');
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        } else {
          state = AuthState(
            status: AuthStatus.authenticated,
            userData: storedData,
            token: storedData?.accessToken,
          );

          // Start the proactive refresh timer
          _refreshManager.startTokenRefreshTimer();
        }
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing auth: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _handleProactiveRefresh() async {
    if (state.status == AuthStatus.authenticated) {
      if (kDebugMode) print('🔄 Handling proactive token refresh');
      final success = await tryRefreshToken();

      if (success) {
        // Schedule the next refresh
        _refreshManager.startTokenRefreshTimer();
      } else {
        if (kDebugMode)
          print('🔄 Proactive refresh failed, user will be logged out');
      }
    }
  }

  Future<SignUpServerResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _repository.signUp(email: email, password: password);

    if (response.requiresConfirmation) {
      state = state.copyWith(
        status: AuthStatus.needsConfirmation,
        confirmationEmail: email,
      );
    }

    return response;
  }

  Future<SignInServerResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (kDebugMode) print('🔐 Sign in attempt for email: $email');

    final response = await _repository.signIn(email: email, password: password);

    if (kDebugMode) {
      print('🔐 Sign in response: ${response.isSuccess}');
      print('🔐 Sign in response data: ${response.data}');
    }

    if (response.isSuccess && response.data?.accessToken != null) {
      // Validate that we have both access and refresh tokens
      if (response.data!.refreshToken == null) {
        if (kDebugMode) print('🔐 ⚠️ Warning: No refresh token received!');
      }

      // Use the specific sign-in method
      await _tokenStorage.saveSignInTokens(
        accessToken: response.data!.accessToken ?? '',
        refreshToken: response.data!.refreshToken ?? '',
        expiryDate: response.data!.expiryDate ?? '',
        username: response.data!.username ?? '',
        email: email,
      );

      final userData = UserData(
        accessToken: response.data!.accessToken,
        refreshToken: response.data!.refreshToken,
        expiryDate: response.data!.expiryDate,
        username: response.data!.username,
        email: email,
      );

      if (kDebugMode) {
        print('🔐 ✅ Sign in successful');
        print('🔐 ✅ Username (user ID): ${userData.username}');
        print(
          '🔐 ✅ Access token: ${userData.accessToken?.substring(0, 20)}...',
        );
        print(
          '🔐 ✅ Refresh token: ${userData.refreshToken?.substring(0, 20)}...',
        );
        print('🔐 ✅ Token expires: ${userData.expiryDate}');
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        userData: userData,
        token: response.data!.accessToken,
      );

      // Start the proactive refresh timer after successful sign in
      _refreshManager.startTokenRefreshTimer();
    } else if (response.data?.accessToken == null) {
      if (kDebugMode) print('🔐 ❌ Sign in requires confirmation');
      state = state.copyWith(
        status: AuthStatus.needsConfirmation,
        confirmationEmail: email,
      );
    }

    return response;
  }

  void setUnauthenticated() {
    _refreshManager.dispose(); // Stop any refresh timers
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
    _refreshManager.dispose(); // Stop any refresh timers
    await _repository.signOut();
    setUnauthenticated();
  }

  Future<ForgotPasswordResponse> forgotPassword({required String email}) async {
    final response = await _repository.forgotPassword(email: email);

    if (response.isSuccess) {
      state = state.copyWith(confirmationEmail: email);
    }

    return response;
  }

  Future<ResendConfirmationResponse> resendConfirmationCode({
    required String email,
  }) async {
    final response = await _repository.resendConfirmationCode(email: email);

    if (response.isSuccess) {
      state = state.copyWith(confirmationEmail: email);
    }

    return response;
  }

  Future<ChangePasswordResponse> changePassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    final response = await _repository.changePassword(
      email: email,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );

    if (response.isSuccess) {
      state = state.copyWith(confirmationEmail: null);
    }

    return response;
  }

  void clearConfirmationState() {
    if (state.status == AuthStatus.needsConfirmation) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        confirmationEmail: null,
      );
    }
  }

  Future<String?> getValidToken() async {
    return await _getValidAccessToken(_tokenStorage);
  }

  Future<bool> tryRefreshToken() async {
    // Check if refresh token is expired first
    final isRefreshTokenExpired = await _tokenStorage.isRefreshTokenExpired();

    if (isRefreshTokenExpired) {
      if (kDebugMode) print('🔄 Cannot refresh - refresh token expired');
      await signOut();
      return false;
    }

    if (kDebugMode) print('🔄 Attempting manual token refresh');
    final response = await _repository.refreshToken();

    if (response.isSuccess && response.data?.accessToken != null) {
      final userData = UserData(
        accessToken: response.data!.accessToken,
        refreshToken: response.data!.refreshToken,
        expiryDate: response.data!.expiryDate,
        username: response.data!.username,
        id: state.userData?.id,
      );

      state = state.copyWith(
        userData: userData,
        token: response.data!.accessToken,
      );

      if (kDebugMode) print('🔄 ✅ Manual token refresh successful');
      return true;
    } else {
      if (kDebugMode) print('🔄 ❌ Manual token refresh failed');
      await signOut();
      return false;
    }
  }
}

// Updated auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserProvider = Provider<UserData?>((ref) {
  return ref.watch(authNotifierProvider).userData;
});

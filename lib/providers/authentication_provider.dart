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
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          // Try to get a valid access token (this will handle refresh if needed)
          final token = await _getValidAccessToken(
            tokenStorage,
            forceRefresh: true,
          );

          if (token != null) {
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
          }

          // If all refresh attempts failed, clear tokens
          await tokenStorage.clearTokens();
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

// Helper function to get valid access token with refresh logic
Future<String?> _getValidAccessToken(
  TokenStorageService tokenStorage, {
  bool forceRefresh = false,
}) async {
  try {
    final currentToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();

    if (currentToken == null || refreshToken == null) {
      return null;
    }

    // Check if access token is expired or force refresh is requested
    final isAccessTokenExpired = await tokenStorage.isTokenExpired();

    if (!isAccessTokenExpired && !forceRefresh) {
      return currentToken;
    }

    // Check if refresh token is expired
    final isRefreshTokenExpired = await tokenStorage.isRefreshTokenExpired();

    if (isRefreshTokenExpired) {
      if (kDebugMode)
        print('🔄 Refresh token expired, need to re-authenticate');
      await tokenStorage.clearTokens();
      return null;
    }

    // Attempt to refresh the access token
    return await _refreshAccessToken(tokenStorage, refreshToken);
  } catch (e) {
    if (kDebugMode) print('Error getting valid access token: $e');
    return null;
  }
}

// Helper function to refresh access token
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
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200 &&
        response.data['data']?['accessToken'] != null) {
      final data = response.data['data'];

      // Get existing stored data to preserve user info
      final existingData = await tokenStorage.getStoredAuthData();

      // Check if the response includes refresh token expiry
      final refreshTokenExpiry = data['refreshTokenExpiry'];

      if (refreshTokenExpiry != null) {
        // Use the new method that supports refresh token expiry
        await tokenStorage.saveTokensWithRefreshExpiry(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? refreshToken,
          expiryDate: data['expiryDate'] ?? '',
          username: data['username'] ?? existingData?.username ?? '',
          id: data['id'] ?? existingData?.id ?? '',
          refreshTokenExpiry: refreshTokenExpiry,
        );
      } else {
        // Use the regular method
        await tokenStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? refreshToken,
          expiryDate: data['expiryDate'] ?? '',
          username: data['username'] ?? existingData?.username ?? '',
          id: data['id'] ?? existingData?.id ?? '',
        );
      }

      if (kDebugMode) print('🔄 ✅ Token refresh successful');
      return data['accessToken'];
    } else {
      if (kDebugMode) print('🔄 ❌ Token refresh failed - invalid response');
      return null;
    }
  } catch (e) {
    if (kDebugMode) print('🔄 ❌ Token refresh failed: $e');
    return null;
  }
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

// Enhanced Auth state notifier with better refresh token handling
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;

  AuthNotifier(this._repository, this._tokenStorage)
    : super(const AuthState(status: AuthStatus.unknown)) {
    _init();
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
          } else {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        } else {
          state = AuthState(
            status: AuthStatus.authenticated,
            userData: storedData,
            token: storedData?.accessToken,
          );
        }
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      if (kDebugMode) print('Error initializing auth: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
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
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        userData: userData,
        token: response.data!.accessToken,
      );
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
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
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
      return true;
    } else {
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

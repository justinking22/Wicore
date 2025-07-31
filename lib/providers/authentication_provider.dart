import 'package:Wicore/repository/auth_repository.dart';
import 'package:Wicore/services/config_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_api_client.dart';
import '../services/token_storage_service.dart';
import '../models/auth_models.dart';

// Basic Dio provider without auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

// Authenticated Dio provider with interceptors
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final tokenStorage = ref.watch(tokenStorageProvider);

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only add token for non-auth endpoints
        if (!options.path.contains('/auth/')) {
          final token = await tokenStorage.getAccessToken();
          if (token != null && !(await tokenStorage.isTokenExpired())) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          // Try to refresh token
          final refreshToken = await tokenStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              // Create a separate dio instance for refresh to avoid circular calls
              final refreshDio = Dio();
              final baseUrl = ref.read(baseUrlProvider);

              final response = await refreshDio.post(
                '$baseUrl/auth/refreshtoken',
                data: {'refreshToken': refreshToken},
                options: Options(headers: {'Content-Type': 'application/json'}),
              );

              if (response.statusCode == 200 &&
                  response.data['data']?['accessToken'] != null) {
                final data = response.data['data'];
                await tokenStorage.saveTokens(
                  accessToken: data['accessToken'],
                  refreshToken: data['refreshToken'] ?? refreshToken,
                  expiresIn: data['expiresIn'] ?? 43200,
                  username: data['username'],
                  id: data['id'],
                );

                // Retry original request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${data['accessToken']}';
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
              }
            } catch (e) {
              if (kDebugMode) print('Token refresh failed: $e');
            }
          }

          // If refresh failed, clear tokens
          await tokenStorage.clearTokens();
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

// Base URL provider
final baseUrlProvider = Provider<String>((ref) {
  return '${ConfigService().getPrimaryApiEndpoint()}'; // Replace with your actual base URL
});

// API client provider (uses basic dio for auth endpoints)
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  return AuthApiClient(dio, baseUrl: baseUrl);
});

// Authenticated API client provider (for other endpoints that need auth)
final authenticatedApiClientProvider = Provider<Dio>((ref) {
  return ref.watch(authenticatedDioProvider);
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

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository)
    : super(const AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final storedData = await _repository.getStoredAuthData();

      if (storedData?.accessToken != null) {
        final isExpired = await _repository.isTokenExpired();

        if (isExpired) {
          final refreshResult = await _repository.refreshToken();
          if (refreshResult.success) {
            state = AuthState(
              status: AuthStatus.authenticated,
              userData: refreshResult.data,
              token: refreshResult.data?.accessToken,
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

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _repository.signUp(
      email: email,
      password: password,
      name: name,
    );

    if (response.requiresConfirmation == true) {
      state = state.copyWith(
        status: AuthStatus.needsConfirmation,
        confirmationEmail: email,
      );
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _repository.signIn(email: email, password: password);

    if (response.success && response.data?.accessToken != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        userData: response.data,
        token: response.data!.accessToken,
      );
    } else if (response.requiresConfirmation == true) {
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

  // Update signOut method to use new setter
  Future<AuthResponse> signOut() async {
    final response = await _repository.signOut();
    setUnauthenticated(); // Use the new method
    return response;
  }

  Future<AuthResponse> forgotPassword({required String email}) async {
    final response = await _repository.forgotPassword(email: email);

    if (response.success) {
      state = state.copyWith(confirmationEmail: email);
    }

    return response;
  }

  Future<AuthResponse> resendConfirmationCode({required String email}) async {
    final response = await _repository.resendConfirmationCode(email: email);

    if (response.success) {
      state = state.copyWith(confirmationEmail: email);
    }

    return response;
  }

  Future<AuthResponse> changePassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    final response = await _repository.changePassword(
      email: email,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );

    if (response.success) {
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
    if (state.token == null) return null;

    if (await _repository.isTokenExpired()) {
      final refreshed = await tryRefreshToken();
      return refreshed ? state.token : null;
    }

    return state.token;
  }

  Future<bool> tryRefreshToken() async {
    final response = await _repository.refreshToken();

    if (response.success && response.data?.accessToken != null) {
      state = state.copyWith(
        userData: response.data,
        token: response.data!.accessToken,
      );
      return true;
    } else {
      // If refresh fails, sign out
      await signOut();
      return false;
    }
  }
}

// Auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserProvider = Provider<AuthData?>((ref) {
  return ref.watch(authNotifierProvider).userData;
});

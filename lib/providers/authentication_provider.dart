// lib/providers/authentication_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:Wicore/models/user_update_request_model.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/repository/auth_repository.dart';
import 'package:Wicore/repository/fcm_repository.dart';
import 'package:Wicore/services/config_service.dart';
import 'package:Wicore/services/fcm_api_client.dart';
import 'package:Wicore/services/incognito_user_service.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/auth_api_client.dart';
import '../services/token_storage_service.dart';
import '../models/user_model.dart';
import '../models/sign_up_response_model.dart';
import '../models/sign_in_response_model.dart';
import '../models/refresh_token_response_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/resend_confirmation_response_model.dart';
import '../models/change_password_response_model.dart';
import '../models/social_login_models.dart';

// Basic Dio provider without auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

// Debug helper for token issues
class AuthDebugHelper {
  final TokenStorageService _tokenStorage;

  AuthDebugHelper(this._tokenStorage);

  Future<void> debugAuthState() async {
    if (!kDebugMode) return;

    print('🔍 === AUTH DEBUG INFORMATION ===');

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final refreshToken = await _tokenStorage.getRefreshToken();
      final expiryDate = await _tokenStorage.getTokenExpiryDate();
      final refreshExpiryDate = await _tokenStorage.getRefreshTokenExpiryDate();
      final isSocial = await _tokenStorage.isSocialLogin();
      final provider = await _tokenStorage.getSocialProvider();

      print('🔍 Login Type: ${isSocial ? "Social ($provider)" : "Regular"}');
      print('🔍 Access Token Present: ${accessToken != null}');
      if (accessToken != null) {
        print(
          '🔍 Access Token Preview: ${accessToken.substring(0, min(20, accessToken.length))}...',
        );
        print('🔍 Access Token Length: ${accessToken.length}');
      }

      print('🔍 Refresh Token Present: ${refreshToken != null}');
      if (refreshToken != null) {
        print(
          '🔍 Refresh Token Preview: ${refreshToken.substring(0, min(20, refreshToken.length))}...',
        );
        print('🔍 Refresh Token Length: ${refreshToken.length}');
      }

      print('🔍 Access Token Expiry: $expiryDate');
      print('🔍 Refresh Token Expiry: $refreshExpiryDate');

      if (expiryDate != null) {
        final expiry = DateTime.parse(expiryDate);
        final now = DateTime.now();
        final timeUntilExpiry = expiry.difference(now);

        print('🔍 Current Time: $now');
        print('🔍 Access Token Expires: $expiry');
        print('🔍 Time Until Expiry: ${timeUntilExpiry.inMinutes} minutes');
        print('🔍 Access Token Expired: ${timeUntilExpiry.isNegative}');
      }

      if (refreshExpiryDate != null) {
        final refreshExpiry = DateTime.parse(refreshExpiryDate);
        final now = DateTime.now();
        final timeUntilRefreshExpiry = refreshExpiry.difference(now);

        print('🔍 Refresh Token Expires: $refreshExpiry');
        print(
          '🔍 Time Until Refresh Expiry: ${timeUntilRefreshExpiry.inHours} hours',
        );
        print('🔍 Refresh Token Expired: ${timeUntilRefreshExpiry.isNegative}');
      }

      // Test token validation
      final isTokenExpired = await _tokenStorage.isTokenExpired();
      final isRefreshTokenExpired = await _tokenStorage.isRefreshTokenExpired();

      print('🔍 Token Storage Says Access Expired: $isTokenExpired');
      print('🔍 Token Storage Says Refresh Expired: $isRefreshTokenExpired');
    } catch (e) {
      print('🔍 Error during debug: $e');
    }

    print('🔍 === END AUTH DEBUG ===');
  }
}

// Enhanced Token refresh manager for social login
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
      final isSocial = await _tokenStorage.isSocialLogin();

      if (isSocial) {
        // For social login, use JWT expiry instead of fixed 2-hour refresh
        final expiryDate = await _tokenStorage.getTokenExpiryDate();
        if (expiryDate != null) {
          final now = DateTime.now();
          final expiry = DateTime.parse(expiryDate);

          // Schedule refresh 5 minutes before JWT expiry
          final refreshTime = expiry.subtract(const Duration(minutes: 5));
          final timeUntilRefresh = refreshTime.difference(now);

          if (kDebugMode) {
            print('🔄 Social login JWT-based refresh scheduling:');
            print('   Current time: $now');
            print('   JWT expires: $expiry');
            print('   Refresh scheduled for: $refreshTime');
            print(
              '   Time until refresh: ${timeUntilRefresh.inMinutes} minutes',
            );
          }

          if (timeUntilRefresh.inSeconds > 30) {
            _refreshTimer = Timer(timeUntilRefresh, () {
              if (kDebugMode) print('🔄 JWT-based social refresh triggered');
              _onRefreshNeeded();
            });
          } else {
            // Token expires soon, refresh immediately
            if (kDebugMode)
              print('🔄 Social token expires soon, refreshing now');
            _onRefreshNeeded();
          }
          return;
        }

        // Fallback to 2-hour refresh if we can't read JWT expiry
        if (kDebugMode) print('🔄 Fallback to 2-hour social refresh');
        const refreshInterval = Duration(hours: 2);
        _refreshTimer = Timer(refreshInterval, _onRefreshNeeded);
      } else {
        // Regular login logic remains the same
        final expiryDate = await _tokenStorage.getTokenExpiryDate();
        if (expiryDate == null) return;

        final now = DateTime.now();
        final expiry = DateTime.parse(expiryDate);
        final refreshTime = expiry.subtract(const Duration(minutes: 2));
        final timeUntilRefresh = refreshTime.difference(now);

        if (timeUntilRefresh.inSeconds > 30) {
          _refreshTimer = Timer(timeUntilRefresh, _onRefreshNeeded);
        } else {
          _onRefreshNeeded();
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling token refresh: $e');
    }
  }

  void dispose() {
    _cancelTimer();
  }
}

// Enhanced helper function to refresh access token with social login support
Future<String?> _refreshAccessToken(
  TokenStorageService tokenStorage,
  String refreshToken,
) async {
  try {
    // Check if this is a social login
    final isSocial = await tokenStorage.isSocialLogin();

    if (isSocial) {
      // Handle social login token refresh via Amplify
      if (kDebugMode)
        print('🔄 Attempting social login token refresh via Amplify');

      final success = await tokenStorage.refreshSocialTokens();

      if (success) {
        // Get the refreshed access token
        final newAccessToken = await tokenStorage.getAccessToken();
        if (kDebugMode) print('🔄 ✅ Social token refresh successful');
        return newAccessToken;
      } else {
        if (kDebugMode) print('🔄 ❌ Social token refresh failed');
        return null;
      }
    } else {
      // Handle regular backend token refresh
      if (kDebugMode) print('🔄 Attempting regular token refresh via backend');

      // Create a separate dio instance for refresh to avoid circular calls
      final refreshDio = Dio();
      final baseUrl = ConfigService().getPrimaryApiEndpoint();

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
          print('🔄 ✅ Regular token refresh successful');
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
    }
  } catch (e) {
    if (kDebugMode) print('🔄 ❌ Token refresh failed: $e');
    return null;
  }
}

// Enhanced helper function to get valid access token with social login support
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

    // Check if this is a social login
    final isSocial = await tokenStorage.isSocialLogin();

    // For social logins, check if refresh token is still valid via Amplify
    if (isSocial) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (!session.isSignedIn) {
          if (kDebugMode)
            print('🔄 Social login session expired, need to re-authenticate');
          await tokenStorage.clearTokens();
          return null;
        }
      } catch (e) {
        if (kDebugMode) print('🔄 Error checking social login session: $e');
        await tokenStorage.clearTokens();
        return null;
      }
    } else {
      // For regular logins, check refresh token expiry as before
      final isRefreshTokenExpired = await tokenStorage.isRefreshTokenExpired();
      if (isRefreshTokenExpired) {
        if (kDebugMode)
          print('🔄 Refresh token expired, need to re-authenticate');
        await tokenStorage.clearTokens();
        return null;
      }
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

// Incognito user service provider
final incognitoUserServiceProvider = Provider<IncognitoUserService>((ref) {
  return IncognitoUserService();
});

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(authApiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(apiClient, tokenStorage);
});

// Enhanced authenticated Dio provider that waits for auth initialization
// Enhanced authenticated Dio provider with comprehensive token debugging
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  // Set base URL
  dio.options.baseUrl = baseUrl;

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  // Add auth interceptor with comprehensive debugging
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Wait for auth initialization before proceeding
        await authNotifier.waitForInitialization();

        // Only add token for non-auth endpoints
        if (!options.path.contains('/auth/')) {
          final token = await _getValidAccessToken(tokenStorage);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';

            if (kDebugMode) {
              print('🔐 DEBUG - === TOKEN DEBUG FOR ${options.path} ===');
              print(
                '🔐 DEBUG - Request URL: ${options.baseUrl}${options.path}',
              );
              print(
                '🔐 DEBUG - Token (first 50 chars): ${token.substring(0, min(50, token.length))}...',
              );
              print('🔐 DEBUG - Token length: ${token.length}');

              // Check if it's a social token
              final provider = await tokenStorage.getSocialProvider();
              final isSocial = provider != null;
              print('🔐 DEBUG - Is social login: $isSocial');
              if (isSocial) {
                print('🔐 DEBUG - Social provider: $provider');
              }

              // Decode JWT token payload
              try {
                final parts = token.split('.');
                if (parts.length == 3) {
                  final payload = parts[1];
                  final normalizedPayload = payload.padRight(
                    (payload.length + 3) ~/ 4 * 4,
                    '=',
                  );
                  final decoded = utf8.decode(
                    base64Url.decode(normalizedPayload),
                  );
                  final jsonPayload =
                      json.decode(decoded) as Map<String, dynamic>;

                  print('🔐 DEBUG - JWT Claims:');
                  print('   sub (user ID): ${jsonPayload['sub']}');
                  print('   aud (audience): ${jsonPayload['aud']}');
                  print('   iss (issuer): ${jsonPayload['iss']}');
                  print('   exp (expires): ${jsonPayload['exp']}');
                  print('   iat (issued at): ${jsonPayload['iat']}');
                  print('   token_use: ${jsonPayload['token_use']}');
                  print('   scope: ${jsonPayload['scope']}');
                  print('   client_id: ${jsonPayload['client_id']}');
                  print('   username: ${jsonPayload['username']}');
                  print('   auth_time: ${jsonPayload['auth_time']}');

                  // Check token expiry
                  if (jsonPayload['exp'] != null) {
                    final expiry = DateTime.fromMillisecondsSinceEpoch(
                      (jsonPayload['exp'] as int) * 1000,
                    );
                    final now = DateTime.now();
                    final timeRemaining = expiry.difference(now);
                    print('   Token expires at: $expiry');
                    print(
                      '   Time remaining: ${timeRemaining.inMinutes} minutes',
                    );
                    print('   Is expired: ${timeRemaining.isNegative}');
                  }
                } else {
                  print(
                    '🔐 DEBUG - Invalid JWT format (${parts.length} parts)',
                  );
                }
              } catch (e) {
                print('🔐 DEBUG - Error decoding JWT: $e');
              }

              // Log all headers being sent
              print('🔐 DEBUG - Request headers:');
              options.headers.forEach((key, value) {
                if (key.toLowerCase() == 'authorization') {
                  print(
                    '   $key: Bearer ${value.toString().substring(7, min(27, value.toString().length))}...',
                  );
                } else {
                  print('   $key: $value');
                }
              });

              print('🔐 DEBUG - === END TOKEN DEBUG ===');
            }

            print('🔐 Added auth header to ${options.path}');
          } else {
            print('⚠️ No valid access token available for ${options.path}');

            // Debug why no token is available
            if (kDebugMode) {
              final storedToken = await tokenStorage.getAccessToken();
              final storedRefresh = await tokenStorage.getRefreshToken();
              final isExpired = await tokenStorage.isTokenExpired();
              final isRefreshExpired =
                  await tokenStorage.isRefreshTokenExpired();

              print('🔐 DEBUG - No token details:');
              print('   Stored access token exists: ${storedToken != null}');
              print('   Stored refresh token exists: ${storedRefresh != null}');
              print('   Access token expired: $isExpired');
              print('   Refresh token expired: $isRefreshExpired');
            }
          }
        } else {
          print('🔐 Skipping auth header for auth endpoint: ${options.path}');
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          print('🔐 DEBUG - HTTP Error occurred:');
          print('   Status code: ${error.response?.statusCode}');
          print('   URL: ${error.requestOptions.path}');
          print('   Response data: ${error.response?.data}');
        }

        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          print('🔄 401 error, attempting token refresh');

          // Try to get a valid access token (this will handle refresh if needed)
          final token = await _getValidAccessToken(
            tokenStorage,
            forceRefresh: true,
          );

          if (token != null) {
            print('🔄 Got new token, retrying request');

            if (kDebugMode) {
              print(
                '🔐 DEBUG - Retry token: ${token.substring(0, min(50, token.length))}...',
              );
            }

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
              print('Retry request failed: $e');
            }
          } else {
            print('🔄 Failed to refresh token, clearing auth state');
            // If all refresh attempts failed, clear tokens
            await tokenStorage.clearTokens();

            // Notify auth state that tokens are invalid
            ref.read(authNotifierProvider.notifier).setUnauthenticated();
          }
        }

        handler.next(error);
      },
      onResponse: (response, handler) async {
        if (kDebugMode && response.statusCode != 200) {
          print('🔐 DEBUG - Response received:');
          print('   Status: ${response.statusCode}');
          print('   URL: ${response.requestOptions.path}');
          print(
            '   Response size: ${response.data?.toString().length ?? 0} chars',
          );
        }
        handler.next(response);
      },
    ),
  );

  return dio;
});

// Enhanced Auth state notifier with app lifecycle handling
class AuthNotifier extends StateNotifier<AuthState>
    with WidgetsBindingObserver {
  final AuthRepository _repository;
  final TokenStorageService _tokenStorage;
  late final TokenRefreshManager _refreshManager;
  late final AuthDebugHelper _debugHelper;
  final Ref _ref; //
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  AuthNotifier(this._repository, this._tokenStorage, this._ref)
    : super(const AuthState(status: AuthStatus.unknown)) {
    _refreshManager = TokenRefreshManager(
      _tokenStorage,
      _handleProactiveRefresh,
    );
    _debugHelper = AuthDebugHelper(_tokenStorage);
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshManager.dispose();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) print('🔐 App resumed - checking token validity');
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        if (kDebugMode) print('🔐 App paused');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  // Wait for initialization to complete
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    if (_initCompleter != null) {
      await _initCompleter!.future;
    }
  }

  Future<void> _init() async {
    if (_initCompleter != null) return; // Prevent multiple initializations

    _initCompleter = Completer<void>();

    try {
      if (kDebugMode) {
        print('🔐 Initializing auth state...');
        await _debugHelper.debugAuthState();
      }

      final storedData = await _repository.getStoredAuthData();

      if (storedData?.accessToken != null && storedData?.refreshToken != null) {
        if (kDebugMode) print('🔐 Found stored tokens');

        // Check if refresh token is expired first
        final isRefreshTokenExpired =
            await _tokenStorage.isRefreshTokenExpired();

        if (isRefreshTokenExpired) {
          if (kDebugMode) print('🔐 Refresh token expired during init');
          await _tokenStorage.clearTokens();
          state = const AuthState(status: AuthStatus.unauthenticated);
        } else {
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
                email: storedData?.email,
              );

              state = AuthState(
                status: AuthStatus.authenticated,
                userData: userData,
                token: refreshResult.data!.accessToken,
              );

              _refreshManager.startTokenRefreshTimer();
              if (kDebugMode) print('🔐 ✅ Init complete - token refreshed');
            } else {
              if (kDebugMode) print('🔐 Token refresh failed during init');
              await _tokenStorage.clearTokens();
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          } else {
            // Access token is still valid
            state = AuthState(
              status: AuthStatus.authenticated,
              userData: storedData,
              token: storedData?.accessToken,
            );

            _refreshManager.startTokenRefreshTimer();
            if (kDebugMode) print('🔐 ✅ Init complete - existing token valid');
          }
        }
      } else {
        if (kDebugMode) print('🔐 No stored tokens found');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      if (kDebugMode) print('🔐 ❌ Error initializing auth: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    } finally {
      _isInitialized = true;
      _initCompleter?.complete();
    }
  }

  Future<void> _handleAppResume() async {
    if (kDebugMode) {
      print('🔐 App resumed - debugging current state');
      await _debugHelper.debugAuthState();
    }

    if (state.status == AuthStatus.authenticated) {
      // Verify token is still valid when app resumes
      final token = await _getValidAccessToken(
        _tokenStorage,
        forceRefresh: false,
      );

      if (token == null) {
        if (kDebugMode) print('🔐 Token invalid on app resume, signing out');
        await signOut();
      } else {
        // Restart the refresh timer in case it was stopped
        _refreshManager.startTokenRefreshTimer();
        if (kDebugMode) print('🔐 Token valid on app resume');
      }
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

  /// Handle social login (Google/Apple) tokens from Amplify Cognito
  Future<SocialLoginServerResponse> signInWithSocial({
    required String provider,
    required String accessToken,
    required String refreshToken,
    required String idToken,
    required String userId,
    String? email,
  }) async {
    try {
      if (kDebugMode) print('🔐 Social login attempt for provider: $provider');

      // Clear existing user state
      _ref.read(userProvider.notifier).clearState();

      // Save tokens first
      await _tokenStorage.saveSocialLoginTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        username: userId, // This is the JWT username (signinwithapple_xxx)
        userId: userId,
        provider: provider,
        email: email,
      );

      // Get the auto-generated expiry date
      final expiryDate = await _tokenStorage.getTokenExpiryDate();

      // Create UserData object
      final userData = UserData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiryDate: expiryDate,
        username: userId, // Use JWT username
        id: userId, // Use JWT username as ID
        email: email,
      );

      // Update auth state
      state = AuthState(
        status: AuthStatus.authenticated,
        userData: userData,
        token: accessToken,
      );

      // Start the refresh timer
      _refreshManager.startTokenRefreshTimer();

      // **CRITICAL**: Create/update user in backend immediately after authentication
      try {
        print('🔐 === STARTING SOCIAL USER CREATION ===');
        print('🔐 Provider: $provider');
        print('🔐 User ID: $userId');
        print('🔐 Email: $email');

        await _createOrUpdateSocialUser(userId, email, provider);

        print('🔐 ✅ Social user creation/update completed successfully');
        print('🔐 ✅ === SOCIAL USER CREATION COMPLETED ===');
      } catch (e) {
        print('🔐 ❌ === SOCIAL USER CREATION FAILED ===');
        print('🔐 ❌ Error: $e');
        // Don't fail the login if user creation fails - they can retry later
      }

      // Try to fetch user profile
      try {
        final userNotifier = _ref.read(userProvider.notifier);
        await userNotifier.getCurrentUserProfile();
        print('Social login - User profile fetched for onboarding check');
      } catch (e) {
        print('Social login - Error fetching user profile: $e');
        // Continue anyway, router will handle it
      }

      // Create response object
      final socialResponse = SocialLoginServerResponse(
        isSuccess: true,
        message: 'Social login successful',
        data: SocialLoginData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          idToken: idToken,
          expiryDate: expiryDate,
          username: userId,
          userId: userId,
          email: email,
          provider: provider,
        ),
      );

      return socialResponse;
    } catch (e) {
      if (kDebugMode) print('🔐 ❌ Social login failed: $e');
      return SocialLoginServerResponse(
        isSuccess: false,
        message: 'Social login failed: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<void> _createOrUpdateSocialUser(
    String userId,
    String? email,
    String provider,
  ) async {
    try {
      print('🔐 === STARTING SOCIAL USER BACKEND CREATION ===');
      print('🔐 User ID for backend: $userId');
      print('🔐 Email: $email');
      print('🔐 Provider: $provider');

      // Extract name from email or use default
      final firstName = email?.split('@').first ?? 'Social User';
      print('🔐 Extracted firstName: $firstName');

      // Create update request for social user
      final updateRequest = UserUpdateRequest(
        id: userId, // Use the JWT username as ID),
        firstName: firstName,
        email: email,
        onboarded: false, // Social users start as not onboarded
        deviceStrength: 1, // Default device strength
      );

      print('🔐 Update request: ${updateRequest.toJson()}');
      print('🔐 Calling updateCurrentUserProfileSmart...');

      // Use the smart update method which handles social vs regular users
      final userNotifier = _ref.read(userProvider.notifier);
      await userNotifier.updateCurrentUserProfile(updateRequest);

      print('🔐 ✅ updateCurrentUserProfileSmart completed');

      // Give backend time to process
      await Future.delayed(const Duration(milliseconds: 300));

      print('🔐 ✅ === SOCIAL USER BACKEND CREATION COMPLETED ===');
    } catch (error) {
      print('🔐 ❌ === SOCIAL USER BACKEND CREATION FAILED ===');
      print('🔐 ❌ Error details: $error');
      print('🔐 ❌ Error type: ${error.runtimeType}');
      rethrow;
    }
  }

  /// Enhanced method to set authenticated state with social login data
  void setAuthenticatedWithSocialData({
    required String provider,
    required String accessToken,
    required String refreshToken,
    required String idToken,
    required String userId,
    String? email,
  }) async {
    // Save tokens first
    await _tokenStorage.saveSocialLoginTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      username: userId,
      userId: userId,
      provider: provider,
      email: email,
    );

    // Get the auto-generated expiry date (2 hours from now)
    final expiryDate = await _tokenStorage.getTokenExpiryDate();

    final userData = UserData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiryDate: expiryDate,
      username: userId,
      id: userId,
      email: email,
    );

    state = AuthState(
      status: AuthStatus.authenticated,
      userData: userData,
      token: accessToken,
    );

    // Start the proactive refresh timer
    _refreshManager.startTokenRefreshTimer();

    if (kDebugMode) {
      print('✅ Auth state set with social login data');
      print('   Provider: $provider');
      print('   User ID: $userId');
      print('   Email: $email');
    }
  }

  /// Check if current user is authenticated via social login
  bool get isSocialLogin {
    final userData = state.userData;
    if (userData?.username == null) return false;

    // Check if username contains social login patterns
    return userData!.username!.contains('google_') ||
        userData.username!.contains('signinwithapple_');
  }

  /// Get social login provider if user is authenticated via social
  String? get socialLoginProvider {
    if (!isSocialLogin) return null;

    final username = state.userData?.username;
    if (username == null) return null;

    if (username.contains('google_')) return 'google';
    if (username.contains('signinwithapple_')) return 'apple';

    return null;
  }

  void setUnauthenticated() {
    _refreshManager.dispose(); // Stop any refresh timers
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Enhanced sign out method that handles social login
  Future<void> signOut() async {
    final wasIncognitoMode = await _tokenStorage.isSocialLogin();
    _ref.read(userProvider.notifier).clearState();

    _refreshManager.dispose(); // Stop any refresh timers

    // Clear incognito user data if this was a social login
    if (wasIncognitoMode) {
      try {
        final incognitoService = IncognitoUserService();
        await incognitoService.clearIncognitoData();
        if (kDebugMode) print('Cleared incognito user data');
      } catch (e) {
        if (kDebugMode) print('Error clearing incognito data: $e');
      }
    }

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
      if (kDebugMode) print('Cannot refresh - refresh token expired');
      await signOut();
      return false;
    }

    if (kDebugMode) print('Attempting manual token refresh');
    final response = await _repository.refreshToken();

    if (response.isSuccess && response.data?.accessToken != null) {
      final userData = UserData(
        accessToken: response.data!.accessToken,
        refreshToken: response.data!.refreshToken,
        expiryDate: response.data!.expiryDate,
        username: response.data!.username,
        id: state.userData?.id,
        email: state.userData?.email,
      );

      state = state.copyWith(
        userData: userData,
        token: response.data!.accessToken,
      );

      if (kDebugMode) print('Manual token refresh successful');
      return true;
    } else {
      if (kDebugMode) print('Manual token refresh failed');
      await signOut();
      return false;
    }
  }

  // Helper method to ensure authentication
  Future<bool> ensureAuthenticated() async {
    await waitForInitialization();

    if (state.status != AuthStatus.authenticated) {
      return false;
    }

    // Double-check token validity
    final token = await getValidToken();
    return token != null;
  }
}

// Updated auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage, ref);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserProvider = Provider<UserData?>((ref) {
  return ref.watch(authNotifierProvider).userData;
});

// Extension for additional functionality
extension AuthNotifierExtension on AuthNotifier {
  void setAuthenticatedWithStoredData(Map<String, dynamic> storedTokens) {
    // Convert stored tokens to UserData
    final userData = UserData(
      accessToken: storedTokens['accessToken']!,
      refreshToken: storedTokens['refreshToken'],
      expiryDate: storedTokens['expiryDate'],
      username: storedTokens['username'],
      id: storedTokens['id'],
      email: storedTokens['email'],
    );

    state = AuthState(
      status: AuthStatus.authenticated,
      userData: userData,
      token: userData.accessToken,
    );

    if (kDebugMode)
      print('Auth state set with stored data - User ID: ${userData.id}');
  }
}

// FCM API client provider (uses authenticated dio)
final fcmApiClientProvider = Provider<FcmApiClient>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  final baseUrl = ref.watch(baseUrlProvider);
  return FcmApiClient(dio, baseUrl: baseUrl);
});

// FCM Repository provider
final fcmRepositoryProvider = Provider<FcmRepository>((ref) {
  final apiClient = ref.watch(fcmApiClientProvider);
  return FcmRepository(apiClient);
});

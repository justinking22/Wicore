import 'package:Wicore/app_router.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/utilities/app_initialization_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/config_service.dart';
// ✅ Added missing imports
import 'models/user_model.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Keep the native splash screen visible
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(ProviderScope(child: const Wicore()));
}

// App initialization state provider
final appInitializationProvider =
    StateNotifierProvider<AppInitializationNotifier, AppInitializationState>((
      ref,
    ) {
      return AppInitializationNotifier(ref);
    });

class AppInitializationNotifier extends StateNotifier<AppInitializationState> {
  final Ref ref;
  final _configService = ConfigService();

  AppInitializationNotifier(this.ref) : super(const AppInitializationState()) {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🔄 Starting app initialization...');

      // First load the configuration
      await _configService.loadConfig();

      // Get the API base URL from the configuration
      final apiBaseUrl = _configService.getPrimaryApiEndpoint();

      if (apiBaseUrl == null) {
        throw Exception('No API endpoint found in configuration');
      }

      debugPrint('✅ Configuration loaded, API URL: $apiBaseUrl');

      // Now configure Amplify
      await _configureAmplify();

      // Initialize auth state by checking stored tokens
      await _initializeAuthState();

      debugPrint('✅ App initialization completed successfully');

      state = state.copyWith(
        isInitialized: true,
        initializationSuccess: true,
        apiBaseUrl: apiBaseUrl,
      );
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
      state = state.copyWith(
        isInitialized: true,
        initializationSuccess: false,
        errorMessage: e.toString(),
      );
    } finally {
      // Remove the native splash screen once initialization is complete
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _configureAmplify() async {
    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/amplifyconfiguration.json',
      );

      // Add Amplify plugins
      final authPlugin = AmplifyAuthCognito();
      final apiPlugin = AmplifyAPI();

      await Amplify.addPlugins([authPlugin, apiPlugin]);

      // Configure Amplify
      await Amplify.configure(jsonString);

      debugPrint('✅ Amplify configured successfully');
    } catch (e) {
      debugPrint('❌ Error configuring Amplify: $e');
      rethrow;
    }
  }

  Future<void> _initializeAuthState() async {
    try {
      debugPrint('🔄 Initializing auth state...');
      final tokenStorage = ref.read(tokenStorageProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Check for stored tokens
      final storedAuthData = await tokenStorage.getStoredTokens();

      if (storedAuthData != null) {
        debugPrint('📱 Found stored tokens');

        // Always attempt token refresh for security
        try {
          final refreshResult =
              await ref.read(authRepositoryProvider).refreshToken();

          if (refreshResult.isSuccess && refreshResult.data != null) {
            debugPrint('✅ Token refreshed successfully');

            // ✅ Fixed: Convert RefreshTokenData to UserData
            final userData = UserData(
              accessToken: refreshResult.data!.accessToken,
              refreshToken: refreshResult.data!.refreshToken,
              expiryDate: refreshResult.data!.expiryDate,
              username: refreshResult.data!.username,
              id: storedAuthData.id, // Preserve existing ID
            );

            authNotifier.state = AuthState(
              status: AuthStatus.authenticated,
              userData: userData,
              token: refreshResult.data!.accessToken,
            );
          } else {
            debugPrint('❌ Token refresh failed, using stored tokens if valid');
            // Check if stored token is still valid
            final isExpired = await tokenStorage.isTokenExpired();

            if (!isExpired) {
              debugPrint('✅ Using valid stored tokens');
              authNotifier.state = AuthState(
                status: AuthStatus.authenticated,
                userData: storedAuthData,
                token: storedAuthData.accessToken,
              );
            } else {
              debugPrint('❌ Stored tokens expired, requiring login');
              await tokenStorage.clearTokens();
              authNotifier.setUnauthenticated();
            }
          }
        } catch (e) {
          debugPrint('❌ Token refresh error: $e');
          // Fall back to stored tokens if valid
          final isExpired = await tokenStorage.isTokenExpired();
          if (!isExpired) {
            debugPrint('✅ Using valid stored tokens after refresh error');
            authNotifier.state = AuthState(
              status: AuthStatus.authenticated,
              userData: storedAuthData,
              token: storedAuthData.accessToken,
            );
          } else {
            debugPrint('❌ Stored tokens expired after refresh error');
            await tokenStorage.clearTokens();
            authNotifier.setUnauthenticated();
          }
        }
      } else {
        debugPrint('ℹ️ No stored tokens found');
        authNotifier.setUnauthenticated();
      }

      debugPrint('✅ Auth state initialization completed');
    } catch (e, st) {
      debugPrint('❌ Error initializing auth state: $e\n$st');
      // Clear tokens and set to unauthenticated on error
      await ref.read(tokenStorageProvider).clearTokens();
      ref.read(authNotifierProvider.notifier).setUnauthenticated();
    }
  }

  void retry() {
    state = const AppInitializationState();
    FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
    _initializeApp();
  }
}

class Wicore extends ConsumerWidget {
  const Wicore({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);

    // Show nothing while initializing (native splash screen is visible)
    if (!initState.isInitialized) {
      return const SizedBox.shrink();
    }

    // Show error screen if initialization failed
    if (!initState.initializationSuccess || initState.apiBaseUrl == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize application',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initState.errorMessage ?? 'Unknown error occurred',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(appInitializationProvider.notifier).retry();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main app with Riverpod router
    return WicoreApp();
  }
}

class WicoreApp extends ConsumerWidget {
  const WicoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Wicore',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: router,
    );
  }
}

// ✅ Fixed extension to use UserData instead of AuthData
extension AuthNotifierExtension on AuthNotifier {
  void setAuthenticatedWithStoredData(Map<String, dynamic> storedTokens) {
    // Convert stored tokens to UserData
    final userData = UserData(
      accessToken: storedTokens['accessToken']!,
      refreshToken: storedTokens['refreshToken'],
      expiryDate: storedTokens['expiryDate'],
      username: storedTokens['username'],
      id: storedTokens['id'],
    );

    state = AuthState(
      status: AuthStatus.authenticated,
      userData: userData,
      token: userData.accessToken,
    );
  }
}

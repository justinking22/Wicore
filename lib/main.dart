import 'package:Wicore/app_router.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/states/app_initialization_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/config_service.dart';
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
      print('🔄 Starting app initialization...');

      // First load the configuration
      await _configService.loadConfig();

      // Get the API base URL from the configuration
      final apiBaseUrl = _configService.getPrimaryApiEndpoint();

      if (apiBaseUrl == null) {
        throw Exception('No API endpoint found in configuration');
      }

      print('✅ Configuration loaded, API URL: $apiBaseUrl');

      // Now configure Amplify
      await _configureAmplify();

      // Initialize auth state by checking stored tokens
      await _initializeAuthState();

      print('✅ App initialization completed successfully');

      state = state.copyWith(
        isInitialized: true,
        initializationSuccess: true,
        apiBaseUrl: apiBaseUrl,
      );
    } catch (e) {
      print('❌ Error initializing app: $e');
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

      print('✅ Amplify configured successfully');
    } catch (e) {
      print('❌ Error configuring Amplify: $e');
      rethrow;
    }
  }

  Future<void> _initializeAuthState() async {
    try {
      print('🔄 Initializing auth state...');
      final tokenStorage = ref.read(tokenStorageProvider);
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Wait for auth initialization to complete
      await authNotifier.waitForInitialization();

      // Check current auth state after initialization
      final authState = ref.read(authNotifierProvider);

      if (authState.status == AuthStatus.authenticated) {
        print('✅ User authenticated during app initialization');

        // Trigger user data fetch after successful auth
        print('🔄 Triggering user data fetch after auth initialization...');
        Future.microtask(() {
          try {
            ref.read(userProvider.notifier).getCurrentUserProfile();
          } catch (e) {
            print('❌ Error triggering user data fetch: $e');
          }
        });
      } else {
        print('ℹ️ User not authenticated during app initialization');
      }

      print('✅ Auth state initialization completed');
    } catch (e, st) {
      print('❌ Error initializing auth state: $e\n$st');
      // Clear tokens and set to unauthenticated on error
      try {
        await ref.read(tokenStorageProvider).clearTokens();
        ref.read(authNotifierProvider.notifier).setUnauthenticated();
      } catch (clearError) {
        print('❌ Error clearing tokens: $clearError');
      }
    }
  }

  void retry() {
    state = const AppInitializationState();
    FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
    _initializeApp();
  }
}

// Auth initialization wrapper widget
class AuthInitializationWrapper extends ConsumerWidget {
  final Widget child;

  const AuthInitializationWrapper({Key? key, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(appInitializationProvider);

    // Show nothing while initializing (native splash screen is visible)
    if (!initState.isInitialized) {
      return const SizedBox.shrink();
    }

    // Show error screen if initialization failed
    if (!initState.initializationSuccess) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppInitializationErrorScreen(
          errorMessage: initState.errorMessage,
          onRetry: () => ref.read(appInitializationProvider.notifier).retry(),
        ),
      );
    }

    return child;
  }
}

// Error screen for app initialization failures
class AppInitializationErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const AppInitializationErrorScreen({
    Key? key,
    this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                errorMessage ?? 'Unknown error occurred',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class Wicore extends ConsumerWidget {
  const Wicore({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthInitializationWrapper(child: const WicoreApp());
  }
}

class WicoreApp extends ConsumerWidget {
  const WicoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auto-fetch provider to ensure it's triggered
    if (kDebugMode)
      print('🔄 WicoreApp - Watching autoFetchCurrentUserProvider...');
    ref.watch(autoFetchCurrentUserProvider);

    // Add debug logging for user state changes
    ref.listen(userProvider, (previous, next) {
      if (kDebugMode) {
        print('🐛 WicoreApp - User provider state changed');
        print('  Previous: ${previous?.toString()}');
        print('  Current: ${next.toString()}');

        next.when(
          data: (response) {
            final onboarded = response?.data?.onboarded;
            final userId = response?.data?.id;
            final firstName = response?.data?.firstName;
            print('🐛 WicoreApp - ✅ User data loaded');
            print('  User ID: $userId');
            print('  First Name: $firstName');
            print('  Onboarded: $onboarded');
            print('  Full response code: ${response?.code}');
            if (response?.data != null) {
              print('  Full user data: ${response!.data!.toJson()}');
            }
          },
          loading: () => print('🐛 WicoreApp - ⏳ User data loading...'),
          error: (error, stack) {
            print('🐛 WicoreApp - ❌ User data error: $error');
          },
        );
      }
    });

    // Add debug logging for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      if (kDebugMode) {
        print('🐛 WicoreApp - Auth state changed');
        print('  Previous status: ${previous?.status}');
        print('  Current status: ${next.status}');
        print('  Is Authenticated: ${next.isAuthenticated}');
        print('  User ID: ${next.userData?.id}');
        print('  Username: ${next.userData?.username}');
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Wicore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Add app lifecycle handling
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router,
    );
  }
}

// Enhanced extension for AuthNotifier
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
      print('✅ Auth state set with stored data - User ID: ${userData.id}');
  }
}

// API service extension for ensuring authentication
extension ApiServiceExtension on ConsumerWidget {
  Future<bool> ensureAuthenticated(WidgetRef ref) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    return await authNotifier.ensureAuthenticated();
  }
}

// Global error boundary for catching authentication errors
class AuthErrorBoundary extends ConsumerWidget {
  final Widget child;

  const AuthErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth errors and handle them
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated &&
          previous?.status == AuthStatus.authenticated) {
        // User was logged out unexpectedly
        if (kDebugMode) print('🔐 User logged out unexpectedly');

        // Show a snackbar or dialog to inform the user
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please log in again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    });

    return child;
  }
}

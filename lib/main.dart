import 'package:Wicore/app_router.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/fcm_provider.dart';
import 'package:Wicore/providers/user_provider.dart';
import 'package:Wicore/services/notification_service.dart';
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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this import
import 'firebase_options.dart';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

// Add background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background FCM message received: ${message.messageId}");
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

      // Initialize FCM after Amplify
      await _initializeFirebaseMessaging();

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

  Future<void> _initializeFirebaseMessaging() async {
    try {
      print('🔄 Initializing Firebase Messaging...');

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permissions first
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert:
            false, // Changed to false since we don't need critical alerts
        provisional: false,
        announcement: false,
      );

      print('📱 FCM Permission status: ${settings.authorizationStatus}');

      // For iOS/macOS, wait for APNS token to be ready
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // await _waitForAPNSToken();

          // Get FCM token with null check
      String? token = await messaging.getToken();
      if (token != null) {
        print('📱 FCM Token Sergey: $token');
        // await _sendTokenToServer(token);
      } else {
        print('📱 Failed to get FCM token');
      }
      }

      // 🔥 ADD: Initialize the NotificationService
      await NotificationService.initialize(ref);

      // Initialize FCM token provider after auth is ready
      Future.microtask(() {
        try {
          ref.read(fcmTokenProvider.notifier);
        } catch (e) {
          print('❌ Error initializing FCM token provider: $e');
        }
      });

      // Handle initial message when app is opened from terminated state
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 FCM initial message: ${initialMessage.notification?.title}');
      }

      print('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }

  // Add this method (exactly like DiagnoX)
  Future<void> _waitForAPNSToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? apnsToken;
    int attempts = 0;
    const maxAttempts = 20; // Increased attempts for slower devices

    print('🍎 Waiting for APNS token...');

    while (apnsToken == null && attempts < maxAttempts) {
      try {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          print('🍎 APNS Token ready: ${apnsToken.substring(0, 10)}...');
          break;
        }
      } catch (e) {
        print('🍎 Attempt ${attempts + 1}: Waiting for APNS token...');
      }

      attempts++;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (apnsToken == null) {
      print('⚠️ Warning: APNS token not available after $maxAttempts attempts');
      // Don't throw error, just log warning
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

// Rest of your existing code remains the same...
// (All the other classes: AuthInitializationWrapper, AppInitializationErrorScreen,
//  Wicore, WicoreApp, extensions, etc.)

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

      // 🔥 ADD THIS: Handle FCM token registration on auth state changes
      _handleFcmTokenOnAuthChange(ref, previous, next);
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Wicore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.black,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
      ),
      routerConfig: router,
    );
  }

  // 🔥 ADD THIS METHOD: Handle FCM token registration on auth changes
  void _handleFcmTokenOnAuthChange(
    WidgetRef ref,
    AuthState? previous,
    AuthState next,
  ) {
    // Handle user login - register FCM token
    if (next.status == AuthStatus.authenticated &&
        previous?.status != AuthStatus.authenticated) {
      if (kDebugMode) print('🔥 User authenticated, registering FCM token');
      Future.microtask(() {
        try {
          ref.read(fcmTokenProvider.notifier).registerTokenIfAuthenticated();
        } catch (e) {
          print('❌ Error registering FCM token after auth: $e');
        }
      });
    }

    // Handle user logout - cleanup FCM listeners
    if (next.status == AuthStatus.unauthenticated &&
        previous?.status == AuthStatus.authenticated) {
      if (kDebugMode)
        print('🔥 User logged out, cleaning up FCM token listeners');
      Future.microtask(() {
        try {
          ref.read(fcmTokenProvider.notifier).handleUserLogout();
        } catch (e) {
          print('❌ Error cleaning up FCM token after logout: $e');
        }
      });
    }
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

import 'package:Wicore/app_router.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/states/auth_status.dart';
import 'package:Wicore/states/app_initialization_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'services/config_service.dart';
import 'models/user_model.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global instance for local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📱 Body: ${message.notification?.body}');
  
  // You can process the message here or store it for later
  await _showLocalNotification(message);
}



void main() async {
  // Ensure Flutter is initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Keep the native splash screen visible
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  await _initializeLocalNotifications();

  runApp(ProviderScope(child: const Wicore()));
}

// Initialize local notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      print('📱 Notification tapped: ${response.payload}');
      // Navigate to specific screen based on payload if needed
    },
  );

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel',
    'Default Channel',
    description: 'Default notification channel',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// Firebase Messaging Provider
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(firebaseMessagingProvider));
});

// class NotificationService {
//   final FirebaseMessaging _messaging;
  
//   NotificationService(this._messaging);

//   // Initialize messaging
//   Future<void> initialize() async {
//     // Request permission (iOS)
//     NotificationSettings settings = await _messaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );

//     print('📱 Permission granted: ${settings.authorizationStatus}');

//     // Get FCM token
//     String? token = await _messaging.getToken();
//     print('📱 FCM Token: $token');
    
//     // TODO: Send token to your backend server
//     // await _sendTokenToServer(token);

//     // Listen to token refresh
//     _messaging.onTokenRefresh.listen((String token) {
//       print('📱 Token refreshed: $token');
//       // TODO: Update token on your server
//       // _sendTokenToServer(token);
//     });

//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('📱 Foreground message: ${message.messageId}');
//       print('📱 Title: ${message.notification?.title}');
//       print('📱 Body: ${message.notification?.body}');
      
//       // Show local notification when app is in foreground
//       _showLocalNotification(message);
//     });

//     // Handle message when app is opened from notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('📱 Message opened app: ${message.messageId}');
//       // Handle navigation based on message data
//       _handleMessageNavigation(message);
//     });

//     // Check for initial message (when app is opened from terminated state)
//     RemoteMessage? initialMessage = await _messaging.getInitialMessage();
//     if (initialMessage != null) {
//       print('📱 Initial message: ${initialMessage.messageId}');
//       _handleMessageNavigation(initialMessage);
//     }
//   }

//   // Handle navigation when notification is tapped
//   void _handleMessageNavigation(RemoteMessage message) {
//     // Extract navigation data from message
//     final data = message.data;
    
//     // Example navigation logic
//     if (data.containsKey('route')) {
//       final route = data['route'];
//       print('📱 Navigating to: $route');
//       // Use your app router to navigate
//       // AppRouter.navigateTo(route);
//     }
    
//     if (data.containsKey('user_id')) {
//       final userId = data['user_id'];
//       print('📱 Navigate to user profile: $userId');
//       // Navigate to user profile
//     }
//   }

//   // Subscribe to topic
//   Future<void> subscribeToTopic(String topic) async {
//     await _messaging.subscribeToTopic(topic);
//     print('📱 Subscribed to topic: $topic');
//   }

//   // Unsubscribe from topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     await _messaging.unsubscribeFromTopic(topic);
//     print('📱 Unsubscribed from topic: $topic');
//   }

//   // Get current token
//   Future<String?> getToken() async {
//     return await _messaging.getToken();
//   }
// }

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

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

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

  Future<void> _initializeFirebaseMessaging() async {
    try {
      debugPrint('🔄 Initializing Firebase Messaging...');
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      // Subscribe to general topics if needed
      await notificationService.subscribeToTopic('general');
      
      debugPrint('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
      // Don't rethrow - messaging is not critical for app functionality
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

            // Convert RefreshTokenData to UserData
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

            // Subscribe to user-specific notifications
            if (storedAuthData.id != null) {
              await _subscribeToUserNotifications(storedAuthData.id!);
            }

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
              
              // Subscribe to user-specific notifications
              if (storedAuthData.id != null) {
                await _subscribeToUserNotifications(storedAuthData.id!);
              }
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
            
            // Subscribe to user-specific notifications
            if (storedAuthData.id != null) {
              await _subscribeToUserNotifications(storedAuthData.id!);
            }
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

  Future<void> _subscribeToUserNotifications(String userId) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.subscribeToTopic('user_$userId');
      debugPrint('✅ Subscribed to user notifications: user_$userId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to user notifications: $e');
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

// Extension for AuthNotifier
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

// Additional helper methods with proper null safety

class NotificationService {
  final FirebaseMessaging _messaging;
  
  NotificationService(this._messaging);

  // Send token to server with null check
  Future<void> _sendTokenToServer(String token) async {
    try {
      // Your API call to send token to backend
      // Example:
      // await apiService.updateFCMToken(token);
      print('📱 Sending token to server: $token');
    } catch (e) {
      print('❌ Failed to send token to server: $e');
    }
  }

  // Initialize messaging with proper null handling
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Permission granted: ${settings.authorizationStatus}');

      // Get FCM token with null check
      String? token = await _messaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        await _sendTokenToServer(token);
      } else {
        print('📱 Failed to get FCM token');
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((String token) {
        print('📱 Token refreshed: $token');
        _sendTokenToServer(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Foreground message: ${message.messageId}');
        print('📱 Title: ${message.notification?.title ?? "No title"}');
        print('📱 Body: ${message.notification?.body ?? "No body"}');
        
        // Show local notification when app is in foreground
        _showLocalNotification(message);
      });

      // Handle message when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 Message opened app: ${message.messageId}');
        _handleMessageNavigation(message);
      });

      // Check for initial message (when app is opened from terminated state)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 Initial message: ${initialMessage.messageId}');
        _handleMessageNavigation(initialMessage);
      }
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
      rethrow;
    }
  }

  // Handle navigation when notification is tapped
  void _handleMessageNavigation(RemoteMessage message) {
    try {
      // Extract navigation data from message
      final data = message.data;
      
      // Example navigation logic
      if (data.containsKey('route')) {
        final route = data['route'];
        if (route != null && route.isNotEmpty) {
          print('📱 Navigating to: $route');
          // Use your app router to navigate
          // AppRouter.navigateTo(route);
        }
      }
      
      if (data.containsKey('user_id')) {
        final userId = data['user_id'];
        if (userId != null && userId.isNotEmpty) {
          print('📱 Navigate to user profile: $userId');
          // Navigate to user profile
        }
      }
    } catch (e) {
      print('❌ Error handling message navigation: $e');
    }
  }

  // Subscribe to topic with error handling
  Future<void> subscribeToTopic(String topic) async {
    try {
      if (topic.isNotEmpty) {
        await _messaging.subscribeToTopic(topic);
        print('📱 Subscribed to topic: $topic');
      }
    } catch (e) {
      print('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic with error handling
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (topic.isNotEmpty) {
        await _messaging.unsubscribeFromTopic(topic);
        print('📱 Unsubscribed from topic: $topic');
      }
    } catch (e) {
      print('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Get current token with null safety
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  // Delete token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('📱 FCM token deleted');
    } catch (e) {
      print('❌ Failed to delete FCM token: $e');
    }
  }
}

// Helper function to show local notifications with null safety
Future<void> _showLocalNotification(RemoteMessage message) async {
  try {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel', // channel ID
      'Default Channel', // channel name
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Use null-aware operators for title and body
    final title = message.notification?.title ?? 'New Message';
    final body = message.notification?.body ?? 'You have a new message';
    final payload = message.data.isNotEmpty ? message.data.toString() : null;

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  } catch (e) {
    print('❌ Failed to show local notification: $e');
  }
}
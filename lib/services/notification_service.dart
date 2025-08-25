import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/fcm_provider.dart';
import 'package:Wicore/states/auth_status.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static late Ref _ref; // Changed from WidgetRef to Ref

  // Initialize the notification service - now accepts Ref instead of WidgetRef
  static Future<void> initialize(Ref ref) async {
    _ref = ref;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle FCM messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Handle FCM messages and show notifications with action button
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Received FCM message: ${message.messageId}');

    await showNotificationWithResolveButton(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? 'You have a new notification',
    );
  }

  // Handle notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Action ID: ${response.actionId}');

    if (response.actionId == 'resolve_action') {
      _callResolveEndpoint();
    }
  }

  // Simple call to your resolve endpoint
  static Future<void> _callResolveEndpoint() async {
    try {
      print('🔄 Calling resolve endpoint...');

      // Check authentication
      final authState = _ref.read(authNotifierProvider);
      if (authState.status != AuthStatus.authenticated) {
        _showErrorMessage('User not authenticated');
        return;
      }

      // Call your FCM repository
      final fcmRepository = _ref.read(fcmRepositoryProvider);
      final response = await fcmRepository.resolveEmergency();

      if (response.isSuccess) {
        print('✅ Resolve endpoint called successfully');
        _showSuccessMessage('Action completed successfully');
      } else {
        _showErrorMessage('Action failed');
      }
    } catch (e) {
      print('❌ Error calling resolve endpoint: $e');
      _showErrorMessage('Action failed. Please try again.');
    }
  }

  // Show notification with resolve button
  static Future<void> showNotificationWithResolveButton({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          channelDescription: 'Default notifications with action button',
          importance: Importance.high,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'resolve_action',
              'Mark Emergency Resolved',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_check_circle'),
            ),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'resolveCategory',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, platformDetails);
  }

  // Show success message
  static Future<void> _showSuccessMessage(String message) async {
    await _notifications.show(
      999999,
      '✅ Success',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'success_channel',
          'Success Messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Show error message
  static Future<void> _showErrorMessage(String message) async {
    await _notifications.show(
      999998,
      '❌ Error',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'error_channel',
          'Error Messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

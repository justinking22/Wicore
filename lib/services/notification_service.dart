import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wicore/providers/authentication_provider.dart';
import 'package:Wicore/providers/fcm_provider.dart';
import 'package:Wicore/states/auth_status.dart';
import 'dart:io';

// CRITICAL: This must be a top-level function for iOS background actions
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Background notification action: ${notificationResponse.actionId}');
  // Note: Background actions have limited capability on iOS
  // For complex operations, consider launching the app to foreground
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static late Ref _ref;

  // Initialize the notification service
  static Future<void> initialize(Ref ref) async {
    _ref = ref;

    // Android settings remain the same
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configure iOS notification actions
    final List<DarwinNotificationAction> iosActions = [
      DarwinNotificationAction.plain(
        'resolve_action', // This ID must match what you check for in the handler
        'Mark Emergency Resolved',
        options: {
          DarwinNotificationActionOption.foreground,
          DarwinNotificationActionOption.authenticationRequired,
        },
      ),
    ];

    // Configure iOS category
    final DarwinNotificationCategory
    resolveCategory = DarwinNotificationCategory(
      'resolveCategory', // This ID must match in showNotificationWithResolveButton
      actions: iosActions,
      options: {
        DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        DarwinNotificationCategoryOption.hiddenPreviewShowSubtitle,
        DarwinNotificationCategoryOption.allowAnnouncement,
      },
    );

    // iOS initialization settings - Configure to show notifications in foreground
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
          notificationCategories: [resolveCategory],
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize with proper callbacks
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Handle FCM messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Handle FCM messages and show notifications with action button
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received FCM message: ${message.messageId}');

    await showNotificationWithResolveButton(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? 'You have a new notification',
    );
  }

  // Handle notification taps (foreground)
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification response received');
    print('Action ID: ${response.actionId ?? "no action"}');
    print('Payload: ${response.payload}');

    if (response.actionId == 'resolve_action') {
      print('Resolve action tapped');
      _callResolveEndpoint();
    } else {
      print('Regular notification tap');
    }
  }

  // Call resolve endpoint
  static Future<void> _callResolveEndpoint() async {
    try {
      print('Calling resolve endpoint...');

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
        print('Resolve endpoint called successfully');
        _showSuccessMessage('Emergency resolved successfully');
      } else {
        _showErrorMessage('Failed to resolve emergency');
      }
    } catch (e) {
      print('Error calling resolve endpoint: $e');
      _showErrorMessage('Action failed. Please try again.');
    }
  }

  // Show notification with resolve button
  static Future<void> showNotificationWithResolveButton({
    required int id,
    required String title,
    required String body,
  }) async {
    final NotificationDetails platformDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
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
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'resolveCategory', // Must match category ID above
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'emergency_notifications',
      ),
    );

    await _notifications.show(id, title, body, platformDetails);
  }

  // Show success message
  static Future<void> _showSuccessMessage(String message) async {
    await _notifications.show(
      999999,
      'Success',
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
      'Error',
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

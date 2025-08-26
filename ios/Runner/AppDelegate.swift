import Firebase
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Initialize Firebase for FCM
    FirebaseApp.configure()

    // Set UNUserNotificationCenter delegate for foreground notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Configure notification categories for action buttons
    configureNotificationCategories()

    // Set messaging delegate
    Messaging.messaging().delegate = self

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Configure notification categories with action buttons
  func configureNotificationCategories() {
    // Create actions
    let resolveAction = UNNotificationAction(
      identifier: "resolve_action",
      title: "Mark Emergency Resolved",
      options: [.foreground]
    )
    
    let dismissAction = UNNotificationAction(
      identifier: "dismiss_action",
      title: "Dismiss",
      options: [.destructive]
    )

    // Create categories
    let emergencyCategory = UNNotificationCategory(
      identifier: "emergency_category",
      actions: [resolveAction, dismissAction],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    
    let generalCategory = UNNotificationCategory(
      identifier: "general_category",
      actions: [dismissAction],
      intentIdentifiers: [],
      options: []
    )

    // Set categories
    UNUserNotificationCenter.current().setNotificationCategories([
      emergencyCategory,
      generalCategory
    ])
    
    print("✅ iOS notification categories configured")
  }

  // Handle successful APNs token registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("🎉 ===========================")
    print("🎉 APNS TOKEN RECEIVED!")
    print("🎉 ===========================")

    // CRITICAL: Set the APNs token for Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken

    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 APNs Token: \(String(tokenString.prefix(20)))...")

    // Call super to ensure proper handling
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle APNs registration failure with detailed error info
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ ===========================")
    print("❌ APNS REGISTRATION FAILED!")
    print("❌ Error: \(error.localizedDescription)")
    print("❌ ===========================")

    // Check for common issues and provide solutions
    let errorDescription = error.localizedDescription
    
    if errorDescription.contains("aps-environment") {
      print("💡 SOLUTION: Add Push Notifications capability in Xcode")
      print("💡 1. Open ios/Runner.xcworkspace in Xcode")
      print("💡 2. Select Runner project")
      print("💡 3. Go to Signing & Capabilities")
      print("💡 4. Add '+' > Push Notifications")
    } else if errorDescription.contains("no valid") {
      print("💡 SOLUTION: Check your provisioning profile and certificates")
      print("💡 Make sure your app ID has Push Notifications enabled")
    } else if errorDescription.contains("simulator") {
      print("💡 INFO: Push notifications don't work in iOS Simulator")
      print("💡 Test on a real device")
    }

    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Handle notification received while app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("📱 iOS notification received in foreground")
    print("📱 Title: \(notification.request.content.title)")
    print("📱 Body: \(notification.request.content.body)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // Handle notification tap and actions
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionIdentifier = response.actionIdentifier
    let notification = response.notification
    let userInfo = notification.request.content.userInfo
    
    print("📱 iOS notification action triggered: \(actionIdentifier)")
    
    // Handle different actions
    switch actionIdentifier {
    case "resolve_action":
      print("🔧 Emergency resolve action triggered")
      handleEmergencyResolve(userInfo: userInfo)
      
    case "dismiss_action":
      print("❌ Dismiss action triggered")
      handleNotificationDismiss(userInfo: userInfo)
      
    case UNNotificationDefaultActionIdentifier:
      print("📱 Notification tapped (default action)")
      handleNotificationTap(userInfo: userInfo)
      
    case UNNotificationDismissActionIdentifier:
      print("🔄 Notification dismissed by user")
      
    default:
      print("❓ Unknown action: \(actionIdentifier)")
    }
    
    completionHandler()
  }
  
  // MARK: - Notification Action Handlers
  
  private func handleEmergencyResolve(userInfo: [AnyHashable: Any]) {
    // Send to Flutter via MethodChannel
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("❌ Could not get FlutterViewController")
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.yourapp.notifications",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.invokeMethod("onEmergencyResolve", arguments: userInfo)
  }
  
  private func handleNotificationDismiss(userInfo: [AnyHashable: Any]) {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.yourapp.notifications", 
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.invokeMethod("onNotificationDismiss", arguments: userInfo)
  }
  
  private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.yourapp.notifications",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.invokeMethod("onNotificationTap", arguments: userInfo)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  
  // Handle FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else {
      print("❌ FCM token is nil")
      return
    }
    
    print("🔥 =========================")
    print("🔥 FCM TOKEN RECEIVED!")
    print("🔥 Token: \(String(fcmToken.prefix(50)))...")
    print("🔥 =========================")

    // Send token to Flutter via MethodChannel (more reliable than NotificationCenter)
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("❌ Could not get FlutterViewController for FCM token")
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "com.yourapp.fcm",
      binaryMessenger: controller.binaryMessenger
    )
    
    channel.invokeMethod("onTokenReceived", arguments: fcmToken) { result in
      if let error = result as? FlutterError {
        print("❌ Error sending FCM token to Flutter: \(error.message ?? "Unknown error")")
      } else {
        print("✅ FCM token sent to Flutter successfully")
      }
    }
    
    // Also post to NotificationCenter as backup
    let dataDict: [String: String] = ["token": fcmToken]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
  
  // Handle incoming data messages (optional - only if needed)
  // Note: This method is deprecated in newer Firebase versions
  // Most message handling should be done in Flutter code
}
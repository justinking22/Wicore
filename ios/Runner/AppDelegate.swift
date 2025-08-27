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

    // 🔥 UPDATED: Configure notification categories for action buttons
    configureNotificationCategories()

    // Set messaging delegate
    Messaging.messaging().delegate = self

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔥 UPDATED: Configure notification categories with proper permission flow
  func configureNotificationCategories() {
    // Create the action with additional options
    let resolveAction = UNNotificationAction(
      identifier: "resolve_action",
      title: "Mark Emergency Resolved",
      options: [.foreground, .authenticationRequired]
    )

    // Configure category with more options
    let resolveCategory = UNNotificationCategory(
      identifier: "resolveCategory",
      actions: [resolveAction],
      intentIdentifiers: [],
      // Add these options to show in more states
      options: [.customDismissAction, .allowInCarPlay]
    )

    // Set the categories
    UNUserNotificationCenter.current().setNotificationCategories([resolveCategory])

    // 🔥 FIXED: Request permissions and register for remote notifications in the callback
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { [weak self] granted, error in
      print("🔔 Notification permission request completed")
      if granted {
        print("✅ iOS notification permissions granted")
        // 🔥 IMPORTANT: Register for remote notifications AFTER permission is granted
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          print("📱 Requesting APNS token registration...")
        }
      } else {
        print("❌ iOS notification permissions denied: \(error?.localizedDescription ?? "Unknown")")
      }
    }
  }

  // 🔥 UPDATED: Handle successful APNs token registration
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
    print("📱 APNs Token: \(tokenString)")

    // Call super to ensure proper handling
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // 🔥 UPDATED: Handle APNs registration failure with more details
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ ===========================")
    print("❌ APNS REGISTRATION FAILED!")
    print("❌ Error: \(error.localizedDescription)")
    print("❌ ===========================")

    // Check for common issues
    if error.localizedDescription.contains("aps-environment") {
      print("💡 SOLUTION: Add Push Notifications capability in Xcode")
      print("💡 1. Open ios/Runner.xcworkspace in Xcode")
      print("💡 2. Select Runner project")
      print("💡 3. Go to Signing & Capabilities")
      print("💡 4. Add '+' > Push Notifications")
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
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound]])
    } else {
      completionHandler([[.alert, .sound]])
    }
  }

  // Update the notification tap handler
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionIdentifier = response.actionIdentifier

    print("📱 iOS notification action received: \(actionIdentifier)")

    if actionIdentifier == "resolve_action" {
      // Handle the resolve action
      print("🎯 Resolve action tapped")

      // Get the notification data
      let userInfo = response.notification.request.content.userInfo
      print("📦 Notification data: \(userInfo)")

      // Get Flutter engine from root view controller
      if let rootViewController = window?.rootViewController as? FlutterViewController {
        let flutterChannel = FlutterMethodChannel(
          name: "com.wicore.app/notifications",
          binaryMessenger: rootViewController.binaryMessenger
        )

        flutterChannel.invokeMethod(
          "handleNotificationAction",
          arguments: ["action": "resolve", "data": userInfo]
        )
      }
    }

    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  // Handle FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 =========================")
    print("🔥 FCM TOKEN RECEIVED!")
    print("🔥 Token: \(String(describing: fcmToken))")
    print("🔥 =========================")

    // You can send this token to your server here
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

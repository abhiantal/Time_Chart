import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Initialize Firebase FIRST
    FirebaseApp.configure()
    print("✅ Firebase configured")

    // ✅ Setup notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("✅ Notification permission granted")
          } else if let error = error {
            print("❌ Notification permission error: \(error.localizedDescription)")
          } else {
            print("❌ Notification permission denied")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    // ✅ Register for remote notifications
    application.registerForRemoteNotifications()
    print("✅ Registered for remote notifications")

    // ✅ Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Handle APNs token registration SUCCESS
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Convert token to string for logging
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("✅ APNs Device Token: \(token)")

    // Give token to Firebase
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNs Token registered with Firebase Messaging")
  }

  // ✅ Handle APNs token registration FAILURE
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // ✅ Handle notification when app is in FOREGROUND
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("📬 Notification received in foreground")
    print("Title: \(notification.request.content.title)")
    print("Body: \(notification.request.content.body)")
    print("UserInfo: \(userInfo)")

    // Show notification banner even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }

  // ✅ Handle notification TAP
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("👆 Notification tapped!")
    print("Title: \(response.notification.request.content.title)")
    print("UserInfo: \(userInfo)")

    // Let Flutter handle the notification data
    completionHandler()
  }

  // ✅ Handle notification when app is in BACKGROUND or TERMINATED
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📨 Background notification received")
    print("UserInfo: \(userInfo)")

    // Process the notification
    completionHandler(.newData)
  }
}
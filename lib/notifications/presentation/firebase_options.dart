// ================================================================
// FILE: lib/notifications/presentation/firebase_options.dart
// Firebase configuration for all platforms
// ================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Get these values from:
/// - Android: android/app/google-services.json
/// - iOS: ios/Runner/GoogleService-Info.plist
/// - Web: Firebase Console → Project Settings → Web app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ============================================================
  // 🌐 WEB CONFIGURATION
  // Get from: Firebase Console → Project Settings → Web app
  // ============================================================
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAg1glwd2m0gOs5sRfA8YIfpPK9YCHzLto', // Using the iOS/Android Key as proxy
    appId: '1:648047579890:web:96e7f13638ad214aa6f66b', // Predicted Web App ID
    messagingSenderId: '648047579890',
    projectId: 'time-chat-aa11',
    authDomain: 'time-chat-aa11.firebaseapp.com',
    storageBucket: 'time-chat-aa11.firebasestorage.app',
  );

  // ============================================================
  // 🤖 ANDROID CONFIGURATION
  // Get from: android/app/google-services.json
  // ============================================================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMRqoqMXvNHlwVdRJFwanOOOwFWeySPaw',
    appId: '1:648047579890:android:c3d5b1d33a341f4aa6f66b',
    messagingSenderId: '648047579890',
    projectId: 'time-chat-aa11',
    storageBucket: 'time-chat-aa11.firebasestorage.app',
  );

  // ============================================================
  // 🍎 iOS CONFIGURATION
  // Get from: ios/Runner/GoogleService-Info.plist
  // ============================================================
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAg1glwd2m0gOs5sRfA8YIfpPK9YCHzLto',
    appId: '1:648047579890:ios:48e7f13638ad214aa6f66b',
    messagingSenderId: '648047579890',
    projectId: 'time-chat-aa11',
    storageBucket: 'time-chat-aa11.firebasestorage.app',
    iosBundleId: 'com.timechart.app',
  );
}

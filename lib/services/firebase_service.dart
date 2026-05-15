// ================================================================
// FILE: lib/services/firebase_service.dart
// GUTTED — prevents dual background handler registration.
//
// FIX 1: firebaseBackgroundHandler is registered ONLY inside
//         FirebaseNotificationCore.initialize().
//         This file must NEVER call FirebaseMessaging.onBackgroundMessage().
//
// If nothing in your app imports FirebaseService directly,
// you can delete this file entirely.
// ================================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/logger.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // ✅ Safe: only exposes getToken() as a convenience wrapper.
  //    All real notification work is in FirebaseNotificationCore.
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      logE('FirebaseService.getToken error', error: e);
      return null;
    }
  }
}

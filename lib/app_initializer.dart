// ================================================================
// FILE: lib/config/app_initializer.dart
// OPTIMIZED - Parallel Initialization
// ================================================================

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';

import 'notifications/notification_setup.dart';
import 'services/powersync_service.dart';
import 'services/supabase_service.dart';
import 'widgets/logger.dart';
import 'media_utility/universal_media_service.dart';
import 'notifications/presentation/firebase_options.dart';
import 'core/providers/app_setup.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool _isInitialized = false;
  String _currentStep = '';
  double _progress = 0.0;
  bool _hasPreloadedData = false;

  bool get isInitialized => _isInitialized;
  String get currentStep => _currentStep;
  double get progress => _progress;

  /// Main initialization flow - NON-BLOCKING for UI
  Future<void> initialize({
    required Function(String step, double progress) onProgress,
  }) async {
    if (_isInitialized) {
      logI('✅ Already initialized');
      onProgress('Ready!', 1.0);
      return;
    }

    try {
      logI('🚀 Starting optimized initialization...');

      _updateProgress('Starting core services...', 0.1, onProgress);

      // 1. Parallelize Firebase and Core App Services (PowerSync, AI)
      await Future.wait([
        _initializeFirebase(),
        AppSetup().initializeServices(),
      ]);

      _updateProgress('Launching background tasks...', 0.4, onProgress);

      // 2. Initialize secondary services asynchronously (fire and forget)
      // These do not need to block the app's first frame.
      
      // Media Service depends on PowerSync
      UniversalMediaService().init().ignore();
      
      // Notifications depend on Firebase
      notificationSetup.initialize().then((_) {
        if (notificationSetup.fcmToken != null) {
          logI('✓ FCM token obtained');
        }
      }).catchError((e) {
        logW('Notifications disabled: $e');
      });

      // Settings full DB sync
      SettingsProvider().initialize().ignore();

      // 3. Setup Auth Listener
      _updateProgress('Checking authentication...', 0.7, onProgress);
      _setupAuthListener();

      // 4. Trigger background sync and local preloading
      if (Supabase.instance.client.auth.currentUser != null) {
        // Trigger sync connection immediately
        PowerSyncService().connectSync();

        // 🚀 OPTIMIZATION: We no longer block the app for up to 3 seconds waiting for sync.
        // Returning users already have local SQLite data, which loads instantly.
        // New users will see empty states and data will populate reactively as it streams in.
        
        // Start preloading local essential data in the background
        _preloadEssentialData().ignore();
      }

      // Complete
      _updateProgress('Ready!', 1.0, onProgress);

      _isInitialized = true;
      logI('✅ Initialization completed successfully');
    } catch (error, stackTrace) {
      logE('❌ Init failed', error: error, stackTrace: stackTrace);
      _isInitialized = false;
    }
  }

  void _updateProgress(
    String step,
    double progress,
    Function(String, double) callback,
  ) {
    _currentStep = step;
    _progress = progress;
    callback(step, progress);
  }

  // ================================================================
  // FIREBASE INITIALIZATION
  // ================================================================

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        logI('✓ Firebase initialized');
      }
    } catch (e) {
      logW('Firebase init warning (non-critical): $e');
    }
  }

  // ================================================================
  // DATA PRELOADING
  // ================================================================

  Future<void> _preloadEssentialData() async {
    if (_hasPreloadedData) return;

    try {
      final powerSync = PowerSyncService();
      final userId = powerSync.currentUserId;

      if (userId == null) return;

      // Parallelize queries
      final futures = <Future>[];

      // Profile
      futures.add(
        powerSync.executeQuery(
          'SELECT * FROM user_profiles WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        ),
      );

      // Settings
      futures.add(
        powerSync.executeQuery(
          'SELECT * FROM user_settings WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        ),
      );

      // Categories (Global + User)
      futures.add(
        powerSync.executeQuery(
          'SELECT * FROM categories WHERE user_id = ? OR is_global = 1 LIMIT 30',
          parameters: [userId],
        ),
      );

      await Future.wait(futures);
      _hasPreloadedData = true;

      // Load secondary data in background
      _preloadSecondaryData(userId);
    } catch (e) {
      logW('Preload failed (non-critical): $e');
    }
  }

  void _preloadSecondaryData(String userId) {
    // Run in microtask to not block UI
    Future.microtask(() {
      final powerSync = PowerSyncService();

      // Posts
      powerSync
          .executeQuery(
            '''
        SELECT p.* FROM posts p
        WHERE p.user_id IN (
          SELECT following_id FROM follows WHERE follower_id = ?
          UNION SELECT ?
        )
        ORDER BY p.created_at DESC LIMIT 10
        ''',
            parameters: [userId, userId],
          )
          .ignore();

      // Buckets
      powerSync
          .executeQuery(
            'SELECT * FROM bucket_models WHERE user_id = ? ORDER BY created_at DESC LIMIT 10',
            parameters: [userId],
          )
          .ignore();

      // Tasks
      powerSync
          .executeQuery(
            'SELECT * FROM day_tasks WHERE user_id = ? ORDER BY created_at DESC LIMIT 10',
            parameters: [userId],
          )
          .ignore();
    });
  }

  // ================================================================
  // AUTH LISTENER
  // ================================================================

  void _setupAuthListener() {
    SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        PowerSyncService().connectSync();
        _preloadEssentialData();
        // ⭐ NEW: Trigger settings initialization when user logs in
        SettingsProvider().initialize(force: true);
      } else if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
        PowerSyncService().disconnectSync();
        PowerSyncService().clearCache();
        SettingsProvider().clearCache();
        _hasPreloadedData = false;

        // 🧹 Securely wipe local database files to prevent data mixing across logins
        PowerSyncService().clearLocalData(reinitialize: false).catchError((e) {
          logW('Background database wipe on sign out failed: $e');
        });
      } else {
        final currentSession = SupabaseService.instance.client.auth.currentSession;
        if (currentSession == null) {
          PowerSyncService().disconnectSync();
          PowerSyncService().clearCache();
          SettingsProvider().clearCache();
          _hasPreloadedData = false;

          // 🧹 Securely wipe local database files to prevent data mixing across logins
          PowerSyncService().clearLocalData(reinitialize: false).catchError((e) {
            logW('Background database wipe on sign out failed: $e');
          });
        }
      }
    });
  }

  // ================================================================
  // STATUS & DEBUGGING
  // ================================================================

  Map<String, bool> getServicesStatus() {
    return {
      'AppInitialized': _isInitialized,
      'Firebase': Firebase.apps.isNotEmpty,
      'Supabase': true,
      'PowerSync': PowerSyncService().isInitialized,
      'Notifications': notificationSetup.isInitialized,
      'PreloadedData': _hasPreloadedData,
    };
  }
}

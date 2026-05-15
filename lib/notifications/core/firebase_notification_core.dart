// ================================================================
// FILE: lib/notifications/core/firebase_notification_core.dart
// Core Firebase notification service (COMPLETE - UPDATED)
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ✅ Import firebase_options
import '../../services/supabase_service.dart';
import '../../config/env_config.dart';
import '../../widgets/logger.dart';
import '../../widgets/app_snackbar.dart';
import '../../user_settings/providers/settings_provider.dart';
import '../presentation/firebase_options.dart';
import '../presentation/repository/notification_repository.dart';
import 'notification_handler_interface.dart';
import 'notification_types.dart';
import '../../features/chats/repositories/chat_repository.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class FirebaseNotificationCore {
  static final FirebaseNotificationCore _instance =
      FirebaseNotificationCore._internal();

  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();
  final NotificationRouter _router = NotificationRouter();

  bool _isInitialized = false;
  String? _fcmToken;
  BuildContext? _context;

  factory FirebaseNotificationCore() => _instance;
  FirebaseNotificationCore._internal() {
    _chatRepo = ChatRepository();
  }

  late final ChatRepository _chatRepo;
  int _lastTotalUnread = 0;

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
  NotificationRouter get router => _router;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  Future<void> initialize({BuildContext? context}) async {
    try {
      if (_isInitialized) {
        logI('✓ Firebase Notification Core already initialized');
        return;
      }

      _context = context;

      // ✅ Firebase should already be initialized by AppInitializer
      if (Firebase.apps.isEmpty) {
        logW('⚠️ Firebase not initialized. Initializing now (fallback)...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _messaging = FirebaseMessaging.instance;

      // Request permissions FIRST
      final settings = await _requestPermissions();
      logI('📱 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        logW('⚠️ User denied notification permissions');
        _isInitialized = true;
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      try {
        _fcmToken = await _messaging.getToken();
        if (_fcmToken != null) {
          logI('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');

          // Save token if user is already authenticated (Non-blocking)
          final user = SupabaseService.instance.client.auth.currentUser;
          if (user != null) {
            _saveFCMToken(_fcmToken!);
          }
        } else {
          logW('⚠️ FCM token is null - this may happen on simulator');
        }
      } catch (e) {
        logE('❌ Error getting FCM token', error: e);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        logI('🔄 FCM Token refreshed');
        _saveFCMToken(newToken);
      });

      // Setup message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        logI('📬 App opened from terminated state via notification');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }

      _isInitialized = true;
      logI('✅ Firebase Notification Core initialized successfully');

      // Listen for auth changes to save/remove token
      _setupAuthListener();
    } catch (error, stackTrace) {
      logE(
        '❌ Firebase Notification Core init error',
        error: error,
        stackTrace: stackTrace,
      );
      _isInitialized = true;
    }
  }

  // ================================================================
  // AUTH LISTENER
  // ================================================================

  void _setupAuthListener() {
    SupabaseService.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;
        if (session != null) {
          // User logged in
          if (_fcmToken != null) {
            _saveFCMToken(_fcmToken!);
          }
        } else {
          // User logged out
          if (_fcmToken != null) {
            deleteFCMToken();
          }
        }
      },
      onError: (error) {
        if (error.toString().contains('Failed host lookup') ||
            error.toString().contains('SocketException') ||
            error is SocketException) {
          logW('⚠️ Network error in notification auth listener');
        } else {
          logE('❌ Notification auth listener error', error: error);
        }
      },
    );
  }

  // ================================================================
  // PERMISSIONS
  // ================================================================

  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  // ================================================================
  // LOCAL NOTIFICATIONS
  // ================================================================

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_launcher_foreground',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    logI('✓ Local notifications initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    for (final channel in NotificationChannels.channels) {
      await androidPlugin.createNotificationChannel(channel);
    }

    logI(
      '✓ ${NotificationChannels.channels.length} notification channels created',
    );
  }

  // ================================================================
  // MESSAGE HANDLERS
  // ================================================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logI('📬 Foreground message received');
    logI('   Title: ${message.notification?.title}');
    logI('   Body: ${message.notification?.body}');
    logI('   Data: ${message.data}');

    final notificationData = NotificationData.fromRemoteMessage(message.data);

    // Check user settings to see if we should show this notification
    try {
      final channelForSettings = _mapChannelForSettings(
        notificationData.notificationType,
      );
      final shouldSend = await settingsProvider.shouldSendNotification(
        channelForSettings,
      );

      if (!shouldSend) {
        logI(
          '📵 Notification suppressed by user settings: $channelForSettings',
        );
        return;
      }
    } catch (e) {
      logW('⚠️ Could not check notification settings: $e');
    }

    // Route to handler
    await _router.routeForeground(notificationData);

    // ✅ Update Badge Indicator
    updateBadgeCount();

    // Show AppSnackbar for foreground alerts
    if (message.notification != null) {
      AppSnackbar.info(
        title: message.notification!.title ?? 'New Notification',
        message: message.notification!.body,
      );
    }

    // Show local notification with HIGH priority (for home screen/banner)
    await _showLocalNotification(message);

    // Save to Inbox (Display)
    await _addToInbox(notificationData);
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    logI('👆 Notification tapped');
    logI('   Data: ${message.data}');

    final notificationData = NotificationData.fromRemoteMessage(message.data);

    // Route to handler
    if (_context != null) {
      await _router.routeTap(_context!, notificationData);
    } else {
      logW('⚠️ No context available for notification tap navigation');
    }

    // Mark as opened = DELETE for cleanup
    final id = message.data['id'] ?? message.data['notification_id'];
    if (id != null) {
      await _repository.markAsRead(id);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    logI('👆 Local notification tapped');
    if (response.payload == null || _context == null) return;

    try {
      final decoded = jsonDecode(response.payload!);
      if (decoded is! Map<String, dynamic>) return;
      
      final notificationData = NotificationData.fromRemoteMessage(decoded);
      _router.routeTap(_context!, notificationData);
    } catch (e) {
      logE('❌ Error parsing local notification payload', error: e);
    }
  }

  // ================================================================
  // SHOW LOCAL NOTIFICATION
  // ================================================================

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      logW('⚠️ No notification payload in message');
      return;
    }

    final data = message.data;
    final notificationData = NotificationData.fromRemoteMessage(data);

    // Check for custom display from handlers
    final customDisplay = await _router.getCustomDisplay(notificationData);

    final channelId =
        notificationData.channelId ??
        notificationData.notificationType.channelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      NotificationChannels.getChannelName(channelId),
      channelDescription: NotificationChannels.getChannelDescription(channelId),
      importance: Importance.max,
      priority: Priority.high,
      icon: customDisplay?['icon'] ?? '@drawable/ic_launcher_foreground',
      playSound: customDisplay?['playSound'] ?? true,
      enableVibration: customDisplay?['vibrate'] ?? true,
      styleInformation:
          customDisplay?['styleInformation'] ??
          BigTextStyleInformation(
            customDisplay?['body'] ?? notification.body ?? '',
            htmlFormatBigText: true,
            contentTitle: customDisplay?['title'] ?? notification.title,
            htmlFormatContentTitle: true,
          ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      customDisplay?['title'] ?? notification.title,
      customDisplay?['body'] ?? notification.body,
      details,
      payload: jsonEncode(data),
    );

    logI('✓ Local notification shown');
  }

  String _mapChannelForSettings(NotificationType type) {
    switch (type.channelId) {
      case 'tasks':
        return 'tasks';
      case 'long_goals':
        return 'goals';
      case 'bucket_list':
        return 'goals';
      case 'diary':
        return 'diary';
      case 'chats':
        return 'chat';
      case 'likes':
      case 'comments':
      case 'follows':
      case 'mentions':
        return 'social';
      case 'ai_service':
        return 'ai';
      case 'system':
        return 'system';
      default:
        return 'system';
    }
  }

  // ================================================================
  // FCM TOKEN MANAGEMENT
  // ================================================================

  Future<void> _saveFCMToken(String token) async {
    try {
      final supabase = SupabaseService.instance;

      if (!supabase.isAuthenticated) {
        logI('⚠️ User not authenticated, skipping token save');
        return;
      }

      final userId = supabase.currentUserId!;

      // Save token with device info (repository handles getting device info)
      final success = await _repository.saveFCMToken(
        userId: userId,
        token: token,
        // deviceInfo and appVersion will be fetched automatically in repository
      );

      if (success) {
        logI('✓ FCM token saved to database with device info');
      } else {
        logW('⚠️ Failed to save FCM token to database');
      }
    } catch (error) {
      if (error.toString().contains('Failed host lookup') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('AuthRetryableFetchException')) {
        logW('⚠️ Network error saving FCM token - will retry later');
      } else {
        logE('❌ Save FCM token error', error: error);
      }
    }
  }

  Future<void> deleteFCMToken() async {
    try {
      final supabase = SupabaseService.instance;
      if (!supabase.isAuthenticated) return;

      final userId = supabase.currentUserId!;

      await _repository.removeFCMToken(userId);
      await _messaging.deleteToken();
      _fcmToken = null;

      logI('✓ FCM token deleted');
    } catch (error) {
      logE('❌ Delete FCM token error', error: error);
    }
  }

  // ================================================================
  // BADGE MANAGEMENT (INTERNAL)
  // ================================================================

  // Badge updates are now handled reactively by foreground/background triggers.

  /// Update the app icon badge count by querying both Chat and Notifications
  Future<void> updateBadgeCount() async {
    try {
      final userId = SupabaseService.instance.currentUserId;
      if (userId == null) {
        FlutterAppBadger.removeBadge();
        return;
      }

      // 1. Get Chat Unreads
      final chatUnread = await _chatRepo.getTotalUnreadCount(userId);

      // 2. Get Notification Unreads (from repository)
      final notifUnread = await _repository.getUnreadCount(userId);

      final total = chatUnread + notifUnread;

      if (total != _lastTotalUnread) {
        _lastTotalUnread = total;
        if (total > 0) {
          FlutterAppBadger.updateBadgeCount(total);
          logD('🔢 App icon badge set to: $total');
        } else {
          FlutterAppBadger.removeBadge();
          logD('🔢 App icon badge removed');
        }
      }
    } catch (e) {
      logW('⚠️ Badge update failed: $e');
    }
  }

  /// Manually reset/clear the badge
  void clearBadge() {
    _lastTotalUnread = 0;
    FlutterAppBadger.removeBadge();
  }

  // ================================================================
  // INBOX MANAGEMENT
  // ================================================================

  Future<void> _addToInbox(NotificationData data) async {
    try {
      final supabase = SupabaseService.instance;
      if (!supabase.isAuthenticated) return;

      final userId = supabase.currentUserId!;

      await _repository.saveToInbox(
        userId: userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data,
      );
    } catch (error) {
      logE('❌ Add to Inbox error', error: error);
    }
  }

  // ================================================================
  // TOPIC SUBSCRIPTION
  // ================================================================

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      logI('✓ Subscribed to topic: $topic');
    } catch (error) {
      logE('❌ Subscribe to topic error', error: error);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      logI('✓ Unsubscribed from topic: $topic');
    } catch (error) {
      logE('❌ Unsubscribe from topic error', error: error);
    }
  }

  // ================================================================
  // CONTEXT UPDATE
  // ================================================================

  void updateContext(BuildContext context) {
    _context = context;
  }

  // ================================================================
  // CLEANUP
  // ================================================================

  Future<void> dispose() async {
    await deleteFCMToken();
    _isInitialized = false;
    _context = null;
    logI('✓ Firebase Notification Core disposed');
  }
}

// ================================================================
// BACKGROUND MESSAGE HANDLER (Must be top-level function)
// ================================================================

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Essential Services for Background Isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EnvConfig.load();
  await SupabaseService().initialize();

  // 2. Log receipt
  logI('📨 Background message received: ${message.messageId}');

  final notificationData = NotificationData.fromRemoteMessage(message.data);

  // 3. Save to Inbox (CRITICAL: Most apps miss this in background)
  // We use a direct NotificationRepository instance as we might not have the fully initialized singleton
  try {
    final repo = NotificationRepository();
    final userId = message.data['user_id']; // Prefer data field if available

    if (userId != null) {
      await repo.saveToInbox(
        userId: userId,
        type: notificationData.type,
        title: notificationData.title,
        body: notificationData.body,
        data: notificationData.data,
      );
      logI('✓ Background notification saved to inbox');
    }
  } catch (e) {
    logW('⚠️ Failed to save background notification to inbox: $e');
  }

  // 4. Route to specific handlers (if any need background processing)
  await NotificationRouter().routeBackground(notificationData);

  // ✅ Badge update — wrapped in try/catch because platform channels
  // are NOT guaranteed in background isolates
  try {
    final repo = NotificationRepository();
    final userId = message.data['user_id'] ?? message.data['userId'];
    if (userId != null) {
      final chatRepo = ChatRepository();
      final chatUnread = await chatRepo.getTotalUnreadCount(userId);
      final notifUnread = await repo.getUnreadCount(userId);
      final total = chatUnread + notifUnread;

      // ✅ Platform channel call isolated — will not crash handler if it fails
      try {
        if (total > 0) {
          FlutterAppBadger.updateBadgeCount(total);
        } else {
          FlutterAppBadger.removeBadge();
        }
        logI('✓ Background badge updated to: $total');
      } catch (badgeError) {
        // Platform channels not available in background isolate — this is expected
        logW('⚠️ Badge update not available in background isolate (expected): $badgeError');
      }
    }
  } catch (e) {
    logW('⚠️ Could not compute badge count in background: $e');
  }
}

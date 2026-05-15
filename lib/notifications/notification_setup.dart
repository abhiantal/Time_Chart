// ================================================================
// FILE: lib/notifications/notification_setup.dart
// Main notification setup - Register all handlers here
// ================================================================

import 'package:flutter/material.dart';
import '../widgets/logger.dart';
import 'core/firebase_notification_core.dart';
import 'core/notification_handler_interface.dart';
import 'handlers/dashboard_notification_handler.dart';
import 'handlers/day_task_notification_handler.dart';
import 'handlers/week_task_notification_handler.dart';
import 'handlers/diary_notification_handler.dart';
import 'handlers/chat_notification_handler.dart';
import 'handlers/social_notification_handler.dart';
import 'handlers/system_notification_handler.dart';
import 'handlers/long_goals_notification_handler.dart';
import 'handlers/bucket_notification_handler.dart';
import 'handlers/ai_notification_handler.dart';
import 'handlers/competition_notification_handler.dart';
import 'handlers/mentoring_notification_handler.dart';



/// Main notification setup class
class NotificationSetup with WidgetsBindingObserver {
  static final NotificationSetup _instance = NotificationSetup._internal();
  factory NotificationSetup() => _instance;
  NotificationSetup._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final FirebaseNotificationCore _core = FirebaseNotificationCore();
  final NotificationRouter _router = NotificationRouter();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseNotificationCore get core => _core;
  NotificationRouter get router => _router;

  // ================================================================
  // LIFECYCLE
  // ================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      logI('🔄 App resumed: Refreshing badges...');
      _core.updateBadgeCount();
    }
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================

  /// Initialize notification system
  Future<void> initialize({BuildContext? context}) async {
    try {
      if (_isInitialized) {
        logI('✓ Notifications already initialized');
        return;
      }

      logI('🔔 Initializing notification system...');

      // Initialize Firebase Core
      await _core.initialize(context: context);

      // Register all handlers
      _registerHandlers();

      _isInitialized = true;
      logI('✅ Notification system initialized');

      // Print status
      _router.printHandlers();
    } catch (error, stackTrace) {
      logE('Notification setup error', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Register all notification handlers
  void _registerHandlers() {
    logI('📋 Registering notification handlers...');

    final handlers = [
      DayTaskNotificationHandler(),
      WeekTaskNotificationHandler(),
      DiaryNotificationHandler(),
      ChatNotificationHandler(),
      SocialNotificationHandler(),
      SystemNotificationHandler(),
      LongGoalsNotificationHandler(),
      BucketNotificationHandler(),
      AiNotificationHandler(),
      CompetitionNotificationHandler(),
      MentoringNotificationHandler(),
      DashboardNotificationHandler(),
    ];

    for (var handler in handlers) {
      _router.registerHandler(handler);
    }

    logI('✓ ${_router.handlers.length} handlers registered');
  }

  // ================================================================
  // CONTEXT UPDATE
  // ================================================================

  void updateContext(BuildContext context) {
    _core.updateContext(context);
  }

  // ================================================================
  // FCM TOKEN MANAGEMENT
  // ================================================================

  String? get fcmToken => _core.fcmToken;

  Future<void> deleteFCMToken() async {
    await _core.deleteFCMToken();
  }

  // ================================================================
  // TOPIC SUBSCRIPTION
  // ================================================================

  Future<void> subscribeToTopic(String topic) async {
    await _core.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _core.unsubscribeFromTopic(topic);
  }

  // ================================================================
  // HANDLER MANAGEMENT
  // ================================================================

  void registerHandler(NotificationHandler handler) {
    _router.registerHandler(handler);
  }

  void unregisterHandler(String handlerId) {
    _router.unregisterHandler(handlerId);
  }

  List<NotificationHandler> get handlers => _router.handlers;

  // ================================================================
  // CLEANUP
  // ================================================================

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _core.dispose();
    _router.clearHandlers();
    _isInitialized = false;
    logI('✓ Notification system disposed');
  }

  Future<void> reset() async {
    _router.clearHandlers();
    _registerHandlers();
    logI('✓ Notification system reset');
  }
}

/// Global notification setup instance
final notificationSetup = NotificationSetup();


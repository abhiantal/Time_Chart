// ================================================================
// FILE: lib/notifications/handlers/leaderboard_notification_handler.dart
// Handles Leaderboard-related notifications
// ================================================================

import 'package:flutter/material.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class LeaderboardNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'leaderboard_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.leaderboardTop100,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('👑 Leaderboard Notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('👑 Leaderboard Notification (Foreground): ${data.type}');
    return true; 
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('👑 Leaderboard Notification (Background): ${data.type}');
    return true; 
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    switch (data.notificationType) {
      case NotificationType.leaderboardTop100:
        return {
          'icon': '@drawable/ic_leaderboard',
          'title': '👑 Top 100 Milestone!',
          'body': data.body,
        };
      default:
        return null;
    }
  }
}

// ================================================================
// FILE: lib/notifications/handlers/diary_notification_handler.dart
// Diary notification handler
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class DiaryNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'diary_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.diaryEveningReminder,
    NotificationType.diaryStreakMilestone,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🔔 Diary notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🔔 Diary notification in foreground: ${data.type}');
    return true;
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🔔 Diary notification in background: ${data.type}');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    try {
      switch (data.notificationType) {
        case NotificationType.diaryEveningReminder:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '📔 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#8BC34A',
          };

        case NotificationType.diaryStreakMilestone:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🔥 ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#FF5722',
          };

        default:
          return null;
      }
    } catch (e) {
      logE('❌ Error customizing notification display: $e');
      return null;
    }
  }
}

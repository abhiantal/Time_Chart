// ================================================================
// FILE: lib/notifications/handlers/week_task_notification_handler.dart
// Week Task notification handler
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class WeekTaskNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'week_task_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.weeklyTaskReminder,
    NotificationType.weeklyTaskStarted,
    NotificationType.weeklyTaskFeedback,
    NotificationType.weeklyTaskDeadline,
    NotificationType.weeklyTaskCompleted,
    NotificationType.weeklyTaskStatus,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🔔 Week task notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🔔 Week task notification in foreground: ${data.type}');

    try {
      switch (data.notificationType) {
        case NotificationType.weeklyTaskDeadline:
          logI('⏰ Week task deadline approaching: ${data.title}');
          break;

        case NotificationType.weeklyTaskCompleted:
          logI('✅ Task completed: ${data.title}');
          break;

        case NotificationType.weeklyTaskStarted:
          logI('🚀 Task started: ${data.title}');
          break;

        default:
          logI('ℹ️ Standard foreground notification');
      }

      return true;
    } catch (e) {
      logE('❌ Error handling foreground notification: $e');
      return false;
    }
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🔔 Week task notification in background: ${data.type}');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    try {
      switch (data.notificationType) {
        case NotificationType.weeklyTaskReminder:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '⏰ ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#2196F3',
          };
        case NotificationType.weeklyTaskDeadline:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'vibrate': true,
            'title': '⏰ ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#FF5252',
          };

        case NotificationType.weeklyTaskCompleted:
        case NotificationType.weeklyTaskStatus:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '✅ ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#4CAF50',
          };

        case NotificationType.weeklyTaskStarted:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🚀 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#2196F3',
          };

        case NotificationType.weeklyTaskFeedback:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '📝 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#9C27B0',
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

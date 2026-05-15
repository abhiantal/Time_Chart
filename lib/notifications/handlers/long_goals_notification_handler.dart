// ================================================================
// FILE: lib/notifications/handlers/long_goals_notification_handler.dart
// Long Goals notification handler
// ================================================================

import 'package:flutter/material.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class LongGoalsNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'long_goals_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.longGoalCreated,
    NotificationType.longGoalDeadline,
    NotificationType.longGoalMilestone,
    NotificationType.longGoalReminder,
    NotificationType.longGoalStarted,
    NotificationType.longGoalFeedback,
    NotificationType.longGoalOverdue,
    NotificationType.longGoalStatus,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🔔 Long goal notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🔔 Long goal notification in foreground: ${data.type}');

    try {
      switch (data.notificationType) {
        case NotificationType.longGoalDeadline:
          logI('⏰ Goal deadline approaching: ${data.title}');
          break;

        case NotificationType.longGoalStatus:
          logI('🏆 Goal status update: ${data.title}');
          break;

        case NotificationType.longGoalStarted:
          logI('🚀 Goal started: ${data.title}');
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
    logI('🔔 Long goal notification in background: ${data.type}');

    try {
      switch (data.notificationType) {
        case NotificationType.longGoalMilestone:
          logI('🎯 Milestone reached, updating cache');
          break;

        case NotificationType.longGoalStatus:
          logI('✅ Goal status updated');
          break;

        default:
          logI('ℹ️ Standard background notification');
      }

      return true;
    } catch (e) {
      logE('❌ Error handling background notification: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    try {
      switch (data.notificationType) {
        case NotificationType.longGoalDeadline:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'vibrate': true,
            'title': '⏰ ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#FF5252',
          };

        case NotificationType.longGoalMilestone:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🎯 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#4CAF50',
          };

        case NotificationType.longGoalStatus:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'vibrate': true,
            'title': '🎉 ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#FFD700',
          };

        case NotificationType.longGoalReminder:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🔔 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#9C27B0',
          };

        case NotificationType.longGoalStarted:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🚀 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#2196F3',
          };

        default:
          return null;
      }
    } catch (e) {
      logE('❌ Error customizing notification display: $e');
      return null;
    }
  }

  // ================================================================
  // NAVIGATION METHODS
  // ================================================================

  /// Get notification title with emoji
  String getNotificationTitle(NotificationType type, String baseTitle) {
    switch (type) {
      case NotificationType.longGoalReminder:
        return '🔔 $baseTitle';
      case NotificationType.longGoalMilestone:
        return '🎯 $baseTitle';
      case NotificationType.longGoalDeadline:
        return '⏰ $baseTitle';
      case NotificationType.longGoalStatus:
        return '🎉 $baseTitle';
      case NotificationType.longGoalStarted:
        return '🚀 $baseTitle';
      default:
        return baseTitle;
    }
  }
}

// ================================================================
// FILE: lib/notifications/handlers/day_task_notification_handler.dart
// Handles all day task notifications with comprehensive timing support
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';

import '../../core/navigation/notification_navigation_handler.dart';

class DayTaskNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'day_task_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.dayTaskReminder,
    NotificationType.dayTaskStarted,
    NotificationType.dayTaskFeedback,
    NotificationType.dayTaskOverdue,
    NotificationType.dayTaskCompleted,
    NotificationType.dayTaskStatus,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🔔 Day task notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🔔 Day task notification in foreground: ${data.type}');

    // You can trigger UI updates here
    // Example: Refresh task list, show in-app alert, etc.

    return true;
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🔔 Day task notification in background: ${data.type}');

    // Background processing
    // Example: Update local cache, sync data, etc.

    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    // Customize notification display based on task notification type
    switch (data.notificationType) {
        case NotificationType.dayTaskReminder:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '⏰ ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#2196F3',
          };
        case NotificationType.dayTaskStarted:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🚀 ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#4CAF50',
          };
        case NotificationType.dayTaskFeedback:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '📝 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#FF9800',
          };
        case NotificationType.dayTaskOverdue:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'vibrate': true,
            'title': '⚠️ ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#F44336',
          };
        case NotificationType.dayTaskCompleted:
        case NotificationType.dayTaskStatus:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '✨ ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#9C27B0',
          };
      default:
        return null;
    }
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  Future<void> _navigateBasedOnType(
    BuildContext context,
    NotificationType type,
    String taskId,
    String? date,
  ) async {
    logI('→ Navigating for task notification: ${type.value}');

    // For now, all notifications go to the day schedule screen
    // You can refine this to open specific dialogs or bottom sheets once on the screen
    await _navigateToTaskDetail(context, taskId, date);
  }

  /// Navigate to task detail screen
  Future<void> _navigateToTaskDetail(
    BuildContext context,
    String taskId,
    String? date,
  ) async {
    try {
      DateTime? parsedDate;
      if (date != null) {
        parsedDate = DateTime.tryParse(date);
      }

      context.goNamed('dayScheduleScreen', extra: {'date': parsedDate});

      logI('✓ Navigated to task detail: $taskId');
    } catch (e) {
      logE('❌ Navigation error', error: e);
      // Fallback: Navigate to main nav
      context.goNamed('personalNav');
    }
  }

  /// Navigate to task feedback screen
  Future<void> _navigateToTaskFeedback(
    BuildContext context,
    String taskId,
    String? date,
  ) async {
    try {
      // Navigate to add/view feedback screen
      // Currently mapping to day schedule as feedback might be a modal there
      await _navigateToTaskDetail(context, taskId, date);

      logI('✓ Navigated to task feedback: $taskId');
    } catch (e) {
      logE('❌ Navigation error', error: e);
      // Fallback: Navigate to task detail
      await _navigateToTaskDetail(context, taskId, date);
    }
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  /// Get notification message based on type
  String getNotificationMessage(NotificationType type, String taskName) {
    switch (type) {
      case NotificationType.dayTaskStarted:
        return '$taskName has started!';
      case NotificationType.dayTaskFeedback:
        return 'How is $taskName going?';
      case NotificationType.dayTaskOverdue:
        return '$taskName is overdue!';
      case NotificationType.dayTaskCompleted:
        return 'You completed $taskName!';
      default:
        return taskName;
    }
  }

  /// Get notification title based on type
  String getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.dayTaskStarted:
        return 'Task Started';
      case NotificationType.dayTaskFeedback:
        return 'Feedback Needed';
      case NotificationType.dayTaskOverdue:
        return 'Task Overdue';
      case NotificationType.dayTaskCompleted:
        return 'Task Completed';
      default:
        return 'Task Notification';
    }
  }
}

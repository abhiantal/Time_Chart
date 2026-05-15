// ================================================================
// FILE: lib/notifications/handlers/analytics_notification_handler.dart
// Handles Analytics-related notifications (Weekly reports, etc.)
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class DashboardNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'dashboard_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.dashboardNewReward,
    NotificationType.dashboardStreakLost,
    NotificationType.dashboardNoActivity,
    NotificationType.dashboardStreakWarning,
    NotificationType.dashboardStreakStatus,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('📊 Analytics Notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('📊 Analytics Notification (Foreground): ${data.type}');
    return true; 
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('📊 Analytics Notification (Background): ${data.type}');
    return true; 
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    switch (data.notificationType) {
      case NotificationType.dashboardNewReward:
        return {
          'icon': '@drawable/ic_reward',
          'title': '🎁 New Reward Available!',
          'body': data.body,
        };
      case NotificationType.dashboardStreakLost:
        return {
          'icon': '@drawable/ic_warning',
          'title': '💔 Streak Lost',
          'body': data.body,
        };
      case NotificationType.dashboardNoActivity:
        return {
          'icon': '@drawable/ic_activity',
          'title': '💤 No Activity Detected',
          'body': data.body,
        };
      case NotificationType.dashboardStreakWarning:
        return {
          'icon': '@drawable/ic_warning',
          'title': '⚠️ Streak at Risk!',
          'body': data.body,
        };
      case NotificationType.dashboardStreakStatus:
        return {
          'icon': '@drawable/ic_streak',
          'title': '🔥 Streak Update',
          'body': data.body,
        };
      default:
        return null;
    }
  }
}

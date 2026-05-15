// ================================================================
// FILE: lib/notifications/handlers/bucket_notification_handler.dart
// Bucket List notification handler
// ================================================================

import 'package:flutter/material.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';

import '../../core/navigation/notification_navigation_handler.dart';

class BucketNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'bucket_handler';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.bucketMorningReminder,
    NotificationType.bucketCompleted,
    NotificationType.bucketOverdueEvening,
    NotificationType.bucketMissedYear,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🔔 Bucket notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🔔 Bucket notification in foreground: ${data.type}');

    try {
      switch (data.notificationType) {
        case NotificationType.bucketMorningReminder:
          logI('🌅 Morning reminder: ${data.title}');
          break;

        case NotificationType.bucketCompleted:
          logI('🎉 Bucket item completed: ${data.title}');
          // TODO: Show celebration animation
          break;

        case NotificationType.bucketOverdueEvening:
          logI('🌙 Overdue evening reflection');
          break;

        case NotificationType.bucketMissedYear:
          logI('🎆 Year end notice');
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
    logI('🔔 Bucket notification in background: ${data.type}');

    try {
      switch (data.notificationType) {
        case NotificationType.bucketCompleted:
          logI('✅ Bucket item completed, updating database');
          // TODO: Update completion status
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
        case NotificationType.bucketMorningReminder:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🌅 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#00BCD4',
          };

        case NotificationType.bucketCompleted:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'vibrate': true,
            'title': '🎉 ${data.title}',
            'body': data.body,
            'priority': 'high',
            'color': '#2196F3',
          };

        case NotificationType.bucketOverdueEvening:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🌙 ${data.title}',
            'body': data.body,
            'priority': 'default',
            'color': '#FF9800',
          };

        case NotificationType.bucketMissedYear:
          return {
            'icon': '@mipmap/ic_notification',
            'playSound': true,
            'title': '🎆 ${data.title}',
            'body': data.body,
            'priority': 'high',
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

  /// Get notification title with emoji
  String getNotificationTitle(NotificationType type, String baseTitle) {
    switch (type) {
      case NotificationType.bucketMorningReminder:
        return '🌅 $baseTitle';
      case NotificationType.bucketCompleted:
        return '🎉 $baseTitle';
      case NotificationType.bucketOverdueEvening:
        return '🌙 $baseTitle';
      case NotificationType.bucketMissedYear:
        return '🎆 $baseTitle';
      default:
        return baseTitle;
    }
  }
}

// ================================================================
// FILE: lib/notifications/handlers/mentoring_notification_handler.dart
// Handles all Mentoring & Data Sharing notifications
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class MentoringNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'mentoring_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.mentorshipRequest,
    NotificationType.mentorshipResponse,
    NotificationType.mentorshipEncouragement,
    NotificationType.menteeMilestone,
    NotificationType.expiryWarning,
    NotificationType.expired,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🎓 Mentoring Notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🎓 Mentoring (Foreground): ${data.type}');
    return true;
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🎓 Mentoring (Background): ${data.type}');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    switch (data.notificationType) {
      case NotificationType.mentorshipRequest:
        return {
          'icon': '@drawable/ic_mentoring_request',
          'title': '🤝 New Mentorship Request',
          'body': data.body,
        };
      case NotificationType.mentorshipResponse:
        return {
          'icon': '@drawable/ic_mentoring_response',
          'title': '✅ Mentorship Response',
          'body': data.body,
        };
      case NotificationType.mentorshipEncouragement:
        return {
          'icon': '@drawable/ic_encouragement',
          'title': '✨ Mentor Encouragement',
          'body': data.body,
        };
      case NotificationType.menteeMilestone:
        return {
          'icon': '@drawable/ic_milestone',
          'title': '🎉 Mentee Milestone!',
          'body': data.body,
        };
      case NotificationType.expiryWarning:
        return {
          'icon': '@drawable/ic_warning',
          'title': '⚠️ Access Expiring Soon',
          'body': data.body,
        };
      case NotificationType.expired:
        return {
          'icon': '@drawable/ic_expired',
          'title': '🚫 Access Expired',
          'body': data.body,
        };
      default:
        return null;
    }
  }
}

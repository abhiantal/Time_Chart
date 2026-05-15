// ================================================================
// FILE: lib/notifications/handlers/competition_notification_handler.dart
// Handles Competition & Challenge notifications
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';
import '../../core/navigation/notification_navigation_handler.dart';

class CompetitionNotificationHandler extends NotificationHandler {
  @override
  String get handlerId => 'competition_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.competitionAddedAsMember,
    NotificationType.competitionNoOpponents,
    NotificationType.competitionEmptySlots,
    NotificationType.competitionLosing,
    NotificationType.leaderboardTop100,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logI('🏆 Competition Notification tapped: ${data.type}');

    // Delegate to central navigation handler
    await NotificationNavigationHandler.instance.navigateForNotification(
      context,
      data,
    );
    return true;
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logI('🏆 Competition (Foreground): ${data.type}');
    return true;
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logI('🏆 Competition (Background): ${data.type}');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    switch (data.notificationType) {
      case NotificationType.competitionAddedAsMember:
        return {
          'icon': '@drawable/ic_challenge',
          'title': '🤝 New Competition!',
          'body': data.body,
        };
      case NotificationType.competitionNoOpponents:
        return {
          'icon': '@drawable/ic_warning',
          'title': '👤 No Opponents Yet',
          'body': data.body,
        };
      case NotificationType.competitionEmptySlots:
        return {
          'icon': '@drawable/ic_slots',
          'title': '🗂️ Empty Slots Available',
          'body': data.body,
        };
      case NotificationType.competitionLosing:
        return {
          'icon': '@drawable/ic_losing',
          'title': '📉 Ranking Dropped',
          'body': data.body,
        };
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

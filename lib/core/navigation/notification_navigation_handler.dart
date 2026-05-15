// ================================================================
// FILE: lib/core/navigation/notification_navigation_handler.dart
// Centralized navigation handler for all notification types
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/core/notification_types.dart';
import '../../widgets/logger.dart';

class NotificationNavigationHandler {
  static final NotificationNavigationHandler _instance =
      NotificationNavigationHandler._internal();
  static NotificationNavigationHandler get instance => _instance;
  NotificationNavigationHandler._internal();

  /// Main entry point for notification navigation
  Future<void> navigateForNotification(
    BuildContext context,
    NotificationData data,
  ) async {
    final type = data.notificationType;
    final payload = data.data;
    final targetId = data.targetId;

    logI('🚀 Navigating for notification: ${type.value} (Target: $targetId)');

    try {
      switch (type) {
        // --- SOCIAL & CHAT ---
        case NotificationType.follow:
          final senderId = payload['sender_id'] ?? payload['userId'];
          if (senderId != null) {
            context.pushNamed(
              'otherUserProfileScreen',
              pathParameters: {'userId': senderId},
            );
          }
          break;

        case NotificationType.like:
        case NotificationType.comment:
        case NotificationType.reply:
        case NotificationType.mention:
          if (targetId != null) {
            context.pushNamed(
              'userPostFeed',
              extra: {'initialPostId': targetId, 'title': 'Post'},
            );
          }
          break;

        case NotificationType.chatMessage:
        case NotificationType.chatMention:
          if (targetId != null) {
            context.pushNamed(
              'chatConversationScreen',
              pathParameters: {'chatId': targetId},
            );
          }
          break;

        case NotificationType.chatInviteReceived:
          context.pushNamed('chatHubScreen');
          break;

        // --- PERSONAL: DAY TASKS ---
        case NotificationType.dayTaskReminder:
        case NotificationType.dayTaskStarted:
        case NotificationType.dayTaskFeedback:
        case NotificationType.dayTaskOverdue:
        case NotificationType.dayTaskCompleted:
        case NotificationType.dayTaskStatus:
          context.goNamed('dayScheduleScreen');
          break;

        // --- PERSONAL: WEEKLY TASKS ---
        case NotificationType.weeklyTaskReminder:
        case NotificationType.weeklyTaskStarted:
        case NotificationType.weeklyTaskFeedback:
        case NotificationType.weeklyTaskDeadline:
        case NotificationType.weeklyTaskCompleted:
        case NotificationType.weeklyTaskStatus:
          final taskId = targetId ?? payload['task_id'];
          if (taskId != null) {
            context.pushNamed(
              'weeklyTaskDailyAnalysisScreen',
              pathParameters: {'taskId': taskId},
            );
          } else {
            context.goNamed('weeklyScheduleScreen');
          }
          break;

        // --- PERSONAL: LONG GOALS ---
        case NotificationType.longGoalCreated:
        case NotificationType.longGoalDeadline:
        case NotificationType.longGoalMilestone:
        case NotificationType.longGoalReminder:
        case NotificationType.longGoalStarted:
        case NotificationType.longGoalFeedback:
        case NotificationType.longGoalOverdue:
        case NotificationType.longGoalStatus:
          final goalId = targetId ?? payload['goal_id'];
          if (goalId != null) {
            context.pushNamed(
              'longGoalDetailScreen',
              pathParameters: {'goalId': goalId},
            );
          } else {
            context.goNamed('longGoalsHomeScreen');
          }
          break;

        // --- PERSONAL: BUCKET LIST ---
        case NotificationType.bucketMorningReminder:
        case NotificationType.bucketCompleted:
        case NotificationType.bucketOverdueEvening:
        case NotificationType.bucketMissedYear:
          final bucketId = targetId ?? payload['bucket_id'];
          if (bucketId != null) {
            context.pushNamed(
              'bucketDetailScreen',
              pathParameters: {'bucketId': bucketId},
            );
          } else {
            context.goNamed('personalNav');
          }
          break;

        // --- PERSONAL: DIARY ---
        case NotificationType.diaryEveningReminder:
        case NotificationType.diaryStreakMilestone:
          context.goNamed('diaryListScreen');
          break;

        // --- ANALYTICS: DASHBOARD ---
        case NotificationType.dashboardNewReward:
        case NotificationType.dashboardStreakLost:
        case NotificationType.dashboardNoActivity:
        case NotificationType.dashboardStreakWarning:
        case NotificationType.dashboardStreakStatus:
          context.goNamed('dashboardScreen');
          break;

        // --- ANALYTICS: COMPETITION & LEADERBOARD ---
        case NotificationType.competitionAddedAsMember:
        case NotificationType.competitionNoOpponents:
        case NotificationType.competitionEmptySlots:
        case NotificationType.competitionLosing:
        case NotificationType.leaderboardTop100:
          final battleId = targetId ?? payload['battle_id'];
          if (battleId != null) {
            context.pushNamed(
              'competitionDetailScreen',
              pathParameters: {'competitorId': battleId},
            );
          } else {
            context.pushNamed('competitionOverviewScreen');
          }
          break;

        // --- ANALYTICS: MENTORSHIP ---
        case NotificationType.mentorshipRequest:
        case NotificationType.mentorshipResponse:
        case NotificationType.mentorshipEncouragement:
        case NotificationType.menteeMilestone:
        case NotificationType.expiryWarning:
        case NotificationType.expired:
          context.pushNamed('mentoringHubScreen');
          break;

        // --- SYSTEM ---
        case NotificationType.systemUpdate:
        case NotificationType.announcement:
        case NotificationType.maintenance:
        case NotificationType.systemAlert:
          context.pushNamed('settingsScreen');
          break;

        case NotificationType.aiInsightReady:
          context.pushNamed('dashboardScreen');
          break;

        case NotificationType.aiTokenLimit:
        case NotificationType.aiTokenLimitReached:
        case NotificationType.aiTokenWarning:
          context.pushNamed('settingsScreen');
          break;

        default:
          logW(
            '⚠️ No specific navigation for notification type: ${type.value}',
          );
          break;
      }
    } catch (e, stackTrace) {
      logE(
        '❌ Navigation error for notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

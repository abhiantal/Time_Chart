// ================================================================
// FILE: lib/notifications/core/notification_types.dart
// All notification types and channel definitions
// ================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification types enum
enum NotificationType {
  // Personal Module - Bucket List
  bucketMorningReminder('bucket_morning_reminder', 'bucket_list'),
  bucketCompleted('bucket_completed', 'bucket_list'),
  bucketOverdueEvening('bucket_overdue_evening', 'bucket_list'),
  bucketMissedYear('bucket_missed_year', 'bucket_list'),

  // Personal Module - Day Tasks
  dayTaskReminder('day_task_reminder', 'tasks'),
  dayTaskStarted('day_task_started', 'tasks'),
  dayTaskFeedback('day_task_feedback', 'tasks'),
  dayTaskOverdue('day_task_overdue', 'tasks'),
  dayTaskCompleted('day_task_completed', 'tasks'),
  dayTaskStatus('day_task_status', 'tasks'),

  // Personal Module - Diary
  diaryEveningReminder('diary_evening_reminder', 'diary'),
  diaryStreakMilestone('diary_streak_milestone', 'diary'),

  // Personal Module - Long Goals
  longGoalCreated('long_goal_created', 'long_goals'),
  longGoalDeadline('long_goal_deadline', 'long_goals'),
  longGoalMilestone('long_goal_milestone', 'long_goals'),
  longGoalReminder('long_goal_reminder', 'long_goals'),
  longGoalStarted('long_goal_started', 'long_goals'),
  longGoalFeedback('long_goal_feedback', 'long_goals'),
  longGoalOverdue('long_goal_overdue', 'long_goals'),
  longGoalStatus('long_goal_status', 'long_goals'),

  // Personal Module - Weekly Tasks
  weeklyTaskReminder('weekly_task_reminder', 'tasks'),
  weeklyTaskStarted('weekly_task_started', 'tasks'),
  weeklyTaskFeedback('weekly_task_feedback', 'tasks'),
  weeklyTaskDeadline('weekly_task_deadline', 'tasks'),
  weeklyTaskCompleted('weekly_task_completed', 'tasks'),
  weeklyTaskStatus('weekly_task_status', 'tasks'),

  // Analytics Module - Competition
  competitionAddedAsMember('competition_added_as_member', 'competition'),
  competitionNoOpponents('competition_no_opponents', 'competition'),
  competitionEmptySlots('competition_empty_slots', 'competition'),
  competitionLosing('competition_losing', 'competition'),

  // Analytics Module - Dashboard
  dashboardNewReward('dashboard_new_reward', 'analytics'),
  dashboardStreakLost('dashboard_streak_lost', 'analytics'),
  dashboardNoActivity('dashboard_no_activity', 'analytics'),
  dashboardStreakWarning('dashboard_streak_warning', 'analytics'),
  dashboardStreakStatus('dashboard_streak_status', 'analytics'),

  // Analytics Module - Leaderboard
  leaderboardTop100('leaderboard_top_100', 'competition'),

  // Analytics Module - Mentorship
  mentorshipRequest('mentorship_request', 'mentoring'),
  mentorshipResponse('mentorship_response', 'mentoring'),
  mentorshipEncouragement('mentorship_encouragement', 'mentoring'),
  menteeMilestone('mentee_milestone', 'mentoring'),
  expiryWarning('expiry_warning', 'mentoring'),
  expired('expired', 'mentoring'),

  // Social & Chat
  chatMessage('chat_message', 'chats'),
  chatMention('chat_mention', 'chats'),
  chatInviteReceived('chat_invite_received', 'chats'),

  like('like', 'likes'),
  comment('comment', 'comments'),
  reply('reply', 'comments'),
  follow('follow', 'follows'),
  mention('mention', 'mentions'),

  // System & AI
  aiTokenWarning('ai_token_warning', 'ai_service'),
  aiTokenLimit('ai_token_limit', 'ai_service'),
  aiTokenLimitReached('ai_token_limit_reached', 'ai_service'),
  aiInsightReady('ai_insight_ready', 'ai_service'),

  systemUpdate('system_update', 'system'),
  systemAlert('system_alert', 'system'),
  announcement('announcement', 'system'),
  maintenance('maintenance', 'system'),

  // Default
  defaultType('default', 'default');

  final String value;
  final String channelId;

  const NotificationType(this.value, this.channelId);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.defaultType,
    );
  }
}

/// Notification channel definitions
class NotificationChannels {
  static const List<AndroidNotificationChannel> channels = [
    AndroidNotificationChannel(
      'default',
      'Default Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    ),
    AndroidNotificationChannel(
      'tasks',
      'Task Reminders',
      description: 'Task deadlines and reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      'long_goals',
      'Long Goals',
      description: 'Long-term goal reminders, milestones, and progress updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'bucket_list',
      'Bucket List',
      description: 'Bucket list items, milestones, and completion reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'diary',
      'Diary',
      description: 'Daily diary reminders and prompts',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      'chats',
      'Messages',
      description: 'New chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'likes',
      'Likes',
      description: 'Someone liked your content',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'comments',
      'Comments',
      description: 'Comments and replies',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'follows',
      'Follows',
      description: 'New followers',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'mentions',
      'Mentions',
      description: 'Someone mentioned you',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'ai_service',
      'AI Service',
      description: 'AI token usage and service notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      'analytics',
      'Analytics',
      description: 'Weekly reports and productivity insights',
      importance: Importance.defaultImportance,
      playSound: true,
    ),
    AndroidNotificationChannel(
      'competition',
      'Competition',
      description: 'Challenges, leaderboards and tournaments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      'mentoring',
      'Mentoring',
      description: 'Connect with mentors and track shared progress',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ),
    AndroidNotificationChannel(
      'system',
      'System Notifications',
      description: 'App updates and announcements',
      importance: Importance.defaultImportance,
    ),
  ];

  static String getChannelName(String channelId) {
    return channels
        .firstWhere((c) => c.id == channelId, orElse: () => channels.first)
        .name;
  }

  static String getChannelDescription(String channelId) {
    return channels
            .firstWhere((c) => c.id == channelId, orElse: () => channels.first)
            .description ??
        '';
  }
}

/// Notification data models
class NotificationData {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? userId;
  final String? targetId;
  final String? channelId;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.userId,
    this.targetId,
    this.channelId,
  });

  factory NotificationData.fromRemoteMessage(Map<String, dynamic> data) {
    return NotificationData(
      type: data['type'] ?? 'default',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data),
      userId: data['userId'],
      targetId: data['targetId'],
      channelId: data['channelId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'body': body,
    'data': data,
    'userId': userId,
    'targetId': targetId,
    'channelId': channelId,
  };

  NotificationType get notificationType => NotificationType.fromString(type);
}

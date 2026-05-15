// ================================================================
// FILE: lib/features/mentoring/models/mentoring.dart
// Complete model for mentorship_connections table
// ================================================================

import 'dart:convert';
import 'package:flutter/material.dart';

// ================================================================
// ENUMS
// ================================================================

/// How was this connection initiated?
enum RequestType {
  requestAccess, // Mentor requests to see Owner's data
  offerShare; // Owner offers to share with Mentor

  String get value {
    switch (this) {
      case RequestType.requestAccess:
        return 'request_access';
      case RequestType.offerShare:
        return 'offer_share';
    }
  }

  String get label {
    switch (this) {
      case RequestType.requestAccess:
        return 'Access Request';
      case RequestType.offerShare:
        return 'Share Offer';
    }
  }

  static RequestType fromString(String? value) {
    switch (value) {
      case 'request_access':
        return RequestType.requestAccess;
      case 'offer_share':
        return RequestType.offerShare;
      default:
        return RequestType.requestAccess;
    }
  }
}

/// Current request status
enum RequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  expired;

  String get value => name;

  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.expired:
        return 'Expired';
    }
  }

  String get emoji {
    switch (this) {
      case RequestStatus.pending:
        return '⏳';
      case RequestStatus.approved:
        return '✅';
      case RequestStatus.rejected:
        return '❌';
      case RequestStatus.cancelled:
        return '🚫';
      case RequestStatus.expired:
        return '⏰';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.pending:
        return const Color(0xFFFFA500);
      case RequestStatus.approved:
        return const Color(0xFF4CAF50);
      case RequestStatus.rejected:
        return const Color(0xFFF44336);
      case RequestStatus.cancelled:
        return const Color(0xFF9E9E9E);
      case RequestStatus.expired:
        return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case RequestStatus.pending:
        return Icons.hourglass_empty;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
      case RequestStatus.cancelled:
        return Icons.remove_circle;
      case RequestStatus.expired:
        return Icons.timer_off;
    }
  }

  static RequestStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return RequestStatus.pending;
      case 'approved':
        return RequestStatus.approved;
      case 'rejected':
        return RequestStatus.rejected;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'expired':
        return RequestStatus.expired;
      default:
        return RequestStatus.pending;
    }
  }
}

/// Current access status
enum AccessStatus {
  inactive,
  active,
  paused,
  expired,
  revoked;

  String get value => name;

  String get label {
    switch (this) {
      case AccessStatus.inactive:
        return 'Inactive';
      case AccessStatus.active:
        return 'Active';
      case AccessStatus.paused:
        return 'Paused';
      case AccessStatus.expired:
        return 'Expired';
      case AccessStatus.revoked:
        return 'Revoked';
    }
  }

  String get emoji {
    switch (this) {
      case AccessStatus.inactive:
        return '⚪';
      case AccessStatus.active:
        return '🟢';
      case AccessStatus.paused:
        return '🟡';
      case AccessStatus.expired:
        return '🔴';
      case AccessStatus.revoked:
        return '⛔';
    }
  }

  Color get color {
    switch (this) {
      case AccessStatus.inactive:
        return const Color(0xFF9E9E9E);
      case AccessStatus.active:
        return const Color(0xFF4CAF50);
      case AccessStatus.paused:
        return const Color(0xFFFFC107);
      case AccessStatus.expired:
        return const Color(0xFFF44336);
      case AccessStatus.revoked:
        return const Color(0xFF212121);
    }
  }

  static AccessStatus fromString(String? value) {
    switch (value) {
      case 'inactive':
        return AccessStatus.inactive;
      case 'active':
        return AccessStatus.active;
      case 'paused':
        return AccessStatus.paused;
      case 'expired':
        return AccessStatus.expired;
      case 'revoked':
        return AccessStatus.revoked;
      default:
        return AccessStatus.inactive;
    }
  }
}

/// Type of mentoring relationship
enum RelationshipType {
  teacherStudent,
  parentChild,
  bossEmployee,
  coachAthlete,
  accountabilityPartner,
  custom;

  String get value {
    switch (this) {
      case RelationshipType.teacherStudent:
        return 'teacher_student';
      case RelationshipType.parentChild:
        return 'parent_child';
      case RelationshipType.bossEmployee:
        return 'boss_employee';
      case RelationshipType.coachAthlete:
        return 'coach_athlete';
      case RelationshipType.accountabilityPartner:
        return 'accountability_partner';
      case RelationshipType.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case RelationshipType.teacherStudent:
        return 'Teacher - Student';
      case RelationshipType.parentChild:
        return 'Parent - Child';
      case RelationshipType.bossEmployee:
        return 'Boss - Employee';
      case RelationshipType.coachAthlete:
        return 'Coach - Athlete';
      case RelationshipType.accountabilityPartner:
        return 'Accountability Partner';
      case RelationshipType.custom:
        return 'Custom';
    }
  }

  String get mentorLabel {
    switch (this) {
      case RelationshipType.teacherStudent:
        return 'Teacher';
      case RelationshipType.parentChild:
        return 'Parent';
      case RelationshipType.bossEmployee:
        return 'Boss';
      case RelationshipType.coachAthlete:
        return 'Coach';
      case RelationshipType.accountabilityPartner:
        return 'Partner';
      case RelationshipType.custom:
        return 'Mentor';
    }
  }

  String get ownerLabel {
    switch (this) {
      case RelationshipType.teacherStudent:
        return 'Student';
      case RelationshipType.parentChild:
        return 'Child';
      case RelationshipType.bossEmployee:
        return 'Employee';
      case RelationshipType.coachAthlete:
        return 'Athlete';
      case RelationshipType.accountabilityPartner:
        return 'Partner';
      case RelationshipType.custom:
        return 'Mentee';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipType.teacherStudent:
        return '👨‍🏫';
      case RelationshipType.parentChild:
        return '👨‍👩‍👧';
      case RelationshipType.bossEmployee:
        return '👔';
      case RelationshipType.coachAthlete:
        return '🏃';
      case RelationshipType.accountabilityPartner:
        return '🤝';
      case RelationshipType.custom:
        return '✏️';
    }
  }

  IconData get icon {
    switch (this) {
      case RelationshipType.teacherStudent:
        return Icons.school;
      case RelationshipType.parentChild:
        return Icons.family_restroom;
      case RelationshipType.bossEmployee:
        return Icons.business_center;
      case RelationshipType.coachAthlete:
        return Icons.sports;
      case RelationshipType.accountabilityPartner:
        return Icons.handshake;
      case RelationshipType.custom:
        return Icons.edit;
    }
  }

  static RelationshipType fromString(String? value) {
    switch (value) {
      case 'teacher_student':
        return RelationshipType.teacherStudent;
      case 'parent_child':
        return RelationshipType.parentChild;
      case 'boss_employee':
        return RelationshipType.bossEmployee;
      case 'coach_athlete':
        return RelationshipType.coachAthlete;
      case 'accountability_partner':
        return RelationshipType.accountabilityPartner;
      case 'custom':
        return RelationshipType.custom;
      default:
        return RelationshipType.custom;
    }
  }
}

/// Access duration options
enum AccessDuration {
  oneTime,
  oneDay,
  oneWeek,
  oneMonth,
  sixMonths,
  always;

  String get value {
    switch (this) {
      case AccessDuration.oneTime:
        return 'one_time';
      case AccessDuration.oneDay:
        return '1_day';
      case AccessDuration.oneWeek:
        return '7_days';
      case AccessDuration.oneMonth:
        return '30_days';
      case AccessDuration.sixMonths:
        return '6_months';
      case AccessDuration.always:
        return 'always';
    }
  }

  String get label {
    switch (this) {
      case AccessDuration.oneTime:
        return 'One Time';
      case AccessDuration.oneDay:
        return '1 Day';
      case AccessDuration.oneWeek:
        return '1 Week';
      case AccessDuration.oneMonth:
        return '1 Month';
      case AccessDuration.sixMonths:
        return '6 Months';
      case AccessDuration.always:
        return 'Always';
    }
  }

  String get description {
    switch (this) {
      case AccessDuration.oneTime:
        return 'View once, then access ends';
      case AccessDuration.oneDay:
        return 'Access for 24 hours';
      case AccessDuration.oneWeek:
        return 'Access for 7 days';
      case AccessDuration.oneMonth:
        return 'Access for 30 days';
      case AccessDuration.sixMonths:
        return 'Access for 180 days';
      case AccessDuration.always:
        return 'Until manually revoked';
    }
  }

  String get emoji {
    switch (this) {
      case AccessDuration.oneTime:
        return '1️⃣';
      case AccessDuration.oneDay:
        return '📅';
      case AccessDuration.oneWeek:
        return '📆';
      case AccessDuration.oneMonth:
        return '🗓️';
      case AccessDuration.sixMonths:
        return '📊';
      case AccessDuration.always:
        return '♾️';
    }
  }

  Duration? get duration {
    switch (this) {
      case AccessDuration.oneTime:
        return const Duration(hours: 1);
      case AccessDuration.oneDay:
        return const Duration(days: 1);
      case AccessDuration.oneWeek:
        return const Duration(days: 7);
      case AccessDuration.oneMonth:
        return const Duration(days: 30);
      case AccessDuration.sixMonths:
        return const Duration(days: 180);
      case AccessDuration.always:
        return null;
    }
  }

  DateTime? calculateExpiresAt([DateTime? from]) {
    final startDate = from ?? DateTime.now();
    final dur = duration;
    if (dur == null) return null;
    return startDate.add(dur);
  }

  static AccessDuration fromString(String? value) {
    switch (value) {
      case 'one_time':
        return AccessDuration.oneTime;
      case '1_day':
        return AccessDuration.oneDay;
      case '7_days':
        return AccessDuration.oneWeek;
      case '30_days':
        return AccessDuration.oneMonth;
      case '6_months':
        return AccessDuration.sixMonths;
      case 'always':
        return AccessDuration.always;
      default:
        return AccessDuration.oneWeek;
    }
  }
}

/// Screens that can be accessed
enum AccessibleScreen {
  dashboard,
  mood,
  rewards,
  stats;

  String get value {
    switch (this) {
      case AccessibleScreen.dashboard:
        return 'dashboard';
      case AccessibleScreen.mood:
        return 'mood';
      case AccessibleScreen.rewards:
        return 'rewards';
      case AccessibleScreen.stats:
        return 'stats';
    }
  }

  String get label {
    switch (this) {
      case AccessibleScreen.dashboard:
        return 'Dashboard Overview';
      case AccessibleScreen.mood:
        return 'Mood Tracker';
      case AccessibleScreen.rewards:
        return 'Rewards & Badges';
      case AccessibleScreen.stats:
        return 'Historical Stats';
    }
  }

  String get description {
    switch (this) {
      case AccessibleScreen.dashboard:
        return 'Overall progress, points, and active items';
      case AccessibleScreen.mood:
        return 'Daily mood entries and emotional trends';
      case AccessibleScreen.rewards:
        return 'Unlocked badges, achievements, and rewards';
      case AccessibleScreen.stats:
        return 'Long-term productivity and streak history';
    }
  }

  String get emoji {
    switch (this) {
      case AccessibleScreen.dashboard:
        return '📊';
      case AccessibleScreen.mood:
        return '😊';
      case AccessibleScreen.rewards:
        return '🎁';
      case AccessibleScreen.stats:
        return '📈';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessibleScreen.dashboard:
        return Icons.dashboard_rounded;
      case AccessibleScreen.mood:
        return Icons.mood_rounded;
      case AccessibleScreen.rewards:
        return Icons.emoji_events_rounded;
      case AccessibleScreen.stats:
        return Icons.query_stats_rounded;
    }
  }

  static AccessibleScreen fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'dashboard':
        return AccessibleScreen.dashboard;
      case 'mood':
      case 'dashboard_mood':
        return AccessibleScreen.mood;
      case 'rewards':
      case 'dashboard_rewards':
        return AccessibleScreen.rewards;
      case 'dashboard_progress':
        return AccessibleScreen.stats;
      default:
        return AccessibleScreen.dashboard;
    }
  }

  static AllowedScreens fromJson(dynamic value) {
    if (value == null) return const AllowedScreens(screens: [AccessibleScreen.dashboard]);

    List<dynamic> list;
    if (value is String) {
      try {
        list = jsonDecode(value) as List<dynamic>;
      } catch (_) {
        return const AllowedScreens(screens: [AccessibleScreen.dashboard]);
      }
    } else if (value is List) {
      list = value;
    } else if (value is Map<String, dynamic>) {
      list = (value['items'] as List? ?? []);
    } else {
      return const AllowedScreens(screens: [AccessibleScreen.dashboard]);
    }

    final rawList = list.map((e) => e?.toString().toLowerCase()).toList();

    // Check if "all" is present in the list
    if (rawList.contains('all')) {
      return AllowedScreens(screens: List.from(AccessibleScreen.values));
    }

    return AllowedScreens(screens: rawList.map((e) => AccessibleScreen.fromString(e)).toList());
  }

  static Map<String, dynamic> toJson(AllowedScreens allowed) {
    return {
      'items': allowed.screens.map((s) => s.value).toList(),
    };
  }
}

class AllowedScreens {
  final List<AccessibleScreen> screens;

  const AllowedScreens({this.screens = const []});

  factory AllowedScreens.fromJson(dynamic json) => AccessibleScreen.fromJson(json);
  Map<String, dynamic> toJson() => AccessibleScreen.toJson(this);

  bool get isEmpty => screens.isEmpty;
  bool get isNotEmpty => screens.isNotEmpty;
  int get length => screens.length;
  AccessibleScreen get first => screens.first;
  bool contains(AccessibleScreen screen) => screens.contains(screen);
  Iterable<T> map<T>(T Function(AccessibleScreen) f) => screens.map(f);
}

// ================================================================
// PERMISSIONS MODEL
// ================================================================

class MentorshipPermissions {
  final bool showPoints;
  final bool showStreak;
  final bool showRank;
  final bool showTasks;
  final bool showTaskDetails;
  final bool showGoals;
  final bool showGoalDetails;
  final bool showMood;
  final bool showDiary;
  final bool showRewards;
  final bool showProgress;

  const MentorshipPermissions({
    this.showPoints = true,
    this.showStreak = true,
    this.showRank = true,
    this.showTasks = false,
    this.showTaskDetails = false,
    this.showGoals = false,
    this.showGoalDetails = false,
    this.showMood = false,
    this.showDiary = false,
    this.showRewards = true,
    this.showProgress = true,
  });

  factory MentorshipPermissions.fromJson(dynamic value) {
    if (value == null) return const MentorshipPermissions();

    Map<String, dynamic> json;
    if (value is String) {
      try {
        json = jsonDecode(value) as Map<String, dynamic>;
      } catch (_) {
        return const MentorshipPermissions();
      }
    } else if (value is Map<String, dynamic>) {
      json = value;
    } else {
      return const MentorshipPermissions();
    }

    return MentorshipPermissions(
      showPoints: json['show_points'] as bool? ?? true,
      showStreak: json['show_streak'] as bool? ?? true,
      showRank: json['show_rank'] as bool? ?? true,
      showTasks: json['show_tasks'] as bool? ?? false,
      showTaskDetails: json['show_task_details'] as bool? ?? false,
      showGoals: json['show_goals'] as bool? ?? false,
      showGoalDetails: json['show_goal_details'] as bool? ?? false,
      showMood: json['show_mood'] as bool? ?? false,
      showDiary: json['show_diary'] as bool? ?? false,
      showRewards: json['show_rewards'] as bool? ?? true,
      showProgress: json['show_progress'] as bool? ?? true,
    );
  }

  factory MentorshipPermissions.all() => const MentorshipPermissions(
    showPoints: true,
    showStreak: true,
    showRank: true,
    showTasks: true,
    showTaskDetails: true,
    showGoals: true,
    showGoalDetails: true,
    showMood: true,
    showDiary: true,
    showRewards: true,
    showProgress: true,
  );

  factory MentorshipPermissions.minimal() => const MentorshipPermissions(
    showPoints: true,
    showStreak: true,
    showRank: false,
    showTasks: false,
    showTaskDetails: false,
    showGoals: false,
    showGoalDetails: false,
    showMood: false,
    showDiary: false,
    showRewards: false,
    showProgress: true,
  );

  factory MentorshipPermissions.forRelationship(RelationshipType type) {
    switch (type) {
      case RelationshipType.parentChild:
        return MentorshipPermissions.all();
      case RelationshipType.teacherStudent:
        return const MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        );
      case RelationshipType.bossEmployee:
        return const MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: true,
          showGoals: true,
          showGoalDetails: true,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        );
      case RelationshipType.coachAthlete:
        return const MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: true,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: true,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        );
      case RelationshipType.accountabilityPartner:
        return const MentorshipPermissions(
          showPoints: true,
          showStreak: true,
          showRank: false,
          showTasks: true,
          showTaskDetails: false,
          showGoals: true,
          showGoalDetails: false,
          showMood: false,
          showDiary: false,
          showRewards: true,
          showProgress: true,
        );
      case RelationshipType.custom:
        return const MentorshipPermissions();
    }
  }

  Map<String, dynamic> toJson() => {
    'show_points': showPoints,
    'show_streak': showStreak,
    'show_rank': showRank,
    'show_tasks': showTasks,
    'show_task_details': showTaskDetails,
    'show_goals': showGoals,
    'show_goal_details': showGoalDetails,
    'show_mood': showMood,
    'show_diary': showDiary,
    'show_rewards': showRewards,
    'show_progress': showProgress,
  };

  MentorshipPermissions copyWith({
    bool? showPoints,
    bool? showStreak,
    bool? showRank,
    bool? showTasks,
    bool? showTaskDetails,
    bool? showGoals,
    bool? showGoalDetails,
    bool? showMood,
    bool? showDiary,
    bool? showRewards,
    bool? showProgress,
  }) {
    return MentorshipPermissions(
      showPoints: showPoints ?? this.showPoints,
      showStreak: showStreak ?? this.showStreak,
      showRank: showRank ?? this.showRank,
      showTasks: showTasks ?? this.showTasks,
      showTaskDetails: showTaskDetails ?? this.showTaskDetails,
      showGoals: showGoals ?? this.showGoals,
      showGoalDetails: showGoalDetails ?? this.showGoalDetails,
      showMood: showMood ?? this.showMood,
      showDiary: showDiary ?? this.showDiary,
      showRewards: showRewards ?? this.showRewards,
      showProgress: showProgress ?? this.showProgress,
    );
  }

  int get enabledCount {
    int count = 0;
    if (showPoints) count++;
    if (showStreak) count++;
    if (showRank) count++;
    if (showTasks) count++;
    if (showTaskDetails) count++;
    if (showGoals) count++;
    if (showGoalDetails) count++;
    if (showMood) count++;
    if (showDiary) count++;
    if (showRewards) count++;
    if (showProgress) count++;
    return count;
  }

  bool get isAll => enabledCount == 11;
  bool get isMinimal => enabledCount <= 3;

  String get summaryLabel {
    if (isAll) return 'Full Access';
    if (isMinimal) return 'Basic Only';
    return '$enabledCount permissions';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorshipPermissions &&
          showPoints == other.showPoints &&
          showStreak == other.showStreak &&
          showRank == other.showRank &&
          showTasks == other.showTasks &&
          showTaskDetails == other.showTaskDetails &&
          showGoals == other.showGoals &&
          showGoalDetails == other.showGoalDetails &&
          showMood == other.showMood &&
          showDiary == other.showDiary &&
          showRewards == other.showRewards &&
          showProgress == other.showProgress;

  @override
  int get hashCode => Object.hash(
    showPoints,
    showStreak,
    showRank,
    showTasks,
    showTaskDetails,
    showGoals,
    showGoalDetails,
    showMood,
    showDiary,
    showRewards,
    showProgress,
  );
}

// ================================================================
// MAIN MODEL
// ================================================================

class MentorshipConnection {
  final String id;

  // Core relationship
  final String ownerId;
  final String mentorId;

  // Request flow
  final RequestType requestType;
  final RequestStatus requestStatus;
  final String? requestMessage;
  final String? responseMessage;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  // Relationship context
  final RelationshipType relationshipType;
  final String? relationshipLabel;

  // Access configuration
  final AllowedScreens allowedScreens;
  final MentorshipPermissions permissions;

  // Duration
  final AccessDuration duration;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  // Status
  final AccessStatus accessStatus;
  final bool isLiveEnabled;

  // Usage tracking
  final int viewCount;
  final DateTime? lastViewedAt;
  final String? lastViewedScreen;

  // Offline cache
  final Map<String, dynamic> cachedSnapshot;
  final DateTime? snapshotCapturedAt;

  // Notifications
  final bool notifyOwnerOnView;
  final bool notifyMentorOnUpdate;
  final bool notifyMentorOnInactive;
  final int inactiveThresholdDays;
  final Map<String, dynamic> lastNotified; // Added

  // Encouragement
  final DateTime? lastEncouragementAt;
  final String? lastEncouragementType;
  final String? lastEncouragementMessage;
  final int encouragementCount;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const MentorshipConnection({
    required this.id,
    required this.ownerId,
    required this.mentorId,
    required this.requestType,
    required this.requestStatus,
    this.requestMessage,
    this.responseMessage,
    required this.requestedAt,
    this.respondedAt,
    required this.relationshipType,
    this.relationshipLabel,
    required this.allowedScreens,
    required this.permissions,
    required this.duration,
    this.startsAt,
    this.expiresAt,
    required this.accessStatus,
    required this.isLiveEnabled,
    required this.viewCount,
    this.lastViewedAt,
    this.lastViewedScreen,
    required this.cachedSnapshot,
    this.snapshotCapturedAt,
    required this.notifyOwnerOnView,
    required this.notifyMentorOnUpdate,
    required this.notifyMentorOnInactive,
    required this.inactiveThresholdDays,
    required this.lastNotified, // Added
    this.lastEncouragementAt,
    this.lastEncouragementType,
    this.lastEncouragementMessage,
    required this.encouragementCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // ================================================================
  // FACTORY CONSTRUCTORS
  // ================================================================

  factory MentorshipConnection.fromJson(Map<String, dynamic> json) {
    return MentorshipConnection(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      mentorId: json['mentor_id'] as String? ?? '',
      requestType: RequestType.fromString(json['request_type'] as String?),
      requestStatus: RequestStatus.fromString(
        json['request_status'] as String?,
      ),
      requestMessage: json['request_message'] == 'null'
          ? null
          : json['request_message'] as String?,
      responseMessage: json['response_message'] == 'null'
          ? null
          : json['response_message'] as String?,
      requestedAt: _parseDateTime(json['requested_at']) ?? DateTime.now(),
      respondedAt: _parseDateTime(json['responded_at']),
      relationshipType: RelationshipType.fromString(
        json['relationship_type'] as String?,
      ),
      relationshipLabel: json['relationship_label'] == 'null'
          ? null
          : json['relationship_label'] as String?,
      allowedScreens: AccessibleScreen.fromJson(json['allowed_screens']),
      permissions: MentorshipPermissions.fromJson(json['permissions']),
      duration: AccessDuration.fromString(json['duration'] as String?),
      startsAt: _parseDateTime(json['starts_at']),
      expiresAt: _parseDateTime(json['expires_at']),
      accessStatus: AccessStatus.fromString(json['access_status'] as String?),
      isLiveEnabled: _parseBool(json['is_live_enabled']),
      viewCount: _parseInt(json['view_count']),
      lastViewedAt: _parseDateTime(json['last_viewed_at']),
      lastViewedScreen: json['last_viewed_screen'] as String?,
      cachedSnapshot: _parseJsonb(json['cached_snapshot']),
      snapshotCapturedAt: _parseDateTime(json['snapshot_captured_at']),
      notifyOwnerOnView: _parseBool(
        json['notify_owner_on_view'],
        defaultValue: false,
      ),
      notifyMentorOnUpdate: _parseBool(json['notify_mentor_on_update']),
      notifyMentorOnInactive: _parseBool(json['notify_mentor_on_inactive']),
      inactiveThresholdDays: _parseInt(
        json['inactive_threshold_days'],
        defaultValue: 3,
      ),
      lastNotified: _parseJsonb(json['last_notified']), // Added
      lastEncouragementAt: _parseDateTime(json['last_encouragement_at']),
      lastEncouragementType: json['last_encouragement_type'] as String?,
      lastEncouragementMessage: json['last_encouragement_message'] as String?,
      encouragementCount: _parseInt(json['encouragement_count']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  factory MentorshipConnection.empty() => MentorshipConnection(
    id: '',
    ownerId: '',
    mentorId: '',
    requestType: RequestType.requestAccess,
    requestStatus: RequestStatus.pending,
    requestedAt: DateTime.now(),
    relationshipType: RelationshipType.custom,
    allowedScreens: const AllowedScreens(screens: [AccessibleScreen.dashboard]),
    permissions: const MentorshipPermissions(),
    duration: AccessDuration.oneWeek,
    accessStatus: AccessStatus.inactive,
    isLiveEnabled: true,
    viewCount: 0,
    cachedSnapshot: const {},
    notifyOwnerOnView: false,
    notifyMentorOnUpdate: true,
    notifyMentorOnInactive: true,
    inactiveThresholdDays: 3,
    lastNotified: const {}, // Added
    encouragementCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  factory MentorshipConnection.forRequestAccess({
    required String ownerId,
    required String mentorId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    List<AccessibleScreen> screens = const [AccessibleScreen.dashboard],
    MentorshipPermissions? permissions,
    AccessDuration duration = AccessDuration.oneMonth,
    String? message,
  }) {
    return MentorshipConnection(
      id: '',
      ownerId: ownerId,
      mentorId: mentorId,
      requestType: RequestType.requestAccess,
      requestStatus: RequestStatus.pending,
      requestMessage: message,
      requestedAt: DateTime.now(),
      relationshipType: relationshipType,
      relationshipLabel: relationshipLabel,
      allowedScreens: AllowedScreens(screens: screens),
      permissions:
          permissions ??
          MentorshipPermissions.forRelationship(relationshipType),
      duration: duration,
      accessStatus: AccessStatus.inactive,
      isLiveEnabled: true,
      viewCount: 0,
      cachedSnapshot: const {},
      notifyOwnerOnView: false,
      notifyMentorOnUpdate: true,
      notifyMentorOnInactive: true,
      inactiveThresholdDays: 3,
      lastNotified: const {}, // Added
      encouragementCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory MentorshipConnection.forOfferShare({
    required String ownerId,
    required String mentorId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    List<AccessibleScreen> screens = const [AccessibleScreen.dashboard],
    MentorshipPermissions? permissions,
    AccessDuration duration = AccessDuration.always,
    bool isLiveEnabled = true,
  }) {
    final now = DateTime.now();
    return MentorshipConnection(
      id: '',
      ownerId: ownerId,
      mentorId: mentorId,
      requestType: RequestType.offerShare,
      requestStatus: RequestStatus.approved,
      requestedAt: now,
      respondedAt: now,
      relationshipType: relationshipType,
      relationshipLabel: relationshipLabel,
      allowedScreens: AllowedScreens(screens: screens),
      permissions:
          permissions ??
          MentorshipPermissions.forRelationship(relationshipType),
      duration: duration,
      startsAt: now,
      expiresAt: duration.calculateExpiresAt(now),
      accessStatus: AccessStatus.active,
      isLiveEnabled: isLiveEnabled,
      viewCount: 0,
      cachedSnapshot: const {},
      notifyOwnerOnView: false,
      notifyMentorOnUpdate: true,
      notifyMentorOnInactive: true,
      inactiveThresholdDays: 3,
      lastNotified: const {}, // Added
      encouragementCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ================================================================
  // TO JSON
  // ================================================================

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'mentor_id': mentorId,
    'request_type': requestType.value,
    'request_status': requestStatus.value,
    'request_message': requestMessage,
    'response_message': responseMessage,
    'requested_at': requestedAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
    'relationship_type': relationshipType.value,
    'relationship_label': relationshipLabel,
    'allowed_screens': allowedScreens.toJson(),
    'permissions': permissions.toJson(),
    'duration': duration.value,
    'starts_at': startsAt?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'access_status': accessStatus.value,
    'is_live_enabled': isLiveEnabled,
    'view_count': viewCount,
    'last_viewed_at': lastViewedAt?.toIso8601String(),
    'last_viewed_screen': lastViewedScreen,
    'cached_snapshot': cachedSnapshot,
    'snapshot_captured_at': snapshotCapturedAt?.toIso8601String(),
    'notify_owner_on_view': notifyOwnerOnView,
    'notify_mentor_on_update': notifyMentorOnUpdate,
    'notify_mentor_on_inactive': notifyMentorOnInactive,
    'inactive_threshold_days': inactiveThresholdDays,
    'last_notified': lastNotified, // Added
    'last_encouragement_at': lastEncouragementAt?.toIso8601String(),
    'last_encouragement_type': lastEncouragementType,
    'encouragement_count': encouragementCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  MentorshipConnection copyWith({
    String? id,
    String? ownerId,
    String? mentorId,
    RequestType? requestType,
    RequestStatus? requestStatus,
    String? requestMessage,
    String? responseMessage,
    DateTime? requestedAt,
    DateTime? respondedAt,
    bool clearRespondedAt = false,
    RelationshipType? relationshipType,
    String? relationshipLabel,
    bool clearRelationshipLabel = false,
    AllowedScreens? allowedScreens,
    MentorshipPermissions? permissions,
    AccessDuration? duration,
    DateTime? startsAt,
    bool clearStartsAt = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    AccessStatus? accessStatus,
    bool? isLiveEnabled,
    int? viewCount,
    DateTime? lastViewedAt,
    bool clearLastViewedAt = false,
    String? lastViewedScreen,
    bool clearLastViewedScreen = false,
    Map<String, dynamic>? cachedSnapshot,
    DateTime? snapshotCapturedAt,
    bool clearSnapshotCapturedAt = false,
    bool? notifyOwnerOnView,
    bool? notifyMentorOnUpdate,
    bool? notifyMentorOnInactive,
    int? inactiveThresholdDays,
    Map<String, dynamic>? lastNotified, // Added
    DateTime? lastEncouragementAt,
    bool clearLastEncouragementAt = false,
    String? lastEncouragementType,
    bool clearLastEncouragementType = false,
    String? lastEncouragementMessage,
    bool clearLastEncouragementMessage = false,
    int? encouragementCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MentorshipConnection(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      mentorId: mentorId ?? this.mentorId,
      requestType: requestType ?? this.requestType,
      requestStatus: requestStatus ?? this.requestStatus,
      requestMessage: requestMessage ?? this.requestMessage,
      responseMessage: responseMessage ?? this.responseMessage,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: clearRespondedAt ? null : (respondedAt ?? this.respondedAt),
      relationshipType: relationshipType ?? this.relationshipType,
      relationshipLabel: clearRelationshipLabel
          ? null
          : (relationshipLabel ?? this.relationshipLabel),
      allowedScreens: allowedScreens ?? this.allowedScreens,
      permissions: permissions ?? this.permissions,
      duration: duration ?? this.duration,
      startsAt: clearStartsAt ? null : (startsAt ?? this.startsAt),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      accessStatus: accessStatus ?? this.accessStatus,
      isLiveEnabled: isLiveEnabled ?? this.isLiveEnabled,
      viewCount: viewCount ?? this.viewCount,
      lastViewedAt: clearLastViewedAt
          ? null
          : (lastViewedAt ?? this.lastViewedAt),
      lastViewedScreen: clearLastViewedScreen
          ? null
          : (lastViewedScreen ?? this.lastViewedScreen),
      cachedSnapshot: cachedSnapshot ?? this.cachedSnapshot,
      snapshotCapturedAt: clearSnapshotCapturedAt
          ? null
          : (snapshotCapturedAt ?? this.snapshotCapturedAt),
      notifyOwnerOnView: notifyOwnerOnView ?? this.notifyOwnerOnView,
      notifyMentorOnUpdate: notifyMentorOnUpdate ?? this.notifyMentorOnUpdate,
      notifyMentorOnInactive:
          notifyMentorOnInactive ?? this.notifyMentorOnInactive,
      inactiveThresholdDays:
          inactiveThresholdDays ?? this.inactiveThresholdDays,
      lastNotified: lastNotified ?? this.lastNotified, // Added
      lastEncouragementAt: clearLastEncouragementAt
          ? null
          : (lastEncouragementAt ?? this.lastEncouragementAt),
      lastEncouragementType: clearLastEncouragementType
          ? null
          : (lastEncouragementType ?? this.lastEncouragementType),
      lastEncouragementMessage: clearLastEncouragementMessage
          ? null
          : (lastEncouragementMessage ?? this.lastEncouragementMessage),
      encouragementCount: encouragementCount ?? this.encouragementCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ================================================================
  // HELPER GETTERS
  // ================================================================

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  bool get isPending => requestStatus == RequestStatus.pending;
  bool get isApproved => requestStatus == RequestStatus.approved;
  bool get isRejected => requestStatus == RequestStatus.rejected;
  bool get isCancelled => requestStatus == RequestStatus.cancelled;
  bool get isRequestExpired => requestStatus == RequestStatus.expired;

  bool get isActive => accessStatus == AccessStatus.active;
  bool get isInactive => accessStatus == AccessStatus.inactive;
  bool get isPaused => accessStatus == AccessStatus.paused;
  bool get isAccessExpired => accessStatus == AccessStatus.expired;
  bool get isRevoked => accessStatus == AccessStatus.revoked;

  bool get isAccessRequest => requestType == RequestType.requestAccess;
  bool get isOfferShare => requestType == RequestType.offerShare;

  bool get hasExpiration => expiresAt != null;
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canAccess => isActive && !isExpired;

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get remainingTimeLabel {
    if (expiresAt == null) return 'Never expires';
    final remaining = remainingTime;
    if (remaining == null || remaining.inSeconds <= 0) return 'Expired';

    if (remaining.inDays > 30) {
      final months = (remaining.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} left';
    } else if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays > 1 ? 's' : ''} left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours > 1 ? 's' : ''} left';
    } else {
      return '${remaining.inMinutes} min left';
    }
  }

  bool get hasAllScreens =>
      allowedScreens.length >= AccessibleScreen.values.length;

  bool canViewScreen(AccessibleScreen screen) {
    if (hasAllScreens) return true;
    return allowedScreens.contains(screen);
  }

  bool canViewScreenByName(String screenName) {
    final screen = AccessibleScreen.fromString(screenName);
    return canViewScreen(screen);
  }

  String get displayLabel {
    final label = relationshipLabel;
    if (label == null || label == 'null' || label.isEmpty) {
      return relationshipType.label;
    }
    return label;
  }

  String get statusLabel {
    if (isPending) return requestStatus.label;
    return accessStatus.label;
  }

  String get statusEmoji {
    if (isPending) return requestStatus.emoji;
    return accessStatus.emoji;
  }

  Color get statusColor {
    if (isPending) return requestStatus.color;
    return accessStatus.color;
  }

  String get screensLabel {
    if (hasAllScreens) return 'All Screens';
    if (allowedScreens.isEmpty) return 'No screens';
    if (allowedScreens.length == 1) return allowedScreens.first.label;
    return '${allowedScreens.length} screen';
  }

  String get lastViewedLabel {
    if (lastViewedAt == null) return 'Never viewed';
    final diff = DateTime.now().difference(lastViewedAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  bool get hasSnapshot => cachedSnapshot.isNotEmpty;

  String? get snapshotAgeLabel {
    if (snapshotCapturedAt == null) return null;
    final diff = DateTime.now().difference(snapshotCapturedAt!);
    if (diff.inMinutes < 5) return 'Fresh';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m old';
    if (diff.inHours < 24) return '${diff.inHours}h old';
    return '${diff.inDays}d old';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MentorshipConnection && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MentorshipConnection(id: $id, owner: $ownerId, mentor: $mentorId, status: $accessStatus)';
}

// ================================================================
// HELPER FUNCTIONS
// ================================================================

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  return null;
}

bool _parseBool(dynamic value, {bool defaultValue = true}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return defaultValue;
}

int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

Map<String, dynamic> _parseJsonb(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is String) {
    if (value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return {};
}

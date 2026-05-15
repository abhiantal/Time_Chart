// FILE: lib/features/analytics/competition/models/competition_model.dart
// REFINED: Standardized model for battle challenges JSONB structures.

import 'dart:convert';
import 'package:flutter/material.dart';

// Reuse DashboardOverview and its sub-classes directly.
// Do NOT copy-paste them — they are already defined there.
import '../../dashboard/models/dashboard_model.dart';

// ── Private parse helpers ────────────────────────────────────────

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _dt(dynamic v) => v != null ? DateTime.tryParse(v.toString()) : null;

Map<String, dynamic> _map(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  }
  return {};
}

// ================================================================
// BATTLE STATUS ENUM
// ================================================================

/// The lifecycle status of a battle challenge.
enum BattleStatus {
  /// Battle is running and stats update automatically.
  active,

  /// Battle ended (time expired or creator completed it).
  completed,

  /// Creator cancelled the battle.
  cancelled;

  static BattleStatus fromString(String? v) {
    switch (v?.toLowerCase()) {
      case 'completed':
        return BattleStatus.completed;
      case 'cancelled':
        return BattleStatus.cancelled;
      default:
        return BattleStatus.active;
    }
  }

  String get value => name; // 'active' / 'completed' / 'cancelled'

  String get label {
    switch (this) {
      case BattleStatus.active:
        return 'Active';
      case BattleStatus.completed:
        return 'Completed';
      case BattleStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BattleStatus.active:
        return const Color(0xFF10B981);
      case BattleStatus.completed:
        return const Color(0xFF3B82F6);
      case BattleStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }
}

// ================================================================
// ROOT MODEL — BattleChallenge
// DB TABLE: battle_challenges (one row per battle)
// ================================================================

class BattleChallenge {
  // --- DB column: id ---
  final String id;

  // --- DB column: user_id ---
  // UUID of the user who owns this battle.
  // Only the owner can add / remove members.
  final String userId;

  // --- DB column: title ---
  final String title;

  // --- DB column: description ---
  final String? description;

  // --- DB column: status ---
  final BattleStatus status;

  // --- DB column: starts_at ---
  final DateTime startsAt;

  // --- DB column: ends_at ---
  // Null = no end date.
  final DateTime? endsAt;

  // --- DB columns: member1_id ... member5_id ---
  // Null = that slot is empty.
  final String? member1Id;
  final String? member2Id;
  final String? member3Id;
  final String? member4Id;
  final String? member5Id;

  // --- DB column: user_stats ---
  // Always present after battle creation.
  // Contains: profile + diary_stats + overview
  final BattleMemberStats? userStats;

  // --- DB columns: member1_stats ... member5_stats ---
  // Null = slot is empty.
  final BattleMemberStats? member1Stats;
  final BattleMemberStats? member2Stats;
  final BattleMemberStats? member3Stats;
  final BattleMemberStats? member4Stats;
  final BattleMemberStats? member5Stats;

  // --- DB column: created_at ---
  final DateTime? createdAt;

  // --- DB column: updated_at ---
  final DateTime? updatedAt;

  const BattleChallenge({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.status = BattleStatus.active,
    required this.startsAt,
    this.endsAt,
    this.member1Id,
    this.member2Id,
    this.member3Id,
    this.member4Id,
    this.member5Id,
    this.userStats,
    this.member1Stats,
    this.member2Stats,
    this.member3Stats,
    this.member4Stats,
    this.member5Stats,
    this.createdAt,
    this.updatedAt,
  });

  factory BattleChallenge.fromJson(Map<String, dynamic> j) => BattleChallenge(
    id: j['id'] as String? ?? '',
    userId: j['user_id'] as String? ?? '',
    title: j['title'] as String? ?? 'Battle Challenge',
    description: j['description'] as String?,
    status: BattleStatus.fromString(j['status'] as String?),
    startsAt: _dt(j['starts_at']) ?? DateTime.now(),
    endsAt: _dt(j['ends_at']),
    member1Id: j['member1_id'] as String?,
    member2Id: j['member2_id'] as String?,
    member3Id: j['member3_id'] as String?,
    member4Id: j['member4_id'] as String?,
    member5Id: j['member5_id'] as String?,
    userStats: j['user_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['user_stats']))
        : null,
    member1Stats: j['member1_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['member1_stats']))
        : null,
    member2Stats: j['member2_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['member2_stats']))
        : null,
    member3Stats: j['member3_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['member3_stats']))
        : null,
    member4Stats: j['member4_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['member4_stats']))
        : null,
    member5Stats: j['member5_stats'] != null
        ? BattleMemberStats.fromJson(_map(j['member5_stats']))
        : null,
    createdAt: _dt(j['created_at']),
    updatedAt: _dt(j['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'status': status.value,
    'starts_at': startsAt.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'member1_id': member1Id,
    'member2_id': member2Id,
    'member3_id': member3Id,
    'member4_id': member4Id,
    'member5_id': member5Id,
    'user_stats': userStats?.toJson(),
    'member1_stats': member1Stats?.toJson(),
    'member2_stats': member2Stats?.toJson(),
    'member3_stats': member3Stats?.toJson(),
    'member4_stats': member4Stats?.toJson(),
    'member5_stats': member5Stats?.toJson(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  // ── Convenience getters ──────────────────────────────────────

  /// All filled stats slots in slot order (user first).
  List<BattleMemberStats> get allMemberStats => [
    if (userStats != null) userStats!,
    if (member1Stats != null) member1Stats!,
    if (member2Stats != null) member2Stats!,
    if (member3Stats != null) member3Stats!,
    if (member4Stats != null) member4Stats!,
    if (member5Stats != null) member5Stats!,
  ];

  /// All members sorted by competition_rank ASC (rank 1 first).
  List<BattleMemberStats> get rankedMembers {
    final list = List<BattleMemberStats>.from(allMemberStats);
    list.sort(
      (a, b) => a.profile.competitionRank.compareTo(b.profile.competitionRank),
    );
    return list;
  }

  /// Number of participants currently in the battle (including creator).
  int get memberCount => allMemberStats.length;

  /// How many member slots are still open (max 5 members, user is owner).
  int get availableSlots =>
      5 -
      [
        member1Id,
        member2Id,
        member3Id,
        member4Id,
        member5Id,
      ].where((id) => id != null).length;

  bool get isActive => status == BattleStatus.active;
  bool get isFull => availableSlots == 0;
  bool get hasEnded => endsAt != null && endsAt!.isBefore(DateTime.now());

  bool isOwner(String testId) => userId == testId;
  bool isParticipant(String testId) =>
      testId == userId ||
      testId == member1Id ||
      testId == member2Id ||
      testId == member3Id ||
      testId == member4Id ||
      testId == member5Id;

  /// Find the stats for a specific user in this battle.
  BattleMemberStats? statsForUser(String targetId) {
    if (userStats?.profile.id == targetId) return userStats;
    if (member1Stats?.profile.id == targetId) return member1Stats;
    if (member2Stats?.profile.id == targetId) return member2Stats;
    if (member3Stats?.profile.id == targetId) return member3Stats;
    if (member4Stats?.profile.id == targetId) return member4Stats;
    if (member5Stats?.profile.id == targetId) return member5Stats;
    return null;
  }

  BattleChallenge copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    BattleStatus? status,
    DateTime? startsAt,
    DateTime? endsAt,
    String? member1Id,
    String? member2Id,
    String? member3Id,
    String? member4Id,
    String? member5Id,
    BattleMemberStats? userStats,
    BattleMemberStats? member1Stats,
    BattleMemberStats? member2Stats,
    BattleMemberStats? member3Stats,
    BattleMemberStats? member4Stats,
    BattleMemberStats? member5Stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BattleChallenge(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    member1Id: member1Id ?? this.member1Id,
    member2Id: member2Id ?? this.member2Id,
    member3Id: member3Id ?? this.member3Id,
    member4Id: member4Id ?? this.member4Id,
    member5Id: member5Id ?? this.member5Id,
    userStats: userStats ?? this.userStats,
    member1Stats: member1Stats ?? this.member1Stats,
    member2Stats: member2Stats ?? this.member2Stats,
    member3Stats: member3Stats ?? this.member3Stats,
    member4Stats: member4Stats ?? this.member4Stats,
    member5Stats: member5Stats ?? this.member5Stats,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ================================================================
// BATTLE MEMBER STATS
// The full snapshot for ONE stats column.
//
// DB structure (inside creator_stats / member1_stats / ...):
//   {
// --     "profile":     { ... }  → BattleMemberProfile
// --     "diary_stats": { ... }  → BattleDiaryStats
// --     "overview":    { ... }  → DashboardOverview  (dashboard_model.dart)
//   }
// ================================================================

class BattleMemberStats {
  // --- stats → profile ---
  // Identity + rank + competition position.
  final BattleMemberProfile profile;

  // --- stats → diary_stats ---
  // Diary entry count, streak, mood trend, last mood.
  // Built fresh from diary_entries table on every refresh.
  final BattleDiaryStats diaryStats;

  // --- stats → overview ---
  // The FULL overview column from performance_analytics.
  // Contains: summary + daily_tasks_stats + weekly_tasks_stats
  //           + long_goals_stats + bucket_list_stats
  // Automatically up-to-date via the trigger chain.
  final DashboardOverview overview;

  const BattleMemberStats({
    required this.profile,
    required this.diaryStats,
    required this.overview,
  });

  factory BattleMemberStats.fromJson(Map<String, dynamic> j) =>
      BattleMemberStats(
        profile: BattleMemberProfile.fromJson(_map(j['profile'])),
        diaryStats: BattleDiaryStats.fromJson(_map(j['diary_stats'])),
        overview: DashboardOverview.fromJson(_map(j['overview'])),
      );

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'diary_stats': diaryStats.toJson(),
    'overview': overview.toJson(),
  };

  // ── Quick-access getters for leaderboard / comparison UI ─────

  /// Total points (from overview.summary.totalPoints).
  int get totalPoints => overview.summary.totalPoints;

  /// Completion rate all time (from overview.summary.completionRateAll).
  double get completionRate => overview.summary.completionRateAll;

  /// Current streak days (from overview.summary.currentStreak).
  int get currentStreak => overview.summary.currentStreak;

  /// Best tier achieved (from overview.summary.bestTierAchieved).
  String get bestTier => overview.summary.bestTierAchieved;

  /// Total rewards earned (from overview.summary.totalRewards).
  int get totalRewards => overview.summary.totalRewards;

  /// Rank within this battle (from profile.competitionRank).
  int get competitionRank => profile.competitionRank;

  /// Username for display.
  String get username => profile.username;

  /// Display Name with fallback to username
  String get displayName => profile.displayName?.isNotEmpty == true
      ? profile.displayName!
      : profile.username;

  /// Profile URL (Avatar).
  String get profileUrl => profile.profileUrl;

  /// True if this member is the battle creator.
  bool get isOwner => profile.isOwner;

  // ── Derived getters for comparison UI (CompetitorScore compatibility) ──

  // Summary Metrics
  int get rankToday => overview.summary.globalRank;
  int get pointsToday => overview.summary.pointsToday;
  int get pointsThisWeek => overview.summary.pointsThisWeek;
  int get totalPointsAllTime => overview.summary.totalPoints;
  int get rewardsTotal => overview.summary.totalRewards;
  double get ratingAverage => overview.summary.averageRating;
  int get streakCurrent => overview.summary.currentStreak;
  int get streakLongest => overview.summary.longestStreak;
  int get progressAverage => overview.summary.averageProgress;
  String get topTier => overview.summary.bestTierAchieved;
  double get rateAll => overview.summary.completionRateAll;
  double get rateWeek => overview.summary.completionRateWeek;
  double get rateToday => overview.summary.completionRateToday;

  int get taskScore =>
      overview.summary.dailyTasksPoints + overview.summary.weeklyTasksPoints;
  int get goalScore => overview.summary.longGoalsPoints;
  int get bucketScore => overview.summary.bucketListPoints;
  int get diaryScore => diaryStats.diaryEntries * 10; // Simple heuristic
  int get streakScore => currentStreak * 5;
  int get globalRank => profile.globalRank;

  // Daily Tasks Stats
  int get tasksCompletedToday => overview.dailyTasksStats.dayTasksCompleted;
  int get tasksTotalToday => overview.dailyTasksStats.totalDayTasks;
  int get tasksNotCompletedToday =>
      overview.dailyTasksStats.dayTasksNotCompleted;
  double get tasksCompletionRate =>
      overview.dailyTasksStats.dayTasksCompletionRate;
  double get tasksAverageRating =>
      overview.dailyTasksStats.dayTasksCompletionRating;
  int get tasksTotalProgress => overview.dailyTasksStats.totalDayTasksProgress;
  int get tasksTotalPoints => overview.dailyTasksStats.totalDayTasksPoints;
  double get todayCompletionRate =>
      overview.dailyTasksStats.completionRateToday;

  // Weekly Tasks Stats
  int get weekTasksCompleted => overview.weeklyTasksStats.weekTasksCompleted;
  int get weekTasksTotal => overview.weeklyTasksStats.totalWeekTasks;
  int get weekTasksNotCompleted =>
      overview.weeklyTasksStats.weekTasksNotCompleted;
  double get weekTasksCompletionRate =>
      overview.weeklyTasksStats.weekTasksCompletionRate;
  double get weekTasksAverageRating =>
      overview.weeklyTasksStats.weekTasksCompletionRating;
  int get weekTasksTotalProgress =>
      overview.weeklyTasksStats.totalWeekTasksProgress;
  int get weekTasksTotalPoints =>
      overview.weeklyTasksStats.totalWeekTasksPoints;

  // Long Goals Stats
  int get goalsTotal => overview.longGoalsStats.totalLongGoals;
  int get activeGoals => overview.longGoalsStats.longGoalsActive;
  int get completedGoals => overview.longGoalsStats.longGoalsCompleted;
  int get notStartedGoals => overview.longGoalsStats.longGoalsNotStarted;
  double get goalsCompletionRate =>
      overview.longGoalsStats.longGoalsCompletionRate;
  double get goalsAverageProgress =>
      overview.longGoalsStats.longGoalsAverageProgress;
  double get goalsAverageRating =>
      overview.longGoalsStats.longGoalsCompletionRating;
  double get goalsTotalProgress =>
      overview.longGoalsStats.totalLongGoalsProgress;
  double get goalsProgress => goalsTotalProgress; // Alias for compatibility
  int get goalsTotalPoints => overview.longGoalsStats.totalLongGoalsPoints;

  // Bucket List Stats
  int get bucketsTotal => overview.bucketListStats.totalBucketItems;
  int get bucketsCompleted => overview.bucketListStats.bucketItemsCompleted;
  int get bucketsInProgress => overview.bucketListStats.bucketItemsInProgress;
  int get bucketsNotStarted => overview.bucketListStats.bucketItemsNotStarted;
  double get bucketsCompletionRate =>
      overview.bucketListStats.bucketCompletionRate;
  double get bucketsAverageProgress =>
      overview.bucketListStats.bucketAverageProgress;
  double get bucketsAverageRating =>
      overview.bucketListStats.bucketCompletionRating;
  double get bucketsTotalProgress =>
      overview.bucketListStats.totalBucketProgress;
  int get bucketsTotalPoints => overview.bucketListStats.totalBucketPoints;

  int get diaryEntriesThisWeek => diaryStats.diaryEntries; // Simplified
  double get moodAverage => diaryStats.lastdayMood?.rating.toDouble() ?? 5.0;
  int get longestStreak => diaryStats.longestStreak;

  int get goldRewards => overview.summary.totalRewards ~/ 3; // Placeholder
  int get silverRewards =>
      (overview.summary.totalRewards % 3) ~/ 2; // Placeholder
  int get bronzeRewards => overview.summary.totalRewards % 2; // Placeholder

  DateTime get lastUpdated => DateTime.now();

  static BattleMemberStats empty() => BattleMemberStats(
    profile: const BattleMemberProfile(id: ''),
    diaryStats: const BattleDiaryStats(),
    overview: DashboardOverview.empty(),
  );
}

typedef CompetitorScore = BattleMemberStats;

// ================================================================
// BATTLE MEMBER PROFILE
// Identity + rank + position for one member.
// Stored inside each stats column under the "profile" key.
//
// DB structure (inside stats JSONB → "profile"):
//   {
//     "id":               "uuid",
//     "uuid":             "uuid",          ← same as id
//     "profile_url":       "https://...",
//     "username":         "jordan_lee",
//     "global_rank":      120,             ← from overview.summary.global_rank
//     "competition_rank": 2,               ← rank within THIS battle
//     "member_number":    1,               ← 0=creator, 1-5=member slots
//     "is_owner":         false,
//     "joined_at":        "2025-03-13T..."
//   }
// ================================================================

class BattleMemberProfile {
  // --- profile → id / uuid ---
  final String id;
  final String uuid;

  // --- profile → profile_url ---
  // From user_profiles.profile_url. Empty string if not set.
  final String profileUrl;

  // --- profile → username ---
  // From user_profiles.username.
  final String username;

  // --- profile → display_name ---
  // From user_profiles.display_name.
  final String? displayName;

  // --- profile → global_rank ---
  // Rank across ALL app users (copied from overview.summary.global_rank).
  final int globalRank;

  // --- profile → competition_rank ---
  // Rank within THIS battle only, based on total_points.
  // 1 = most points. Recomputed on every stats refresh.
  // 0 = not yet computed (freshly added member before first rank pass).
  final int competitionRank;

  // --- profile → member_number ---
  // 0 = creator, 1–5 = member slots.
  final int memberNumber;

  // --- profile → is_owner ---
  // True only for the battle creator.
  final bool isOwner;

  // --- profile → joined_at ---
  // When this member joined the battle.
  // For creator: same as battle.created_at.
  // For members: when add_battle_member() was called for them.
  final DateTime? joinedAt;

  const BattleMemberProfile({
    required this.id,
    this.uuid = '',
    this.profileUrl = '',
    this.username = '',
    this.displayName,
    this.globalRank = 0,
    this.competitionRank = 0,
    this.memberNumber = 0,
    this.isOwner = false,
    this.joinedAt,
  });

  factory BattleMemberProfile.fromJson(Map<String, dynamic> j) =>
      BattleMemberProfile(
        id: j['id'] as String? ?? '',
        uuid: j['uuid'] as String? ?? j['id'] as String? ?? '',
        profileUrl:
            j['profile_url'] as String? ?? j['avatar_url'] as String? ?? '',
        username: j['username'] as String? ?? '',
        displayName: j['display_name'] as String?,
        globalRank: _int(j['global_rank']),
        competitionRank: _int(j['competition_rank']),
        memberNumber: _int(j['member_number']),
        isOwner: j['is_owner'] == true,
        joinedAt: _dt(j['joined_at']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid.isEmpty ? id : uuid,
    'profile_url': profileUrl,
    'username': username,
    'display_name': displayName,
    'global_rank': globalRank,
    'competition_rank': competitionRank,
    'member_number': memberNumber,
    'is_owner': isOwner,
    'joined_at': joinedAt?.toIso8601String(),
  };

  // ── Display helpers ────────────────────────────────────────────

  /// Medal emoji for this member's competition position.
  String get rankMedal {
    switch (competitionRank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return competitionRank > 0 ? '#$competitionRank' : '-';
    }
  }

  /// Display label for global rank.
  String get globalRankLabel {
    if (globalRank <= 0) return 'Unranked';
    if (globalRank == 1) return '#1 🏆';
    return '#$globalRank';
  }

  /// Initials fallback when profileUrl is empty.
  String get initials {
    final nameToUse =
        (displayName?.isNotEmpty == true ? displayName : username) ?? '';
    if (nameToUse.isEmpty) return '?';
    final parts = nameToUse.trim().split(RegExp(r'[_\s]+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  bool get hasAvatar => profileUrl.isNotEmpty;
}

// ================================================================
// BATTLE DIARY STATS
// Fresh diary data for one member.
// Stored inside each stats column under the "diary_stats" key.
//
// DB structure (inside stats JSONB → "diary_stats"):
//   {
//     "diaryEntries":  5,           ← total diary entries all time
//     "currentStreak": 12,          ← current consecutive active days
//     "longestStreak": 20,          ← longest streak ever
//     "trend":         "declining", ← mood trend over last 30 days
//     "lastday_mood": {
//       "emoji":  "😐",
//       "label":  "Okay",
//       "rating": 6                 ← 1–10 scale
//     }
//   }
//
// NOTE: Field names match your EXACT spec:
//   diaryEntries  (camelCase)
//   currentStreak (camelCase)
//   logesteStreak (camelCase, original typo preserved)
//   trend         (lowercase)
//   lastday_mood  (snake_case)
// ================================================================

class BattleDiaryStats {
  // --- diary_stats → diaryEntries ---
  // Total diary entries this user has ever written (all time).
  final int diaryEntries;

  // --- diary_stats → currentStreak ---
  // Consecutive days with activity (completed task OR diary entry).
  // Same definition as overview.summary.currentStreak.
  final int currentStreak;

  // --- diary_stats → longestStreak ---
  // All-time longest streak.
  final int longestStreak;

  // --- diary_stats → trend ---
  // Mood trend over the last 30 days.
  // Values: "improving" / "declining" / "stable"
  final String trend;

  // --- diary_stats → lastday_mood ---
  // Mood from the user's most recent diary entry with a mood rating.
  // Null if user has never written a diary entry with mood data.
  final BattleLastMood? lastdayMood;

  const BattleDiaryStats({
    this.diaryEntries = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.trend = 'stable',
    this.lastdayMood,
  });

  factory BattleDiaryStats.fromJson(Map<String, dynamic> j) => BattleDiaryStats(
    diaryEntries: _int(j['diaryEntries']),
    currentStreak: _int(j['currentStreak']),
    longestStreak: _int(j['longestStreak'] ?? j['logesteStreak']),
    trend: j['trend'] as String? ?? 'stable',
    lastdayMood: j['lastday_mood'] != null
        ? BattleLastMood.fromJson(_map(j['lastday_mood']))
        : null,
  );

  Map<String, dynamic> toJson() => {
    'diaryEntries': diaryEntries,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'trend': trend,
    'lastday_mood': lastdayMood?.toJson(),
  };

  // ── Display helpers ────────────────────────────────────────────

  /// Emoji representing the streak length.
  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    if (currentStreak >= 3) return '⚡';
    if (currentStreak >= 1) return '✨';
    return '💤';
  }

  /// Icon for the mood trend direction.
  IconData get trendIcon {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  /// Color for the mood trend.
  Color get trendColor {
    switch (trend.toLowerCase()) {
      case 'improving':
        return const Color(0xFF10B981);
      case 'declining':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  bool get hasMood => lastdayMood != null;
  bool get hasStreak => currentStreak > 0;
}

// ================================================================
// BATTLE LAST MOOD
// The mood from a member's most recent diary entry.
// Stored inside diary_stats under the "lastday_mood" key.
//
// DB structure (inside diary_stats → "lastday_mood"):
//   {
//     "emoji":  "😐",
//     "label":  "Okay",
//     "rating": 6       ← 1–10 scale (same as mood column in PA)
//   }
// ================================================================

class BattleLastMood {
  // --- lastday_mood → emoji ---
  // Mood emoji, e.g. "😐", "😊", "😢".
  final String emoji;

  // --- lastday_mood → label ---
  // Text label, e.g. "Okay", "Good", "Sad".
  final String label;

  // --- lastday_mood → rating ---
  // 1–10 scale. 1 = very bad, 10 = excellent.
  // Same scale used throughout the app (dashboard_model.dart).
  final int rating;

  const BattleLastMood({this.emoji = '😐', this.label = '', this.rating = 0});

  factory BattleLastMood.fromJson(Map<String, dynamic> j) => BattleLastMood(
    emoji: j['emoji'] as String? ?? '😐',
    label: j['label'] as String? ?? '',
    rating: _int(j['rating']),
  );

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'label': label,
    'rating': rating,
  };

  // ── Display helpers ────────────────────────────────────────────

  Color get color {
    if (rating >= 9) return const Color(0xFF43E97B);
    if (rating >= 7) return const Color(0xFF4FACFE);
    if (rating >= 5) return const Color(0xFFFFD54F);
    if (rating >= 3) return const Color(0xFFFFA726);
    return const Color(0xFFFF6B6B);
  }

  bool get isPositive => rating >= 7;
  bool get isNegative => rating < 4;
}

// ================================================================
// BATTLE LEADERBOARD ENTRY
// A flat, quick-access view for one member on the ranking screen.
// Built from BattleMemberStats — NOT stored in DB.
// ================================================================

class BattleLeaderboardEntry {
  /// Full stats object (if you need deeper data in the UI).
  final BattleMemberStats stats;

  // Flat fields for direct widget use
  final String username;
  final String profileUrl;
  final int competitionRank;
  final int totalPoints;
  final int currentStreak;
  final String bestTier;
  final double completionRate;
  final int diaryEntries;
  final String moodEmoji;
  final String rankMedal;
  final bool isOwner;

  const BattleLeaderboardEntry({
    required this.stats,
    required this.username,
    required this.profileUrl,
    required this.competitionRank,
    required this.totalPoints,
    required this.currentStreak,
    required this.bestTier,
    required this.completionRate,
    required this.diaryEntries,
    required this.moodEmoji,
    required this.rankMedal,
    required this.isOwner,
  });

  /// Build from a single BattleMemberStats snapshot.
  factory BattleLeaderboardEntry.fromStats(BattleMemberStats s) =>
      BattleLeaderboardEntry(
        stats: s,
        username: s.displayName,
        profileUrl: s.profile.profileUrl,
        competitionRank: s.profile.competitionRank,
        totalPoints: s.overview.summary.totalPoints,
        currentStreak: s.overview.summary.currentStreak,
        bestTier: s.overview.summary.bestTierAchieved,
        completionRate: s.overview.summary.completionRateAll,
        diaryEntries: s.diaryStats.diaryEntries,
        moodEmoji: s.diaryStats.lastdayMood?.emoji ?? '😐',
        rankMedal: s.profile.rankMedal,
        isOwner: s.profile.isOwner,
      );

  /// Build the full ranked leaderboard from a BattleChallenge.
  /// Sorted by competitionRank ASC (1 = first place).
  static List<BattleLeaderboardEntry> fromBattle(BattleChallenge battle) =>
      battle.rankedMembers.map(BattleLeaderboardEntry.fromStats).toList();
}

/// Result from searching for a user to add as a competitor.
class UserSearchResult {
  final String id;
  final String username;
  final String? displayName;
  final String? profileUrl;
  final String? email;
  final int score;

  UserSearchResult({
    required this.id,
    required this.username,
    this.displayName,
    this.profileUrl,
    this.email,
    this.score = 0,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) => UserSearchResult(
    id: j['id'] as String? ?? j['uuid'] as String? ?? '',
    username: j['username'] as String? ?? '',
    displayName: j['display_name'] as String?,
    profileUrl: j['profile_url'] as String? ?? j['avatar_url'] as String?,
    email: j['email'] as String?,
    score: _int(j['score']),
  );
}

/// Consolidated data for the Competition Detail Screen.
class CompetitionDetailData {
  final String userName;
  final String? userProfileUrl;
  final int userTotalScore;
  final double userOverallProgress;

  final String competitorName;
  final String? competitorProfileUrl;
  final int competitorTotalScore;
  final double competitorOverallProgress;

  // Additional metrics for comparison
  final int userDailyTasksCompleted;
  final int userDailyTasksTotal;
  final int competitorDailyTasksCompleted;
  final int competitorDailyTasksTotal;

  final int userWeeklyTasksCompleted;
  final int userWeeklyTasksTotal;
  final int competitorWeeklyTasksCompleted;
  final int competitorWeeklyTasksTotal;

  final double userGoalsProgress;
  final double competitorGoalsProgress;

  final int userBucketsCompleted;
  final int userBucketsTotal;
  final int competitorBucketsCompleted;
  final int competitorBucketsTotal;

  final int userDiaryEntriesWeek;
  final int competitorDiaryEntriesWeek;

  final int userStreak;
  final int competitorStreak;
  final int userStreakLongest;
  final int competitorStreakLongest;

  const CompetitionDetailData({
    required this.userName,
    this.userProfileUrl,
    required this.userTotalScore,
    required this.userOverallProgress,
    required this.competitorName,
    this.competitorProfileUrl,
    required this.competitorTotalScore,
    required this.competitorOverallProgress,
    this.userDailyTasksCompleted = 0,
    this.userDailyTasksTotal = 0,
    this.competitorDailyTasksCompleted = 0,
    this.competitorDailyTasksTotal = 0,
    this.userWeeklyTasksCompleted = 0,
    this.userWeeklyTasksTotal = 0,
    this.competitorWeeklyTasksCompleted = 0,
    this.competitorWeeklyTasksTotal = 0,
    this.userGoalsProgress = 0,
    this.competitorGoalsProgress = 0,
    this.userBucketsCompleted = 0,
    this.userBucketsTotal = 0,
    this.competitorBucketsCompleted = 0,
    this.competitorBucketsTotal = 0,
    this.userDiaryEntriesWeek = 0,
    this.competitorDiaryEntriesWeek = 0,
    this.userStreak = 0,
    this.competitorStreak = 0,
    this.userStreakLongest = 0,
    this.competitorStreakLongest = 0,
  });

  bool get isUserWinning => userTotalScore > competitorTotalScore;
  bool get isTied => userTotalScore == competitorTotalScore;
  int get pointDifference => (userTotalScore - competitorTotalScore).abs();

  factory CompetitionDetailData.fromStats({
    required BattleMemberStats myStats,
    required BattleMemberStats compStats,
  }) {
    return CompetitionDetailData(
      userName: myStats.username,
      userProfileUrl: myStats.profileUrl,
      userTotalScore: myStats.totalPoints,
      userOverallProgress: myStats.completionRate * 100,

      competitorName: compStats.username,
      competitorProfileUrl: compStats.profileUrl,
      competitorTotalScore: compStats.totalPoints,
      competitorOverallProgress: compStats.completionRate * 100,

      userDailyTasksCompleted:
          myStats.overview.dailyTasksStats.dayTasksCompleted,
      userDailyTasksTotal: myStats.overview.dailyTasksStats.totalDayTasks,
      competitorDailyTasksCompleted:
          compStats.overview.dailyTasksStats.dayTasksCompleted,
      competitorDailyTasksTotal:
          compStats.overview.dailyTasksStats.totalDayTasks,

      userWeeklyTasksCompleted:
          myStats.overview.weeklyTasksStats.weekTasksCompleted,
      userWeeklyTasksTotal: myStats.overview.weeklyTasksStats.totalWeekTasks,
      competitorWeeklyTasksCompleted:
          compStats.overview.weeklyTasksStats.weekTasksCompleted,
      competitorWeeklyTasksTotal:
          compStats.overview.weeklyTasksStats.totalWeekTasks,

      userGoalsProgress:
          myStats.overview.longGoalsStats.longGoalsAverageProgress * 100,
      competitorGoalsProgress:
          compStats.overview.longGoalsStats.longGoalsAverageProgress * 100,

      userBucketsCompleted:
          myStats.overview.bucketListStats.bucketItemsCompleted,
      userBucketsTotal: myStats.overview.bucketListStats.totalBucketItems,
      competitorBucketsCompleted:
          compStats.overview.bucketListStats.bucketItemsCompleted,
      competitorBucketsTotal:
          compStats.overview.bucketListStats.totalBucketItems,

      userDiaryEntriesWeek: myStats.diaryStats.diaryEntries % 7, // Placeholder
      competitorDiaryEntriesWeek:
          compStats.diaryStats.diaryEntries % 7, // Placeholder
      userStreak: myStats.currentStreak,
      competitorStreak: compStats.currentStreak,
      userStreakLongest: myStats.longestStreak,
      competitorStreakLongest: compStats.longestStreak,
    );
  }

  factory CompetitionDetailData.empty() => const CompetitionDetailData(
    userName: '',
    competitorName: '',
    userTotalScore: 0,
    userOverallProgress: 0,
    competitorTotalScore: 0,
    competitorOverallProgress: 0,
  );
}

// ================================================================
// COMPARISON CATEGORY ENUM
// ================================================================

enum ComparisonCategory {
  overall('🏆', 'Overall', [
    Color(0xFF6366F1),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
  ]),
  tasks('✅', 'Tasks', [Color(0xFF8B5CF6), Color(0xFFD946EF)]),
  goals('🎯', 'Goals', [Color(0xFF3B82F6), Color(0xFF2DD4BF)]),
  buckets('🪣', 'Bucket List', [Color(0xFFF97316), Color(0xFFFACC15)]),
  diary('📔', 'Journaling', [Colors.teal, Colors.tealAccent]),
  streaks('🔥', 'Streaks', [Colors.deepOrange, Colors.orange]);

  final String emoji;
  final String label;
  final List<Color> colors;

  const ComparisonCategory(this.emoji, this.label, this.colors);
}

// ================================================================
// MULTI-COMPETITOR COMPARISON MODELS
// ================================================================

class CompetitorComparisonData {
  final String id;
  final String name;
  final String? profileUrl;
  final int totalScore;
  final int globalRank;
  final int taskScore;
  final int goalScore;
  final int bucketScore;
  final int diaryScore;
  final int streakScore;
  final int dailyTasksCompleted;
  final int dailyTasksTotal;
  final int weeklyTasksCompleted;
  final int weeklyTasksTotal;
  final double taskCompletionRate;
  final int activeGoals;
  final int completedGoals;
  final double goalsProgress;
  final int bucketsCompleted;
  final int bucketsTotal;
  final int diaryEntriesWeek;
  final double moodAverage;
  final int currentStreak;
  final int longestStreak;
  final int goldRewards;
  final int silverRewards;
  final int bronzeRewards;

  const CompetitorComparisonData({
    required this.id,
    required this.name,
    this.profileUrl,
    required this.totalScore,
    required this.globalRank,
    required this.taskScore,
    required this.goalScore,
    required this.bucketScore,
    required this.diaryScore,
    required this.streakScore,
    required this.dailyTasksCompleted,
    required this.dailyTasksTotal,
    required this.weeklyTasksCompleted,
    required this.weeklyTasksTotal,
    required this.taskCompletionRate,
    required this.activeGoals,
    required this.completedGoals,
    required this.goalsProgress,
    required this.bucketsCompleted,
    required this.bucketsTotal,
    required this.diaryEntriesWeek,
    required this.moodAverage,
    required this.currentStreak,
    required this.longestStreak,
    required this.goldRewards,
    required this.silverRewards,
    required this.bronzeRewards,
  });

  factory CompetitorComparisonData.fromStats(BattleMemberStats s) {
    return CompetitorComparisonData(
      id: s.profile.id,
      name: s.profile.username,
      profileUrl: s.profile.profileUrl,
      totalScore: s.totalPoints,
      globalRank: s.globalRank,
      taskScore: s.taskScore,
      goalScore: s.goalScore,
      bucketScore: s.bucketScore,
      diaryScore: s.diaryScore,
      streakScore: s.streakScore,
      dailyTasksCompleted: s.tasksCompletedToday,
      dailyTasksTotal: s.tasksTotalToday,
      weeklyTasksCompleted: s.weekTasksCompleted,
      weeklyTasksTotal: s.weekTasksTotal,
      taskCompletionRate: s.todayCompletionRate,
      activeGoals: s.activeGoals,
      completedGoals: s.completedGoals,
      goalsProgress: s.goalsProgress,
      bucketsCompleted: s.bucketsCompleted,
      bucketsTotal: s.bucketsTotal,
      diaryEntriesWeek: s.diaryEntriesThisWeek,
      moodAverage: s.moodAverage,
      currentStreak: s.currentStreak,
      longestStreak: s.longestStreak,
      goldRewards: s.goldRewards,
      silverRewards: s.silverRewards,
      bronzeRewards: s.bronzeRewards,
    );
  }
}

class CompetitionComparisonData {
  final String userName;
  final String? userProfileUrl;
  final int userTotalScore;
  final int userGlobalRank;
  final int userTaskScore;
  final int userGoalScore;
  final int userBucketScore;
  final int userDiaryScore;
  final int userStreakScore;
  final int userDailyTasksCompleted;
  final int userDailyTasksTotal;
  final int userWeeklyTasksCompleted;
  final int userWeeklyTasksTotal;
  final double userTaskCompletionRate;
  final int userActiveGoals;
  final int userCompletedGoals;
  final double userGoalsProgress;
  final int userBucketsCompleted;
  final int userBucketsTotal;
  final int userDiaryEntriesWeek;
  final double userMoodAverage;
  final int userCurrentStreak;
  final int userLongestStreak;
  final int userGoldRewards;
  final int userSilverRewards;
  final int userBronzeRewards;

  final List<CompetitorComparisonData> competitors;
  final DateTime lastUpdated;

  const CompetitionComparisonData({
    required this.userName,
    this.userProfileUrl,
    required this.userTotalScore,
    required this.userGlobalRank,
    required this.userTaskScore,
    required this.userGoalScore,
    required this.userBucketScore,
    required this.userDiaryScore,
    required this.userStreakScore,
    required this.userDailyTasksCompleted,
    required this.userDailyTasksTotal,
    required this.userWeeklyTasksCompleted,
    required this.userWeeklyTasksTotal,
    required this.userTaskCompletionRate,
    required this.userActiveGoals,
    required this.userCompletedGoals,
    required this.userGoalsProgress,
    required this.userBucketsCompleted,
    required this.userBucketsTotal,
    required this.userDiaryEntriesWeek,
    required this.userMoodAverage,
    required this.userCurrentStreak,
    required this.userLongestStreak,
    required this.userGoldRewards,
    required this.userSilverRewards,
    required this.userBronzeRewards,
    required this.competitors,
    required this.lastUpdated,
  });

  factory CompetitionComparisonData.fromStats({
    required BattleMemberStats myStats,
    required List<BattleMemberStats> competitorsStats,
  }) {
    return CompetitionComparisonData(
      userName: myStats.username,
      userProfileUrl: myStats.profileUrl,
      userTotalScore: myStats.totalPoints,
      userGlobalRank: myStats.globalRank,
      userTaskScore: myStats.taskScore,
      userGoalScore: myStats.goalScore,
      userBucketScore: myStats.bucketScore,
      userDiaryScore: myStats.diaryScore,
      userStreakScore: myStats.streakScore,
      userDailyTasksCompleted: myStats.tasksCompletedToday,
      userDailyTasksTotal: myStats.tasksTotalToday,
      userWeeklyTasksCompleted: myStats.weekTasksCompleted,
      userWeeklyTasksTotal: myStats.weekTasksTotal,
      userTaskCompletionRate: myStats.todayCompletionRate,
      userActiveGoals: myStats.activeGoals,
      userCompletedGoals: myStats.completedGoals,
      userGoalsProgress: myStats.goalsProgress,
      userBucketsCompleted: myStats.bucketsCompleted,
      userBucketsTotal: myStats.bucketsTotal,
      userDiaryEntriesWeek: myStats.diaryEntriesThisWeek,
      userMoodAverage: myStats.moodAverage,
      userCurrentStreak: myStats.currentStreak,
      userLongestStreak: myStats.longestStreak,
      userGoldRewards: myStats.goldRewards,
      userSilverRewards: myStats.silverRewards,
      userBronzeRewards: myStats.bronzeRewards,
      competitors: competitorsStats
          .map((s) => CompetitorComparisonData.fromStats(s))
          .toList(),
      lastUpdated: DateTime.now(),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../reward_tags/reward_enums.dart';
import '../../../../reward_tags/reward_manager.dart';
import '../../../../helpers/card_color_helper.dart';

// ================================================================
// SHARED TOP-LEVEL HELPERS
// ================================================================


// ================================================================
// PRIVATE PARSE HELPERS
// ================================================================

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
double _dbl(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
DateTime? _dt(dynamic v) => v != null ? DateTime.tryParse(v.toString()) : null;

Map<String, dynamic> _parseJsonb(dynamic v) {
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

List<Map<String, dynamic>> _parseJsonbList(dynamic v) {
  List<dynamic> raw;
  if (v is List) {
    raw = v;
  } else if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is List) {
        raw = d;
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  } else {
    return [];
  }
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<dynamic> _parseJsonbListRaw(dynamic v) {
  if (v is Map && v.containsKey('items')) return (v['items'] as List);
  if (v is List) return v;
  if (v is String && v.isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is Map && d.containsKey('items')) return (d['items'] as List);
      if (d is List) return d;
    } catch (_) {}
  }
  return [];
}

// ================================================================
// ROOT MODEL — UserDashboard
// DB TABLE: performance_analytics (one row per user)
// ================================================================

class UserDashboard {
  // --- DB column: id ---
  final String id;

  // --- DB column: user_id ---
  final String userId;

  // --- DB column: overview ---
  final DashboardOverview overview;

  // --- DB column: today ---
  final TodaySummary today;

  // --- DB column: active_items ---
  final ActiveItems activeItems;

  // --- DB column: progress_history ---
  final ProgressHistory progressHistory;

  // --- DB column: weekly_history ---
  final WeeklyHistory weeklyHistory;

  // --- DB column: category_stats ---
  final CategoryStats categoryStats;

  // --- DB column: rewards ---
  final Rewards rewards;

  // --- DB column: streaks ---
  final Streaks streaks;

  // --- DB column: mood ---
  final Mood mood;

  // --- DB column: recent_activity ---
  final List<RecentActivityItem> recentActivity;

  // --- DB column: last_notified ---
  final Map<String, dynamic> lastNotified;

  // --- DB column: snapshot_at ---
  final DateTime? snapshotAt;

  // --- DB column: updated_at ---
  final DateTime? updatedAt;

  // --- DB column: created_at ---
  final DateTime? createdAt;

  const UserDashboard({
    required this.id,
    required this.userId,
    required this.overview,
    required this.today,
    required this.activeItems,
    required this.progressHistory,
    required this.weeklyHistory,
    required this.categoryStats,
    required this.rewards,
    required this.streaks,
    required this.mood,
    required this.recentActivity,
    this.lastNotified = const {},
    this.snapshotAt,
    this.updatedAt,
    this.createdAt,
  });

  factory UserDashboard.empty(String userId) => UserDashboard(
        id: 'empty',
        userId: userId,
        overview: DashboardOverview.empty(),
        today: TodaySummary.empty(),
        activeItems: ActiveItems.empty(),
        progressHistory: ProgressHistory.empty(),
        weeklyHistory: WeeklyHistory.empty(),
        categoryStats: CategoryStats.empty(),
        rewards: Rewards.empty(),
        streaks: Streaks.empty(),
        mood: Mood.empty(),
        recentActivity: const [],
        lastNotified: const {},
        snapshotAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

  factory UserDashboard.fromJson(Map<String, dynamic> json) => UserDashboard(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    overview: DashboardOverview.fromJson(_parseJsonb(json['overview'])),
    today: TodaySummary.fromJson(_parseJsonb(json['today'])),
    activeItems: ActiveItems.fromJson(_parseJsonb(json['active_items'])),
    progressHistory: ProgressHistory.fromJson(
      _parseJsonb(json['progress_history']),
    ),
    weeklyHistory: WeeklyHistory.fromJson(_parseJsonb(json['weekly_history'])),
    categoryStats: CategoryStats.fromJson(_parseJsonb(json['category_stats'])),
    rewards: Rewards.fromJson(_parseJsonb(json['rewards'])),
    streaks: Streaks.fromJson(_parseJsonb(json['streaks'])),
    mood: Mood.fromJson(_parseJsonb(json['mood'])),
    recentActivity: _parseJsonbListRaw(
      json['recent_activity'],
    ).map((e) => RecentActivityItem.fromJson(Map<String, dynamic>.from(e))).toList(),
    lastNotified: _parseJsonb(json['last_notified']),
    snapshotAt: _dt(json['snapshot_at']),
    updatedAt: _dt(json['updated_at']),
    createdAt: _dt(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'overview': overview.toJson(),
    'today': today.toJson(),
    'active_items': activeItems.toJson(),
    'progress_history': progressHistory.toJson(),
    'weekly_history': weeklyHistory.toJson(),
    'category_stats': categoryStats.toJson(),
    'rewards': rewards.toJson(),
    'streaks': streaks.toJson(),
    'mood': mood.toJson(),
    'recent_activity': {'items': recentActivity.map((e) => e.toJson()).toList()},
    'last_notified': lastNotified,
    'snapshot_at': snapshotAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };

  UserDashboard copyWith({
    String? id,
    String? userId,
    DashboardOverview? overview,
    TodaySummary? today,
    ActiveItems? activeItems,
    ProgressHistory? progressHistory,
    WeeklyHistory? weeklyHistory,
    CategoryStats? categoryStats,
    Rewards? rewards,
    Streaks? streaks,
    Mood? mood,
    List<RecentActivityItem>? recentActivity,
    Map<String, dynamic>? lastNotified,
    DateTime? snapshotAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) => UserDashboard(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    overview: overview ?? this.overview,
    today: today ?? this.today,
    activeItems: activeItems ?? this.activeItems,
    progressHistory: progressHistory ?? this.progressHistory,
    weeklyHistory: weeklyHistory ?? this.weeklyHistory,
    categoryStats: categoryStats ?? this.categoryStats,
    rewards: rewards ?? this.rewards,
    streaks: streaks ?? this.streaks,
    mood: mood ?? this.mood,
    recentActivity: recentActivity ?? this.recentActivity,
    lastNotified: lastNotified ?? this.lastNotified,
    snapshotAt: snapshotAt ?? this.snapshotAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
}

// ================================================================
// DB COLUMN: overview
// ================================================================

class DashboardOverview {
  // --- overview → summary ---
  // Global high-level numbers shown on the main dashboard header
  final DashboardSummary summary;

  // --- overview → daily_tasks_stats ---
  // Aggregated stats for ALL day_tasks of this user (all time)
  final DailyTasksStats dailyTasksStats;

  // --- overview → weekly_tasks_stats ---
  // Aggregated stats for ALL weekly_tasks of this user (all time)
  final WeeklyTasksStats weeklyTasksStats;

  // --- overview → long_goals_stats ---
  // Aggregated stats for ALL long_goals of this user (all time)
  final LongGoalsStats longGoalsStats;

  // --- overview → bucket_list_stats ---
  // Aggregated stats for ALL bucket_models of this user (all time)
  final BucketListStats bucketListStats;

  const DashboardOverview({
    required this.summary,
    required this.dailyTasksStats,
    required this.weeklyTasksStats,
    required this.longGoalsStats,
    required this.bucketListStats,
  });

  factory DashboardOverview.empty() => DashboardOverview(
    summary: DashboardSummary.empty(),
    dailyTasksStats: DailyTasksStats.empty(),
    weeklyTasksStats: WeeklyTasksStats.empty(),
    longGoalsStats: LongGoalsStats.empty(),
    bucketListStats: BucketListStats.empty(),
  );

  factory DashboardOverview.fromJson(Map<String, dynamic> j) =>
      DashboardOverview(
        summary: DashboardSummary.fromJson(_parseJsonb(j['summary'])),
        dailyTasksStats: DailyTasksStats.fromJson(
          _parseJsonb(j['daily_tasks_stats']),
        ),
        weeklyTasksStats: WeeklyTasksStats.fromJson(
          _parseJsonb(j['weekly_tasks_stats']),
        ),
        longGoalsStats: LongGoalsStats.fromJson(
          _parseJsonb(j['long_goals_stats']),
        ),
        bucketListStats: BucketListStats.fromJson(
          _parseJsonb(j['bucket_list_stats']),
        ),
      );

  Map<String, dynamic> toJson() => {
    'summary': summary.toJson(),
    'daily_tasks_stats': dailyTasksStats.toJson(),
    'weekly_tasks_stats': weeklyTasksStats.toJson(),
    'long_goals_stats': longGoalsStats.toJson(),
    'bucket_list_stats': bucketListStats.toJson(),
  };
}

// --- overview → summary ---
// Global metrics shown in dashboard header card
class DashboardSummary {
  final int globalRank; // user's rank among all users
  final int pointsToday; // points earned today
  final int totalPoints; // all-time total points
  final int totalRewards; // all-time total rewards earned
  final double averageRating; // average rating across all tasks
  final int currentStreak; // current active streak (days)
  final int longestStreak; // longest streak ever (days)
  final int averageProgress; // average progress % across all tasks
  final int pointsThisWeek; // points earned this week
  final String bestTierAchieved; // highest reward tier ever earned
  final double completionRateAll; // completion rate all time (%)
  final double completionRateWeek; // completion rate this week (%)
  final double completionRateToday; // completion rate today (%)
  final int dailyTasksPoints; // total points from daily tasks
  final int weeklyTasksPoints; // total points from weekly tasks
  final int longGoalsPoints; // total points from long goals
  final int bucketListPoints; // total points from bucket list
  final RewardPackage rewardPackage; // generated reward package for dashboard

  DashboardSummary({
    this.globalRank = 0,
    this.pointsToday = 0,
    this.totalPoints = 0,
    this.totalRewards = 0,
    this.averageRating = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.averageProgress = 0,
    this.pointsThisWeek = 0,
    this.bestTierAchieved = 'none',
    this.completionRateAll = 0,
    this.completionRateWeek = 0,
    this.completionRateToday = 0,
    this.dailyTasksPoints = 0,
    this.weeklyTasksPoints = 0,
    this.longGoalsPoints = 0,
    this.bucketListPoints = 0,
    RewardPackage? rewardPackage,
  }) : rewardPackage = rewardPackage ?? RewardPackage.empty(
    source: RewardSource.dashboard,
    reason: 'Initialising dashboard summary...',
  );

  factory DashboardSummary.empty() => DashboardSummary();

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
    globalRank: _int(j['global_rank']),
    pointsToday: _int(j['points_today']),
    totalPoints: _int(j['total_points']),
    totalRewards: _int(j['total_rewards']),
    averageRating: _dbl(j['average_rating']),
    currentStreak: _int(j['current_streak']),
    longestStreak: _int(j['longest_streak']),
    averageProgress: _int(j['average_progress']),
    pointsThisWeek: _int(j['points_this_week']),
    bestTierAchieved: j['best_tier_achieved'] as String? ?? 'none',
    completionRateAll: _dbl(j['completion_rate_all']),
    completionRateWeek: _dbl(j['completion_rate_week']),
    completionRateToday: _dbl(j['completion_rate_today']),
    dailyTasksPoints: _int(
      j['daily_tasks_points'] ?? j['total_day_tasks_points'],
    ),
    weeklyTasksPoints: _int(
      j['weekly_tasks_points'] ?? j['total_week_tasks_points'],
    ),
    longGoalsPoints: _int(
      j['long_goals_points'] ?? j['total_long_goals_points'],
    ),
    bucketListPoints: _int(j['bucket_list_points'] ?? j['total_bucket_points']),
    rewardPackage: RewardManager.forDashboardSummary(
      globalRank: _int(j['global_rank']),
      pointsToday: _int(j['points_today']),
      totalPoints: _int(j['total_points']),
      totalRewards: _int(j['total_rewards']),
      averageRating: _dbl(j['average_rating']),
      currentStreak: _int(j['current_streak']),
      longestStreak: _int(j['longest_streak']),
      averageProgress: _int(j['average_progress']),
      pointsThisWeek: _int(j['points_this_week']),
      bestTierAchieved: j['best_tier_achieved'] as String? ?? 'none',
      completionRateAll: _dbl(j['completion_rate_all']),
      completionRateWeek: _dbl(j['completion_rate_week']),
      completionRateToday: _dbl(j['completion_rate_today']),
      dailyTasksPoints: _int(
        j['daily_tasks_points'] ?? j['total_day_tasks_points'],
      ),
      weeklyTasksPoints: _int(
        j['weekly_tasks_points'] ?? j['total_week_tasks_points'],
      ),
      longGoalsPoints: _int(
        j['long_goals_points'] ?? j['total_long_goals_points'],
      ),
      bucketListPoints: _int(j['bucket_list_points'] ?? j['total_bucket_points']),
    ),
  );

  Map<String, dynamic> toJson() => {
    'global_rank': globalRank,
    'points_today': pointsToday,
    'total_points': totalPoints,
    'total_rewards': totalRewards,
    'average_rating': averageRating,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'average_progress': averageProgress,
    'points_this_week': pointsThisWeek,
    'best_tier_achieved': bestTierAchieved,
    'completion_rate_all': completionRateAll,
    'completion_rate_week': completionRateWeek,
    'completion_rate_today': completionRateToday,
    'daily_tasks_points': dailyTasksPoints,
    'weekly_tasks_points': weeklyTasksPoints,
    'long_goals_points': longGoalsPoints,
    'bucket_list_points': bucketListPoints,
    'reward_package': rewardPackage.toJson(),
  };

  // Display helpers
  String get rankLabel {
    if (globalRank <= 0) return 'Unranked';
    if (globalRank == 1) return '#1 🥇';
    if (globalRank == 2) return '#2 🥈';
    if (globalRank == 3) return '#3 🥉';
    if (globalRank <= 10) return '#$globalRank 🏆';
    return '#$globalRank';
  }

  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    if (currentStreak >= 3) return '⚡';
    if (currentStreak >= 1) return '✨';
    return '💤';
  }

  Color get bestTierColor => CardColorHelper.getTierColor(bestTierAchieved);
  String get bestTierEmoji => CardColorHelper.getTierEmoji(bestTierAchieved);
}

// --- overview → daily_tasks_stats ---
// Aggregated numbers from the day_tasks table (all time)
class DailyTasksStats {
  final int totalDayTasks; // total day tasks created
  final int dayTasksCompleted; // total completed
  final int dayTasksNotCompleted; // total not completed
  final double dayTasksCompletionRate; // completion rate %
  final double dayTasksCompletionRating; // average rating
  final int totalDayTasksProgress; // average progress %
  final int totalDayTasksPoints; // total points earned
  final double completionRateToday; // completion rate today (%)

  const DailyTasksStats({
    this.totalDayTasks = 0,
    this.dayTasksCompleted = 0,
    this.dayTasksNotCompleted = 0,
    this.dayTasksCompletionRate = 0,
    this.dayTasksCompletionRating = 0,
    this.totalDayTasksProgress = 0,
    this.totalDayTasksPoints = 0,
    this.completionRateToday = 0,
  });

  factory DailyTasksStats.empty() => const DailyTasksStats();

  factory DailyTasksStats.fromJson(Map<String, dynamic> j) => DailyTasksStats(
    totalDayTasks: _int(j['total_day_tasks']),
    dayTasksCompleted: _int(j['day_tasks_completed']),
    dayTasksNotCompleted: _int(j['day_tasks_not_completed']),
    dayTasksCompletionRate: _dbl(j['day_tasks_completion_rate']),
    dayTasksCompletionRating: _dbl(j['day_tasks_completion_rating']),
    totalDayTasksProgress: _int(j['total_day_tasks_progress']),
    totalDayTasksPoints: _int(j['total_day_tasks_points']),
    completionRateToday: _dbl(
      j['completion_rate_today'] ?? j['day_tasks_completion_rate'],
    ),
  );

  Map<String, dynamic> toJson() => {
    'total_day_tasks': totalDayTasks,
    'day_tasks_completed': dayTasksCompleted,
    'day_tasks_not_completed': dayTasksNotCompleted,
    'day_tasks_completion_rate': dayTasksCompletionRate,
    'day_tasks_completion_rating': dayTasksCompletionRating,
    'total_day_tasks_progress': totalDayTasksProgress,
    'total_day_tasks_points': totalDayTasksPoints,
    'completion_rate_today': completionRateToday,
  };

  // Aliases for chart compatibility
  int get completedToday => dayTasksCompleted;
  int get totalToday => totalDayTasks;
}

// --- overview → weekly_tasks_stats ---
// Aggregated numbers from the weekly_tasks table (all time)
class WeeklyTasksStats {
  final int totalWeekTasks; // total week tasks created
  final int weekTasksCompleted; // total completed
  final int weekTasksNotCompleted; // total not completed
  final double weekTasksCompletionRate; // completion rate %
  final double weekTasksCompletionRating; // average rating
  final int totalWeekTasksProgress; // average progress %
  final int totalWeekTasksPoints; // total points earned

  const WeeklyTasksStats({
    this.totalWeekTasks = 0,
    this.weekTasksCompleted = 0,
    this.weekTasksNotCompleted = 0,
    this.weekTasksCompletionRate = 0,
    this.weekTasksCompletionRating = 0,
    this.totalWeekTasksProgress = 0,
    this.totalWeekTasksPoints = 0,
  });

  factory WeeklyTasksStats.empty() => const WeeklyTasksStats();

  factory WeeklyTasksStats.fromJson(Map<String, dynamic> j) => WeeklyTasksStats(
    totalWeekTasks: _int(j['total_week_tasks']),
    weekTasksCompleted: _int(j['week_tasks_completed']),
    weekTasksNotCompleted: _int(j['week_tasks_not_completed']),
    weekTasksCompletionRate: _dbl(j['week_tasks_completion_rate']),
    weekTasksCompletionRating: _dbl(j['week_tasks_completion_rating']),
    totalWeekTasksProgress: _int(j['total_week_tasks_progress']),
    totalWeekTasksPoints: _int(j['total_week_tasks_points']),
  );

  Map<String, dynamic> toJson() => {
    'total_week_tasks': totalWeekTasks,
    'week_tasks_completed': weekTasksCompleted,
    'week_tasks_not_completed': weekTasksNotCompleted,
    'week_tasks_completion_rate': weekTasksCompletionRate,
    'week_tasks_completion_rating': weekTasksCompletionRating,
    'total_week_tasks_progress': totalWeekTasksProgress,
    'total_week_tasks_points': totalWeekTasksPoints,
  };
}

// --- overview → long_goals_stats ---
// Aggregated numbers from the long_goals table (all time)
class LongGoalsStats {
  final int totalLongGoals; // total goals created
  final int longGoalsActive; // currently active goals
  final int longGoalsCompleted; // completed goals
  final int longGoalsNotStarted; // goals not started yet
  final double longGoalsCompletionRate; // completion rate %
  final double longGoalsAverageProgress; // average progress %
  final double longGoalsCompletionRating; // average rating
  final double totalLongGoalsProgress; // total progress (same as average)
  final int totalLongGoalsPoints; // total points earned

  const LongGoalsStats({
    this.totalLongGoals = 0,
    this.longGoalsActive = 0,
    this.longGoalsCompleted = 0,
    this.longGoalsNotStarted = 0,
    this.longGoalsCompletionRate = 0,
    this.longGoalsAverageProgress = 0,
    this.longGoalsCompletionRating = 0,
    this.totalLongGoalsProgress = 0,
    this.totalLongGoalsPoints = 0,
  });

  factory LongGoalsStats.empty() => const LongGoalsStats();

  factory LongGoalsStats.fromJson(Map<String, dynamic> j) => LongGoalsStats(
    totalLongGoals: _int(j['total_long_goals']),
    longGoalsActive: _int(j['long_goals_active']),
    longGoalsCompleted: _int(j['long_goals_completed']),
    longGoalsNotStarted: _int(j['long_goals_not_started']),
    longGoalsCompletionRate: _dbl(j['long_goals_completion_rate']),
    longGoalsAverageProgress: _dbl(j['long_goals_average_progress']),
    longGoalsCompletionRating: _dbl(j['long_goals_completion_rating']),
    totalLongGoalsProgress: _dbl(j['total_long_goals_progress']),
    totalLongGoalsPoints: _int(j['total_long_goals_points']),
  );

  Map<String, dynamic> toJson() => {
    'total_long_goals': totalLongGoals,
    'long_goals_active': longGoalsActive,
    'long_goals_completed': longGoalsCompleted,
    'long_goals_not_started': longGoalsNotStarted,
    'long_goals_completion_rate': longGoalsCompletionRate,
    'long_goals_average_progress': longGoalsAverageProgress,
    'long_goals_completion_rating': longGoalsCompletionRating,
    'total_long_goals_progress': totalLongGoalsProgress,
    'total_long_goals_points': totalLongGoalsPoints,
  };

  // Aliases for chart compatibility
  int get completed => longGoalsCompleted;
  int get total => totalLongGoals;
}

// --- overview → bucket_list_stats ---
// Aggregated numbers from the bucket_models table (all time)
class BucketListStats {
  final int totalBucketItems; // total bucket items created
  final int bucketItemsCompleted; // completed buckets
  final int bucketItemsInProgress; // in-progress buckets
  final int bucketItemsNotStarted; // not started buckets
  final double bucketCompletionRate; // completion rate %
  final double bucketAverageProgress; // average progress %
  final double bucketCompletionRating; // average rating
  final double totalBucketProgress; // total progress (same as average)
  final int totalBucketPoints; // total points earned

  const BucketListStats({
    this.totalBucketItems = 0,
    this.bucketItemsCompleted = 0,
    this.bucketItemsInProgress = 0,
    this.bucketItemsNotStarted = 0,
    this.bucketCompletionRate = 0,
    this.bucketAverageProgress = 0,
    this.bucketCompletionRating = 0,
    this.totalBucketProgress = 0,
    this.totalBucketPoints = 0,
  });

  factory BucketListStats.empty() => const BucketListStats();

  factory BucketListStats.fromJson(Map<String, dynamic> j) => BucketListStats(
    totalBucketItems: _int(j['total_bucket_items']),
    bucketItemsCompleted: _int(j['bucket_items_completed']),
    bucketItemsInProgress: _int(j['bucket_items_in_progress']),
    bucketItemsNotStarted: _int(j['bucket_items_not_started']),
    bucketCompletionRate: _dbl(j['bucket_completion_rate']),
    bucketAverageProgress: _dbl(j['bucket_average_progress']),
    bucketCompletionRating: _dbl(j['bucket_completion_rating']),
    totalBucketProgress: _dbl(j['total_bucket_progress']),
    totalBucketPoints: _int(j['total_bucket_points']),
  );

  Map<String, dynamic> toJson() => {
    'total_bucket_items': totalBucketItems,
    'bucket_items_completed': bucketItemsCompleted,
    'bucket_items_in_progress': bucketItemsInProgress,
    'bucket_items_not_started': bucketItemsNotStarted,
    'bucket_completion_rate': bucketCompletionRate,
    'bucket_average_progress': bucketAverageProgress,
    'bucket_completion_rating': bucketCompletionRating,
    'total_bucket_progress': totalBucketProgress,
    'total_bucket_points': totalBucketPoints,
  };

  // Aliases for chart compatibility
  int get completed => bucketItemsCompleted;
  int get total => totalBucketItems;
}

// ================================================================
// DB COLUMN: today
// ================================================================

class TodaySummary {
  // --- today → date ---
  final DateTime date;

  // --- today → day_name ---
  final String dayName;

  // --- today → diary_entry ---
  // Today's diary entry info (null message if no entry)
  final TodayDiaryEntry diaryEntry;

  // --- today → buckets_entry ---
  // Bucket checklist items that have activity today
  final List<TodayBucketEntry> bucketsEntry;

  // --- today → day_tasks ---
  // All day tasks scheduled for today
  final List<TodayDayTask> dayTasks;

  // --- today → week_tasks_due_today ---
  // Weekly tasks that are scheduled for today's day of week
  final List<TodayWeekTask> weekTasksDueToday;

  // --- today → long_goals_due_today ---
  // Long goals that have a scheduled work day today
  final List<TodayLongGoal> longGoalsDueToday;

  // --- today → summary ---
  // Aggregate numbers for all of today's tasks
  final TodaySummaryMetrics summary;

  const TodaySummary({
    required this.date,
    this.dayName = '',
    required this.diaryEntry,
    this.bucketsEntry = const [],
    this.dayTasks = const [],
    this.weekTasksDueToday = const [],
    this.longGoalsDueToday = const [],
    required this.summary,
  });

  factory TodaySummary.empty() => TodaySummary(
    date: DateTime.now(),
    diaryEntry: TodayDiaryEntry.empty(),
    summary: TodaySummaryMetrics.empty(),
  );

  factory TodaySummary.fromJson(Map<String, dynamic> j) => TodaySummary(
    date: _dt(j['date']) ?? DateTime.now(),
    dayName: j['day_name'] as String? ?? '',
    diaryEntry: TodayDiaryEntry.fromJson(_parseJsonb(j['diary_entry'])),
    bucketsEntry: _parseJsonbListRaw(
      j['buckets_entry'],
    ).map((e) => TodayBucketEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
    dayTasks: _parseJsonbListRaw(
      j['day_tasks'],
    ).map((e) => TodayDayTask.fromJson(Map<String, dynamic>.from(e))).toList(),
    weekTasksDueToday: _parseJsonbListRaw(
      j['week_tasks_due_today'],
    ).map((e) => TodayWeekTask.fromJson(Map<String, dynamic>.from(e))).toList(),
    longGoalsDueToday: _parseJsonbListRaw(
      j['long_goals_due_today'],
    ).map((e) => TodayLongGoal.fromJson(Map<String, dynamic>.from(e))).toList(),
    summary: TodaySummaryMetrics.fromJson(_parseJsonb(j['summary'])),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'day_name': dayName,
    'diary_entry': diaryEntry.toJson(),
    'buckets_entry': {'items': bucketsEntry.map((e) => e.toJson()).toList()},
    'day_tasks': {'items': dayTasks.map((e) => e.toJson()).toList()},
    'week_tasks_due_today': {'items': weekTasksDueToday.map((e) => e.toJson()).toList()},
    'long_goals_due_today': {'items': longGoalsDueToday.map((e) => e.toJson()).toList()},
    'summary': summary.toJson(),
  };

  // True when there is absolutely nothing scheduled today
  bool get hasNoActivity =>
      dayTasks.isEmpty &&
      weekTasksDueToday.isEmpty &&
      longGoalsDueToday.isEmpty &&
      bucketsEntry.isEmpty;
}

// --- today → diary_entry ---
class TodayDiaryEntry {
  final bool hasEntry; // false = "No diary entry for today"
  final String moodLabel; // e.g. "Okay"
  final int wordCount; // number of words in the entry
  final int moodRating; // 1–10 mood scale

  const TodayDiaryEntry({
    this.hasEntry = false,
    this.moodLabel = '',
    this.wordCount = 0,
    this.moodRating = 0,
  });

  factory TodayDiaryEntry.empty() => const TodayDiaryEntry();

  factory TodayDiaryEntry.fromJson(Map<String, dynamic> j) => TodayDiaryEntry(
    hasEntry: j['has_entry'] == true,
    moodLabel: j['mood_label'] as String? ?? '',
    wordCount: _int(j['word_count']),
    moodRating: _int(j['mood_rating']),
  );

  Map<String, dynamic> toJson() => {
    'has_entry': hasEntry,
    'mood_label': moodLabel,
    'word_count': wordCount,
    'mood_rating': moodRating,
  };

  // UI helpers
  Color get moodColor => CardColorHelper.moodColorForValue(moodRating.toDouble());
  String get moodEmoji => CardColorHelper.moodEmojiForValue(moodRating.toDouble());

  // Message shown in UI when no diary entry exists
  String get emptyMessage => 'No diary entry for today';
}

// --- today → buckets_entry item ---
// A bucket checklist task that was actioned today
class TodayBucketEntry {
  final String id; // bucket_models.id
  final String title; // bucket title
  final String checklistTask; // the checklist item worked on
  final String status; // inProgress / completed
  final String priority; // high / medium / low
  final int points; // points earned from this item
  final int progress; // progress % of this checklist item
  final String? reward; // reward tag name if earned, null if not
  final DateTime? doneTime; // when this item was marked done

  final bool isOverdue;

  const TodayBucketEntry({
    required this.id,
    required this.title,
    this.checklistTask = '',
    this.status = '',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.reward,
    this.doneTime,
    this.isOverdue = false,
  });

  factory TodayBucketEntry.fromJson(Map<String, dynamic> j) => TodayBucketEntry(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    checklistTask: j['checklist_task'] as String? ?? '',
    status: j['status'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    points: _int(j['points']),
    progress: _int(j['progress']),
    reward: j['reward'] as String?,
    doneTime: _dt(j['done_time']),
    isOverdue: j['is_overdue'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'checklist_task': checklistTask,
    'status': status,
    'priority': priority,
    'points': points,
    'progress': progress,
    'reward': reward,
    'done_time': doneTime?.toIso8601String(),
    'is_overdue': isOverdue,
  };

  bool get hasReward => reward != null && reward!.isNotEmpty;
}

// --- today → day_tasks item ---
// A single day task scheduled for today
class TodayDayTask {
  final String id;
  final String title;
  final String priority;
  final String status;
  final String categoryType;
  final int points; // points earned (from Metadata)
  final int progress; // progress % (from Metadata)
  final TodayPenalty?
  penalty; // penalty info if any (from Metadata), null if none
  final String? reward; // reward tag name if earned, null if not
  final bool isComplete;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? summary;

  const TodayDayTask({
    required this.id,
    required this.title,
    this.priority = 'medium',
    this.status = '',
    this.categoryType = '',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.isComplete = false,
    this.timeStart,
    this.timeEnd,
    this.summary,
  });

  factory TodayDayTask.fromJson(Map<String, dynamic> j) => TodayDayTask(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    status: j['status'] as String? ?? '',
    categoryType: j['category_type'] as String? ?? '',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    isComplete: j['is_complete'] == true,
    timeStart: _dt(j['time_start']),
    timeEnd: _dt(j['time_end']),
    summary: j['summary'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'priority': priority,
    'status': status,
    'category_type': categoryType,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'is_complete': isComplete,
    'time_start': timeStart?.toIso8601String(),
    'time_end': timeEnd?.toIso8601String(),
    'summary': summary,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;

  bool get isOverdue {
    if (isComplete) return false;
    if (timeEnd == null) return false;
    return DateTime.now().isAfter(timeEnd!);
  }
}

// --- today → week_tasks_due_today item ---
// A weekly task whose scheduled day matches today
class TodayWeekTask {
  final String id;
  final String title;
  final String priority;
  final String status;
  final String categoryType;
  final int points; // points earned (from WeeklySummary)
  final int progress; // progress % (from WeeklySummary)
  final TodayPenalty?
  penalty; // penalty if any (from WeeklySummary), null if none
  final String? reward; // reward tag name if earned, null if not
  final bool isComplete;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? summary;

  const TodayWeekTask({
    required this.id,
    required this.title,
    this.priority = 'medium',
    this.status = '',
    this.categoryType = '',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.isComplete = false,
    this.timeStart,
    this.timeEnd,
    this.summary,
  });

  factory TodayWeekTask.fromJson(Map<String, dynamic> j) => TodayWeekTask(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    status: j['status'] as String? ?? '',
    categoryType: j['category_type'] as String? ?? '',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    isComplete: j['is_complete'] == true,
    timeStart: _dt(j['time_start']),
    timeEnd: _dt(j['time_end']),
    summary: j['summary'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'priority': priority,
    'status': status,
    'category_type': categoryType,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'is_complete': isComplete,
    'time_start': timeStart?.toIso8601String(),
    'time_end': timeEnd?.toIso8601String(),
    'summary': summary,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;

  bool get isOverdue {
    if (isComplete) return false;
    if (timeEnd == null) return false;
    return DateTime.now().isAfter(timeEnd!);
  }
}

// --- today → long_goals_due_today item ---
// A long goal with a scheduled work day today
class TodayLongGoal {
  final String id;
  final String title;
  final String priority;
  final String status;
  final String categoryType;
  final int points; // points earned (from GoalAnalysis)
  final int progress; // progress % (from GoalAnalysis)
  final TodayPenalty?
  penalty; // penalty if any (from GoalAnalysis), null if none
  final String? reward; // reward tag name if earned, null if not
  final bool isComplete;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? summary;

  const TodayLongGoal({
    required this.id,
    required this.title,
    this.priority = 'medium',
    this.status = '',
    this.categoryType = '',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.isComplete = false,
    this.timeStart,
    this.timeEnd,
    this.summary,
  });

  factory TodayLongGoal.fromJson(Map<String, dynamic> j) => TodayLongGoal(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    status: j['status'] as String? ?? '',
    categoryType: j['category_type'] as String? ?? '',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    isComplete: j['is_complete'] == true,
    timeStart: _dt(j['time_start']),
    timeEnd: _dt(j['time_end']),
    summary: j['summary'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'priority': priority,
    'status': status,
    'category_type': categoryType,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'is_complete': isComplete,
    'time_start': timeStart?.toIso8601String(),
    'time_end': timeEnd?.toIso8601String(),
    'summary': summary,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;

  bool get isOverdue {
    if (isComplete) return false;
    if (timeEnd == null) return false;
    return DateTime.now().isAfter(timeEnd!);
  }
}

// --- Shared penalty model used inside today tasks ---
// Stored as null when no penalty exists
class TodayPenalty {
  final int penaltyPoints; // how many points were deducted
  final String reason; // why the penalty was applied

  const TodayPenalty({required this.penaltyPoints, required this.reason});

  factory TodayPenalty.fromJson(Map<String, dynamic> j) => TodayPenalty(
    penaltyPoints: _int(j['penalty_points']),
    reason: j['reason'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'penalty_points': penaltyPoints,
    'reason': reason,
  };
}

// --- today → summary ---
// Aggregate metrics for everything scheduled today
class TodaySummaryMetrics {
  final int totalScheduledTask; // total tasks/goals/buckets today
  final int notCompleted; // count not completed
  final int completed; // count completed
  final int inProgress; // count in progress
  final int pointsEarned; // total points earned today
  final double dayRating; // average rating for today

  const TodaySummaryMetrics({
    this.totalScheduledTask = 0,
    this.notCompleted = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.pointsEarned = 0,
    this.dayRating = 0,
  });

  factory TodaySummaryMetrics.empty() => const TodaySummaryMetrics();

  factory TodaySummaryMetrics.fromJson(Map<String, dynamic> j) =>
      TodaySummaryMetrics(
        totalScheduledTask: _int(j['total_scheduled_task']),
        notCompleted: _int(j['not_completed']),
        completed: _int(j['completed']),
        inProgress: _int(j['in_progress']),
        pointsEarned: _int(j['points_earned']),
        dayRating: _dbl(j['day_rating']),
      );

  Map<String, dynamic> toJson() => {
    'total_scheduled_task': totalScheduledTask,
    'not_completed': notCompleted,
    'completed': completed,
    'in_progress': inProgress,
    'points_earned': pointsEarned,
    'day_rating': dayRating,
  };

  double get completionRate =>
      totalScheduledTask > 0 ? (completed / totalScheduledTask) * 100 : 0;

  int get notStarted => notCompleted;
}

// ================================================================
// DB COLUMN: active_items
// ================================================================

class ActiveItems {
  // --- active_items → active_day_tasks ---
  // Day tasks still in progress (not completed, not cancelled)
  final List<ActiveDayTask> activeDayTasks;

  // --- active_items → active_buckets ---
  // Bucket lists still in progress (no complete_date)
  final List<ActiveBucket> activeBuckets;

  // --- active_items → active_long_goals ---
  // Long goals with status = inProgress
  final List<ActiveLongGoal> activeLongGoals;

  // --- active_items → active_week_tasks ---
  // Weekly tasks with status = inProgress
  final List<ActiveWeekTask> activeWeekTasks;

  const ActiveItems({
    this.activeDayTasks = const [],
    this.activeBuckets = const [],
    this.activeLongGoals = const [],
    this.activeWeekTasks = const [],
  });

  factory ActiveItems.empty() => const ActiveItems();

  factory ActiveItems.fromJson(Map<String, dynamic> j) => ActiveItems(
    activeDayTasks: _parseJsonbListRaw(
      j['active_day_tasks'],
    ).map((e) => ActiveDayTask.fromJson(Map<String, dynamic>.from(e))).toList(),
    activeBuckets: _parseJsonbListRaw(
      j['active_buckets'],
    ).map((e) => ActiveBucket.fromJson(Map<String, dynamic>.from(e))).toList(),
    activeLongGoals: _parseJsonbListRaw(
      j['active_long_goals'],
    ).map((e) => ActiveLongGoal.fromJson(Map<String, dynamic>.from(e))).toList(),
    activeWeekTasks: _parseJsonbListRaw(
      j['active_week_tasks'],
    ).map((e) => ActiveWeekTask.fromJson(Map<String, dynamic>.from(e))).toList(),
  );

  Map<String, dynamic> toJson() => {
    'active_day_tasks': {'items': activeDayTasks.map((e) => e.toJson()).toList()},
    'active_buckets': {'items': activeBuckets.map((e) => e.toJson()).toList()},
    'active_long_goals': {'items': activeLongGoals.map((e) => e.toJson()).toList()},
    'active_week_tasks': {'items': activeWeekTasks.map((e) => e.toJson()).toList()},
  };

  bool get hasNoDayTasks => activeDayTasks.isEmpty;
  bool get hasNoBuckets => activeBuckets.isEmpty;
  bool get hasNoLongGoals => activeLongGoals.isEmpty;
  bool get hasNoWeekTasks => activeWeekTasks.isEmpty;
  bool get isCompletelyEmpty =>
      hasNoDayTasks && hasNoBuckets && hasNoLongGoals && hasNoWeekTasks;

  int get totalActiveCount =>
      activeDayTasks.length +
      activeBuckets.length +
      activeLongGoals.length +
      activeWeekTasks.length;
}

// --- active_items → active_day_tasks item ---
// Data sourced from day_tasks.metadata (Metadata model)
class ActiveDayTask {
  final String id;
  final String title;
  final String status;
  final String priority;
  final int points; // from Metadata.pointsEarned
  final int progress; // from Metadata.progress
  final TodayPenalty? penalty; // from Metadata.penalty (null if no penalty)
  final String? reward; // reward tag name if earned, null if not
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final bool isComplete;

  const ActiveDayTask({
    required this.id,
    required this.title,
    this.status = '',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.timeStart,
    this.timeEnd,
    this.isComplete = false,
  });

  factory ActiveDayTask.fromJson(Map<String, dynamic> j) => ActiveDayTask(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    timeStart: _dt(j['time_start']),
    timeEnd: _dt(j['time_end']),
    isComplete: j['is_complete'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'priority': priority,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'time_start': timeStart?.toIso8601String(),
    'time_end': timeEnd?.toIso8601String(),
    'is_complete': isComplete,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;

  bool get isOverdue {
    if (isComplete) return false;
    if (timeEnd == null) return false;
    return DateTime.now().isAfter(timeEnd!);
  }
}

// --- active_items → active_buckets item ---
// Data sourced from bucket_models.metadata (BucketMetadata model)
class ActiveBucket {
  final String id;
  final String title;
  final String status;
  final String priority;
  final int points; // from BucketMetadata.totalPointsEarned
  final int progress; // from BucketMetadata.averageProgress
  final TodayPenalty? penalty; // from BucketMetadata (null if no penalty)
  final String? reward; // reward tag name if earned, null if not
  final DateTime? startingDate;
  final DateTime? endingDate;
  final bool isOverdue;

  const ActiveBucket({
    required this.id,
    required this.title,
    this.status = '',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.startingDate,
    this.endingDate,
    this.isOverdue = false,
  });

  factory ActiveBucket.fromJson(Map<String, dynamic> j) => ActiveBucket(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    startingDate: _dt(j['statinge_date']),
    endingDate: _dt(j['endinge_date']),
    isOverdue: j['is_overdue'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'priority': priority,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'statinge_date': startingDate?.toIso8601String(),
    'endinge_date': endingDate?.toIso8601String(),
    'is_overdue': isOverdue,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;
}

// --- active_items → active_long_goals item ---
// Data sourced from long_goals.analysis (GoalAnalysis model)
class ActiveLongGoal {
  final String id;
  final String title;
  final String status;
  final String priority;
  final int points; // from GoalAnalysis.pointsEarned
  final int progress; // from GoalAnalysis.averageProgress
  final TodayPenalty?
  penalty; // from GoalAnalysis.totalPenalty (null if no penalty)
  final String? reward; // reward tag name if earned, null if not
  final DateTime? startingDate;
  final DateTime? endingDate;
  final bool isOverdue;

  const ActiveLongGoal({
    required this.id,
    required this.title,
    this.status = '',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.startingDate,
    this.endingDate,
    this.isOverdue = false,
  });

  factory ActiveLongGoal.fromJson(Map<String, dynamic> j) => ActiveLongGoal(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    startingDate: _dt(j['statinge_date']),
    endingDate: _dt(j['endinge_date']),
    isOverdue: j['is_overdue'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'priority': priority,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'statinge_date': startingDate?.toIso8601String(),
    'endinge_date': endingDate?.toIso8601String(),
    'is_overdue': isOverdue,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;
}

// --- active_items → active_week_tasks item ---
// Data sourced from weekly_tasks.metadata (WeeklySummary model)
class ActiveWeekTask {
  final String id;
  final String title;
  final String status;
  final String priority;
  final int points; // from WeeklySummary.pointsEarned
  final int progress; // from WeeklySummary.progress
  final TodayPenalty?
  penalty; // from WeeklySummary.penalty (null if no penalty)
  final String? reward; // reward tag name if earned, null if not
  final DateTime? startingDate;
  final DateTime? endingDate;
  final bool isOverdue;

  const ActiveWeekTask({
    required this.id,
    required this.title,
    this.status = '',
    this.priority = 'medium',
    this.points = 0,
    this.progress = 0,
    this.penalty,
    this.reward,
    this.startingDate,
    this.endingDate,
    this.isOverdue = false,
  });

  factory ActiveWeekTask.fromJson(Map<String, dynamic> j) => ActiveWeekTask(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    status: j['status'] as String? ?? '',
    priority: j['priority'] as String? ?? 'medium',
    points: _int(j['points']),
    progress: _int(j['progress']),
    penalty: j['penalty'] != null
        ? TodayPenalty.fromJson(_parseJsonb(j['penalty']))
        : null,
    reward: j['reward'] as String?,
    startingDate: _dt(j['statinge_date']),
    endingDate: _dt(j['endinge_date']),
    isOverdue: j['is_overdue'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'priority': priority,
    'points': points,
    'progress': progress,
    'penalty': penalty?.toJson(),
    'reward': reward,
    'statinge_date': startingDate?.toIso8601String(),
    'endinge_date': endingDate?.toIso8601String(),
    'is_overdue': isOverdue,
  };

  bool get hasPenalty => penalty != null;
  bool get hasReward => reward != null && reward!.isNotEmpty;
}

// ================================================================
// DB COLUMN: progress_history
// ================================================================

class ProgressHistory {
  // --- progress_history → trend ---
  // "improving" / "declining" / "stable"
  final String trend;

  // --- progress_history → average_progress ---
  // Average daily progress across the last 30 days
  final double averageProgress;

  // --- progress_history → best_day ---
  // Day with highest points in the last 30 days
  final DayValuePoint? bestDay;

  // --- progress_history → worst_day ---
  // Day with lowest (but non-zero) points in the last 30 days
  final DayValuePoint? worstDay;

  // --- progress_history → daily_stats ---
  // One entry per day for the last 30 days
  // Each entry has: date, points, tasks_completed, streaks, completion_rate
  final List<DailyStatPoint> dailyStats;

  const ProgressHistory({
    this.trend = 'stable',
    this.averageProgress = 0,
    this.bestDay,
    this.worstDay,
    this.dailyStats = const [],
  });

  factory ProgressHistory.empty() => const ProgressHistory();

  factory ProgressHistory.fromJson(Map<String, dynamic> j) => ProgressHistory(
    trend: j['trend'] as String? ?? 'stable',
    averageProgress: _dbl(j['average_progress']),
    bestDay: j['best_day'] != null
        ? DayValuePoint.fromJson(_parseJsonb(j['best_day']))
        : null,
    worstDay: j['worst_day'] != null
        ? DayValuePoint.fromJson(_parseJsonb(j['worst_day']))
        : null,
    dailyStats: _parseJsonbListRaw(
      j['daily_stats'],
    ).map((e) => DailyStatPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
  );

  Map<String, dynamic> toJson() => {
    'trend': trend,
    'average_progress': averageProgress,
    'best_day': bestDay?.toJson(),
    'worst_day': worstDay?.toJson(),
    'daily_stats': {'items': dailyStats.map((e) => e.toJson()).toList()},
  };

  // Total points across all 30 days
  double get totalPoints => dailyStats.fold(0.0, (s, p) => s + p.points);

  IconData get trendIcon {
    switch (trend) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }
}

// --- progress_history → best_day / worst_day ---
class DayValuePoint {
  final DateTime date;
  final int value; // points value for that day
  final int? tasksCompleted; // tasks completed that day

  const DayValuePoint({
    required this.date,
    required this.value,
    this.tasksCompleted = 0,
  });

  factory DayValuePoint.fromJson(Map<String, dynamic> j) => DayValuePoint(
    date: _dt(j['date']) ?? DateTime.now(),
    value: _int(j['value']),
    tasksCompleted: _int(j['tasks_completed']),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'value': value,
    'tasks_completed': tasksCompleted,
  };

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// --- progress_history → daily_stats item ---
// One consolidated object per day (replaces the old 4 separate arrays)
class DailyStatPoint {
  final DateTime date;
  final int points; // points earned that day
  final int tasksCompleted; // number of tasks completed that day
  final int streaks; // streak count at that day
  final double completionRate; // completion rate % for that day

  const DailyStatPoint({
    required this.date,
    this.points = 0,
    this.tasksCompleted = 0,
    this.streaks = 0,
    this.completionRate = 0,
  });

  factory DailyStatPoint.fromJson(Map<String, dynamic> j) => DailyStatPoint(
    date: _dt(j['date']) ?? DateTime.now(),
    points: _int(j['points']),
    tasksCompleted: _int(j['tasks_completed']),
    streaks: _int(j['streaks']),
    completionRate: _dbl(j['completion_rate']),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'points': points,
    'tasks_completed': tasksCompleted,
    'streaks': streaks,
    'completion_rate': completionRate,
  };

  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String get shortDate => '${date.day}/${date.month}';

  bool get hasActivity => tasksCompleted > 0 || points > 0;
}

// ================================================================
// DB COLUMN: weekly_history
// ================================================================

class WeeklyHistory {
  // --- weekly_history → last_week_points ---
  final int lastWeekPoints;

  // --- weekly_history → current_week_points ---
  final int currentWeekPoints;

  // --- weekly_history → average_weekly_points ---
  final double averageWeeklyPoints;

  // --- weekly_history → week_over_week_change ---
  // % change between last week and current week
  final double weekOverWeekChange;

  // --- weekly_history → best_week ---
  final WeekValuePoint? bestWeek;

  // --- weekly_history → worst_week ---
  final WeekValuePoint? worstWeek;

  // --- weekly_history → weekly_stats ---
  // One entry per week for the last 12 weeks
  final List<WeeklyStatPoint> weeklyStats;

  const WeeklyHistory({
    this.lastWeekPoints = 0,
    this.currentWeekPoints = 0,
    this.averageWeeklyPoints = 0,
    this.weekOverWeekChange = 0,
    this.bestWeek,
    this.worstWeek,
    this.weeklyStats = const [],
  });

  factory WeeklyHistory.empty() => const WeeklyHistory();

  factory WeeklyHistory.fromJson(Map<String, dynamic> j) => WeeklyHistory(
    lastWeekPoints: _int(j['last_week_points']),
    currentWeekPoints: _int(j['current_week_points']),
    averageWeeklyPoints: _dbl(j['average_weekly_points']),
    weekOverWeekChange: _dbl(j['week_over_week_change']),
    bestWeek: j['best_week'] != null
        ? WeekValuePoint.fromJson(_parseJsonb(j['best_week']))
        : null,
    worstWeek: j['worst_week'] != null
        ? WeekValuePoint.fromJson(_parseJsonb(j['worst_week']))
        : null,
    weeklyStats: _parseJsonbListRaw(
      j['weekly_stats'],
    ).map((e) => WeeklyStatPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
  );

  Map<String, dynamic> toJson() => {
    'last_week_points': lastWeekPoints,
    'current_week_points': currentWeekPoints,
    'average_weekly_points': averageWeeklyPoints,
    'week_over_week_change': weekOverWeekChange,
    'best_week': bestWeek?.toJson(),
    'worst_week': worstWeek?.toJson(),
    'weekly_stats': {'items': weeklyStats.map((e) => e.toJson()).toList()},
  };

  int get totalTasksCompleted =>
      weeklyStats.fold(0, (s, w) => s + w.tasksCompleted);
}

// --- weekly_history → best_week / worst_week ---
class WeekValuePoint {
  final int points;
  final DateTime weekStart;
  final int weekNumber;
  final int? tasksCompleted;

  const WeekValuePoint({
    required this.points,
    required this.weekStart,
    required this.weekNumber,
    this.tasksCompleted = 0,
  });

  factory WeekValuePoint.fromJson(Map<String, dynamic> j) => WeekValuePoint(
    points: _int(j['points']),
    weekStart: _dt(j['week_start']) ?? DateTime.now(),
    weekNumber: _int(j['week_number']),
    tasksCompleted: _int(j['tasks_completed']),
  );

  Map<String, dynamic> toJson() => {
    'points': points,
    'week_start': weekStart.toIso8601String(),
    'week_number': weekNumber,
    'tasks_completed': tasksCompleted,
  };
}

// --- weekly_history → weekly_stats item ---
// One consolidated object per week (replaces the old 4 separate arrays)
class WeeklyStatPoint {
  final int weekNumber;
  final DateTime weekStart;
  final int points; // total points that week
  final int tasksCompleted; // tasks completed that week
  final int goalsCompleted; // long goals completed that week
  final double completionRate; // completion rate % that week

  const WeeklyStatPoint({
    required this.weekNumber,
    required this.weekStart,
    this.points = 0,
    this.tasksCompleted = 0,
    this.goalsCompleted = 0,
    this.completionRate = 0,
  });

  factory WeeklyStatPoint.fromJson(Map<String, dynamic> j) => WeeklyStatPoint(
    weekNumber: _int(j['week_number']),
    weekStart: _dt(j['week_start']) ?? DateTime.now(),
    points: _int(j['points']),
    tasksCompleted: _int(j['tasks_completed']),
    goalsCompleted: _int(j['goals_completed']),
    completionRate: _dbl(j['completion_rate']),
  );

  Map<String, dynamic> toJson() => {
    'week_number': weekNumber,
    'week_start': weekStart.toIso8601String(),
    'points': points,
    'tasks_completed': tasksCompleted,
    'goals_completed': goalsCompleted,
    'completion_rate': completionRate,
  };

  bool get hasActivity => tasksCompleted > 0 || points > 0;
}

// ================================================================
// DB COLUMN: category_stats
// (Unchanged from previous version — same structure)
// ================================================================

class CategoryStats {
  // --- category_stats → stats ---
  final List<CategoryStatItem> stats;

  // --- category_stats → top_category ---
  final String topCategory;

  // --- category_stats → total_points ---
  final int totalPoints;

  // --- category_stats → category_percentages ---
  final Map<String, double> categoryPercentages;

  const CategoryStats({
    this.stats = const [],
    this.topCategory = '',
    this.totalPoints = 0,
    this.categoryPercentages = const {},
  });

  factory CategoryStats.empty() => const CategoryStats();

  factory CategoryStats.fromJson(Map<String, dynamic> j) {
    final Map<String, double> pct = {};
    final raw = j['category_percentages'];
    if (raw is Map) raw.forEach((k, v) => pct[k.toString()] = _dbl(v));
    return CategoryStats(
      stats: _parseJsonbListRaw(
        j['stats'],
      ).map((e) => CategoryStatItem.fromJson(Map<String, dynamic>.from(e))).toList(),
      topCategory: j['top_category'] as String? ?? '',
      totalPoints: _int(j['total_points']),
      categoryPercentages: pct,
    );
  }

  Map<String, dynamic> toJson() => {
    'stats': {'items': stats.map((e) => e.toJson()).toList()},
    'top_category': topCategory,
    'total_points': totalPoints,
    'category_percentages': categoryPercentages,
  };

  Color getCategoryColor(String name) {
    try {
      return stats
          .firstWhere((s) => s.categoryName.toLowerCase() == name.toLowerCase())
          .displayColor;
    } catch (_) {
      return const Color(0xFF94A3B8);
    }
  }
}

class CategoryStatItem {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final String icon;
  final String color;
  final int points;
  final int totalTasks;
  final int tasksCompleted;
  final double completionRate;

  const CategoryStatItem({
    this.categoryId = '',
    required this.categoryName,
    this.categoryType = '',
    this.icon = '📌',
    this.color = '#94A3B8',
    this.points = 0,
    this.totalTasks = 0,
    this.tasksCompleted = 0,
    this.completionRate = 0,
  });

  factory CategoryStatItem.fromJson(Map<String, dynamic> j) => CategoryStatItem(
    categoryId: j['category_id'] as String? ?? '',
    categoryName: j['category_name'] as String? ?? '',
    categoryType: j['category_type'] as String? ?? '',
    icon: j['icon'] as String? ?? '📌',
    color: j['color'] as String? ?? '#94A3B8',
    points: _int(j['points']),
    totalTasks: _int(j['total_tasks']),
    tasksCompleted: _int(j['tasks_completed']),
    completionRate: _dbl(j['completion_rate']),
  );

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'category_name': categoryName,
    'category_type': categoryType,
    'icon': icon,
    'color': color,
    'points': points,
    'total_tasks': totalTasks,
    'tasks_completed': tasksCompleted,
    'completion_rate': completionRate,
  };

  Color get displayColor {
    try {
      final hex = color.replaceFirst('#', '');
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
    return const Color(0xFF94A3B8);
  }
}

// ================================================================
// DB COLUMN: rewards
// ================================================================

class Rewards {
  // --- rewards → summary ---
  // High-level reward totals shown in the rewards card header
  final RewardsSummary summary;

  // --- rewards → earned_rewards_no ---
  // Count of how many times EACH TIER has been earned (ALL TIME, all sources)
  // e.g. {"spark": 5, "flame": 3, "blaze": 23, ...}
  // "blaze": 23 means the user has earned the Blaze reward 23 times total
  final Map<String, int> earnedRewardsNo;

  // --- rewards → unlocked_rewards ---
  // Full list of ALL rewards ever earned (all time, all task types)
  final List<UnlockedReward> unlockedRewards;

  const Rewards({
    required this.summary,
    this.earnedRewardsNo = const {},
    this.unlockedRewards = const [],
  });

  factory Rewards.empty() => Rewards(summary: RewardsSummary.empty());

  factory Rewards.fromJson(Map<String, dynamic> j) {
    final Map<String, int> counts = {};
    final rawCounts = j['earned_rewards_no'];
    if (rawCounts is Map) {
      rawCounts.forEach((k, v) => counts[k.toString()] = _int(v));
    }
    return Rewards(
      summary: RewardsSummary.fromJson(_parseJsonb(j['summary'])),
      earnedRewardsNo: counts,
      unlockedRewards: _parseJsonbListRaw(
        j['unlocked_rewards'],
      ).map((e) => UnlockedReward.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary.toJson(),
    'earned_rewards_no': earnedRewardsNo,
    'unlocked_rewards': {'items': unlockedRewards.map((e) => e.toJson()).toList()},
  };

  int get totalRewardsEarned => summary.totalRewardsEarned;
  String get bestTierAchieved => summary.bestTierAchieved;
  int get totalPoints => summary.totalPoints;

  // Getters for individual tier counts (all time)
  int get sparkCount => earnedRewardsNo['spark'] ?? 0;
  int get flameCount => earnedRewardsNo['flame'] ?? 0;
  int get emberCount => earnedRewardsNo['ember'] ?? 0;
  int get blazeCount => earnedRewardsNo['blaze'] ?? 0;
  int get crystalCount => earnedRewardsNo['crystal'] ?? 0;
  int get prismCount => earnedRewardsNo['prism'] ?? 0;
  int get radiantCount => earnedRewardsNo['radiant'] ?? 0;
  int get novaCount => earnedRewardsNo['nova'] ?? 0;

  // Most recently earned rewards (for display in activity feed)
  List<UnlockedReward> get recentRewards {
    final sorted = List<UnlockedReward>.from(unlockedRewards)
      ..sort(
        (a, b) => (b.earnedAt ?? DateTime(1970)).compareTo(
          a.earnedAt ?? DateTime(1970),
        ),
      );
    return sorted.take(5).toList();
  }

  Color get bestTierColor => CardColorHelper.getTierColor(summary.bestTierAchieved);
  String get bestTierEmoji => CardColorHelper.getTierEmoji(summary.bestTierAchieved);
}

// --- rewards → summary ---
class RewardsSummary {
  final int allRewardsPoints; // total points from all rewards
  final int totalPoints; // alias for allRewardsPoints
  final String bestTierAchieved; // highest tier ever earned
  final String worstTierAchieved; // lowest tier earned (or "none" if not yet)
  final int totalRewardsEarned; // total number of rewards earned all time
  final String nextRewards; // next reward user is working towards
  final String? suggestion; // smart suggestion for the user (can be null after hot reload)

  const RewardsSummary({
    this.allRewardsPoints = 0,
    this.totalPoints = 0,
    this.bestTierAchieved = 'none',
    this.worstTierAchieved = 'none',
    this.totalRewardsEarned = 0,
    this.nextRewards = 'none',
    this.suggestion = '',
  });

  factory RewardsSummary.empty() => const RewardsSummary();

  factory RewardsSummary.fromJson(Map<String, dynamic> j) => RewardsSummary(
    allRewardsPoints: _int(j['all_rewards_points']),
    totalPoints: _int(j['all_rewards_points']),
    bestTierAchieved: j['best_tier_achieved'] as String? ?? 'none',
    worstTierAchieved: j['worst_tier_achieved'] as String? ?? 'none',
    totalRewardsEarned: _int(j['total_rewards_earned']),
    nextRewards: j['next_rewards'] as String? ?? 'none',
    suggestion: j['suggestion'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'all_rewards_points': allRewardsPoints,
    'best_tier_achieved': bestTierAchieved,
    'worst_tier_achieved': worstTierAchieved,
    'total_rewards_earned': totalRewardsEarned,
    'next_rewards': nextRewards,
    'suggestion': suggestion,
  };

  Color get bestTierColor => CardColorHelper.getTierColor(bestTierAchieved);
  String get bestTierEmoji => CardColorHelper.getTierEmoji(bestTierAchieved);
  Color get worstTierColor => CardColorHelper.getTierColor(worstTierAchieved);
  String get worstTierEmoji => CardColorHelper.getTierEmoji(worstTierAchieved);

  Color getTierColor(String tier) => CardColorHelper.getTierColor(tier);
}

// --- rewards → unlocked_rewards item ---
// A single reward ever earned by the user (from any task type)
class UnlockedReward {
  final String id; // source task/goal/bucket id
  final String icon; // emoji icon for this tier
  final String tagName; // reward tag name e.g. "Rising Flame"
  final String tier; // reward tier name e.g. "flame"
  final String? category; // category_type of the source task
  final DateTime? earnedAt; // when this reward was earned
  final String
  earnedFrom; // source type: "day_task" / "week_task" / "long_goal" / "bucket"
  final String taskName; // name of the task/goal/bucket that earned this
  final int? points; // points earned from this reward (can be null after hot reload)

  const UnlockedReward({
    required this.id,
    this.icon = '🏆',
    this.tagName = '',
    required this.tier,
    this.category,
    this.earnedAt,
    this.earnedFrom = '',
    this.taskName = '',
    this.points = 0,
  });

  factory UnlockedReward.fromJson(Map<String, dynamic> j) => UnlockedReward(
    id: j['id'] as String? ?? '',
    icon: j['icon'] as String? ?? '🏆',
    tagName: j['tagName'] as String? ?? j['tag_name'] as String? ?? '',
    tier: j['tier'] as String? ?? '',
    category: j['category'] as String?,
    earnedAt: _dt(j['earned_at']),
    earnedFrom: j['earned_from'] as String? ?? '',
    taskName: j['task_name'] as String? ?? '',
    points: _int(j['points']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'tagName': tagName,
    'tier': tier,
    'category': category,
    'earned_at': earnedAt?.toIso8601String(),
    'earned_from': earnedFrom,
    'task_name': taskName,
    'points': points,
  };

  Color get tierColor => CardColorHelper.getTierColor(tier);
  String get tierEmoji => CardColorHelper.getTierEmoji(tier);

  String get timeAgo {
    if (earnedAt == null) return '';
    final d = DateTime.now().difference(earnedAt!);
    if (d.inDays == 0) return 'Today';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    return '${(d.inDays / 30).floor()}mo ago';
  }
}

// ================================================================
// DB COLUMN: mood
// (Unchanged from previous version — same structure)
// ================================================================

class Mood {
  // --- mood → trend ---
  final String trend; // "improving" / "declining" / "stable"

  // --- mood → today_mood ---
  final TodayMood? todayMood;

  // --- mood → mood_history ---
  // One entry per diary entry that has a mood rating
  final List<MoodDataPoint> moodHistory;

  // --- mood → mood_frequency ---
  // e.g. {"Good": 5, "Okay": 3}
  final Map<String, int> moodFrequency;

  // --- mood → most_common_mood ---
  final String mostCommonMood;

  // --- mood → average_mood_last_7_days (1–10 scale) ---
  final double averageMoodLast7Days;

  // --- mood → average_mood_last_30_days (1–10 scale) ---
  final double averageMoodLast30Days;

  const Mood({
    this.trend = 'stable',
    this.todayMood,
    this.moodHistory = const [],
    this.moodFrequency = const {},
    this.mostCommonMood = '',
    this.averageMoodLast7Days = 0,
    this.averageMoodLast30Days = 0,
  });

  factory Mood.empty() => const Mood();

  factory Mood.fromJson(Map<String, dynamic> j) {
    final Map<String, int> freq = {};
    final rawFreq = j['mood_frequency'];
    if (rawFreq is Map) rawFreq.forEach((k, v) => freq[k.toString()] = _int(v));
    return Mood(
      trend: j['trend'] as String? ?? 'stable',
      todayMood: j['today_mood'] != null
          ? TodayMood.fromJson(_parseJsonb(j['today_mood']))
          : null,
      moodHistory: _parseJsonbListRaw(
        j['mood_history'],
      ).map((e) => MoodDataPoint.fromJson(Map<String, dynamic>.from(e))).toList(),
      moodFrequency: freq,
      mostCommonMood: j['most_common_mood'] as String? ?? '',
      averageMoodLast7Days: _dbl(j['average_mood_last_7_days']),
      averageMoodLast30Days: _dbl(j['average_mood_last_30_days']),
    );
  }

  Map<String, dynamic> toJson() => {
    'trend': trend,
    'today_mood': todayMood?.toJson(),
    'mood_history': {'items': moodHistory.map((e) => e.toJson()).toList()},
    'mood_frequency': moodFrequency,
    'most_common_mood': mostCommonMood,
    'average_mood_last_7_days': averageMoodLast7Days,
    'average_mood_last_30_days': averageMoodLast30Days,
  };

  String get moodEmoji => CardColorHelper.moodEmojiForValue(averageMoodLast7Days);
  Color get moodColor => CardColorHelper.moodColorForValue(averageMoodLast7Days);

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

  Color get trendColor {
    switch (trend.toLowerCase()) {
      case 'improving':
        return const Color(0xFF43E97B);
      case 'declining':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  List<MoodDataPoint> get last7DaysHistory {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return moodHistory.where((p) => p.date.isAfter(cutoff)).toList();
  }
}

class TodayMood {
  final String emoji;
  final String label;
  final int rating; // 1–10

  const TodayMood({this.emoji = '😐', this.label = '', this.rating = 0});

  factory TodayMood.fromJson(Map<String, dynamic> j) => TodayMood(
    emoji: j['emoji'] as String? ?? '😐',
    label: j['label'] as String? ?? '',
    rating: _int(j['rating']),
  );

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'label': label,
    'rating': rating,
  };

  Color get color => CardColorHelper.moodColorForValue(rating.toDouble());
  String get displayEmoji => CardColorHelper.moodEmojiForValue(rating.toDouble());
}

class MoodDataPoint {
  final DateTime date;
  final double value; // 1–10
  final String? label;

  const MoodDataPoint({required this.date, required this.value, this.label});

  factory MoodDataPoint.fromJson(Map<String, dynamic> j) => MoodDataPoint(
    date: _dt(j['date']) ?? DateTime.now(),
    value: _dbl(j['value']),
    label: j['label'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'value': value,
    'label': label,
  };

  String get moodEmoji => CardColorHelper.moodEmojiForValue(value);
  String get emoji => moodEmoji;
  Color get moodColor => CardColorHelper.moodColorForValue(value);
}

// ================================================================
// DB COLUMN: streaks
// ================================================================

class Streaks {
  // --- streaks → current ---
  // Info about the current active streak
  final StreakCurrent current;

  // --- streaks → longest ---
  // Info about the all-time longest streak
  final StreakLongest longest;

  // --- streaks → next_milestone ---
  // The next streak milestone the user is working towards
  final StreakNextMilestone nextMilestone;

  // --- streaks → risk ---
  // Whether the current streak is at risk of breaking today
  final StreakRisk risk;

  // --- streaks → history ---
  // 30-day calendar + break history
  final StreakHistory history;

  // --- streaks → stats ---
  // All-time streak statistics
  final StreakStats stats;

  // Keep flat milestones list for quick access
  final List<int> milestones;

  const Streaks({
    required this.current,
    required this.longest,
    required this.nextMilestone,
    required this.risk,
    required this.history,
    required this.stats,
    this.milestones = const [3, 7, 14, 21, 30, 60, 90, 180, 365],
  });

  factory Streaks.empty() => Streaks(
    current: StreakCurrent.empty(),
    longest: StreakLongest.empty(),
    nextMilestone: StreakNextMilestone.empty(),
    risk: StreakRisk.empty(),
    history: StreakHistory.empty(),
    stats: StreakStats.empty(),
  );

  factory Streaks.fromJson(Map<String, dynamic> j) {
    List<int> ms = [3, 7, 14, 21, 30, 60, 90, 180, 365];
    final rawMs = _parseJsonbListRaw(j['milestones']);
    if (rawMs.isNotEmpty) {
      ms = rawMs.whereType<num>().map((e) => e.toInt()).toList();
    }
    return Streaks(
      current: StreakCurrent.fromJson(_parseJsonb(j['current'])),
      longest: StreakLongest.fromJson(_parseJsonb(j['longest'])),
      nextMilestone: StreakNextMilestone.fromJson(
        _parseJsonb(j['next_milestone']),
      ),
      risk: StreakRisk.fromJson(_parseJsonb(j['risk'])),
      history: StreakHistory.fromJson(_parseJsonb(j['history'])),
      stats: StreakStats.fromJson(_parseJsonb(j['stats'])),
      milestones: ms,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current.toJson(),
    'longest': longest.toJson(),
    'next_milestone': nextMilestone.toJson(),
    'risk': risk.toJson(),
    'history': history.toJson(),
    'stats': stats.toJson(),
    'milestones': {'items': milestones},
  };

  // Convenience getters for UI
  int get currentDays => current.days;
  int get longestDays => longest.days;
  int get currentStreak => current.days;
  int get longestStreak => longest.days;
  bool get isActive => current.isActive;
  bool get isAtRisk => risk.isAtRisk;

  String get streakEmoji {
    final d = current.days;
    if (d >= 30) return '🔥🔥🔥';
    if (d >= 14) return '🔥🔥';
    if (d >= 7) return '🔥';
    if (d >= 3) return '⚡';
    if (d >= 1) return '✨';
    return '💤';
  }
}

// --- streaks → current ---
class StreakCurrent {
  final int days; // current streak length in days
  final bool isActive; // true if streak is still going
  final DateTime? startedDate; // when the current streak started
  final DateTime? lastActiveDate; // last day activity was logged

  const StreakCurrent({
    this.days = 0,
    this.isActive = false,
    this.startedDate,
    this.lastActiveDate,
  });

  factory StreakCurrent.empty() => const StreakCurrent();

  factory StreakCurrent.fromJson(Map<String, dynamic> j) => StreakCurrent(
    days: _int(j['days']),
    isActive: j['is_active'] == true,
    startedDate: _dt(j['started_date']),
    lastActiveDate: _dt(j['last_active_date']),
  );

  Map<String, dynamic> toJson() => {
    'days': days,
    'is_active': isActive,
    'started_date': startedDate?.toIso8601String(),
    'last_active_date': lastActiveDate?.toIso8601String(),
  };
}

// --- streaks → longest ---
class StreakLongest {
  final int days;
  final DateTime? startedDate;
  final DateTime? endedDate;

  const StreakLongest({this.days = 0, this.startedDate, this.endedDate});

  factory StreakLongest.empty() => const StreakLongest();

  factory StreakLongest.fromJson(Map<String, dynamic> j) => StreakLongest(
    days: _int(j['days']),
    startedDate: _dt(j['started_date']),
    endedDate: _dt(j['ended_date']),
  );

  Map<String, dynamic> toJson() => {
    'days': days,
    'started_date': startedDate?.toIso8601String(),
    'ended_date': endedDate?.toIso8601String(),
  };
}

// --- streaks → next_milestone ---
class StreakNextMilestone {
  final int target; // target number of days
  final int daysRemaining; // days left to reach the target
  final double progressPercent; // % progress towards this milestone

  const StreakNextMilestone({
    this.target = 0,
    this.daysRemaining = 0,
    this.progressPercent = 0,
  });

  factory StreakNextMilestone.empty() => const StreakNextMilestone();

  factory StreakNextMilestone.fromJson(Map<String, dynamic> j) =>
      StreakNextMilestone(
        target: _int(j['target']),
        daysRemaining: _int(j['days_remaining']),
        progressPercent: _dbl(j['progress_percent']),
      );

  Map<String, dynamic> toJson() => {
    'target': target,
    'days_remaining': daysRemaining,
    'progress_percent': progressPercent,
  };
}

// --- streaks → risk ---
class StreakRisk {
  final bool isAtRisk; // true if streak may break today
  final int? hoursUntilBreak; // hours until streak breaks (null if not at risk)
  final DateTime? lastActivityDate; // last day activity was logged

  const StreakRisk({
    this.isAtRisk = false,
    this.hoursUntilBreak,
    this.lastActivityDate,
  });

  factory StreakRisk.empty() => const StreakRisk();

  factory StreakRisk.fromJson(Map<String, dynamic> j) => StreakRisk(
    isAtRisk: j['is_at_risk'] == true,
    hoursUntilBreak: (j['hours_until_break'] as num?)?.toInt(),
    lastActivityDate: _dt(j['last_activity_date']),
  );

  Map<String, dynamic> toJson() => {
    'is_at_risk': isAtRisk,
    'hours_until_break': hoursUntilBreak,
    'last_activity_date': lastActivityDate?.toIso8601String(),
  };
}

// --- streaks → history ---
class StreakHistory {
  // 30-day calendar: {"2024-01-15": true, "2024-01-14": false, ...}
  final Map<String, bool> calendar30Days;

  // List of days where the streak was broken
  final List<StreakBreak> breaksInLast90Days;

  const StreakHistory({
    this.calendar30Days = const {},
    this.breaksInLast90Days = const [],
  });

  factory StreakHistory.empty() => const StreakHistory();

  factory StreakHistory.fromJson(Map<String, dynamic> j) {
    final Map<String, bool> cal = {};
    final rawCal = j['calendar_30_days'];
    if (rawCal is Map) rawCal.forEach((k, v) => cal[k.toString()] = v == true);
    return StreakHistory(
      calendar30Days: cal,
      breaksInLast90Days: _parseJsonbList(
        j['breaks_in_last_90_days'],
      ).map(StreakBreak.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calendar_30_days': calendar30Days,
    'breaks_in_last_90_days': breaksInLast90Days
        .map((e) => e.toJson())
        .toList(),
  };

  // Check if a specific date had activity
  bool wasActiveOn(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return calendar30Days[key] == true;
  }
}

// --- streaks → history → breaks_in_last_90_days item ---
class StreakBreak {
  final DateTime date;
  final String reason; // e.g. "no_activity"

  const StreakBreak({required this.date, required this.reason});

  factory StreakBreak.fromJson(Map<String, dynamic> j) => StreakBreak(
    date: _dt(j['date']) ?? DateTime.now(),
    reason: j['reason'] as String? ?? 'no_activity',
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'reason': reason,
  };
}

// --- streaks → stats ---
class StreakStats {
  final int totalActiveDaysAllTime; // total days with any activity ever
  final double averageStreak; // average streak length across all streaks
  final String mostCommonBreakDay; // e.g. "Monday"

  const StreakStats({
    this.totalActiveDaysAllTime = 0,
    this.averageStreak = 0,
    this.mostCommonBreakDay = '',
  });

  factory StreakStats.empty() => const StreakStats();

  factory StreakStats.fromJson(Map<String, dynamic> j) => StreakStats(
    totalActiveDaysAllTime: _int(j['total_active_days_all_time']),
    averageStreak: _dbl(j['average_streak']),
    mostCommonBreakDay: j['most_common_break_day'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'total_active_days_all_time': totalActiveDaysAllTime,
    'average_streak': averageStreak,
    'most_common_break_day': mostCommonBreakDay,
  };
}

// ================================================================
// DB COLUMN: recent_activity
// ================================================================

class RecentActivityItem {
  final String id; // source record id
  final String
  type; // source type: "day task" / "weekly task" / "bucket" / "diary" / "long goal"
  final String
  action; // what happened: "task_completed" / "reward_earned" / "diary_created" / "goal_created" / "goal_completed"
  final String category; // category_type of the source
  final String? subTypes; // sub_types of the source (if any)
  final String message; // human-readable description
  final int points; // points associated with this activity
  final bool isMilestone; // true for special achievements
  final DateTime createdAt; // when this activity happened

  const RecentActivityItem({
    required this.id,
    required this.type,
    required this.action,
    required this.category,
    this.subTypes,
    required this.message,
    this.points = 0,
    this.isMilestone = false,
    required this.createdAt,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> j) =>
      RecentActivityItem(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? '',
        action: j['action'] as String? ?? '',
        category: j['category'] as String? ?? '',
        subTypes: j['sub_types'] as String?,
        message: j['message'] as String? ?? '',
        points: _int(j['points']),
        isMilestone: j['is_milestone'] == true,
        createdAt: _dt(j['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'action': action,
    'category': category,
    'sub_types': subTypes,
    'message': message,
    'points': points,
    'is_milestone': isMilestone,
    'created_at': createdAt.toIso8601String(),
  };

  // Time display helpers
  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}';
  }

  String get groupLabel {
    final d = DateTime.now().difference(createdAt);
    if (d.inDays == 0) return 'Today';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return 'This Week';
    return 'Earlier';
  }

  String get pointsLabel => points > 0 ? '+$points pts' : '';
  bool get hasPoints => points > 0;

  // Icon based on action type
  IconData get actionIcon {
    switch (action) {
      case 'task_completed':
        return Icons.check_circle_rounded;
      case 'reward_earned':
        return Icons.emoji_events_rounded;
      case 'diary_created':
        return Icons.book_rounded;
      case 'goal_created':
        return Icons.flag_rounded;
      case 'goal_completed':
        return Icons.celebration_rounded;
      default:
        return Icons.fiber_manual_record_rounded;
    }
  }

  // Color based on action type
  Color get actionColor {
    switch (action) {
      case 'task_completed':
        return const Color(0xFF10B981);
      case 'reward_earned':
        return const Color(0xFFF59E0B);
      case 'diary_created':
        return const Color(0xFF8B5CF6);
      case 'goal_created':
        return const Color(0xFF3B82F6);
      case 'goal_completed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

// ================================================================
// ACTIVITY GROUP HELPER
// Groups RecentActivityItem list by date label (Today/Yesterday/etc.)
// ================================================================

class ActivityGroup {
  final String label;
  final List<RecentActivityItem> items;

  const ActivityGroup({required this.label, required this.items});

  static List<ActivityGroup> groupByDate(List<RecentActivityItem> items) {
    final Map<String, List<RecentActivityItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.groupLabel, () => []).add(item);
    }
    const order = ['Today', 'Yesterday', 'This Week', 'Earlier'];
    return order
        .where((l) => grouped.containsKey(l))
        .map((l) => ActivityGroup(label: l, items: grouped[l]!))
        .toList();
  }
}

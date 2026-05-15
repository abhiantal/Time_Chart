// ================================================================
// FILE: lib/features/analytics/leaderboard/models/leaderboard_model.dart
//
// Model for a single leaderboard entry.
// Data comes from performance_analytics.overview.summary (live Supabase).
// Rank reward is calculated client-side via RewardManager.forGlobalRank().
// ================================================================

import 'package:flutter/material.dart';
import '../../../../reward_tags/reward_manager.dart';
import '../../../../helpers/card_color_helper.dart';

// ── Private parse helpers ────────────────────────────────────────

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
double _dbl(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

Map<String, dynamic> _map(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}

// ================================================================
// LEADERBOARD ENTRY
// One row per user, sorted by totalPoints descending.
// All DashboardSummary fields are read from:
//   performance_analytics → overview → summary
// ================================================================

class LeaderboardEntry {
  // ── Identity ─────────────────────────────────────────────────
  final String id;      // performance_analytics.id
  final String userId;  // performance_analytics.user_id

  // ── Profile ──────────────────────────────────────────────────
  final String username;
  final String? displayName;
  final String? avatarUrl;

  // ── DashboardSummary fields ───────────────────────────────────
  final int globalRank;            // 1-indexed position in this leaderboard
  final int pointsToday;
  final int totalPoints;           // primary sort key
  final int totalRewards;
  final double averageRating;
  final int currentStreak;
  final int longestStreak;
  final int averageProgress;
  final int pointsThisWeek;
  final String bestTierAchieved;
  final double completionRateAll;
  final double completionRateWeek;
  final double completionRateToday;
  final int dailyTasksPoints;
  final int weeklyTasksPoints;
  final int longGoalsPoints;
  final int bucketListPoints;

  // ── Rewards (personal to the user) ──────────────────────────
  final List<RewardPackage> rewards;

  // ── Rank reward (client-side via RewardManager.forGlobalRank) ─
  final RewardPackage rankReward;

  // ── Timestamp ────────────────────────────────────────────────
  final DateTime updatedAt;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    this.username = '',
    this.displayName,
    this.avatarUrl,
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
    this.rewards = const [],
    required this.rankReward,
    required this.updatedAt,
  });

  // ── Factory: parse one raw Supabase row ───────────────────────
  // [row]               row from performance_analytics
  //                     (overview must already be decoded to a Map)
  // [rank]              1-indexed position after sorting by totalPoints
  // [totalParticipants] total users in this leaderboard fetch
  factory LeaderboardEntry.fromRow(
      Map<String, dynamic> row, {
        String username = '',
        String? displayName,
        String? avatarUrl,
        required int rank,
        required int totalParticipants,
      }) {
    final summary = _map(_map(row['overview'])['summary']);

    // Support both current and legacy summary key names
    final dtPts = _int(summary['daily_tasks_points']  ?? summary['total_day_tasks_points']);
    final wtPts = _int(summary['weekly_tasks_points'] ?? summary['total_week_tasks_points']);
    final lgPts = _int(summary['long_goals_points']   ?? summary['total_long_goals_points']);
    final blPts = _int(summary['bucket_list_points']  ?? summary['total_bucket_points']);

    // Calculate rank reward client-side
    final rankReward = RewardManager.forGlobalRank(
      globalRank:        rank,
      totalParticipants: totalParticipants,
      isVerified:        true,
    );

    // Parse personal rewards (unlocked_rewards)
    final List<RewardPackage> rewards = [];
    final rewardsRaw = _map(row['rewards'])['unlocked_rewards'];
    if (rewardsRaw is List) {
      for (final r in rewardsRaw) {
        try {
          rewards.add(RewardPackage.fromJson(_map(r)));
        } catch (_) {}
      }
    }

    return LeaderboardEntry(
      id:                  row['id'] as String? ?? '',
      userId:              row['user_id'] as String? ?? '',
      username:            username,
      displayName:         displayName,
      avatarUrl:           avatarUrl,
      globalRank:          rank,
      pointsToday:         _int(summary['points_today']),
      totalPoints:         _int(summary['total_points']),
      totalRewards:        _int(summary['total_rewards']),
      averageRating:       _dbl(summary['average_rating']),
      currentStreak:       _int(summary['current_streak']),
      longestStreak:       _int(summary['longest_streak']),
      averageProgress:     _int(summary['average_progress']),
      pointsThisWeek:      _int(summary['points_this_week']),
      bestTierAchieved:    summary['best_tier_achieved'] as String? ?? 'none',
      completionRateAll:   _dbl(summary['completion_rate_all']),
      completionRateWeek:  _dbl(summary['completion_rate_week']),
      completionRateToday: _dbl(summary['completion_rate_today']),
      dailyTasksPoints:    dtPts,
      weeklyTasksPoints:   wtPts,
      longGoalsPoints:     lgPts,
      bucketListPoints:    blPts,
      rewards:             rewards,
      rankReward:          rankReward,
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── copyWith ──────────────────────────────────────────────────
  LeaderboardEntry copyWith({
    int? globalRank,
    RewardPackage? rankReward,
  }) => LeaderboardEntry(
    id:                  id,
    userId:              userId,
    username:            username,
    displayName:         displayName,
    avatarUrl:           avatarUrl,
    globalRank:          globalRank  ?? this.globalRank,
    pointsToday:         pointsToday,
    totalPoints:         totalPoints,
    totalRewards:        totalRewards,
    averageRating:       averageRating,
    currentStreak:       currentStreak,
    longestStreak:       longestStreak,
    averageProgress:     averageProgress,
    pointsThisWeek:      pointsThisWeek,
    bestTierAchieved:    bestTierAchieved,
    completionRateAll:   completionRateAll,
    completionRateWeek:  completionRateWeek,
    completionRateToday: completionRateToday,
    dailyTasksPoints:    dailyTasksPoints,
    weeklyTasksPoints:   weeklyTasksPoints,
    longGoalsPoints:     longGoalsPoints,
    bucketListPoints:    bucketListPoints,
    rewards:             rewards,
    rankReward:          rankReward ?? this.rankReward,
    updatedAt:           updatedAt,
  );

  // ── Display helpers ───────────────────────────────────────────

  /// Best available display name
  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (username.isNotEmpty) return username;
    return 'User ${userId.length >= 6 ? userId.substring(0, 6) : userId}';
  }

  /// Two-letter avatar initials
  String get initials {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'[_\s]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Medal emoji for top 3, numeric label for rest
  String get rankLabel {
    switch (globalRank) {
      case 0:  return '–';
      case 1:  return '🥇';
      case 2:  return '🥈';
      case 3:  return '🥉';
      default: return '#$globalRank';
    }
  }

  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7)  return '🔥';
    if (currentStreak >= 3)  return '⚡';
    if (currentStreak >= 1)  return '✨';
    return '💤';
  }

  Color  get bestTierColor => CardColorHelper.getTierColor(bestTierAchieved);
  String get bestTierEmoji => CardColorHelper.getTierEmoji(bestTierAchieved);

  String get ratingLabel     => '${averageRating.toStringAsFixed(1)}★';
  String get completionLabel => '${completionRateAll.toStringAsFixed(1)}%';
  String get pointsLabel     => '$totalPoints pts';
}
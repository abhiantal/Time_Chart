// lib/reward_tags/reward_manager.dart
//
// Central calculation engine for all reward types.
// Produces RewardPackage — the single model shared across the app.
// JSON keys match the backend contract exactly.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'reward_enums.dart';
import 'reward_config.dart';
import 'animated_reward_emoji.dart';

export 'reward_enums.dart';
export 'reward_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REWARD PACKAGE  (the single model that travels everywhere)
// ─────────────────────────────────────────────────────────────────────────────

class RewardPackage {
  final bool earned;
  final RewardTier tier;

  /// Hex colour string e.g. "#3B82F6"  — null when not earned.
  final String? rewardColor;

  final String tagName;
  final String tagReason;
  final int points;
  final RewardSource source;
  final String suggestion;
  final DateTime calculatedAt;

  const RewardPackage({
    required this.earned,
    required this.tier,
    this.rewardColor,
    required this.tagName,
    required this.tagReason,
    required this.points,
    required this.source,
    required this.suggestion,
    required this.calculatedAt,
  });

  // ── Derived helpers ──────────────────────────────────────────────────────

  int get tierLevel => tier.level;

  String get rewardDisplayName => RewardTextEngine.rewardDisplayName(tier);

  RewardColor? get rewardColorEnum {
    if (!earned) return null;
    return kTierRegistry[tier]?.color;
  }

  /// The [Color] object corresponding to [rewardColor].
  Color get primaryColor {
    final meta = kTierRegistry[tier];
    if (meta == null) return const Color(0xFF9E9E9E);
    return Color(meta.color.argb);
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  /// Full JSON — matches backend contract.
  Map<String, dynamic> toJson() => {
    'earned': earned,
    'tier': tier.name,
    'tierLevel': tierLevel,
    'rewardColor': rewardColor,
    'tagName': tagName,
    'tagReason': tagReason,
    'points': points,
    'source': source.name,
    'suggestion': suggestion,
    'calculatedAt': calculatedAt.toIso8601String(),
  };

  factory RewardPackage.fromJson(Map<String, dynamic> json) {
    // Support both old tier names (blueGem → spark) and new names.
    RewardTier parseTier(String raw) {
      const legacyMap = {
        'spark': 'spark',
        'flame': 'flame',
        'ember': 'ember',
        'blaze': 'blaze',
        'crystal': 'crystal',
        'prism': 'prism',
        'radiant': 'radiant',
        'nova': 'nova',
      };
      final mapped = legacyMap[raw] ?? raw;
      return RewardTier.values.firstWhere(
            (t) => t.name == mapped,
        orElse: () => RewardTier.none,
      );
    }

    final tier = parseTier(json['tier'] as String? ?? 'none');

    // rewardColor may be a hex string "#3B82F6" or an old enum name "blue"
    String? colorHex = json['rewardColor'] as String?;
    if (colorHex != null && !colorHex.startsWith('#')) {
      // convert legacy enum name to hex
      final legacyColorMap = {
        'blue': '#3B82F6',
        'silver': '#94A3B8',
        'green': '#10B981',
        'red': '#EF4444',
        'gold': '#FFD700',
        'purple': '#A855F7',
        'cyan': '#06B6D4',
      };
      colorHex = legacyColorMap[colorHex];
    }

    return RewardPackage(
      earned: json['earned'] as bool? ?? false,
      tier: tier,
      rewardColor: colorHex,
      tagName: json['tagName'] as String? ?? '',
      tagReason: json['tagReason'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      source: RewardSource.values.firstWhere(
            (s) => s.name == (json['source'] as String? ?? ''),
        orElse: () => RewardSource.dayTask,
      ),
      suggestion: json['suggestion'] as String? ?? '',
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : DateTime.now().toUtc(),
    );
  }

  /// Slim model JSON used by AI/recommendation endpoints.
  Map<String, dynamic> toModelJson() => {
    'earned': earned,
    'tier': tier.name,
    'tier_level': tierLevel,
    'tag_name': tagName,
    'tag_reason': tagReason,
    'reward_color': rewardColor,
    'points': points,
    'earned_at': calculatedAt.toIso8601String(),
  };

  factory RewardPackage.empty({
    required RewardSource source,
    required String reason,
  }) => RewardPackage(
    earned: false,
    tier: RewardTier.none,
    tagName: '',
    tagReason: reason,
    points: 0,
    source: source,
    suggestion: reason,
    calculatedAt: DateTime.now().toUtc(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARD MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class RewardManager {
  RewardManager._();

  static RewardTier parseTier(String? raw) {
    if (raw == null) return RewardTier.none;
    const legacyMap = {
      'spark': 'spark',
      'flame': 'flame',
      'ember': 'ember',
      'blaze': 'blaze',
      'crystal': 'crystal',
      'prism': 'prism',
      'radiant': 'radiant',
      'nova': 'nova',
    };
    final mapped = legacyMap[raw.toLowerCase()] ?? raw.toLowerCase();
    return RewardTier.values.firstWhere(
          (t) => t.name == mapped,
      orElse: () => RewardTier.none,
    );
  }

  // ── Universal calculation ────────────────────────────────────────────────

  static RewardPackage calculate({
    required double progress,
    required double rating,
    required int pointsEarned,
    required int completedDays,
    required int totalDays,
    required int hoursPerDay,
    required int taskStack,
    required RewardSource source,
    required bool onTimeCompletion,
    double? consistencyOverride,
  }) {
    final tier = _calculateTier(
      progress: progress,
      rating: rating,
      pointsEarned: pointsEarned,
      completedDays: completedDays,
      totalDays: totalDays,
      hoursPerDay: hoursPerDay,
      taskStack: taskStack,
      onTimeCompletion: onTimeCompletion,
      consistencyOverride: consistencyOverride,
    );

    final reason = RewardTextEngine.tagReason(
      tier: tier,
      source: source,
      progress: progress,
      rating: rating,
      completedDays: completedDays,
      hoursPerDay: hoursPerDay,
      taskStack: taskStack,
    );

    final suggest = RewardTextEngine.suggestion(
      tier: tier,
      source: source,
      progress: progress.round(),
      rating: rating,
      completed: completedDays,
      missed: totalDays - completedDays,
    );

    if (tier == RewardTier.none) {
      return RewardPackage(
        earned: false,
        tier: RewardTier.none,
        tagName: '',
        tagReason: reason,
        points: 0,
        source: source,
        suggestion: suggest,
        calculatedAt: DateTime.now().toUtc(),
      );
    }

    final meta = kTierRegistry[tier]!;
    return RewardPackage(
      earned: true,
      tier: tier,
      rewardColor: meta.color.hexCode,
      tagName: meta.tagName,
      tagReason: reason,
      points: meta.points,
      source: source,
      suggestion: suggest,
      calculatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Tier calculation logic ───────────────────────────────────────────────

  static RewardTier _calculateTier({
    required double progress,
    required double rating,
    required int pointsEarned,
    required int completedDays,
    required int totalDays,
    required int hoursPerDay,
    required int taskStack,
    required bool onTimeCompletion,
    double? consistencyOverride,
  }) {
    if (progress < 60.0 || rating < 2.0) return RewardTier.none;

    final consistency =
        consistencyOverride ??
            (totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0);

    // Tier 8 — Nova
    if (progress >= 99.0 &&
        rating >= 4.9 &&
        pointsEarned >= 95 &&
        completedDays >= 60 &&
        consistency >= 98.0 &&
        (hoursPerDay >= 5 || hoursPerDay == 0) &&
        onTimeCompletion) {
      return RewardTier.nova;
    }
    // Tier 7 — Radiant
    if (progress >= 97.0 &&
        rating >= 4.7 &&
        pointsEarned >= 85 &&
        completedDays >= 45 &&
        consistency >= 95.0 &&
        (hoursPerDay >= 4 || hoursPerDay == 0) &&
        onTimeCompletion) {
      return RewardTier.radiant;
    }
    // Tier 6 — Prism
    if (progress >= 95.0 &&
        rating >= 4.5 &&
        pointsEarned >= 75 &&
        completedDays >= 30 &&
        consistency >= 90.0 &&
        (hoursPerDay >= 3 || hoursPerDay == 0)) {
      return RewardTier.prism;
    }
    // Tier 5 — Crystal
    if (progress >= 92.0 &&
        rating >= 4.2 &&
        pointsEarned >= 60 &&
        completedDays >= 21 &&
        consistency >= 85.0) {
      return RewardTier.crystal;
    }
    // Tier 4 — Blaze
    if (progress >= 88.0 &&
        rating >= 4.0 &&
        pointsEarned >= 45 &&
        (taskStack >= 3 || completedDays >= 14)) {
      return RewardTier.blaze;
    }
    // Tier 3 — Ember
    if (progress >= 80.0 &&
        rating >= 3.5 &&
        pointsEarned >= 30 &&
        consistency >= 70.0) {
      return RewardTier.ember;
    }
    // Tier 2 — Flame
    if (progress >= 70.0 &&
        rating >= 3.0 &&
        pointsEarned >= 20 &&
        completedDays >= 3) {
      return RewardTier.flame;
    }
    // Tier 1 — Spark
    if (progress >= 60.0 && rating >= 2.0) {
      return RewardTier.spark;
    }

    return RewardTier.none;
  }

  // ── Source-specific factory helpers ─────────────────────────────────────

  static RewardPackage forDayTask({
    required int feedbackCount,
    required bool hasText,
    required bool isComplete,
    required bool isOverdue,
    required int timelineHours,
  }) {
    final points = (feedbackCount * 5) + (hasText ? 10 : 0);

    int progress = 0;
    if (feedbackCount > 0) {
      progress = 50 + (feedbackCount * 8).clamp(0, 40);
      if (hasText) progress += 10;
    }

    // Adaptive penalty: harsher if less progress was made
    final penaltyMultiplier = 1.0 - (progress / 100).clamp(0.0, 1.0);
    final penalty = !isComplete ? (penaltyMultiplier * 50).round() : 0;
    final net = (points - penalty).clamp(0, 100);

    // Adaptive progress reduction: scales with the penalty
    if (penalty > 0) {
      final reductionFactor = 1.0 - (penalty / 100).clamp(0.0, 0.5);
      progress = (progress * reductionFactor).round();
    }
    progress = progress.clamp(0, 100);

    return calculate(
      progress: progress.toDouble(),
      rating: (1.0 + 4.0 * (progress / 100)).clamp(1.0, 5.0),
      pointsEarned: net,
      completedDays: isComplete ? 1 : 0,
      totalDays: 1,
      hoursPerDay: timelineHours,
      taskStack: 0,
      source: RewardSource.dayTask,
      onTimeCompletion: !isOverdue,
    );
  }

  static RewardPackage forWeekTaskDay({
    required List<dynamic> feedbacks,
    required String? finalText,
    required bool isComplete,
  }) {
    final mediaPoints = feedbacks.length * 5;
    final textPoints = (finalText != null && finalText.isNotEmpty) ? 10 : 0;
    final total = mediaPoints + textPoints;
    final penalty = (!isComplete && feedbacks.isEmpty) ? 50 : 0;
    final net = (total - penalty).clamp(0, 1000);

    int progress = 0;
    if (feedbacks.isNotEmpty) {
      progress = 50 + (feedbacks.length * 8).clamp(0, 40);
      if (textPoints > 0) progress += 10;
    }
    if (penalty > 0) progress = (progress * 0.5).round();
    progress = progress.clamp(0, 100);

    return calculate(
      progress: progress.toDouble(),
      rating: (1.0 + 4.0 * (progress / 100)).clamp(1.0, 5.0),
      pointsEarned: net,
      completedDays: isComplete ? 1 : 0,
      totalDays: 1,
      hoursPerDay: (feedbacks.length * 20 ~/ 60) + 1,
      taskStack: 0,
      source: RewardSource.weekTask,
      onTimeCompletion: isComplete,
    );
  }

  static RewardPackage forWeekTaskSummary({
    required List<dynamic> dailyProgress,
    required int totalScheduledDays,
    required int taskStack,
    required bool isOverdue,
  }) {
    if (dailyProgress.isEmpty) {
      return RewardPackage.empty(
        source: RewardSource.weekTask,
        reason: 'Complete at least one day to earn rewards',
      );
    }

    int totalPoints = 0, totalProgressSum = 0, completed = 0, totalHours = 0;
    double totalRatingSum = 0;

    for (final day in dailyProgress) {
      final m = day.metrics;
      totalPoints += m.pointsEarned as int;
      totalProgressSum += m.progress as int;
      totalRatingSum += (m.rating as num).toDouble();
      if (day.isComplete as bool) {
        completed++;
        totalHours += (((day.feedbacks as List).length * 20) ~/ 60) + 1;
      }
    }

    // Only average across days that have either been completed or have activity
    // This prevents future empty days from skewing the weekly average downwards
    final activeDaysCount = dailyProgress.where((day) {
      final p = (day.metrics.progress as num?)?.toInt() ?? 0;
      final f = (day.feedbacks as List?)?.length ?? 0;
      return p > 0 || f > 0 || (day.isComplete as bool? ?? false);
    }).length;

    final divisor = activeDaysCount > 0 ? activeDaysCount : 1;

    final avgProgress = (totalProgressSum / divisor).round();
    final avgRating = totalRatingSum / divisor;
    final avgHours = completed > 0 ? totalHours ~/ completed : 0;

    return calculate(
      progress: avgProgress.toDouble(),
      rating: avgRating,
      pointsEarned: totalPoints,
      completedDays: completed,
      totalDays: totalScheduledDays,
      hoursPerDay: avgHours,
      taskStack: taskStack,
      source: RewardSource.weekTask,
      onTimeCompletion: !isOverdue,
      consistencyOverride: (completed / divisor) * 100,
    );
  }

  static RewardPackage forLongGoal({
    required List<dynamic> goalLog,
    required int completedWeeks,
    required int totalWeeks,
    required int hoursPerDay,
    required bool isCompleted,
  }) {
    int points = 0;
    for (final week in goalLog) {
      final dailyFeedback = week.dailyFeedback as List;
      final byDay = <int, List<dynamic>>{};
      for (final f in dailyFeedback) {
        final day = f.feedbackDay as int;
        byDay.putIfAbsent(day, () => []).add(f);
        final url = f.mediaUrl;
        if (url != null && url.toString().isNotEmpty) points += 5;
      }
      for (final entry in byDay.entries) {
        final last = entry.value.isNotEmpty ? entry.value.last : null;
        if (last != null && last.feedbackText.toString().isNotEmpty)
          points += 10;
      }
    }

    final penalty = goalLog.every((w) => (w.dailyFeedback as List).isEmpty)
        ? 50
        : 0;
    final net = (points - penalty).clamp(0, 100);

    return calculate(
      progress: net.toDouble(),
      rating: (1.0 + 4.0 * (net.toDouble() / 100)).clamp(1.0, 5.0),
      pointsEarned: net,
      completedDays: completedWeeks * 7,
      totalDays: totalWeeks * 7,
      hoursPerDay: hoursPerDay,
      taskStack: completedWeeks,
      source: RewardSource.longGoal,
      onTimeCompletion: isCompleted,
    );
  }

  static RewardPackage forBucket({
    required List<dynamic> checklist,
    required bool isComplete,
    required bool onTime,
  }) {
    final done = checklist.where((c) => c.done as bool).length;
    final total = checklist.isEmpty ? 1 : checklist.length;
    final progress = ((done / total) * 100).round();

    int points = 0;
    for (final item in checklist) {
      if (item.done as bool) points += item.points as int;
    }

    return calculate(
      progress: progress.toDouble(),
      rating: (1.0 + 4.0 * (progress / 100)).clamp(1.0, 5.0),
      pointsEarned: points,
      completedDays: done,
      totalDays: total,
      hoursPerDay: 0,
      taskStack: 0,
      source: RewardSource.bucket,
      onTimeCompletion: onTime,
    );
  }

  static RewardPackage forDiary({
    required double progress,
    required double rating,
    required int pointsEarned,
  }) {
    return calculate(
      progress: progress,
      rating: rating,
      pointsEarned: pointsEarned,
      completedDays: 1,
      totalDays: 1,
      hoursPerDay: 0,
      taskStack: 0,
      source: RewardSource.diary,
      onTimeCompletion: true,
    );
  }

  // ── DASHBOARD REWARDS - FROM SUMMARY ─────────────────────────────────────

  /// Calculate dashboard reward from DashboardSummary metrics.
  ///
  /// This is the primary method for calculating dashboard rewards.
  /// It analyzes overall user performance across all task types.
  ///
  /// Parameters come directly from DashboardSummary JSON:
  /// - globalRank: User's rank (1 = best)
  /// - totalPoints: All-time total points
  /// - totalRewards: Total rewards earned
  /// - averageRating: Average task rating (1-5 scale)
  /// - currentStreak: Current active streak (days)
  /// - longestStreak: All-time longest streak (days)
  /// - averageProgress: Average progress % across tasks
  /// - completionRateAll: All-time completion rate (%)
  /// - completionRateWeek: This week's completion rate (%)
  /// - dailyTasksPoints: Points from daily tasks
  /// - weeklyTasksPoints: Points from weekly tasks
  /// - longGoalsPoints: Points from long goals
  /// - bucketListPoints: Points from bucket items
  static RewardPackage forDashboardSummary({
    required int globalRank,
    required int pointsToday,
    required int totalPoints,
    required int totalRewards,
    required double averageRating,
    required int currentStreak,
    required int longestStreak,
    required int averageProgress,
    required int pointsThisWeek,
    required String bestTierAchieved,
    required double completionRateAll,
    required double completionRateWeek,
    required double completionRateToday,
    required int dailyTasksPoints,
    required int weeklyTasksPoints,
    required int longGoalsPoints,
    required int bucketListPoints,
  }) {
    // ── Calculate composite score ──────────────────────────────────────────

    // 1. Reward count score (0-100)
    // Assuming ~15 total tiers (core + dashboard), scale it
    final rewardScore = (totalRewards / 15 * 100).clamp(0.0, 100.0);

    // 2. Completion score (0-100)
    // Weighted: 40% all-time, 30% this week, 30% today to prioritize recent momentum
    final completionScore = (completionRateAll * 0.4 +
            completionRateWeek * 0.3 +
            completionRateToday * 0.3)
        .clamp(0.0, 100.0);

    // 3. Quality score (0-100)
    // Based on average rating (1-5 scale)
    final qualityScore = (averageRating / 5.0 * 100).clamp(0.0, 100.0);

    // 4. Progress score (0-100)
    // Direct average progress percentage
    final progressScore = averageProgress.toDouble().clamp(0.0, 100.0);

    // 5. Consistency score (0-100)
    // Based on streak achievement with diminishing returns
    late double consistencyScore;
    if (currentStreak >= 30) {
      consistencyScore = 100.0;
    } else if (currentStreak >= 21) {
      consistencyScore = 85.0 + ((currentStreak - 21) / 9 * 15);
    } else if (currentStreak >= 14) {
      consistencyScore = 70.0 + ((currentStreak - 14) / 7 * 15);
    } else if (currentStreak >= 7) {
      consistencyScore = 55.0 + ((currentStreak - 7) / 7 * 15);
    } else if (currentStreak >= 3) {
      consistencyScore = 35.0 + ((currentStreak - 3) / 4 * 20);
    } else if (currentStreak >= 1) {
      consistencyScore = 15.0 + (currentStreak / 2 * 20);
    } else {
      // No active streak, use longest streak history
      consistencyScore = (longestStreak / 30 * 40).clamp(0.0, 40.0);
    }

    // 6. Diversification score (0-100)
    // Check if user is earning rewards across multiple task types
    int taskTypesWithPoints = 0;
    if (dailyTasksPoints > 0) taskTypesWithPoints++;
    if (weeklyTasksPoints > 0) taskTypesWithPoints++;
    if (longGoalsPoints > 0) taskTypesWithPoints++;
    if (bucketListPoints > 0) taskTypesWithPoints++;

    final diversificationScore =
    (taskTypesWithPoints / 4 * 100).clamp(0.0, 100.0);

    // 7. Recent Momentum Bonus (0-20)
    // Based on points earned today and this week
    final todayPointsBonus = (pointsToday / 100 * 10).clamp(0.0, 10.0);
    final weekPointsBonus = (pointsThisWeek / 500 * 10).clamp(0.0, 10.0);
    final momentumBonus = todayPointsBonus + weekPointsBonus;

    // 8. Global rank score (0-30 bonus)
    // Top performers get bonus points
    double rankBonus = 0.0;
    if (globalRank == 1) {
      rankBonus = 30.0;
    } else if (globalRank <= 3) {
      rankBonus = 25.0;
    } else if (globalRank <= 5) {
      rankBonus = 20.0;
    } else if (globalRank <= 10) {
      rankBonus = 15.0;
    } else if (globalRank <= 20) {
      rankBonus = 10.0;
    } else if (globalRank <= 50) {
      rankBonus = 5.0;
    }

    // ── Weighted composite score ───────────────────────────────────────────
    // Weights emphasize consistency and quality over raw points
    final dashboardScore = (rewardScore * 0.15 +
            completionScore * 0.22 +
            qualityScore * 0.20 +
            progressScore * 0.10 +
            consistencyScore * 0.13 +
            diversificationScore * 0.07 +
            momentumBonus +
            rankBonus)
        .clamp(0.0, 140.0);

    // ── Determine tier based on composite score ───────────────────────────

    late RewardTier tier;
    final score = dashboardScore; // alias for readability

    if (score >= 125 &&
        totalRewards >= 8 &&
        averageRating >= 4.5 &&
        currentStreak >= 30 &&
        completionRateAll >= 90 &&
        taskTypesWithPoints >= 4) {
      tier = RewardTier.dashboardApex; // ⚜️ Tier 7 - Absolute pinnacle
    } else if (score >= 115 &&
        totalRewards >= 7 &&
        averageRating >= 4.2 &&
        currentStreak >= 21 &&
        completionRateAll >= 85 &&
        taskTypesWithPoints >= 4) {
      tier = RewardTier.dashboardOmega; // Ω Tier 6 - Transcendent mastery
    } else if (score >= 105 &&
        totalRewards >= 6 &&
        averageRating >= 4.0 &&
        currentStreak >= 14 &&
        completionRateAll >= 80 &&
        taskTypesWithPoints >= 3) {
      tier = RewardTier.dashboardDiamond; // 💎 Tier 5 - Unbreakable brilliance
    } else if (score >= 85 &&
        totalRewards >= 5 &&
        averageRating >= 3.7 &&
        currentStreak >= 10 &&
        completionRateAll >= 75 &&
        taskTypesWithPoints >= 3) {
      tier = RewardTier.dashboardPlatinum; // 🔮 Tier 4 - Enlightened excellence
    } else if (score >= 70 &&
        totalRewards >= 4 &&
        averageRating >= 3.4 &&
        currentStreak >= 7 &&
        completionRateAll >= 70 &&
        taskTypesWithPoints >= 2) {
      tier = RewardTier.dashboardGold; // 🔱 Tier 3 - Golden ascendance
    } else if (score >= 55 &&
        totalRewards >= 3 &&
        averageRating >= 3.0 &&
        currentStreak >= 3 &&
        completionRateAll >= 60 &&
        taskTypesWithPoints >= 2) {
      tier = RewardTier.dashboardSilver; // ☄️ Tier 2 - Silver dedication
    } else if (totalRewards >= 1 &&
        completionRateAll >= 40 &&
        averageRating >= 2.0) {
      tier = RewardTier.dashboardBronze; // 🍀 Tier 1 - Bronze achievement
    } else {
      tier = RewardTier.none;
    }

    // ── Generate reward package ────────────────────────────────────────────

    if (tier == RewardTier.none) {
      return RewardPackage(
        earned: false,
        tier: RewardTier.none,
        rewardColor: null,
        tagName: '',
        tagReason:
        'Complete tasks and earn rewards to unlock your first Dashboard Bronze! '
            'You need: 1+ reward, 40%+ completion rate, and 2.0★+ average rating.',
        points: 0,
        source: RewardSource.dashboard,
        suggestion:
        '🎯 Complete more tasks and focus on quality to earn your first dashboard reward!',
        calculatedAt: DateTime.now().toUtc(),
      );
    }

    final meta = kTierRegistry[tier]!;

    // ── Build detailed reason message ──────────────────────────────────────

    final reason = _buildDashboardReasonMessage(
      tier: tier,
      totalRewards: totalRewards,
      completionRate: completionRateAll,
      averageRating: averageRating,
      currentStreak: currentStreak,
      totalPoints: totalPoints,
      dashboardScore: dashboardScore,
      globalRank: globalRank,
    );

    final suggestion = _buildDashboardSuggestion(
      tier: tier,
      currentScore: dashboardScore,
        missingMetrics: _identifyMissingMetrics(
          tier: tier,
          totalRewards: totalRewards,
          averageRating: averageRating,
          currentStreak: currentStreak,
          taskTypesWithPoints: taskTypesWithPoints,
          completionRateAll: completionRateAll,
          pointsToday: pointsToday,
          pointsThisWeek: pointsThisWeek,
          completionRateToday: completionRateToday,
        ),
    );

    return RewardPackage(
      earned: true,
      tier: tier,
      rewardColor: meta.color.hexCode,
      tagName: meta.tagName,
      tagReason: reason,
      points: meta.points,
      source: RewardSource.dashboard,
      suggestion: suggestion,
      calculatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Helper: Build detailed dashboard reason message ─────────────────────

  static String _buildDashboardReasonMessage({
    required RewardTier tier,
    required int totalRewards,
    required double completionRate,
    required double averageRating,
    required int currentStreak,
    required int totalPoints,
    required double dashboardScore,
    required int globalRank,
  }) {
    final emoji = kTierRegistry[tier]?.emoji ?? '✨';
    final tagName = kTierRegistry[tier]?.tagName ?? 'Unknown';
    final completion = completionRate.toStringAsFixed(1);
    final rating = averageRating.toStringAsFixed(1);
    final score = dashboardScore.toStringAsFixed(0);
    final rankStr = globalRank == 1 ? '#1 GLOBALLY 🌍' : 'Rank #$globalRank';

    switch (tier) {
      case RewardTier.dashboardApex:
        return '$emoji $tagName — The ultimate achievement! '
            'You\'ve unlocked $totalRewards rewards with $rating★ quality, $completion% completion, '
            'and $currentStreak-day streak. $rankStr. You are legendary!';

      case RewardTier.dashboardOmega:
        return '$emoji $tagName — Transcendent mastery! '
            '$totalRewards rewards earned with $rating★ rating, $completion% completion, '
            'and $currentStreak-day streak. Beyond excellence!';

      case RewardTier.dashboardDiamond:
        return '$emoji $tagName — Unbreakable brilliance! '
            '$totalRewards+ rewards achieved with $rating★ quality and $completion% completion. '
            'You\'ve reached timeless mastery!';

      case RewardTier.dashboardPlatinum:
        return '$emoji $tagName — Enlightened excellence! '
            '$totalRewards rewards unlocked with $rating★ rating and $completion% completion. '
            'You\'ve transcended with a $currentStreak-day streak!';

      case RewardTier.dashboardGold:
        return '$emoji $tagName — Golden ascendance! '
            '$totalRewards rewards earned with $rating★ quality and $completion% completion. '
            'Rising to glory at $score/100 performance!';

      case RewardTier.dashboardSilver:
        return '$emoji $tagName — Silver dedication! '
            '$totalRewards rewards unlocked with $rating★ rating and $completion% completion. '
            'Vigilance recognized at $score/100!';

      case RewardTier.dashboardBronze:
        return '$emoji $tagName — Bronze achievement! '
            'Your first $totalRewards reward(s) unlocked! '
            'Your journey begins with $completion% completion and $rating★ quality!';

      default:
        return '$emoji $tagName — Achievement unlocked!';
    }
  }

  // ── Helper: Build dashboard suggestion ──────────────────────────────────

  static String _buildDashboardSuggestion({
    required RewardTier tier,
    required double currentScore,
    required List<String> missingMetrics,
  }) {
    switch (tier) {
      case RewardTier.dashboardApex:
        return '⚜️ APEX ETERNAL! You\'ve reached the absolute pinnacle. You are a legend!';

      case RewardTier.dashboardOmega:
        return 'Ω OMEGA ASCENDANT! Push for Apex Eternal — ${missingMetrics.join(", ")}';

      case RewardTier.dashboardDiamond:
        return '💎 DIAMOND SOVEREIGN! Aim for Omega Ascendant — ${missingMetrics.join(", ")}';

      case RewardTier.dashboardPlatinum:
        return '🔮 PLATINUM ORACLE! Target Diamond Sovereign — ${missingMetrics.join(", ")}';

      case RewardTier.dashboardGold:
        return '🔱 GOLDEN PHOENIX! Push for Platinum Oracle — ${missingMetrics.join(", ")}';

      case RewardTier.dashboardSilver:
        return '☄️ COMET SENTINEL! Reach Gold tier — ${missingMetrics.join(", ")}';

      case RewardTier.dashboardBronze:
        return '🍀 LUCK GUARDIAN! Push for Silver — earn more rewards and stay consistent!';

      default:
        return 'Keep grinding to unlock your next dashboard tier!';
    }
  }

  // ── Helper: Identify missing metrics for next tier ──────────────────────

  static List<String> _identifyMissingMetrics({
    required RewardTier tier,
    required int totalRewards,
    required double averageRating,
    required int currentStreak,
    required int taskTypesWithPoints,
    required double completionRateAll,
    required int pointsToday,
    required int pointsThisWeek,
    required double completionRateToday,
  }) {
    final missing = <String>[];

    final ptsTo100 = 100 - pointsToday;
    final ptsToWeek = 500 - pointsThisWeek;

    switch (tier) {
      case RewardTier.dashboardBronze:
        if (totalRewards < 3) missing.add('${3 - totalRewards} more rewards');
        if (averageRating < 3.0) missing.add('improve rating to 3.0★');
        if (currentStreak < 3) missing.add('${3 - currentStreak} more days');
        if (completionRateAll < 60) missing.add('reach 60% completion');
        if (ptsTo100 > 0) missing.add('earn $ptsTo100 more points today');
        break;

      case RewardTier.dashboardSilver:
        if (totalRewards < 4) missing.add('${4 - totalRewards} more rewards');
        if (averageRating < 3.4) missing.add('improve rating to 3.4★');
        if (currentStreak < 7) missing.add('${7 - currentStreak} more days');
        if (completionRateAll < 70) missing.add('reach 70% completion');
        if (completionRateToday < 80) missing.add('boost today\'s completion');
        break;

      case RewardTier.dashboardGold:
        if (totalRewards < 5) missing.add('${5 - totalRewards} more rewards');
        if (averageRating < 3.7) missing.add('improve rating to 3.7★');
        if (currentStreak < 10) missing.add('${10 - currentStreak} more days');
        if (completionRateAll < 75) missing.add('reach 75% completion');
        if (ptsToWeek > 0) missing.add('earn $ptsToWeek more points this week');
        break;

      case RewardTier.dashboardPlatinum:
        if (totalRewards < 6) missing.add('${6 - totalRewards} more rewards');
        if (averageRating < 4.0) missing.add('improve rating to 4.0★');
        if (currentStreak < 14) missing.add('${14 - currentStreak} more days');
        if (completionRateAll < 80) missing.add('reach 80% completion');
        if (completionRateToday < 90) missing.add('finish all tasks today');
        break;

      case RewardTier.dashboardDiamond:
        if (totalRewards < 7) missing.add('${7 - totalRewards} more rewards');
        if (averageRating < 4.2) missing.add('improve rating to 4.2★');
        if (currentStreak < 21) missing.add('${21 - currentStreak} more days');
        if (completionRateAll < 85) missing.add('reach 85% completion');
        if (ptsToWeek > 100) missing.add('push for massive weekly points');
        break;

      case RewardTier.dashboardOmega:
        if (totalRewards < 8) missing.add('${8 - totalRewards} more rewards');
        if (averageRating < 4.5) missing.add('improve rating to 4.5★');
        if (currentStreak < 30) missing.add('${30 - currentStreak} more days');
        if (completionRateAll < 90) missing.add('reach 90% completion');
        if (completionRateToday < 100) missing.add('maintain perfect daily execution');
        break;

      case RewardTier.dashboardApex:
        missing.add('You\'ve reached the pinnacle!');
        break;

      default:
        break;
    }

    return missing.isEmpty ? ['Keep pushing for greatness!'] : missing;
  }

  // ── GLOBAL RANK REWARDS ──────────────────────────────────────────────────

  /// Calculate global rank reward based on user's position in leaderboard.
  ///
  /// Parameters:
  /// - [globalRank]: User's current rank (1 = best)
  /// - [totalParticipants]: Total number of users in the leaderboard
  /// - [isVerified]: Whether user's rank is verified
  static RewardPackage forGlobalRank({
    required int globalRank,
    required int totalParticipants,
    required bool isVerified,
  }) {
    late RewardTier tier;

    // Global rank tier thresholds (based on top percentile)
    if (globalRank == 1 && isVerified) {
      tier = RewardTier.rankSentinel; // 🦄 Tier 7 - Rank #1
    } else if (globalRank <= 3 && isVerified) {
      tier = RewardTier.rankVanguard; // 🔱 Tier 6 - Top 3
    } else if (globalRank <= 5 && isVerified) {
      tier = RewardTier.rankGodsend; // 💫 Tier 5 - Top 5
    } else if (globalRank <= 10) {
      tier = RewardTier.rankIcon; // 💠 Tier 4 - Top 10
    } else if (globalRank <= 20) {
      tier = RewardTier.rankLegend; // 🐉 Tier 3 - Top 20
    } else if (globalRank <= 50) {
      tier = RewardTier.rankMaster; // 🏹 Tier 2 - Top 50
    } else if (globalRank <= 100) {
      tier = RewardTier.rankElite; // 🐲 Tier 1 - Top 100
    } else {
      tier = RewardTier.none;
    }

    if (tier == RewardTier.none) {
      return RewardPackage.empty(
        source: RewardSource.globalRank,
        reason: 'Climb into the top 100 globally to earn rank rewards!',
      );
    }

    final meta = kTierRegistry[tier]!;

    // Calculate percentile for display
    final percentile =
        ((totalParticipants - globalRank) / totalParticipants) * 100;

    final reason = RewardTextEngine.tagReason(
      tier: tier,
      source: RewardSource.globalRank,
      progress: percentile,
      rating: (percentile / 20).clamp(0.0, 5.0),
      completedDays: totalParticipants - globalRank,
      hoursPerDay: 0,
      taskStack: 0,
      globalRank: globalRank,
    );

    final suggestion = RewardTextEngine.suggestion(
      tier: tier,
      source: RewardSource.globalRank,
      progress: percentile.round(),
      rating: (percentile / 20).clamp(0.0, 5.0),
      completed: globalRank,
      missed: totalParticipants - globalRank,
    );

    return RewardPackage(
      earned: true,
      tier: tier,
      rewardColor: meta.color.hexCode,
      tagName: meta.tagName,
      tagReason: reason,
      points: meta.points,
      source: RewardSource.globalRank,
      suggestion: suggestion,
      calculatedAt: DateTime.now().toUtc(),
    );
  }

  // ── Widget helpers ───────────────────────────────────────────────────────

  static Widget? getRewardWidget(RewardPackage package, {double size = 120}) {
    if (!package.earned) return null;
    return AnimatedRewardEmoji(tier: package.tier, size: size);
  }

  static Widget? getRewardWidgetByTier(RewardTier tier, {double size = 120}) {
    if (tier == RewardTier.none) return null;
    return AnimatedRewardEmoji(tier: tier, size: size);
  }

  // ── Tier info helpers ────────────────────────────────────────────────────

  static Map<String, dynamic> getTierInfo(RewardTier tier) {
    final meta = kTierRegistry[tier];
    if (meta == null) {
      return {
        'name': 'None',
        'tagName': '',
        'emoji': '💪',
        'description': 'Keep pushing!',
        'points': 0,
        'level': 0,
        'color': const Color(0xFF9E9E9E),
        'hexColor': '#9E9E9E',
      };
    }
    return {
      'name': meta.tagName,
      'tagName': meta.tagName,
      'powerWord': meta.powerWord,
      'emoji': meta.emoji,
      'description': meta.description,
      'points': meta.points,
      'level': tier.level,
      'color': Color(meta.color.argb),
      'hexColor': meta.color.hexCode,
      'isDiamond': tier.isDiamond,
      'isDashboard': tier.isDashboard,
      'isRank': tier.isRank,
      'isGem': tier.isGem,
    };
  }

  static List<Map<String, dynamic>> getAllTiers() => RewardTier.values
      .where((t) => t != RewardTier.none)
      .map(getTierInfo)
      .toList();

  /// Get core tiers only (spark to nova)
  static List<Map<String, dynamic>> getCoreTiers() => RewardTier.values
      .where((t) => t != RewardTier.none && !t.isDashboard && !t.isRank)
      .map(getTierInfo)
      .toList();

  /// Get dashboard tiers only
  static List<Map<String, dynamic>> getDashboardTiers() =>
      RewardTier.values.where((t) => t.isDashboard).map(getTierInfo).toList();

  /// Get global rank tiers only
  static List<Map<String, dynamic>> getRankTiers() =>
      RewardTier.values.where((t) => t.isRank).map(getTierInfo).toList();

  static Map<String, dynamic>? getNextTierInfo(RewardTier current) {
    final next = current.level + 1;
    if (next > 22) return null;
    final nextTier = RewardTier.values.firstWhere(
          (t) => t.level == next,
      orElse: () => RewardTier.none,
    );
    if (nextTier == RewardTier.none) return null;
    return getTierInfo(nextTier);
  }

  /// Get next tier for core rewards (within same category)
  static Map<String, dynamic>? getNextCoreTierInfo(RewardTier current) {
    if (!current.isGem && current != RewardTier.spark) return null;

    final coreTiers = RewardTier.values
        .where((t) => !t.isDashboard && !t.isRank && t != RewardTier.none)
        .toList();
    final currentIndex = coreTiers.indexOf(current);

    if (currentIndex < 0 || currentIndex >= coreTiers.length - 1) return null;

    final nextTier = coreTiers[currentIndex + 1];
    return getTierInfo(nextTier);
  }

  /// Get next tier for dashboard rewards
  static Map<String, dynamic>? getNextDashboardTierInfo(RewardTier current) {
    if (!current.isDashboard) return null;

    final dashboardTiers = RewardTier.values
        .where((t) => t.isDashboard)
        .toList();
    final currentIndex = dashboardTiers.indexOf(current);

    if (currentIndex < 0 || currentIndex >= dashboardTiers.length - 1)
      return null;

    final nextTier = dashboardTiers[currentIndex + 1];
    return getTierInfo(nextTier);
  }

  /// Get next tier for global rank rewards
  static Map<String, dynamic>? getNextRankTierInfo(RewardTier current) {
    if (!current.isRank) return null;

    final rankTiers = RewardTier.values.where((t) => t.isRank).toList();
    final currentIndex = rankTiers.indexOf(current);

    if (currentIndex < 0 || currentIndex >= rankTiers.length - 1) return null;

    final nextTier = rankTiers[currentIndex + 1];
    return getTierInfo(nextTier);
  }
}
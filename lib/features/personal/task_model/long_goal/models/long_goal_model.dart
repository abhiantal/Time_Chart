// ================================================================
// FILE: lib/features/long_goal/models/long_goal_model.dart
// FULLY INTEGRATED WITH REWARD MANAGER (8 TIERS) & CARD COLOR HELPER
// ================================================================

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import 'package:intl/intl.dart';

/// Main Long Goal Model with weekly progress tracking
class LongGoalModel {
  final String id;
  final String userId;
  final String title;
  final String? categoryId;
  final String? categoryType;
  final String? subTypes;
  final GoalDescription description;
  final GoalTimeline timeline;
  final Indicators indicators;
  final GoalMetrics metrics;
  final GoalAnalysis analysis;
  final GoalLog goalLog;
  final SocialInfo socialInfo;
  final ShareInfo shareInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LongGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.categoryId,
    this.categoryType,
    this.subTypes,
    required this.description,
    required this.timeline,
    required this.indicators,
    required this.metrics,
    required this.analysis,
    required this.goalLog,
    required this.socialInfo,
    required this.shareInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if a date is scheduled in work schedule
  bool isDateScheduled(DateTime date) {
    // 1. Check if date is within task lifetime
    if (timeline.startDate != null) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final startOnly = DateTime(
        timeline.startDate!.year,
        timeline.startDate!.month,
        timeline.startDate!.day,
      );
      
      if (dateOnly.isBefore(startOnly)) {
        return false;
      }

      if (timeline.endDate != null) {
        final endOnly = DateTime(
          timeline.endDate!.year,
          timeline.endDate!.month,
          timeline.endDate!.day,
        );
        if (dateOnly.isAfter(endOnly)) {
          return false;
        }
      }
    }

    // 2. Check if day of week matches
    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    final shortDayName = dayName.substring(0, 3);

    return timeline.workSchedule.workDays.any((d) {
      final cleanD = d.trim().toLowerCase();
      return cleanD == dayName ||
          cleanD == shortDayName ||
          dayName.startsWith(cleanD);
    });
  }

  /// Get daily progress for a specific date by searching through all weekly logs
  DailyProgress? getProgressForDate(DateTime date) {
    // 1. Group feedback by date to find if this date has any
    for (var week in goalLog.weeklyLogs) {
      for (var f in week.dailyFeedback) {
        if (f.feedbackDay.year == date.year &&
            f.feedbackDay.month == date.month &&
            f.feedbackDay.day == date.day) {
          if (f.dailyProgress != null) return f.dailyProgress;

          final dayFeedbacks = week.dailyFeedback
              .where(
                (df) =>
                    df.feedbackDay.year == date.year &&
                    df.feedbackDay.month == date.month &&
                    df.feedbackDay.day == date.day,
              )
              .toList();

          return DailyProgress.calculateForDay(
            weekId: week.weekId,
            dayFeedbacks: dayFeedbacks,
            hoursPerDay: timeline.workSchedule.hoursPerDay,
          );
        }
      }
    }
    return null;
  }

  /// Get the weekId corresponding to a specific date
  String getWeekIdForDate(DateTime date) {
    if (timeline.startDate == null) {
      if (indicators.weeklyPlans.isNotEmpty) return indicators.weeklyPlans.first.weekId;
      return 'w1';
    }

    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(
      timeline.startDate!.year,
      timeline.startDate!.month,
      timeline.startDate!.day,
    );

    final diffDays = dateOnly.difference(startOnly).inDays;
    if (diffDays < 0) {
      if (indicators.weeklyPlans.isNotEmpty) return indicators.weeklyPlans.first.weekId;
      return 'w1';
    }

    final weekIndex = diffDays ~/ 7;
    if (weekIndex < indicators.weeklyPlans.length) {
      return indicators.weeklyPlans[weekIndex].weekId;
    }

    if (indicators.weeklyPlans.isNotEmpty) return indicators.weeklyPlans.last.weekId;
    return 'w1';
  }

  /// Get all past scheduled dates that are missing real feedback (text or media)
  List<DateTime> getMissedDates() {
    if (timeline.startDate == null) return [];

    final List<DateTime> missed = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start from the beginning of the goal
    DateTime current = DateTime(
      timeline.startDate!.year,
      timeline.startDate!.month,
      timeline.startDate!.day,
    );

    while (current.isBefore(today)) {
      if (isDateScheduled(current)) {
        final weekId = getWeekIdForDate(current);
        final week = goalLog.weeklyLogs.firstWhere(
          (w) => w.weekId == weekId,
          orElse: () => WeeklyGoalLog(weekId: weekId, dailyFeedback: []),
        );

        final dayFeedbacks = week.dailyFeedback.where((f) =>
            f.feedbackDay.year == current.year &&
            f.feedbackDay.month == current.month &&
            f.feedbackDay.day == current.day);

        final hasRealFeedback = dayFeedbacks.any((f) => f.hasMedia || f.hasText);
        if (!hasRealFeedback) {
          missed.add(current);
        }
      }
      current = current.add(const Duration(days: 1));
    }
    return missed;
  }

  /// Legacy getter for backward compatibility
  String get goalId => id;

  // ================================================================
  // FACTORY CONSTRUCTORS
  // ================================================================

  /// Helper to safely parse JSON fields that might be strings or Maps
  static Map<String, dynamic> _parseJsonb(dynamic v) {
    if (v == null) return {};
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

  static dynamic _parseJsonbRaw(dynamic v) {
    if (v == null) return null;
    if (v is Map || v is List) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return jsonDecode(v);
      } catch (_) {}
    }
    return v;
  }


  factory LongGoalModel.fromJson(Map<String, dynamic> json) {
    return LongGoalModel(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? json['categoryId']?.toString(),
      categoryType: json['category_type']?.toString() ?? json['categoryType']?.toString(),
      subTypes: json['sub_types']?.toString() ?? json['subTypes']?.toString(),
      description: GoalDescription.fromJson(_parseJsonb(json['description'])),
      timeline: GoalTimeline.fromJson(_parseJsonb(json['timeline'])),
      indicators: Indicators.fromJson(_parseJsonb(json['indicators'])),
      metrics: GoalMetrics.fromJson(_parseJsonb(json['metrics'])),
      analysis: GoalAnalysis.fromJson(_parseJsonb(json['analysis'])),
      goalLog: GoalLog.fromJson(json['goal_log'] ?? json['goalLog']),
      socialInfo: SocialInfo.fromJson(_parseJsonb(json['social_info'])),
      shareInfo: ShareInfo.fromJson(_parseJsonb(json['share_info'])),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : (json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'category_id': categoryId,
      'category_type': categoryType,
      'sub_types': subTypes,
      'description': description.toJson(),
      'timeline': timeline.toJson(),
      'indicators': indicators.toJson(),
      'metrics': metrics.toJson(),
      'analysis': analysis.toJson(),
      'goal_log': goalLog.toJson(),
      'social_info': socialInfo.toJson(),
      'share_info': shareInfo.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  LongGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? categoryId,
    String? categoryType,
    String? subTypes,
    GoalDescription? description,
    GoalTimeline? timeline,
    Indicators? indicators,
    GoalMetrics? metrics,
    GoalAnalysis? analysis,
    GoalLog? goalLog,
    SocialInfo? socialInfo,
    ShareInfo? shareInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LongGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryType: categoryType ?? this.categoryType,
      subTypes: subTypes ?? this.subTypes,
      description: description ?? this.description,
      timeline: timeline ?? this.timeline,
      indicators: indicators ?? this.indicators,
      metrics: metrics ?? this.metrics,
      analysis: analysis ?? this.analysis,
      goalLog: goalLog ?? this.goalLog,
      socialInfo: socialInfo ?? this.socialInfo,
      shareInfo: shareInfo ?? this.shareInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // ================================================================
  // HELPER GETTERS
  // ================================================================

  /// Check if goal is active (with 1-day grace period)
  bool get isActive {
    if (timeline.startDate == null || timeline.endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(timeline.startDate!.subtract(const Duration(days: 1))) &&
        now.isBefore(timeline.endDate!.add(const Duration(days: 1)));
  }

  /// Check if goal is overdue
  bool get isOverdue {
    if (timeline.endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(timeline.endDate!) && indicators.status != 'completed';
  }

  /// Get total completed weeks
  int get completedWeeks => indicators.weeklyPlans.where((w) => w.isCompleted).length;

  /// Get total weeks
  int get totalWeeks => indicators.weeklyPlans.length;

  /// Get task stack (consecutive weeks completed)
  int get taskStack {
    int stack = 0;
    for (var i = indicators.weeklyPlans.length - 1; i >= 0; i--) {
      if (indicators.weeklyPlans[i].isCompleted) {
        stack++;
      } else {
        break;
      }
    }
    return stack;
  }

  /// Get consistency score (0-100)
  double get consistencyScore => analysis.consistencyScore;

  // ================================================================
  // REWARD MANAGER INTEGRATION - NEW UNIFIED SYSTEM
  // ================================================================

  /// Calculate complete RewardPackage (Tag + Reward together)
  RewardPackage calculateRewardPackage() {
    final eval = evaluateGoal();
    final progress = (eval['progress'] as num).toDouble();
    final rating = (eval['rating'] as num).toDouble();
    final points = (eval['points_earned'] as num).toInt();

    return RewardManager.calculate(
      progress: progress,
      rating: rating,
      pointsEarned: points,
      completedDays: metrics.completedDays,
      totalDays: metrics.totalDays,
      hoursPerDay: timeline.workSchedule.hoursPerDay,
      taskStack: taskStack,
      source: RewardSource.longGoal,
      onTimeCompletion: !isOverdue && indicators.status == 'completed',
      consistencyOverride: eval['consistency_score'] as double?,
    );
  }

  /// Quick check if any reward was earned
  bool get hasEarnedReward => calculateRewardPackage().earned;

  /// Get the reward tier
  RewardTier get rewardTier => calculateRewardPackage().tier;

  // ================================================================
  // CALCULATION METHODS
  // ================================================================

  /// Evaluate the entire goal and return a structured breakdown
  Map<String, dynamic> evaluateGoal({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);

    int totalPointsEarned = 0;
    int totalPenalty = 0;
    int totalFeedbacks = 0;
    int totalMedia = 0;
    int totalWords = 0;
    int passDays = 0;
    
    List<Map<String, dynamic>> dailyBreakdown = [];

    // 1. Iterate through all scheduled days
    if (timeline.startDate != null) {
      DateTime current = DateTime(
        timeline.startDate!.year,
        timeline.startDate!.month,
        timeline.startDate!.day,
      );
      
      final endLimit = timeline.endDate != null && today.isAfter(timeline.endDate!) 
          ? timeline.endDate! 
          : today;

      while (!current.isAfter(endLimit)) {
        if (isDateScheduled(current)) {
          final weekId = getWeekIdForDate(current);
          final week = goalLog.weeklyLogs.firstWhere(
            (w) => w.weekId == weekId,
            orElse: () => WeeklyGoalLog(weekId: weekId, dailyFeedback: []),
          );

          final dayFeedbacks = week.dailyFeedback.where((f) =>
              f.feedbackDay.year == current.year &&
              f.feedbackDay.month == current.month &&
              f.feedbackDay.day == current.day).toList();

          if (dayFeedbacks.isNotEmpty) {
            passDays++;
            
            // Base Calculation for the day
            int dayPoints = 0;
            int dayPenalty = 0;

            // 1) Feedback: count × 5
            dayPoints += dayFeedbacks.length * 5;
            totalFeedbacks += dayFeedbacks.length;

            // 2) Media / Text
            for (var f in dayFeedbacks) {
              if (f.hasMedia) {
                dayPoints += 5;
                totalMedia++;
              }
              if (f.hasText) {
                final words = f.feedbackText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                dayPoints += words * 3;
                totalWords += words;
              }
            }

            // 3) Priority: low=5, medium=10, high=15
            int priorityPoints = 0;
            switch (indicators.priority.toLowerCase()) {
              case 'high': priorityPoints = 15; break;
              case 'medium': priorityPoints = 10; break;
              case 'low': priorityPoints = 5; break;
              default: priorityPoints = 5;
            }
            dayPoints += priorityPoints;

            // 4) On Time: +20 (between starting and ending time)
            // If preferredTimeSlot exists, check if any feedback is within it
            if (timeline.workSchedule.preferredTimeSlot != null) {
              final slot = timeline.workSchedule.preferredTimeSlot!;
              final startTime = DateTime(current.year, current.month, current.day, slot.startingTime.hour, slot.startingTime.minute);
              final endTime = DateTime(current.year, current.month, current.day, slot.endingTime.hour, slot.endingTime.minute);
              
              bool isOnTime = dayFeedbacks.any((f) => 
                (f.feedbackDay.isAtSameMomentAs(startTime) || f.feedbackDay.isAfter(startTime)) && 
                (f.feedbackDay.isAtSameMomentAs(endTime) || f.feedbackDay.isBefore(endTime)));
              
              if (isOnTime) dayPoints += 20;

              // 5) Completion Duration bonus
              final duration = endTime.difference(startTime);
              final d = duration.inMinutes / 60.0;
              int durationBonus = 0;
              if (d < 1) { durationBonus = 5; }
              else if (d < 2) { durationBonus = 10; }
              else if (d < 3) { durationBonus = 15; }
              else if (d < 4) { durationBonus = 20; }
              else if (d < 5) { durationBonus = 30; }
              else if (d < 6) { durationBonus = 40; }
              else if (d < 7) { durationBonus = 50; }
              else if (d < 8) { durationBonus = 70; }
              else if (d < 9) { durationBonus = 80; }
              else { durationBonus = 100; }
              dayPoints += durationBonus;

              // Slot Penalties: Every 20 minutes = 1 feedback slot
              final totalSessionMinutes = duration.inMinutes;
              final totalSlots = (totalSessionMinutes / 20).floor();
              for (int n = 1; n <= totalSlots; n++) {
                final slotEnd = startTime.add(Duration(minutes: n * 20));
                final windowStart = slotEnd.subtract(const Duration(minutes: 2));
                final windowEnd = slotEnd.add(const Duration(minutes: 2));
                
                bool submitted = dayFeedbacks.any((f) => 
                  (f.feedbackDay.isAtSameMomentAs(windowStart) || f.feedbackDay.isAfter(windowStart)) && 
                  (f.feedbackDay.isAtSameMomentAs(windowEnd) || f.feedbackDay.isBefore(windowEnd)));
                
                if (!submitted) dayPenalty += 10;
              }
            }

            totalPointsEarned += dayPoints;
            totalPenalty += dayPenalty;

            dailyBreakdown.add({
              "date": current.toIso8601String(),
              "points": dayPoints,
              "penalty": dayPenalty,
              "feedbackCount": dayFeedbacks.length,
            });
          }
        }
        current = current.add(const Duration(days: 1));
      }
    }

    // 6) Overdue: -10 points per full day (for long goal)
    int overduePenalty = 0;
    if (timeline.endDate != null && currentTime.isAfter(timeline.endDate!)) {
      final diffDays = today.difference(DateTime(timeline.endDate!.year, timeline.endDate!.month, timeline.endDate!.day)).inDays;
      overduePenalty = diffDays * 10;
      totalPenalty += overduePenalty;
    }

    // 7) Missed / Failed: If goal did not have any feedback till end date -> -100
    int missedGoalPenalty = 0;
    if (timeline.endDate != null && currentTime.isAfter(timeline.endDate!) && totalFeedbacks == 0) {
      missedGoalPenalty = 100;
      totalPenalty += missedGoalPenalty;
    }

    final finalScore = totalPointsEarned - totalPenalty;
    final progress = (finalScore / (metrics.totalDays > 0 ? metrics.totalDays * 50 : 100) * 100).clamp(0.0, 100.0);
    final rating = (1.0 + 4.0 * (progress / 100)).clamp(0.0, 5.0);

    // Consistency Score
    double consistency = 0.0;
    if (dailyBreakdown.isNotEmpty) {
      final mean = finalScore / dailyBreakdown.length;
      double variance = 0;
      for (var day in dailyBreakdown) {
        variance += math.pow((day['points'] - day['penalty']) - mean, 2);
      }
      variance /= dailyBreakdown.length;
      final stdDev = math.sqrt(variance);
      consistency = (progress - stdDev).clamp(0.0, 100.0);
    }

    return {
      "status": totalFeedbacks > 0 ? "completed" : (timeline.endDate != null && currentTime.isAfter(timeline.endDate!) ? "missed" : "inProgress"),
      "points_earned": totalPointsEarned,
      "penalty": totalPenalty,
      "final_score": finalScore,
      "rating": rating,
      "progress": progress.round(),
      "consistency_score": consistency,
      "breakdown": {
        "feedbacks": totalFeedbacks,
        "media": totalMedia,
        "words": totalWords,
        "overdue_penalty": overduePenalty,
        "missed_penalty": missedGoalPenalty,
        "daily_breakdown": dailyBreakdown,
      }
    };
  }

  /// Calculate status based on timeline and progress
  String calculateStatus() {
    if (timeline.startDate == null) return 'unknown';

    final now = DateTime.now();

    // Respect manual status changes
    if (indicators.status == 'cancelled') return 'cancelled';
    if (indicators.status == 'skipped') return 'skipped';
    if (indicators.status == 'postponed') return 'postponed';

    // Check if completed manually if status is updated externally
    if (indicators.status == 'completed') {
      return 'completed';
    }

    // Check timeline
    if (now.isBefore(timeline.startDate!)) {
      final hoursUntilStart = timeline.startDate!.difference(now).inHours;
      return hoursUntilStart <= 1 ? 'upcoming' : 'pending';
    }

    if (timeline.endDate != null) {
      if (now.isAfter(timeline.startDate!) && now.isBefore(timeline.endDate!)) {
        return 'inProgress';
      }
      if (now.isAfter(timeline.endDate!)) {
        return metrics.completedDays > 0 ? 'completed' : (indicators.priority == 'high' ? 'failed' : 'missed');
      }
    }

    return 'inProgress';
  }

  /// Recalculate all metrics and analysis
  LongGoalModel recalculate() {
    // 1. Backfill missing scheduled days in the goal log
    final updatedGoalLog = _backfillGoalLog();
    final updatedModel = copyWith(goalLog: updatedGoalLog);

    final List<WeekMetrics> calculatedWeeklyMetrics = [];
    final startDate = timeline.startDate;

    // 2. Calculate each week's metrics
    for (int i = 0; i < updatedModel.indicators.weeklyPlans.length; i++) {
      final plan = updatedModel.indicators.weeklyPlans[i];
      WeeklyGoalLog weekLog;
      try {
        weekLog = updatedModel.goalLog.weeklyLogs.firstWhere(
          (w) => w.weekId == plan.weekId,
          orElse: () => WeeklyGoalLog(weekId: plan.weekId, dailyFeedback: []),
        );
      } catch (_) {
        weekLog = WeeklyGoalLog(weekId: plan.weekId, dailyFeedback: []);
      }

      int weekPoints = 0;
      int weekCompletedDays = 0;
      int weekTotalScheduledDays = 0;
      int weekPendingDays = 0;
      List<String> pendingDates = [];
      int weekPenaltyPoints = 0;
      List<String> penaltyReasons = [];

      DateTime? weekStartDate = startDate?.add(Duration(days: i * 7));

      final dailyByDay = <String, List<DailyFeedback>>{};
      for (var f in weekLog.dailyFeedback) {
        final dateKey = DateFormat('yyyy-MM-dd').format(f.feedbackDay);
        dailyByDay.putIfAbsent(dateKey, () => []).add(f);
      }

      if (weekStartDate != null) {
        for (int d = 0; d < 7; d++) {
          final currentDay = weekStartDate.add(Duration(days: d));
          final dateKey = DateFormat('yyyy-MM-dd').format(currentDay);

          final isScheduled = isDateScheduled(currentDay);
          if (isScheduled) {
            weekTotalScheduledDays++;
            
            if (dailyByDay.containsKey(dateKey)) {
              final dayFeedbacks = dailyByDay[dateKey]!;
              final latest = dayFeedbacks.last;
              
              // Only count as "completed" if it has actual feedback, not just a backfilled missed entry
              if (dayFeedbacks.any((f) => f.hasMedia || f.hasText)) {
                weekCompletedDays++;
              }

              final dayProgress = DailyProgress.calculateForDay(
                weekId: plan.weekId,
                dayFeedbacks: dayFeedbacks,
                hoursPerDay: timeline.workSchedule.hoursPerDay,
              );

              weekPoints += dayProgress.pointsEarned;
              if (dayProgress.penalty != null) {
                weekPenaltyPoints += dayProgress.penalty!.penaltyPoints;
                if (!penaltyReasons.contains(dayProgress.penalty!.reason)) {
                  penaltyReasons.add(dayProgress.penalty!.reason);
                }
              }
            } else {
              weekPendingDays++;
              pendingDates.add(dateKey);
            }
          }
        }
      }

      final weekPenalty = weekPenaltyPoints > 0
          ? PenaltyInfo(
              penaltyPoints: weekPenaltyPoints.clamp(0, 100),
              reason: penaltyReasons.join(', '),
            )
          : null;

      final weekProgress =
          (weekPoints - (weekPenalty?.penaltyPoints ?? 0)).clamp(0, 100);
      final weekRating = (1.0 + 4.0 * (weekProgress / 100)).clamp(0.0, 5.0);

      final weekReward = RewardManager.calculate(
        progress: weekProgress.toDouble(),
        rating: weekRating,
        pointsEarned: weekPoints,
        completedDays: weekCompletedDays,
        totalDays: weekTotalScheduledDays > 0 ? weekTotalScheduledDays : 7,
        hoursPerDay: timeline.workSchedule.hoursPerDay,
        taskStack: 0,
        source: RewardSource.longGoal,
        onTimeCompletion: weekCompletedDays >= weekTotalScheduledDays &&
            weekTotalScheduledDays > 0,
      );

      calculatedWeeklyMetrics.add(WeekMetrics(
        weekId: plan.weekId,
        rewardPackage: weekReward,
        penalty: weekPenalty,
        progress: weekProgress,
        pointsEarned: weekPoints,
        rating: weekRating,
        totalScheduledDays: weekTotalScheduledDays,
        completedDays: weekCompletedDays,
        pendingGoalDays: weekPendingDays,
        pendingDates: pendingDates,
        suggestion: weekReward.suggestion,
      ));
    }

    final totalCompletedDays = calculatedWeeklyMetrics.isEmpty
        ? 0
        : calculatedWeeklyMetrics
            .map((m) => m.completedDays)
            .reduce((a, b) => a + b);

    final eval = updatedModel.evaluateGoal();
    final status = eval['status'] as String;
    final pointsEarned = (eval['points_earned'] as num).toInt();
    final penaltyPoints = (eval['penalty'] as num).toInt();
    final progress = (eval['progress'] as num).toDouble();
    final rating = (eval['rating'] as num).toDouble();
    final consistency = (eval['consistency_score'] as num).toDouble();

    final penaltyInfo = penaltyPoints > 0
        ? PenaltyInfo(penaltyPoints: penaltyPoints, reason: 'Goal Penalties')
        : null;

    final globalReward = RewardManager.calculate(
      progress: progress,
      rating: rating,
      pointsEarned: pointsEarned,
      completedDays: totalCompletedDays,
      totalDays: metrics.totalDays,
      hoursPerDay: timeline.workSchedule.hoursPerDay,
      taskStack: taskStack,
      source: RewardSource.longGoal,
      onTimeCompletion: !isOverdue && status == 'completed',
      consistencyOverride: consistency,
    );

    final color = CardColorHelper.getProgressColor(progress.round());

    final newMetrics = metrics.copyWith(
      completedDays: totalCompletedDays,
      weeklyMetrics: calculatedWeeklyMetrics,
    );

    final newAnalysis = analysis.copyWith(
      averageProgress: progress,
      averageRating: rating,
      pointsEarned: pointsEarned,
      consistencyScore: consistency,
      rewardPackage: globalReward,
      suggestions: [globalReward.suggestion],
      totalPenalty: penaltyInfo,
    );

    final newIndicators = indicators.copyWith(
      status: status,
      longGoalColor: _colorToHex(color),
    );

    return updatedModel.copyWith(
      metrics: newMetrics,
      analysis: newAnalysis,
      indicators: newIndicators,
      updatedAt: DateTime.now(),
    );
  }

  /// Ensures every scheduled day from startingDate up to min(today, endDate)
  /// has a DailyFeedback entry in the goal log.
  GoalLog _backfillGoalLog() {
    if (timeline.startDate == null) return goalLog;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      timeline.startDate!.year,
      timeline.startDate!.month,
      timeline.startDate!.day,
    );
    final end = timeline.endDate ?? today;
    final lastDateToCheck = today.isBefore(end) ? today : end;

    final List<WeeklyGoalLog> updatedWeeklyLogs = List.from(goalLog.weeklyLogs);
    DateTime current = start;

    while (!current.isAfter(lastDateToCheck)) {
      if (isDateScheduled(current)) {
        final weekId = getWeekIdForDate(current);
        final dateKey = DateFormat('yyyy-MM-dd').format(current);

        // Find or create weekly log
        int weekIndex = updatedWeeklyLogs.indexWhere((w) => w.weekId == weekId);
        if (weekIndex < 0) {
          updatedWeeklyLogs.add(WeeklyGoalLog(weekId: weekId, dailyFeedback: []));
          weekIndex = updatedWeeklyLogs.length - 1;
        }

        final weekLog = updatedWeeklyLogs[weekIndex];
        final exists = weekLog.dailyFeedback.any(
          (f) =>
              f.feedbackDay.year == current.year &&
              f.feedbackDay.month == current.month &&
              f.feedbackDay.day == current.day,
        );

        if (!exists) {
          final List<DailyFeedback> updatedFeedbacks =
              List.from(weekLog.dailyFeedback);
          updatedFeedbacks.add(DailyFeedback(
            weekId: weekId,
            feedbackDay: current,
            feedbackCount: '0',
            feedbackText: '',
            dailyProgress: DailyProgress.empty,
          ));
          updatedWeeklyLogs[weekIndex] =
              weekLog.copyWith(dailyFeedback: updatedFeedbacks);
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return goalLog.copyWith(weeklyLogs: updatedWeeklyLogs);
  }

  // ================================================================
  // COLOR HELPER INTEGRATION
  // ================================================================

  /// Get card gradient colors
  List<Color> getCardGradient({required bool isDarkMode}) {
    return CardColorHelper.getTaskCardGradient(
      priority: indicators.priority,
      status: indicators.status,
      progress: analysis.averageProgress.round(),
      isDarkMode: isDarkMode,
    );
  }

  /// Get card decoration
  BoxDecoration getCardDecoration({
    required bool isDarkMode,
    double borderRadius = 16.0,
  }) {
    return CardColorHelper.getCardDecoration(
      priority: indicators.priority,
      status: indicators.status,
      progress: analysis.averageProgress.round(),
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }

  /// Get status color
  Color get statusColor => CardColorHelper.getStatusColor(indicators.status);

  /// Get priority color
  Color get priorityColor =>
      CardColorHelper.getPriorityColor(indicators.priority);

  /// Get progress color
  Color get progressColor =>
      CardColorHelper.getProgressColor(analysis.averageProgress.round());
}

// ================================================================
// GOAL DESCRIPTION
// ================================================================

class GoalDescription {
  final String need;
  final String motivation;
  final String outcome;

  const GoalDescription({
    required this.need,
    required this.motivation,
    required this.outcome,
  });

  factory GoalDescription.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return GoalDescription(
      need: json['need']?.toString() ?? '',
      motivation: json['motivation']?.toString() ?? '',
      outcome: json['outcome']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'need': need,
    'motivation': motivation,
    'outcome': outcome,
  };

  GoalDescription copyWith({
    String? need,
    String? motivation,
    String? outcome,
  }) {
    return GoalDescription(
      need: need ?? this.need,
      motivation: motivation ?? this.motivation,
      outcome: outcome ?? this.outcome,
    );
  }
}

// ================================================================
// GOAL TIMELINE
// ================================================================

class GoalTimeline {
  final bool isUnspecified;
  final DateTime? startDate;
  final DateTime? endDate;
  final WorkSchedule workSchedule;

  const GoalTimeline({
    required this.isUnspecified,
    this.startDate,
    this.endDate,
    required this.workSchedule,
  });

  factory GoalTimeline.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return GoalTimeline(
      isUnspecified: json['is_unspecified'] == true || json['is_unspecified'] == 1 || json['isUnspecified'] == true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'].toString()).toLocal()
          : (json['startDate'] != null ? DateTime.parse(json['startDate'].toString()).toLocal() : null),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'].toString()).toLocal()
          : (json['endDate'] != null ? DateTime.parse(json['endDate'].toString()).toLocal() : null),
      workSchedule: WorkSchedule.fromJson(
        LongGoalModel._parseJsonb(json['work_schedule'] ?? json['workSchedule']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_unspecified': isUnspecified,
    'start_date': startDate?.toUtc().toIso8601String(),
    'end_date': endDate?.toUtc().toIso8601String(),
    'work_schedule': workSchedule.toJson(),
  };

  GoalTimeline copyWith({
    bool? isUnspecified,
    DateTime? startDate,
    DateTime? endDate,
    WorkSchedule? workSchedule,
  }) {
    return GoalTimeline(
      isUnspecified: isUnspecified ?? this.isUnspecified,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      workSchedule: workSchedule ?? this.workSchedule,
    );
  }

  /// Get remaining time
  Duration? get remainingTime {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return Duration.zero;
    return endDate!.difference(now);
  }

  /// Get elapsed time
  Duration? get elapsedTime {
    if (startDate == null) return null;
    final now = DateTime.now();
    if (now.isBefore(startDate!)) return Duration.zero;
    return now.difference(startDate!);
  }

  /// Get total duration
  Duration? get totalDuration {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!);
  }

  /// Is overdue
  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }
}

// ================================================================
// WORK SCHEDULE
// ================================================================

class WorkSchedule {
  final List<String> workDays;
  final int hoursPerDay;
  final TimeSlot? preferredTimeSlot;

  const WorkSchedule({
    required this.workDays,
    required this.hoursPerDay,
    this.preferredTimeSlot,
  });

  factory WorkSchedule.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return WorkSchedule(
      workDays: List<String>.from(
        (json['work_days'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      hoursPerDay: (json['hours_per_day'] ?? json['hoursPerDay'] ?? 0) as int,
      preferredTimeSlot: json['preferred_time_slot'] != null || json['preferredTimeSlot'] != null
          ? TimeSlot.fromJson(
              LongGoalModel._parseJsonb(json['preferred_time_slot'] ?? json['preferredTimeSlot']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'work_days': workDays,
    'hours_per_day': hoursPerDay,
    'preferred_time_slot': preferredTimeSlot?.toJson(),
  };

  WorkSchedule copyWith({
    List<String>? workDays,
    int? hoursPerDay,
    TimeSlot? preferredTimeSlot,
  }) {
    return WorkSchedule(
      workDays: workDays ?? this.workDays,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
    );
  }
}

// ================================================================
// TIME SLOT
// ================================================================

class TimeSlot {
  final DateTime startingTime;
  final DateTime endingTime;

  const TimeSlot({required this.startingTime, required this.endingTime});

  factory TimeSlot.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return TimeSlot(
      startingTime: DateTime.parse(json['starting_time']?.toString() ?? json['startingTime']?.toString() ?? DateTime.now().toIso8601String()).toLocal(),
      endingTime: DateTime.parse(json['ending_time']?.toString() ?? json['endingTime']?.toString() ?? DateTime.now().toIso8601String()).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
    'starting_time': startingTime.toUtc().toIso8601String(),
    'ending_time': endingTime.toUtc().toIso8601String(),
  };

  TimeSlot copyWith({DateTime? startingTime, DateTime? endingTime}) {
    return TimeSlot(
      startingTime: startingTime ?? this.startingTime,
      endingTime: endingTime ?? this.endingTime,
    );
  }

  Duration get duration => endingTime.difference(startingTime);
}

// ================================================================
// WEEKLY PLAN
// ================================================================

class WeeklyPlan {
  final String weekId;
  final String weeklyGoal;
  final String mood;
  final bool isCompleted;

  const WeeklyPlan({
    required this.weekId,
    required this.weeklyGoal,
    required this.mood,
    required this.isCompleted,
  });

  factory WeeklyPlan.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return WeeklyPlan(
      weekId: json['week_id']?.toString() ?? json['weekId']?.toString() ?? '',
      weeklyGoal: json['weekly_goal']?.toString() ?? json['weeklyGoal']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1 || json['isCompleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'week_id': weekId,
    'weekly_goal': weeklyGoal,
    'mood': mood,
    'is_completed': isCompleted,
  };

  WeeklyPlan copyWith({
    String? weekId,
    String? weeklyGoal,
    String? mood,
    bool? isCompleted,
  }) {
    return WeeklyPlan(
      weekId: weekId ?? this.weekId,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      mood: mood ?? this.mood,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// ================================================================
// INDICATORS
// ================================================================

class Indicators {
  final String status;
  final String priority;
  final String longGoalColor;
  final List<WeeklyPlan> weeklyPlans;

  const Indicators({
    required this.status,
    required this.priority,
    this.longGoalColor = '#667EEA',
    this.weeklyPlans = const [],
  });

  factory Indicators.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return Indicators(
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString() ?? 'normal',
      longGoalColor: json['long_goal_color']?.toString() ?? json['longGoalColor']?.toString() ?? '#667EEA',
      weeklyPlans: _parseJsonbList(
        json['weekly_plans'] ?? json['weeklyPlans'],
        (e) => WeeklyPlan.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'priority': priority,
    'long_goal_color': longGoalColor,
    'weekly_plans': {'items': weeklyPlans.map((e) => e.toJson()).toList()},
  };

  Indicators copyWith({
    String? status,
    String? priority,
    String? longGoalColor,
    List<WeeklyPlan>? weeklyPlans,
  }) {
    return Indicators(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      longGoalColor: longGoalColor ?? this.longGoalColor,
      weeklyPlans: weeklyPlans ?? this.weeklyPlans,
    );
  }

  /// Get status color
  Color get statusColor => CardColorHelper.getStatusColor(status);

  /// Get priority color
  Color get priorityColor => CardColorHelper.getPriorityColor(priority);

  /// Get color from hex
  Color get goalColor {
    try {
      final hex = longGoalColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF667EEA);
    }
  }
}

// ================================================================
// WEEK METRICS
// ================================================================

class WeekMetrics {
  final String weekId;
  final RewardPackage? rewardPackage;
  final PenaltyInfo? penalty;
  final int progress;
  final int pointsEarned;
  final double rating;
  final int totalScheduledDays; // total work days in this week
  final int completedDays; // days with feedback
  final int pendingGoalDays; // days scheduled but not completed
  final List<String> pendingDates; // specific dates not completed
  final String? suggestion;

  const WeekMetrics({
    required this.weekId,
    this.rewardPackage,
    this.penalty,
    required this.progress,
    required this.pointsEarned,
    required this.rating,
    required this.totalScheduledDays,
    required this.completedDays,
    required this.pendingGoalDays,
    required this.pendingDates,
    this.suggestion,
  });

  factory WeekMetrics.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return WeekMetrics(
      weekId: json['week_id']?.toString() ?? json['weekId']?.toString() ?? '',
      rewardPackage: json['reward_package'] != null
          ? RewardPackage.fromJson(
              LongGoalModel._parseJsonb(json['reward_package']))
          : null,
      penalty: json['penalty'] != null
          ? PenaltyInfo.fromJson(LongGoalModel._parseJsonb(json['penalty']))
          : null,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['points_earned'] as num? ?? json['pointsEarned'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalScheduledDays: (json['total_scheduled_days'] ?? json['totalScheduledDays'] ?? 0) as int,
      completedDays: (json['completed_days'] as num? ?? json['completedDays'] as num?)?.toInt() ?? 0,
      pendingGoalDays: (json['pending_goal_days'] as num? ?? json['pendingGoalDays'] as num?)?.toInt() ?? 0,
      pendingDates: List<String>.from(
        (json['pending_dates'] ?? json['pendingDates'] as List<dynamic>?)
                ?.map((e) => e.toString()) ??
            [],
      ),
      suggestion: json['suggestion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'week_id': weekId,
        'reward_package': rewardPackage?.toJson(),
        'penalty': penalty?.toJson(),
        'progress': progress,
        'points_earned': pointsEarned,
        'rating': rating,
        'total_scheduled_days': totalScheduledDays,
        'completed_days': completedDays,
        'pending_goal_days': pendingGoalDays,
        'pending_dates': pendingDates,
        'suggestion': suggestion,
      };

  WeekMetrics copyWith({
    String? weekId,
    RewardPackage? rewardPackage,
    PenaltyInfo? penalty,
    int? progress,
    int? pointsEarned,
    double? rating,
    int? totalScheduledDays,
    int? completedDays,
    int? pendingGoalDays,
    List<String>? pendingDates,
    String? suggestion,
  }) {
    return WeekMetrics(
      weekId: weekId ?? this.weekId,
      rewardPackage: rewardPackage ?? this.rewardPackage,
      penalty: penalty ?? this.penalty,
      progress: progress ?? this.progress,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      rating: rating ?? this.rating,
      totalScheduledDays: totalScheduledDays ?? this.totalScheduledDays,
      completedDays: completedDays ?? this.completedDays,
      pendingGoalDays: pendingGoalDays ?? this.pendingGoalDays,
      pendingDates: pendingDates ?? this.pendingDates,
      suggestion: suggestion ?? this.suggestion,
    );
  }
}

// ================================================================
// GOAL METRICS
// ================================================================

class GoalMetrics {
  final int totalDays;
  final int completedDays;
  final int tasksPending;
  final List<WeekMetrics> weeklyMetrics;

  const GoalMetrics({
    required this.totalDays,
    required this.completedDays,
    required this.tasksPending,
    this.weeklyMetrics = const [],
  });

  factory GoalMetrics.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return GoalMetrics(
      totalDays: (json['total_days'] as num? ?? json['totalDays'] as num?)?.toInt() ?? 0,
      completedDays: (json['completed_days'] as num? ?? json['completedDays'] as num?)?.toInt() ?? 0,
      tasksPending: (json['tasks_pending'] as num? ?? json['tasksPending'] as num?)?.toInt() ?? 0,
      weeklyMetrics: _parseJsonbList(
        json['weekly_metrics'] ?? json['weeklyMetrics'],
        (e) => WeekMetrics.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_days': totalDays,
        'completed_days': completedDays,
        'tasks_pending': tasksPending,
        'weekly_metrics': weeklyMetrics.map((e) => e.toJson()).toList(),
      };

  GoalMetrics copyWith({
    int? totalDays,
    int? completedDays,
    int? tasksPending,
    List<WeekMetrics>? weeklyMetrics,
  }) {
    return GoalMetrics(
      totalDays: totalDays ?? this.totalDays,
      completedDays: completedDays ?? this.completedDays,
      tasksPending: tasksPending ?? this.tasksPending,
      weeklyMetrics: weeklyMetrics ?? this.weeklyMetrics,
    );
  }

  /// Completion percentage
  double get completionPercentage {
    if (totalDays == 0) return 0;
    return (completedDays / totalDays) * 100;
  }
}

// ================================================================
// GOAL ANALYSIS - Integrated with RewardPackage
// ================================================================

class GoalAnalysis {
  final double averageProgress;
  final double averageRating;
  final int pointsEarned;
  final double consistencyScore;
  final RewardPackage? rewardPackage;
  final PenaltyInfo? totalPenalty;
  final List<String> suggestions;

  const GoalAnalysis({
    required this.averageProgress,
    required this.averageRating,
    required this.pointsEarned,
    this.consistencyScore = 0.0,
    this.rewardPackage,
    this.totalPenalty,
    required this.suggestions,
  });

  factory GoalAnalysis.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    RewardPackage? rewardPackage;
    if (json['reward_package'] != null) {
      rewardPackage = RewardPackage.fromJson(LongGoalModel._parseJsonb(json['reward_package']));
    }

    return GoalAnalysis(
      averageProgress: (json['average_progress'] as num? ?? json['averageProgress'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num? ?? json['averageRating'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['points_earned'] as num? ?? json['pointsEarned'] as num?)?.toInt() ?? 0,
      consistencyScore: (json['consistency_score'] as num? ?? json['consistencyScore'] as num?)?.toDouble() ?? 0.0,
      rewardPackage: rewardPackage,
      totalPenalty: (json['total_penalty'] ?? json['totalPenalty']) != null
          ? PenaltyInfo.fromJson(LongGoalModel._parseJsonb(json['total_penalty'] ?? json['totalPenalty']))
          : null,
      suggestions: List<String>.from(
        (json['suggestions'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'average_progress': averageProgress.round(),
    'average_rating': averageRating,
    'points_earned': pointsEarned,
    'consistency_score': consistencyScore,
    'reward_package': rewardPackage?.toJson(),
    'total_penalty': totalPenalty?.toJson(),
    'suggestions': suggestions,
  };

  GoalAnalysis copyWith({
    double? averageProgress,
    double? averageRating,
    int? pointsEarned,
    double? consistencyScore,
    RewardPackage? rewardPackage,
    PenaltyInfo? totalPenalty,
    List<String>? suggestions,
  }) {
    return GoalAnalysis(
      averageProgress: averageProgress ?? this.averageProgress,
      averageRating: averageRating ?? this.averageRating,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      rewardPackage: rewardPackage ?? this.rewardPackage,
      totalPenalty: totalPenalty ?? this.totalPenalty,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  // ================================================================
  // REWARD HELPERS
  // ================================================================

  /// Check if reward was earned
  bool get hasReward => rewardPackage?.earned ?? false;

  /// Get tag name
  String get tagName => rewardPackage?.tagName ?? '';

  /// Get reward display name
  String get rewardDisplayName => rewardPackage?.rewardDisplayName ?? '';

  /// Get tier
  RewardTier get tier => rewardPackage?.tier ?? RewardTier.none;

  /// Get tier level (1-8)
  int get tierLevel => rewardPackage?.tierLevel ?? 0;

  /// Get tier info
  Map<String, dynamic> get tierInfo => RewardManager.getTierInfo(tier);

  /// Get progress color
  Color get progressColor =>
      CardColorHelper.getProgressColor(averageProgress.round());

  /// Get tier color
  Color get tierColor {
    if (rewardPackage == null || !rewardPackage!.earned) {
      return CardColorHelper.getProgressColor(averageProgress.round());
    }
    return rewardPackage!.primaryColor;
  }

  static GoalAnalysis get empty => const GoalAnalysis(
    averageProgress: 0,
    averageRating: 0,
    pointsEarned: 0,
    suggestions: [],
  );
}

// ================================================================
// PENALTY INFO
// ================================================================

class PenaltyInfo {
  final int penaltyPoints;
  final String reason;

  const PenaltyInfo({required this.penaltyPoints, required this.reason});

  factory PenaltyInfo.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return PenaltyInfo(
      penaltyPoints: (json['penalty_points'] as num? ?? json['penaltyPoints'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'penalty_points': penaltyPoints,
    'reason': reason,
  };

  PenaltyInfo copyWith({int? penaltyPoints, String? reason}) {
    return PenaltyInfo(
      penaltyPoints: penaltyPoints ?? this.penaltyPoints,
      reason: reason ?? this.reason,
    );
  }
}

// ================================================================
// WEEKLY GOAL LOG
// ================================================================

class WeeklyGoalLog {
  final String weekId;
  final List<DailyFeedback> dailyFeedback;

  const WeeklyGoalLog({
    required this.weekId,
    required this.dailyFeedback,
  });

  factory WeeklyGoalLog.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    final rawFeedback = json['daily_feedback'] ?? json['dailyFeedback'];
    return WeeklyGoalLog(
      weekId: json['week_id']?.toString() ?? json['weekId']?.toString() ?? '',
      dailyFeedback: _parseJsonbList(
        rawFeedback,
        (e) => DailyFeedback.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'week_id': weekId,
    'daily_feedback': {'items': dailyFeedback.map((e) => e.toJson()).toList()},
  };

  WeeklyGoalLog copyWith({
    String? weekId,
    List<DailyFeedback>? dailyFeedback,
  }) {
    return WeeklyGoalLog(
      weekId: weekId ?? this.weekId,
      dailyFeedback: dailyFeedback ?? this.dailyFeedback,
    );
  }
}

// ================================================================
// DAILY FEEDBACK
// ================================================================

class DailyFeedback {
  final String weekId;
  final DateTime feedbackDay;
  final String feedbackCount;
  final String feedbackText;
  final String? mediaUrl;
  final DailyProgress? dailyProgress;

  const DailyFeedback({
    required this.weekId,
    required this.feedbackDay,
    required this.feedbackCount,
    required this.feedbackText,
    this.mediaUrl,
    this.dailyProgress,
  });

  factory DailyFeedback.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return DailyFeedback(
      weekId: json['week_id']?.toString() ?? json['weekId']?.toString() ?? '',
      feedbackDay: json['feedback_day'] != null
          ? DateTime.parse(json['feedback_day'].toString())
          : (json['feedbackDay'] != null ? DateTime.parse(json['feedbackDay'].toString()) : DateTime.now()),
      feedbackCount:
          (json['feedback_count'] ?? json['feedback_number'] ?? json['feedbackCount'] ?? json['feedbackNumber'])?.toString() ?? '',
      feedbackText: (json['feedback_text'] ?? json['feedbackText'])?.toString() ?? '',
      mediaUrl: (json['media_url'] ?? json['mediaUrl'])?.toString(),
      dailyProgress: (json['daily_progress'] ?? json['dailyProgress']) != null
          ? DailyProgress.fromJson(
              LongGoalModel._parseJsonb(json['daily_progress'] ?? json['dailyProgress']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'week_id': weekId,
    'feedback_day': feedbackDay.toIso8601String(),
    'feedback_count': feedbackCount,
    'feedback_text': feedbackText,
    'media_url': mediaUrl,
    'daily_progress': dailyProgress?.toJson(),
  };

  DateTime get date => feedbackDay;

  String get formattedDate => DateFormat('MMM d, yyyy').format(date);
  String get formattedTime => DateFormat('h:mm a').format(date);
  String get formattedDateTime => DateFormat('MMM d, h:mm a').format(date);

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  bool get hasText => feedbackText.isNotEmpty;

  DailyFeedback copyWith({
    String? weekId,
    DateTime? feedbackDay,
    String? feedbackCount,
    String? feedbackText,
    String? mediaUrl,
    DailyProgress? dailyProgress,
  }) {
    return DailyFeedback(
      weekId: weekId ?? this.weekId,
      feedbackDay: feedbackDay ?? this.feedbackDay,
      feedbackCount: feedbackCount ?? this.feedbackCount,
      feedbackText: feedbackText ?? this.feedbackText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      dailyProgress: dailyProgress ?? this.dailyProgress,
    );
  }
}

// ================================================================
// DAILY PROGRESS - Integrated with RewardPackage
// ================================================================

class DailyProgress {
  final RewardPackage? rewardPackage;
  final PenaltyInfo? penalty;
  final int progress;
  final int pointsEarned;
  final double rating;
  final bool isComplete;
  final bool isAuthentic;
  final String? verificationReason;
  final String? motivationalQuote;

  DailyProgress({
    this.rewardPackage,
    this.penalty,
    required this.progress,
    required this.pointsEarned,
    required this.rating,
    required this.isComplete,
    this.isAuthentic = true,
    this.verificationReason,
    this.motivationalQuote,
  });

  factory DailyProgress.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    RewardPackage? rewardPackage;
    if (json['reward_package'] != null) {
      rewardPackage = RewardPackage.fromJson(LongGoalModel._parseJsonb(json['reward_package']));
    }

    return DailyProgress(
      rewardPackage: rewardPackage,
      penalty: (json['penalty'] ?? json['total_penalty']) != null
          ? PenaltyInfo.fromJson(LongGoalModel._parseJsonb(json['penalty'] ?? json['total_penalty']))
          : null,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['points_earned'] as num? ?? json['pointsEarned'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isComplete: json['is_complete'] == true || json['is_complete'] == 1 || json['isComplete'] == true,
      isAuthentic: json['is_authentic'] == true || json['is_authentic'] == 1 || json['isAuthentic'] == true,
      verificationReason: (json['verification_reason'] ?? json['verificationReason'])?.toString(),
      motivationalQuote: (json['motivational_quote'] ?? json['motivationalQuote'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reward_package': rewardPackage?.toJson(),
    'penalty': penalty?.toJson(),
    'progress': progress,
    'points_earned': pointsEarned,
    'rating': rating,
    'is_complete': isComplete,
    'is_authentic': isAuthentic,
    'verification_reason': verificationReason,
    'motivational_quote': motivationalQuote,
  };

  /// Calculate daily progress
  static DailyProgress calculateForDay({
    required String weekId,
    required List<DailyFeedback> dayFeedbacks,
    required int hoursPerDay,
  }) {
    final hasAny = dayFeedbacks.isNotEmpty;

    // Calculate points - prioritize verified data if exists in any feedback
    int points = 0;
    bool isAuthentic = true;
    String? reason;

    for (final f in dayFeedbacks) {
      if (f.dailyProgress != null) {
        // If any feedback in the day is unauthentic, the whole day is penalized
        if (!f.dailyProgress!.isAuthentic) {
          isAuthentic = false;
          reason = f.dailyProgress!.verificationReason;
        }
        // We take the best verified progress for points if multiple? 
        // Or aggregate? Let's take the latest authentic one.
        if (f.dailyProgress!.isAuthentic) {
          points = f.dailyProgress!.pointsEarned;
        }
      }
    }

    // Fallback logic if no AI progress yet or if we need to add basics
    if (points == 0 && hasAny) {
      // 1) Feedback: count × 5
      points += dayFeedbacks.length * 5;
      
      for (final f in dayFeedbacks) {
        // 2) Media / Text
        if (f.hasMedia) points += 5;
        if (f.hasText) {
          final words = f.feedbackText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          points += words * 3;
        }
      }
    }

    // Calculate penalty
    final hasRealFeedback = dayFeedbacks.any((f) => f.hasMedia || f.hasText);

    PenaltyInfo? penalty;
    if (!hasRealFeedback && hasAny) {
      penalty = const PenaltyInfo(
        penaltyPoints: 50,
        reason: 'No real content provided',
      );
      points = 0;
    } else if (!isAuthentic) {
      penalty = PenaltyInfo(
        penaltyPoints: 100,
        reason: reason ?? 'Feedback failed verification',
      );
      points = 0; // Reset points for unauthentic days
    }

    final penaltyPoints = penalty?.penaltyPoints ?? 0;
    final progressVal = (points - penaltyPoints).clamp(0, 100);
    final ratingVal = isAuthentic ? (1.0 + 4.0 * (progressVal / 100)).clamp(0.0, 5.0) : 0.0;

    // Calculate RewardPackage
    final rewardPackage = RewardManager.calculate(
      progress: progressVal.toDouble(),
      rating: ratingVal,
      pointsEarned: points,
      completedDays: hasAny ? 1 : 0,
      totalDays: 1,
      hoursPerDay: hoursPerDay,
      taskStack: 0,
      source: RewardSource.longGoal,
      onTimeCompletion: hasAny,
    );

    return DailyProgress(
      rewardPackage: rewardPackage,
      penalty: penalty,
      progress: progressVal,
      pointsEarned: points,
      rating: ratingVal,
      isComplete: hasAny,
      motivationalQuote: rewardPackage.suggestion,
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  bool get hasReward => rewardPackage?.earned ?? false;

  String get tagName => rewardPackage?.tagName ?? '';

  String get rewardDisplayName => rewardPackage?.rewardDisplayName ?? '';

  Color get progressColor => CardColorHelper.getProgressColor(progress);

  Color get tierColor {
    if (rewardPackage == null || !rewardPackage!.earned) {
      return progressColor;
    }
    return rewardPackage!.primaryColor;
  }

  /// Get gradient colors
  List<Color> getGradientColors({required bool isDarkMode}) {
    final status = isComplete ? 'completed' : 'inProgress';
    return CardColorHelper.getTaskCardGradient(
      priority: 'medium',
      status: status,
      progress: progress,
      isDarkMode: isDarkMode,
    );
  }

  DailyProgress copyWith({
    RewardPackage? rewardPackage,
    PenaltyInfo? penalty,
    int? progress,
    int? pointsEarned,
    double? rating,
    bool? isComplete,
    String? motivationalQuote,
  }) {
    return DailyProgress(
      rewardPackage: rewardPackage ?? this.rewardPackage,
      penalty: penalty ?? this.penalty,
      progress: progress ?? this.progress,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      rating: rating ?? this.rating,
      isComplete: isComplete ?? this.isComplete,
      motivationalQuote: motivationalQuote ?? this.motivationalQuote,
    );
  }

  static DailyProgress get empty => DailyProgress(
    progress: 0,
    pointsEarned: 0,
    rating: 0,
    isComplete: false,
  );
}

// ================================================================
// SOCIAL INFO
// ================================================================

class SocialInfo {
  final bool isPosted;
  final PostedInfo? posted;

  const SocialInfo({required this.isPosted, this.posted});

  factory SocialInfo.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return SocialInfo(
      isPosted: json['is_posted'] == true || json['is_posted'] == 1,
      posted: json['posted'] != null
          ? PostedInfo.fromJson(LongGoalModel._parseJsonb(json['posted']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_posted': isPosted,
    'posted': posted?.toJson(),
  };

  SocialInfo copyWith({bool? isPosted, PostedInfo? posted}) {
    return SocialInfo(
      isPosted: isPosted ?? this.isPosted,
      posted: posted ?? this.posted,
    );
  }
}

// ================================================================
// POSTED INFO
// ================================================================

class PostedInfo {
  final String postId;
  final bool live;
  final String? snapshotUrl;
  final DateTime time;

  PostedInfo({
    this.postId = '',
    required this.live,
    this.snapshotUrl,
    required this.time,
  });

  factory PostedInfo.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return PostedInfo(
      postId: json['post_id']?.toString() ?? json['postId']?.toString() ?? '',
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: (json['snapshot_url'] ?? json['snapshotUrl'])?.toString(),
      time: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'].toString())
          : (json['time'] != null
                ? DateTime.parse(json['time'].toString())
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'live': live,
    'snapshot_url': snapshotUrl,
    'posted_at': time.toIso8601String(),
  };

  PostedInfo copyWith({
    String? postId,
    bool? live,
    String? snapshotUrl,
    DateTime? time,
  }) => PostedInfo(
    postId: postId ?? this.postId,
    live: live ?? this.live,
    snapshotUrl: snapshotUrl ?? this.snapshotUrl,
    time: time ?? this.time,
  );
}

// ================================================================
// SHARE INFO
// ================================================================

class ShareInfo {
  final bool isShare;
  final SharedInfo? shareId;

  const ShareInfo({required this.isShare, this.shareId});

  factory ShareInfo.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return ShareInfo(
      isShare: json['is_share'] == true || json['is_share'] == 1,
      shareId: json['share_id'] != null
          ? SharedInfo.fromJson(LongGoalModel._parseJsonb(json['share_id']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_share': isShare,
    'share_id': shareId?.toJson(),
  };

  ShareInfo copyWith({bool? isShare, SharedInfo? shareId}) {
    return ShareInfo(
      isShare: isShare ?? this.isShare,
      shareId: shareId ?? this.shareId,
    );
  }
}

// ================================================================
// SHARED INFO
// ================================================================

class SharedInfo {
  final bool live;
  final String? snapshotUrl;
  final String withId;
  final DateTime time;

  const SharedInfo({
    required this.live,
    this.snapshotUrl,
    required this.withId,
    required this.time,
  });

  factory SharedInfo.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonb(v);
    return SharedInfo(
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: (json['snapshot_url'] ?? json['snapshotUrl'])?.toString(),
      withId: (json['with_id'] ?? json['withId'])?.toString() ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'live': live,
    'snapshot_url': snapshotUrl,
    'with_id': withId,
    'time': time.toIso8601String(),
  };

  SharedInfo copyWith({
    bool? live,
    String? snapshotUrl,
    String? withId,
    DateTime? time,
  }) {
    return SharedInfo(
      live: live ?? this.live,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      withId: withId ?? this.withId,
      time: time ?? this.time,
    );
  }
}

// ================================================================
// EXTENSION FOR REWARD HELPER
// ================================================================

extension LongGoalRewardExtension on LongGoalModel {
  /// Get the complete reward package
  RewardPackage get rewardPackage => calculateRewardPackage();

  /// Check if goal has any reward
  bool get hasAnyReward => analysis.hasReward;

  /// Get reward box data for PremiumRewardBox widget
  Map<String, dynamic> getRewardBoxData() {
    final package = calculateRewardPackage();

    return {
      'taskId': id,
      'taskType': 'longGoal',
      'taskTitle': title,
      'rewardPackage': package,
    };
  }

  /// Get all earned tiers from weeks
  List<RewardTier> get earnedTiers {
    final tiers = <RewardTier>[];

    for (var week in goalLog.weeklyLogs) {
      final dailyByDay = <String, List<DailyFeedback>>{};
      for (var f in week.dailyFeedback) {
        final dateKey = DateFormat('yyyy-MM-dd').format(f.feedbackDay);
        dailyByDay.putIfAbsent(dateKey, () => []).add(f);
      }
      for (var entry in dailyByDay.entries) {
        final last = entry.value.last;
        if (last.dailyProgress?.rewardPackage?.earned ?? false) {
           tiers.add(last.dailyProgress!.rewardPackage!.tier);
        }
      }
    }

    if (analysis.hasReward) {
      tiers.add(analysis.tier);
    }

    return tiers;
  }

  /// Get highest tier name
  String get highestTierName {
    RewardTier best = RewardTier.none;

    for (var tier in earnedTiers) {
      if (tier.index > best.index) {
        best = tier;
      }
    }

    final tierInfo = RewardManager.getTierInfo(best);
    return tierInfo['name'] as String? ?? 'None';
  }

  /// Get next tier info
  Map<String, dynamic>? get nextTierInfo {
    return RewardManager.getNextTierInfo(analysis.tier);
  }
}

extension LongGoalColorExtension on LongGoalModel {
  /// Get dynamic gradient based on context
  Gradient getDynamicGradient(BuildContext context) {
    return CardColorHelper.getDynamicGradient(
      context,
      recordId: id,
      priority: indicators.priority,
      status: indicators.status,
      progress: analysis.averageProgress.round(),
      rating: analysis.averageRating,
      createdAt: createdAt,
      dueDate: timeline.endDate ?? DateTime.now(),
    );
  }

  /// Get box decoration for card
  BoxDecoration getBoxDecoration(
    BuildContext context, {
    double borderRadius = 16.0,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return getCardDecoration(
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }
}


// ================================================================
// GOAL LOG WRAPPER
// ================================================================

class GoalLog {
  final List<WeeklyGoalLog> weeklyLogs;

  const GoalLog({required this.weeklyLogs});

  factory GoalLog.fromJson(dynamic v) {
    final json = LongGoalModel._parseJsonbRaw(v);
    if (json is List) {
      return GoalLog(
        weeklyLogs: json.map((e) => WeeklyGoalLog.fromJson(e)).toList(),
      );
    }
    final map = LongGoalModel._parseJsonb(json);
    final rawLogs = map['weekly_logs'] ?? map['weeklyLogs'];
    return GoalLog(
      weeklyLogs: _parseJsonbList(
        rawLogs,
        (e) => WeeklyGoalLog.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'weekly_logs': {'items': weeklyLogs.map((e) => e.toJson()).toList()},
  };

  GoalLog copyWith({List<WeeklyGoalLog>? weeklyLogs}) {
    return GoalLog(weeklyLogs: weeklyLogs ?? this.weeklyLogs);
  }
}
// ================================================================
// HELPER FUNCTIONS
// ================================================================

List<T> _parseJsonbList<T>(
  dynamic v,
  T Function(Map<String, dynamic>) fromJson,
) {
  final json = LongGoalModel._parseJsonbRaw(v);
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }
  if (json is Map && json.containsKey('items')) {
    final items = json['items'] as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }
  return [];
}


String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

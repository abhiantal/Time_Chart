// ================================================================
// FILE: lib/features/week_task/models/week_task_model.dart
// FULLY INTEGRATED WITH REWARD MANAGER (8 TIERS) & CARD COLOR HELPER
// ================================================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';

/// Main Week WeekTaskModel with daily progress tracking
class WeekTaskModel {
  static DateTime parseDuration(String? value) {
    if (value == null || value.isEmpty) return DateTime(0, 1, 1, 4, 0, 0);

    // Check for "4 hours : 20 minutes" format
    if (value.contains('hour') || value.contains('minute')) {
      try {
        int hours = 0;
        int minutes = 0;

        final hourMatch = RegExp(r'(\d+)\s+hour').firstMatch(value);
        final minuteMatch = RegExp(r'(\d+)\s+minute').firstMatch(value);

        if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
        if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);

        return DateTime(0, 1, 1, hours, minutes);
      } catch (_) {
        // Fallback to other parsing methods
      }
    }

    // Check for ISO 8601 duration (starts with P)
    if (value.startsWith('P')) {
      try {
        int hours = 0;
        int minutes = 0;
        int seconds = 0;

        // Simple regex-based parsing for PT[H]H[M]M[S]S
        final hourMatch = RegExp(r'(\d+)H').firstMatch(value);
        final minuteMatch = RegExp(r'(\d+)M').firstMatch(value);
        final secondMatch = RegExp(r'(\d+)S').firstMatch(value);

        if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
        if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);
        if (secondMatch != null) seconds = int.parse(secondMatch.group(1)!);

        return DateTime(0, 1, 1, hours, minutes, seconds);
      } catch (_) {
        return DateTime(0, 1, 1, 4, 0, 0);
      }
    }

    // Try parsing as ISO 8601 DateTime
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime(0, 1, 1, 4, 0, 0);
    }
  }

  static String formatDurationHMS(DateTime? duration) {
    if (duration == null) return '0 hours : 0 minutes';
    final hours = duration.hour;
    final minutes = duration.minute;

    String hourStr = hours == 1 ? 'hour' : 'hours';
    String minuteStr = minutes == 1 ? 'minute' : 'minutes';

    if (hours > 0 && minutes > 0) {
      return '$hours $hourStr : $minutes $minuteStr';
    } else if (hours > 0) {
      return '$hours $hourStr';
    } else {
      return '$minutes $minuteStr';
    }
  }

  final String id;
  final String userId;
  final String categoryId;
  final String categoryType;
  final String subTypes;
  final AboutTask aboutTask;
  final Indicators indicators;
  final TaskTimeline timeline;
  final WeekTaskFeedback feedback;
  final WeeklySummary summary;
  final SocialInfo socialInfo;
  final ShareInfo shareInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeekTaskModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryType,
    required this.subTypes,
    required this.aboutTask,
    required this.indicators,
    required this.timeline,
    required this.feedback,
    required this.summary,
    required this.socialInfo,
    required this.shareInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper getter for backward compatibility with UI
  List<DailyProgress> get dailyProgress => feedback.dailyProgress;

  // ================================================================
  // FACTORY CONSTRUCTORS
  // ================================================================

  factory WeekTaskModel.fromJson(Map<String, dynamic> json) {
    return WeekTaskModel(
      id: json['task_id'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryType: json['category_type'] ?? '',
      subTypes: json['sub_types'] ?? '',
      aboutTask: AboutTask.fromJson(_parseJsonb(json['about_task'])),
      indicators: Indicators.fromJson(_parseJsonb(json['indicators'])),
      timeline: TaskTimeline.fromJson(_parseJsonb(json['timeline'])),
      feedback: WeekTaskFeedback.fromJson(_parseJsonb(json['feedback'])),
      summary: WeeklySummary.fromJson(_parseJsonb(json['metadata'])),
      socialInfo: SocialInfo.fromJson(_parseJsonb(json['social_info'])),
      shareInfo: ShareInfo.fromJson(_parseJsonb(json['share_info'])),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'task_id': id,
    'user_id': userId,
    'category_id': categoryId,
    'category_type': categoryType,
    'sub_types': subTypes,
    'about_task': aboutTask.toJson(),
    'indicators': indicators.toJson(),
    'timeline': timeline.toJson(),
    'feedback': feedback.toJson(),
    'metadata': summary.toJson(),
    'social_info': socialInfo.toJson(),
    'share_info': shareInfo.toJson(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ================================================================
  // HELPER METHODS
  // ================================================================

  List<String> get scheduledDays => timeline.taskDays
      .split(',')
      .map((d) => d.trim().toLowerCase())
      .where((d) => d.isNotEmpty)
      .toList();

  DailyProgress? getProgressForDate(DateTime date) {
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    try {
      return dailyProgress.firstWhere((p) => p.taskDate == dateStr);
    } catch (_) {
      return null;
    }
  }

  bool isDateScheduled(DateTime date) {
    return timeline.isScheduledDate(date, createdAt: createdAt);
  }

  DailyProgress? get todayProgress => getProgressForDate(DateTime.now());

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(
          timeline.startingDate.subtract(const Duration(days: 1)),
        ) &&
        now.isBefore(timeline.expectedEndingDate.add(const Duration(days: 1)));
  }

  // Compatibility getter
  bool get isOverdue => false;

  int get totalCompletedDays {
    return dailyProgress.where((p) => p.dailyMetrics.isComplete).length;
  }

  int get totalFeedbacks =>
      dailyProgress.fold<int>(0, (sum, p) => sum + p.feedbacks.length);
  int get totalPointsEarned => summary.pointsEarned;

  int get taskStack {
    return totalCompletedDays ~/ 7;
  }

  int get estimatedHoursPerDay {
    if (dailyProgress.isEmpty) return 0;

    int totalHours = 0;
    int daysWithFeedback = 0;

    for (var day in dailyProgress) {
      if (day.feedbacks.isNotEmpty) {
        daysWithFeedback++;
        totalHours += (day.feedbacks.length * 20 ~/ 60) + 1;
      }
    }

    return daysWithFeedback > 0 ? totalHours ~/ daysWithFeedback : 0;
  }

  WeekTaskModel recalculate() {
    // 1. Backfill missing scheduled days first
    final backfilledProgress = _backfillDailyProgress();

    // 2. Recalculate each daily progress
    final updatedDailyProgress = backfilledProgress.map((day) {
      return day.evaluate(
        timeline: timeline,
        priority: indicators.priority,
        createdAt: createdAt,
      );
    }).toList();

    // 3. Calculate weekly summary
    final newSummary = WeeklySummary.calculate(
      dailyProgress: updatedDailyProgress,
      timeline: timeline,
      scheduledDays: scheduledDays,
      taskStack: taskStack,
      createdAt: createdAt,
    );

    String newStatus = indicators.status;

    if (newStatus == 'onHold') {
      // Keep onHold
    } else if (newSummary.progress >= 100) {
      newStatus = 'completed';
    } else if (newSummary.progress > 0) {
      newStatus = 'inProgress';
    } else {
      newStatus = 'pending';
    }

    return copyWith(
      feedback: feedback.copyWith(dailyProgress: updatedDailyProgress),
      summary: newSummary,
      indicators: indicators.copyWith(status: newStatus),
      updatedAt: DateTime.now(),
    );
  }

  /// Ensure every scheduled day from startingDate up to min(today, expectedEndingDate)
  /// has a DailyProgress entry in the list.
  List<DailyProgress> _backfillDailyProgress() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final taskStart = DateTime(
      timeline.startingDate.year,
      timeline.startingDate.month,
      timeline.startingDate.day,
    );
    final actualStart = taskStart.isBefore(createdDate) ? createdDate : taskStart;
    final end = timeline.expectedEndingDate;
    final lastDateToCheck = today.isBefore(end) ? today : end;

    final List<DailyProgress> updatedList = List.from(dailyProgress);
    DateTime current = actualStart;

    while (!current.isAfter(lastDateToCheck)) {
      if (isDateScheduled(current)) {
        final dateStr = DateFormat('dd-MM-yyyy').format(current);
        final exists = updatedList.any((p) => p.taskDate == dateStr);

        if (!exists) {
          updatedList.add(DailyProgress(
            taskDate: dateStr,
            dayName: DateFormat('EEEE').format(current),
            feedbacks: [],
            dailyMetrics: DayMetrics.empty,
          ));
        }
      }
      current = current.add(const Duration(days: 1));
    }

    // Sort by date to keep it clean
    updatedList.sort((a, b) => a.date.compareTo(b.date));
    return updatedList;
  }

  // ================================================================
  // REWARD MANAGER INTEGRATION
  // ================================================================

  RewardPackage calculateRewardPackage() {
    return RewardManager.calculate(
      progress: summary.progress.toDouble(),
      rating: summary.rating,
      pointsEarned: summary.pointsEarned,
      completedDays: totalCompletedDays,
      totalDays: timeline.totalScheduledDays,
      hoursPerDay: estimatedHoursPerDay,
      taskStack: taskStack,
      source: RewardSource.weekTask,
      onTimeCompletion: true,
    );
  }

  bool get hasEarnedReward => calculateRewardPackage().earned;

  RewardTier get rewardTier => calculateRewardPackage().tier;

  // ================================================================
  // COLOR HELPER INTEGRATION
  // ================================================================

  /// Get card gradient colors based on status, priority, and progress
  List<Color> getCardGradient({required bool isDarkMode}) {
    return CardColorHelper.getTaskCardGradient(
      priority: indicators.priority,
      status: indicators.status,
      progress: summary.progress,
      isDarkMode: isDarkMode,
    );
  }

  /// Get card decoration with gradient
  BoxDecoration getCardDecoration({
    required bool isDarkMode,
    double borderRadius = 16.0,
  }) {
    return CardColorHelper.getCardDecoration(
      priority: indicators.priority,
      status: indicators.status,
      progress: summary.progress,
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }

  /// Get primary status color
  Color get statusColor => CardColorHelper.getStatusColor(indicators.status);

  /// Get primary priority color
  Color get priorityColor =>
      CardColorHelper.getPriorityColor(indicators.priority);

  /// Get progress color
  Color get progressColor => CardColorHelper.getProgressColor(summary.progress);

  // ================================================================
  // COPY WITH
  // ================================================================

  WeekTaskModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryType,
    String? subTypes,
    AboutTask? aboutTask,
    Indicators? indicators,
    TaskTimeline? timeline,
    WeekTaskFeedback? feedback,
    WeeklySummary? summary,
    SocialInfo? socialInfo,
    ShareInfo? shareInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WeekTaskModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    categoryType: categoryType ?? this.categoryType,
    subTypes: subTypes ?? this.subTypes,
    aboutTask: aboutTask ?? this.aboutTask,
    indicators: indicators ?? this.indicators,
    timeline: timeline ?? this.timeline,
    feedback: feedback ?? this.feedback,
    summary: summary ?? this.summary,
    socialInfo: socialInfo ?? this.socialInfo,
    shareInfo: shareInfo ?? this.shareInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

// ================================================================
// ABOUT TASK
// ================================================================

class AboutTask {
  final String taskName;
  final String? taskDescription;
  final String? mediaUrl;

  AboutTask({required this.taskName, this.taskDescription, this.mediaUrl});

  Map<String, dynamic> toJson() => {
    'task_name': taskName,
    'task_description': taskDescription,
    'media_url': mediaUrl,
  };

  factory AboutTask.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return AboutTask(
      taskName: json['task_name'] ?? '',
      taskDescription: json['task_description'],
      mediaUrl: json['media_url'],
    );
  }
}

// ================================================================
// INDICATORS
// ================================================================

class Indicators {
  final String status;
  final String priority;

  Indicators({required this.status, required this.priority});

  Map<String, dynamic> toJson() => {'status': status, 'priority': priority};

  factory Indicators.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return Indicators(
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
    );
  }

  Indicators copyWith({String? status, String? priority}) => Indicators(
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );

  /// Get status color using CardColorHelper
  Color get statusColor => CardColorHelper.getStatusColor(status);

  /// Get priority color using CardColorHelper
  Color get priorityColor => CardColorHelper.getPriorityColor(priority);
}

// ================================================================
// TASK TIMELINE
// ================================================================

class TaskTimeline {
  final String taskDays;
  final DateTime startingDate;
  final DateTime expectedEndingDate;
  final DateTime startingTime;
  final DateTime endingTime;
  final DateTime taskDuration;

  TaskTimeline({
    required this.taskDays,
    required this.startingDate,
    required this.expectedEndingDate,
    required this.startingTime,
    required this.endingTime,
    required this.taskDuration,
  });

  Map<String, dynamic> toJson() => {
    'task_days': taskDays,
    'starting_date': startingDate.toUtc().toIso8601String(),
    'expected_ending_date': expectedEndingDate.toUtc().toIso8601String(),
    'starting_time': startingTime.toUtc().toIso8601String(),
    'ending_time': endingTime.toUtc().toIso8601String(),
    'task_duration': WeekTaskModel.formatDurationHMS(taskDuration),
  };

  factory TaskTimeline.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return TaskTimeline(
      taskDays: json['task_days'] ?? '',
      startingDate: json['starting_date'] != null
          ? DateTime.parse(json['starting_date']).toLocal()
          : DateTime.now(),
      expectedEndingDate: json['expected_ending_date'] != null
          ? DateTime.parse(json['expected_ending_date']).toLocal()
          : DateTime.now().add(const Duration(days: 7)),
      startingTime: json['starting_time'] != null
          ? DateTime.parse(json['starting_time']).toLocal()
          : DateTime.now(),
      endingTime: json['ending_time'] != null
          ? DateTime.parse(json['ending_time']).toLocal()
          : DateTime.now().add(const Duration(days: 7)),
      taskDuration: WeekTaskModel.parseDuration(json['task_duration']),
    );
  }

  List<String> get scheduledDays => taskDays
      .split(',')
      .map((d) => d.trim().toLowerCase())
      .where((d) => d.isNotEmpty)
      .toList();

  bool isScheduledDate(DateTime date, {DateTime? createdAt}) {
    // 1. Check if date is within task lifetime
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(
      startingDate.year,
      startingDate.month,
      startingDate.day,
    );
    final endOnly = DateTime(
      expectedEndingDate.year,
      expectedEndingDate.month,
      expectedEndingDate.day,
    );

    if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
      return false;
    }

    if (createdAt != null) {
      final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (dateOnly.isBefore(createdDate)) {
        return false;
      }

      // Check if task was created after the session ending time on this date
      final dayEndingTime = DateTime(
        dateOnly.year,
        dateOnly.month,
        dateOnly.day,
        endingTime.hour,
        endingTime.minute,
        endingTime.second,
      );

      if (createdAt.isAfter(dayEndingTime)) {
        return false;
      }
    }

    // 2. Check if day of week matches
    final dayName = DateFormat('EEEE').format(date).toLowerCase();
    final shortDayName = dayName.substring(0, 3);

    return scheduledDays.any((d) {
      final cleanD = d.trim().toLowerCase();
      return cleanD == dayName ||
          cleanD == shortDayName ||
          dayName.startsWith(cleanD);
    });
  }

  int calculateTotalScheduledDays(DateTime? createdAt) {
    int count = 0;
    DateTime current = startingDate;
    while (!current.isAfter(expectedEndingDate)) {
      if (isScheduledDate(current, createdAt: createdAt)) count++;
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  int get totalScheduledDays => calculateTotalScheduledDays(null);

  bool get isOverdue => false;

  /// Get remaining time
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expectedEndingDate)) return Duration.zero;
    return expectedEndingDate.difference(now);
  }

  /// Get elapsed time
  Duration get elapsedTime {
    final now = DateTime.now();
    if (now.isBefore(startingDate)) return Duration.zero;
    return now.difference(startingDate);
  }

  TaskTimeline copyWith({
    String? taskDays,
    DateTime? startingDate,
    DateTime? expectedEndingDate,
    DateTime? startingTime,
    DateTime? endingTime,
    DateTime? taskDuration,
  }) {
    return TaskTimeline(
      taskDays: taskDays ?? this.taskDays,
      startingDate: startingDate ?? this.startingDate,
      expectedEndingDate: expectedEndingDate ?? this.expectedEndingDate,
      startingTime: startingTime ?? this.startingTime,
      endingTime: endingTime ?? this.endingTime,
      taskDuration: taskDuration ?? this.taskDuration,
    );
  }

  // Compatibility getters
  int get feedbackIntervalMinutes => 0;
}

// ================================================================
// WEEK TASK FEEDBACK (JSON OBJECT WRAPPER)
// ================================================================

class WeekTaskFeedback {
  final List<DailyProgress> dailyProgress;

  WeekTaskFeedback({required this.dailyProgress});

  factory WeekTaskFeedback.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    if (json.isEmpty) return WeekTaskFeedback(dailyProgress: []);
    final raw = json['daily_progress_list'] ?? json['dailyProgressList'];

    return WeekTaskFeedback(
      dailyProgress: _parseJsonbList(
        raw,
        (e) => DailyProgress.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_progress_list': {'items': dailyProgress.map((p) => p.toJson()).toList()},
  };

  WeekTaskFeedback copyWith({List<DailyProgress>? dailyProgress}) =>
      WeekTaskFeedback(dailyProgress: dailyProgress ?? this.dailyProgress);
}

// ================================================================
// DAILY PROGRESS
// ================================================================

class DailyProgress {
  final String taskDate;
  final String dayName;
  final List<DailyFeedback> feedbacks;
  final DayMetrics dailyMetrics;

  DailyProgress({
    required this.taskDate,
    required this.dayName,
    required this.feedbacks,
    required this.dailyMetrics,
  });

  factory DailyProgress.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DailyProgress(
      taskDate: json['task_date'] ?? '',
      dayName: json['day_name'] ?? '',
      feedbacks: _parseJsonbList(
        json['feedbacks'],
        (e) => DailyFeedback.fromJson(e),
      ),
      dailyMetrics: DayMetrics.fromJson(_parseJsonb(json['daily_progress'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'task_date': taskDate,
    'day_name': dayName,
    'feedbacks': {'items': feedbacks.map((f) => f.toJson()).toList()},
    'daily_progress': dailyMetrics.toJson(),
  };

  DateTime get date {
    try {
      final parts = taskDate.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  // Compatibility getters
  bool get isComplete => dailyMetrics.isComplete;
  DayMetrics get metrics => dailyMetrics;

  bool canAddFeedback() {
    return true;
  }

  Duration timeUntilNextFeedback() => Duration.zero;

  DailyProgress evaluate({
    required TaskTimeline timeline,
    required String priority,
    DateTime? createdAt,
  }) {
    final newMetrics = DayMetrics.calculate(
      feedbacks: feedbacks,
      timeline: timeline,
      priority: priority,
      taskDate: date,
      createdAt: createdAt,
    );
    return copyWith(dailyMetrics: newMetrics);
  }

  /// Get card gradient for this day
  List<Color> getCardGradient({required bool isDarkMode}) {
    final status = dailyMetrics.isComplete ? 'completed' : 'inProgress';
    return CardColorHelper.getTaskCardGradient(
      priority: 'medium',
      status: status,
      progress: dailyMetrics.progress,
      isDarkMode: isDarkMode,
    );
  }

  DailyProgress copyWith({
    String? taskDate,
    String? dayName,
    List<DailyFeedback>? feedbacks,
    DayMetrics? dailyMetrics,
  }) => DailyProgress(
    taskDate: taskDate ?? this.taskDate,
    dayName: dayName ?? this.dayName,
    feedbacks: feedbacks ?? this.feedbacks,
    dailyMetrics: dailyMetrics ?? this.dailyMetrics,
  );
}

// ================================================================
// DAILY FEEDBACK
// ================================================================

class DailyFeedback {
  final String feedbackNumber;
  final String text;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isPass;
  final String? verificationReason;

  DailyFeedback({
    required this.feedbackNumber,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    this.isPass = true,
    this.verificationReason,
  });

  factory DailyFeedback.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DailyFeedback(
      feedbackNumber: json['feedback_number']?.toString() ?? json['feedback_count']?.toString() ?? '0',
      text: json['text'] ?? json['final_text'] ?? '',
      mediaUrl: json['media_url'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp']).toLocal()
          : DateTime.now(),
      isPass: json['is_pass'] == true || json['is_pass'] == 1 || json['is_pass'] == null,
      verificationReason: json['verification_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'feedback_number': feedbackNumber,
    'text': text,
    'media_url': mediaUrl,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'is_pass': isPass,
    'verification_reason': verificationReason,
  };

  // Compatibility getters
  String get finalText => text;
  int get feedbackCount => int.tryParse(feedbackNumber) ?? 0;

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
}

// ================================================================
// DAY METRICS
// ================================================================

class DayMetrics {
  final RewardPackage? rewardPackage;
  final Penalty? penalty;
  final int progress;
  final int pointsEarned;
  final int penaltyPoints;
  final int finalScore;
  final double rating;
  final bool isComplete;
  final String status;
  final Map<String, dynamic>? breakdown;

  DayMetrics({
    this.rewardPackage,
    this.penalty,
    required this.progress,
    required this.pointsEarned,
    this.penaltyPoints = 0,
    this.finalScore = 0,
    required this.rating,
    required this.isComplete,
    this.status = 'pending',
    this.breakdown,
  });

  factory DayMetrics.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DayMetrics(
      rewardPackage: json['reward_package'] != null
          ? RewardPackage.fromJson(_parseJsonb(json['reward_package']))
          : null,
      penalty: json['penalty'] != null
          ? Penalty.fromJson(_parseJsonb(json['penalty']))
          : null,
      progress: json['progress'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
      penaltyPoints: json['penalty_points'] ?? 0,
      finalScore: json['final_score'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isComplete: json['is_complete'] == true || json['is_complete'] == 1,
      status: json['status'] ?? 'pending',
      breakdown: json['breakdown'] != null ? Map<String, dynamic>.from(json['breakdown']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'reward_package': rewardPackage?.toJson(),
    'penalty': penalty?.toJson(),
    'progress': progress,
    'points_earned': pointsEarned,
    'penalty_points': penaltyPoints,
    'final_score': finalScore,
    'rating': rating,
    'is_complete': isComplete,
    'status': status,
    'breakdown': breakdown,
  };

  DayMetrics copyWith({
    RewardPackage? rewardPackage,
    Penalty? penalty,
    int? progress,
    int? pointsEarned,
    int? penaltyPoints,
    int? finalScore,
    double? rating,
    bool? isComplete,
    String? status,
    Map<String, dynamic>? breakdown,
  }) {
    return DayMetrics(
      rewardPackage: rewardPackage ?? this.rewardPackage,
      penalty: penalty ?? this.penalty,
      progress: progress ?? this.progress,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      penaltyPoints: penaltyPoints ?? this.penaltyPoints,
      finalScore: finalScore ?? this.finalScore,
      rating: rating ?? this.rating,
      isComplete: isComplete ?? this.isComplete,
      status: status ?? this.status,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  // Compatibility getters for UI
  Color get progressColor => CardColorHelper.getProgressColor(progress);
  bool get hasReward => rewardPackage?.earned ?? false;
  String get tagName => rewardPackage?.tagName ?? '';
  String get rewardDisplayName => rewardPackage?.rewardDisplayName ?? '';
  String get motivationalQuote => '';

  static DayMetrics calculate({
    required List<DailyFeedback> feedbacks,
    required TaskTimeline timeline,
    required String priority,
    required DateTime taskDate,
    DateTime? createdAt,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final dayEndingTime = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
      timeline.endingTime.hour,
      timeline.endingTime.minute,
      timeline.endingTime.second,
    );

    // RULE 7: MISSED / FAILED
    // If no feedback between starting and ending time -> mark as missed/failed penalty = -100 points
    if (feedbacks.isEmpty && currentTime.isAfter(dayEndingTime)) {
      if (createdAt != null && createdAt.isAfter(dayEndingTime)) {
        return DayMetrics(
          status: "pending",
          pointsEarned: 0,
          penaltyPoints: 0,
          finalScore: 0,
          rating: 0.0,
          progress: 0,
          isComplete: false,
        );
      }

      return DayMetrics(
        status: "missed",
        pointsEarned: 0,
        penaltyPoints: 100,
        finalScore: -100,
        rating: 0.0,
        progress: 0,
        isComplete: false,
        penalty: const Penalty(penaltyPoints: 100, reason: "No feedback submitted during task session"),
      );
    }

    // COMPLETED: If task has any feedback (even one)
    final isCompleted = feedbacks.isNotEmpty;
    final status = isCompleted ? "completed" : "pending";

    // 1) Feedback count × 5
    int feedbackPoints = 0;
    // 2) Media / Text
    int mediaPoints = 0;
    int textPoints = 0;

    for (var f in feedbacks) {
      if (f.isPass) {
        feedbackPoints += 5;
        if (f.hasMedia) mediaPoints += 5;
        
        final words = f.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        textPoints += words * 3;
      }
    }

    // 3) Priority: low = 5, medium = 10, high = 15
    int priorityPoints = 0;
    switch (priority.toLowerCase()) {
      case 'high': priorityPoints = 15; break;
      case 'medium': priorityPoints = 10; break;
      case 'low': priorityPoints = 5; break;
    }

    // 4) On Time: +20 (between starting and ending time)
    int onTimeBonus = 0;
    if (feedbacks.any((f) => (f.timestamp.isAtSameMomentAs(timeline.startingTime) || f.timestamp.isAfter(timeline.startingTime)) && 
                              (f.timestamp.isAtSameMomentAs(timeline.endingTime) || f.timestamp.isBefore(timeline.endingTime)))) {
      onTimeBonus = 20;
    }

    // 5) Completion Duration
    int durationPoints = 0;
    final durationInMinutes = timeline.endingTime.difference(timeline.startingTime).inMinutes;
    final d = durationInMinutes / 60.0;
    
    if (d < 1) { durationPoints = 5; }
    else if (d < 2) { durationPoints = 10; }
    else if (d < 3) { durationPoints = 15; }
    else if (d < 4) { durationPoints = 20; }
    else if (d < 5) { durationPoints = 30; }
    else if (d < 6) { durationPoints = 40; }
    else if (d < 7) { durationPoints = 50; }
    else if (d < 8) { durationPoints = 70; }
    else if (d < 9) { durationPoints = 80; }
    else { durationPoints = 100; }

    int totalPointsEarned = feedbackPoints + mediaPoints + textPoints + priorityPoints + onTimeBonus + durationPoints;

    // SLOT PENALTIES: Every 20 minutes = 1 feedback slot
    // User must submit feedback within a 2â€“4 minute window inside that slot
    int slotPenalty = 0;
    final totalSlots = (durationInMinutes / 20).floor();
    
    for (int n = 1; n <= totalSlots; n++) {
      final slotEnd = timeline.startingTime.add(Duration(minutes: n * 20));
      final windowStart = slotEnd.subtract(const Duration(minutes: 2));
      final windowEnd = slotEnd.add(const Duration(minutes: 2));
      
      bool submitted = feedbacks.any((f) => 
        (f.timestamp.isAtSameMomentAs(windowStart) || f.timestamp.isAfter(windowStart)) && 
        (f.timestamp.isAtSameMomentAs(windowEnd) || f.timestamp.isBefore(windowEnd)));
      
      if (!submitted) {
        slotPenalty += 10;
      }
    }

    int totalPenalty = slotPenalty;
    int finalScore = totalPointsEarned - totalPenalty;

    // RATING & PROGRESS
    double rating = 0.0;
    int progress = 0;
    
    if (finalScore <= 0) { rating = 0.0; progress = 0; }
    else if (finalScore <= 20) { rating = 1.0; progress = 10; }
    else if (finalScore <= 50) { rating = 2.0; progress = 30; }
    else if (finalScore <= 100) { rating = 3.0; progress = 55; }
    else if (finalScore <= 150) { rating = 4.0; progress = 75; }
    else if (finalScore <= 200) { rating = 4.5; progress = 88; }
    else { rating = 5.0; progress = 100; }

    return DayMetrics(
      status: status,
      pointsEarned: totalPointsEarned,
      penaltyPoints: totalPenalty,
      finalScore: finalScore,
      rating: rating,
      progress: progress,
      isComplete: isCompleted,
      breakdown: {
        "feedbackPoints": feedbackPoints,
        "mediaPoints": mediaPoints,
        "textPoints": textPoints,
        "priorityPoints": priorityPoints,
        "onTimeBonus": onTimeBonus,
        "durationPoints": durationPoints,
        "slotPenalty": slotPenalty,
      },
      penalty: totalPenalty > 0 ? Penalty(penaltyPoints: totalPenalty, reason: "Slot window misses") : null,
    );
  }

  static DayMetrics get empty =>
      DayMetrics(progress: 0, pointsEarned: 0, rating: 0, isComplete: false);
}

// ================================================================
// WEEKLY SUMMARY
// ================================================================

class WeeklySummary {
  final String weekId;
  final RewardPackage? rewardPackage;
  final Penalty? penalty;
  final int progress;
  final int pointsEarned;
  final double rating;
  final double consistencyScore;
  final int totalScheduledDays;
  final int completedDays;
  final int pendingGoalDays;
  final List<String> pendingDates;
  final String status;
  final String bestDay;
  final String worstDay;

  const WeeklySummary({
    this.weekId = '',
    this.rewardPackage,
    this.penalty,
    required this.progress,
    required this.pointsEarned,
    required this.rating,
    this.consistencyScore = 0.0,
    required this.totalScheduledDays,
    required this.completedDays,
    required this.pendingGoalDays,
    required this.pendingDates,
    required this.status,
    this.bestDay = 'N/A',
    this.worstDay = 'N/A',
  });

  factory WeeklySummary.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return WeeklySummary(
      weekId: json['week_id'] ?? '',
      rewardPackage: json['reward_package'] != null
          ? RewardPackage.fromJson(_parseJsonb(json['reward_package']))
          : null,
      penalty: json['penalty'] != null
          ? Penalty.fromJson(_parseJsonb(json['penalty']))
          : null,
      progress: json['progress'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? 0.0,
      totalScheduledDays: json['total_scheduled_days'] ?? 0,
      completedDays: json['completed_days'] ?? 0,
      pendingGoalDays: json['pending_goal_days'] ?? 0,
      pendingDates: List<String>.from(json['pending_dates'] ?? []),
      status: json['status'] ?? 'pending',
      bestDay: json['best_day'] ?? 'N/A',
      worstDay: json['worst_day'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {
    'week_id': weekId,
    'reward_package': rewardPackage?.toJson(),
    'penalty': penalty?.toJson(),
    'progress': progress,
    'points_earned': pointsEarned,
    'rating': rating,
    'consistency_score': consistencyScore,
    'total_scheduled_days': totalScheduledDays,
    'completed_days': completedDays,
    'pending_goal_days': pendingGoalDays,
    'pending_dates': pendingDates,
    'status': status,
    'best_day': bestDay,
    'worst_day': worstDay,
  };

  static WeeklySummary calculate({
    required List<DailyProgress> dailyProgress,
    required TaskTimeline timeline,
    required List<String> scheduledDays,
    int taskStack = 0,
    DateTime? createdAt,
  }) {
    if (dailyProgress.isEmpty) return WeeklySummary.empty;

    int totalPoints = 0, totalProgressSum = 0, completed = 0, missed = 0;

    for (var day in dailyProgress) {
      totalPoints += day.dailyMetrics.pointsEarned;
      totalProgressSum += day.dailyMetrics.progress;

      final dateOnly = DateTime(day.date.year, day.date.month, day.date.day);
      bool isDayScheduled = scheduledDays.contains(day.dayName.toLowerCase());
      if (createdAt != null) {
        final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (dateOnly.isBefore(createdDate)) {
          isDayScheduled = false;
        }
      }

      if (day.dailyMetrics.isComplete) {
        completed++;
      } else if (isDayScheduled) {
        missed++;
      }
    }

    final divisor = dailyProgress.isNotEmpty ? dailyProgress.length : 1;
    final avgProg = (totalProgressSum / divisor).round();
    final avgRating = (1.0 + 4.0 * (avgProg / 100)).clamp(1.0, 5.0);

    final totalScheduled = timeline.calculateTotalScheduledDays(createdAt);

    final consistencyScore = totalScheduled == 0 
        ? 0.0 
        : (completed / totalScheduled * 100).clamp(0.0, 100.0);

    final reward = RewardManager.calculate(
      progress: avgProg.toDouble(),
      rating: avgRating,
      pointsEarned: totalPoints,
      completedDays: completed,
      totalDays: totalScheduled,
      hoursPerDay: 0,
      taskStack: taskStack,
      source: RewardSource.weekTask,
      onTimeCompletion: true,
    );

    return WeeklySummary(
      weekId: '',
      rewardPackage: reward,
      penalty: null,
      progress: avgProg,
      pointsEarned: totalPoints,
      rating: double.parse(avgRating.toStringAsFixed(1)),
      consistencyScore: double.parse(consistencyScore.toStringAsFixed(1)),
      totalScheduledDays: totalScheduled,
      completedDays: completed,
      pendingGoalDays: missed,
      pendingDates: [],
      status: avgProg >= 90
          ? 'excellent'
          : (avgProg >= 70
                ? 'good'
                : (avgProg >= 40 ? 'needs_improvement' : 'failed')),
    );
  }

  Color get progressColor => CardColorHelper.getProgressColor(progress);

  List<Color> getGradientColors({required bool isDarkMode}) {
    return CardColorHelper.getTaskCardGradient(
      priority: 'medium',
      status: progress >= 100 ? 'completed' : 'inProgress',
      progress: progress,
      isDarkMode: isDarkMode,
    );
  }

  bool get hasWeeklyReward => rewardPackage?.earned ?? false;
  RewardTier get weeklyTier => rewardPackage?.tier ?? RewardTier.none;
  String get weeklyTagName => rewardPackage?.tagName ?? '';
  String get weeklyRewardDisplayName => rewardPackage?.rewardDisplayName ?? '';
  int get totalRewardsEarned => (rewardPackage?.earned ?? false) ? 1 : 0;
  double get completionRate =>
      totalScheduledDays == 0 ? 0 : (completedDays / totalScheduledDays) * 100;

  // Compatibility getters
  List<RewardPackage> get dailyRewards => [];
  List<RewardPackage> get allEarnedRewards => [];
  String get bestTag => '';
  RewardTier get bestTierEarned => RewardTier.none;

  static WeeklySummary get empty => const WeeklySummary(
    progress: 0,
    pointsEarned: 0,
    rating: 0,
    totalScheduledDays: 0,
    completedDays: 0,
    pendingGoalDays: 0,
    pendingDates: [],
    status: 'pending',
    bestDay: 'N/A',
    worstDay: 'N/A',
  );
}

// ================================================================
// PENALTY / SOCIAL / SHARE / POSTED
// ================================================================

class Penalty {
  final int penaltyPoints;
  final String reason;
  const Penalty({required this.penaltyPoints, required this.reason});
  Map<String, dynamic> toJson() => {
    'penalty_points': penaltyPoints,
    'reason': reason,
  };
  factory Penalty.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return Penalty(
      penaltyPoints: json['penalty_points'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class SocialInfo {
  final bool isPosted;
  final PostedInfo? posted;
  const SocialInfo({required this.isPosted, this.posted});
  Map<String, dynamic> toJson() => {
    'is_posted': isPosted,
    'posted': posted?.toJson(),
  };
  factory SocialInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return SocialInfo(
      isPosted: json['is_posted'] == true || json['is_posted'] == 1,
      posted: json['posted'] != null ? PostedInfo.fromJson(json['posted']) : null,
    );
  }
}

class PostedInfo {
  final String postId;
  final bool live;
  final String? snapshotUrl;
  final DateTime time;
  const PostedInfo({
    this.postId = '',
    required this.live,
    this.snapshotUrl,
    required this.time,
  });
  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'live': live,
    'snapshot_url': snapshotUrl,
    'posted_at': time.toIso8601String(),
  };
  factory PostedInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return PostedInfo(
      postId: json['post_id'] ?? '',
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: json['snapshot_url'],
      time: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'])
          : (json['time'] != null
                ? DateTime.parse(json['time'])
                : DateTime.now()),
    );
  }
}

class ShareInfo {
  final bool isShare;
  final SharedData? shareId;
  const ShareInfo({required this.isShare, this.shareId});
  Map<String, dynamic> toJson() => {
    'is_share': isShare,
    'share_id': shareId?.toJson(),
  };
  factory ShareInfo.fromJson(Map<String, dynamic> json) => ShareInfo(
    isShare: json['is_share'] ?? false,
    shareId: json['share_id'] != null
        ? SharedData.fromJson(json['share_id'])
        : null,
  );
  ShareInfo copyWith({bool? isShare, SharedData? shareId}) => ShareInfo(
    isShare: isShare ?? this.isShare,
    shareId: shareId ?? this.shareId,
  );
}

class SharedData {
  final bool live;
  final String snapshotUrl;
  final String withId;
  final DateTime time;
  const SharedData({
    required this.live,
    required this.snapshotUrl,
    required this.withId,
    required this.time,
  });
  Map<String, dynamic> toJson() => {
    'live': live,
    'snapshot_url': snapshotUrl,
    'with_id': withId,
    'time': time.toIso8601String(),
  };
  factory SharedData.fromJson(Map<String, dynamic> json) => SharedData(
    live: json['live'] ?? false,
    snapshotUrl: json['snapshot_url'] ?? '',
    withId: json['with_id'] ?? '',
    time: json['time'] != null ? DateTime.parse(json['time']) : DateTime.now(),
  );
  SharedData copyWith({
    bool? live,
    String? snapshotUrl,
    String? withId,
    DateTime? time,
  }) => SharedData(
    live: live ?? this.live,
    snapshotUrl: snapshotUrl ?? this.snapshotUrl,
    withId: withId ?? this.withId,
    time: time ?? this.time,
  );
}

// ================================================================
// EXTENSIONS
// ================================================================

extension WeekTaskRewardExtension on WeekTaskModel {
  RewardPackage get rewardPackage => calculateRewardPackage();
  bool get hasAnyReward => summary.totalRewardsEarned > 0;
  String get highestTierName {
    final info = RewardManager.getTierInfo(summary.weeklyTier);
    return info['name'] as String? ?? 'None';
  }

  Map<String, dynamic>? get nextTierInfo =>
      RewardManager.getNextTierInfo(summary.weeklyTier);
}

extension WeekTaskColorExtension on WeekTaskModel {
  Gradient getDynamicGradient(BuildContext context) {
    return CardColorHelper.getDynamicGradient(
      context,
      recordId: id,
      priority: indicators.priority,
      status: indicators.status,
      progress: summary.progress,
      rating: summary.rating,
      createdAt: createdAt,
      dueDate: timeline.expectedEndingDate,
    );
  }

  BoxDecoration getBoxDecoration(
    BuildContext context, {
    double borderRadius = 16.0,
  }) {
    return CardColorHelper.getCardDecoration(
      priority: indicators.priority,
      status: indicators.status,
      progress: summary.progress,
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      borderRadius: borderRadius,
    );
  }
}

// ================================================================
// HELPER FUNCTIONS
// ================================================================

List<T> _parseJsonbList<T>(
  dynamic v,
  T Function(Map<String, dynamic>) fromJson,
) {
  final json = _parseJsonbRaw(v);
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

Map<String, dynamic> _parseJsonb(dynamic v) {
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

dynamic _parseJsonbRaw(dynamic v) {
  if (v == null) return null;
  if (v is Map || v is List) return v;
  if (v is String && v.isNotEmpty) {
    try {
      return jsonDecode(v);
    } catch (_) {}
  }
  return v;
}

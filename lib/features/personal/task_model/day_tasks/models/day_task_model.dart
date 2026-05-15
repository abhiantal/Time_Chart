// ================================================================
// FILE: lib/features/day_task/models/day_task_model.dart
// FULLY INTEGRATED WITH REWARD MANAGER (8 TIERS) & CARD COLOR HELPER
// ================================================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';

export 'package:the_time_chart/reward_tags/reward_manager.dart'
    show RewardPackage, RewardTier, RewardColor;


/// Main Day Task Model with feedback tracking
class DayTaskModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryType;
  final String subTypes;
  final AboutTask aboutTask;
  final Indicators indicators;
  final Timeline timeline;
  final Feedback feedback;
  final Metadata metadata;
  final SocialInfo socialInfo;
  final ShareInfo shareInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayTaskModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryType,
    required this.subTypes,
    required this.aboutTask,
    required this.indicators,
    required this.timeline,
    required this.feedback,
    required this.metadata,
    required this.socialInfo,
    required this.shareInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  // ================================================================
  // FACTORY CONSTRUCTORS
  // ================================================================

  factory DayTaskModel.fromJson(Map<String, dynamic> json) => DayTaskModel(
        id: json['task_id'] ?? '',
        userId: json['user_id'] ?? '',
        categoryId: json['category_id'] ?? '',
        categoryType: json['category_type'] ?? '',
        subTypes: json['sub_types'] ?? '',
        aboutTask: AboutTask.fromJson(_parseJsonb(json['about_task'])),
        indicators: Indicators.fromJson(_parseJsonb(json['indicators'])),
        timeline: Timeline.fromJson(_parseJsonb(json['timeline'])),
        feedback: Feedback.fromJson(_parseJsonb(json['feedback'])),
        metadata: Metadata.fromJson(_parseJsonb(json['metadata'])),
        socialInfo: SocialInfo.fromJson(_parseJsonb(json['social_info'])),
        shareInfo: ShareInfo.fromJson(_parseJsonb(json['share_info'])),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );

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
    'metadata': metadata.toJson(),
    'social_info': socialInfo.toJson(),
    'share_info': shareInfo.toJson(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // ================================================================
  // COPY WITH
  // ================================================================

  DayTaskModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryType,
    String? subTypes,
    AboutTask? aboutTask,
    Indicators? indicators,
    Timeline? timeline,
    Feedback? feedback,
    Metadata? metadata,
    SocialInfo? socialInfo,
    ShareInfo? shareInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DayTaskModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    categoryType: categoryType ?? this.categoryType,
    subTypes: subTypes ?? this.subTypes,
    aboutTask: aboutTask ?? this.aboutTask,
    indicators: indicators ?? this.indicators,
    timeline: timeline ?? this.timeline,
    feedback: feedback ?? this.feedback,
    metadata: metadata ?? this.metadata,
    socialInfo: socialInfo ?? this.socialInfo,
    shareInfo: shareInfo ?? this.shareInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  // ================================================================
  // HELPER GETTERS
  // ================================================================

  /// Check if task is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(timeline.startingTime) &&
        now.isBefore(timeline.endingTime);
  }

  /// Check if task is overdue
  bool get isOverdue => timeline.overdue;

  /// Get feedback count
  int get feedbackCount => feedback.comments.length;

  /// Check if has any text feedback
  bool get hasTextFeedback => feedback.comments.any((c) => c.text.isNotEmpty);

  /// Get total media count across all feedbacks
  int get totalMediaCount => feedback.comments.where((c) => c.hasMedia).length;

  /// Check if task was on time (first feedback before endingTime)
  bool get isOnTime {
    if (feedback.comments.isEmpty) return false;
    return feedback.comments.first.timestamp.isBefore(timeline.endingTime);
  }

  /// Get timeline hours
  int get timelineHours =>
      timeline.endingTime.difference(timeline.startingTime).inHours;

  /// Calculate status based on timeline and progress
  String calculateStatus({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final hasFeedback = feedbackCount > 0;

    // Respect manual/system status overrides
    if (indicators.status == 'cancelled') return 'cancelled';
    if (indicators.status == 'skipped') return 'skipped';
    if (indicators.status == 'postponed') return 'postponed';
    if (indicators.status == 'completed' || metadata.isComplete) return 'completed';
    if (indicators.status == 'failed') return 'failed';
    if (indicators.status == 'hold') return 'hold';
    if (indicators.status == 'overdue') return 'overdue';

    // 1. Before endingTime: Task is never 'completed', always 'pending/upcoming/inProgress'
    if (currentTime.isBefore(timeline.endingTime)) {
      if (currentTime.isBefore(timeline.startingTime)) {
        final hoursUntilStart = timeline.startingTime.difference(currentTime).inHours;
        return hoursUntilStart <= 1 ? 'upcoming' : 'pending';
      }
      return 'inProgress';
    }

    // 2. After endingTime: Check for feedback to determine completion
    if (hasFeedback) {
      return 'completed';
    }

    // 3. After endingTime, no feedback: Mark as overdue or failed/missed
    final taskDate = DateTime.parse(timeline.taskDate);
    final isSameDay = currentTime.year == taskDate.year && 
                      currentTime.month == taskDate.month && 
                      currentTime.day == taskDate.day;
    
    // Check if it's past 23:59 on the task date
    final endOfDay = DateTime(taskDate.year, taskDate.month, taskDate.day, 23, 59, 59);
    if (currentTime.isAfter(endOfDay)) {
      return indicators.priority == 'high' ? 'failed' : 'missed';
    }

    if (isSameDay) {
      return 'overdue';
    }
    
    return indicators.priority == 'high' ? 'failed' : 'missed';
  }

  /// Evaluate the task and return a structured JSON breakdown
  Map<String, dynamic> evaluateTask({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final taskDate = DateTime.parse(timeline.taskDate);
    final endOfDay = DateTime(taskDate.year, taskDate.month, taskDate.day, 23, 59, 59);

    // STEP 1 — MISSED TASK CHECK
    // If no feedback till 11:59 PM (date change)
    if (feedback.comments.isEmpty && currentTime.isAfter(endOfDay)) {
      return {
        "status": "missed",
        "penalty": 100,
        "points_earned": 0,
        "final_score": -100,
        "rating": 0.0,
        "progress": 0,
      };
    }

    // STEP 2 — COMPLETION STATUS
    // If task has any feedback (even one) -> completed
    final isCompleted = feedback.comments.isNotEmpty;
    final status = isCompleted ? "completed" : "missed";

    // STEP 3 & 4 — CALCULATE points_earned (positive only)
    int feedbackPoints = 0;
    int mediaPoints = 0;
    int textPoints = 0;
    
    List<Map<String, dynamic>> feedbackVerification = [];
    int passFeedbackCount = 0;
    
    for (int i = 0; i < feedback.comments.length; i++) {
      final comment = feedback.comments[i];
      // Only PASS feedbacks contribute positive points
      final isPass = comment.isPass; 
      
      feedbackVerification.add({
        "feedbackIndex": i,
        "result": isPass ? "PASS" : "FAIL",
        "reason": comment.verificationReason ?? (isPass ? "Verified" : "Irrelevant content"),
      });

      if (isPass) {
        passFeedbackCount++;
        feedbackPoints += 5;
        
        // 2) Media / Text
        // total media count × 5
        // We assume mediaUrl is a single URL, but if it was a list we'd count them.
        if (comment.hasMedia) {
          mediaPoints += 5; 
        }
        
        // word count × 3
        final words = comment.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        textPoints += words * 3;
      }
    }

    // 3) Priority
    int priorityPoints = 0;
    switch (indicators.priority.toLowerCase()) {
      case 'high': priorityPoints = 15; break;
      case 'medium': priorityPoints = 10; break;
      case 'low': priorityPoints = 5; break;
    }

    // 4) On Time
    // +20 (between starting and ending time, inclusive)
    int onTimeBonus = 0;
    if (timeline.completionTime != null) {
      final compTime = timeline.completionTime!;
      final start = timeline.startingTime;
      final end = timeline.endingTime;
      if ((compTime.isAfter(start) || compTime.isAtSameMomentAs(start)) &&
          (compTime.isBefore(end) || compTime.isAtSameMomentAs(end))) {
        onTimeBonus = 20;
      }
    }

    // 5) Completion Duration (scheduled task duration d)
    final duration = timeline.endingTime.difference(timeline.startingTime);
    final d = duration.inMinutes / 60.0; // duration in hours
    int durationPoints = 0;
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

    // STEP 5 — CALCULATE penalty (negative only)
    
    // Feedback Slot Penalties: Every 20 minutes = 1 feedback slot
    int slotPenalty = 0;
    List<Map<String, dynamic>> slotBreakdown = [];
    
    final totalTaskMinutes = timeline.endingTime.difference(timeline.startingTime).inMinutes;
    final totalSlots = (totalTaskMinutes / 20).floor();
    
    for (int n = 1; n <= totalSlots; n++) {
      final slotEnd = timeline.startingTime.add(Duration(minutes: n * 20));
      // User must submit feedback within a 2–4 minute window inside that slot
      // Based on example: 18 -> 22 min for slot at 20 min.
      final windowStart = slotEnd.subtract(const Duration(minutes: 2));
      final windowEnd = slotEnd.add(const Duration(minutes: 2));
      
      bool submitted = feedback.comments.any((c) => 
        (c.timestamp.isAtSameMomentAs(windowStart) || c.timestamp.isAfter(windowStart)) && 
        (c.timestamp.isAtSameMomentAs(windowEnd) || c.timestamp.isBefore(windowEnd)));
      
      int penalty = submitted ? 0 : 10;
      slotPenalty += penalty;
      
      slotBreakdown.add({
        "slot": n,
        "windowStart": windowStart.toIso8601String(),
        "windowEnd": windowEnd.toIso8601String(),
        "submitted": submitted,
        "penalty": penalty,
      });
    }

    // 6) Overdue: -10 points per full hour
    // Applies if end time passed and user did not give any feedback
    int overduePenalty = 0;
    if (currentTime.isAfter(timeline.endingTime) && (feedback.comments.isEmpty || timeline.overdue)) {
      final durationOverdue = currentTime.difference(timeline.endingTime);
      final hoursOverdue = durationOverdue.inHours;
      overduePenalty = hoursOverdue * 10;
      
      // Stop accruing once date changes
      if (currentTime.isAfter(endOfDay)) {
        final maxOverdueDuration = endOfDay.difference(timeline.endingTime);
        overduePenalty = maxOverdueDuration.inHours * 10;
      }
    }

    int totalPenalty = slotPenalty + overduePenalty;

    // If task is missed (Step 7 rules), penalty is -100 total (as specified in rule 7)
    if (status == "missed" && currentTime.isAfter(endOfDay)) {
      totalPenalty = 100;
      totalPointsEarned = 0;
    }

    // STEP 6 — FINAL SCORE
    int finalScore = totalPointsEarned - totalPenalty;

    // STEP 7 — RATING & PROGRESS
    double rating = 0.0;
    int progress = 0;
    
    if (finalScore <= 0) { rating = 0.0; progress = 0; }
    else if (finalScore <= 20) { rating = 1.0; progress = 10; }
    else if (finalScore <= 50) { rating = 2.0; progress = 30; }
    else if (finalScore <= 100) { rating = 3.0; progress = 55; }
    else if (finalScore <= 150) { rating = 4.0; progress = 75; }
    else if (finalScore <= 200) { rating = 4.5; progress = 88; }
    else { rating = 5.0; progress = 100; }

    return {
      "status": status,
      "points_earned": totalPointsEarned,
      "penalty": totalPenalty,
      "final_score": finalScore,
      "rating": rating,
      "progress": progress,
      "feedbackVerification": feedbackVerification,
      "slotBreakdown": slotBreakdown,
      "breakdown": {
        "feedbackPoints": feedbackPoints,
        "mediaPoints": mediaPoints,
        "textPoints": textPoints,
        "priorityPoints": priorityPoints,
        "onTimeBonus": onTimeBonus,
        "durationPoints": durationPoints,
        "slotPenalty": slotPenalty,
        "overduePenalty": overduePenalty
      }
    };
  }

  /// Recalculate all metrics using the new evaluation engine
  DayTaskModel recalculate({DateTime? now}) {
    final evaluation = evaluateTask(now: now);
    
    // Update metadata
    final newMetadata = metadata.copyWith(
      progress: evaluation['progress'],
      pointsEarned: evaluation['points_earned'],
      rating: evaluation['rating'],
      penalty: PenaltyInfo(
        penaltyPoints: evaluation['penalty'], 
        reason: 'Evaluation calculated based on feedback and timeline',
      ),
      isComplete: evaluation['status'] == 'completed',
      breakdown: evaluation['breakdown'],
    );

    var updatedTask = copyWith(
      metadata: newMetadata,
      updatedAt: DateTime.now(),
    );

    // Also update reward package
    updatedTask = updatedTask.copyWith(
      metadata: updatedTask.metadata.copyWith(
        rewardPackage: updatedTask.calculateRewardPackage(),
      ),
    );

    return updatedTask;
  }




  // ================================================================
  // REWARD MANAGER INTEGRATION - NEW UNIFIED SYSTEM
  // ================================================================

  /// Calculate complete RewardPackage (Tag + Reward together)
  RewardPackage calculateRewardPackage() {
    return RewardManager.forDayTask(
      feedbackCount: feedbackCount,
      hasText: hasTextFeedback,
      isComplete: metadata.isComplete,
      isOverdue: timeline.overdue,
      timelineHours: timelineHours,
    );
  }

  /// Quick check if any reward was earned
  bool get hasEarnedReward => calculateRewardPackage().earned;

  /// Get the reward tier
  RewardTier get rewardTier => calculateRewardPackage().tier;

  /// Calculate overdue penalty (-10 points per full hour past endingTime)
  int calculateOverduePenalty() {
    final now = DateTime.now();
    // If completed, use completion time, else use now for live calculation
    final endTime = timeline.completionTime ?? now;

    if (endTime.isBefore(timeline.endingTime)) return 0;

    final overdueDuration = endTime.difference(timeline.endingTime);
    final overdueHours = overdueDuration.inHours;

    return (overdueHours * 10).clamp(0, 100);
  }

  /// Calculate total points with all bonuses and penalties
  int calculatePoints() {
    return evaluateTask()['points_earned'];
  }

  /// Calculate combined penalty
  int calculatePenalty() {
    return evaluateTask()['penalty'];
  }


  /// Calculate penalty for missed updates based on gaps in feedback
  int _calculateMissedUpdatePenalty() {
    if (feedbackCount < 2) return 0;

    int penalty = 0;
    // Sort comments by timestamp
    final sortedComments = [...feedback.comments]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < sortedComments.length - 1; i++) {
      final gap = sortedComments[i + 1].timestamp.difference(sortedComments[i].timestamp).inHours;
      if (gap >= 4) {
        final periods = gap ~/ 4;
        penalty += periods * 20;
      }
    }

    return penalty;
  }

  /// Calculate rating based on progress
  /// Calculate rating based on progress
  double calculateRating(double progress) {
    return (1.0 + 4.0 * (progress / 100)).clamp(1.0, 5.0);
  }

  /// Calculate progress based on points and penalties
  double calculateProgress() {
    final points = calculatePoints();
    return (points.toDouble()).clamp(0.0, 100.0);
  }





  /// Get card gradient colors
  List<Color> getCardGradient({required bool isDarkMode}) {
    return CardColorHelper.getTaskCardGradient(
      priority: indicators.priority,
      status: calculateStatus(),
      progress: metadata.progress,
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
      status: calculateStatus(),
      progress: metadata.progress,
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }

  /// Get status color
  Color get statusColor => CardColorHelper.getStatusColor(calculateStatus());

  /// Get priority color
  Color get priorityColor =>
      CardColorHelper.getPriorityColor(indicators.priority);

  /// Get priority gradient (for UI consistency)
  List<Color> get priorityGradient {
    switch (indicators.priority.toLowerCase()) {
      case 'high':
        return [Colors.red, Colors.orange];
      case 'medium':
        return [Colors.orange, Colors.yellow];
      case 'low':
        return [Colors.green, Colors.teal];
      default:
        return [Colors.blue, Colors.purple];
    }
  }

  /// Check if reward should be shown
  bool get shouldShowReward {
    if (!metadata.isComplete) return false;
    if (metadata.pointsEarned < 10) return false;
    return metadata.rewardPackage?.earned ?? false;
  }

  /// Get progress color
  Color get progressColor =>
      CardColorHelper.getProgressColor(metadata.progress);
}

// ================================================================
// ABOUT TASK
// ================================================================

class AboutTask {
  final String taskName;
  final String? taskDescription;
  final String? mediaUrl;

  AboutTask({required this.taskName, this.taskDescription, this.mediaUrl});

  factory AboutTask.fromJson(dynamic json) {
    final map = _parseJsonb(json);
    return AboutTask(
      taskName: map['task_name'] ?? '',
      taskDescription: map['task_description'],
      mediaUrl: map['media_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'task_name': taskName,
    'task_description': taskDescription,
    'media_url': mediaUrl,
  };

  AboutTask copyWith({
    String? taskName,
    String? taskDescription,
    String? mediaUrl,
  }) => AboutTask(
    taskName: taskName ?? this.taskName,
    taskDescription: taskDescription ?? this.taskDescription,
    mediaUrl: mediaUrl ?? this.mediaUrl,
  );
}

// ================================================================
// INDICATORS
// ================================================================

class Indicators {
  final String status;
  final String priority;

  Indicators({required this.status, required this.priority});

  factory Indicators.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return Indicators(
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {'status': status, 'priority': priority};

  Indicators copyWith({String? status, String? priority}) => Indicators(
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );

  /// Get status color
  Color get statusColor => CardColorHelper.getStatusColor(status);

  /// Get priority color
  Color get priorityColor => CardColorHelper.getPriorityColor(priority);
}

// ================================================================
// TIMELINE
// ================================================================

class Timeline {
  final String taskDate;
  final DateTime startingTime;
  final DateTime endingTime;
  final DateTime? completionTime;
  final bool overdue;
  final bool isUnspecified;

  Timeline({
    required this.taskDate,
    required this.startingTime,
    required this.endingTime,
    this.completionTime,
    required this.overdue,
    required this.isUnspecified,
  });

  factory Timeline.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return Timeline(
      taskDate: json['task_date'] ?? '',
      startingTime: json['starting_time'] != null
          ? DateTime.parse(json['starting_time']).toLocal()
          : DateTime.now(),
      endingTime: json['ending_time'] != null
          ? DateTime.parse(json['ending_time']).toLocal()
          : DateTime.now(),
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time']).toLocal()
          : null,
      overdue: json['overdue'] == true || json['overdue'] == 1,
      isUnspecified: json['is_unspecified'] == true || json['is_unspecified'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'task_date': taskDate,
    'starting_time': startingTime.toUtc().toIso8601String(),
    'ending_time': endingTime.toUtc().toIso8601String(),
    'completion_time': completionTime?.toUtc().toIso8601String(),
    'overdue': overdue,
    'is_unspecified': isUnspecified,
  };

  Timeline copyWith({
    String? taskDate,
    DateTime? startingTime,
    DateTime? endingTime,
    DateTime? completionTime,
    bool? overdue,
    bool? isUnspecified,
  }) => Timeline(
    taskDate: taskDate ?? this.taskDate,
    startingTime: startingTime ?? this.startingTime,
    endingTime: endingTime ?? this.endingTime,
    completionTime: completionTime ?? this.completionTime,
    overdue: overdue ?? this.overdue,
    isUnspecified: isUnspecified ?? this.isUnspecified,
  );

  /// Get duration
  Duration get duration => endingTime.difference(startingTime);

  /// Get remaining time
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endingTime)) return Duration.zero;
    return endingTime.difference(now);
  }

  /// Get elapsed time
  Duration get elapsedTime {
    final now = DateTime.now();
    if (now.isBefore(startingTime)) return Duration.zero;
    if (now.isAfter(endingTime)) return duration;
    return now.difference(startingTime);
  }

  /// Get progress percentage based on time
  double get timeProgress {
    if (duration.inMinutes == 0) return 0;
    return (elapsedTime.inMinutes / duration.inMinutes * 100).clamp(0, 100);
  }

  /// Is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startingTime) && now.isBefore(endingTime);
  }

  /// Is completed
  bool get isCompleted => completionTime != null;

  /// Was completed on time
  bool get wasCompletedOnTime =>
      completionTime != null && completionTime!.isBefore(endingTime);
}

// ================================================================
// FEEDBACK
// ================================================================

class Feedback {
  final List<Comment> comments;

  Feedback({required this.comments});

  factory Feedback.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    if (json.isEmpty) return Feedback(comments: []);

    final rawComments = json['comments'] ?? json['items'];

    return Feedback(
      comments: _parseJsonbList(
        rawComments,
        (e) => Comment.fromJson(e),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'comments': {'items': comments.map((c) => c.toJson()).toList()},
  };

  Feedback copyWith({List<Comment>? comments}) =>
      Feedback(comments: comments ?? this.comments);

  /// Get total feedback count
  int get count => comments.length;

  /// Check if has any text
  bool get hasText => comments.any((c) => c.text.isNotEmpty);

  /// Check if has any media
  bool get hasMedia => comments.any((c) => c.mediaUrl != null);

  /// Get last comment
  Comment? get lastComment => comments.isNotEmpty ? comments.last : null;

  /// Add a new comment
  Feedback addComment(Comment comment) =>
      copyWith(comments: [...comments, comment]);
}

// ================================================================
// COMMENT
// ================================================================

class Comment {
  final String feedbackNumber;
  final String text;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isPass;
  final String? verificationReason;

  Comment({
    required this.feedbackNumber,
    required this.text,
    this.mediaUrl,
    DateTime? timestamp,
    this.isPass = true,
    this.verificationReason,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Comment.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return Comment(
      feedbackNumber: json['feedback_number'] ?? '',
      text: json['text'] ?? '',
      mediaUrl: json['media_url'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp']).toLocal()
          : DateTime.now(),
      isPass: json['is_pass'] == true || json['is_pass'] == null,
      verificationReason: json['verification_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'feedback_number': feedbackNumber,
      'text': text,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'is_pass': isPass,
      'verification_reason': verificationReason,
    };

    if (mediaUrl != null) {
      json['media_url'] = mediaUrl;
    }

    return json;
  }

  Comment copyWith({
    String? feedbackNumber,
    String? text,
    String? mediaUrl,
    DateTime? timestamp,
    bool? isPass,
    String? verificationReason,
  }) => Comment(
    feedbackNumber: feedbackNumber ?? this.feedbackNumber,
    text: text ?? this.text,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    timestamp: timestamp ?? this.timestamp,
    isPass: isPass ?? this.isPass,
    verificationReason: verificationReason ?? this.verificationReason,
  );

  /// Has media attachment
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Has text content
  bool get hasText => text.isNotEmpty;
}



// ================================================================
// METADATA - Integrated with RewardPackage
// ================================================================

class Metadata {
  final RewardPackage? rewardPackage;
  final PenaltyInfo? penalty;
  final int progress;
  final int pointsEarned;
  final double rating;
  final String taskColor;
  final bool isComplete;
  final String? summary;
  final Map<String, dynamic>? breakdown;

  Metadata({
    this.rewardPackage,
    this.penalty,
    required this.progress,
    required this.pointsEarned,
    required this.rating,
    required this.taskColor,
    required this.isComplete,
    this.summary,
    this.breakdown,
  });

  factory Metadata.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    RewardPackage? rewardPackage;
    if (json['reward_package'] != null) {
      rewardPackage = RewardPackage.fromJson(_parseJsonb(json['reward_package']));
    }

    return Metadata(
      rewardPackage: rewardPackage,
      penalty: json['penalty'] != null
          ? PenaltyInfo.fromJson(json['penalty'])
          : null,
      progress: json['progress'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      taskColor: json['task_color'] ?? '#667EEA',
      isComplete: json['is_complete'] == true || json['is_complete'] == 1,
      summary: json['summary'],
      breakdown: json['breakdown'] != null ? Map<String, dynamic>.from(json['breakdown']) : null,
    );
  }

  /// Get reward emoji based on package
  String get rewardEmoji {
    if (rewardPackage == null || !rewardPackage!.earned) return '💎';
    return kTierRegistry[rewardPackage!.tier]?.emoji ?? '💎';
  }


  Map<String, dynamic> toJson() => {
    'reward_package': rewardPackage?.toJson(),
    'penalty': penalty?.toJson(),
    'progress': progress,
    'points_earned': pointsEarned,
    'rating': rating,
    'task_color': taskColor,
    'is_complete': isComplete,
    'summary': summary,
    'breakdown': breakdown,
  };

  Metadata copyWith({
    RewardPackage? rewardPackage,
    PenaltyInfo? penalty,
    int? progress,
    int? pointsEarned,
    double? rating,
    String? taskColor,
    bool? isComplete,
    String? summary,
    Map<String, dynamic>? breakdown,
  }) => Metadata(
    rewardPackage: rewardPackage ?? this.rewardPackage,
    penalty: penalty ?? this.penalty,
    progress: progress ?? this.progress,
    pointsEarned: pointsEarned ?? this.pointsEarned,
    rating: rating ?? this.rating,
    taskColor: taskColor ?? this.taskColor,
    isComplete: isComplete ?? this.isComplete,
    summary: summary ?? this.summary,
    breakdown: breakdown ?? this.breakdown,
  );


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

  // ================================================================
  // COLOR HELPERS
  // ================================================================

  /// Get progress color
  Color get progressColor => CardColorHelper.getProgressColor(progress);

  /// Get tier color based on reward
  Color get tierColor {
    if (rewardPackage == null || !rewardPackage!.earned) {
      return CardColorHelper.getProgressColor(progress);
    }
    return rewardPackage!.primaryColor;
  }

  /// Get task color as Color object
  Color get color {
    try {
      final hex = taskColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF667EEA);
    }
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

  static Metadata get empty => Metadata(
    progress: 0,
    pointsEarned: 0,
    rating: 0,
    taskColor: '#667EEA',
    isComplete: false,
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
    final json = _parseJsonb(v);
    return PenaltyInfo(
      penaltyPoints: json['penalty_points'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'penalty_points': penaltyPoints,
    'reason': reason,
  };

  PenaltyInfo copyWith({int? penaltyPoints, String? reason}) => PenaltyInfo(
    penaltyPoints: penaltyPoints ?? this.penaltyPoints,
    reason: reason ?? this.reason,
  );
}

// ================================================================
// SOCIAL INFO
// ================================================================

class SocialInfo {
  final bool isPosted;
  final PostedInfo? posted;

  SocialInfo({required this.isPosted, this.posted});

  factory SocialInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return SocialInfo(
      isPosted: json['is_posted'] == true || json['is_posted'] == 1,
      posted: json['posted'] != null ? PostedInfo.fromJson(json['posted']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_posted': isPosted,
    'posted': posted?.toJson(),
  };

  SocialInfo copyWith({bool? isPosted, PostedInfo? posted}) => SocialInfo(
    isPosted: isPosted ?? this.isPosted,
    posted: posted ?? this.posted,
  );
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
  final DaySharedInfo? shareId;

  const ShareInfo({required this.isShare, this.shareId});

  factory ShareInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return ShareInfo(
      isShare: json['is_share'] == true || json['is_share'] == 1,
      shareId: json['share_id'] != null
          ? DaySharedInfo.fromJson(json['share_id'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_share': isShare,
    'share_id': shareId?.toJson(),
  };

  ShareInfo copyWith({bool? isShare, DaySharedInfo? shareId}) => ShareInfo(
    isShare: isShare ?? this.isShare,
    shareId: shareId ?? this.shareId,
  );
}

// ================================================================
// DAY SHARED INFO
// ================================================================

class DaySharedInfo {
  final bool live;
  final String snapshotUrl;
  final String withId;
  final DateTime time;

  const DaySharedInfo({
    required this.live,
    required this.snapshotUrl,
    required this.withId,
    required this.time,
  });

  factory DaySharedInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DaySharedInfo(
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: json['snapshot_url'] ?? '',
      withId: json['with_id'] ?? '',
      time: json['time'] != null ? DateTime.parse(json['time']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'live': live,
    'snapshot_url': snapshotUrl,
    'with_id': withId,
    'time': time.toIso8601String(),
  };

  DaySharedInfo copyWith({
    bool? live,
    String? snapshotUrl,
    String? withId,
    DateTime? time,
  }) => DaySharedInfo(
    live: live ?? this.live,
    snapshotUrl: snapshotUrl ?? this.snapshotUrl,
    withId: withId ?? this.withId,
    time: time ?? this.time,
  );
}

// ================================================================
// EXTENSION FOR REWARD HELPER
// ================================================================

extension DayTaskRewardExtension on DayTaskModel {
  /// Get the complete reward package
  RewardPackage get rewardPackage => calculateRewardPackage();

  /// Check if task has any reward
  bool get hasAnyReward => metadata.hasReward;

  /// Get reward box data for PremiumRewardBox widget
  Map<String, dynamic> getRewardBoxData() {
    final package = calculateRewardPackage();

    return {
      'taskId': id,
      'taskType': 'dayTask',
      'taskTitle': aboutTask.taskName,
      'rewardPackage': package,
    };
  }

  /// Get highest tier name
  String get tierName {
    final tierInfo = RewardManager.getTierInfo(metadata.tier);
    return tierInfo['name'] as String? ?? 'None';
  }

  /// Get next tier info
  Map<String, dynamic>? get nextTierInfo {
    return RewardManager.getNextTierInfo(metadata.tier);
  }
}

extension DayTaskColorExtension on DayTaskModel {
  /// Get dynamic gradient based on context
  Gradient getDynamicGradient(BuildContext context) {
    return CardColorHelper.getDynamicGradient(
      context,
      recordId: id,
      priority: indicators.priority,
      status: indicators.status,
      progress: metadata.progress,
      rating: metadata.rating,
      createdAt: createdAt,
      dueDate: timeline.endingTime,
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
// HELPER FUNCTIONS

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

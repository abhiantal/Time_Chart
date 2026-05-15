import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import '../../../../helpers/card_color_helper.dart';

class BucketModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String? categoryType;
  final String? subTypes;
  final String title;
  final BucketDetails details;
  final List<ChecklistItem> checklist;
  final BucketTimeline timeline;

  final BucketMetadata metadata;
  final SocialInfo? socialInfo;
  final ShareInfo? shareInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Backward compatibility
  String get bucketId => id;

  BucketModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categoryType,
    this.subTypes,
    required this.title,
    required this.details,
    this.checklist = const [],
    required this.timeline,
    required this.metadata,
    this.socialInfo,
    this.shareInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted {
    if (checklist.isEmpty) return false;
    // Marked completed if all checklist items have at least one feedback
    return checklist.every((item) => item.feedbacks.isNotEmpty);
  }

  // ==============================================================================
  // 1. INTEGRATION: COLORS & REWARDS CALCULATION
  // ==============================================================================

  /// Calculates Rewards, Tags, and Performance Metrics from checklist, then returns a fully updated BucketModel.
  BucketModel recalculateRewards() {
    final int completedItems = checklist.where((c) => c.done).length;
    final int totalItems = checklist.isEmpty ? 1 : checklist.length;

    // 1. Points Earned (Positive)
    int pointsEarned = 0;

    // feedbackBase: Each feedback entry across all items counts for 5 points
    int totalFeedbacks = 0;
    int totalMediaCount = 0;
    int totalWordCount = 0;

    for (var item in checklist) {
      totalFeedbacks += item.feedbacks.length;
      for (var fb in item.feedbacks) {
        totalMediaCount += fb.mediaUrls.length;
        totalWordCount += fb.text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
      }
      // checklist item completion bonus: +50 per item
      if (item.done) pointsEarned += 50;
    }

    pointsEarned += totalFeedbacks * 5;
    pointsEarned += totalMediaCount * 5;
    pointsEarned += totalWordCount * 8;

    // Priority bonus
    int priorityBonus = 0;
    switch (metadata.priority.toLowerCase()) {
      case 'low': priorityBonus = 5; break;
      case 'medium': priorityBonus = 10; break;
      case 'high': priorityBonus = 15; break;
    }
    pointsEarned += priorityBonus;

    // On Time Bonus: +200
    bool isOnTime = timeline.dueDate != null &&
        (timeline.completeDate ?? DateTime.now()).isBefore(timeline.dueDate!.add(const Duration(days: 1)));
    if (isCompleted && isOnTime) {
      pointsEarned += 200;
    }

    // 2. Penalties (Negative)
    int totalPenalties = 0;

    // Overdue Penalty: -20 per full day if end date passed and completed
    if (timeline.dueDate != null && isCompleted && timeline.completeDate != null) {
      if (timeline.completeDate!.isAfter(timeline.dueDate!)) {
        final overdueDays = timeline.completeDate!.difference(timeline.dueDate!).inDays;
        totalPenalties += overdueDays * 20;
      }
    }

    // Missed/Failed: -200 if not completed by last day of the year
    final now = DateTime.now();
    final lastDayOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    if (now.isAfter(lastDayOfYear) && !isCompleted) {
      totalPenalties += 200;
    }

    // 3. Final Calculation
    final int finalScore = pointsEarned - totalPenalties;
    final double newProgress = (completedItems / totalItems * 100).clamp(0, 100).toDouble();
    final double newRating = (1.0 + 4.0 * (finalScore / 1000).clamp(0.0, 1.0)).clamp(1.0, 5.0);

    // Call RewardManager.calculate
    final package = RewardManager.calculate(
      progress: newProgress,
      rating: newRating,
      pointsEarned: finalScore,
      completedDays: completedItems,
      totalDays: totalItems,
      hoursPerDay: 0,
      taskStack: 0,
      source: RewardSource.bucket,
      onTimeCompletion: isOnTime && isCompleted,
    );

    return copyWith(
      metadata: metadata.copyWith(
        averageRating: newRating,
        averageProgress: newProgress,
        totalPointsEarned: finalScore,
        rewardPackage: package,
      ),
    );
  }

  // ==============================================================================
  // 2. CONVENIENCE GETTERS FOR REWARDS
  // ==============================================================================
  bool get hasReward => metadata.rewardPackage?.earned ?? false;
  String get tagName => metadata.rewardPackage?.tagName ?? '';
  String get rewardDisplayName =>
      metadata.rewardPackage?.rewardDisplayName ?? '';
  RewardTier get tier => metadata.rewardPackage?.tier ?? RewardTier.none;
  RewardPackage? get rewardPackage => metadata.rewardPackage;

  // ==============================================================================
  // 3. CONVENIENCE GETTERS FOR COLORS (Computed on-the-fly using CardColorHelper)
  // ==============================================================================

  /// Get gradient colors for this bucket's card
  List<Color> getCardGradient({required bool isDarkMode}) {
    final status = _getDerivedStatus();
    return CardColorHelper.getTaskCardGradient(
      priority: metadata.priority,
      status: status,
      progress: metadata.averageProgress.toInt(),
      isDarkMode: isDarkMode,
    );
  }

  /// Get BoxDecoration for bucket card
  BoxDecoration getCardDecoration({
    required bool isDarkMode,
    double borderRadius = 16.0,
  }) {
    final status = _getDerivedStatus();
    return CardColorHelper.getCardDecoration(
      priority: metadata.priority,
      status: status,
      progress: metadata.averageProgress.toInt(),
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }

  /// Get single color for priority
  Color get priorityColor =>
      CardColorHelper.getPriorityColor(metadata.priority);

  /// Get single color for progress (e.g., for checklist items)
  Color get progressColor =>
      CardColorHelper.getProgressColor(metadata.averageProgress.toInt());

  /// Get status color for the bucket
  Color get statusColor {
    final status = _getDerivedStatus();
    return CardColorHelper.getStatusColor(status);
  }

  /// Internal helper for derived status (for color logic)
  String _getDerivedStatus() {
    if (isCompleted) return 'completed';
    if (timeline.dueDate != null && DateTime.now().isAfter(timeline.dueDate!)) {
      return 'missed';
    }
    if (metadata.averageProgress > 0) return 'inprogress';
    return 'pending';
  }

  // ==============================================================================
  // SERIALIZATION & FACTORY
  // ==============================================================================

  factory BucketModel.fromJson(Map<String, dynamic> json) {
    return BucketModel(
      id: json['id']?.toString() ?? json['bucket_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryType: json['category_type']?.toString(),
      subTypes: json['sub_types']?.toString(),
      title: json['title']?.toString() ?? '',
      details: BucketDetails.fromJson(_parseJsonb(json['details'])),
      checklist: _parseJsonbList(
        json['checklist'],
        (m) => ChecklistItem.fromJson(m),
      ),
      timeline: BucketTimeline.fromJson(_parseJsonb(json['timeline'])),
      metadata: BucketMetadata.fromJson(_parseJsonb(json['metadata'])),
      socialInfo: json['social_info'] != null
          ? SocialInfo.fromJson(_parseJsonb(json['social_info']))
          : null,
      shareInfo: json['share_info'] != null
          ? ShareInfo.fromJson(_parseJsonb(json['share_info']))
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_type': categoryType,
      'sub_types': subTypes,
      'title': title,
      'details': details.toJson(),
      'checklist': checklist.map((c) => c.toJson()).toList(),
      'timeline': timeline.toJson(),
      'metadata': metadata.toJson(),
      'social_info': socialInfo?.toJson(),
      'share_info': shareInfo?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BucketModel copyWith({
    String? id,
    String? title,
    BucketDetails? details,
    List<ChecklistItem>? checklist,
    BucketTimeline? timeline,
    BucketMetadata? metadata,
    SocialInfo? socialInfo,
    ShareInfo? shareInfo,
  }) {
    return BucketModel(
      id: id ?? this.id,
      userId: userId,
      categoryId: categoryId,
      categoryType: categoryType,
      subTypes: subTypes,
      title: title ?? this.title,
      details: details ?? this.details,
      checklist: checklist ?? this.checklist,
      timeline: timeline ?? this.timeline,
      metadata: metadata ?? this.metadata,
      socialInfo: socialInfo ?? this.socialInfo,
      shareInfo: shareInfo ?? this.shareInfo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ==============================================================================
// 1. BUCKET METADATA (Aggregate Bucket Data)
// ==============================================================================
class BucketMetadata {
  final String priority;
  final double averageRating;
  final double averageProgress;
  final int totalPointsEarned;
  final RewardPackage? rewardPackage;
  final PerformanceSummary? summary;

  BucketMetadata({
    this.priority = 'medium',
    this.averageRating = 0.0,
    this.averageProgress = 0.0,
    this.totalPointsEarned = 0,
    this.rewardPackage,
    this.summary,
  });

  factory BucketMetadata.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return BucketMetadata(
      priority: json['priority']?.toString() ?? 'medium',
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      averageProgress: (json['average_progress'] ?? 0).toDouble(),
      totalPointsEarned: (json['total_points_earned'] ?? 0).toInt(),
      rewardPackage: json['reward_package'] != null
          ? RewardPackage.fromJson(_parseJsonb(json['reward_package']))
          : null,
      summary: json['summary'] != null
          ? PerformanceSummary.fromJson(_parseJsonb(json['summary']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'average_rating': averageRating,
      'average_progress': averageProgress.round(),
      'total_points_earned': totalPointsEarned,
      'reward_package': rewardPackage?.toJson(),
      'summary': summary?.toJson(),
    };
  }

  BucketMetadata copyWith({
    String? priority,
    double? averageRating,
    double? averageProgress,
    int? totalPointsEarned,
    RewardPackage? rewardPackage,
    PerformanceSummary? summary,
  }) {
    return BucketMetadata(
      priority: priority ?? this.priority,
      averageRating: averageRating ?? this.averageRating,
      averageProgress: averageProgress ?? this.averageProgress,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      rewardPackage: rewardPackage ?? this.rewardPackage,
      summary: summary ?? this.summary,
    );
  }
}

// ==============================================================================
// SUPPORTING CLASSES
// ==============================================================================

class PerformanceSummary {
  final List<String> plan;
  final String summary;
  final String suggestion;

  PerformanceSummary({
    this.plan = const [],
    this.summary = '',
    this.suggestion = '',
  });

  factory PerformanceSummary.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return PerformanceSummary(
      plan: List<String>.from(json['plan'] ?? []),
      summary: json['summary']?.toString() ?? '',
      suggestion: json['suggestion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'plan': plan, 'summary': summary, 'suggestion': suggestion};
  }
}

// ================================================================
// REMAINING MODELS (Unchanged Structure)
// ================================================================

class BucketDetails {
  final String description;
  final String motivation;
  final String outCome;
  final List<String> mediaUrl;
  BucketDetails({
    required this.description,
    required this.motivation,
    required this.outCome,
    this.mediaUrl = const [],
  });
  factory BucketDetails.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return BucketDetails(
      description: json['description']?.toString() ?? '',
      motivation: json['motivation']?.toString() ?? '',
      outCome: (json['out_come'] ?? json['outcome'] ?? '')?.toString() ?? '',
      mediaUrl: _parseJsonbStringList(json['media_url']),
    );
  }
  Map<String, dynamic> toJson() => {
    'description': description,
    'motivation': motivation,
    'out_come': outCome,
    'media_url': mediaUrl,
  };
}

class ChecklistFeedback {
  final String id;
  final String text;
  final List<String> mediaUrls;
  final DateTime timestamp;
  final bool? isAiVerified;
  final String? aiFeedback;

  ChecklistFeedback({
    required this.id,
    required this.text,
    this.mediaUrls = const [],
    required this.timestamp,
    this.isAiVerified,
    this.aiFeedback,
  });

  factory ChecklistFeedback.fromJson(Map<String, dynamic> json) {
    return ChecklistFeedback(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      mediaUrls: _parseJsonbStringList(json['media_urls']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isAiVerified: json['is_ai_verified'] as bool?,
      aiFeedback: json['ai_feedback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'media_urls': mediaUrls,
        'timestamp': timestamp.toIso8601String(),
        'is_ai_verified': isAiVerified,
        'ai_feedback': aiFeedback,
      };

  ChecklistFeedback copyWith({
    String? id,
    String? text,
    List<String>? mediaUrls,
    DateTime? timestamp,
    bool? isAiVerified,
    String? aiFeedback,
  }) {
    return ChecklistFeedback(
      id: id ?? this.id,
      text: text ?? this.text,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      timestamp: timestamp ?? this.timestamp,
      isAiVerified: isAiVerified ?? this.isAiVerified,
      aiFeedback: aiFeedback ?? this.aiFeedback,
    );
  }
}

class ChecklistItem {
  final String id;
  final String task;
  final bool done;
  final List<ChecklistFeedback> feedbacks;
  final DateTime? date;
  final int points;

  ChecklistItem({
    required this.id,
    required this.task,
    this.done = false,
    this.feedbacks = const [],
    this.date,
    this.points = 0,
  });

  factory ChecklistItem.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return ChecklistItem(
      id: json['id']?.toString() ?? '',
      task: json['task']?.toString() ?? '',
      done: json['done'] == true || json['done'] == 1,
      feedbacks: _parseJsonbList(
        json['feedbacks'] ?? json['feedback'], // Handle migration if needed
        (m) => ChecklistFeedback.fromJson(m),
      ),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      points: (json['points'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'done': done,
        'feedbacks': feedbacks.map((f) => f.toJson()).toList(),
        'date': date?.toIso8601String(),
        'points': points,
      };

  ChecklistItem copyWith({
    String? id,
    String? task,
    bool? done,
    List<ChecklistFeedback>? feedbacks,
    DateTime? date,
    int? points,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      task: task ?? this.task,
      done: done ?? this.done,
      feedbacks: feedbacks ?? this.feedbacks,
      date: date ?? this.date,
      points: points ?? this.points,
    );
  }

  // Aggregate media for backward compatibility/quick display
  List<String> get allMedia => feedbacks.expand((f) => f.mediaUrls).toList();
}

class BucketTimeline {
  final bool isUnspecified;
  final DateTime addedDate;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completeDate;
  BucketTimeline({
    required this.isUnspecified,
    required this.addedDate,
    this.startDate,
    this.dueDate,
    this.completeDate,
  });
  factory BucketTimeline.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return BucketTimeline(
      isUnspecified: json['is_unspecified'] == true || json['is_unspecified'] == 1 || json['is_unspecified'] == null,
      addedDate: json['added_date'] != null
          ? DateTime.tryParse(json['added_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      completeDate: json['complete_date'] != null
          ? DateTime.tryParse(json['complete_date'].toString())
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
    'is_unspecified': isUnspecified,
    'added_date': addedDate.toIso8601String(),
    'start_date': startDate?.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'complete_date': completeDate?.toIso8601String(),
  };
  BucketTimeline copyWith({
    bool? isUnspecified,
    DateTime? addedDate,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? completeDate,
  }) {
    return BucketTimeline(
      isUnspecified: isUnspecified ?? this.isUnspecified,
      addedDate: addedDate ?? this.addedDate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      completeDate: completeDate ?? this.completeDate,
    );
  }
}

class SocialInfo {
  final bool isPosted;
  final PostedInfo? posted;
  SocialInfo({this.isPosted = false, this.posted});
  factory SocialInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return SocialInfo(
      isPosted: json['is_posted'] == true || json['is_posted'] == 1,
      posted: json['posted'] != null ? PostedInfo.fromJson(_parseJsonb(json['posted'])) : null,
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

class ShareInfo {
  final bool isShare;
  final BucketSharedInfo? shareId;
  ShareInfo({this.isShare = false, this.shareId});
  factory ShareInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return ShareInfo(
      isShare: json['is_share'] == true || json['is_share'] == 1,
      shareId: json['share_id'] != null
          ? BucketSharedInfo.fromJson(_parseJsonb(json['share_id']))
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
    'is_share': isShare,
    'share_id': shareId?.toJson(),
  };

  ShareInfo copyWith({bool? isShare, BucketSharedInfo? shareId}) {
    return ShareInfo(
      isShare: isShare ?? this.isShare,
      shareId: shareId ?? this.shareId,
    );
  }
}

class BucketSharedInfo {
  final String withId;
  final bool live;
  final String? snapshotUrl;
  final DateTime time;

  BucketSharedInfo({
    required this.withId,
    required this.live,
    this.snapshotUrl,
    required this.time,
  });

  factory BucketSharedInfo.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return BucketSharedInfo(
      withId: json['with_id']?.toString() ?? '',
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: json['snapshot_url']?.toString(),
      time: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'with_id': withId,
    'live': live,
    'snapshot_url': snapshotUrl,
    'posted_at': time.toIso8601String(),
  };

  BucketSharedInfo copyWith({
    String? withId,
    bool? live,
    String? snapshotUrl,
    DateTime? time,
  }) {
    return BucketSharedInfo(
      withId: withId ?? this.withId,
      live: live ?? this.live,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      time: time ?? this.time,
    );
  }
}

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
      postId: json['post_id']?.toString() ?? '',
      live: json['live'] == true || json['live'] == 1,
      snapshotUrl: json['snapshot_url']?.toString(),
      time: json['posted_at'] != null
          ? DateTime.tryParse(json['posted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'live': live,
    'snapshot_url': snapshotUrl,
    'posted_at': time.toIso8601String(),
  };
  String get withId => postId;

  PostedInfo copyWith({
    String? postId,
    bool? live,
    String? snapshotUrl,
    DateTime? time,
  }) {
    return PostedInfo(
      postId: postId ?? this.postId,
      live: live ?? this.live,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      time: time ?? this.time,
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

List<String> _parseJsonbStringList(dynamic v) {
  final json = _parseJsonbRaw(v);
  if (json is List) {
    return List<String>.from(json.map((e) => e.toString()));
  }
  if (json is Map && json.containsKey('items')) {
    return List<String>.from((json['items'] as List).map((e) => e.toString()));
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

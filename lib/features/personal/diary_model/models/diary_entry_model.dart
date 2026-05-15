// lib/features/diary/models/diary_entry_model.dart

import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../../media_utility/media_display.dart';
import '../../../../reward_tags/reward_manager.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';

class DiaryEntryModel {
  final String id;
  final String userId;
  final DateTime entryDate;
  final String? title;
  final String? content;

  final DiaryMood? mood;
  final List<DiaryQnA>? shotQna;
  final List<DiaryAttachment>? attachments;
  final DiaryLinkedItems? linkedItems;
  final DiaryMetadata? metadata;
  final DiarySettings? settings;
  final int entryNumber; // For sorting and tracking sequence

  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.entryDate,
    this.title,
    this.content,
    this.mood,
    this.shotQna,
    this.attachments,
    this.linkedItems,
    this.metadata,
    this.settings,
    this.entryNumber = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    return DiaryEntryModel(
      id: json['entry_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      entryDate: json['entry_date'] != null
          ? DateTime.tryParse(json['entry_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      mood: json['mood'] != null
          ? DiaryMood.fromJson(_parseJsonb(json['mood']))
          : null,
      shotQna: _parseJsonbList(
        json['shot_qna'],
        (e) => DiaryQnA.fromJson(e),
      ),
      attachments: _parseJsonbList(
        json['attachments'],
        (e) => DiaryAttachment.fromJson(e),
      ),
      linkedItems: json['linked_items'] != null
          ? DiaryLinkedItems.fromJson(_parseJsonb(json['linked_items']))
          : null,
      metadata: (json['metadata'] ?? json['metadata_info']) != null
          ? DiaryMetadata.fromJson(_parseJsonb(json['metadata'] ?? json['metadata_info']))
          : null,
      settings: json['settings'] != null
          ? DiarySettings.fromJson(_parseJsonb(json['settings']))
          : null,
      entryNumber: (json['entry_number'] ??
          json['entryNumber'] ??
          _parseJsonb(json['metadata'])['entry_number'] ??
          0) as int,
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
      'entry_id': id,
      'user_id': userId,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'title': title,
      'content': content,
      'mood': mood?.toJson(),
      'shot_qna': shotQna?.map((e) => e.toJson()).toList(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'linked_items': linkedItems?.toJson(),
      'metadata': metadata?.toJson(),
      'settings': settings?.toJson(),
      'entry_number': entryNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DiaryEntryModel copyWith({
    String? entryId,
    String? userId,
    DateTime? entryDate,
    String? title,
    String? content,
    DiaryMood? mood,
    List<DiaryQnA>? shotQna,
    List<DiaryAttachment>? attachments,
    DiaryLinkedItems? linkedItems,
    DiaryMetadata? metadata,
    DiarySettings? settings,
    int? entryNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntryModel(
      id: entryId ?? id,
      userId: userId ?? this.userId,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      shotQna: shotQna ?? this.shotQna,
      attachments: attachments ?? this.attachments,
      linkedItems: linkedItems ?? this.linkedItems,
      metadata: metadata ?? this.metadata,
      settings: settings ?? this.settings,
      entryNumber: entryNumber ?? this.entryNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ================================================================
  // CONVENIENCE GETTERS
  // ================================================================

  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasTitle => title != null && title!.isNotEmpty;
  bool get hasMood => mood != null && mood!.label != null;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  bool get hasQnA => shotQna != null && shotQna!.isNotEmpty;
  bool get isPrivate => settings?.isPrivate ?? true;
  bool get isFavorite => settings?.isFavorite ?? false;
  bool get isPinned => settings?.isPinned ?? false;

  int get wordCount => metadata?.wordCount ?? 0;
  String? get aiSummary => metadata?.aiSummary;

  // RewardPackage convenience getters
  bool get hasReward => metadata?.hasReward ?? false;
  String get tagName => metadata?.tagName ?? '';
  String get rewardDisplayName => metadata?.rewardDisplayName ?? '';
  RewardTier get tier => metadata?.tier ?? RewardTier.none;
  RewardPackage? get rewardPackage => metadata?.rewardPackage;

  // Card color convenience getter
  String? get taskColor => metadata?.taskColor;

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
    return '${months[entryDate.month - 1]} ${entryDate.day}, ${entryDate.year}';
  }

  // ================================================================
  // CARD GRADIENT HELPERS (using CardColorHelper)
  // ================================================================

  /// Get gradient colors for this diary entry's card
  List<Color> getCardGradient({required bool isDarkMode}) {
    // Use mood-based status mapping for diary entries
    final moodStatus = _getMoodBasedStatus();
    final moodPriority = calculatePriority(mood);

    return CardColorHelper.getTaskCardGradient(
      priority: metadata?.taskColor ?? moodPriority,
      status: moodStatus,
      progress: calculatedProgress,
      isDarkMode: isDarkMode,
    );
  }

  /// Get BoxDecoration for diary card
  BoxDecoration getCardDecoration({
    required bool isDarkMode,
    double borderRadius = 16.0,
  }) {
    return CardColorHelper.getCardDecoration(
      priority: metadata?.taskColor ?? calculatePriority(mood),
      status: _getMoodBasedStatus(),
      progress: calculatedProgress,
      isDarkMode: isDarkMode,
      borderRadius: borderRadius,
    );
  }

  /// Map mood rating to a status for color purposes
  String _getMoodBasedStatus() {
    if (mood == null) return 'pending';

    final rating = mood!.rating;
    if (rating >= 4) return 'completed';
    if (rating >= 3) return 'inprogress';
    if (rating >= 2) return 'upcoming';
    if (rating >= 1) return 'missed';
    return 'pending';
  }

  /// Map mood to priority for color variation
  static String calculatePriority(DiaryMood? mood) {
    if (mood == null) return 'medium';

    final rating = mood.rating;
    if (rating >= 5) return 'low'; // Happy/calm colors
    if (rating >= 4) return 'medium';
    if (rating >= 3) return 'medium';
    if (rating >= 2) return 'high';
    return 'urgent'; // Low mood gets attention colors
  }

  /// Calculate a progress value based on diary completeness according to spec
  static int calculateProgress({
    required bool hasContent,
    required int wordCount,
    required bool hasAttachments,
    required int attachmentCount,
    required int linkedItemsCount,
    required double? sentimentScore,
    required double consistencyScore,
    required bool isOverdue, // If day is past and no content
  }) {
    if (!hasContent) {
      return isOverdue ? 0 : 0;
    }

    double pointsEarned = 0;

    // 1. Entry Base: +50
    pointsEarned += 50;

    // 2. Media: count * 5
    pointsEarned += attachmentCount * 5;

    // 3. Text: word count * 5
    pointsEarned += wordCount * 5;

    // 4. Linked Items: count * 10
    pointsEarned += linkedItemsCount * 10;

    // 5. Sentiment Analysis: 0 to 100 points
    if (sentimentScore != null) {
      // Map 0.0-1.0 to 0-100
      pointsEarned += (sentimentScore * 100).clamp(0, 100);
    }

    // 6. Final weight by consistency (0.0 to 1.0)
    // "revord only calculated on the base on consistansy scro"
    pointsEarned *= consistencyScore;

    return pointsEarned.round().clamp(0, 10000); // Higher limit for points
  }

  int get calculatedProgress {
    final now = DateTime.now();
    final isPastDay = entryDate.isBefore(DateTime(now.year, now.month, now.day));
    
    return calculateProgress(
      hasContent: hasContent,
      wordCount: wordCount,
      hasAttachments: hasAttachments,
      attachmentCount: attachments?.length ?? 0,
      linkedItemsCount: linkedItems?.totalCount ?? 0,
      sentimentScore: metadata?.sentimentScore,
      consistencyScore: (metadata?.consistencyScore ?? 0) / 100.0,
      isOverdue: isPastDay && !hasContent,
    );
  }

  /// Calculates Rewards and returns updated DiaryEntryModel
  DiaryEntryModel recalculateRewards() {
    final int pointsEarned = calculatedProgress;
    final double rating = (1.0 + 4.0 * (pointsEarned / 500)).clamp(1.0, 5.0);
    
    final package = RewardManager.calculate(
      progress: (pointsEarned / 5).clamp(0, 100), // Map to 0-100 for visual progress
      rating: rating,
      pointsEarned: pointsEarned,
      completedDays: hasContent ? 1 : 0,
      totalDays: 1,
      hoursPerDay: 0,
      taskStack: 0,
      source: RewardSource.diary,
      onTimeCompletion: hasContent,
    );

    return copyWith(
      metadata: metadata?.copyWith(
        rewardPackage: package,
      ),
    );
  }
}

// ================================================================
// DIARY MOOD
// ================================================================

class DiaryMood {
  final int rating;
  final String? label;
  final double score;
  final String? emoji;

  DiaryMood({
    required this.rating,
    this.label,
    required this.score,
    this.emoji,
  });

  factory DiaryMood.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiaryMood(
      rating: (json['rating'] ?? 0) as int,
      label: json['label']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'rating': rating, 'label': label, 'score': score, 'emoji': emoji};
  }

  DiaryMood copyWith({
    int? rating,
    String? label,
    double? score,
    String? emoji,
  }) {
    return DiaryMood(
      rating: rating ?? this.rating,
      label: label ?? this.label,
      score: score ?? this.score,
      emoji: emoji ?? this.emoji,
    );
  }

  /// Get mood color based on rating
  Color get moodColor {
    if (rating >= 5) return const Color(0xFF43E97B); // Great
    if (rating >= 4) return const Color(0xFF4FACFE); // Good
    if (rating >= 3) return const Color(0xFFFFE082); // Okay
    if (rating >= 2) return const Color(0xFFFF9966); // Low
    return const Color(0xFFFF6B6B); // Very Low
  }
}

// ================================================================
// DIARY Q&A
// ================================================================

class DiaryQnA {
  final String qnaNumber;
  final String type;
  final String question;
  final String? options;
  final String answer;

  DiaryQnA({
    required this.qnaNumber,
    required this.type,
    required this.question,
    this.options,
    required this.answer,
  });

  factory DiaryQnA.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiaryQnA(
      qnaNumber: (json['qna_number'] ?? json['qnaNumber'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: json['options']?.toString(),
      answer: json['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qna_number': qnaNumber,
      'type': type,
      'question': question,
      if (options != null) 'options': options,
      'answer': answer,
    };
  }

  bool get isMCQ => type == 'mcq';
  bool get isShortAnswer => type == 'short_answer';
  bool get isAnswered => answer.isNotEmpty;

  List<String> get optionsList =>
      options?.split('|').map((e) => e.trim()).toList() ?? [];
}

// ================================================================
// DIARY ATTACHMENT
// ================================================================

class DiaryAttachment {
  final String id;
  final String type;
  final String url;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? thumbnailUrl;

  DiaryAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
  });

  factory DiaryAttachment.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiaryAttachment(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? json['fileName']?.toString(),
      fileSize: (json['file_size'] ?? json['fileSize']) as int?,
      mimeType: json['mime_type']?.toString() ?? json['mimeType']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString() ?? json['thumbnailUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    };
  }

  factory DiaryAttachment.fromMediaFile(EnhancedMediaFile mediaFile) {
    String typeStr;
    switch (mediaFile.type) {
      case MediaFileType.image:
        typeStr = 'image';
        break;
      case MediaFileType.video:
        typeStr = 'video';
        break;
      case MediaFileType.audio:
        typeStr = 'audio';
        break;
      case MediaFileType.document:
        typeStr = 'document';
        break;
    }
    return DiaryAttachment(
      id: mediaFile.id,
      type: typeStr,
      url: mediaFile.url,
      fileName: mediaFile.fileName,
      fileSize: mediaFile.size,
    );
  }

  EnhancedMediaFile toMediaFile() {
    MediaFileType mediaType;
    switch (type.toLowerCase()) {
      case 'image':
        mediaType = MediaFileType.image;
        break;
      case 'video':
        mediaType = MediaFileType.video;
        break;
      case 'audio':
        mediaType = MediaFileType.audio;
        break;
      default:
        mediaType = MediaFileType.document;
    }
    return EnhancedMediaFile(
      id: id,
      url: url,
      type: mediaType,
      fileName: fileName,
      size: fileSize,
    );
  }

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isDocument => type == 'document';

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ================================================================
// DIARY LINKED ITEMS
// ================================================================

class DiaryLinkedItems {
  final List<LinkedItem> longGoals;
  final List<LinkedItem> dayTasks;
  final List<LinkedItem> weeklyTasks;
  final List<LinkedItem> bucketItems;

  DiaryLinkedItems({
    this.longGoals = const [],
    this.dayTasks = const [],
    this.weeklyTasks = const [],
    this.bucketItems = const [],
  });

  factory DiaryLinkedItems.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiaryLinkedItems(
      longGoals: _parseJsonbList(json['long_goals'], (e) => LinkedItem.fromJson(e)),
      dayTasks: _parseJsonbList(json['day_tasks'], (e) => LinkedItem.fromJson(e)),
      weeklyTasks: _parseJsonbList(json['weekly_tasks'], (e) => LinkedItem.fromJson(e)),
      bucketItems: _parseJsonbList(json['bucket_items'], (e) => LinkedItem.fromJson(e)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'long_goals': longGoals.map((e) => e.toJson()).toList(),
      'day_tasks': dayTasks.map((e) => e.toJson()).toList(),
      'weekly_tasks': weeklyTasks.map((e) => e.toJson()).toList(),
      'bucket_items': bucketItems.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasLinks =>
      longGoals.isNotEmpty ||
      dayTasks.isNotEmpty ||
      weeklyTasks.isNotEmpty ||
      bucketItems.isNotEmpty;

  int get totalCount =>
      longGoals.length +
      dayTasks.length +
      weeklyTasks.length +
      bucketItems.length;
}

// ================================================================
// LINKED ITEM
// ================================================================

class LinkedItem {
  final String id;
  final String? title;

  LinkedItem({required this.id, this.title});

  factory LinkedItem.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    final idValue =
        json['goal_id']?.toString() ??
        json['task_id']?.toString() ??
        json['bucket_id']?.toString() ??
        json['id']?.toString();
    return LinkedItem(id: idValue ?? '', title: json['title']?.toString());
  }

  Map<String, dynamic> toJson() {
    return {'id': id, if (title != null) 'title': title};
  }
}

// ================================================================
// DIARY METADATA (with RewardPackage & TaskColor)
// ================================================================

class DiaryMetadata {
  final String? taskColor;
  final RewardPackage? rewardPackage;
  final int wordCount;
  final bool hasAttachments;
  final double? sentimentScore;
  final double consistencyScore; // Attendance tracking (0-100)
  final String? aiSummary;

  DiaryMetadata({
    this.taskColor,
    this.rewardPackage,
    required this.wordCount,
    required this.hasAttachments,
    this.sentimentScore,
    this.consistencyScore = 0.0,
    this.aiSummary,
  });

  factory DiaryMetadata.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiaryMetadata(
      taskColor: json['task_color']?.toString() ?? json['taskColor']?.toString(),
      rewardPackage: (json['reward_package'] ?? json['rewardPackage']) != null
          ? RewardPackage.fromJson(
              _parseJsonb(json['reward_package'] ?? json['rewardPackage']),
            )
          : null,
      wordCount: (json['word_count'] ?? json['wordCount'] ?? 0) as int,
      hasAttachments: json['has_attachments'] == true || json['has_attachments'] == 1 || json['hasAttachments'] == true,
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? (json['sentimentScore'] as num?)?.toDouble(),
      consistencyScore: (json['consistency_score'] as num?)?.toDouble() ?? (json['consistencyScore'] as num?)?.toDouble() ?? 0.0,
      aiSummary: (json['ai_summary'] ?? json['aiSummary'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (taskColor != null) 'task_color': taskColor,
      if (rewardPackage != null) 'reward_package': rewardPackage!.toJson(),
      'word_count': wordCount,
      'has_attachments': hasAttachments,
      'consistency_score': consistencyScore,
      if (sentimentScore != null) 'sentiment_score': sentimentScore,
      if (aiSummary != null) 'ai_summary': aiSummary,
    };
  }

  DiaryMetadata copyWith({
    String? taskColor,
    RewardPackage? rewardPackage,
    int? wordCount,
    bool? hasAttachments,
    double? sentimentScore,
    double? consistencyScore,
    String? aiSummary,
  }) {
    return DiaryMetadata(
      taskColor: taskColor ?? this.taskColor,
      rewardPackage: rewardPackage ?? this.rewardPackage,
      wordCount: wordCount ?? this.wordCount,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  // RewardPackage convenience getters
  bool get hasReward => rewardPackage?.earned ?? false;
  String get tagName => rewardPackage?.tagName ?? '';
  String get rewardDisplayName => rewardPackage?.rewardDisplayName ?? '';
  RewardTier get tier => rewardPackage?.tier ?? RewardTier.none;

  // Card color helper methods
  Color get priorityColor => CardColorHelper.getPriorityColor(taskColor);

  List<Color> getGradientColors({required bool isDarkMode}) {
    return CardColorHelper.getTaskCardGradient(
      priority: taskColor,
      status: null,
      progress: null,
      isDarkMode: isDarkMode,
    );
  }
}

// ================================================================
// DIARY SETTINGS
// ================================================================

class DiarySettings {
  final bool isPrivate;
  final bool isFavorite;
  final bool isPinned;

  DiarySettings({
    required this.isPrivate,
    required this.isFavorite,
    required this.isPinned,
  });

  factory DiarySettings.fromJson(dynamic v) {
    final json = _parseJsonb(v);
    return DiarySettings(
      isPrivate: json['is_private'] == true || json['is_private'] == 1 || json['isPrivate'] == true || json['is_private'] == null,
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1 || json['isFavorite'] == true,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1 || json['isPinned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_private': isPrivate,
      'is_favorite': isFavorite,
      'is_pinned': isPinned,
    };
  }

  DiarySettings copyWith({bool? isPrivate, bool? isFavorite, bool? isPinned}) {
    return DiarySettings(
      isPrivate: isPrivate ?? this.isPrivate,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
    );
  }
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

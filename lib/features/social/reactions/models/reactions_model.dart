// ============================================================
// 📁 models/social/reaction_model.dart
// Complete Reaction Model - Multi-reaction system (LinkedIn style)
// No external packages — pure Dart
// ============================================================

/// ════════════════════════════════════════════════════════════
/// REACTION TYPE ENUM
/// ════════════════════════════════════════════════════════════

enum ReactionType {
  like,
  love,
  celebrate,
  support,
  insightful,
  curious,
  haha,
  wow,
  sad,
  angry;

  static ReactionType fromString(String? value) {
    return ReactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReactionType.like,
    );
  }

  static ReactionType? tryFromString(String? value) {
    if (value == null) return null;
    try {
      return ReactionType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  /// Emoji representation
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.celebrate:
        return '🎉';
      case ReactionType.support:
        return '🙌';
      case ReactionType.insightful:
        return '💡';
      case ReactionType.curious:
        return '🤔';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }

  /// Display label
  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.celebrate:
        return 'Celebrate';
      case ReactionType.support:
        return 'Support';
      case ReactionType.insightful:
        return 'Insightful';
      case ReactionType.curious:
        return 'Curious';
      case ReactionType.haha:
        return 'Haha';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
    }
  }

  /// Color hex for UI (returns string, no Flutter dependency)
  String get colorHex {
    switch (this) {
      case ReactionType.like:
        return '#2196F3'; // blue
      case ReactionType.love:
        return '#E91E63'; // red/pink
      case ReactionType.celebrate:
        return '#4CAF50'; // green
      case ReactionType.support:
        return '#9C27B0'; // purple
      case ReactionType.insightful:
        return '#FF9800'; // orange
      case ReactionType.curious:
        return '#607D8B'; // blue-grey
      case ReactionType.haha:
        return '#FFC107'; // amber
      case ReactionType.wow:
        return '#FF5722'; // deep orange
      case ReactionType.sad:
        return '#795548'; // brown
      case ReactionType.angry:
        return '#F44336'; // red
    }
  }

  /// Whether this is a "positive" reaction
  bool get isPositive {
    switch (this) {
      case ReactionType.like:
      case ReactionType.love:
      case ReactionType.celebrate:
      case ReactionType.support:
      case ReactionType.insightful:
      case ReactionType.haha:
      case ReactionType.wow:
        return true;
      case ReactionType.curious:
        return true; // neutral-positive
      case ReactionType.sad:
      case ReactionType.angry:
        return false;
    }
  }

  /// Priority order for display (most common first)
  int get displayOrder {
    switch (this) {
      case ReactionType.like:
        return 0;
      case ReactionType.love:
        return 1;
      case ReactionType.celebrate:
        return 2;
      case ReactionType.support:
        return 3;
      case ReactionType.insightful:
        return 4;
      case ReactionType.curious:
        return 5;
      case ReactionType.haha:
        return 6;
      case ReactionType.wow:
        return 7;
      case ReactionType.sad:
        return 8;
      case ReactionType.angry:
        return 9;
    }
  }
}

/// ════════════════════════════════════════════════════════════
/// REACTION TARGET TYPE ENUM
/// ════════════════════════════════════════════════════════════

enum ReactionTargetType {
  post,
  comment;

  static ReactionTargetType fromString(String? value) {
    return ReactionTargetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReactionTargetType.post,
    );
  }
}

/// ════════════════════════════════════════════════════════════
/// TOGGLE ACTION ENUM (result of toggle_reaction)
/// ════════════════════════════════════════════════════════════

enum ReactionAction {
  added,
  changed,
  removed;

  static ReactionAction fromString(String? value) {
    return ReactionAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReactionAction.added,
    );
  }
}

/// ════════════════════════════════════════════════════════════
/// 🎯 MAIN REACTION MODEL
/// ════════════════════════════════════════════════════════════

class ReactionModel {
  final String id;
  final String userId;
  final ReactionTargetType targetType;
  final String targetId;
  final ReactionType reactionType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReactionModel({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.reactionType,
    required this.createdAt,
    required this.updatedAt,
  });

  // ──── FROM JSON ────
  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      targetType: ReactionTargetType.fromString(json['target_type'] as String?),
      targetId: json['target_id'] as String? ?? '',
      reactionType: ReactionType.fromString(json['reaction_type'] as String?),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ──── TO JSON ────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_type': targetType.name,
      'target_id': targetId,
      'reaction_type': reactionType.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ──── TO CREATE JSON ────
  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'target_type': targetType.name,
      'target_id': targetId,
      'reaction_type': reactionType.name,
    };
  }

  // ──── COMPUTED ────
  bool get isOnPost => targetType == ReactionTargetType.post;
  bool get isOnComment => targetType == ReactionTargetType.comment;
  String get emoji => reactionType.emoji;
  String get label => reactionType.label;
  bool get isPositive => reactionType.isPositive;

  /// Time since reacted
  String get timeAgo {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m';
    if (duration.inHours < 24) return '${duration.inHours}h';
    if (duration.inDays < 7) return '${duration.inDays}d';
    if (duration.inDays < 30) return '${(duration.inDays / 7).floor()}w';
    return '${(duration.inDays / 30).floor()}mo';
  }

  // ──── COPY WITH ────
  ReactionModel copyWith({
    String? id,
    String? userId,
    ReactionTargetType? targetType,
    String? targetId,
    ReactionType? reactionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ──── EMPTY ────
  static ReactionModel empty() {
    return ReactionModel(
      id: '',
      userId: '',
      targetType: ReactionTargetType.post,
      targetId: '',
      reactionType: ReactionType.like,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  // ──── EQUALITY ────
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReactionModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ReactionModel(id: $id, type: ${reactionType.name}, target: ${targetType.name}/$targetId)';
}

/// ════════════════════════════════════════════════════════════
/// TOGGLE REACTION RESULT
/// (Response from toggle_reaction() Supabase function)
/// ════════════════════════════════════════════════════════════

class ToggleReactionResult {
  final bool success;
  final ReactionAction action;
  final ReactionType? reactionType; // null if removed
  final ReactionType? oldReaction; // null if newly added

  const ToggleReactionResult({
    required this.success,
    required this.action,
    this.reactionType,
    this.oldReaction,
  });

  factory ToggleReactionResult.fromJson(Map<String, dynamic> json) {
    return ToggleReactionResult(
      success: json['success'] as bool? ?? false,
      action: ReactionAction.fromString(json['action'] as String?),
      reactionType: ReactionType.tryFromString(
        json['reaction_type'] as String?,
      ),
      oldReaction: ReactionType.tryFromString(json['old_reaction'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action.name,
      if (reactionType != null) 'reaction_type': reactionType!.name,
      if (oldReaction != null) 'old_reaction': oldReaction!.name,
    };
  }

  bool get isAdded => action == ReactionAction.added;
  bool get isChanged => action == ReactionAction.changed;
  bool get isRemoved => action == ReactionAction.removed;
  bool get hasReaction => reactionType != null;

  @override
  String toString() =>
      'ToggleReactionResult(action: ${action.name}, type: ${reactionType?.name})';
}

/// ════════════════════════════════════════════════════════════
/// REACTION USER (from get_reaction_users() function)
/// ════════════════════════════════════════════════════════════

class ReactionUser {
  final String userId;
  final String username;
  final String? displayName;
  final String? profileUrl;
  final ReactionType reactionType;
  final DateTime reactedAt;

  const ReactionUser({
    required this.userId,
    required this.username,
    this.displayName,
    this.profileUrl,
    required this.reactionType,
    required this.reactedAt,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String?,
      profileUrl: json['profile_url'] as String?,
      reactionType: ReactionType.fromString(json['reaction_type'] as String?),
      reactedAt:
          DateTime.tryParse(json['reacted_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      if (displayName != null) 'display_name': displayName,
      if (profileUrl != null) 'profile_url': profileUrl,
      'reaction_type': reactionType.name,
      'reacted_at': reactedAt.toIso8601String(),
    };
  }

  String get emoji => reactionType.emoji;
  String get label => reactionType.label;

  String get timeAgo {
    final duration = DateTime.now().difference(reactedAt);
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m';
    if (duration.inHours < 24) return '${duration.inHours}h';
    if (duration.inDays < 7) return '${duration.inDays}d';
    return '${(duration.inDays / 7).floor()}w';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReactionUser && userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'ReactionUser(user: $username, type: ${reactionType.name})';
}

/// ════════════════════════════════════════════════════════════
/// REACTION SUMMARY (for displaying reaction bar on posts)
/// ════════════════════════════════════════════════════════════

class ReactionSummary {
  final int total;
  final List<ReactionBreakdown> breakdown;
  final ReactionType? myReaction;
  final List<String> topReactorNames; // "John, Jane and 5 others"

  const ReactionSummary({
    this.total = 0,
    this.breakdown = const [],
    this.myReaction,
    this.topReactorNames = const [],
  });

  factory ReactionSummary.fromReactionsCount(
    Map<String, dynamic>? reactionsCountJson, {
    String? userReaction,
    List<String>? reactorNames,
  }) {
    if (reactionsCountJson == null) {
      return const ReactionSummary();
    }

    final total = reactionsCountJson['total'] as int? ?? 0;

    // Build breakdown from non-zero counts
    final breakdownList = <ReactionBreakdown>[];
    for (final type in ReactionType.values) {
      final count = reactionsCountJson[type.name] as int? ?? 0;
      if (count > 0) {
        breakdownList.add(
          ReactionBreakdown(
            reactionType: type,
            count: count,
            percentage: total > 0 ? (count / total) * 100 : 0.0,
          ),
        );
      }
    }

    // Sort by count descending
    breakdownList.sort((a, b) => b.count.compareTo(a.count));

    return ReactionSummary(
      total: total,
      breakdown: breakdownList,
      myReaction: ReactionType.tryFromString(userReaction),
      topReactorNames: reactorNames ?? [],
    );
  }

  // ──── COMPUTED ────
  bool get isEmpty => total == 0;
  bool get isNotEmpty => total > 0;
  bool get hasMyReaction => myReaction != null;

  /// Top 3 reaction emojis (most used)
  List<String> get topEmojis {
    return breakdown.take(3).map((b) => b.reactionType.emoji).toList();
  }

  /// Top 3 reaction types
  List<ReactionType> get topTypes {
    return breakdown.take(3).map((b) => b.reactionType).toList();
  }

  /// Formatted count string "1.2K"
  String get formattedTotal {
    if (total < 1000) return total.toString();
    if (total < 10000) {
      final formatted = (total / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(total / 1000).floor()}K'
          : '${formatted}K';
    }
    if (total < 1000000) return '${(total / 1000).floor()}K';
    return '${(total / 1000000).toStringAsFixed(1)}M';
  }

  /// Display text: "👍❤️🎉 1.2K"
  String get displayText {
    if (isEmpty) return '';
    final emojis = topEmojis.join('');
    return '$emojis $formattedTotal';
  }

  /// Reactor names text: "John, Jane and 5 others"
  String get reactorNamesText {
    if (topReactorNames.isEmpty) return '';
    if (topReactorNames.length == 1) return topReactorNames[0];
    if (topReactorNames.length == 2) {
      return '${topReactorNames[0]} and ${topReactorNames[1]}';
    }
    final remaining = total - topReactorNames.length;
    if (remaining <= 0) {
      return '${topReactorNames[0]}, ${topReactorNames[1]} and ${topReactorNames[2]}';
    }
    return '${topReactorNames[0]}, ${topReactorNames[1]} and $remaining others';
  }

  ReactionSummary copyWith({
    int? total,
    List<ReactionBreakdown>? breakdown,
    ReactionType? myReaction,
    List<String>? topReactorNames,
  }) {
    return ReactionSummary(
      total: total ?? this.total,
      breakdown: breakdown ?? this.breakdown,
      myReaction: myReaction ?? this.myReaction,
      topReactorNames: topReactorNames ?? this.topReactorNames,
    );
  }

  @override
  String toString() =>
      'ReactionSummary(total: $total, top: ${topEmojis.join()})';
}

/// ════════════════════════════════════════════════════════════
/// REACTION BREAKDOWN (per reaction type stats)
/// ════════════════════════════════════════════════════════════

class ReactionBreakdown {
  final ReactionType reactionType;
  final int count;
  final double percentage;

  const ReactionBreakdown({
    required this.reactionType,
    required this.count,
    this.percentage = 0.0,
  });

  String get emoji => reactionType.emoji;
  String get label => reactionType.label;
  String get formattedCount {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  @override
  String toString() =>
      'ReactionBreakdown(${reactionType.name}: $count ($formattedPercentage))';
}

/// ════════════════════════════════════════════════════════════
/// REACTION PICKER ITEM (for reaction picker UI)
/// ════════════════════════════════════════════════════════════

class ReactionPickerItem {
  final ReactionType type;
  final bool isSelected;

  const ReactionPickerItem({required this.type, this.isSelected = false});

  String get emoji => type.emoji;
  String get label => type.label;
  String get colorHex => type.colorHex;

  ReactionPickerItem copyWith({ReactionType? type, bool? isSelected}) {
    return ReactionPickerItem(
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Get all picker items with optional selected type
  static List<ReactionPickerItem> allItems({ReactionType? selectedType}) {
    return ReactionType.values
        .map(
          (type) =>
              ReactionPickerItem(type: type, isSelected: type == selectedType),
        )
        .toList()
      ..sort((a, b) => a.type.displayOrder.compareTo(b.type.displayOrder));
  }

  /// Get primary picker items (most common 6)
  static List<ReactionPickerItem> primaryItems({ReactionType? selectedType}) {
    const primaryTypes = [
      ReactionType.like,
      ReactionType.love,
      ReactionType.celebrate,
      ReactionType.support,
      ReactionType.insightful,
      ReactionType.curious,
    ];
    return primaryTypes
        .map(
          (type) =>
              ReactionPickerItem(type: type, isSelected: type == selectedType),
        )
        .toList();
  }

  @override
  String toString() =>
      'ReactionPickerItem(${type.name}, selected: $isSelected)';
}

/// ════════════════════════════════════════════════════════════
/// REACTION STATE (local UI state for a single target)
/// ════════════════════════════════════════════════════════════

class ReactionState {
  final String targetId;
  final ReactionTargetType targetType;
  final ReactionType? currentReaction;
  final int totalCount;
  final bool isLoading;
  final bool isPickerOpen;
  final Map<String, int> counts; // reactionType → count

  const ReactionState({
    required this.targetId,
    this.targetType = ReactionTargetType.post,
    this.currentReaction,
    this.totalCount = 0,
    this.isLoading = false,
    this.isPickerOpen = false,
    this.counts = const {},
  });

  factory ReactionState.fromPost(
    String postId, {
    Map<String, dynamic>? reactionsCountJson,
    String? userReaction,
  }) {
    final countsMap = <String, int>{};
    int total = 0;

    if (reactionsCountJson != null) {
      total = reactionsCountJson['total'] as int? ?? 0;
      for (final type in ReactionType.values) {
        final count = reactionsCountJson[type.name] as int? ?? 0;
        if (count > 0) {
          countsMap[type.name] = count;
        }
      }
    }

    return ReactionState(
      targetId: postId,
      targetType: ReactionTargetType.post,
      currentReaction: ReactionType.tryFromString(userReaction),
      totalCount: total,
      counts: countsMap,
    );
  }

  factory ReactionState.fromComment(
    String commentId, {
    Map<String, dynamic>? reactionsCountJson,
    String? userReaction,
  }) {
    final countsMap = <String, int>{};
    int total = 0;

    if (reactionsCountJson != null) {
      total = reactionsCountJson['total'] as int? ?? 0;
      for (final type in ReactionType.values) {
        final count = reactionsCountJson[type.name] as int? ?? 0;
        if (count > 0) {
          countsMap[type.name] = count;
        }
      }
    }

    return ReactionState(
      targetId: commentId,
      targetType: ReactionTargetType.comment,
      currentReaction: ReactionType.tryFromString(userReaction),
      totalCount: total,
      counts: countsMap,
    );
  }

  // ──── COMPUTED ────
  bool get hasReacted => currentReaction != null;
  bool get hasNoReaction => currentReaction == null;
  bool get hasReactions => totalCount > 0;
  String? get currentEmoji => currentReaction?.emoji;
  String? get currentLabel => currentReaction?.label;

  /// Apply toggle result to update local state
  ReactionState applyToggleResult(ToggleReactionResult result) {
    final newCounts = Map<String, int>.from(counts);
    int newTotal = totalCount;

    switch (result.action) {
      case ReactionAction.added:
        // Add new reaction
        final typeName = result.reactionType!.name;
        newCounts[typeName] = (newCounts[typeName] ?? 0) + 1;
        newTotal += 1;
        break;

      case ReactionAction.changed:
        // Remove old, add new
        if (result.oldReaction != null) {
          final oldName = result.oldReaction!.name;
          newCounts[oldName] = ((newCounts[oldName] ?? 1) - 1);
          if (newCounts[oldName]! <= 0) newCounts.remove(oldName);
        }
        final newName = result.reactionType!.name;
        newCounts[newName] = (newCounts[newName] ?? 0) + 1;
        // total stays same
        break;

      case ReactionAction.removed:
        // Remove reaction
        if (result.oldReaction != null) {
          final oldName = result.oldReaction!.name;
          newCounts[oldName] = ((newCounts[oldName] ?? 1) - 1);
          if (newCounts[oldName]! <= 0) newCounts.remove(oldName);
        } else if (currentReaction != null) {
          final oldName = currentReaction!.name;
          newCounts[oldName] = ((newCounts[oldName] ?? 1) - 1);
          if (newCounts[oldName]! <= 0) newCounts.remove(oldName);
        }
        newTotal = (newTotal - 1).clamp(0, newTotal);
        break;
    }

    return ReactionState(
      targetId: targetId,
      targetType: targetType,
      currentReaction: result.reactionType,
      totalCount: newTotal,
      isLoading: false,
      isPickerOpen: false,
      counts: newCounts,
    );
  }

  /// Get top emojis for display
  List<String> get topEmojis {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(3)
        .map((e) => ReactionType.fromString(e.key).emoji)
        .toList();
  }

  /// Formatted total
  String get formattedTotal {
    if (totalCount < 1000) return totalCount.toString();
    if (totalCount < 1000000) {
      return '${(totalCount / 1000).toStringAsFixed(1)}K';
    }
    return '${(totalCount / 1000000).toStringAsFixed(1)}M';
  }

  ReactionState copyWith({
    String? targetId,
    ReactionTargetType? targetType,
    ReactionType? currentReaction,
    int? totalCount,
    bool? isLoading,
    bool? isPickerOpen,
    Map<String, int>? counts,
    bool clearReaction = false,
  }) {
    return ReactionState(
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      currentReaction: clearReaction
          ? null
          : (currentReaction ?? this.currentReaction),
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isPickerOpen: isPickerOpen ?? this.isPickerOpen,
      counts: counts ?? this.counts,
    );
  }

  @override
  String toString() =>
      'ReactionState(target: $targetId, reaction: ${currentReaction?.name}, total: $totalCount)';
}

/// ════════════════════════════════════════════════════════════
/// REACTION USERS LIST (paginated response)
/// ════════════════════════════════════════════════════════════

class ReactionUsersList {
  final List<ReactionUser> users;
  final int total;
  final ReactionType? filterType; // null = all types
  final bool hasMore;
  final int offset;

  const ReactionUsersList({
    this.users = const [],
    this.total = 0,
    this.filterType,
    this.hasMore = false,
    this.offset = 0,
  });

  factory ReactionUsersList.fromJsonList(
    List<dynamic> jsonList, {
    ReactionType? filterType,
    int offset = 0,
    int limit = 50,
  }) {
    final users = jsonList
        .map((e) => ReactionUser.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReactionUsersList(
      users: users,
      total: users.length,
      filterType: filterType,
      hasMore: users.length >= limit,
      offset: offset,
    );
  }

  bool get isEmpty => users.isEmpty;
  bool get isNotEmpty => users.isNotEmpty;

  /// Group users by reaction type
  Map<ReactionType, List<ReactionUser>> get groupedByType {
    final grouped = <ReactionType, List<ReactionUser>>{};
    for (final user in users) {
      grouped.putIfAbsent(user.reactionType, () => []).add(user);
    }
    return grouped;
  }

  /// Get users for specific reaction type
  List<ReactionUser> usersForType(ReactionType type) {
    return users.where((u) => u.reactionType == type).toList();
  }

  /// Append more users (for pagination)
  ReactionUsersList appendUsers(ReactionUsersList more) {
    return ReactionUsersList(
      users: [...users, ...more.users],
      total: total + more.total,
      filterType: filterType,
      hasMore: more.hasMore,
      offset: more.offset,
    );
  }

  ReactionUsersList copyWith({
    List<ReactionUser>? users,
    int? total,
    ReactionType? filterType,
    bool? hasMore,
    int? offset,
  }) {
    return ReactionUsersList(
      users: users ?? this.users,
      total: total ?? this.total,
      filterType: filterType ?? this.filterType,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }

  @override
  String toString() =>
      'ReactionUsersList(count: ${users.length}, filter: ${filterType?.name ?? "all"})';
}

/// ════════════════════════════════════════════════════════════
/// REACTION TAB (for reaction details bottom sheet)
/// ════════════════════════════════════════════════════════════

class ReactionTab {
  final ReactionType? type; // null = "All" tab
  final String label;
  final String? emoji;
  final int count;
  final bool isSelected;

  const ReactionTab({
    this.type,
    required this.label,
    this.emoji,
    this.count = 0,
    this.isSelected = false,
  });

  /// Generate tabs from reactions count
  static List<ReactionTab> fromReactionsCount(
    Map<String, dynamic>? reactionsCountJson, {
    ReactionType? selectedType,
  }) {
    if (reactionsCountJson == null) return [];

    final total = reactionsCountJson['total'] as int? ?? 0;
    final tabs = <ReactionTab>[];

    // "All" tab first
    tabs.add(
      ReactionTab(
        type: null,
        label: 'All',
        count: total,
        isSelected: selectedType == null,
      ),
    );

    // Individual reaction tabs (only those with count > 0)
    for (final type in ReactionType.values) {
      final count = reactionsCountJson[type.name] as int? ?? 0;
      if (count > 0) {
        tabs.add(
          ReactionTab(
            type: type,
            label: type.label,
            emoji: type.emoji,
            count: count,
            isSelected: type == selectedType,
          ),
        );
      }
    }

    return tabs;
  }

  bool get isAllTab => type == null;

  String get displayLabel {
    if (emoji != null) return '$emoji $count';
    return '$label $count';
  }

  ReactionTab copyWith({
    ReactionType? type,
    String? label,
    String? emoji,
    int? count,
    bool? isSelected,
  }) {
    return ReactionTab(
      type: type ?? this.type,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() =>
      'ReactionTab(${type?.name ?? "all"}: $count, selected: $isSelected)';
}

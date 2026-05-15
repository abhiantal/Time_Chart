// ============================================================
// 📁 providers/reaction_provider.dart
// Reaction Provider - State management for reactions
// Supports multi-reaction system (LinkedIn style)
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/reaction_repository.dart';
import '../models/reactions_model.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class ReactionProvider extends ChangeNotifier {
  final ReactionRepository _repository;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  String? get currentUserId => _currentUserId;

  // ════════════════════════════════════════════════════════════
  // STATE
  // ════════════════════════════════════════════════════════════

  /// Reaction states keyed by "targetType:targetId"
  final Map<String, ReactionState> _reactionStates = {};

  /// Reaction users lists keyed by "targetType:targetId"
  final Map<String, ReactionUsersList> _reactionUsersCache = {};

  /// Reaction tabs keyed by "targetType:targetId"
  final Map<String, List<ReactionTab>> _reactionTabsCache = {};

  /// Loading state for batch operations
  bool _isBatchLoading = false;

  /// Error message
  String? _error;

  // ════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ════════════════════════════════════════════════════════════

  ReactionProvider({ReactionRepository? repository})
    : _repository = repository ?? ReactionRepository();

  // ════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════

  bool get isBatchLoading => _isBatchLoading;
  String? get error => _error;

  /// Generate cache key
  String _key(ReactionTargetType type, String targetId) =>
      '${type.name}:$targetId';

  // ════════════════════════════════════════════════════════════
  // GET REACTION STATE
  // ════════════════════════════════════════════════════════════

  /// Get reaction state for a post
  ReactionState getPostReactionState(String postId) {
    return getReactionState(ReactionTargetType.post, postId);
  }

  /// Get reaction state for a comment
  ReactionState getCommentReactionState(String commentId) {
    return getReactionState(ReactionTargetType.comment, commentId);
  }

  /// Get reaction state for any target
  ReactionState getReactionState(ReactionTargetType type, String targetId) {
    final key = _key(type, targetId);
    return _reactionStates[key] ??
        ReactionState(targetId: targetId, targetType: type);
  }

  /// Check if user has reacted to a post
  bool hasReactedToPost(String postId) {
    return getPostReactionState(postId).hasReacted;
  }

  /// Check if user has reacted to a comment
  bool hasReactedToComment(String commentId) {
    return getCommentReactionState(commentId).hasReacted;
  }

  /// Get current reaction type for a post
  ReactionType? getPostReaction(String postId) {
    return getPostReactionState(postId).currentReaction;
  }

  /// Get current reaction type for a comment
  ReactionType? getCommentReaction(String commentId) {
    return getCommentReactionState(commentId).currentReaction;
  }

  // ════════════════════════════════════════════════════════════
  // INITIALIZE REACTION STATE
  // ════════════════════════════════════════════════════════════

  /// Initialize state from post data (call when rendering post)
  void initializePostState({
    required String postId,
    Map<String, dynamic>? reactionsCount,
    String? userReaction,
  }) {
    final key = _key(ReactionTargetType.post, postId);

    // Skip if already initialized with same data
    final existing = _reactionStates[key];
    if (existing != null &&
        existing.currentReaction?.name == userReaction &&
        existing.totalCount == (reactionsCount?['total'] ?? 0)) {
      return;
    }

    _reactionStates[key] = ReactionState.fromPost(
      postId,
      reactionsCountJson: reactionsCount,
      userReaction: userReaction,
    );
  }

  /// Initialize state from comment data
  void initializeCommentState({
    required String commentId,
    Map<String, dynamic>? reactionsCount,
    String? userReaction,
  }) {
    final key = _key(ReactionTargetType.comment, commentId);

    _reactionStates[key] = ReactionState.fromComment(
      commentId,
      reactionsCountJson: reactionsCount,
      userReaction: userReaction,
    );
  }

  /// Initialize states for multiple posts (for feed)
  Future<void> initializePostStatesBatch(List<String> postIds) async {
    if (postIds.isEmpty) return;

    _isBatchLoading = true;
    notifyListeners();

    try {
      final userReactions = await _repository.batchGetUserReactions(postIds);

      for (final postId in postIds) {
        final key = _key(ReactionTargetType.post, postId);

        // Only update user reaction, keep existing counts
        final existing = _reactionStates[key];
        if (existing != null) {
          _reactionStates[key] = existing.copyWith(
            currentReaction: ReactionType.tryFromString(userReactions[postId]),
          );
        } else {
          _reactionStates[key] = ReactionState(
            targetId: postId,
            targetType: ReactionTargetType.post,
            currentReaction: ReactionType.tryFromString(userReactions[postId]),
          );
        }
      }
    } catch (e) {
      _error = 'Failed to load reactions';
    }

    _isBatchLoading = false;
    notifyListeners();
  }

  /// Get reaction users list
  ReactionUsersList? getReactionUsers({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final key = _key(targetType, targetId);
    return _reactionUsersCache[key];
  }

  /// Load reaction tabs for bottom sheet
  Future<List<ReactionTab>> loadReactionTabs({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? selectedType,
  }) async {
    final key = _key(targetType, targetId);

    try {
      final tabs = await _repository.getReactionTabs(
        targetType: targetType,
        targetId: targetId,
        selectedType: selectedType,
      );

      _reactionTabsCache[key] = tabs;
      notifyListeners();

      return tabs;
    } catch (e) {
      // Build from local state as fallback
      final state = getReactionState(targetType, targetId);
      final counts = <String, dynamic>{
        'total': state.totalCount,
        ...state.counts,
      };

      return ReactionTab.fromReactionsCount(counts, selectedType: selectedType);
    }
  }

  /// Load reaction users
  Future<ReactionUsersList> loadReactionUsers({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? filterType,
    bool forceRefresh = false,
  }) async {
    final key = _key(targetType, targetId);

    if (!forceRefresh && _reactionUsersCache.containsKey(key)) {
      final cached = _reactionUsersCache[key]!;
      if (cached.filterType == filterType) {
        return cached;
      }
    }

    try {
      final users = await _repository.fetchReactionUsersFromServer(
        targetType: targetType,
        targetId: targetId,
        filterType: filterType,
      );

      _reactionUsersCache[key] = users;
      notifyListeners();

      return users;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load reactions');
      return const ReactionUsersList();
    }
  }

  /// Load more reaction users
  Future<void> loadMoreReactionUsers({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? filterType,
  }) async {
    final key = _key(targetType, targetId);
    final current = _reactionUsersCache[key];

    if (current == null || !current.hasMore) return;

    try {
      final more = await _repository.fetchReactionUsersFromServer(
        targetType: targetType,
        targetId: targetId,
        filterType: filterType,
        offset: current.offset + current.users.length,
      );

      _reactionUsersCache[key] = current.appendUsers(more);
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load more');
    }
  }
  // ════════════════════════════════════════════════════════════
  // TOGGLE REACTION
  // ════════════════════════════════════════════════════════════

  /// Toggle reaction on a post
  Future<ToggleReactionResult?> togglePostReaction({
    required String postId,
    required ReactionType reactionType,
  }) {
    return toggleReaction(
      targetType: ReactionTargetType.post,
      targetId: postId,
      reactionType: reactionType,
    );
  }

  /// Toggle reaction on a comment
  Future<ToggleReactionResult?> toggleCommentReaction({
    required String commentId,
    required ReactionType reactionType,
  }) {
    return toggleReaction(
      targetType: ReactionTargetType.comment,
      targetId: commentId,
      reactionType: reactionType,
    );
  }

  /// Toggle like on a post (shortcut)
  Future<ToggleReactionResult?> togglePostLike(String postId) {
    return togglePostReaction(postId: postId, reactionType: ReactionType.like);
  }

  /// Toggle like on a comment (shortcut)
  Future<ToggleReactionResult?> toggleCommentLike(String commentId) {
    return toggleCommentReaction(
      commentId: commentId,
      reactionType: ReactionType.like,
    );
  }

  /// Toggle reaction on any target
  Future<ToggleReactionResult?> toggleReaction({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) async {
    final key = _key(targetType, targetId);
    final currentState =
        _reactionStates[key] ??
        ReactionState(targetId: targetId, targetType: targetType);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Set loading state
    _reactionStates[key] = currentState.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.toggleReaction(
        targetType: targetType,
        targetId: targetId,
        reactionType: reactionType,
      );

      if (result != null && result.success) {
        // Apply result to state
        _reactionStates[key] = currentState.applyToggleResult(result);

        // Show feedback based on action
        _showReactionFeedback(result, reactionType);

        notifyListeners();
        return result;
      } else {
        // Revert loading state
        _reactionStates[key] = currentState.copyWith(isLoading: false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      // Revert loading state on error
      _reactionStates[key] = currentState.copyWith(isLoading: false);
      ErrorHandler.showErrorSnackbar('Failed to update reaction');
      notifyListeners();
      return null;
    }
  }

  /// Show feedback for reaction action
  void _showReactionFeedback(ToggleReactionResult result, ReactionType type) {
    switch (result.action) {
      case ReactionAction.added:
        // Subtle feedback - no snackbar for likes
        if (type != ReactionType.like) {
          AppSnackbar.info(title: '${type.emoji} ${type.label}');
        }
        break;
      case ReactionAction.changed:
        // No snackbar for changes
        break;
      case ReactionAction.removed:
        // No snackbar for removals
        break;
    }
  }

  // ════════════════════════════════════════════════════════════
  // REMOVE REACTION
  // ════════════════════════════════════════════════════════════

  /// Remove current reaction from a post
  Future<ToggleReactionResult?> removePostReaction(String postId) async {
    final state = getPostReactionState(postId);
    if (state.currentReaction == null) return null;

    return togglePostReaction(
      postId: postId,
      reactionType: state.currentReaction!,
    );
  }

  /// Remove current reaction from a comment
  Future<ToggleReactionResult?> removeCommentReaction(String commentId) async {
    final state = getCommentReactionState(commentId);
    if (state.currentReaction == null) return null;

    return toggleCommentReaction(
      commentId: commentId,
      reactionType: state.currentReaction!,
    );
  }

  // ════════════════════════════════════════════════════════════
  // REACTION PICKER
  // ════════════════════════════════════════════════════════════

  /// Open reaction picker for a target
  void openPicker({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final key = _key(targetType, targetId);
    final state =
        _reactionStates[key] ??
        ReactionState(targetId: targetId, targetType: targetType);

    _reactionStates[key] = state.copyWith(isPickerOpen: true);
    notifyListeners();
  }

  /// Close reaction picker for a target
  void closePicker({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final key = _key(targetType, targetId);
    final state = _reactionStates[key];
    if (state == null) return;

    _reactionStates[key] = state.copyWith(isPickerOpen: false);
    notifyListeners();
  }

  /// Check if picker is open
  bool isPickerOpen({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final key = _key(targetType, targetId);
    return _reactionStates[key]?.isPickerOpen ?? false;
  }

  /// Get picker items with current selection
  List<ReactionPickerItem> getPickerItems({
    required ReactionTargetType targetType,
    required String targetId,
    bool primaryOnly = true,
  }) {
    final state = getReactionState(targetType, targetId);

    if (primaryOnly) {
      return ReactionPickerItem.primaryItems(
        selectedType: state.currentReaction,
      );
    }

    return ReactionPickerItem.allItems(selectedType: state.currentReaction);
  }

  // ════════════════════════════════════════════════════════════
  // REACTION SUMMARY
  // ════════════════════════════════════════════════════════════

  /// Get reaction summary for display
  ReactionSummary getReactionSummary({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final state = getReactionState(targetType, targetId);

    return ReactionSummary(
      total: state.totalCount,
      breakdown: _buildBreakdown(state.counts),
      myReaction: state.currentReaction,
    );
  }

  /// Build breakdown from counts map
  List<ReactionBreakdown> _buildBreakdown(Map<String, int> counts) {
    final list = <ReactionBreakdown>[];
    int total = 0;

    counts.forEach((typeName, count) {
      total += count;
    });

    counts.forEach((typeName, count) {
      if (count > 0) {
        list.add(
          ReactionBreakdown(
            reactionType: ReactionType.fromString(typeName),
            count: count,
            percentage: total > 0 ? (count / total) * 100 : 0.0,
          ),
        );
      }
    });

    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  // ════════════════════════════════════════════════════════════
  // REACTION USERS (Who reacted?)
  // ════════════════════════════════════════════════════════════
  // Methods moved to lines 181-281

  /// Update selected tab
  void updateSelectedTab({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? selectedType,
  }) {
    final key = _key(targetType, targetId);
    final tabs = _reactionTabsCache[key];

    if (tabs == null) return;

    _reactionTabsCache[key] = tabs.map((tab) {
      return tab.copyWith(isSelected: tab.type == selectedType);
    }).toList();

    notifyListeners();

    // Load users for selected tab
    loadReactionUsers(
      targetType: targetType,
      targetId: targetId,
      filterType: selectedType,
      forceRefresh: true,
    );
  }

  // ════════════════════════════════════════════════════════════
  // WATCH REACTIONS (Streams)
  // ════════════════════════════════════════════════════════════

  /// Watch reaction count changes
  Stream<int> watchReactionCount({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return _repository.watchReactionCount(
      targetType: targetType,
      targetId: targetId,
    );
  }

  /// Watch user's reaction changes
  Stream<ReactionType?> watchUserReaction({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return _repository.watchUserReaction(
      targetType: targetType,
      targetId: targetId,
    );
  }

  // ════════════════════════════════════════════════════════════
  // OPTIMISTIC UPDATES
  // ════════════════════════════════════════════════════════════

  /// Optimistically update reaction (before server confirms)
  void optimisticToggle({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) {
    final key = _key(targetType, targetId);
    final currentState =
        _reactionStates[key] ??
        ReactionState(targetId: targetId, targetType: targetType);

    ReactionAction action;
    ReactionType? newReaction;
    ReactionType? oldReaction = currentState.currentReaction;

    if (oldReaction == null) {
      // Adding new reaction
      action = ReactionAction.added;
      newReaction = reactionType;
    } else if (oldReaction == reactionType) {
      // Removing same reaction
      action = ReactionAction.removed;
      newReaction = null;
    } else {
      // Changing reaction
      action = ReactionAction.changed;
      newReaction = reactionType;
    }

    final optimisticResult = ToggleReactionResult(
      success: true,
      action: action,
      reactionType: newReaction,
      oldReaction: oldReaction,
    );

    _reactionStates[key] = currentState.applyToggleResult(optimisticResult);
    notifyListeners();
  }

  /// Revert optimistic update (if server fails)
  void revertOptimisticToggle({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType? previousReaction,
    required int previousCount,
    required Map<String, int> previousCounts,
  }) {
    final key = _key(targetType, targetId);

    _reactionStates[key] = ReactionState(
      targetId: targetId,
      targetType: targetType,
      currentReaction: previousReaction,
      totalCount: previousCount,
      counts: previousCounts,
    );

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // EXTERNAL STATE UPDATES
  // ════════════════════════════════════════════════════════════

  /// Update state from external source (e.g., real-time update)
  void updateStateFromExternal({
    required ReactionTargetType targetType,
    required String targetId,
    required Map<String, dynamic> reactionsCount,
    String? userReaction,
  }) {
    final key = _key(targetType, targetId);

    if (targetType == ReactionTargetType.post) {
      _reactionStates[key] = ReactionState.fromPost(
        targetId,
        reactionsCountJson: reactionsCount,
        userReaction: userReaction,
      );
    } else {
      _reactionStates[key] = ReactionState.fromComment(
        targetId,
        reactionsCountJson: reactionsCount,
        userReaction: userReaction,
      );
    }

    notifyListeners();
  }

  /// Increment reaction count externally (real-time)
  void incrementReactionCount({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) {
    final key = _key(targetType, targetId);
    final state = _reactionStates[key];
    if (state == null) return;

    final newCounts = Map<String, int>.from(state.counts);
    newCounts[reactionType.name] = (newCounts[reactionType.name] ?? 0) + 1;

    _reactionStates[key] = state.copyWith(
      totalCount: state.totalCount + 1,
      counts: newCounts,
    );

    notifyListeners();
  }

  /// Decrement reaction count externally (real-time)
  void decrementReactionCount({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) {
    final key = _key(targetType, targetId);
    final state = _reactionStates[key];
    if (state == null) return;

    final newCounts = Map<String, int>.from(state.counts);
    final currentCount = newCounts[reactionType.name] ?? 0;
    if (currentCount > 0) {
      newCounts[reactionType.name] = currentCount - 1;
      if (newCounts[reactionType.name] == 0) {
        newCounts.remove(reactionType.name);
      }
    }

    _reactionStates[key] = state.copyWith(
      totalCount: (state.totalCount - 1).clamp(0, state.totalCount),
      counts: newCounts,
    );

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ════════════════════════════════════════════════════════════

  /// Get total reactions for a post
  int getPostReactionCount(String postId) {
    return getPostReactionState(postId).totalCount;
  }

  /// Get total reactions for a comment
  int getCommentReactionCount(String commentId) {
    return getCommentReactionState(commentId).totalCount;
  }

  /// Get top emojis for a post
  List<String> getPostTopEmojis(String postId) {
    return getPostReactionState(postId).topEmojis;
  }

  /// Get formatted total for a post
  String getPostFormattedTotal(String postId) {
    return getPostReactionState(postId).formattedTotal;
  }

  /// Check if loading for a target
  bool isLoading({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return getReactionState(targetType, targetId).isLoading;
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Clear state for a specific target
  void clearState({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    final key = _key(targetType, targetId);
    _reactionStates.remove(key);
    _reactionUsersCache.remove(key);
    _reactionTabsCache.remove(key);
    notifyListeners();
  }

  /// Clear all states for a target type
  void clearAllStates(ReactionTargetType targetType) {
    final prefix = '${targetType.name}:';

    _reactionStates.removeWhere((key, _) => key.startsWith(prefix));
    _reactionUsersCache.removeWhere((key, _) => key.startsWith(prefix));
    _reactionTabsCache.removeWhere((key, _) => key.startsWith(prefix));

    notifyListeners();
  }

  /// Clear all cached data
  void clearCache() {
    _reactionStates.clear();
    _reactionUsersCache.clear();
    _reactionTabsCache.clear();
    _isBatchLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh state from server
  Future<void> refreshState({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    try {
      final state = await _repository.getReactionState(
        targetType: targetType,
        targetId: targetId,
      );

      final key = _key(targetType, targetId);
      _reactionStates[key] = state;
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to refresh');
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}

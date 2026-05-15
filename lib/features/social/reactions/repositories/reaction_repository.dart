// ============================================================
// 📁 repositories/social/reaction_repository.dart
// Complete Reaction Repository with PowerSync + Supabase
// ============================================================

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/services/powersync_service.dart';

import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

class ReactionRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  // ════════════════════════════════════════════════════════════
  // SINGLETON
  // ════════════════════════════════════════════════════════════

  static ReactionRepository? _instance;

  factory ReactionRepository() {
    _instance ??= ReactionRepository._internal(
      PowerSyncService(),
      Supabase.instance.client,
    );
    return _instance!;
  }

  ReactionRepository._internal(this._powerSync, this._supabase);

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw PowerSyncException('User not authenticated');
    }
  }

  // ════════════════════════════════════════════════════════════
  // TOGGLE REACTION (Add / Change / Remove)
  // ════════════════════════════════════════════════════════════

  /// Toggle reaction on a post or comment.
  /// - If no existing reaction → ADD
  /// - If same reaction exists → REMOVE
  /// - If different reaction exists → CHANGE
  Future<ToggleReactionResult?> toggleReaction({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) async {
    _ensureAuthenticated();

    try {
      // Check for existing reaction
      final existing = await _powerSync.querySingle(
        'SELECT * FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ?',
        parameters: [_currentUserId, targetType.name, targetId],
      );

      String action;
      ReactionType? oldReaction;
      ReactionType? newReaction;

      if (existing != null) {
        final existingType = existing['reaction_type'] as String;

        if (existingType == reactionType.name) {
          // ── REMOVE (same reaction clicked again) ──
          await _powerSync.delete('reactions', existing['id'] as String);
          action = 'removed';
          oldReaction = ReactionType.fromString(existingType);
          newReaction = null;
        } else {
          // ── CHANGE (different reaction) ──
          oldReaction = ReactionType.fromString(existingType);
          newReaction = reactionType;
          await _powerSync.update('reactions', {
            'reaction_type': reactionType.name,
          }, existing['id'] as String);
          action = 'changed';
        }
      } else {
        // ── ADD (no existing reaction) ──
        newReaction = reactionType;
        await _powerSync.insert('reactions', {
          'user_id': _currentUserId,
          'target_type': targetType.name,
          'target_id': targetId,
          'reaction_type': reactionType.name,
        });
        action = 'added';
      }

      // Update counts on target
      await _recalculateReactionCounts(targetType, targetId);

      return ToggleReactionResult(
        success: true,
        action: ReactionAction.fromString(action),
        reactionType: newReaction,
        oldReaction: oldReaction,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'toggleReaction');
      ErrorHandler.showErrorSnackbar(
        ErrorHandler.formatErrorMessage(error),
        title: 'Reaction failed',
      );
      return null;
    }
  }

  /// Quick like (shortcut for toggle with 'like')
  Future<ToggleReactionResult?> toggleLike({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return toggleReaction(
      targetType: targetType,
      targetId: targetId,
      reactionType: ReactionType.like,
    );
  }

  /// Quick like on a post
  Future<ToggleReactionResult?> togglePostLike(String postId) {
    return toggleLike(targetType: ReactionTargetType.post, targetId: postId);
  }

  /// Quick like on a comment
  Future<ToggleReactionResult?> toggleCommentLike(String commentId) {
    return toggleLike(
      targetType: ReactionTargetType.comment,
      targetId: commentId,
    );
  }

  // ════════════════════════════════════════════════════════════
  // GET USER'S REACTION
  // ════════════════════════════════════════════════════════════

  /// Get current user's reaction on a target
  Future<ReactionModel?> getUserReaction({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    _ensureAuthenticated();

    try {
      final row = await _powerSync.querySingle(
        'SELECT * FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ?',
        parameters: [_currentUserId, targetType.name, targetId],
      );

      if (row == null) return null;
      return ReactionModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getUserReaction');
      return null;
    }
  }

  /// Get current user's reaction type string (for UI)
  Future<String?> getUserReactionType({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    _ensureAuthenticated();

    try {
      final row = await _powerSync.querySingle(
        'SELECT reaction_type FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ?',
        parameters: [_currentUserId, targetType.name, targetId],
      );
      return row?['reaction_type'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Check if current user has reacted to a target
  Future<bool> hasUserReacted({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    _ensureAuthenticated();

    try {
      final row = await _powerSync.querySingle(
        'SELECT 1 FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ?',
        parameters: [_currentUserId, targetType.name, targetId],
      );
      return row != null;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET REACTIONS LIST (Who reacted?)
  // ════════════════════════════════════════════════════════════

  /// Get users who reacted to a target (with profiles)
  Future<ReactionUsersList> getReactionUsers({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? filterType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final typeFilter = filterType != null ? 'AND r.reaction_type = ?' : '';

      final params = <dynamic>[targetType.name, targetId];
      if (filterType != null) params.add(filterType.name);
      params.addAll([limit, offset]);

      final rows = await _powerSync.executeQuery('''
        SELECT r.user_id, r.reaction_type, r.created_at as reacted_at,
               up.username, up.profile_url
        FROM reactions r
        LEFT JOIN user_profiles up ON up.user_id = r.user_id
        WHERE r.target_type = ? AND r.target_id = ?
        $typeFilter
        ORDER BY r.created_at DESC
        LIMIT ? OFFSET ?
        ''', parameters: params);

      return ReactionUsersList.fromJsonList(
        rows,
        filterType: filterType,
        offset: offset,
        limit: limit,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getReactionUsers');
      return const ReactionUsersList();
    }
  }

  /// Get reaction users from Supabase RPC (online, richer data)
  Future<ReactionUsersList> fetchReactionUsersFromServer({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? filterType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (!_powerSync.isOnline) {
        return getReactionUsers(
          targetType: targetType,
          targetId: targetId,
          filterType: filterType,
          limit: limit,
          offset: offset,
        );
      }

      final response = await _supabase.rpc(
        'get_reaction_users',
        params: {
          'p_target_type': targetType.name,
          'p_target_id': targetId,
          if (filterType != null) 'p_reaction_type': filterType.name,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response is List) {
        return ReactionUsersList.fromJsonList(
          response,
          filterType: filterType,
          offset: offset,
          limit: limit,
        );
      }

      return const ReactionUsersList();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        'fetchReactionUsersFromServer',
      );
      return getReactionUsers(
        targetType: targetType,
        targetId: targetId,
        filterType: filterType,
        limit: limit,
        offset: offset,
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // REACTION COUNTS & SUMMARY
  // ════════════════════════════════════════════════════════════

  /// Get reaction counts for a target (breakdown by type)
  Future<Map<String, dynamic>> getReactionCounts({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    try {
      final rows = await _powerSync.executeQuery(
        '''
        SELECT reaction_type, COUNT(*) as count
        FROM reactions
        WHERE target_type = ? AND target_id = ?
        GROUP BY reaction_type
        ''',
        parameters: [targetType.name, targetId],
      );

      final counts = <String, dynamic>{'total': 0};
      int total = 0;

      for (final type in ReactionType.values) {
        counts[type.name] = 0;
      }

      for (final row in rows) {
        final type = row['reaction_type'] as String;
        final count = row['count'] as int? ?? 0;
        counts[type] = count;
        total += count;
      }

      counts['total'] = total;
      return counts;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getReactionCounts');
      return {'total': 0};
    }
  }

  /// Build ReactionSummary for a target
  Future<ReactionSummary> getReactionSummary({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    try {
      final counts = await getReactionCounts(
        targetType: targetType,
        targetId: targetId,
      );

      String? userReaction;
      if (_currentUserId != null) {
        userReaction = await getUserReactionType(
          targetType: targetType,
          targetId: targetId,
        );
      }

      // Get top reactor names
      final topReactors = await _powerSync.executeQuery(
        '''
        SELECT up.username
        FROM reactions r
        LEFT JOIN user_profiles up ON up.user_id = r.user_id
        WHERE r.target_type = ? AND r.target_id = ?
        ORDER BY r.created_at DESC
        LIMIT 3
        ''',
        parameters: [targetType.name, targetId],
      );

      final names = topReactors
          .map((r) => r['username'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      return ReactionSummary.fromReactionsCount(
        counts,
        userReaction: userReaction,
        reactorNames: names,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getReactionSummary');
      return const ReactionSummary();
    }
  }

  /// Build ReactionState for local UI
  Future<ReactionState> getReactionState({
    required ReactionTargetType targetType,
    required String targetId,
  }) async {
    try {
      final counts = await getReactionCounts(
        targetType: targetType,
        targetId: targetId,
      );

      String? userReaction;
      if (_currentUserId != null) {
        userReaction = await getUserReactionType(
          targetType: targetType,
          targetId: targetId,
        );
      }

      if (targetType == ReactionTargetType.post) {
        return ReactionState.fromPost(
          targetId,
          reactionsCountJson: counts,
          userReaction: userReaction,
        );
      } else {
        return ReactionState.fromComment(
          targetId,
          reactionsCountJson: counts,
          userReaction: userReaction,
        );
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getReactionState');
      return ReactionState(targetId: targetId, targetType: targetType);
    }
  }

  // ════════════════════════════════════════════════════════════
  // REACTION TABS (for bottom sheet)
  // ════════════════════════════════════════════════════════════

  /// Get reaction tabs for the reaction details bottom sheet
  Future<List<ReactionTab>> getReactionTabs({
    required ReactionTargetType targetType,
    required String targetId,
    ReactionType? selectedType,
  }) async {
    try {
      final counts = await getReactionCounts(
        targetType: targetType,
        targetId: targetId,
      );
      return ReactionTab.fromReactionsCount(counts, selectedType: selectedType);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getReactionTabs');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // WATCH REACTIONS (Live Updates)
  // ════════════════════════════════════════════════════════════

  /// Watch reactions on a specific target (live stream)
  Stream<List<ReactionModel>> watchReactions({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return _powerSync
        .watchQuery(
          'SELECT * FROM reactions WHERE target_type = ? AND target_id = ? ORDER BY created_at DESC',
          parameters: [targetType.name, targetId],
        )
        .map(
          (rows) => rows
              .map(
                (row) => ReactionModel.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  /// Watch reaction count on a target
  Stream<int> watchReactionCount({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    return _powerSync
        .watchQuery(
          'SELECT COUNT(*) as count FROM reactions WHERE target_type = ? AND target_id = ?',
          parameters: [targetType.name, targetId],
        )
        .map(
          (rows) => rows.isNotEmpty ? (rows.first['count'] as int? ?? 0) : 0,
        );
  }

  /// Watch current user's reaction on a target
  Stream<ReactionType?> watchUserReaction({
    required ReactionTargetType targetType,
    required String targetId,
  }) {
    _ensureAuthenticated();

    return _powerSync
        .watchQuery(
          'SELECT reaction_type FROM reactions WHERE user_id = ? AND target_type = ? AND target_id = ?',
          parameters: [_currentUserId, targetType.name, targetId],
        )
        .map((rows) {
          if (rows.isEmpty) return null;
          return ReactionType.tryFromString(
            rows.first['reaction_type'] as String?,
          );
        });
  }

  // ════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ════════════════════════════════════════════════════════════

  /// Get user's reactions on multiple posts at once (for feed)
  Future<Map<String, String?>> batchGetUserReactions(
    List<String> postIds,
  ) async {
    _ensureAuthenticated();

    if (postIds.isEmpty) return {};

    try {
      final placeholders = List.generate(postIds.length, (_) => '?').join(',');

      final rows = await _powerSync.executeQuery(
        '''
        SELECT target_id, reaction_type
        FROM reactions
        WHERE user_id = ?
          AND target_type = 'post'
          AND target_id IN ($placeholders)
        ''',
        parameters: [_currentUserId, ...postIds],
      );

      final result = <String, String?>{};
      for (final id in postIds) {
        result[id] = null;
      }
      for (final row in rows) {
        result[row['target_id'] as String] = row['reaction_type'] as String?;
      }

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'batchGetUserReactions');
      return {};
    }
  }

  /// Check reactions for multiple posts at once (for feed)
  Future<Map<String, bool>> batchHasUserReacted(List<String> postIds) async {
    _ensureAuthenticated();

    if (postIds.isEmpty) return {};

    try {
      final placeholders = List.generate(postIds.length, (_) => '?').join(',');

      final rows = await _powerSync.executeQuery(
        '''
        SELECT target_id
        FROM reactions
        WHERE user_id = ?
          AND target_type = 'post'
          AND target_id IN ($placeholders)
        ''',
        parameters: [_currentUserId, ...postIds],
      );

      final reactedIds = rows.map((r) => r['target_id'] as String).toSet();

      final result = <String, bool>{};
      for (final id in postIds) {
        result[id] = reactedIds.contains(id);
      }

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'batchHasUserReacted');
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  // USER'S REACTION HISTORY
  // ════════════════════════════════════════════════════════════

  /// Get all posts the current user has reacted to
  Future<List<ReactionModel>> getUserReactionHistory({
    ReactionType? filterType,
    int limit = 50,
    int offset = 0,
  }) async {
    _ensureAuthenticated();

    try {
      final typeFilter = filterType != null ? 'AND reaction_type = ?' : '';

      final params = <dynamic>[_currentUserId];
      if (filterType != null) params.add(filterType.name);
      params.addAll([limit, offset]);

      final rows = await _powerSync.executeQuery('''
        SELECT * FROM reactions
        WHERE user_id = ? AND target_type = 'post'
        $typeFilter
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
        ''', parameters: params);

      return rows
          .map((row) => ReactionModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getUserReactionHistory');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // RECALCULATE COUNTS (sync counts on target)
  // ════════════════════════════════════════════════════════════

  /// Recalculate and update reaction counts on a post or comment
  Future<void> _recalculateReactionCounts(
    ReactionTargetType targetType,
    String targetId,
  ) async {
    try {
      final counts = await getReactionCounts(
        targetType: targetType,
        targetId: targetId,
      );

      if (targetType == ReactionTargetType.post) {
        await _powerSync.update('posts', {'reactions_count': counts}, targetId);
      } else if (targetType == ReactionTargetType.comment) {
        await _powerSync.update('comments', {
          'reactions_count': counts,
        }, targetId);
      }
    } catch (e) {
      logW('Failed to recalculate reaction counts: $e');
    }
  }

  /// Force recalculate counts for a post (manual fix)
  Future<void> recalculatePostReactionCounts(String postId) async {
    await _recalculateReactionCounts(ReactionTargetType.post, postId);
  }

  /// Force recalculate counts for a comment (manual fix)
  Future<void> recalculateCommentReactionCounts(String commentId) async {
    await _recalculateReactionCounts(ReactionTargetType.comment, commentId);
  }

  // ════════════════════════════════════════════════════════════
  // SUPABASE RPC (Online operations)
  // ════════════════════════════════════════════════════════════

  /// Toggle reaction via Supabase RPC (for guaranteed server-side consistency)
  Future<ToggleReactionResult?> toggleReactionViaServer({
    required ReactionTargetType targetType,
    required String targetId,
    required ReactionType reactionType,
  }) async {
    _ensureAuthenticated();

    try {
      if (!_powerSync.isOnline) {
        logI('Offline — using local toggle');
        return toggleReaction(
          targetType: targetType,
          targetId: targetId,
          reactionType: reactionType,
        );
      }

      final response = await _supabase.rpc(
        'toggle_reaction',
        params: {
          'p_user_id': _currentUserId,
          'p_target_type': targetType.name,
          'p_target_id': targetId,
          'p_reaction_type': reactionType.name,
        },
      );

      if (response is Map<String, dynamic>) {
        return ToggleReactionResult.fromJson(response);
      }

      return null;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'toggleReactionViaServer');
      // Fallback to local
      return toggleReaction(
        targetType: targetType,
        targetId: targetId,
        reactionType: reactionType,
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Remove all reactions by current user (account cleanup)
  Future<int> removeAllUserReactions() async {
    _ensureAuthenticated();

    try {
      final rows = await _powerSync.executeQuery(
        'SELECT id, target_type, target_id FROM reactions WHERE user_id = ?',
        parameters: [_currentUserId],
      );

      int count = 0;
      for (final row in rows) {
        await _powerSync.delete('reactions', row['id'] as String);
        await _recalculateReactionCounts(
          ReactionTargetType.fromString(row['target_type'] as String?),
          row['target_id'] as String,
        );
        count++;
      }

      logI('Removed $count reactions for user $_currentUserId');
      return count;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'removeAllUserReactions');
      return 0;
    }
  }
}

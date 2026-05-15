// ============================================================
// 📁 repositories/social/comment_repository.dart
// Complete Comment Repository with PowerSync + Supabase
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/social/comments/models/comments_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';

import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';

class CommentRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  // ════════════════════════════════════════════════════════════
  // SINGLETON
  // ════════════════════════════════════════════════════════════

  static CommentRepository? _instance;

  factory CommentRepository() {
    _instance ??= CommentRepository._internal(
      PowerSyncService(),
      Supabase.instance.client,
    );
    return _instance!;
  }

  CommentRepository._internal(this._powerSync, this._supabase);

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  void _ensureAuthenticated() {
    if (_currentUserId == null) {
      throw PowerSyncException('User not authenticated');
    }
  }

  static const List<String> _jsonbColumns = ['media', 'reactions_count'];

  Map<String, dynamic> _parseRow(Map<String, dynamic> row) {
    return _powerSync.parseJsonbFields(
      Map<String, dynamic>.from(row),
      _jsonbColumns,
    );
  }

  List<Map<String, dynamic>> _parseRows(List<Map<String, dynamic>> rows) {
    return rows.map(_parseRow).toList();
  }

  // ════════════════════════════════════════════════════════════
  // ADD COMMENT
  // ════════════════════════════════════════════════════════════

  /// Add a root comment or reply to a post
  Future<CommentModel?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentions,
    List<String>? mentionedUsernames,
    CommentMedia? media,
  }) async {
    _ensureAuthenticated();

    try {
      // Verify post exists and allows comments
      final post = await _powerSync.querySingle(
        'SELECT id, user_id, allow_comments, status, is_deleted FROM posts WHERE id = ?',
        parameters: [postId],
      );

      if (post == null) {
        AppSnackbar.error('Post not found');
        return null;
      }

      if (post['status'] != 'published' ||
          (post['is_deleted'] as int? ?? 0) == 1) {
        AppSnackbar.error('Post is not available');
        return null;
      }

      if ((post['allow_comments'] as int? ?? 1) == 0) {
        AppSnackbar.error('Comments are disabled on this post');
        return null;
      }

      // Handle threading
      int threadDepth = 0;
      String? threadPath;
      String? replyToUserId;

      if (parentCommentId != null) {
        final parent = await _powerSync.querySingle(
          'SELECT * FROM comments WHERE id = ? AND post_id = ?',
          parameters: [parentCommentId, postId],
        );

        if (parent == null) {
          AppSnackbar.error('Parent comment not found');
          return null;
        }

        final parentDepth = parent['thread_depth'] as int? ?? 0;
        if (parentDepth >= 4) {
          AppSnackbar.error('Maximum reply depth reached');
          return null;
        }

        replyToUserId = parent['user_id'] as String?;
        threadDepth = parentDepth + 1;

        // Calculate thread path
        final parentPath = parent['thread_path'] as String? ?? '0001';

        final siblingCount = await _powerSync.executeQuery(
          'SELECT COUNT(*) as count FROM comments WHERE parent_comment_id = ?',
          parameters: [parentCommentId],
        );
        final siblings = siblingCount.first['count'] as int? ?? 0;
        final segment = (siblings + 1).toString().padLeft(4, '0');
        threadPath = '$parentPath/$segment';
      } else {
        // Root comment
        final rootCount = await _powerSync.executeQuery(
          'SELECT COUNT(*) as count FROM comments WHERE post_id = ? AND parent_comment_id IS NULL',
          parameters: [postId],
        );
        final roots = rootCount.first['count'] as int? ?? 0;
        threadPath = (roots + 1).toString().padLeft(4, '0');
      }

      // Check if commenter is the post author
      final isByAuthor = post['user_id'] == _currentUserId;

      final data = <String, dynamic>{
        'user_id': _currentUserId,
        'post_id': postId,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        if (replyToUserId != null) 'reply_to_user_id': replyToUserId,
        'thread_depth': threadDepth,
        'thread_path': threadPath,
        'content': content,
        if (mentions != null && mentions.isNotEmpty)
          'mentions': jsonEncode(mentions),
        if (mentionedUsernames != null && mentionedUsernames.isNotEmpty)
          'mentioned_usernames': jsonEncode(mentionedUsernames),
        if (media != null) 'media': media.toJson(),
        'reactions_count': {'total': 0},
        'replies_count': 0,
        'is_edited': 0,
        'is_deleted': 0,
        'is_hidden': 0,
        'is_pinned': 0,
        'is_by_author': isByAuthor ? 1 : 0,
      };

      final commentId = await _powerSync.insert('comments', data);

      // Update post comment count
      await _recalculatePostCommentCount(postId);

      // Update parent replies count
      if (parentCommentId != null) {
        await _recalculateParentRepliesCount(parentCommentId);
      }

      // Fetch created comment with profile
      return await getCommentById(commentId);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'addComment');
      ErrorHandler.showErrorSnackbar(
        ErrorHandler.formatErrorMessage(error),
        title: 'Failed to add comment',
      );
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET COMMENT BY ID
  // ════════════════════════════════════════════════════════════

  /// Get a single comment with author profile
  Future<CommentModel?> getCommentById(String commentId) async {
    try {
      final row = await _powerSync.querySingle(
        '''
        SELECT c.*, 
               up.username, 
               up.profile_url,
               rtu.username as reply_to_username
        FROM comments c
        LEFT JOIN user_profiles up ON up.user_id = c.user_id
        LEFT JOIN user_profiles rtu ON rtu.user_id = c.reply_to_user_id
        WHERE c.id = ?
        ''',
        parameters: [commentId],
      );

      if (row == null) return null;

      final parsed = _parseRow(row);

      // Check user interaction
      if (_currentUserId != null) {
        final reacted = await _powerSync.querySingle(
          "SELECT reaction_type FROM reactions WHERE target_type = 'comment' AND target_id = ? AND user_id = ?",
          parameters: [commentId, _currentUserId],
        );
        parsed['has_reacted'] = reacted != null;
        parsed['user_reaction'] = reacted?['reaction_type'];
      }

      return CommentModel.fromJson(parsed);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getCommentById');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET POST COMMENTS
  // ════════════════════════════════════════════════════════════

  /// Get comments for a post (threaded, with sorting)
  Future<CommentsList> getPostComments({
    required String postId,
    CommentSortBy sortBy = CommentSortBy.newest,
    int limit = 50,
    int offset = 0,
    String? parentCommentId,
  }) async {
    try {
      String orderClause;
      switch (sortBy) {
        case CommentSortBy.oldest:
          orderClause = 'c.created_at ASC';
          break;
        case CommentSortBy.top:
          orderClause =
              "COALESCE(json_extract(c.reactions_count, '\$.total'), 0) DESC, c.created_at DESC";
          break;
        case CommentSortBy.threaded:
          orderClause = 'c.thread_path ASC';
          break;
        case CommentSortBy.newest:
          orderClause = 'c.is_pinned DESC, c.created_at DESC';
          break;
      }

      String parentFilter = '';
      final params = <dynamic>[postId];

      if (parentCommentId != null) {
        parentFilter = 'AND (c.parent_comment_id = ? OR c.id = ?)';
        params.addAll([parentCommentId, parentCommentId]);
      }

      params.addAll([limit, offset]);

      final rows = await _powerSync.executeQuery('''
        SELECT c.*, 
               up.username, 
               up.profile_url,
               rtu.username as reply_to_username
        FROM comments c
        LEFT JOIN user_profiles up ON up.user_id = c.user_id
        LEFT JOIN user_profiles rtu ON rtu.user_id = c.reply_to_user_id
        WHERE c.post_id = ?
        $parentFilter
        ORDER BY $orderClause
        LIMIT ? OFFSET ?
        ''', parameters: params);

      final parsed = _parseRows(rows);

      // Add user interaction state
      if (_currentUserId != null) {
        for (final row in parsed) {
          final cId = row['id'] as String;
          final reacted = await _powerSync.querySingle(
            "SELECT reaction_type FROM reactions WHERE target_type = 'comment' AND target_id = ? AND user_id = ?",
            parameters: [cId, _currentUserId],
          );
          row['has_reacted'] = reacted != null;
          row['user_reaction'] = reacted?['reaction_type'];
        }
      }

      // Get total count
      final countResult = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM comments WHERE post_id = ? AND is_deleted = 0',
        parameters: [postId],
      );
      final totalCount = countResult?['count'] as int? ?? 0;

      return CommentsList.fromJsonList(
        postId,
        parsed,
        sortBy: sortBy,
        offset: offset,
        limit: limit,
        totalCount: totalCount,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getPostComments');
      return CommentsList(postId: postId);
    }
  }

  /// Get replies to a specific comment
  Future<List<CommentModel>> getCommentReplies({
    required String commentId,
    required String postId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _powerSync.executeQuery(
        '''
        SELECT c.*, 
               up.username, 
               up.profile_url,
               rtu.username as reply_to_username
        FROM comments c
        LEFT JOIN user_profiles up ON up.user_id = c.user_id
        LEFT JOIN user_profiles rtu ON rtu.user_id = c.reply_to_user_id
        WHERE c.parent_comment_id = ?
          AND c.post_id = ?
          AND c.is_deleted = 0
        ORDER BY c.thread_path ASC
        LIMIT ? OFFSET ?
        ''',
        parameters: [commentId, postId, limit, offset],
      );

      final parsed = _parseRows(rows);

      if (_currentUserId != null) {
        for (final row in parsed) {
          final cId = row['id'] as String;
          final reacted = await _powerSync.querySingle(
            "SELECT reaction_type FROM reactions WHERE target_type = 'comment' AND target_id = ? AND user_id = ?",
            parameters: [cId, _currentUserId],
          );
          row['has_reacted'] = reacted != null;
          row['user_reaction'] = reacted?['reaction_type'];
        }
      }

      return parsed.map((row) => CommentModel.fromJson(row)).toList();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'getCommentReplies');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // WATCH COMMENTS (Live Updates)
  // ════════════════════════════════════════════════════════════

  /// Watch comments on a post (live stream)
  Stream<List<CommentModel>> watchPostComments({
    required String postId,
    int limit = 50,
  }) {
    return _powerSync
        .watchQuery(
          '''
          SELECT c.*, 
                 up.username, 
                 up.profile_url,
                 rtu.username as reply_to_username
          FROM comments c
          LEFT JOIN user_profiles up ON up.user_id = c.user_id
          LEFT JOIN user_profiles rtu ON rtu.user_id = c.reply_to_user_id
          WHERE c.post_id = ?
          ORDER BY c.is_pinned DESC, c.created_at DESC
          LIMIT ?
          ''',
          parameters: [postId, limit],
        )
        .map(
          (rows) => _parseRows(
            rows,
          ).map((row) => CommentModel.fromJson(row)).toList(),
        );
  }

  /// Watch comment count on a post
  Stream<int> watchCommentCount(String postId) {
    return _powerSync
        .watchQuery(
          'SELECT COUNT(*) as count FROM comments WHERE post_id = ? AND is_deleted = 0',
          parameters: [postId],
        )
        .map(
          (rows) => rows.isNotEmpty ? (rows.first['count'] as int? ?? 0) : 0,
        );
  }

  // ════════════════════════════════════════════════════════════
  // EDIT COMMENT
  // ════════════════════════════════════════════════════════════

  /// Edit a comment's content
  Future<EditCommentResult> editComment({
    required String commentId,
    required String newContent,
  }) async {
    _ensureAuthenticated();

    try {
      final comment = await _powerSync.querySingle(
        'SELECT * FROM comments WHERE id = ? AND user_id = ? AND is_deleted = 0',
        parameters: [commentId, _currentUserId],
      );

      if (comment == null) {
        AppSnackbar.error('Comment not found or unauthorized');
        return const EditCommentResult(success: false);
      }

      final oldContent = comment['content'] as String;

      if (oldContent == newContent) {
        return const EditCommentResult(success: true, changed: false);
      }

      await _powerSync.update('comments', {
        'content': newContent,
        'is_edited': 1,
        'edited_at': DateTime.now().toIso8601String(),
      }, commentId);

      return EditCommentResult(
        success: true,
        changed: true,
        commentId: commentId,
        oldContent: oldContent,
        newContent: newContent,
        editedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'editComment');
      ErrorHandler.showErrorSnackbar(
        ErrorHandler.formatErrorMessage(error),
        title: 'Failed to edit comment',
      );
      return const EditCommentResult(success: false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // DELETE COMMENT (Soft Delete)
  // ════════════════════════════════════════════════════════════

  /// Delete a comment (by comment author or post author)
  Future<DeleteCommentResult> deleteComment({required String commentId}) async {
    _ensureAuthenticated();

    try {
      final comment = await _powerSync.querySingle(
        '''
        SELECT c.*, p.user_id as post_author_id
        FROM comments c
        JOIN posts p ON p.id = c.post_id
        WHERE c.id = ?
        ''',
        parameters: [commentId],
      );

      if (comment == null) {
        AppSnackbar.error('Comment not found');
        return const DeleteCommentResult(success: false);
      }

      final commentAuthorId = comment['user_id'] as String;
      final postAuthorId = comment['post_author_id'] as String;
      final postId = comment['post_id'] as String;
      final parentId = comment['parent_comment_id'] as String?;

      // Check authorization
      final isCommentAuthor = commentAuthorId == _currentUserId;
      final isPostAuthor = postAuthorId == _currentUserId;

      if (!isCommentAuthor && !isPostAuthor) {
        AppSnackbar.error('Unauthorized to delete this comment');
        return const DeleteCommentResult(success: false);
      }

      // Soft delete
      await _powerSync.update('comments', {'is_deleted': 1}, commentId);

      // Recalculate counts
      await _recalculatePostCommentCount(postId);
      if (parentId != null) {
        await _recalculateParentRepliesCount(parentId);
      }

      AppSnackbar.success('Comment deleted');

      return DeleteCommentResult(
        success: true,
        commentId: commentId,
        deletedBy: isPostAuthor && !isCommentAuthor
            ? 'post_author'
            : 'comment_author',
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'deleteComment');
      ErrorHandler.showErrorSnackbar(
        ErrorHandler.formatErrorMessage(error),
        title: 'Failed to delete comment',
      );
      return const DeleteCommentResult(success: false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // PIN COMMENT (Post author only)
  // ════════════════════════════════════════════════════════════

  /// Pin or unpin a comment (only 1 pinned comment per post)
  Future<PinCommentResult> togglePinComment({required String commentId}) async {
    _ensureAuthenticated();

    try {
      final comment = await _powerSync.querySingle(
        '''
        SELECT c.*, p.user_id as post_author_id
        FROM comments c
        JOIN posts p ON p.id = c.post_id
        WHERE c.id = ?
        ''',
        parameters: [commentId],
      );

      if (comment == null) {
        AppSnackbar.error('Comment not found');
        return const PinCommentResult(success: false);
      }

      final postAuthorId = comment['post_author_id'] as String;
      if (postAuthorId != _currentUserId) {
        AppSnackbar.error('Only the post author can pin comments');
        return const PinCommentResult(success: false);
      }

      final isPinned = (comment['is_pinned'] as int? ?? 0) == 1;
      final postId = comment['post_id'] as String;

      if (!isPinned) {
        // Unpin existing pinned comment
        await _powerSync.execute(
          'UPDATE comments SET is_pinned = 0, updated_at = ? WHERE post_id = ? AND is_pinned = 1',
          [DateTime.now().toIso8601String(), postId],
        );
      }

      // Toggle pin
      await _powerSync.update('comments', {
        'is_pinned': isPinned ? 0 : 1,
      }, commentId);

      AppSnackbar.success(isPinned ? 'Comment unpinned' : 'Comment pinned');

      return PinCommentResult(
        success: true,
        commentId: commentId,
        isPinned: !isPinned,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'togglePinComment');
      return const PinCommentResult(success: false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // HIDE COMMENT (Post author moderation)
  // ════════════════════════════════════════════════════════════

  /// Hide or unhide a comment (post author moderation)
  Future<HideCommentResult> toggleHideComment({
    required String commentId,
    bool hide = true,
  }) async {
    _ensureAuthenticated();

    try {
      final comment = await _powerSync.querySingle(
        '''
        SELECT c.*, p.user_id as post_author_id
        FROM comments c
        JOIN posts p ON p.id = c.post_id
        WHERE c.id = ?
        ''',
        parameters: [commentId],
      );

      if (comment == null) {
        AppSnackbar.error('Comment not found');
        return const HideCommentResult(success: false);
      }

      final postAuthorId = comment['post_author_id'] as String;
      if (postAuthorId != _currentUserId) {
        AppSnackbar.error('Only the post author can hide comments');
        return const HideCommentResult(success: false);
      }

      await _powerSync.update('comments', {
        'is_hidden': hide ? 1 : 0,
      }, commentId);

      AppSnackbar.success(hide ? 'Comment hidden' : 'Comment visible');

      return HideCommentResult(
        success: true,
        commentId: commentId,
        isHidden: hide,
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'toggleHideComment');
      return const HideCommentResult(success: false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // COMMENT COUNT
  // ════════════════════════════════════════════════════════════

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM comments WHERE post_id = ? AND is_deleted = 0',
        parameters: [postId],
      );
      return result?['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get reply count for a comment
  Future<int> getReplyCount(String commentId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM comments WHERE parent_comment_id = ? AND is_deleted = 0',
        parameters: [commentId],
      );
      return result?['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BATCH: User interaction on multiple comments
  // ════════════════════════════════════════════════════════════

  /// Check which comments the current user has reacted to
  Future<Map<String, String?>> batchGetUserCommentReactions(
    List<String> commentIds,
  ) async {
    _ensureAuthenticated();

    if (commentIds.isEmpty) return {};

    try {
      final placeholders = List.generate(
        commentIds.length,
        (_) => '?',
      ).join(',');

      final rows = await _powerSync.executeQuery(
        '''
        SELECT target_id, reaction_type
        FROM reactions
        WHERE user_id = ?
          AND target_type = 'comment'
          AND target_id IN ($placeholders)
        ''',
        parameters: [_currentUserId, ...commentIds],
      );

      final result = <String, String?>{};
      for (final id in commentIds) {
        result[id] = null;
      }
      for (final row in rows) {
        result[row['target_id'] as String] = row['reaction_type'] as String?;
      }

      return result;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        'batchGetUserCommentReactions',
      );
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  // SUPABASE RPC (Online)
  // ════════════════════════════════════════════════════════════

  /// Add comment via Supabase RPC
  Future<CommentModel?> addCommentViaServer({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentions,
    List<String>? mentionedUsernames,
    CommentMedia? media,
  }) async {
    _ensureAuthenticated();

    try {
      if (!_powerSync.isOnline) {
        return addComment(
          postId: postId,
          content: content,
          parentCommentId: parentCommentId,
          mentions: mentions,
          mentionedUsernames: mentionedUsernames,
          media: media,
        );
      }

      final response = await _supabase.rpc(
        'add_comment',
        params: {
          'p_user_id': _currentUserId,
          'p_post_id': postId,
          'p_content': content,
          if (parentCommentId != null && parentCommentId.isNotEmpty)
            'p_parent_comment_id': parentCommentId,
          if (mentions != null && mentions.isNotEmpty) 'p_mentions': mentions,
          if (mentionedUsernames != null && mentionedUsernames.isNotEmpty)
            'p_mentioned_usernames': mentionedUsernames,
          if (media != null) 'p_media': media.toJson(),
        },
      );

      if (response is Map<String, dynamic>) {
        final result = AddCommentResult.fromJson(response);
        if (result.success) {
          return result.toCommentModel(postId: postId);
        }
      }

      return null;
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'addCommentViaServer');
      return addComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
        mentions: mentions,
        mentionedUsernames: mentionedUsernames,
        media: media,
      );
    }
  }

  /// Get post comments via Supabase RPC
  Future<CommentsList> fetchPostCommentsFromServer({
    required String postId,
    CommentSortBy sortBy = CommentSortBy.newest,
    int limit = 50,
    int offset = 0,
    String? parentCommentId,
  }) async {
    _ensureAuthenticated();

    try {
      if (!_powerSync.isOnline) {
        return getPostComments(
          postId: postId,
          sortBy: sortBy,
          limit: limit,
          offset: offset,
          parentCommentId: parentCommentId,
        );
      }

      final response = await _supabase.rpc(
        'get_post_comments',
        params: {
          'p_post_id': postId,
          'p_requesting_user_id': _currentUserId,
          'p_sort_by': sortBy.name,
          'p_limit': limit,
          'p_offset': offset,
          if (parentCommentId != null) 'p_parent_comment_id': parentCommentId,
        },
      );

      if (response is List) {
        return CommentsList.fromJsonList(
          postId,
          response,
          sortBy: sortBy,
          offset: offset,
          limit: limit,
        );
      }

      return CommentsList(postId: postId);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace,
        'fetchPostCommentsFromServer',
      );
      return getPostComments(
        postId: postId,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        parentCommentId: parentCommentId,
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // PRIVATE: COUNT RECALCULATION
  // ════════════════════════════════════════════════════════════

  /// Recalculate comment count on a post
  Future<void> _recalculatePostCommentCount(String postId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM comments WHERE post_id = ? AND is_deleted = 0',
        parameters: [postId],
      );
      final count = result?['count'] as int? ?? 0;

      await _powerSync.update('posts', {'comments_count': count}, postId);
    } catch (e) {
      logW('Failed to recalculate post comment count: $e');
    }
  }

  /// Recalculate replies count on a parent comment
  Future<void> _recalculateParentRepliesCount(String parentCommentId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM comments WHERE parent_comment_id = ? AND is_deleted = 0',
        parameters: [parentCommentId],
      );
      final count = result?['count'] as int? ?? 0;

      await _powerSync.update('comments', {
        'replies_count': count,
      }, parentCommentId);
    } catch (e) {
      logW('Failed to recalculate parent replies count: $e');
    }
  }

  /// Force recalculate all counts for a post's comments
  Future<void> recalculateAllCounts(String postId) async {
    try {
      await _recalculatePostCommentCount(postId);

      final parents = await _powerSync.executeQuery(
        'SELECT DISTINCT parent_comment_id FROM comments WHERE post_id = ? AND parent_comment_id IS NOT NULL',
        parameters: [postId],
      );

      for (final row in parents) {
        final parentId = row['parent_comment_id'] as String;
        await _recalculateParentRepliesCount(parentId);
      }

      logI('Recalculated all comment counts for post $postId');
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace, 'recalculateAllCounts');
    }
  }
}

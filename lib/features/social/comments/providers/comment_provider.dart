// ============================================================
// 📁 providers/comment_provider.dart (ENHANCED)
// Complete Comment Provider with UI State Management
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';

import '../repositories/comment_repository.dart';
import '../models/comments_model.dart';
import 'package:the_time_chart/widgets/error_handler.dart';

class CommentProvider extends ChangeNotifier {
  final CommentRepository _repository;

  // ════════════════════════════════════════════════════════════
  // STATE - COMMENTS LISTS
  // ════════════════════════════════════════════════════════════
  final Map<String, CommentsList> _commentsLists = {};
  final Map<String, bool> _repliesLoading = {};
  final Map<String, bool> _expandedComments = {};
  final Map<String, CommentInputState> _inputStates = {};

  String? _activePostId;
  bool _isLoading = false;
  String? _error;

  CommentProvider({CommentRepository? repository})
    : _repository = repository ?? CommentRepository();

  // ════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get activePostId => _activePostId;

  CommentsList getCommentsList(String postId) {
    return _commentsLists[postId] ?? CommentsList(postId: postId);
  }

  CommentInputState getInputState(String postId) {
    return _inputStates[postId] ?? const CommentInputState();
  }

  bool isRepliesLoading(String commentId) {
    return _repliesLoading[commentId] ?? false;
  }

  bool isExpanded(String commentId) {
    return _expandedComments[commentId] ?? false;
  }

  // ════════════════════════════════════════════════════════════
  // SET ACTIVE POST
  // ════════════════════════════════════════════════════════════
  void setActivePost(String? postId) {
    _activePostId = postId;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // LOAD COMMENTS
  // ════════════════════════════════════════════════════════════
  Future<void> loadComments({
    required String postId,
    CommentSortBy sortBy = CommentSortBy.top,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;

    if (refresh) {
      _commentsLists[postId] = CommentsList(postId: postId, isLoading: true);
    } else {
      _commentsLists[postId] =
          (_commentsLists[postId] ?? CommentsList(postId: postId)).copyWith(
            isLoading: true,
          );
    }

    notifyListeners();

    try {
      final comments = await _repository.fetchPostCommentsFromServer(
        postId: postId,
        sortBy: sortBy,
        offset: refresh ? 0 : (_commentsLists[postId]?.offset ?? 0),
      );

      if (refresh || _commentsLists[postId] == null) {
        _commentsLists[postId] = comments;
      } else {
        final existing = _commentsLists[postId]!;
        _commentsLists[postId] = existing.copyWith(
          comments: [...existing.comments, ...comments.comments],
          offset: comments.offset,
          totalCount: comments.totalCount,
        );
      }
    } catch (e) {
      _error = 'Failed to load comments';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // LOAD REPLIES
  // ════════════════════════════════════════════════════════════
  Future<void> loadReplies({
    required String postId,
    required String commentId,
  }) async {
    if (_repliesLoading[commentId] == true) return;

    _repliesLoading[commentId] = true;
    notifyListeners();

    try {
      final replies = await _repository.getCommentReplies(
        commentId: commentId,
        postId: postId,
      );

      // Update the comment with its replies
      final currentList = _commentsLists[postId];
      if (currentList != null) {
        final updatedComments = currentList.comments.map((c) {
          if (c.id == commentId) {
            return c.copyWith(
              replies: replies,
              isRepliesLoaded: true,
              isExpanded: true,
            );
          }
          return c;
        }).toList();

        _commentsLists[postId] = currentList.copyWith(
          comments: updatedComments,
        );
      }

      _expandedComments[commentId] = true;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load replies');
    }

    _repliesLoading[commentId] = false;
    notifyListeners();
  }

  Future<void> loadMoreReplies({
    required String postId,
    required String commentId,
  }) async {
    final currentList = _commentsLists[postId];
    if (currentList == null) return;

    final comment = currentList.comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => CommentModel.empty(),
    );

    if (comment.isEmpty || _repliesLoading[commentId] == true) return;

    _repliesLoading[commentId] = true;
    notifyListeners();

    try {
      final moreReplies = await _repository.getCommentReplies(
        commentId: commentId,
        postId: postId,
        offset: comment.replies.length,
      );

      final updatedComments = currentList.comments.map((c) {
        if (c.id == commentId) {
          return c.copyWith(replies: [...c.replies, ...moreReplies]);
        }
        return c;
      }).toList();

      _commentsLists[postId] = currentList.copyWith(comments: updatedComments);
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load more replies');
    }

    _repliesLoading[commentId] = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // TOGGLE REPLIES
  // ════════════════════════════════════════════════════════════
  void toggleReplies({required String postId, required String commentId}) {
    final isCurrentlyExpanded = _expandedComments[commentId] ?? false;

    if (isCurrentlyExpanded) {
      _expandedComments[commentId] = false;
      _updateCommentInList(postId, commentId, (comment) {
        return comment.copyWith(isExpanded: false);
      });
    } else {
      final comment = _findComment(postId, commentId);
      if (comment != null && !comment.isRepliesLoaded && comment.hasReplies) {
        loadReplies(postId: postId, commentId: commentId);
      } else {
        _expandedComments[commentId] = true;
        _updateCommentInList(postId, commentId, (comment) {
          return comment.copyWith(isExpanded: true);
        });
      }
    }

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // ADD COMMENT
  // ════════════════════════════════════════════════════════════
  Future<CommentModel?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentions,
    CommentMedia? media,
  }) async {
    final inputState = _inputStates[postId] ?? const CommentInputState();

    _inputStates[postId] = inputState.copyWith(isSubmitting: true);
    notifyListeners();

    try {
      final comment = await _repository.addCommentViaServer(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
        mentions: mentions,
        mentionedUsernames: _extractUsernames(content),
        media: media,
      );

      if (comment != null) {
        final currentList = _commentsLists[postId];
        if (currentList != null) {
          if (parentCommentId != null) {
            // Add as reply
            final updatedComments = currentList.comments.map((c) {
              if (c.id == parentCommentId) {
                return c.copyWith(
                  replies: [...c.replies, comment],
                  repliesCount: c.repliesCount + 1,
                  isRepliesLoaded: true,
                  isExpanded: true,
                );
              }
              return c;
            }).toList();

            _commentsLists[postId] = currentList.copyWith(
              comments: updatedComments,
              totalCount: currentList.totalCount + 1,
            );

            _expandedComments[parentCommentId] = true;
          } else {
            // Add as root comment
            _commentsLists[postId] = currentList.addComment(comment);
          }
        }

        // Clear input state
        _inputStates[postId] = const CommentInputState();
        notifyListeners();

        return comment;
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to add comment');
    }

    _inputStates[postId] = inputState.copyWith(isSubmitting: false);
    notifyListeners();
    return null;
  }

  // ════════════════════════════════════════════════════════════
  // EDIT COMMENT
  // ════════════════════════════════════════════════════════════
  Future<bool> editComment({
    required String commentId,
    required String newContent,
    required String postId,
  }) async {
    try {
      final result = await _repository.editComment(
        commentId: commentId,
        newContent: newContent,
      );

      if (result.success && result.changed) {
        _updateCommentInList(postId, commentId, (comment) {
          return comment.copyWith(
            content: newContent,
            isEdited: true,
            editedAt: result.editedAt ?? DateTime.now(),
          );
        });

        _inputStates[postId] = const CommentInputState();
        notifyListeners();
        return true;
      }

      return result.success;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to edit comment');
      return false;
    }
  }

  void startEditing(String postId, CommentModel comment) {
    _inputStates[postId] = CommentInputState.editing(comment);
    notifyListeners();
  }

  void cancelEditing(String postId) {
    _inputStates[postId] = const CommentInputState();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // DELETE COMMENT
  // ════════════════════════════════════════════════════════════
  Future<bool> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      final comment = _findComment(postId, commentId);
      final parentId = comment?.parentCommentId;

      final result = await _repository.deleteComment(commentId: commentId);

      if (result.success) {
        final currentList = _commentsLists[postId];
        if (currentList != null) {
          if (parentId != null) {
            // Remove from parent's replies
            final updatedComments = currentList.comments.map((c) {
              if (c.id == parentId) {
                return c.copyWith(
                  replies: c.replies.where((r) => r.id != commentId).toList(),
                  repliesCount: (c.repliesCount - 1).clamp(0, c.repliesCount),
                );
              }
              return c;
            }).toList();

            _commentsLists[postId] = currentList.copyWith(
              comments: updatedComments,
              totalCount: (currentList.totalCount - 1).clamp(
                0,
                currentList.totalCount,
              ),
            );
          } else {
            _commentsLists[postId] = currentList.removeComment(commentId);
          }
        }

        _expandedComments.remove(commentId);
        _repliesLoading.remove(commentId);
        notifyListeners();

        return true;
      }

      return false;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to delete comment');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // PIN/UNPIN COMMENT
  // ════════════════════════════════════════════════════════════
  Future<bool> togglePinComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      final result = await _repository.togglePinComment(commentId: commentId);

      if (result.success) {
        final currentList = _commentsLists[postId];
        if (currentList != null) {
          if (result.isPinned) {
            _commentsLists[postId] = currentList.pinComment(commentId);
          } else {
            _commentsLists[postId] = currentList.unpinComment();
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to pin comment');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // HIDE/UNHIDE COMMENT
  // ════════════════════════════════════════════════════════════
  Future<bool> toggleHideComment({
    required String commentId,
    required String postId,
    bool hide = true,
  }) async {
    try {
      final result = await _repository.toggleHideComment(
        commentId: commentId,
        hide: hide,
      );

      if (result.success) {
        _updateCommentInList(postId, commentId, (comment) {
          return comment.copyWith(isHidden: result.isHidden);
        });

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to hide comment');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // INPUT STATE MANAGEMENT
  // ════════════════════════════════════════════════════════════
  void updateInputText(String postId, String text) {
    final currentState = _inputStates[postId] ?? const CommentInputState();

    _inputStates[postId] = currentState.copyWith(
      text: text,
      detectedMentions: CommentInputState.extractMentions(text),
      detectedHashtags: CommentInputState.extractHashtags(text),
    );

    notifyListeners();
  }

  void startReply(String postId, CommentModel comment) {
    _inputStates[postId] = CommentInputState.replying(comment);
    notifyListeners();
  }

  void cancelReply(String postId) {
    final currentState = _inputStates[postId];
    if (currentState != null) {
      _inputStates[postId] = currentState.copyWith(clearReply: true, text: '');
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════
  // REACTION UPDATES
  // ════════════════════════════════════════════════════════════
  void updateCommentReaction({
    required String postId,
    required String commentId,
    required String? reactionType,
    required int totalReactions,
  }) {
    _updateCommentInList(postId, commentId, (comment) {
      final newReactionsCount = Map<String, dynamic>.from(
        comment.reactionsCountRaw ?? {},
      );
      newReactionsCount['total'] = totalReactions;

      return comment.copyWith(
        reactionsCountRaw: newReactionsCount,
        hasReacted: reactionType != null,
        userReaction: reactionType,
      );
    });

    _updateCommentInReplies(postId, commentId, (comment) {
      final newReactionsCount = Map<String, dynamic>.from(
        comment.reactionsCountRaw ?? {},
      );
      newReactionsCount['total'] = totalReactions;

      return comment.copyWith(
        reactionsCountRaw: newReactionsCount,
        hasReacted: reactionType != null,
        userReaction: reactionType,
      );
    });

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ════════════════════════════════════════════════════════════
  CommentModel? _findComment(String postId, String commentId) {
    final list = _commentsLists[postId];
    if (list == null) return null;

    for (final comment in list.comments) {
      if (comment.id == commentId) return comment;
      for (final reply in comment.replies) {
        if (reply.id == commentId) return reply;
      }
    }

    return list.pinnedComment?.id == commentId ? list.pinnedComment : null;
  }

  void _updateCommentInList(
    String postId,
    String commentId,
    CommentModel Function(CommentModel) update,
  ) {
    final currentList = _commentsLists[postId];
    if (currentList == null) return;

    final updatedComments = currentList.comments.map((c) {
      if (c.id == commentId) {
        return update(c);
      }
      return c;
    }).toList();

    CommentModel? updatedPinned = currentList.pinnedComment;
    if (updatedPinned?.id == commentId) {
      updatedPinned = update(updatedPinned!);
    }

    _commentsLists[postId] = currentList.copyWith(
      comments: updatedComments,
      pinnedComment: updatedPinned,
    );
  }

  void _updateCommentInReplies(
    String postId,
    String commentId,
    CommentModel Function(CommentModel) update,
  ) {
    final currentList = _commentsLists[postId];
    if (currentList == null) return;

    final updatedComments = currentList.comments.map((c) {
      final updatedReplies = c.replies.map((r) {
        if (r.id == commentId) {
          return update(r);
        }
        return r;
      }).toList();

      if (updatedReplies != c.replies) {
        return c.copyWith(replies: updatedReplies);
      }
      return c;
    }).toList();

    _commentsLists[postId] = currentList.copyWith(comments: updatedComments);
  }

  List<String> _extractUsernames(String content) {
    final regex = RegExp(r'@(\w+)');
    return regex.allMatches(content).map((m) => m.group(1)!).toList();
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════
  void clearCommentsForPost(String postId) {
    _commentsLists.remove(postId);
    _inputStates.remove(postId);
    _expandedComments.removeWhere(
      (key, _) => _findComment(postId, key) != null,
    );
    _repliesLoading.removeWhere((key, _) => _findComment(postId, key) != null);

    if (_activePostId == postId) {
      _activePostId = null;
    }

    notifyListeners();
  }

  void clearCache() {
    _commentsLists.clear();
    _repliesLoading.clear();
    _expandedComments.clear();
    _inputStates.clear();
    _activePostId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}

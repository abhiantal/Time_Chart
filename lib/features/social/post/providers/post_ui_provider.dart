import 'package:flutter/material.dart';

class PostUIProvider extends ChangeNotifier {
  // Active media index per post
  final Map<String, int> _activeMediaIndex = {};

  // Expanded/collapsed state per post
  final Map<String, bool> _expandedPosts = {};

  // Reaction picker state per post
  final Map<String, bool> _reactionPickerOpen = {};

  // Currently replying to comment
  String? _activeReplyCommentId;
  String? _activeReplyPostId;

  // Getters
  int getActiveMediaIndex(String postId) {
    return _activeMediaIndex[postId] ?? 0;
  }

  bool isPostExpanded(String postId) {
    return _expandedPosts[postId] ?? false;
  }

  bool isReactionPickerOpen(String postId) {
    return _reactionPickerOpen[postId] ?? false;
  }

  String? get activeReplyCommentId => _activeReplyCommentId;
  String? get activeReplyPostId => _activeReplyPostId;

  // Setters
  void setActiveMediaIndex(String postId, int index) {
    _activeMediaIndex[postId] = index;
    notifyListeners();
  }

  void togglePostExpanded(String postId) {
    _expandedPosts[postId] = !(_expandedPosts[postId] ?? false);
    notifyListeners();
  }

  void setReactionPickerOpen(String postId, bool isOpen) {
    _reactionPickerOpen[postId] = isOpen;
    notifyListeners();
  }

  void setActiveReply(String postId, String commentId) {
    _activeReplyPostId = postId;
    _activeReplyCommentId = commentId;
    notifyListeners();
  }

  void clearActiveReply() {
    _activeReplyPostId = null;
    _activeReplyCommentId = null;
    notifyListeners();
  }

  // Cleanup
  void clearPostState(String postId) {
    _activeMediaIndex.remove(postId);
    _expandedPosts.remove(postId);
    _reactionPickerOpen.remove(postId);

    if (_activeReplyPostId == postId) {
      _activeReplyPostId = null;
      _activeReplyCommentId = null;
    }

    notifyListeners();
  }

  void clearAll() {
    _activeMediaIndex.clear();
    _expandedPosts.clear();
    _reactionPickerOpen.clear();
    _activeReplyPostId = null;
    _activeReplyCommentId = null;
    notifyListeners();
  }
}

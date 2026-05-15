import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import '../../../../../widgets/logger.dart';
import '../models/post_model.dart';
import '../repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _repository;

  PostProvider({PostRepository? repository})
      : _repository = repository ?? PostRepository();

  List<FeedPost> _feedPosts = [];
  List<FeedPost> get feedPosts => _feedPosts;

  List<ExplorePost> _explorePosts = [];
  List<ExplorePost> get explorePosts => _explorePosts;

  // Cache user posts by userId to prevent data leakage between profile views
  final Map<String, List<PostModel>> _userPostsMap = {};
  List<PostModel> get userPosts => _userPostsMap.values.expand((element) => element).toList(); // Overall fallback
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingFeed = false;
  bool get isLoadingFeed => _isLoadingFeed;

  bool _isLoadingExplore = false;
  bool get isLoadingExplore => _isLoadingExplore;

  bool _isLoadingUser = false;
  bool get isLoadingUser => _isLoadingUser;

  bool _hasMoreFeed = true;
  bool get hasMoreFeed => _hasMoreFeed;

  bool _hasMoreExplore = true;
  bool get hasMoreExplore => _hasMoreExplore;

  String? _error;
  String? get error => _error;

  final Map<String, PostModel> _postCache = {};

  // =================================================================
  // CREATE / SHARE
  // =================================================================
  Future<PostModel?> createPost({
    required String userId,
    PostType? postType,
    String? caption,
    List<PostMedia> media = const [],
    PostVisibility visibility = PostVisibility.public,
    ArticleData? articleData,
    PollData? pollData,
    int? durationSeconds,
    String? thumbnailUrl,
    AdData? adData,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final post = await _repository.createPost(
        userId: userId,
        postType: postType,
        caption: caption,
        media: media,
        visibility: visibility,
        articleData: articleData,
        pollData: pollData,
        durationSeconds: durationSeconds,
        thumbnailUrl: thumbnailUrl,
        adData: adData,
      );

      if (post != null) {
        _postCache[post.id] = post;
        // Add to user posts map
        if (!_userPostsMap.containsKey(userId)) {
          _userPostsMap[userId] = [];
        }
        _userPostsMap[userId]!.insert(0, post);
        
        // Add to feed if it's a normal post
        _feedPosts.insert(0, FeedPost(post: post));
      }
      return post;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PostModel?> createPostFromSource({
    required String sourceType,
    required String sourceId,
    String? sourceMode,
    String? caption,
    String visibility = 'public',
    bool isLive = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final post = await _repository.createPostFromSource(
        sourceType: sourceType,
        sourceId: sourceId,
        sourceMode: sourceMode,
        caption: caption,
        visibility: visibility,
        isLive: isLive,
      );

      if (post != null) {
        _postCache[post.id] = post;
        _feedPosts.insert(0, FeedPost(post: post));
      }
      return post;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =================================================================
  // FEED LOADING
  // =================================================================
  Future<void> loadHomeFeed({bool refresh = false}) async {
    if (_isLoadingFeed) return;
    _isLoadingFeed = true;
    _error = null;
    if (refresh) {
      _hasMoreFeed = true;
      notifyListeners();
    }

    try {
      final posts = await _repository.getHomeFeed(
        limit: 20,
        offset: refresh ? 0 : _feedPosts.length,
      );

      if (refresh) {
        _feedPosts = posts;
      } else {
        _feedPosts.addAll(posts);
      }

      _hasMoreFeed = posts.length == 20;

      for (var fp in posts) {
        _postCache[fp.post.id] = fp.post;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> loadExploreFeed({bool refresh = false}) async {
    if (_isLoadingExplore) return;
    _isLoadingExplore = true;
    _error = null;
    if (refresh) {
      _hasMoreExplore = true;
      notifyListeners();
    }

    try {
      final posts = await _repository.getExploreFeed(
        limit: 20,
        offset: refresh ? 0 : _explorePosts.length,
      );

      if (refresh) {
        _explorePosts = posts;
      } else {
        _explorePosts.addAll(posts);
      }

      _hasMoreExplore = posts.length == 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingExplore = false;
      notifyListeners();
    }
  }

  // =================================================================
  // INTERACTIONS
  // =================================================================
  Future<bool> updatePost({
    required String postId,
    String? caption,
    PostVisibility? visibility,
  }) async {
    try {
      final success = await _repository.updatePost(
        postId: postId,
        caption: caption,
        visibility: visibility,
      );

      if (success) {
        final cached = _postCache[postId];
        if (cached != null) {
          final updated = cached.copyWith(
            caption: caption,
            visibility: visibility,
          );
          _postCache[postId] = updated;
          
          // Update in feeds
          final feedIdx = _feedPosts.indexWhere((fp) => fp.post.id == postId);
          if (feedIdx != -1) {
            _feedPosts[feedIdx] = _feedPosts[feedIdx].copyWith(post: updated);
          }
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final success = await _repository.deletePost(postId);
      if (success) {
        _feedPosts.removeWhere((fp) => fp.post.id == postId);
        _explorePosts.removeWhere((ep) => ep.post.id == postId);
        _postCache.remove(postId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> votePoll({required String postId, required String optionId}) async {
    await _repository.votePoll(postId: postId, optionId: optionId);
    // Refresh post in cache
    final updated = await _repository.getPostById(postId);
    if (updated != null) {
      _postCache[postId] = updated;
      final idx = _feedPosts.indexWhere((fp) => fp.post.id == postId);
      if (idx != -1) {
        _feedPosts[idx] = _feedPosts[idx].copyWith(post: updated);
      }
      notifyListeners();
    }
  }

  PostModel? getCachedPost(String postId) => _postCache[postId];

  Future<void> loadUserPosts(String userId) async {
    if (_isLoadingUser) return;
    _isLoadingUser = true;
    notifyListeners();

    try {
      final posts = await _repository.getUserPosts(userId);
      _userPostsMap[userId] = posts;
      for (final p in posts) {
        _postCache[p.id] = p;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  List<PostModel> getUserPosts(String userId) => _userPostsMap[userId] ?? [];
  bool isLoadingUserPosts(String userId) => _isLoadingUser;

  Future<int> getPostCount(String userId) => _repository.getPostCount(userId);
  Stream<int> watchPostCount(String userId) => _repository.watchPostCount(userId);

  Future<void> reportPost({required String postId, required String reason}) async {
    // Basic implementation for now
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> removePostBySourceId(String sourceId) async {
    final post = await _repository.getPostBySource(sourceType: 'any', sourceId: sourceId);
    if (post != null) {
      await deletePost(post.id);
    }
  }

  // ================================================================
  // SHARE POST
  // ================================================================

  /// Shares a post with multiple chats
  Future<int> sharePostViaChat({
    required PostModel post,
    required List<String> chatIds,
    String? messageText,
  }) async {
    int successCount = 0;
    final chatRepository = ChatRepository();

    for (final chatId in chatIds) {
      try {
        await chatRepository.sendSharedContent(
          chatId: chatId,
          contentType: SharedContentType.post,
          contentId: post.id,
          caption: messageText,
        );
        successCount++;
      } catch (e) {
        logE('Error sharing post ${post.id} to chat $chatId', error: e);
      }
    }

    return successCount;
  }
}

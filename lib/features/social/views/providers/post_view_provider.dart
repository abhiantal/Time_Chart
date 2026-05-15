// ============================================================
// 📁 providers/post_view_provider.dart
// Post View Provider - State management for views & analytics
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/post_views_model.dart';
import '../repositories/post_view_repository.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';

class PostViewProvider extends ChangeNotifier {
  final PostViewRepository _repository;

  // Analytics Cache
  final Map<String, PostAnalytics> _analyticsCache = {};

  // Viewer List Cache (Story ID -> List Model)
  final Map<String, StoryViewersListModel> _storyViewersCache = {};

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  PostViewProvider({PostViewRepository? repository})
    : _repository = repository ?? PostViewRepository();

  // ════════════════════════════════════════════════════════════
  // VIEW RECORDING
  // ════════════════════════════════════════════════════════════

  /// Record a view (with debounce handled in UI or repo)
  Future<RecordViewResult> recordView({
    required String postId,
    ViewSource source = ViewSource.feed,
  }) async {
    try {
      return await _repository.recordView(postId: postId, source: source);
    } catch (e, stack) {
      ErrorHandler.logError(e.toString(), stack);
      // Return failed/empty result on error
      return RecordViewResult(
        success: false,
        isNewView: false,
        action: ViewRecordAction.recorded, // or none
      );
    }
  }

  /// Record view with manual debounce (if needed strictly here)
  Future<void> recordViewDebounced({
    required String postId,
    ViewSource source = ViewSource.feed,
  }) async {
    await _repository.recordViewDebounced(postId: postId, source: source);
  }

  Future<void> recordViewWithDebounce({
    required String postId,
    ViewSource source = ViewSource.feed,
  }) async {
    return recordViewDebounced(postId: postId, source: source);
  }

  /// Update video progress
  Future<void> updateVideoProgress({
    required String postId,
    required int duration,
    required int percent,
    bool completed = false,
  }) async {
    try {
      await _repository.updateViewProgress(
        postId: postId,
        durationSeconds: duration,
        viewPercent: percent,
        completed: completed,
      );
    } catch (e) {
      // Background operation, just log
      logE('Error updating video progress', error: e);
    }
  }

  /// Record ad click
  Future<void> recordAdClick(String postId) async {
    try {
      await _repository.recordAdClick(postId);
    } catch (e) {
      logE('Error recording ad click', error: e);
    }
  }

  // ════════════════════════════════════════════════════════════
  // ANALYTICS LOADING
  // ════════════════════════════════════════════════════════════

  /// Load stats for a post
  Future<PostAnalytics> loadAnalytics({
    required String postId,
    int days = 30,
    bool forceRefresh = false,
  }) async {
    // Return cached if available and not forcing refresh
    if (!forceRefresh && _analyticsCache.containsKey(postId)) {
      return _analyticsCache[postId]!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final analytics = await _repository.getPostAnalytics(
        postId: postId,
        days: days,
      );
      _analyticsCache[postId] = analytics;
      return analytics;
    } catch (e) {
      _error = 'Failed to load analytics: ${e.toString()}';
      // ErrorHandler.showErrorSnackbar(_error!);
      return PostAnalytics.empty(postId); // fail gracefully
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get cached analytics
  PostAnalytics? getCachedAnalytics(String postId) {
    return _analyticsCache[postId];
  }

  /// Clear specific cache
  void clearAnalyticsCache(String postId) {
    _analyticsCache.remove(postId);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // STORY VIEWERS
  // ════════════════════════════════════════════════════════════

  /// Load story viewers
  Future<void> loadStoryViewers({
    required String storyId,
    bool refresh = false,
  }) async {
    if (!refresh && _storyViewersCache.containsKey(storyId)) return;

    _isLoading = true;
    notifyListeners();

    try {
      final viewers = await _repository.getStoryViewers(storyId: storyId);
      _storyViewersCache[storyId] = viewers;
    } catch (e) {
      _error = 'Failed to load viewers';
      // ErrorHandler.showErrorSnackbar(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more viewers (pagination)
  Future<void> loadMoreStoryViewers(String storyId) async {
    final current = _storyViewersCache[storyId];
    if (current == null || !current.hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextBatch = await _repository.getStoryViewers(
        storyId: storyId,
        offset: current.offset,
      );

      _storyViewersCache[storyId] = current.appendViewers(nextBatch.viewers);
    } catch (e) {
      _error = 'Failed to load more viewers';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  StoryViewersListModel? getStoryViewers(String storyId) {
    return _storyViewersCache[storyId];
  }

  // ════════════════════════════════════════════════════════════
  // STREAMS
  // ════════════════════════════════════════════════════════════

  Stream<int> watchViewCount(String postId) =>
      _repository.watchViewCount(postId);

  Stream<StoryViewersListModel> watchStoryViewers(String storyId) =>
      _repository.watchStoryViewers(storyId: storyId);

  /// Reset state
  void reset() {
    _analyticsCache.clear();
    _storyViewersCache.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

// ============================================================
// 📁 repositories/post_view_repository.dart
// Post View Repository - View tracking & analytics operations
// Uses PowerSync for offline-first + Supabase RPC for analytics
// ============================================================

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';

class PostViewRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  // Local tracking state to prevent duplicate API calls
  final Map<String, ViewTrackingState> _trackingStates = {};

  PostViewRepository({PowerSyncService? powerSync, SupabaseClient? supabase})
    : _powerSync = powerSync ?? PowerSyncService(),
      _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ════════════════════════════════════════════════════════════
  // RECORD VIEW
  // ════════════════════════════════════════════════════════════

  /// Record a view on a post (with deduplication)
  Future<RecordViewResult> recordView({
    required String postId,
    ViewSource source = ViewSource.feed,
    int? durationSeconds,
    int? viewPercent,
    bool? completed,
  }) async {
    try {
      final userId = _currentUserId;

      // Check local tracking state first
      final existingState = _trackingStates[postId];
      if (existingState != null && !existingState.shouldRecord) {
        logD('View already recorded today for $postId, skipping');
        return RecordViewResult(
          success: true,
          isNewView: false,
          action: ViewRecordAction.updated,
        );
      }

      // Determine device type and platform
      final deviceType = _getDeviceType();
      final platform = _getPlatform();

      final response = await _supabase.rpc(
        'record_view',
        params: {
          'p_post_id': postId,
          'p_user_id': userId,
          'p_view_source': source.name,
          'p_view_duration_seconds': durationSeconds,
          'p_view_percent': viewPercent,
          'p_completed': completed,
          'p_device_type': deviceType?.name,
          'p_platform': platform?.name,
        },
      );

      final result = RecordViewResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      // Update local tracking state
      _trackingStates[postId] = ViewTrackingState(
        postId: postId,
        isRecorded: true,
        recordedAt: DateTime.now(),
        source: source,
      );

      if (result.isNewView) {
        logI('✓ Recorded new view for post: $postId');
      }

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(
        e,
        stack,
        'recordView (falling back to offline loop)',
      );

      try {
        final userId = _currentUserId;
        if (userId != null) {
          final today = DateTime.now();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          await _powerSync.insert('post_views', {
            'id': const Uuid().v4(),
            'post_id': postId,
            'user_id': userId,
            'view_date': dateStr,
            'view_source': source.name,
            'view_duration_seconds': durationSeconds ?? 0,
            'view_percent': viewPercent ?? 0,
            'completed': (completed == true) ? 1 : 0,
            'clicked_cta': 0,
            'device_type': _getDeviceType()?.name,
            'platform': _getPlatform()?.name,
            'created_at': today.toIso8601String(),
            'updated_at': today.toIso8601String(),
          });
          logI(
            '✓ Recorded VIEW offline in local PowerSync database for post: $postId',
          );
        }
      } catch (localE) {
        logE('Failed to save offline view locally', error: localE);
      }

      // Return success anyway for offline support
      return RecordViewResult(
        success: true,
        isNewView: true,
        action: ViewRecordAction.recorded,
      );
    }
  }

  /// Record view with debounce (for scroll-based viewing)
  Future<void> recordViewDebounced({
    required String postId,
    ViewSource source = ViewSource.feed,
    Duration minViewTime = const Duration(seconds: 2),
  }) async {
    // Check if already tracked
    if (_trackingStates[postId]?.isRecorded == true) {
      return;
    }

    // Mark as pending
    _trackingStates[postId] = ViewTrackingState(postId: postId, source: source);

    // Wait for minimum view time
    await Future.delayed(minViewTime);

    // Check if still viewing (not scrolled away)
    if (_trackingStates[postId]?.isRecorded == false) {
      await recordView(postId: postId, source: source);
    }
  }

  /// Cancel pending view recording (user scrolled away)
  void cancelPendingView(String postId) {
    final state = _trackingStates[postId];
    if (state != null && !state.isRecorded) {
      _trackingStates.remove(postId);
    }
  }

  // ════════════════════════════════════════════════════════════
  // VIDEO PROGRESS TRACKING
  // ════════════════════════════════════════════════════════════

  /// Update video view progress
  Future<ViewProgressResult> updateViewProgress({
    required String postId,
    required int durationSeconds,
    required int viewPercent,
    bool completed = false,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'update_view_progress',
        params: {
          'p_post_id': postId,
          'p_user_id': userId,
          'p_duration_seconds': durationSeconds,
          'p_view_percent': viewPercent,
          'p_completed': completed,
        },
      );

      final result = ViewProgressResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      // Update local tracking state
      final existingState = _trackingStates[postId];
      _trackingStates[postId] =
          (existingState ?? ViewTrackingState(postId: postId)).updateProgress(
            durationSeconds,
            viewPercent,
          );

      logD('Updated view progress: $postId - ${viewPercent}%');

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(
        e,
        stack,
        'updateViewProgress (falling back to offline loop)',
      );

      try {
        final userId = _currentUserId;
        if (userId != null) {
          final today = DateTime.now();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          await _powerSync.execute(
            'UPDATE post_views SET view_duration_seconds = MAX(view_duration_seconds, ?), view_percent = MAX(view_percent, ?), completed = ? WHERE post_id = ? AND user_id = ? AND view_date = ?',
            [
              durationSeconds,
              viewPercent,
              completed ? 1 : 0,
              postId,
              userId,
              dateStr,
            ],
          );
          logI(
            '✓ Updated VIEW PROGRESS offline in local PowerSync database for post: $postId',
          );
        }
      } catch (localE) {
        logE('Failed to update offline progress locally', error: localE);
      }

      return ViewProgressResult(success: false, postId: postId);
    }
  }

  /// Mark video as completed
  Future<void> markVideoCompleted(String postId, int totalDuration) async {
    await updateViewProgress(
      postId: postId,
      durationSeconds: totalDuration,
      viewPercent: 100,
      completed: true,
    );
  }

  // ════════════════════════════════════════════════════════════
  // AD CLICK TRACKING
  // ════════════════════════════════════════════════════════════

  /// Record ad CTA click
  Future<RecordAdClickResult> recordAdClick(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'record_ad_click',
        params: {'p_post_id': postId, 'p_user_id': userId},
      );

      final result = RecordAdClickResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Recorded ad click for post: $postId');

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(
        e,
        stack,
        'recordAdClick (falling back to offline loop)',
      );

      try {
        final userId = _currentUserId;
        if (userId != null) {
          final today = DateTime.now();
          final dateStr =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          await _powerSync.execute(
            'UPDATE post_views SET clicked_cta = 1 WHERE post_id = ? AND user_id = ? AND view_date = ?',
            [postId, userId, dateStr],
          );
          logI(
            '✓ Recorded AD CLICK offline in local PowerSync database for post: $postId',
          );

          return RecordAdClickResult(success: true, postId: postId);
        }
      } catch (localE) {
        logE('Failed to record ad click locally', error: localE);
      }

      return RecordAdClickResult(success: false, postId: postId);
    }
  }

  // ════════════════════════════════════════════════════════════
  // POST ANALYTICS
  // ════════════════════════════════════════════════════════════

  /// Get detailed analytics for a post (post owner only)
  Future<PostAnalytics> getPostAnalytics({
    required String postId,
    int days = 30,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'get_post_analytics',
        params: {'p_post_id': postId, 'p_user_id': userId, 'p_days': days},
      );

      return PostAnalytics.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getPostAnalytics');
      return PostAnalytics.empty(postId);
    }
  }

  /// Get basic view count (from local cache first)
  Future<int> getViewCount(String postId) async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT views_count FROM posts WHERE id = ?',
        parameters: [postId],
      );

      return (result?['views_count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Stream view count with real-time updates
  Stream<int> watchViewCount(String postId) {
    return _powerSync
        .watchQuery(
          'SELECT views_count FROM posts WHERE id = ?',
          parameters: [postId],
        )
        .map((results) {
          if (results.isEmpty) return 0;
          return (results.first['views_count'] as int?) ?? 0;
        });
  }

  // ════════════════════════════════════════════════════════════
  // STORY VIEWERS
  // ════════════════════════════════════════════════════════════

  /// Get story viewers (story owner only)
  Future<StoryViewersListModel> getStoryViewers({
    required String storyId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'get_story_viewers',
        params: {
          'p_post_id': storyId,
          'p_user_id': userId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final list = (response as List<dynamic>?) ?? [];

      return StoryViewersListModel.fromJsonList(
        storyId,
        list,
        offset: offset,
        limit: limit,
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getStoryViewers');
      return StoryViewersListModel(storyId: storyId);
    }
  }

  /// Stream story viewers with real-time updates
  Stream<StoryViewersListModel> watchStoryViewers({
    required String storyId,
    int limit = 50,
  }) async* {
    yield await getStoryViewers(storyId: storyId, limit: limit);

    // Listen for new views
    yield* _supabase
        .from('post_views')
        .stream(primaryKey: ['id'])
        .eq('post_id', storyId)
        .order('created_at', ascending: false)
        .limit(limit)
        .asyncMap((_) => getStoryViewers(storyId: storyId, limit: limit));
  }

  // ════════════════════════════════════════════════════════════
  // VIEW HISTORY
  // ════════════════════════════════════════════════════════════

  /// Get user's view history
  Future<List<PostViewModel>> getViewHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final results = await _powerSync.executeQuery(
        '''
        SELECT pv.* 
        FROM post_views pv
        WHERE pv.user_id = ?
        ORDER BY pv.created_at DESC
        LIMIT ? OFFSET ?
        ''',
        parameters: [userId, limit, offset],
      );

      return results.map((r) => PostViewModel.fromJson(r)).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getViewHistory');
      return [];
    }
  }

  /// Check if user has viewed a post today
  Future<bool> hasViewedToday(String postId) async {
    // Check local state first
    final state = _trackingStates[postId];
    if (state != null) {
      return !state.shouldRecord;
    }

    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final result = await _powerSync.querySingle(
        '''
        SELECT 1 FROM post_views 
        WHERE post_id = ? AND user_id = ? AND view_date = ?
        ''',
        parameters: [postId, userId, dateStr],
      );

      return result != null;
    } catch (e) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // AGGREGATE STATISTICS
  // ════════════════════════════════════════════════════════════

  /// Get total views for all user's posts
  Future<int> getTotalViewsForUser(String userId) async {
    try {
      final result = await _powerSync.querySingle(
        '''
        SELECT SUM(views_count) as total 
        FROM posts 
        WHERE user_id = ? AND is_deleted = 0
        ''',
        parameters: [userId],
      );

      return (result?['total'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get views breakdown by source for user's posts
  Future<Map<ViewSource, int>> getViewsBySource({
    required String userId,
    int days = 30,
  }) async {
    try {
      final results = await _powerSync.executeQuery(
        '''
        SELECT pv.view_source, COUNT(*) as count
        FROM post_views pv
        JOIN posts p ON p.id = pv.post_id
        WHERE p.user_id = ?
        AND pv.view_date >= date('now', '-$days days')
        GROUP BY pv.view_source
        ''',
        parameters: [userId],
      );

      final breakdown = <ViewSource, int>{};
      for (final row in results) {
        final source = ViewSource.tryFromString(row['view_source'] as String?);
        if (source != null) {
          breakdown[source] = (row['count'] as int?) ?? 0;
        }
      }

      return breakdown;
    } catch (e) {
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════

  DeviceType? _getDeviceType() {
    // Simple detection based on screen size would be done in UI
    // Here we just detect platform
    if (Platform.isIOS || Platform.isAndroid) {
      return DeviceType.mobile;
    }
    return DeviceType.desktop;
  }

  ViewPlatform? _getPlatform() {
    if (Platform.isIOS) return ViewPlatform.ios;
    if (Platform.isAndroid) return ViewPlatform.android;
    return ViewPlatform.web;
  }

  /// Clear local tracking state (e.g., on logout)
  void clearTrackingState() {
    _trackingStates.clear();
  }

  /// Get current tracking state for a post
  ViewTrackingState? getTrackingState(String postId) {
    return _trackingStates[postId];
  }
}

// lib/features/bucket/providers/bucket_provider.dart

import 'package:flutter/foundation.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/features/personal/bucket_model/repositories/bucket_repository.dart';
import 'package:the_time_chart/features/personal/bucket_model/services/bucket_ai_service.dart';

import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';

class BucketProvider extends ChangeNotifier {
  final BucketRepository _repository = BucketRepository();
  final BucketAiService _aiService = BucketAiService();


  List<BucketModel> _buckets = [];
  BucketModel? _currentBucket;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // ================================================================
  // GETTERS
  // ================================================================

  List<BucketModel> get buckets => _buckets;
  BucketModel? get currentBucket => _currentBucket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ================================================================
  // STATISTICS
  // ================================================================

  int get totalBuckets => _buckets.length;
  int get completedBucketsCount => _buckets.where((b) => b.isCompleted).length;
  int get activeBucketsCount => _buckets.where((b) => !b.isCompleted).length;

  List<BucketModel> get activeBuckets =>
      _buckets.where((b) => !b.isCompleted).toList();
  List<BucketModel> get completedBuckets =>
      _buckets.where((b) => b.isCompleted).toList();

  double get averageProgress {
    if (_buckets.isEmpty) return 0.0;
    final total = _buckets.fold<double>(
      0.0,
      (sum, b) => sum + b.metadata.averageProgress,
    );
    return total / _buckets.length;
  }

  // ================================================================
  // GET BUCKET BY ID
  // ================================================================

  Future<BucketModel?> getBucket(String bucketId) async {
    // Check local cache first
    try {
      return _buckets.firstWhere((b) => b.bucketId == bucketId);
    } catch (_) {
      // Fetch from repository
      try {
        final bucket = await _repository.getBucket(bucketId);
        if (bucket != null) {
          final index = _buckets.indexWhere(
            (b) => b.bucketId == bucket.bucketId,
          );
          if (index != -1) {
            _buckets[index] = bucket;
          } else {
            _buckets.add(bucket);
          }
          notifyListeners();
        }
        return bucket;
      } catch (e, s) {
        logE('Error fetching bucket by ID', error: e, stackTrace: s);
        return null;
      }
    }
  }

  // ================================================================
  // LOAD BUCKETS
  // ================================================================

  int _offset = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  // ================================================================
  // LOAD BUCKETS
  // ================================================================

  Future<void> loadBuckets(String userId, {bool refresh = true}) async {
    try {
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _setLoading(true);
      } else {
        if (!_hasMore || _isLoading) return;
        _isLoading = true; // Manual flag to prevent concurrent loads
      }

      logI('Loading buckets for user: $userId (offset: $_offset)');

      _userId = userId;
      final fetched = await _repository.getUserBuckets(
        userId,
        limit: _pageSize,
        offset: _offset,
      );

      if (refresh) {
        _buckets = fetched;
      } else {
        _buckets.addAll(fetched);
      }

      _hasMore = fetched.length >= _pageSize;
      _offset += fetched.length;
      _error = null;

      logI('Loaded ${fetched.length} buckets. Total: ${_buckets.length}');

      // Schedule reminders for active buckets (only for first page to avoid OS limits)
      if (refresh) {
        // Notifications are now handled by the backend/modular architecture
      }
    } catch (e, stackTrace) {
      logE('Error loading buckets: $e', error: e, stackTrace: stackTrace);
      _error = e.toString();
      AppSnackbar.error('Failed to load buckets');
    } finally {
      if (refresh) {
        _setLoading(false);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreBuckets() async {
    if (_userId != null) {
      await loadBuckets(_userId!, refresh: false);
    }
  }

  // ================================================================
  // CREATE BUCKET
  // ================================================================

  Future<BucketModel?> createBucket(BucketModel bucket) async {
    try {
      _setLoading(true);
      logI('Creating new bucket');

      final created = await _repository.createBucket(bucket);
      if (created != null) {
        _buckets.insert(0, created);
        AppSnackbar.success('Bucket created successfully!');

        // Generate initial AI summary
        final summary = await _aiService.generateBucketSummary(
          bucket: created,
          userId: _userId ?? created.userId,
        );

        if (summary != null) {
          final perfSummary = PerformanceSummary(
            summary: summary.summary,
            suggestion: summary.suggestion,
            plan: summary.aiPlan,
          );
          final updated = created.copyWith(
            metadata: created.metadata.copyWith(summary: perfSummary),
          );
          await _repository.updateBucket(updated);
          final idx = _buckets.indexWhere(
            (b) => b.bucketId == created.bucketId,
          );
          if (idx != -1) _buckets[idx] = updated;
        }

        // Schedule reminders
        // Notifications are now handled by the backend/modular architecture

        notifyListeners();
        return created;
      }
      return null;
    } catch (e, stackTrace) {
      logE('Error creating bucket: $e', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to create bucket');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // UPDATE BUCKET
  // ================================================================

  Future<bool> updateBucket(
    BucketModel bucket, {
    bool isSocialAction = false,
  }) async {
    try {
      _setLoading(true);
      logI('Updating bucket: ${bucket.bucketId}');

      // 1. Completion Lock Check
      final existing = _buckets.firstWhere(
        (b) => b.bucketId == bucket.bucketId,
        orElse: () => bucket,
      );
      if (existing.isCompleted && !isSocialAction) {
        AppSnackbar.warning(
          'Bucket is completed and locked from further updates.',
        );
        return false;
      }

      // Get previous state to check if newly completed
      final prevBucket = _buckets.firstWhere(
        (b) => b.bucketId == bucket.bucketId,
        orElse: () => bucket,
      );

      // Use models's recalculateRewards for all performance/reward calculations
      BucketModel updatedBucket;
      try {
        updatedBucket = bucket.recalculateRewards();
      } catch (e, s) {
        logE(
          'Failed to recalculate rewards for bucket',
          error: e,
          stackTrace: s,
        );
        AppSnackbar.error('Internal calculation error. Please try again.');
        return false;
      }

      final newlyCompleted =
          updatedBucket.isCompleted && !prevBucket.isCompleted;

      final success = await _repository.updateBucket(updatedBucket);
      if (success) {
        final index = _buckets.indexWhere((b) => b.bucketId == bucket.bucketId);
        if (index != -1) {
          _buckets[index] = updatedBucket;
        }
        AppSnackbar.success('Bucket updated');

        // Reschedule notifications
        // Notifications are now handled by the backend/modular architecture

        notifyListeners();

        // Run AI enrichment asynchronously if newly completed
        if (newlyCompleted) {
          _enrichWithAIContent(updatedBucket)
              .then((enriched) async {
                if (enriched != updatedBucket) {
                  await _repository.updateBucket(enriched);
                  final idx = _buckets.indexWhere(
                    (b) => b.bucketId == bucket.bucketId,
                  );
                  if (idx != -1) {
                    _buckets[idx] = enriched;
                    notifyListeners();
                  }
                }
              })
              .catchError((e) {
                logE('Async AI enrichment failed for bucket', error: e);
              });
        }

        return true;
      }
      return false;
    } catch (e, stackTrace) {
      logE('Error updating bucket: $e', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to update bucket');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // DELETE BUCKET
  // ================================================================

  Future<bool> deleteBucket(String bucketId) async {
    try {
      _setLoading(true);
      logI('Deleting bucket: $bucketId');

      final success = await _repository.deleteBucket(bucketId);
      if (success) {
        _buckets.removeWhere((b) => b.bucketId == bucketId);
        // Notifications are now handled by the backend/modular architecture
        AppSnackbar.success('Bucket deleted');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      logE('Error deleting bucket: $e', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to delete bucket');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // CHECKLIST OPERATIONS
  // ================================================================

  Future<bool> addChecklistItem(String bucketId, ChecklistItem item) async {
    try {
      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final updatedChecklist = [...bucket.checklist, item];
      final updatedBucket = bucket.copyWith(checklist: updatedChecklist);
      return await updateBucket(updatedBucket);
    } catch (e, s) {
      logE('Error adding checklist item: $e', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> updateChecklistItem(
    String bucketId,
    String itemId,
    ChecklistItem updatedItem,
  ) async {
    try {
      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final updatedChecklist = bucket.checklist.map((item) {
        return item.id == itemId ? updatedItem : item;
      }).toList();

      final updatedBucket = bucket.copyWith(checklist: updatedChecklist);
      return await updateBucket(updatedBucket);
    } catch (e, s) {
      logE('Error updating checklist item: $e', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> deleteChecklistItem(String bucketId, String itemId) async {
    try {
      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final updatedChecklist = bucket.checklist
          .where((item) => item.id != itemId)
          .toList();

      final updatedBucket = bucket.copyWith(checklist: updatedChecklist);
      return await updateBucket(updatedBucket);
    } catch (e, s) {
      logE('Error deleting checklist item: $e', error: e, stackTrace: s);
      return false;
    }
  }

  Future<bool> toggleChecklistItem(String bucketId, String itemId) async {
    try {
      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final updatedChecklist = bucket.checklist.map((item) {
        if (item.id == itemId) {
          return item.copyWith(done: !item.done);
        }
        return item;
      }).toList();

      final updatedBucket = bucket.copyWith(checklist: updatedChecklist);
      return await updateBucket(updatedBucket);
    } catch (e, s) {
      logE('Error toggling checklist item: $e', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // POST BUCKET
  // ================================================================

  Future<bool> postBucket({
    required String bucketId,
    required bool isLive,
    String? snapshotUrl,
    String? caption,
  }) async {
    try {
      _setLoading(true);
      logI('Posting bucket: $bucketId');

      final postId = await _repository.postBucket(
        bucketId: bucketId,
        isLive: isLive,
        snapshotUrl: snapshotUrl,
        caption: caption,
      );

      if (postId != null) {
        final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
        final currentSocialInfo =
            bucket.socialInfo ?? SocialInfo(isPosted: false);
        final updatedSocialInfo = currentSocialInfo.copyWith(
          isPosted: true,
          posted:
              currentSocialInfo.posted?.copyWith(
                postId: postId,
                live: isLive,
                time: DateTime.now(),
              ) ??
              PostedInfo(postId: postId, live: isLive, time: DateTime.now()),
        );
        final updatedBucket = bucket.copyWith(socialInfo: updatedSocialInfo);
        await updateBucket(updatedBucket, isSocialAction: true);
        await loadBuckets(bucket.userId);
        AppSnackbar.success('Bucket posted successfully!');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      logE('Error posting bucket: $e', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to post bucket');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // REMOVE POST
  // ================================================================

  Future<bool> removePost(String bucketId) async {
    try {
      _setLoading(true);
      logI('Removing post for bucket: $bucketId');

      final bucketInfo = _buckets.firstWhere(
        (b) => b.bucketId == bucketId,
        orElse: () => throw Exception('Bucket not found'),
      );
      final postId = bucketInfo.socialInfo?.posted?.postId;

      if (postId != null && postId.isNotEmpty) {
        final postRepo = PostRepository();
        final success = await postRepo.deletePost(postId);
        if (!success) {
          logE('Failed to delete post from repository');
          return false;
        }
      }

      final updatedBucket = bucketInfo.copyWith(
        socialInfo: SocialInfo(isPosted: false, posted: null),
      );

      await updateBucket(updatedBucket, isSocialAction: true);
      await loadBuckets(bucketInfo.userId);

      logI('✅ Post removed successfully');
      return true;
    } catch (e, stackTrace) {
      logE('Error removing post: $e', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // SHARE OPERATIONS
  // ================================================================

  Future<bool> shareBucketViaChat({
    required String bucketId,
    required String chatId,
    String? messageText,
    bool isLive = false,
  }) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);

      final chatRepo = ChatRepository();
      await chatRepo.sendSharedContent(
        chatId: chatId,
        contentType: SharedContentType.bucketModel,
        contentId: bucketId,
        caption: messageText,
        mode: isLive ? 'live' : 'snapshot',
      );

      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final currentShareInfo = bucket.shareInfo ?? ShareInfo();
      final updatedShareInfo = currentShareInfo.copyWith(
        isShare: true,
        shareId:
            currentShareInfo.shareId?.copyWith(withId: chatId) ??
            BucketSharedInfo(
              time: DateTime.now(),
              live: isLive,
              withId: chatId,
            ),
      );

      final updatedBucket = bucket.copyWith(shareInfo: updatedShareInfo);
      await updateBucket(updatedBucket, isSocialAction: true);

      logI('✅ Bucket shared via chat: $chatId');
      return true;
    } catch (e, stackTrace) {
      logE(
        'Error sharing bucket via chat: $e',
        error: e,
        stackTrace: stackTrace,
      );
      AppSnackbar.error('Failed to share bucket');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // AI OPERATIONS
  // ================================================================

  Future<bool> generateAISummary(String bucketId) async {
    try {
      AppSnackbar.loading(title: 'Generating AI summary...');

      final bucket = _buckets.firstWhere((b) => b.bucketId == bucketId);
      final summary = await _aiService.generateBucketSummary(
        bucket: bucket,
        userId: _userId ?? bucket.userId,
      );

      AppSnackbar.hideLoading();

      if (summary != null) {
        final perfSummary = PerformanceSummary(
          summary: summary.summary,
          suggestion: summary.suggestion,
          plan: summary.aiPlan,
        );
        final updatedMetadata = bucket.metadata.copyWith(summary: perfSummary);
        final updatedBucket = bucket.copyWith(metadata: updatedMetadata);
        return await updateBucket(updatedBucket, isSocialAction: true);
      }
      return false;
    } catch (e, s) {
      AppSnackbar.hideLoading();
      logE('Error generating AI summary: $e', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  /// Enriches bucket with AI-generated summary and motivation
  Future<BucketModel> _enrichWithAIContent(BucketModel bucket) async {
    var enrichedBucket = bucket;

    // Generate AI summary
    final summary = await _aiService.generateBucketSummary(
      bucket: bucket,
      userId: _userId ?? bucket.userId,
    );

    if (summary != null) {
      enrichedBucket = enrichedBucket.copyWith(
        metadata: enrichedBucket.metadata.copyWith(
          summary: PerformanceSummary(
            summary: summary.summary,
            suggestion: summary.suggestion,
            plan: summary.aiPlan,
          ),
        ),
      );
    }

    return enrichedBucket;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCurrentBucket(BucketModel? bucket) {
    _currentBucket = bucket;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _buckets.clear();
    super.dispose();
  }
}

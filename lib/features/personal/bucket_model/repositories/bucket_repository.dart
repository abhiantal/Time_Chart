// lib/features/personal/bucket_model/repositories/bucket_repository.dart

import 'dart:convert';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/error_handler.dart';

class BucketRepository {
  static final BucketRepository _instance = BucketRepository._internal();
  factory BucketRepository() => _instance;
  BucketRepository._internal();

  final _powerSync = PowerSyncService();
  static const String _tableName = 'bucket_models';

  final _jsonbColumns = [
    'details',
    'checklist',
    'timeline',
    'metadata',
    'social_info',
    'share_info',
  ];

  // ================================================================
  // CREATE BUCKET
  // ================================================================
  Future<BucketModel?> createBucket(BucketModel bucket) async {
    try {
      logI('Creating bucket in local database');

      final data = bucket.toJson();

      final currentId = _powerSync.currentUserId ?? '';

      // Ensure user_id exists FIRST to satisfy Supabase RLS policies
      if (data['user_id'] == null ||
          data['user_id'].toString().trim().isEmpty) {
        if (currentId.isNotEmpty) {
          data['user_id'] = currentId;
        } else {
          logE(
            '❌ Action denied: Cannot create bucket without active user session (RLS violation)',
          );
          ErrorHandler.showErrorSnackbar(
            'You must be logged in to create a bucket',
            title: 'Session Error',
          );
          return null;
        }
      }

      // PowerSyncService.insert handles ID generation if missing, but BucketModel might have empty ID
      if (bucket.id.isEmpty) {
        data.remove('id'); // Let PowerSync generate it
      }

      final id = await _powerSync.insert(_tableName, data);

      logI('✅ Bucket created locally: $id');
      return bucket.copyWith(id: id);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Create bucket');
      return null;
    }
  }

  // ================================================================
  // GET USER BUCKETS
  // ================================================================
  Future<List<BucketModel>> getUserBuckets(
    String userId, {
    int? limit,
    int? offset,
    String? categoryType,
    bool? isCompleted,
  }) async {
    try {
      logI('Fetching buckets for user: $userId (limit: $limit, offset: $offset)');

      var sql =
          '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
      ''';
      final List<dynamic> args = [userId, _tableName];

      // Apply filters
      if (categoryType != null) {
        sql += ' AND category_type = ?';
        args.add(categoryType);
      }

      if (isCompleted != null) {
        if (isCompleted) {
          sql += " AND json_extract(timeline, '\$.complete_date') IS NOT NULL";
        } else {
          sql += " AND json_extract(timeline, '\$.complete_date') IS NULL";
        }
      }

      // Apply ordering and pagination
      sql += ' ORDER BY created_at DESC';

      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);

        if (offset != null) {
          sql += ' OFFSET ?';
          args.add(offset);
        }
      }

      final results = await _powerSync.executeQuery(sql, parameters: args);

      return results
          .map(
            (row) => BucketModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch user buckets');
      return [];
    }
  }

  // ================================================================
  // GET SINGLE BUCKET
  // ================================================================
  Future<BucketModel?> getBucket(String bucketId) async {
    try {
      // Check if excluded locally
      final excluded = await _powerSync.executeQuery(
        'SELECT 1 FROM local_sync_exclusions WHERE excluded_id = ? AND table_name = ?',
        parameters: [bucketId, _tableName],
      );
      if (excluded.isNotEmpty) {
        logI('🚫 Bucket $bucketId is excluded locally');
        return null;
      }

      final result = await _powerSync.getById(_tableName, bucketId);

      if (result == null) {
        logI('⚠️ Bucket not found locally');
        return null;
      }

      return BucketModel.fromJson(
        _powerSync.parseJsonbFields(result, _jsonbColumns),
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch bucket');
      return null;
    }
  }

  // ================================================================
  // UPDATE BUCKET
  // ================================================================
  Future<bool> updateBucket(BucketModel bucket) async {
    try {
      logI('Updating bucket locally: ${bucket.id}');

      final data = bucket.toJson();
      await _powerSync.update(_tableName, data, bucket.id);

      logI('✅ Bucket updated locally');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Update bucket');
      return false;
    }
  }

  // ================================================================
  // DELETE BUCKET
  // ================================================================
  Future<bool> deleteBucket(String bucketId) async {
    try {
      logI('Deleting bucket locally: $bucketId');

      // Record exclusion before actual delete from local store
      await _recordExclusion(bucketId);

      await _powerSync.delete(_tableName, bucketId);

      logI('✅ Bucket deleted locally');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Delete bucket');
      return false;
    }
  }

  // ================================================================
  // RECORD EXCLUSION
  // ================================================================
  Future<void> _recordExclusion(String id) async {
    try {
      await _powerSync.insert('local_sync_exclusions', {
        'excluded_id': id,
        'table_name': _tableName,
        'created_at': DateTime.now().toIso8601String(),
      });
      logI('📍 Recorded local exclusion for $id');
    } catch (e) {
      logE('❌ Error recording exclusion', error: e);
    }
  }

  // ================================================================
  // SEARCH BUCKETS
  // ================================================================
  Future<List<BucketModel>> searchBuckets(
    String userId,
    String searchQuery,
  ) async {
    try {
      logI('Searching buckets locally: $searchQuery');

      final query = '%$searchQuery%';

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? '
        'AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?) '
        'AND ('
        'json_extract(details, "\$.description") LIKE ? OR '
        'json_extract(details, "\$.motivation") LIKE ? OR '
        'category_type LIKE ?'
        ') ORDER BY created_at DESC',
        parameters: [userId, _tableName, query, query, query],
      );

      return results
          .map(
            (row) => BucketModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Search buckets');
      return [];
    }
  }

  // ================================================================
  // GET BUCKETS BY CATEGORY
  // ================================================================
  Future<List<BucketModel>> getBucketsByCategory(
    String userId,
    String categoryType,
  ) async {
    try {
      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? '
        'AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?) '
        'AND category_type = ? ORDER BY created_at DESC',
        parameters: [userId, _tableName, categoryType],
      );

      return results
          .map(
            (row) => BucketModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'Fetch buckets by category_model',
      );
      return [];
    }
  }

  // ================================================================
  // GET OVERDUE BUCKETS
  // ================================================================
  Future<List<BucketModel>> getOverdueBuckets(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? '
        'AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?) '
        'AND json_extract(timeline, "\$.complete_date") IS NULL '
        'AND json_extract(timeline, "\$.due_date") < ? '
        'ORDER BY json_extract(timeline, "\$.due_date") ASC',
        parameters: [userId, _tableName, now],
      );

      return results
          .map(
            (row) => BucketModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch overdue buckets');
      return [];
    }
  }

  // ================================================================
  // GET UPCOMING BUCKETS
  // ================================================================
  Future<List<BucketModel>> getUpcomingBuckets(
    String userId, {
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final future = now.add(Duration(days: days));
      final nowStr = now.toIso8601String();
      final futureStr = future.toIso8601String();

      final results = await _powerSync.executeQuery(
        'SELECT * FROM $_tableName WHERE user_id = ? '
        'AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?) '
        'AND json_extract(timeline, "\$.complete_date") IS NULL '
        'AND json_extract(timeline, "\$.due_date") >= ? '
        'AND json_extract(timeline, "\$.due_date") <= ? '
        'ORDER BY json_extract(timeline, "\$.due_date") ASC',
        parameters: [userId, _tableName, nowStr, futureStr],
      );

      return results
          .map(
            (row) => BucketModel.fromJson(
              _powerSync.parseJsonbFields(row, _jsonbColumns),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch upcoming buckets');
      return [];
    }
  }

  // ================================================================
  // GET USER STATISTICS
  // ================================================================
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final results = await _powerSync.executeQuery(
        '''
        SELECT 
          COUNT(*) as totalBuckets,
          SUM(CASE WHEN json_extract(timeline, '\$.complete_date') IS NOT NULL THEN 1 ELSE 0 END) as completedBuckets,
          SUM(json_extract(metadata, '\$.total_points_earned')) as totalPoints,
          AVG(json_extract(metadata, '\$.average_rating')) as averageRating,
          AVG(json_extract(metadata, '\$.average_progress')) as averageProgress
        FROM $_tableName 
        WHERE user_id = ?
        ''',
        parameters: [userId],
      );

      if (results.isEmpty) {
        return {
          'totalBuckets': 0,
          'completedBuckets': 0,
          'activeBuckets': 0,
          'totalPoints': 0,
          'averageRating': 0.0,
          'averageProgress': 0.0,
          'completionRate': 0.0,
        };
      }

      final row = results.first;
      final totalBuckets = (row['totalBuckets'] as num?)?.toInt() ?? 0;
      final completedBuckets = (row['completedBuckets'] as num?)?.toInt() ?? 0;

      return {
        'totalBuckets': totalBuckets,
        'completedBuckets': completedBuckets,
        'activeBuckets': totalBuckets - completedBuckets,
        'totalPoints': (row['totalPoints'] as num?)?.toInt() ?? 0,
        'averageRating': (row['averageRating'] as num?)?.toDouble() ?? 0.0,
        'averageProgress': (row['averageProgress'] as num?)?.toDouble() ?? 0.0,
        'completionRate': totalBuckets > 0
            ? (completedBuckets / totalBuckets * 100)
            : 0.0,
      };
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Fetch statistics');
      return {};
    }
  }

  // ================================================================
  // BATCH OPERATIONS
  // ================================================================
  Future<bool> batchUpdateBuckets(List<BucketModel> buckets) async {
    try {
      logI('Batch updating ${buckets.length} buckets locally');

      await _powerSync.transaction((db) async {
        for (var bucket in buckets) {
          final data = bucket.toJson();

          _powerSync.parseJsonbFields(data, []);

          final keys = data.keys.where((k) => k != 'id').toList();
          final values = keys.map((k) {
            final v = data[k];
            if (v is Map || v is List) return jsonEncode(v);
            if (v is DateTime) return v.toIso8601String();
            return v;
          }).toList();
          values.add(bucket.id);

          final setClause = keys.map((k) => '$k = ?').join(', ');

          await db.execute(
            'UPDATE $_tableName SET $setClause WHERE id = ?',
            values,
          );
        }
        return true;
      });

      logI('✅ Batch update successful locally');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Batch update buckets');
      return false;
    }
  }

  // ================================================================
  // POST BUCKET
  // ================================================================
  Future<String?> postBucket({
    required String bucketId,
    required bool isLive,
    String? snapshotUrl,
    String? caption,
  }) async {
    try {
      if (bucketId.isEmpty) {
        logE('❌ Cannot post bucket: bucket_id is empty');
        return null;
      }

      final postRepository = PostRepository();
      final post = await postRepository.createPostFromSource(
        sourceType: 'bucket_model',
        sourceId: bucketId,
        isLive: isLive,
        caption: caption,
        visibility: 'public',
      );

      if (post != null) {
        logI('✅ Bucket posted successfully: $bucketId');
        return post.id;
      } else {
        logE('❌ Failed to create post');
        return null;
      }
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Post bucket');
      return null;
    }
  }

  // ================================================================
  // CLEANUP
  // ================================================================
  Future<bool> deleteOldCompletedBuckets({
    required String userId,
    int daysOld = 180,
  }) async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: daysOld))
          .toIso8601String();

      await _powerSync.deleteWhere(
        _tableName,
        'user_id = ? AND json_extract(timeline, "\$.complete_date") IS NOT NULL AND json_extract(timeline, "\$.complete_date") < ?',
        [userId, cutoffDate],
      );

      logI('✅ Cleanup successful locally');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Cleanup old buckets');
      return false;
    }
  }
}

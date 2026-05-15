// ============================================================
// 📁 repositories/save_repository.dart
// Save Repository - All bookmark/save-related database operations
// Uses PowerSync for offline-first + Supabase RPC for complex ops
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import '../models/saves_model.dart';
import 'package:the_time_chart/widgets/logger.dart';

class SaveRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  // Local cache for quick lookup
  final Set<String> _savedPostIds = {};
  bool _cacheInitialized = false;

  SaveRepository({PowerSyncService? powerSync, SupabaseClient? supabase})
    : _powerSync = powerSync ?? PowerSyncService(),
      _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ════════════════════════════════════════════════════════════
  // CACHE INITIALIZATION
  // ════════════════════════════════════════════════════════════

  /// Initialize local cache of saved post IDs for quick lookup
  Future<void> initializeCache() async {
    if (_cacheInitialized) return;

    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final results = await _powerSync.executeQuery(
        'SELECT post_id FROM saves WHERE user_id = ?',
        parameters: [userId],
      );

      _savedPostIds.clear();
      for (final row in results) {
        final postId = row['post_id'] as String?;
        if (postId != null) {
          _savedPostIds.add(postId);
        }
      }

      _cacheInitialized = true;
      logI('✓ Save cache initialized with ${_savedPostIds.length} posts');
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'initializeSaveCache');
    }
  }

  /// Check if post is saved (from cache - instant)
  bool isPostSavedSync(String postId) {
    return _savedPostIds.contains(postId);
  }

  // ════════════════════════════════════════════════════════════
  // TOGGLE SAVE (Save/Unsave)
  // ════════════════════════════════════════════════════════════

  /// Toggle save status for a post
  Future<ToggleSaveResult> toggleSave({
    required String postId,
    String collectionName = kDefaultCollectionName,
    String? note,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'toggle_save',
        params: {
          'p_user_id': userId,
          'p_post_id': postId,
          'p_collection_name': collectionName,
          'p_note': note,
        },
      );

      final result = ToggleSaveResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      // Update local cache
      if (result.isSaved) {
        _savedPostIds.add(postId);
      } else {
        _savedPostIds.remove(postId);
      }

      logI('✓ Toggle save: ${result.action.name} -> $postId');

      // Invalidate PowerSync cache for saves
      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'toggleSave');
      rethrow;
    }
  }

  /// Save a post to a specific collection
  Future<ToggleSaveResult> saveToCollection({
    required String postId,
    required String collectionName,
    String? note,
  }) async {
    // If already saved, first unsave then resave to new collection
    if (_savedPostIds.contains(postId)) {
      await toggleSave(postId: postId); // Unsave
    }
    return toggleSave(
      postId: postId,
      collectionName: collectionName,
      note: note,
    );
  }

  /// Unsave a post
  Future<ToggleSaveResult> unsavePost(String postId) async {
    if (!_savedPostIds.contains(postId)) {
      return ToggleSaveResult(
        success: true,
        action: SaveAction.unsaved,
        postId: postId,
      );
    }
    return toggleSave(postId: postId);
  }

  // ════════════════════════════════════════════════════════════
  // CHECK SAVE STATUS
  // ════════════════════════════════════════════════════════════

  /// Check if a post is saved (async, from database)
  Future<bool> isPostSaved(String postId) async {
    // Check cache first
    if (_cacheInitialized) {
      return _savedPostIds.contains(postId);
    }

    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final result = await _powerSync.querySingle(
        'SELECT 1 FROM saves WHERE user_id = ? AND post_id = ?',
        parameters: [userId, postId],
      );

      final isSaved = result != null;

      // Update cache
      if (isSaved) {
        _savedPostIds.add(postId);
      }

      return isSaved;
    } catch (e) {
      return false;
    }
  }

  /// Check save status for multiple posts (batch)
  Future<Map<String, bool>> checkSaveStatusBatch(List<String> postIds) async {
    final results = <String, bool>{};

    // Check cache first
    if (_cacheInitialized) {
      for (final postId in postIds) {
        results[postId] = _savedPostIds.contains(postId);
      }
      return results;
    }

    try {
      final userId = _currentUserId;
      if (userId == null) {
        for (final postId in postIds) {
          results[postId] = false;
        }
        return results;
      }

      // Query all at once
      final placeholders = List.generate(postIds.length, (_) => '?').join(',');
      final queryResults = await _powerSync.executeQuery(
        'SELECT post_id FROM saves WHERE user_id = ? AND post_id IN ($placeholders)',
        parameters: [userId, ...postIds],
      );

      final savedIds = queryResults
          .map((r) => r['post_id'] as String?)
          .whereType<String>()
          .toSet();

      for (final postId in postIds) {
        results[postId] = savedIds.contains(postId);
      }

      return results;
    } catch (e) {
      for (final postId in postIds) {
        results[postId] = false;
      }
      return results;
    }
  }

  /// Get save info for a post (collection, note, etc.)
  Future<SaveModel?> getSaveInfo(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;

      final result = await _powerSync.querySingle(
        'SELECT * FROM saves WHERE user_id = ? AND post_id = ?',
        parameters: [userId, postId],
      );

      if (result == null) return null;
      return SaveModel.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // GET SAVED POSTS
  // ════════════════════════════════════════════════════════════

  /// Get saved posts with optional collection filter
  Future<SavedPostsList> getSavedPosts({
    String? collectionName,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const SavedPostsList();
      }

      final response = await _supabase.rpc(
        'get_saved_posts',
        params: {
          'p_user_id': userId,
          'p_collection_name': collectionName,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final list = (response as List<dynamic>?) ?? [];

      return SavedPostsList.fromJsonList(
        list,
        collectionFilter: collectionName,
        offset: offset,
        limit: limit,
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getSavedPosts');
      return const SavedPostsList();
    }
  }

  /// Stream saved posts with real-time updates
  Stream<SavedPostsList> watchSavedPosts({
    String? collectionName,
    int limit = 20,
  }) async* {
    // Initial fetch
    yield await getSavedPosts(collectionName: collectionName, limit: limit);

    // Watch for changes
    yield* _powerSync
        .watchQuery(
          '''
          SELECT s.*, p.caption, p.media, p.post_type
          FROM saves s
          LEFT JOIN posts p ON p.id = s.post_id
          WHERE s.user_id = ?
          ${collectionName != null ? "AND s.collection_name = ?" : ""}
          ORDER BY s.created_at DESC
          LIMIT ?
          ''',
          parameters: collectionName != null
              ? [_currentUserId, collectionName, limit]
              : [_currentUserId, limit],
        )
        .asyncMap(
          (_) => getSavedPosts(collectionName: collectionName, limit: limit),
        );
  }

  // ════════════════════════════════════════════════════════════
  // COLLECTIONS
  // ════════════════════════════════════════════════════════════

  /// Get all user collections
  Future<CollectionsList> getCollections() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const CollectionsList();
      }

      final response = await _supabase.rpc(
        'get_user_collections',
        params: {'p_user_id': userId},
      );

      final list = (response as List<dynamic>?) ?? [];

      return CollectionsList.fromJsonList(list);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getCollections');
      return const CollectionsList();
    }
  }

  /// Stream collections with real-time updates
  Stream<CollectionsList> watchCollections() async* {
    yield await getCollections();

    yield* _powerSync
        .watchQuery(
          '''
          SELECT collection_name, COUNT(*) as post_count, MAX(created_at) as latest_saved_at
          FROM saves
          WHERE user_id = ?
          GROUP BY collection_name
          ORDER BY latest_saved_at DESC
          ''',
          parameters: [_currentUserId],
        )
        .asyncMap((_) => getCollections());
  }

  /// Create a new collection by saving a post to it
  Future<ToggleSaveResult> createCollection({
    required String collectionName,
    required String firstPostId,
    String? note,
  }) async {
    return saveToCollection(
      postId: firstPostId,
      collectionName: collectionName,
      note: note,
    );
  }

  /// Rename a collection
  Future<RenameCollectionResult> renameCollection({
    required String oldName,
    required String newName,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (oldName == kDefaultCollectionName) {
        throw Exception('Cannot rename the default collection');
      }

      final response = await _supabase.rpc(
        'rename_collection',
        params: {
          'p_user_id': userId,
          'p_old_name': oldName,
          'p_new_name': newName,
        },
      );

      final result = RenameCollectionResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Renamed collection: $oldName → $newName');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'renameCollection');
      rethrow;
    }
  }

  /// Delete a collection
  Future<DeleteCollectionResult> deleteCollection({
    required String collectionName,
    bool deleteSaves = false,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (collectionName == kDefaultCollectionName) {
        throw Exception('Cannot delete the default collection');
      }

      final response = await _supabase.rpc(
        'delete_collection',
        params: {
          'p_user_id': userId,
          'p_collection_name': collectionName,
          'p_delete_saves': deleteSaves,
        },
      );

      final result = DeleteCollectionResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Deleted collection: $collectionName (${result.action})');

      // If saves were deleted, update cache
      if (deleteSaves) {
        // We need to refresh the cache
        _cacheInitialized = false;
        await initializeCache();
      }

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'deleteCollection');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // MOVE & UPDATE SAVES
  // ════════════════════════════════════════════════════════════

  /// Move a save to a different collection
  Future<MoveSaveResult> moveToCollection({
    required String saveId,
    required String newCollectionName,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'move_save_to_collection',
        params: {
          'p_user_id': userId,
          'p_save_id': saveId,
          'p_new_collection_name': newCollectionName,
        },
      );

      final result = MoveSaveResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Moved save to: $newCollectionName');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'moveToCollection');
      rethrow;
    }
  }

  /// Update note on a save
  Future<UpdateNoteResult> updateNote({
    required String saveId,
    String? note,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'update_save_note',
        params: {'p_user_id': userId, 'p_save_id': saveId, 'p_note': note},
      );

      final result = UpdateNoteResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Updated note on save: $saveId');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'updateNote');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // STATISTICS
  // ════════════════════════════════════════════════════════════

  /// Get total saved posts count
  Future<int> getTotalSavedCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return 0;

      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM saves WHERE user_id = ?',
        parameters: [userId],
      );

      return (result?['count'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get count by collection
  Future<Map<String, int>> getCountByCollection() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return {};

      final results = await _powerSync.executeQuery(
        '''
        SELECT collection_name, COUNT(*) as count 
        FROM saves 
        WHERE user_id = ? 
        GROUP BY collection_name
        ''',
        parameters: [userId],
      );

      final counts = <String, int>{};
      for (final row in results) {
        final name = row['collection_name'] as String?;
        final count = row['count'] as int?;
        if (name != null && count != null) {
          counts[name] = count;
        }
      }

      return counts;
    } catch (e) {
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  // SEARCH
  // ════════════════════════════════════════════════════════════

  /// Search saved posts by content or note
  Future<List<SavedPost>> searchSavedPosts({
    required String query,
    String? collectionName,
    int limit = 20,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final searchPattern = '%$query%';

      final results = await _powerSync.executeQuery(
        '''
        SELECT s.id as save_id, s.post_id, s.collection_name, s.note, 
               s.created_at as saved_at, p.user_id as post_user_id,
               p.caption, p.media, p.post_type, p.content_type,
               p.reactions_count, p.comments_count, p.published_at,
               up.username as post_username, up.profile_url as post_profile_url
        FROM saves s
        JOIN posts p ON p.id = s.post_id
        JOIN user_profiles up ON up.user_id = p.user_id
        WHERE s.user_id = ?
        AND (
          p.caption LIKE ? 
          OR s.note LIKE ?
          OR up.username LIKE ?
          OR up.display_name LIKE ?
        )
        ${collectionName != null ? "AND s.collection_name = ?" : ""}
        ORDER BY s.created_at DESC
        LIMIT ?
        ''',
        parameters: collectionName != null
            ? [
                userId,
                searchPattern,
                searchPattern,
                searchPattern,
                searchPattern,
                collectionName,
                limit,
              ]
            : [userId, searchPattern, searchPattern, searchPattern, searchPattern, limit],
      );

      return results.map((r) => SavedPost.fromJson(r)).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'searchSavedPosts');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Clear local cache (e.g., on logout)
  void clearCache() {
    _savedPostIds.clear();
    _cacheInitialized = false;
  }

  /// Get collection names for picker
  Future<List<String>> getCollectionNames() async {
    final collections = await getCollections();
    return collections.collectionNames;
  }
}

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../../../../widgets/logger.dart';
import '../../../../services/powersync_service.dart';

class PostRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  PostRepository({
    PowerSyncService? powerSync,
    SupabaseClient? supabase,
  })  : _powerSync = powerSync ?? PowerSyncService(),
        _supabase = supabase ?? Supabase.instance.client;

  // =================================================================
  // CREATE POST
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
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final typeResolved = _resolvePostType(postType, media, pollData != null);
      final insertData = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'post_type': typeResolved,
        'caption': caption,
        'media': media.map((m) => m.toJson()).toList(),
        'media_count': media.length,
        'visibility': visibility.name,
        'article_data': articleData?.toJson(),
        'poll_data': pollData?.toJson(),
        'published_at': now,
        'comments_count': 0,
        'reposts_count': 0,
        'views_count': 0,
        'ad_data': adData?.toJson(),
        'is_sponsored': adData != null,
      };

      await _powerSync.insert('posts', insertData);
      
      // Fetch the created post back
      return await getPostById(insertData['id'] as String);
    } catch (e) {
      print('Error creating post: $e');
      return null;
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
    final actualSourceMode = sourceMode ?? (isLive ? 'live' : 'snapshot');
    final actualCaption = caption;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final now = DateTime.now().toUtc().toIso8601String();

      final insertData = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'post_type': 'text', // Standard type for shared content
        'caption': actualCaption,
        'source_type': sourceType,
        'source_id': sourceId,
        'source_mode': actualSourceMode,
        'visibility': visibility,
        'published_at': now,
        'comments_count': 0,
        'reposts_count': 0,
        'views_count': 0,
      };

      await _powerSync.insert('posts', insertData);
      return await getPostById(insertData['id'] as String);
    } catch (e) {
      print('Error sharing source: $e');
      return null;
    }
  }

  // =================================================================
  // FETCH POSTS
  // =================================================================
  Future<PostModel?> getPostById(String postId) async {
    await _powerSync.waitForReady();
    try {
      final localData = await _powerSync.querySingle(
        'SELECT * FROM posts WHERE id = ?',
        parameters: [postId],
      );

      if (localData != null) {
        final parsed = _powerSync.parseJsonbFields(localData, [
          'media',
          'reactions_count',
          'poll_data',
          'article_data',
        ]);
        return PostModel.fromJson(parsed);
      }
      return null;
    } catch (e) {
      print('Error fetching post by id: $e');
      return null;
    }
  }

  Future<FeedPost?> getFeedPostById(String postId) async {
    await _powerSync.waitForReady();
    try {
      final result = await _powerSync.querySingle(
        '''
        SELECT p.*, ui.username, ui.display_name, ui.profile_url
        FROM posts p
        LEFT JOIN user_profiles ui ON p.user_id = ui.id
        WHERE p.id = ?
        ''',
        parameters: [postId],
      );

      if (result != null) {
        final parsed = _powerSync.parseJsonbFields(result, [
          'media',
          'reactions_count',
          'poll_data',
          'article_data',
        ]);
        final post = PostModel.fromJson(parsed);
        return FeedPost(
          post: post,
          username: result['username'],
          displayName: result['display_name'],
          profileUrl: result['profile_url'],
        );
      }
      return null;
    } catch (e) {
      print('Error fetching feed post by id: $e');
      return null;
    }
  }

  Future<List<FeedPost>> getHomeFeed({int limit = 20, int offset = 0}) async {
    await _powerSync.waitForReady();
    final currentUserId = _supabase.auth.currentUser?.id;

    // 1. If online, fetch LIVE from Supabase
    if (_powerSync.isOnline) {
      try {
        logI('🌐 Fetching home feed live from Supabase...');
        final List<dynamic> response = await _supabase
            .from('posts')
            .select('''
              *,
              user_profiles:user_id (username, display_name, profile_url)
            ''')
            .order('published_at', ascending: false)
            .range(offset, offset + limit - 1);

        return response.map((e) {
          final eMap = e as Map<String, dynamic>;
          final post = PostModel.fromJson(eMap);
          final profile = eMap['user_profiles'] as Map<String, dynamic>? ?? {};
          return FeedPost(
            post: post,
            username: profile['username'] ?? '',
            displayName: profile['display_name'] ?? '',
            profileUrl: profile['profile_url'],
          );
        }).toList();
      } catch (e) {
        logW('⚠️ Supabase home feed query failed, falling back to local SQLite: $e');
      }
    }

    // 2. Offline fallback: Query local SQLite database (only own and saved posts)
    try {
      logI('🔌 Fetching home feed offline from local SQLite...');
      final whereClause = _getVisibilityWhereClause(currentUserId);
      
      final results = await _powerSync.executeQuery(
        '''
        SELECT p.*, ui.username, ui.display_name, ui.profile_url
        FROM posts p
        LEFT JOIN user_profiles ui ON p.user_id = ui.id
        WHERE p.published_at IS NOT NULL AND $whereClause
        ORDER BY p.published_at DESC
        LIMIT ? OFFSET ?
        ''',
        parameters: [limit, offset],
      );

      return results.map((e) {
        final parsed = _powerSync.parseJsonbFields(e, [
          'media',
          'reactions_count',
          'poll_data',
          'article_data',
        ]);
        final post = PostModel.fromJson(parsed);
        return FeedPost(
          post: post,
          username: e['username'],
          displayName: e['display_name'],
          profileUrl: e['profile_url'],
        );
      }).toList();
    } catch (e) {
      logE('❌ Error fetching offline home feed: $e');
      return [];
    }
  }

  Future<List<ExplorePost>> getExploreFeed({int limit = 20, int offset = 0}) async {
    await _powerSync.waitForReady();

    // 1. If online, fetch LIVE from Supabase
    if (_powerSync.isOnline) {
      try {
        logI('🌐 Fetching explore feed live from Supabase...');
        final List<dynamic> response = await _supabase
            .from('posts')
            .select('*')
            .eq('visibility', 'public')
            .order('views_count', ascending: false)
            .order('published_at', ascending: false)
            .range(offset, offset + limit - 1);

        return response.map((e) {
          return ExplorePost(post: PostModel.fromJson(e as Map<String, dynamic>));
        }).toList();
      } catch (e) {
        logW('⚠️ Supabase explore query failed, falling back to local SQLite: $e');
      }
    }

    // 2. Offline fallback: Query local SQLite database
    try {
      logI('🔌 Fetching explore feed offline from local SQLite...');
      final results = await _powerSync.db.getAll(
        '''
        SELECT p.* FROM posts p 
        WHERE p.published_at IS NOT NULL AND p.visibility = 'public'
        ORDER BY p.views_count DESC, p.published_at DESC
        LIMIT ? OFFSET ?
        ''',
        [limit, offset],
      );

      return results.map((e) {
        final parsed = _powerSync.parseJsonbFields(e, [
          'media',
          'reactions_count',
          'poll_data',
          'article_data',
        ]);
        return ExplorePost(post: PostModel.fromJson(parsed));
      }).toList();
    } catch (e) {
      logE('❌ Error fetching offline explore feed: $e');
      return [];
    }
  }

  Future<List<PostModel>> getUserPosts(String profileUserId) async {
    await _powerSync.waitForReady();
    final currentUserId = PowerSyncService().currentUserId;

    // 1. If online, fetch LIVE from Supabase
    if (_powerSync.isOnline) {
      try {
        logI('🌐 Fetching user posts live from Supabase for: $profileUserId...');
        final List<dynamic> response = await _supabase
            .from('posts')
            .select('*')
            .eq('user_id', profileUserId)
            .order('published_at', ascending: false);

        return response.map((e) {
          return PostModel.fromJson(e as Map<String, dynamic>);
        }).toList();
      } catch (e) {
        logW('⚠️ Supabase user posts query failed, falling back to local SQLite: $e');
      }
    }

    // 2. Offline fallback: Query local SQLite database (for own or saved posts of this user)
    try {
      logI('🔌 Fetching user posts offline from local SQLite for: $profileUserId...');
      final whereClause = _getVisibilityWhereClause(currentUserId);

      final results = await _powerSync.db.getAll(
        'SELECT p.* FROM posts p WHERE p.user_id = ? AND p.published_at IS NOT NULL AND $whereClause ORDER BY p.published_at DESC',
        [profileUserId],
      );

      return results.map((e) {
        final parsed = _powerSync.parseJsonbFields(e, [
          'media',
          'reactions_count',
          'poll_data',
          'article_data',
        ]);
        return PostModel.fromJson(parsed);
      }).toList();
    } catch (e) {
      logE('❌ Error fetching offline user posts: $e');
      return [];
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
    await _powerSync.waitForReady();
    try {
      final updates = <String, dynamic>{};
      if (caption != null) updates['caption'] = caption;
      if (visibility != null) updates['visibility'] = visibility.name;

      if (updates.isEmpty) return true;

      await _powerSync.db.execute(
        '''
        UPDATE posts 
        SET caption = COALESCE(?, caption),
            visibility = COALESCE(?, visibility)
        WHERE id = ?
        ''',
        [caption, visibility?.name, postId],
      );
      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    await _powerSync.waitForReady();
    try {
      await _powerSync.db.execute('DELETE FROM posts WHERE id = ?', [postId]);
      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  Future<void> votePoll({required String postId, required String optionId}) async {
    await _powerSync.waitForReady();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final post = await getPostById(postId);
      if (post == null || post.pollData == null) return;

      final poll = post.pollData!;
      if (poll.voters.contains(userId)) return;

      final updatedOptions = poll.options.map((o) {
        if (o.id == optionId) {
          return PollOption(id: o.id, text: o.text, votes: o.votes + 1);
        }
        return o;
      }).toList();

      final updatedVoters = [...poll.voters, userId];
      final updatedPoll = PollData(
        question: poll.question,
        options: updatedOptions,
        voters: updatedVoters,
      );

      await _powerSync.db.execute(
        'UPDATE posts SET poll_data = ? WHERE id = ?',
        [jsonEncode(updatedPoll.toJson()), postId],
      );
    } catch (e) {
      print('Error voting poll: $e');
    }
  }
  
  // =================================================================
  // COMPATIBILITY HELPERS
  // =================================================================
  Future<bool> isSourcePosted({required String sourceType, required String sourceId}) async {
    await _powerSync.waitForReady();
    final result = await _powerSync.db.getOptional(
      'SELECT id FROM posts WHERE source_type = ? AND source_id = ? LIMIT 1',
      [sourceType, sourceId],
    );
    return result != null;
  }

  Future<PostModel?> getPostBySource({required String sourceType, required String sourceId}) async {
    final result = await _powerSync.db.getOptional(
      'SELECT * FROM posts WHERE source_type = ? AND source_id = ? LIMIT 1',
      [sourceType, sourceId],
    );
    if (result == null) return null;
    final parsed = _powerSync.parseJsonbFields(result, ['media', 'reactions_count', 'poll_data', 'article_data']);
    return PostModel.fromJson(parsed);
  }

  Future<int> getPostCount(String userId) async {
    // 0. Wait for PowerSync to be ready
    await _powerSync.waitForReady();

    try {
      // 1. Try to get from cached profile social_stats field first
      final profile = await _powerSync.db.getOptional(
        'SELECT social_stats FROM user_profiles WHERE id = ?',
        [userId],
      );

      int cachedCount = 0;
      if (profile != null && profile['social_stats'] != null) {
        final rawStats = profile['social_stats'];
        try {
          final Map<String, dynamic> stats;
          if (rawStats is String) {
            stats = jsonDecode(rawStats);
          } else {
            stats = Map<String, dynamic>.from(rawStats as Map);
          }
          cachedCount = stats['posts_count'] as int? ?? 0;
        } catch (e) {
          print('Error parsing social_stats for post count: $e');
        }
      }

      // 2. If cached is 0 or missing, OR we want accuracy, count from posts table
      // We always count from posts table for the current user for accuracy
      final currentUserId = PowerSyncService().currentUserId;
      if (cachedCount == 0 || userId == currentUserId) {
        final whereClause = _getVisibilityWhereClause(currentUserId);
        final result = await _powerSync.querySingle(
          'SELECT COUNT(*) as count FROM posts p WHERE p.user_id = ? AND p.published_at IS NOT NULL AND $whereClause',
          parameters: [userId],
        );
        final localCount = result?['count'] as int? ?? 0;
        
        // Return whichever is higher to account for potentially delayed sync or local additions
        return localCount > cachedCount ? localCount : cachedCount;
      }

      return cachedCount;
    } catch (e) {
      print('Error getting post count: $e');
      return 0;
    }
  }

  Stream<int> watchPostCount(String userId) {
    // 0. Wait for PowerSync to be ready
    if (!_powerSync.isReady) {
      logI('watchPostCount: Waiting for PowerSync...');
      return Stream.fromFuture(_powerSync.waitForReady())
          .asyncExpand((_) => watchPostCount(userId));
    }

    // We watch user_profiles for this user since that's where stats are cached
    return _powerSync.watchQuery(
      'SELECT social_stats FROM user_profiles WHERE id = ?',
      parameters: [userId],
    ).asyncMap((results) async {
      int cachedCount = 0;
      if (results.isNotEmpty && results.first['social_stats'] != null) {
        final rawStats = results.first['social_stats'];
        final Map<String, dynamic> stats;
        
        if (rawStats is String) {
          stats = jsonDecode(rawStats);
        } else {
          stats = Map<String, dynamic>.from(rawStats as Map);
        }
        
        cachedCount = stats['posts_count'] as int? ?? 0;
      }

      // Fallback/Verify with local count
      final currentUserId = PowerSyncService().currentUserId;
      if (cachedCount == 0 || userId == currentUserId) {
         final whereClause = _getVisibilityWhereClause(currentUserId);
         final result = await _powerSync.db.getOptional(
           'SELECT COUNT(*) as count FROM posts p WHERE p.user_id = ? AND p.published_at IS NOT NULL AND $whereClause',
           [userId],
         );
         final localCount = result?['count'] as int? ?? 0;
         return localCount > cachedCount ? localCount : cachedCount;
      }
      
      return cachedCount;
    });
  }

  String _resolvePostType(PostType? type, List<PostMedia> media, bool isPoll) {
    if (isPoll) return 'poll';
    
    // Explicitly check for allowed specific types first
    if (type == PostType.day_task) return 'day_task';
    if (type == PostType.long_goal) return 'long_goal';
    if (type == PostType.week_task) return 'week_task';
    if (type == PostType.bucket) return 'bucket';
    if (type == PostType.reel) return 'reel';
    if (type == PostType.story) return 'story';
    if (type == PostType.advertisement) return 'advertisement';
    
    // Map visual/video types to 'video' for DB if not already specific
    if (type == PostType.video) return 'video';
    
    // If it has media and isn't specifically video, it's an image post
    if (media.isNotEmpty) {
      if (media.any((m) => m.isVideo)) return 'video';
      return 'image';
    }

    // Default to 'text' for general posts (including PostType.post, text, shared, etc.)
    return 'text';
  }

  String _getVisibilityWhereClause(String? currentUserId) {
    if (currentUserId == null) {
      return "p.visibility = 'public'";
    }

    // A post is visible if:
    // 1. It's public
    // 2. It's yours
    // 3. It's 'followers' and you follow them
    // 4. It's 'friends' and you are friends (relationship includes 'friend', 'close_friend', 'favorite')
    // 5. It's 'custom' and you are in the visible_to list OR NOT in hide_from list
    return '''
      (
        p.visibility = 'public' OR 
        p.user_id = '$currentUserId' OR
        (p.visibility = 'followers' AND EXISTS (
          SELECT 1 FROM follows f 
          WHERE f.follower_id = '$currentUserId' 
          AND f.following_id = p.user_id 
          AND f.status = 'active'
        )) OR
        (p.visibility = 'friends' AND EXISTS (
          SELECT 1 FROM follows f 
          WHERE f.follower_id = '$currentUserId' 
          AND f.following_id = p.user_id 
          AND f.status = 'active' 
          AND f.relationship IN ('friend', 'close_friend', 'favorite')
        )) OR
        (p.visibility = 'custom' AND (
          (p.visible_to IS NOT NULL AND p.visible_to LIKE '%$currentUserId%') OR
          (p.visible_to IS NULL AND p.hide_from IS NOT NULL AND p.hide_from NOT LIKE '%$currentUserId%')
        ))
      )
    ''';
  }
}

// ============================================================
// 📁 repositories/follow_repository.dart
// Follow Repository - All follow-related database operations
// Uses PowerSync for offline-first + Supabase RPC for complex ops
// ============================================================

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/social/follow/models/follows_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_models.dart';

class FollowRepository {
  final PowerSyncService _powerSync;
  final SupabaseClient _supabase;

  FollowRepository({PowerSyncService? powerSync, SupabaseClient? supabase})
    : _powerSync = powerSync ?? PowerSyncService(),
      _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ════════════════════════════════════════════════════════════
  // TOGGLE FOLLOW (Follow/Unfollow)
  // ════════════════════════════════════════════════════════════

  /// Toggle follow status - returns action taken
  Future<ToggleFollowResult> toggleFollow(String targetUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      // Call Supabase RPC function
      final response = await _supabase.rpc(
        'toggle_follow',
        params: {'p_follower_id': userId, 'p_following_id': targetUserId},
      );

      final result = ToggleFollowResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Toggle follow: ${result.action.name} -> $targetUserId');

      // Invalidate local cache
      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'toggleFollow');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // CHECK FOLLOW STATUS
  // ════════════════════════════════════════════════════════════

  /// Check follow relationship between current user and target
  Future<FollowStatusCheck> checkFollowStatus(String targetUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return FollowStatusCheck.none;
      }

      if (userId == targetUserId) {
        return FollowStatusCheck.none;
      }

      final response = await _supabase.rpc(
        'check_follow_status',
        params: {'p_user_id': userId, 'p_target_user_id': targetUserId},
      );

      return FollowStatusCheck.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'checkFollowStatus');
      return FollowStatusCheck.none;
    }
  }

  /// Check follow status for multiple users (batch)
  Future<Map<String, FollowStatusCheck>> checkFollowStatusBatch(
    List<String> userIds,
  ) async {
    final results = <String, FollowStatusCheck>{};

    // Process in parallel with limit
    final futures = userIds.map((id) async {
      final status = await checkFollowStatus(id);
      return MapEntry(id, status);
    });

    final entries = await Future.wait(futures);
    results.addEntries(entries);

    return results;
  }

  // ════════════════════════════════════════════════════════════
  // GET FOLLOWERS
  // ════════════════════════════════════════════════════════════

  /// Get followers for a user
  Future<FollowersList> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    try {
      final requestingUserId = _currentUserId ?? userId;

      final response = await _supabase.rpc(
        'get_followers',
        params: {
          'p_user_id': userId,
          'p_requesting_user_id': requestingUserId,
          'p_limit': limit,
          'p_offset': offset,
          'p_search': search,
        },
      );

      final list = (response as List<dynamic>?) ?? [];

      return FollowersList.fromJsonList(
        list,
        offset: offset,
        limit: limit,
        searchQuery: search,
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getFollowers');
      return const FollowersList();
    }
  }

  /// Stream followers with real-time updates
  Stream<FollowersList> watchFollowers({
    required String userId,
    int limit = 50,
  }) async* {
    // Initial fetch
    yield await getFollowers(userId: userId, limit: limit);

    // Watch for changes in follows table
    yield* _powerSync
        .watchQuery(
          '''
          SELECT f.*, up.username, up.profile_url, up.user_info
          FROM follows f
          JOIN user_profiles up ON up.user_id = f.follower_id
          WHERE f.following_id = ? AND f.status = 'active'
          ORDER BY f.created_at DESC
          LIMIT ?
          ''',
          parameters: [userId, limit],
        )
        .asyncMap((_) => getFollowers(userId: userId, limit: limit));
  }

  // ════════════════════════════════════════════════════════════
  // GET FOLLOWING
  // ════════════════════════════════════════════════════════════

  /// Get users that a user is following
  Future<FollowingList> getFollowing({
    required String userId,
    FollowRelationship? relationship,
    int limit = 50,
    int offset = 0,
    String? search,
  }) async {
    try {
      final requestingUserId = _currentUserId ?? userId;

      final response = await _supabase.rpc(
        'get_following',
        params: {
          'p_user_id': userId,
          'p_requesting_user_id': requestingUserId,
          'p_relationship': relationship?.value,
          'p_limit': limit,
          'p_offset': offset,
          'p_search': search,
        },
      );

      final list = (response as List<dynamic>?) ?? [];

      return FollowingList.fromJsonList(
        list,
        offset: offset,
        limit: limit,
        filterRelationship: relationship,
        searchQuery: search,
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getFollowing');
      return const FollowingList();
    }
  }

  /// Stream following with real-time updates
  Stream<FollowingList> watchFollowing({
    required String userId,
    FollowRelationship? relationship,
    int limit = 50,
  }) async* {
    yield await getFollowing(
      userId: userId,
      relationship: relationship,
      limit: limit,
    );

    yield* _powerSync
        .watchQuery(
          '''
          SELECT f.*, up.username, up.profile_url, up.user_info
          FROM follows f
          JOIN user_profiles up ON up.user_id = f.following_id
          WHERE f.follower_id = ? AND f.status = 'active'
          ORDER BY f.created_at DESC
          LIMIT ?
          ''',
          parameters: [userId, limit],
        )
        .asyncMap(
          (_) => getFollowing(
            userId: userId,
            relationship: relationship,
            limit: limit,
          ),
        );
  }

  // ════════════════════════════════════════════════════════════
  // FOLLOW REQUESTS
  // ════════════════════════════════════════════════════════════

  /// Get pending follow requests (for private accounts)
  Future<List<FollowRequest>> getPendingRequests({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final results = await _powerSync.executeQuery(
        '''
        SELECT f.id as follow_id, f.follower_id as user_id, 
               up.username, up.profile_url, up.user_info,
               f.created_at
        FROM follows f
        JOIN user_profiles up ON up.user_id = f.follower_id
        WHERE f.following_id = ? AND f.status = 'pending'
        ORDER BY f.created_at DESC
        LIMIT ? OFFSET ?
        ''',
        parameters: [userId, limit, offset],
      );

      return results.map((r) => FollowRequest.fromJson(r)).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getPendingRequests');
      return [];
    }
  }

  /// Stream pending follow requests
  Stream<List<FollowRequest>> watchPendingRequests({int limit = 50}) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _powerSync
        .watchQuery(
          '''
          SELECT f.id as follow_id, f.follower_id as user_id,
                 up.username, up.profile_url, up.user_info,
                 f.created_at
          FROM follows f
          JOIN user_profiles up ON up.user_id = f.follower_id
          WHERE f.following_id = ? AND f.status = 'pending'
          ORDER BY f.created_at DESC
          LIMIT ?
          ''',
          parameters: [userId, limit],
        )
        .map(
          (results) => results.map((r) => FollowRequest.fromJson(r)).toList(),
        );
  }

  /// Respond to follow request (accept/reject)
  Future<FollowRequestResult> respondToFollowRequest({
    required String followerId,
    required bool accept,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'respond_follow_request',
        params: {
          'p_user_id': userId,
          'p_follower_id': followerId,
          'p_accept': accept,
        },
      );

      final result = FollowRequestResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Follow request ${result.action.name}: $followerId');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'respondToFollowRequest');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // UPDATE RELATIONSHIP
  // ════════════════════════════════════════════════════════════

  /// Update relationship type (close friend, favorite, muted, etc.)
  Future<UpdateRelationshipResult> updateRelationship({
    required String targetUserId,
    required FollowRelationship relationship,
    bool? showInFeed,
    FollowNotificationPrefs? notifications,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'update_follow_relationship',
        params: {
          'p_follower_id': userId,
          'p_following_id': targetUserId,
          'p_relationship': relationship.value,
          'p_show_in_feed': showInFeed,
          'p_notifications': notifications?.toJson(),
        },
      );

      final result = UpdateRelationshipResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Updated relationship to ${relationship.value}: $targetUserId');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'updateRelationship');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // BLOCK / UNBLOCK
  // ════════════════════════════════════════════════════════════

  /// Block a user
  Future<BlockUserResult> blockUser(String targetUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'block_user',
        params: {'p_user_id': userId, 'p_block_user_id': targetUserId},
      );

      final result = BlockUserResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Blocked user: $targetUserId');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'blockUser');
      rethrow;
    }
  }

  /// Unblock a user
  Future<BlockUserResult> unblockUser(String targetUserId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.rpc(
        'unblock_user',
        params: {'p_user_id': userId, 'p_blocked_user_id': targetUserId},
      );

      final result = BlockUserResult.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      logI('✓ Unblocked user: $targetUserId');

      _powerSync.clearCache();

      return result;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'unblockUser');
      rethrow;
    }
  }

  /// Get blocked users list
  Future<List<FollowingUser>> getBlockedUsers({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final results = await _powerSync.executeQuery(
        '''
        SELECT f.id as follow_id, f.following_id as user_id,
               up.username, up.profile_url, up.user_info,
               f.created_at as followed_at
        FROM follows f
        JOIN user_profiles up ON up.user_id = f.following_id
        WHERE f.follower_id = ? AND f.status = 'blocked'
        ORDER BY f.updated_at DESC
        LIMIT ? OFFSET ?
        ''',
        parameters: [userId, limit, offset],
      );

      return results.map((r) => FollowingUser.fromJson(r)).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getBlockedUsers');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // FOLLOW SUGGESTIONS
  // ════════════════════════════════════════════════════════════

  /// Get follow suggestions based on mutual connections
  Future<List<FollowSuggestion>> getFollowSuggestions({int limit = 20}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final response = await _supabase.rpc(
        'get_follow_suggestions',
        params: {'p_user_id': userId, 'p_limit': limit},
      );

      final list = (response as List<dynamic>?) ?? [];

      return list
          .map((e) => FollowSuggestion.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getFollowSuggestions');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // SOCIAL COUNTS
  // ════════════════════════════════════════════════════════════

  /// Get follower/following counts for a user
  Future<SocialCounts> getSocialCounts(String userId) async {
    // 0. Wait for PowerSync to be ready
    await _powerSync.waitForReady();

    try {
      // 1. Try to get from user_profiles.social_stats first (cached/synced)
      final profileResult = await _powerSync.querySingle(
        'SELECT social_stats FROM user_profiles WHERE user_id = ? LIMIT 1',
        parameters: [userId],
      );

      if (profileResult != null && profileResult['social_stats'] != null) {
        final rawStats = profileResult['social_stats'];
        final Map<String, dynamic> statsMap;
        
        if (rawStats is String) {
          statsMap = jsonDecode(rawStats);
        } else if (rawStats is Map<String, dynamic>) {
          statsMap = rawStats;
        } else {
          statsMap = {};
        }

        final stats = SocialStats.fromJson(statsMap);
        
        // Use cached stats for other users (since we might not have their posts/follows synced)
        if (userId != _currentUserId) {
          return SocialCounts(
            followersCount: stats.followersCount,
            followingCount: stats.followingCount,
            postsCount: stats.postsCount,
          );
        }
      }

      // 2. Fallback to real-time calculation (accurate for current user or if rows are synced)
      final result = await _powerSync.querySingle(
        '''
        SELECT 
          (SELECT COUNT(*) FROM follows WHERE following_id = ? AND status = 'active') as followers_count,
          (SELECT COUNT(*) FROM follows WHERE follower_id = ? AND status = 'active') as following_count,
          (SELECT COUNT(*) FROM posts WHERE user_id = ?) as posts_count
        ''',
        parameters: [userId, userId, userId],
      );

      return SocialCounts.fromJson(result ?? {});
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'getSocialCounts');
      return const SocialCounts();
    }
  }

  /// Stream social counts with real-time updates
  Stream<SocialCounts> watchSocialCounts(String userId) {
    // 0. Wait for PowerSync to be ready
    if (!_powerSync.isReady) {
      logI('watchSocialCounts: Waiting for PowerSync...');
      return Stream.fromFuture(_powerSync.waitForReady())
          .asyncExpand((_) => watchSocialCounts(userId));
    }

    return _powerSync
        .watchQuery(
          '''
          SELECT 
            (SELECT social_stats FROM user_profiles WHERE user_id = ?) as cached_stats,
            (SELECT COUNT(*) FROM follows WHERE following_id = ? AND status = 'active') as followers_count,
            (SELECT COUNT(*) FROM follows WHERE follower_id = ? AND status = 'active') as following_count,
            (SELECT COUNT(*) FROM posts WHERE user_id = ?) as posts_count
          ''',
          parameters: [userId, userId, userId, userId],
        )
        .map((results) {
          if (results.isEmpty) return const SocialCounts();
          
          final row = results.first;
          if (userId != _currentUserId && row['cached_stats'] != null) {
            final rawStats = row['cached_stats'];
            final Map<String, dynamic> statsMap;
            
            if (rawStats is String) {
              statsMap = jsonDecode(rawStats);
            } else if (rawStats is Map<String, dynamic>) {
              statsMap = rawStats;
            } else {
              statsMap = {};
            }

            final stats = SocialStats.fromJson(statsMap);
            return SocialCounts(
              followersCount: stats.followersCount,
              followingCount: stats.followingCount,
              postsCount: stats.postsCount,
              competitionsCount: stats.competitionsCount,
            );
          }
          
          return SocialCounts.fromJson(row);
        });
  }

  // ════════════════════════════════════════════════════════════
  // CLOSE FRIENDS
  // ════════════════════════════════════════════════════════════

  /// Get close friends list
  Future<List<FollowingUser>> getCloseFriends({int limit = 50}) async {
    final result = await getFollowing(
      userId: _currentUserId ?? '',
      relationship: FollowRelationship.closeFriend,
      limit: limit,
    );
    return result.users;
  }

  /// Add to close friends
  Future<void> addToCloseFriends(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.closeFriend,
    );
  }

  /// Remove from close friends
  Future<void> removeFromCloseFriends(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  // ════════════════════════════════════════════════════════════
  // FAVORITES
  // ════════════════════════════════════════════════════════════

  /// Get favorites list
  Future<List<FollowingUser>> getFavorites({int limit = 50}) async {
    final result = await getFollowing(
      userId: _currentUserId ?? '',
      relationship: FollowRelationship.favorite,
      limit: limit,
    );
    return result.users;
  }

  /// Add to favorites
  Future<void> addToFavorites(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.favorite,
    );
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  // ════════════════════════════════════════════════════════════
  // MUTE / RESTRICT
  // ════════════════════════════════════════════════════════════

  /// Mute a user (still following but hidden from feed)
  Future<void> muteUser(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.muted,
      showInFeed: false,
    );
  }

  /// Unmute a user
  Future<void> unmuteUser(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.follow,
      showInFeed: true,
    );
  }

  /// Restrict a user
  Future<void> restrictUser(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.restricted,
    );
  }

  /// Unrestrict a user
  Future<void> unrestrictUser(String userId) async {
    await updateRelationship(
      targetUserId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  /// Get muted users
  Future<List<FollowingUser>> getMutedUsers({int limit = 50}) async {
    final result = await getFollowing(
      userId: _currentUserId ?? '',
      relationship: FollowRelationship.muted,
      limit: limit,
    );
    return result.users;
  }

  /// Get restricted users
  Future<List<FollowingUser>> getRestrictedUsers({int limit = 50}) async {
    final result = await getFollowing(
      userId: _currentUserId ?? '',
      relationship: FollowRelationship.restricted,
      limit: limit,
    );
    return result.users;
  }
}

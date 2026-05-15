// ================================================================
// FILE: lib/user_profile/profile_repository.dart
// Single responsibility: All profile data operations
// Handles PowerSync (local) + Supabase (remote) + Media uploads
// ================================================================

import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../media_utility/universal_media_service.dart';
import '../../services/powersync_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/logger.dart';
import 'profile_models.dart';

class ProfileRepository {
  // Dependencies
  final PowerSyncService _powerSync;
  final SupabaseService _supabase;
  final UniversalMediaService _mediaService;

  // Table name
  static const String _table = 'user_profiles';

  // Singleton pattern
  static ProfileRepository? _instance;

  factory ProfileRepository() {
    _instance ??= ProfileRepository._(
      PowerSyncService(),
      SupabaseService(),
      UniversalMediaService(),
    );
    return _instance!;
  }

  ProfileRepository._(this._powerSync, this._supabase, this._mediaService);

  // For testing
  ProfileRepository.withDependencies({
    required PowerSyncService powerSync,
    required SupabaseService supabase,
    required UniversalMediaService mediaService,
  }) : _powerSync = powerSync,
       _supabase = supabase,
       _mediaService = mediaService;

  // ================================================================
  // GETTERS
  // ================================================================

  String? get currentUserId => _supabase.currentUserId;
  String? get currentEmail => _supabase.currentUser?.email;
  User? get currentUser => _supabase.currentUser;
  bool get isLoggedIn => currentUserId != null;

  // ================================================================
  // CREATE
  // ================================================================

  /// Create a new user profile
  /// Returns created profile or throws ProfileException
  Future<UserProfile> createProfile(UserProfile profile) async {
    _assertLoggedIn();

    try {
      logI('Creating profile for user: ${profile.userId}');

      // Validate
      if (!profile.isValid) {
        throw ProfileException.invalidData('Profile validation failed');
      }

      // Check if already exists
      final existing = await getMyProfile();
      if (existing != null) {
        logW('Profile already exists, updating with new data');
        final updates = ProfileUpdateDto.fromProfile(profile);
        return await updateMyProfile(updates);
      }

      // Upsert via PowerSync (local-first)
      // put() uses INSERT OR REPLACE which handles existing records gracefully
      final localData = profile.toLocalJson();
      await _powerSync.put(_table, localData);

      logI('Profile created/saved successfully: ${profile.username}');
      return profile;
    } catch (e, s) {
      logE('Failed to create profile', error: e, stackTrace: s);

      if (e is ProfileException) rethrow;

      throw ProfileException(
        'Failed to create profile',
        code: 'CREATE_FAILED',
        originalError: e,
      );
    }
  }

  /// Create profile from raw data (for onboarding)
  Future<UserProfile> createProfileFromData(Map<String, dynamic> data) async {
    _assertLoggedIn();

    final userId = currentUserId!;
    final email = currentEmail ?? '';
    final now = DateTime.now();

    final rawUrl = data['profile_url'] as String?;
    final sanitizedUrl = (rawUrl != null && UserProfile.isLocalPath(rawUrl)) ? null : rawUrl;

    // Robust name parsing
    final rawUsername = data['username'] as String?;
    final rawDisplayName = data['display_name'] as String? ?? data['full_name'] as String?;
    
    final username = rawUsername ?? rawDisplayName ?? email.split('@').first;
    final displayName = rawDisplayName ?? rawUsername ?? email.split('@').first;

    // Build profile object with all possible fields from data
    final profile = UserProfile(
      id: userId,
      userId: userId,
      email: email,
      username: username,
      displayName: displayName,
      profileUrl: sanitizedUrl,
      address: data['address'] as String?,
      organizationName: data['organization_name'] as String?,
      organizationLocation: data['organization_location'] as String?,
      organizationRole: data['organization_role'] as String?,
      isInfluencer: data['is_influencer'] as bool? ?? false,
      influencerCategory: data['influencer_category'] as String?,
      messageForFollower: data['message_for_follower'] as String?,
      primaryGoal: data['primary_goal'] as String?,
      weaknesses: UserProfile.parseStringList(data['weaknesses']),
      strengths: UserProfile.parseStringList(data['strengths']),
      isProfilePublic: data['is_profile_public'] as bool? ?? true,
      openToChat: data['open_to_chat'] as bool? ?? true,
      subscriptionTier: data['subscription_tier'] as String? ?? 'free',
      onboardingCompleted: data['onboarding_completed'] as bool? ?? false,
      promotedCommunityId: data['promoted_community_id'] as String?,
      createdCommunityId: data['created_community_id'] as String?,
      score: data['score'] as int? ?? 0,
      globalRank: data['global_rank'] as int? ?? 0,

      createdAt: now,
      updatedAt: now,
    );

    return createProfile(profile);
  }

  // ================================================================
  // READ - LOCAL FIRST
  // ================================================================

  /// Get current user's profile (local-first)
  Future<UserProfile?> getMyProfile() async {
    if (!isLoggedIn) return null;

    try {
      final result = await _powerSync.getById(_table, currentUserId!);
      if (result == null) return null;

      final profile = UserProfile.fromJson(result);

      // Validate and refresh avatar URL if needed
      final refreshedProfile = await _refreshAvatarUrl(profile);

      return refreshedProfile;
    } catch (e, s) {
      logE('Failed to get my profile', error: e, stackTrace: s);
      return null;
    }
  }

  /// Get current user's profile with a remote check fallback (useful for re-installs)
  Future<UserProfile?> getMyProfileWithRemoteCheck() async {
    if (!isLoggedIn) return null;

    // 1. Try local cache first
    var profile = await getMyProfile();
    if (profile != null) return profile;

    // 2. If local is empty, check Supabase directly
    logI('Profile not found locally, checking remote Supabase...');
    final existsRemotely = await profileExistsRemotely();

    if (existsRemotely) {
      logI('Profile exists remotely. Fetching directly from remote for fast navigation...');
      // 🚀 OPTIMIZATION: Instead of waiting for PowerSync sync (which can take 10+ seconds and block),
      // fetch directly from remote Supabase immediately. This takes ~150-200ms and allows instant navigation.
      // Also write it to the local cache immediately so subsequent reads hit the local cache.
      try {
        final remoteProfile = await _getProfileFromRemote(currentUserId!);
        if (remoteProfile != null) {
          logI('✓ Profile loaded from remote Supabase for fast start');
          
          // Populate local SQLite cache immediately to avoid future cache misses and blocking REST queries
          try {
            await _powerSync.put(_table, remoteProfile.toLocalJson());
            logI('✓ Saved remote profile to local SQLite cache');
          } catch (cacheError) {
            logW('Failed to save fetched remote profile to local cache (non-critical): $cacheError');
          }

          return remoteProfile;
        }
      } catch (e) {
        logW('Failed to fetch remote profile directly: $e. Falling back to wait for sync...');
      }

      logI('Waiting for PowerSync to sync (fallback)...');
      try {
        // Reduced timeout to 1 second to prevent blocking main UI thread and navigation on slow networks
        await _powerSync.waitForSync(timeout: const Duration(seconds: 1));
        profile = await getMyProfile();
        if (profile != null) {
          return profile;
        }
      } catch (e) {
        logW('Wait for sync timed out or failed: $e');
      }
    }

    logI('Profile does not exist locally or remotely');
    return null;
  }

  /// Get profile by ID (local-first, then remote)
  Future<UserProfile?> getProfileById(String userId) async {
    try {
      // Try local first
      final localResult = await _powerSync.getById(_table, userId);
      if (localResult != null) {
        final profile = UserProfile.fromJson(localResult);
        return await _refreshAvatarUrl(profile);
      }

      // Fallback to remote
      return await _getProfileFromRemote(userId);
    } catch (e, s) {
      logE('Failed to get profile by ID', error: e, stackTrace: s);
      return null;
    }
  }

  /// Get profile by username (local-first, then remote)
  Future<UserProfile?> getProfileByUsername(String username) async {
    try {
      // Try local first
      final result = await _powerSync.querySingle(
        'SELECT * FROM $_table WHERE LOWER(username) = ? LIMIT 1',
        parameters: [username.toLowerCase()],
      );

      if (result != null) {
        final profile = UserProfile.fromJson(result);
        return await _refreshAvatarUrl(profile);
      }

      // Fallback to remote
      final response = await _supabase.client
          .from(_table)
          .select()
          .ilike('username', username)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        return await _refreshAvatarUrl(profile);
      }

      return null;
    } catch (e, s) {
      logE('Failed to get profile by username', error: e, stackTrace: s);
      return null;
    }
  }

  // ================================================================
  // READ - LISTS
  // ================================================================

  /// Get public profiles
  Future<List<UserProfile>> getPublicProfiles({int limit = 50}) async {
    try {
      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_table 
        WHERE is_profile_public = 1 
        ORDER BY created_at DESC 
        LIMIT ?
        ''',
        parameters: [limit],
      );

      return _parseProfileList(results);
    } catch (e, s) {
      logE('Failed to get public profiles', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get influencers
  Future<List<UserProfile>> getInfluencers({int limit = 50}) async {
    try {
      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_table 
        WHERE json_extract(influencer, '\$.is_influencer') = 1 
        ORDER BY created_at DESC
        LIMIT ?
        ''',
        parameters: [limit],
      );

      return _parseProfileList(results);
    } catch (e, s) {
      logE('Failed to get influencers', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get organization members
  Future<List<UserProfile>> getOrganizationMembers(String orgName) async {
    try {
      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_table 
        WHERE json_extract(organization, '\$.name') = ? 
        ORDER BY username ASC
        ''',
        parameters: [orgName],
      );

      return _parseProfileList(results);
    } catch (e, s) {
      logE('Failed to get organization members', error: e, stackTrace: s);
      return [];
    }
  }

  /// Search profiles by username or email
  Future<List<UserProfile>> searchProfiles(
    String query, {
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    try {
      // Try remote first for latest results
      final response = await _supabase.client
          .from(_table)
          .select('*, score, global_rank')
          .or('username.ilike.%$query%,email.ilike.%$query%,display_name.ilike.%$query%')
          .eq('is_profile_public', true)
          .limit(limit);

      return _parseProfileList(response as List);
    } catch (remoteError) {
      logW('Remote search failed, falling back to local: $remoteError');

      // Fallback to local
      try {
        final lowerQuery = query.toLowerCase();
        final results = await _powerSync.executeQuery(
          '''
          SELECT * FROM $_table 
          WHERE (LOWER(username) LIKE ? OR LOWER(email) LIKE ? OR LOWER(display_name) LIKE ?)
          AND is_profile_public = 1
          ORDER BY username ASC
          LIMIT ?
          ''',
          parameters: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%', limit],
        );

        return _parseProfileList(results);
      } catch (e, s) {
        logE('Local search failed', error: e, stackTrace: s);
        return [];
      }
    }
  }

  // ================================================================
  // WATCH (REALTIME)
  // ================================================================

  /// Watch current user's profile for changes
  Stream<UserProfile?> watchMyProfile() {
    if (!isLoggedIn) return Stream.value(null);

    return _powerSync
        .watchQuery(
          'SELECT * FROM $_table WHERE user_id = ?',
          parameters: [currentUserId],
        )
        .asyncMap((results) async {
          if (results.isEmpty) return null;

          final profile = UserProfile.fromJson(results.first);
          return await _refreshAvatarUrl(profile);
        });
  }

  /// Watch public profiles
  Stream<List<UserProfile>> watchPublicProfiles({int limit = 50}) {
    return _powerSync
        .watchQuery(
          '''
          SELECT * FROM $_table 
          WHERE is_profile_public = 1 
          ORDER BY created_at DESC 
          LIMIT ?
          ''',
          parameters: [limit],
        )
        .asyncMap((results) => _parseProfileList(results));
  }

  // ================================================================
  // UPDATE
  // ================================================================

  /// Update current user's profile
  Future<UserProfile> updateMyProfile(ProfileUpdateDto updates) async {
    _assertLoggedIn();

    if (!updates.hasChanges) {
      logW('No changes to update');
      final current = await getMyProfileWithRemoteCheck();
      if (current != null) return current;
      throw ProfileException.notFound();
    }

    try {
      logI('Updating profile: $updates');

      // 1. Get existing profile (check remote if local is missing)
      // This handles the case where local data was cleared but remote exists
      UserProfile? existing = await getMyProfileWithRemoteCheck();

      // 2. If still null, try to see if we can create one from metadata (fallback)
      if (existing == null) {
        logW('Profile not found locally or remotely. Attempting to create one from auth metadata.');
        final user = _supabase.currentUser;
        if (user != null) {
          existing = UserProfile.empty(user.id, user.email ?? '');
        } else {
          throw ProfileException.notFound();
        }
      }

      // 3. Apply updates to the existing profile object
      // We use copyWith which has sanitization logic
      final updated = existing.copyWith(
        username: updates.username,
        displayName: updates.displayName,
        profileUrl: updates.profileUrl,
        address: updates.address,
        organizationName: updates.orgName,
        organizationLocation: updates.orgLocation,
        organizationRole: updates.orgRole,
        isInfluencer: updates.isInfluencer,
        influencerCategory: updates.influencerCategory,
        messageForFollower: updates.messageForFollower,
        primaryGoal: updates.primaryGoal,
        weaknesses: updates.weaknesses,
        strengths: updates.strengths,
        isProfilePublic: updates.isProfilePublic,
        openToChat: updates.openToChat,
        promotedCommunityId: updates.promotedCommunityId,
        subscriptionTier: updates.subscriptionTier,
        onboardingCompleted: updates.onboardingCompleted,
      );

      // 4. Upsert into local database (Put)
      // toLocalJson() provides a COMPLETE record for SQLite INSERT OR REPLACE
      await _powerSync.put(_table, updated.toLocalJson());

      logI('Profile updated and saved locally');
      return updated;
    } catch (e, s) {
      logE('Failed to update profile', error: e, stackTrace: s);

      if (e is ProfileException) rethrow;

      throw ProfileException(
        'Failed to update profile',
        code: 'UPDATE_FAILED',
        originalError: e,
      );
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin() async {
    if (!isLoggedIn) return;

    try {
      await _powerSync.update(_table, {
        'last_login': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, currentUserId!);
    } catch (e, s) {
      logE('Failed to update last login', error: e, stackTrace: s);
    }
  }

  // ================================================================
  // AVATAR OPERATIONS
  // ================================================================

  /// Upload avatar and return URL
  Future<String> uploadAvatar(XFile imageFile) async {
    _assertLoggedIn();

    try {
      logI('Uploading avatar...');

      // Verify bucket access
      final hasAccess = await _mediaService.verifyBucketAccess(
        MediaBucket.userAvatars,
      );
      if (!hasAccess) {
        throw ProfileException.uploadFailed('Storage bucket not accessible');
      }

      // 1. Generate Storage Path & Public URL Optimistically
      final fileName = imageFile.name; // or generated name
      // Note: uploadAvatar in MediaService generates a name. We should probably replicate that or let uploadSingle handle it?
      // Better: Use uploadSingle with exact path similar to ChatMediaRepository.

      final storagePath = '$currentUserId/$fileName';

      final publicUrl = _mediaService.getPublicUrl(
        bucket: MediaBucket.userAvatars,
        storagePath: storagePath,
      );

      // 2. Start Upload
      // We don't await the result primarily for the URL, but we DO want to ensure upload starts.
      // However, ProfileRepository usually awaits.
      // But we want to return the publicUrl immediately if we want "optimistic" behavior?
      // Actually, for profile update, we usually want to wait for success.
      // BUT the user said "always https".
      // If we wait, and it's offline, uploadSingle returns file://.
      // So we MUST use the optimistic URL and pass exactStoragePath.

      final file = File(imageFile.path);
      await _mediaService.uploadSingle(
        file: file,
        bucket: MediaBucket.userAvatars,
        exactStoragePath: storagePath,
        autoCompress: true,
      );

      // We return the public URL, assuming upload will succeed or queue background.
      // Note: uploadSingle returns the URL it got. If offline, it returns file://.
      // But we want to return publicUrl.

      logI('Avatar uploaded (optimistic): $publicUrl');
      return publicUrl;
    } catch (e, s) {
      logE('Failed to upload avatar', error: e, stackTrace: s);

      if (e is ProfileException) rethrow;
      throw ProfileException.uploadFailed(e);
    }
  }

  /// Upload avatar and update profile in one operation
  Future<UserProfile> uploadAndSetAvatar(XFile imageFile) async {
    final url = await uploadAvatar(imageFile);
    return updateMyProfile(ProfileUpdateDto.avatar(url));
  }

  /// Delete current avatar
  Future<void> deleteAvatar() async {
    _assertLoggedIn();

    try {
      final profile = await getMyProfile();
      if (profile?.profileUrl == null || profile!.profileUrl!.isEmpty) {
        logI('No avatar to delete');
        return;
      }

      // Delete from storage
      final deleted = await _mediaService.deleteSingle(
        mediaUrl: profile.profileUrl!,
        bucket: MediaBucket.userAvatars,
      );

      if (!deleted) {
        logW('Storage deletion failed, continuing to clear URL');
      }

      // Clear URL from profile
      await updateMyProfile(const ProfileUpdateDto(profileUrl: ''));

      logI('Avatar deleted successfully');
    } catch (e, s) {
      logE('Failed to delete avatar', error: e, stackTrace: s);
      throw ProfileException(
        'Failed to delete avatar',
        code: 'DELETE_AVATAR_FAILED',
        originalError: e,
      );
    }
  }

  // ================================================================
  // STATISTICS
  // ================================================================

  Future<int> getProfileCount() async {
    try {
      final result = await _powerSync.querySingle(
        'SELECT COUNT(*) as count FROM $_table',
      );
      return result?['count'] as int? ?? 0;
    } catch (e) {
      logE('Failed to get profile count', error: e);
      return 0;
    }
  }

  Future<int> getInfluencerCount() async {
    try {
      final result = await _powerSync.querySingle('''
        SELECT COUNT(*) as count FROM $_table 
        WHERE json_extract(influencer, '\$.is_influencer') = 1
        ''');
      return result?['count'] as int? ?? 0;
    } catch (e) {
      logE('Failed to get influencer count', error: e);
      return 0;
    }
  }

  Future<Map<String, int>> getStatistics() async {
    final total = await getProfileCount();
    final influencers = await getInfluencerCount();
    return {'total': total, 'influencers': influencers};
  }

  // ================================================================
  // SYNC OPERATIONS
  // ================================================================

  /// Force sync with remote
  Future<void> syncWithRemote() async {
    if (!isLoggedIn) return;

    try {
      logI('Syncing profile with remote...');

      if (_powerSync.isInitialized) {
        await _powerSync.waitForSync(timeout: const Duration(seconds: 15));
      }

      logI('Profile sync completed');
    } catch (e, s) {
      logE('Profile sync failed', error: e, stackTrace: s);
      throw ProfileException.syncFailed(e);
    }
  }

  /// Check if profile exists remotely
  Future<bool> profileExistsRemotely() async {
    if (!isLoggedIn) return false;

    try {
      final response = await _supabase.client
          .from(_table)
          .select('id')
          .eq('user_id', currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      logE('Failed to check remote profile', error: e);
      return false;
    }
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  void _assertLoggedIn() {
    if (!isLoggedIn) {
      throw ProfileException.notAuthenticated();
    }
  }

  Future<UserProfile?> _getProfileFromRemote(String userId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        return await _refreshAvatarUrl(profile);
      }
      return null;
    } catch (e) {
      logE('Failed to get profile from remote', error: e);
      return null;
    }
  }

  Future<UserProfile> _refreshAvatarUrl(UserProfile profile) async {
    // 🛡️ SANITY CHECK: We NO LONGER mutate the profileUrl with a local path here.
    // Overwriting the persistent field with a transient local path (file://) 
    // caused leaks into the database.
    // The UI layer (e.g., UserProfileScreen) is responsible for calling
    // mediaService.getValidAvatarUrl() for display-time resolution.
    return profile;
  }

  Future<List<UserProfile>> _parseProfileList(List<dynamic> results) async {
    final profiles = <UserProfile>[];

    for (final row in results) {
      try {
        final profile = UserProfile.fromJson(
          row is Map<String, dynamic> ? row : Map<String, dynamic>.from(row),
        );
        final refreshed = await _refreshAvatarUrl(profile);
        profiles.add(refreshed);
      } catch (e) {
        logW('Failed to parse profile: $e');
      }
    }

    return profiles;
  }

  // ================================================================
  // CLEANUP
  // ================================================================

  void dispose() {
    // Clean up any subscriptions if needed
  }
}

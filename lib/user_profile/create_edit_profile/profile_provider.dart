// ================================================================
// FILE: lib/user_profile/profile_provider.dart
// State management + Business logic for user profiles
// Uses ChangeNotifier with proper state handling
// ================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../Authentication/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/logger.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

/// Provider for managing user profile state and operations
class ProfileProvider extends ChangeNotifier {
  // ================================================================
  // DEPENDENCIES
  // ================================================================

  final ProfileRepository _repository;
  AuthProvider? _authProvider;

  // ================================================================
  // STATE
  // ================================================================

  UserProfile? _currentProfile;
  ProfileStatus _status = ProfileStatus.initial;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  // Subscriptions
  StreamSubscription<UserProfile?>? _profileSubscription;

  // ================================================================
  // GETTERS
  // ================================================================

  /// Current user's profile
  UserProfile? get currentProfile => _currentProfile;

  /// Alias for backward compatibility
  UserProfile? get myProfile => _currentProfile;

  /// Current profile status
  ProfileStatus get status => _status;

  /// Error message if status is error
  String? get errorMessage => _errorMessage;

  /// Error alias for backward compatibility
  String? get error => _errorMessage;

  /// Upload progress (0.0 - 1.0)
  double get uploadProgress => _uploadProgress;

  /// Whether profile is loading
  bool get isLoading => _status == ProfileStatus.loading;

  /// Whether profile is updating
  bool get isUpdating => _status == ProfileStatus.updating;

  /// Whether there's an error
  bool get hasError => _status == ProfileStatus.error;

  /// Whether profile is loaded
  bool get isLoaded =>
      _status == ProfileStatus.loaded && _currentProfile != null;

  /// Whether user is logged in
  bool get isLoggedIn =>
      _authProvider?.isAuthenticated ?? _repository.isLoggedIn;

  /// Current user ID
  String? get currentUserId => _repository.currentUserId;

  /// Profile completion percentage (0.0 - 1.0)
  double get completionPercentage =>
      _currentProfile?.completionPercentage ?? 0.0;

  /// Profile completion percentage as integer (0 - 100)
  int get completionPercentageInt => (completionPercentage * 100).toInt();

  /// Whether onboarding is completed
  bool get onboardingCompleted => _currentProfile?.onboardingCompleted ?? false;

  /// Whether profile has organization
  bool get hasOrganization => _currentProfile?.hasOrganization ?? false;

  /// Whether profile has goals set
  bool get hasGoals => _currentProfile?.hasGoals ?? false;

  /// Whether user is influencer
  bool get isInfluencer => _currentProfile?.isInfluencer ?? false;

  /// Whether profile is public
  bool get isProfilePublic => _currentProfile?.isProfilePublic ?? true;

  /// Subscription tier
  String get subscriptionTier => _currentProfile?.subscriptionTier ?? 'free';

  /// Display name
  String get displayName => _currentProfile?.displayName ?? 'User';

  /// User initials for avatar fallback
  String get initials => _currentProfile?.initials ?? '?';

  /// Profile URL
  String? get profileUrl => _currentProfile?.profileUrl;

  /// Username
  String get username => _currentProfile?.username ?? '';

  /// Email
  String get email => _currentProfile?.email ?? '';

  /// Username from auth metadata (initial fallback)
  String get authUsername =>
      _repository.currentUser?.userMetadata?['username'] as String? ?? '';

  /// Display name from auth metadata (initial fallback)
  String get authDisplayName =>
      _repository.currentUser?.userMetadata?['display_name'] as String? ??
      _repository.currentUser?.userMetadata?['full_name'] as String? ??
      authUsername;

  // ================================================================
  // CONSTRUCTOR
  // ================================================================

  ProfileProvider({
    ProfileRepository? repository,
    FirebaseService? firebaseService,
  }) : _repository = repository ?? ProfileRepository();

  // ================================================================
  // AUTH INTEGRATION
  // ================================================================

  /// Update auth provider reference (called by ProxyProvider)
  void updateAuth(AuthProvider auth) {
    final wasLoggedIn = _authProvider?.isAuthenticated ?? false;
    final isNowLoggedIn = auth.isAuthenticated;

    _authProvider = auth;

    // Handle auth state changes
    if (!wasLoggedIn && isNowLoggedIn) {
      // User just logged in - initialize profile
      logI('Auth state changed: User logged in, initializing profile...');
      initialize();
    } else if (wasLoggedIn && !isNowLoggedIn) {
      // User logged out - clear profile
      logI('Auth state changed: User logged out, clearing profile...');
      clear();
    }
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================

  /// Initialize the provider - call on app start or after login
  Future<void> initialize() async {
    if (!isLoggedIn) {
      logW('Cannot initialize ProfileProvider: User not logged in');
      return;
    }

    logI('Initializing ProfileProvider...');

    await loadProfile();
    _startWatchingProfile();

    logI('ProfileProvider initialized');
  }

  /// Dispose resources
  @override
  void dispose() {
    _profileSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  // ================================================================
  // LOAD PROFILE
  // ================================================================

  /// Load current user's profile (alias for loadProfile)
  Future<void> loadMyProfile({bool forceRefresh = false, bool silent = false}) async {
    await loadProfile(forceRefresh: forceRefresh, silent: silent);
  }

  /// Load current user's profile
  Future<void> loadProfile({bool forceRefresh = false, bool silent = false}) async {
    if (!isLoggedIn) {
      _setError('User not logged in');
      return;
    }

    if (!silent) {
      _setStatus(ProfileStatus.loading);
    }

    try {
      // Try to sync with remote first if force refresh
      if (forceRefresh) {
        try {
          await _repository.syncWithRemote();
        } catch (e) {
          logW('Sync failed, continuing with local data: $e');
        }
      }

      final profile = await _repository.getMyProfileWithRemoteCheck();

      if (profile != null) {
        _currentProfile = profile;
        _setStatus(ProfileStatus.loaded);
        logI('Profile loaded: ${profile.username}');
      } else {
        // Profile doesn't exist yet - might need onboarding
        _currentProfile = null;
        _setStatus(ProfileStatus.loaded);
        logI('No profile found - user may need onboarding');
      }
    } on ProfileException catch (e) {
      _setError(e.message);
      logE('Failed to load profile', error: e);
    } catch (e, s) {
      _setError('Failed to load profile');
      logE('Failed to load profile', error: e, stackTrace: s);
    }
  }

  /// Refresh profile from remote
  Future<void> refreshProfile() async {
    await loadProfile(forceRefresh: true);
  }

  // ================================================================
  // WATCH PROFILE
  // ================================================================

  void _startWatchingProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = _repository.watchMyProfile().listen(
      (profile) {
        if (profile != null && profile != _currentProfile) {
          _currentProfile = profile;
          _setStatus(ProfileStatus.loaded);
          logD('Profile updated via watch');
        }
      },
      onError: (e) {
        logE('Profile watch error', error: e);
      },
    );
  }

  // ================================================================
  // CREATE PROFILE
  // ================================================================

  /// Create a new profile during onboarding
  Future<bool> createProfile({
    required String username,
    required String displayName,
    String? address,
    String? profileUrl,
    String? organizationName,
    String? organizationLocation,
    String? organizationRole,
    bool isInfluencer = false,
    String? influencerCategory,
    String? messageForFollower,
    String? primaryGoal,
    List<String>? weaknesses,
    List<String>? strengths,
    bool isProfilePublic = true,
    bool openToChat = true,
    String subscriptionTier = 'free',
    bool onboardingCompleted = true,
  }) async {
    if (!isLoggedIn) {
      AppSnackbar.error('User not logged in');
      return false;
    }

    // Validate username
    if (username.length < ProfileConstants.minUsernameLength) {
      AppSnackbar.error(
        'Username too short',
        description:
            'Username must be at least ${ProfileConstants.minUsernameLength} characters',
      );
      return false;
    }

    if (!ProfileConstants.usernamePattern.hasMatch(username)) {
      AppSnackbar.error(
        'Invalid username',
        description:
            'Username can only contain letters, numbers, and underscores',
      );
      return false;
    }

    if (displayName.trim().isEmpty) {
      AppSnackbar.error(
        'Invalid display name',
        description: 'Display name cannot be empty',
      );
      return false;
    }

    _setStatus(ProfileStatus.updating);

    try {
      final profile = await _repository.createProfileFromData({
        'username': username.trim(),
        'display_name': displayName.trim(),
        'address': address?.trim(),
        'profile_url': profileUrl,
        'organization_name': organizationName?.trim(),
        'organization_location': organizationLocation?.trim(),
        'organization_role': organizationRole?.trim(),
        'is_influencer': isInfluencer,
        'influencer_category': influencerCategory?.trim(),
        'message_for_follower': messageForFollower?.trim(),
        'primary_goal': primaryGoal,
        'weaknesses': weaknesses ?? [],
        'strengths': strengths ?? [],
        'is_profile_public': isProfilePublic,
        'open_to_chat': openToChat,
        'subscription_tier': subscriptionTier,
        'onboarding_completed': onboardingCompleted,
      });

      _currentProfile = profile;
      _setStatus(ProfileStatus.loaded);

      logI('Profile created: ${profile.username}');
      return true;
    } on ProfileException catch (e) {
      _setError(e.message);
      AppSnackbar.error('Failed to create profile', description: e.message);
      return false;
    } catch (e, s) {
      _setError('Failed to create profile');
      logE('Failed to create profile', error: e, stackTrace: s);
      AppSnackbar.error('Failed to create profile', description: e.toString());
      return false;
    }
  }

  /// Create profile with optional avatar in a single fast operation
  Future<bool> createProfileWithAvatar({
    required String username,
    required String displayName,
    XFile? avatarFile,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!isLoggedIn) return false;

    _setStatus(ProfileStatus.updating);

    try {
      String? avatarUrl;
      
      // Start avatar upload in background if provided
      if (avatarFile != null) {
        logI('Starting background avatar upload...');
        // uploadAvatar returns the storage path (URL) immediately after local caching/queuing
        avatarUrl = await _repository.uploadAvatar(avatarFile);
      }

      // Merge data
      final Map<String, dynamic> data = {
        'username': username,
        'display_name': displayName,
        'profile_url': avatarUrl,
        if (additionalData != null) ...additionalData,
      };

      // Create profile metadata immediately
      final profile = await _repository.createProfileFromData(data);
      
      _currentProfile = profile;
      _setStatus(ProfileStatus.loaded);
      
      return true;
    } catch (e, s) {
      _setError('Failed to create profile');
      logE('Fast profile creation failed', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // UPDATE PROFILE
  // ================================================================

  /// Update profile with DTO
  Future<bool> updateProfile(ProfileUpdateDto updates) async {
    if (!isLoggedIn) {
      AppSnackbar.error('User not logged in');
      return false;
    }

    if (!updates.hasChanges) {
      logW('No changes to update');
      return true;
    }

    // Validate username if provided
    if (updates.username != null) {
      if (updates.username!.length < ProfileConstants.minUsernameLength) {
        AppSnackbar.error(
          'Username too short',
          description:
              'Username must be at least ${ProfileConstants.minUsernameLength} characters',
        );
        return false;
      }
      if (!ProfileConstants.usernamePattern.hasMatch(updates.username!)) {
        AppSnackbar.error(
          'Invalid username',
          description:
              'Username can only contain letters, numbers, and underscores',
        );
        return false;
      }
    }

    if (updates.displayName != null && updates.displayName!.trim().isEmpty) {
      AppSnackbar.error(
        'Invalid display name',
        description: 'Display name cannot be empty',
      );
      return false;
    }

    // Store current profile for rollback
    final previousProfile = _currentProfile;

    // Optimistic update
    if (_currentProfile != null) {
      _currentProfile = _applyUpdatesToProfile(_currentProfile!, updates);
      notifyListeners();
    }

    _setStatus(ProfileStatus.updating);

    try {
      final updatedProfile = await _repository.updateMyProfile(updates);
      _currentProfile = updatedProfile;
      _setStatus(ProfileStatus.loaded);

      logI('Profile updated: $updates');
      return true;
    } on ProfileException catch (e) {
      // Rollback
      _currentProfile = previousProfile;
      _setError(e.message);
      AppSnackbar.error('Failed to update profile', description: e.message);
      return false;
    } catch (e, s) {
      // Rollback
      _currentProfile = previousProfile;
      _setError('Failed to update profile');
      logE('Failed to update profile', error: e, stackTrace: s);
      AppSnackbar.error('Failed to update profile', description: e.toString());
      return false;
    }
  }

  /// Update basic info (username, address)
  Future<bool> updateBasicInfo({String? username, String? displayName, String? address}) async {
    return updateProfile(
      ProfileUpdateDto(username: username, displayName: displayName, address: address),
    );
  }

  /// Update organization info
  Future<bool> updateOrganization({
    String? name,
    String? location,
    String? role,
  }) async {
    return updateProfile(
      ProfileUpdateDto(orgName: name, orgLocation: location, orgRole: role),
    );
  }

  /// Update influencer status
  Future<bool> updateInfluencerStatus({
    required bool isInfluencer,
    String? category,
    String? message,
  }) async {
    return updateProfile(
      ProfileUpdateDto(
        isInfluencer: isInfluencer,
        influencerCategory: isInfluencer ? category : null,
        messageForFollower: isInfluencer ? message : null,
      ),
    );
  }

  /// Update user goals/info
  Future<bool> updateUserInfo({
    String? primaryGoal,
    List<String>? weaknesses,
    List<String>? strengths,
  }) async {
    return updateProfile(
      ProfileUpdateDto(
        primaryGoal: primaryGoal,
        weaknesses: weaknesses,
        strengths: strengths,
      ),
    );
  }

  /// Toggle profile visibility
  Future<bool> toggleProfileVisibility() async {
    final newVisibility = !isProfilePublic;
    final success = await updateProfile(
      ProfileUpdateDto(isProfilePublic: newVisibility),
    );

    if (success) {
      AppSnackbar.success(
        newVisibility ? 'Profile is now public' : 'Profile is now private',
      );
    }

    return success;
  }

  /// Update subscription tier
  Future<bool> updateSubscription(String tier) async {
    if (!ProfileConstants.subscriptionTiers.contains(tier)) {
      AppSnackbar.error('Invalid subscription tier');
      return false;
    }

    return updateProfile(ProfileUpdateDto(subscriptionTier: tier));
  }

  /// Mark onboarding as completed
  Future<bool> completeOnboarding() async {
    return updateProfile(ProfileUpdateDto.completeOnboarding());
  }

  // ================================================================
  // AVATAR OPERATIONS
  // ================================================================

  /// Upload and set avatar
  Future<bool> uploadAvatar(XFile imageFile) async {
    if (!isLoggedIn) {
      AppSnackbar.error('User not logged in');
      return false;
    }

    _uploadProgress = 0.0;
    notifyListeners();

    try {
      _uploadProgress = 0.3;
      notifyListeners();

      final updatedProfile = await _repository.uploadAndSetAvatar(imageFile);

      _uploadProgress = 1.0;
      _currentProfile = updatedProfile;
      notifyListeners();

      logI('Avatar uploaded successfully');
      return true;
    } on ProfileException catch (e) {
      _uploadProgress = 0.0;
      notifyListeners();
      logE('Failed to upload avatar', error: e);
      return false;
    } catch (e, s) {
      _uploadProgress = 0.0;
      notifyListeners();
      logE('Failed to upload avatar', error: e, stackTrace: s);
      return false;
    }
  }

  /// Delete current avatar
  Future<bool> deleteAvatar() async {
    if (!isLoggedIn) {
      AppSnackbar.error('User not logged in');
      return false;
    }

    if (_currentProfile?.profileUrl == null) {
      AppSnackbar.info(title: 'No picture to remove');
      return true;
    }

    try {
      await _repository.deleteAvatar();

      _currentProfile = _currentProfile?.copyWith(profileUrl: null);
      notifyListeners();

      return true;
    } on ProfileException catch (e) {
      AppSnackbar.error('Failed to remove picture', description: e.message);
      return false;
    } catch (e, s) {
      logE('Failed to delete avatar', error: e, stackTrace: s);
      AppSnackbar.error('Failed to remove picture', description: e.toString());
      return false;
    }
  }

  // ================================================================
  // SEARCH & FETCH OTHER PROFILES
  // ================================================================

  /// Get profile by user ID
  Future<UserProfile?> getProfileById(String userId) async {
    try {
      return await _repository.getProfileById(userId);
    } catch (e, s) {
      logE('Failed to get profile by ID', error: e, stackTrace: s);
      return null;
    }
  }

  /// Get profile by username
  Future<UserProfile?> getProfileByUsername(String username) async {
    try {
      return await _repository.getProfileByUsername(username);
    } catch (e, s) {
      logE('Failed to get profile by username', error: e, stackTrace: s);
      return null;
    }
  }

  /// Search profiles
  Future<List<UserProfile>> searchProfiles(
    String query, {
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    try {
      return await _repository.searchProfiles(query, limit: limit);
    } catch (e, s) {
      logE('Failed to search profiles', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get public profiles
  Future<List<UserProfile>> getPublicProfiles({int limit = 50}) async {
    try {
      return await _repository.getPublicProfiles(limit: limit);
    } catch (e, s) {
      logE('Failed to get public profiles', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get influencers
  Future<List<UserProfile>> getInfluencers({int limit = 50}) async {
    try {
      return await _repository.getInfluencers(limit: limit);
    } catch (e, s) {
      logE('Failed to get influencers', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get organization members
  Future<List<UserProfile>> getOrganizationMembers(String orgName) async {
    try {
      return await _repository.getOrganizationMembers(orgName);
    } catch (e, s) {
      logE('Failed to get organization members', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // STATISTICS
  // ================================================================

  /// Get profile statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _repository.getStatistics();
    } catch (e, s) {
      logE('Failed to get statistics', error: e, stackTrace: s);
      return {'total': 0, 'influencers': 0};
    }
  }

  // ================================================================
  // LAST LOGIN
  // ================================================================

  /// Update last login timestamp
  Future<void> updateLastLogin() async {
    try {
      await _repository.updateLastLogin();
    } catch (e, s) {
      logE('Failed to update last login', error: e, stackTrace: s);
    }
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Check if given user ID is current user
  bool isMyProfile(String userId) {
    return _currentProfile?.id == userId || _currentProfile?.userId == userId;
  }

  /// Clear all state (call on logout)
  void clear() {
    _profileSubscription?.cancel();
    _currentProfile = null;
    _status = ProfileStatus.initial;
    _errorMessage = null;
    _uploadProgress = 0.0;
    notifyListeners();
    logI('ProfileProvider cleared');
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  void _setStatus(ProfileStatus status) {
    _status = status;
    if (status != ProfileStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _status = ProfileStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Apply DTO updates to profile (for optimistic updates)
  UserProfile _applyUpdatesToProfile(
    UserProfile profile,
    ProfileUpdateDto updates,
  ) {
    return profile.copyWith(
      username: updates.username ?? profile.username,
      displayName: updates.displayName ?? profile.displayName,
      profileUrl: updates.profileUrl ?? profile.profileUrl,
      address: updates.address ?? profile.address,
      organizationName: updates.orgName ?? profile.organizationName,
      organizationLocation: updates.orgLocation ?? profile.organizationLocation,
      organizationRole: updates.orgRole ?? profile.organizationRole,
      isInfluencer: updates.isInfluencer ?? profile.isInfluencer,
      influencerCategory:
          updates.influencerCategory ?? profile.influencerCategory,
      messageForFollower:
          updates.messageForFollower ?? profile.messageForFollower,
      primaryGoal: updates.primaryGoal ?? profile.primaryGoal,
      weaknesses: updates.weaknesses ?? profile.weaknesses,
      strengths: updates.strengths ?? profile.strengths,
      isProfilePublic: updates.isProfilePublic ?? profile.isProfilePublic,
      openToChat: updates.openToChat ?? profile.openToChat,
      subscriptionTier: updates.subscriptionTier ?? profile.subscriptionTier,
      onboardingCompleted:
          updates.onboardingCompleted ?? profile.onboardingCompleted,
    );
  }
}

// ================================================================
// EXTENSION FOR EASY ACCESS IN WIDGETS
// ================================================================

extension ProfileProviderExtension on ProfileProvider {
  /// Get a short summary for display
  String get profileSummary {
    if (_currentProfile == null) return 'No profile';
    return '${_currentProfile!.displayName} ($completionPercentageInt% complete)';
  }

  /// Get subscription badge text
  String get subscriptionBadge {
    switch (subscriptionTier) {
      case 'pro':
        return 'PRO';
      case 'elite':
        return 'ELITE';
      default:
        return 'FREE';
    }
  }

  /// Check if user has premium subscription
  bool get isPremium => subscriptionTier != 'free';

  /// Check if profile needs attention (low completion)
  bool get needsAttention => completionPercentage < 0.5;

  /// Get greeting message
  String get greeting {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    return '$timeGreeting, $displayName!';
  }
}

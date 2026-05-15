// ============================================================
// 📁 providers/follow_provider.dart
// Follow Provider - State management for follow operations
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/follow_repository.dart';
import '../models/follows_model.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class FollowProvider extends ChangeNotifier {
  final FollowRepository _repository;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  // State
  final Map<String, FollowButtonState> _buttonStates = {};
  final Map<String, FollowStatusCheck> _statusCache = {};

  FollowersList? _currentFollowers;
  FollowingList? _currentFollowing;
  List<FollowRequest> _pendingRequests = [];
  List<FollowingUser> _blockedUsers = [];
  List<FollowSuggestion> _suggestions = [];

  bool _isLoading = false;
  String? _error;

  FollowProvider({FollowRepository? repository})
    : _repository = repository ?? FollowRepository();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  FollowersList? get currentFollowers => _currentFollowers;
  FollowingList? get currentFollowing => _currentFollowing;
  List<FollowRequest> get pendingRequests => _pendingRequests;
  List<FollowingUser> get blockedUsers => _blockedUsers;
  List<FollowSuggestion> get suggestions => _suggestions;
  int get pendingRequestsCount => _pendingRequests.length;

  // ════════════════════════════════════════════════════════════
  // BUTTON STATE MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Get button state for a user
  FollowButtonState getButtonState(String userId) {
    return _buttonStates[userId] ?? FollowButtonState(targetUserId: userId);
  }

  /// Initialize button state from status check
  Future<FollowButtonState> initializeButtonState(String userId) async {
    if (_buttonStates.containsKey(userId)) {
      return _buttonStates[userId]!;
    }

    final status = await _repository.checkFollowStatus(userId);
    final state = FollowButtonState.fromStatusCheck(userId, status);

    _buttonStates[userId] = state;
    _statusCache[userId] = status;
    notifyListeners();

    return state;
  }

  // ════════════════════════════════════════════════════════════
  // TOGGLE FOLLOW
  // ════════════════════════════════════════════════════════════

  /// Toggle follow for a user
  Future<ToggleFollowResult?> toggleFollow(String userId) async {
    // Update UI immediately (optimistic)
    final currentState =
        _buttonStates[userId] ?? FollowButtonState(targetUserId: userId);
    _buttonStates[userId] = currentState.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _repository.toggleFollow(userId);

      // Update state based on result
      _buttonStates[userId] = currentState.applyToggleResult(result);

      // Show feedback
      if (result.isFollowed) {
        AppSnackbar.success('Following');
      } else if (result.isRequested) {
        AppSnackbar.info(title: 'Follow Request Sent');
      } else if (result.isUnfollowed) {
        AppSnackbar.info(title: 'Unfollowed');
      }

      notifyListeners();
      return result;
    } catch (e) {
      // Revert on error
      _buttonStates[userId] = currentState.copyWith(isLoading: false);
      ErrorHandler.showErrorSnackbar('Failed to update follow status');
      notifyListeners();
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  // FOLLOWERS
  // ════════════════════════════════════════════════════════════

  /// Load followers for a user
  Future<void> loadFollowers({
    required String userId,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) _currentFollowers = null;
    notifyListeners();

    try {
      _currentFollowers = await _repository.getFollowers(
        userId: userId,
        offset: refresh ? 0 : (_currentFollowers?.offset ?? 0),
      );
    } catch (e) {
      _error = 'Failed to load followers';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more followers (pagination)
  Future<void> loadMoreFollowers(String userId) async {
    if (_isLoading ||
        _currentFollowers == null ||
        !_currentFollowers!.hasMore) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final more = await _repository.getFollowers(
        userId: userId,
        offset: _currentFollowers!.offset + _currentFollowers!.users.length,
      );
      _currentFollowers = _currentFollowers!.appendUsers(more);
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load more followers');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // FOLLOWING
  // ════════════════════════════════════════════════════════════

  /// Load following
  Future<void> loadFollowing({
    required String userId,
    FollowRelationship? relationship,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) _currentFollowing = null;
    notifyListeners();

    try {
      _currentFollowing = await _repository.getFollowing(
        userId: userId,
        relationship: relationship,
        offset: refresh ? 0 : (_currentFollowing?.offset ?? 0),
      );
    } catch (e) {
      _error = 'Failed to load following';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more following
  Future<void> loadMoreFollowing(
    String userId, {
    FollowRelationship? relationship,
  }) async {
    if (_isLoading ||
        _currentFollowing == null ||
        !_currentFollowing!.hasMore) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final more = await _repository.getFollowing(
        userId: userId,
        relationship: relationship,
        offset: _currentFollowing!.offset + _currentFollowing!.users.length,
      );
      _currentFollowing = _currentFollowing!.appendUsers(more);
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load more');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load pending follow requests
  Future<void> loadPendingRequests() async {
    try {
      _pendingRequests = await _repository.getPendingRequests();
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load follow requests');
    }
  }

  /// Accept follow request
  Future<void> acceptFollowRequest(String followerId) async {
    try {
      await _repository.respondToFollowRequest(
        followerId: followerId,
        accept: true,
      );
      _pendingRequests.removeWhere((r) => r.userId == followerId);
      AppSnackbar.success('Follow request accepted');
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to accept request');
    }
  }

  /// Reject follow request
  Future<void> rejectFollowRequest(String followerId) async {
    try {
      await _repository.respondToFollowRequest(
        followerId: followerId,
        accept: false,
      );
      _pendingRequests.removeWhere((r) => r.userId == followerId);
      AppSnackbar.info(title: 'Follow request declined');
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to decline request');
    }
  }

  /// Load follow suggestions
  Future<void> loadSuggestions() async {
    try {
      _suggestions = await _repository.getFollowSuggestions();
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load suggestions');
    }
  }

  /// Dismiss a suggestion
  void dismissSuggestion(String userId) {
    _suggestions.removeWhere((s) => s.userId == userId);
    notifyListeners();
  }

  /// Update relationship
  Future<void> updateRelationship({
    required String userId,
    required FollowRelationship relationship,
  }) async {
    try {
      await _repository.updateRelationship(
        targetUserId: userId,
        relationship: relationship,
      );

      // Update local state
      final currentState = _buttonStates[userId];
      if (currentState != null) {
        _buttonStates[userId] = currentState.copyWith(
          relationship: relationship,
        );
      }

      // Refresh following list if we're on that screen
      if (_currentFollowing != null) {
        await loadFollowing(userId: _currentUserId!, refresh: true);
      }

      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to update relationship');
    }
  }

  /// Add to close friends
  Future<void> addToCloseFriends(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.closeFriend,
    );
  }

  /// Remove from close friends
  Future<void> removeFromCloseFriends(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  /// Mute user
  Future<void> muteUser(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.muted,
    );
  }

  /// Unmute user
  Future<void> unmuteUser(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  /// Restrict user
  Future<void> restrictUser(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.restricted,
    );
  }

  /// Unrestrict user
  Future<void> unrestrictUser(String userId) async {
    await updateRelationship(
      userId: userId,
      relationship: FollowRelationship.follow,
    );
  }

  // ════════════════════════════════════════════════════════════
  // STATS & CHECKS
  // ════════════════════════════════════════════════════════════

  Future<int> getFollowersCount(String userId) async {
    final counts = await _repository.getSocialCounts(userId);
    return counts.followersCount;
  }

  Future<int> getFollowingCount(String userId) async {
    final counts = await _repository.getSocialCounts(userId);
    return counts.followingCount;
  }

  Future<bool> isFollowing(String userId) async {
    if (_statusCache.containsKey(userId)) {
      return _statusCache[userId]!.isFollowing;
    }
    final status = await _repository.checkFollowStatus(userId);
    _statusCache[userId] = status;
    return status.isFollowing;
  }

  /// Load blocked users
  Future<void> loadBlockedUsers({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    if (refresh) _blockedUsers = [];
    notifyListeners();

    try {
      _blockedUsers = await _repository.getBlockedUsers();
    } catch (e) {
      _error = 'Failed to load blocked users';
      ErrorHandler.showErrorSnackbar(_error!);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // BLOCK / UNBLOCK
  // ════════════════════════════════════════════════════════════

  /// Block a user
  Future<void> blockUser(String userId) async {
    try {
      await _repository.blockUser(userId);

      _buttonStates[userId] = FollowButtonState(
        targetUserId: userId,
        isBlocked: true,
      );

      AppSnackbar.info(title: 'User blocked');
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to block user');
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      await _repository.unblockUser(userId);

      _buttonStates[userId] = FollowButtonState(
        targetUserId: userId,
        isBlocked: false,
      );

      AppSnackbar.info(title: 'User unblocked');
      notifyListeners();
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to unblock user');
    }
  }

  // ════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════

  /// Clear all cached data
  void clearCache() {
    _buttonStates.clear();
    _statusCache.clear();
    _currentFollowers = null;
    _currentFollowing = null;
    _pendingRequests.clear();
    _suggestions.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}

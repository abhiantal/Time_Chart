// ================================================================
// FILE: lib/features/mentoring/providers/mentorship_provider.dart
// Provider for mentorship_connections
// ================================================================

import 'dart:async';
import 'package:flutter/material.dart';


import '../../../../../widgets/error_handler.dart';
import '../../../../../widgets/logger.dart';
import '../../../../user_profile/create_edit_profile/profile_models.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';
import '../models/mentorship_model.dart';
import '../repositories/mentorship_repository.dart';

class MentorshipProvider extends ChangeNotifier {
  final MentorshipRepository _repository = MentorshipRepository();
  final ProfileRepository _profileRepo = ProfileRepository();


  // Profile Cache for Mentor/Mentee Names and Avatars
  final Map<String, UserProfile> _profilesCache = {};
  UserProfile? getUserProfile(String userId) => _profilesCache[userId];

  Future<void> loadProfilesForUsers(Iterable<String> userIds) async {
    final uniqueIds = userIds
        .where((id) => !_profilesCache.containsKey(id))
        .toSet();
    if (uniqueIds.isEmpty) return;

    final futures = uniqueIds.map((id) async {
      try {
        final profile = await _profileRepo.getProfileById(id);
        if (profile != null) {
          _profilesCache[id] = profile;
        }
      } catch (e) {
        logW('Failed to load profile for $id: $e');
      }
    });

    await Future.wait(futures);
    notifyListeners();
  }

  // ================================================================
  // STATE
  // ================================================================

  List<MentorshipConnection> _myMentors = [];
  List<MentorshipConnection> _myMentees = [];
  List<MentorshipConnection> _allIncomingRequests = [];
  List<MentorshipConnection> _allOutgoingRequests = [];
  List<MentorshipConnection> _pendingOffers = [];
  Map<String, int> _stats = {};
  MentorshipConnection? _selectedConnection;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<MentorshipConnection>>? _mentorsSubscription;
  StreamSubscription<List<MentorshipConnection>>? _menteesSubscription;
  StreamSubscription<List<MentorshipConnection>>? _incomingSubscription;
  StreamSubscription<List<MentorshipConnection>>? _outgoingSubscription;

  // ================================================================
  // GETTERS
  // ================================================================

  List<MentorshipConnection> get myMentors => List.unmodifiable(_myMentors);
  List<MentorshipConnection> get myMentees => List.unmodifiable(_myMentees);
  List<MentorshipConnection> get allIncomingRequests =>
      List.unmodifiable(_allIncomingRequests);
  List<MentorshipConnection> get allOutgoingRequests =>
      List.unmodifiable(_allOutgoingRequests);

  List<MentorshipConnection> get incomingRequests => _allIncomingRequests
      .where((r) => r.requestStatus == RequestStatus.pending)
      .toList();

  List<MentorshipConnection> get outgoingRequests => _allOutgoingRequests
      .where((r) => r.requestStatus == RequestStatus.pending)
      .toList();

  List<MentorshipConnection> get pendingOffers =>
      List.unmodifiable(_pendingOffers);
  Map<String, int> get stats => Map.unmodifiable(_stats);
  MentorshipConnection? get selectedConnection => _selectedConnection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  List<MentorshipConnection> get activeMentors =>
      _myMentors.where((m) => m.accessStatus == AccessStatus.active).toList();

  List<MentorshipConnection> get activeMentees =>
      _myMentees.where((m) => m.accessStatus == AccessStatus.active).toList();

  List<MentorshipConnection> get pausedMentors =>
      _myMentors.where((m) => m.accessStatus == AccessStatus.paused).toList();

  List<MentorshipConnection> get pausedMentees =>
      _myMentees.where((m) => m.accessStatus == AccessStatus.paused).toList();

  List<MentorshipConnection> get inactiveMentees => _myMentees.where((m) {
    if (m.lastViewedAt == null) return false;
    final daysSinceView = DateTime.now().difference(m.lastViewedAt!).inDays;
    return daysSinceView >= m.inactiveThresholdDays;
  }).toList();

  int get pendingIncomingCount => incomingRequests.length;
  int get pendingOutgoingCount => outgoingRequests.length;
  int get pendingOffersCount => _pendingOffers.length;
  int get totalPendingCount =>
      pendingIncomingCount + pendingOutgoingCount + pendingOffersCount;

  bool get hasAnyMentorship => _myMentors.isNotEmpty || _myMentees.isNotEmpty;
  bool get hasPendingRequests => totalPendingCount > 0;

  int get totalMentors => _stats['total_mentors'] ?? 0;
  int get totalMentees => _stats['total_mentees'] ?? 0;
  int get activeMentorsCount => _stats['active_mentors'] ?? 0;
  int get activeMenteesCount => _stats['active_mentees'] ?? 0;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  Future<void> initialize(String? userId) async {
    if (userId == null || userId.isEmpty) {
      logW('⚠️ MentorshipProvider: No user ID provided');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      logI('🚀 Initializing MentorshipProvider for user: $userId');

      // Load all data
      await Future.wait([
        _loadMyMentors(userId),
        _loadMyMentees(userId),
        _loadIncomingRequests(userId),
        _loadOutgoingRequests(userId),
        _loadPendingOffers(userId),
        _loadStats(userId),
      ]);

      // Check for expired connections
      await _repository.checkExpiredConnections();

      // Start watching
      _startWatching(userId);

      logI('✅ MentorshipProvider initialized');
    } catch (e, stack) {
      logE(
        '❌ MentorshipProvider initialization failed',
        error: e,
        stackTrace: stack,
      );
      _setError('Failed to load mentorship data');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAll() async {
    final userId = _repository.currentUserId;
    if (userId.isEmpty) {
      logW('⚠️ Cannot refresh: No user ID');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      await Future.wait([
        _loadMyMentors(userId),
        _loadMyMentees(userId),
        _loadIncomingRequests(userId),
        _loadOutgoingRequests(userId),
        _loadPendingOffers(userId),
        _loadStats(userId),
      ]);

      await _repository.checkExpiredConnections();

      logI('✅ All data refreshed');
    } catch (e, stack) {
      logE('❌ Refresh failed', error: e, stackTrace: stack);
      _setError('Failed to refresh data');
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // LOAD METHODS
  // ================================================================

  Future<void> _loadMyMentors(String userId) async {
    try {
      _myMentors = await _repository.getMyMentors(userId);
      await loadProfilesForUsers(_myMentors.map((m) => m.mentorId));
      notifyListeners();
      logI('✅ Loaded ${_myMentors.length} mentors');
    } catch (e, stack) {
      logE('❌ Failed to load mentors', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _loadMyMentees(String userId) async {
    try {
      _myMentees = await _repository.getMyMentees(userId);
      await loadProfilesForUsers(_myMentees.map((m) => m.ownerId));
      notifyListeners();
      logI('✅ Loaded ${_myMentees.length} mentees');
    } catch (e, stack) {
      logE('❌ Failed to load mentees', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _loadIncomingRequests(String userId) async {
    try {
      _allIncomingRequests = await _repository.getIncomingRequests(userId);
      loadProfilesForUsers(_allIncomingRequests.map((r) => r.mentorId));
      notifyListeners();
      logI('✅ Loaded ${_allIncomingRequests.length} incoming requests');
    } catch (e, stack) {
      logE('❌ Failed to load incoming requests', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _loadOutgoingRequests(String userId) async {
    try {
      _allOutgoingRequests = await _repository.getOutgoingRequests(userId);
      loadProfilesForUsers(_allOutgoingRequests.map((r) => r.ownerId));
      notifyListeners();
      logI('✅ Loaded ${_allOutgoingRequests.length} outgoing requests');
    } catch (e, stack) {
      logE('❌ Failed to load outgoing requests', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _loadPendingOffers(String userId) async {
    try {
      _pendingOffers = await _repository.getPendingOffersToMe(userId);
      loadProfilesForUsers(_pendingOffers.map((o) => o.ownerId));
      notifyListeners();
      logI('✅ Loaded ${_pendingOffers.length} pending offers');
    } catch (e, stack) {
      logE('❌ Failed to load pending offers', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _loadStats(String userId) async {
    try {
      _stats = await _repository.getStats(userId);
      notifyListeners();
      logI('✅ Loaded leaderboard');
    } catch (e, stack) {
      logE('❌ Failed to load leaderboard', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ================================================================
  // STREAM WATCHING
  // ================================================================

  void _startWatching(String userId) {
    _stopWatching();

    _mentorsSubscription = _repository.watchMyMentors(userId).listen((mentors) {
      _myMentors = mentors;
      loadProfilesForUsers(mentors.map((m) => m.mentorId));
      notifyListeners();
    }, onError: (e) => logE('Mentors stream error', error: e));

    _menteesSubscription = _repository.watchMyMentees(userId).listen((mentees) {
      _myMentees = mentees;
      loadProfilesForUsers(mentees.map((m) => m.ownerId));
      notifyListeners();
    }, onError: (e) => logE('Mentees stream error', error: e));

    _incomingSubscription = _repository.watchIncomingRequests(userId).listen((
      requests,
    ) {
      _allIncomingRequests = requests;
      notifyListeners();
    }, onError: (e) => logE('Incoming requests stream error', error: e));

    _outgoingSubscription = _repository.watchOutgoingRequests(userId).listen((
      requests,
    ) {
      _allOutgoingRequests = requests;
      notifyListeners();
    }, onError: (e) => logE('Outgoing requests stream error', error: e));

    logI('✅ Started watching mentorship streams');
  }

  void _stopWatching() {
    _mentorsSubscription?.cancel();
    _menteesSubscription?.cancel();
    _incomingSubscription?.cancel();
    _outgoingSubscription?.cancel();
    _mentorsSubscription = null;
    _menteesSubscription = null;
    _incomingSubscription = null;
    _outgoingSubscription = null;
  }

  // ================================================================
  // REQUEST ACTIONS
  // ================================================================

  /// Send access request (I want to monitor someone)
  Future<MentorshipConnection?> sendAccessRequest({
    required String targetUserId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    List<AccessibleScreen> screens = const [AccessibleScreen.dashboard],
    MentorshipPermissions? permissions,
    AccessDuration duration = AccessDuration.oneMonth,
    String? message,
  }) async {
    try {
      _setLoading(true);

      final currentUserId = _repository.currentUserId;
      if (currentUserId.isEmpty) {
        ErrorHandler.showErrorSnackbar('Not authenticated');
        return null;
      }

      if (targetUserId == currentUserId) {
        ErrorHandler.showErrorSnackbar('Cannot request access to yourself');
        return null;
      }

      // Check if connection already exists
      final existing = await _repository.getConnectionForPair(
        targetUserId,
        currentUserId,
      );
      if (existing != null) {
        if (existing.isPending) {
          ErrorHandler.showErrorSnackbar('Request already pending');
          return null;
        }
        if (existing.isActive) {
          ErrorHandler.showErrorSnackbar('You already have access');
          return null;
        }
      }

      final connection = MentorshipConnection.forRequestAccess(
        ownerId: targetUserId,
        mentorId: currentUserId,
        relationshipType: relationshipType,
        relationshipLabel: relationshipLabel,
        screens: screens,
        permissions: permissions,
        duration: duration,
        message: message,
      );

      final result = await _repository.createAccessRequest(connection);

      if (result != null) {
        _allOutgoingRequests.add(result);
        notifyListeners();
        // Notifications are now handled by the backend/modular architecture
        logI('✅ Access request sent');
      }

      return result;
    } catch (e, stack) {
      logE('❌ Failed to send access request', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to send request');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Share access (I want to share my data with someone)
  Future<MentorshipConnection?> shareAccessWith({
    required String viewerId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    List<AccessibleScreen> screens = const [AccessibleScreen.dashboard],
    MentorshipPermissions? permissions,
    AccessDuration duration = AccessDuration.always,
    bool isLiveEnabled = true,
  }) async {
    try {
      _setLoading(true);

      final currentUserId = _repository.currentUserId;
      if (currentUserId.isEmpty) {
        ErrorHandler.showErrorSnackbar('Not authenticated');
        return null;
      }

      if (viewerId == currentUserId) {
        ErrorHandler.showErrorSnackbar('Cannot share access with yourself');
        return null;
      }

      // Check if connection already exists
      final existing = await _repository.getConnectionForPair(
        currentUserId,
        viewerId,
      );
      if (existing != null) {
        if (existing.isActive) {
          ErrorHandler.showErrorSnackbar('Already sharing with this user');
          return null;
        }
      }

      final connection = MentorshipConnection.forOfferShare(
        ownerId: currentUserId,
        mentorId: viewerId,
        relationshipType: relationshipType,
        relationshipLabel: relationshipLabel,
        screens: screens,
        permissions: permissions,
        duration: duration,
        isLiveEnabled: isLiveEnabled,
      );

      final result = await _repository.createShareOffer(connection);

      if (result != null) {
        _myMentors.add(result);
        notifyListeners();
        // Notifications are now handled by the backend/modular architecture
        logI('✅ Access shared');
      }

      return result;
    } catch (e, stack) {
      logE('❌ Failed to share access', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Failed to share access');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Approve incoming request
  Future<bool> approveRequest(
    String connectionId, {
    MentorshipPermissions? customPermissions,
    List<AccessibleScreen>? customScreens,
    String? responseMessage,
  }) async {
    try {
      _setLoading(true);

      final success = await _repository.approveRequest(
        connectionId,
        customPermissions: customPermissions,
        customScreens: customScreens,
        responseMessage: responseMessage,
      );

      if (success) {
        // Update local status for immediate feedback
        final incomingIndex = _allIncomingRequests.indexWhere(
          (r) => r.id == connectionId,
        );
        if (incomingIndex != -1) {
          _allIncomingRequests[incomingIndex] =
              _allIncomingRequests[incomingIndex].copyWith(
                requestStatus: RequestStatus.approved,
                accessStatus: AccessStatus.active,
                respondedAt: DateTime.now(),
              );
        }

        // Add to mentors if not already there
        final mentorIndex = _myMentors.indexWhere((m) => m.id == connectionId);
        if (mentorIndex == -1 && incomingIndex != -1) {
          _myMentors.add(_allIncomingRequests[incomingIndex]);
        }

        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to approve request', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reject incoming request
  Future<bool> rejectRequest(String connectionId, {String? reason}) async {
    try {
      _setLoading(true);

      final success = await _repository.rejectRequest(
        connectionId,
        responseMessage: reason,
      );

      if (success) {
        final index = _allIncomingRequests.indexWhere(
          (r) => r.id == connectionId,
        );
        if (index != -1) {
          _allIncomingRequests[index] = _allIncomingRequests[index].copyWith(
            requestStatus: RequestStatus.rejected,
            respondedAt: DateTime.now(),
          );
        }
        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to reject request', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel outgoing request
  Future<bool> cancelRequest(String connectionId) async {
    try {
      _setLoading(true);

      final success = await _repository.cancelRequest(connectionId);

      if (success) {
        final index = _allOutgoingRequests.indexWhere(
          (r) => r.id == connectionId,
        );
        if (index != -1) {
          _allOutgoingRequests[index] = _allOutgoingRequests[index].copyWith(
            requestStatus: RequestStatus.cancelled,
            updatedAt: DateTime.now(),
          );
        }
        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to cancel request', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // ACCESS MANAGEMENT
  // ================================================================

  /// Revoke access (stop someone from viewing me, or stop viewing someone)
  Future<bool> revokeAccess(String connectionId) async {
    try {
      _setLoading(true);

      final success = await _repository.revokeAccess(connectionId);

      if (success) {
        // Remove from both lists since revoked items should not appear
        _myMentors.removeWhere((m) => m.id == connectionId);
        _myMentees.removeWhere((m) => m.id == connectionId);
        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to revoke access', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Pause access
  Future<bool> pauseAccess(String connectionId) async {
    try {
      _setLoading(true);

      final success = await _repository.pauseAccess(connectionId);

      if (success) {
        // Update in mentors list
        final mentorIndex = _myMentors.indexWhere((m) => m.id == connectionId);
        if (mentorIndex != -1) {
          _myMentors[mentorIndex] = _myMentors[mentorIndex].copyWith(
            accessStatus: AccessStatus.paused,
          );
        }
        // Also update in mentees list
        final menteeIndex = _myMentees.indexWhere((m) => m.id == connectionId);
        if (menteeIndex != -1) {
          _myMentees[menteeIndex] = _myMentees[menteeIndex].copyWith(
            accessStatus: AccessStatus.paused,
          );
        }
        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to pause access', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resume access
  Future<bool> resumeAccess(String connectionId) async {
    try {
      _setLoading(true);

      final success = await _repository.resumeAccess(connectionId);

      if (success) {
        // Update in mentors list
        final mentorIndex = _myMentors.indexWhere((m) => m.id == connectionId);
        if (mentorIndex != -1) {
          _myMentors[mentorIndex] = _myMentors[mentorIndex].copyWith(
            accessStatus: AccessStatus.active,
          );
        }
        // Also update in mentees list
        final menteeIndex = _myMentees.indexWhere((m) => m.id == connectionId);
        if (menteeIndex != -1) {
          _myMentees[menteeIndex] = _myMentees[menteeIndex].copyWith(
            accessStatus: AccessStatus.active,
          );
        }
        await _loadStats(_repository.currentUserId);
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to resume access', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update permissions
  Future<bool> updatePermissions(
    String connectionId, {
    MentorshipPermissions? permissions,
    List<AccessibleScreen>? screens,
    bool? isLiveEnabled,
  }) async {
    try {
      _setLoading(true);

      final success = await _repository.updatePermissions(
        connectionId,
        permissions: permissions,
        screens: screens,
        isLiveEnabled: isLiveEnabled,
      );

      if (success) {
        final index = _myMentors.indexWhere((m) => m.id == connectionId);
        if (index != -1) {
          _myMentors[index] = _myMentors[index].copyWith(
            permissions: permissions ?? _myMentors[index].permissions,
            allowedScreens: screens != null
                ? AllowedScreens(screens: screens)
                : _myMentors[index].allowedScreens,
            isLiveEnabled: isLiveEnabled ?? _myMentors[index].isLiveEnabled,
          );
        }
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to update permissions', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Extend access duration
  Future<bool> extendAccess(
    String connectionId,
    AccessDuration newDuration,
  ) async {
    try {
      _setLoading(true);

      final success = await _repository.extendDuration(
        connectionId,
        newDuration,
      );

      if (success) {
        final index = _myMentors.indexWhere((m) => m.id == connectionId);
        if (index != -1) {
          _myMentors[index] = _myMentors[index].copyWith(
            duration: newDuration,
            accessStatus: AccessStatus.active,
            expiresAt: newDuration.calculateExpiresAt(),
          );
        }
        notifyListeners();
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to extend access', error: e, stackTrace: stack);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // VIEWING ACTIONS
  // ================================================================

  /// Log screen view (when viewing mentee's data)
  Future<bool> logScreenView(String connectionId, {String? screen}) async {
    try {
      final success = await _repository.logView(connectionId, screen: screen);

      if (success) {
        final index = _myMentees.indexWhere((m) => m.id == connectionId);
        if (index != -1) {
          _myMentees[index] = _myMentees[index].copyWith(
            viewCount: _myMentees[index].viewCount + 1,
            lastViewedAt: DateTime.now(),
            lastViewedScreen: screen,
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to log view', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update cached snapshot
  Future<bool> updateSnapshot(
    String connectionId,
    Map<String, dynamic> snapshot,
  ) async {
    try {
      final success = await _repository.updateSnapshot(connectionId, snapshot);

      if (success) {
        final index = _myMentees.indexWhere((m) => m.id == connectionId);
        if (index != -1) {
          _myMentees[index] = _myMentees[index].copyWith(
            cachedSnapshot: snapshot,
            snapshotCapturedAt: DateTime.now(),
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to update snapshot', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Send encouragement to mentee
  Future<bool> sendEncouragement(
    String connectionId, {
    String type = 'emoji',
    String? message,
  }) async {
    try {
      final success = await _repository.sendEncouragement(
        connectionId,
        type: type,
        message: message,
      );

      if (success) {
        final index = _myMentees.indexWhere((m) => m.id == connectionId);
        if (index != -1) {
          _myMentees[index] = _myMentees[index].copyWith(
            lastEncouragementAt: DateTime.now(),
            lastEncouragementType: type,
            lastEncouragementMessage: message,
            encouragementCount: _myMentees[index].encouragementCount + 1,
          );
          // Notifications are now handled by the backend/modular architecture
          notifyListeners();
        }
      }

      return success;
    } catch (e, stack) {
      logE('❌ Failed to send encouragement', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // PERMISSION CHECKS
  // ================================================================

  /// Check if I can view a specific user's data
  bool canIViewUser(String userId) {
    return _myMentees.any((m) => m.ownerId == userId && m.canAccess);
  }

  /// Check if a user can view my data
  bool canUserViewMe(String userId) {
    return _myMentors.any((m) => m.mentorId == userId && m.canAccess);
  }

  /// Get my access to a specific user
  MentorshipConnection? getMyAccessTo(String userId) {
    try {
      return _myMentees.firstWhere((m) => m.ownerId == userId && m.canAccess);
    } catch (_) {
      return null;
    }
  }

  /// Get a user's access to me
  MentorshipConnection? getUserAccessToMe(String userId) {
    try {
      return _myMentors.firstWhere((m) => m.mentorId == userId && m.canAccess);
    } catch (_) {
      return null;
    }
  }

  /// Check if I can view a specific screen of a user
  bool canViewScreen(String userId, AccessibleScreen screen) {
    final access = getMyAccessTo(userId);
    if (access == null) return false;
    return access.canViewScreen(screen);
  }

  /// Check if I can view a specific screen by name
  bool canViewScreenByName(String userId, String screenName) {
    final access = getMyAccessTo(userId);
    if (access == null) return false;
    return access.canViewScreenByName(screenName);
  }

  // ================================================================
  // SELECTION
  // ================================================================

  void selectConnection(MentorshipConnection connection) {
    _selectedConnection = connection;
    notifyListeners();
  }

  void clearSelectedConnection() {
    _selectedConnection = null;
    notifyListeners();
  }

  Future<MentorshipConnection?> getConnectionById(String connectionId) async {
    // First check local cache
    final local = [
      ..._myMentors,
      ..._myMentees,
      ..._allIncomingRequests,
      ..._allOutgoingRequests,
    ].where((c) => c.id == connectionId).firstOrNull;

    if (local != null) return local;

    // Fetch from repository
    return await _repository.getById(connectionId);
  }

  // ================================================================
  // UTILITY METHODS
  // ================================================================

  /// Get mentees filtered by relationship type
  List<MentorshipConnection> getMenteesByRelationship(RelationshipType type) {
    return _myMentees.where((m) => m.relationshipType == type).toList();
  }

  /// Get mentors filtered by relationship type
  List<MentorshipConnection> getMentorsByRelationship(RelationshipType type) {
    return _myMentors.where((m) => m.relationshipType == type).toList();
  }

  /// Get mentees that need attention (inactive)
  List<MentorshipConnection> getMenteesNeedingAttention() {
    return _myMentees.where((m) {
      if (!m.canAccess) return false;
      if (m.lastViewedAt == null) return true;
      final daysSinceView = DateTime.now().difference(m.lastViewedAt!).inDays;
      return daysSinceView >= m.inactiveThresholdDays;
    }).toList();
  }

  /// Get mentees expiring soon (within 7 days)
  List<MentorshipConnection> getMenteesExpiringSoon() {
    return _myMentees.where((m) {
      if (!m.hasExpiration) return false;
      final remaining = m.remainingTime;
      if (remaining == null) return false;
      return remaining.inDays <= 7 && remaining.inDays > 0;
    }).toList();
  }

  /// Get mentors expiring soon (within 7 days)
  List<MentorshipConnection> getMentorsExpiringSoon() {
    return _myMentors.where((m) {
      if (!m.hasExpiration) return false;
      final remaining = m.remainingTime;
      if (remaining == null) return false;
      return remaining.inDays <= 7 && remaining.inDays > 0;
    }).toList();
  }

  // ================================================================
  // STATE HELPERS
  // ================================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clear() {
    _stopWatching();
    _myMentors.clear();
    _myMentees.clear();
    _allIncomingRequests.clear();
    _allOutgoingRequests.clear();
    _pendingOffers.clear();
    _stats.clear();
    _selectedConnection = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }
}

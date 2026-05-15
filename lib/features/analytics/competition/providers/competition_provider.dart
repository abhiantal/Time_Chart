// ================================================================
// FILE: lib/features/personal/battle/providers/battle_challenge_provider.dart
// ================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../Authentication/auth_provider.dart';
import '../../../../widgets/logger.dart';
import '../models/competition_model.dart';
import '../repositories/competitions_repository.dart';


/// View model for a competitor with their profile and latest stats.
class CompetitorWithProfile {
  final BattleMemberProfile competitor;
  final BattleMemberStats? score;
  final String displayName;
  final String? profileUrl;

  CompetitorWithProfile({
    required this.competitor,
    this.score,
    required this.displayName,
    this.profileUrl,
  });
}

// Debounce: collapses rapid state changes into one rebuild per frame
const Duration _kDebounce = Duration(milliseconds: 16);

// ================================================================
// PROVIDER
// ================================================================

class BattleChallengeProvider extends ChangeNotifier {
  BattleChallengeProvider({BattleChallengeRepository? repository})
    : _repo = repository ?? BattleChallengeRepository();

  final BattleChallengeRepository _repo;


  // ── Internal state ────────────────────────────────────────────
  List<BattleChallenge> _battles = [];
  BattleChallenge? _selected; // battle open in detail screen
  bool _loading = false; // initial list load spinner
  bool _busy = false; // write op in flight
  bool _initialised = false;
  String _userId = '';
  String? _error;
  bool _disposed = false;

  // ── Subscriptions & Timers ────────────────────────────────────
  StreamSubscription<List<BattleChallenge>>? _listSub;
  StreamSubscription<BattleChallenge?>? _detailSub;
  Timer? _debounce;

  // ================================================================
  // PUBLIC READ-ONLY STATE
  // ================================================================

  /// All battles for the user (creator + any member), newest first.
  List<BattleChallenge> get battles => _battles;

  /// Only active battles.
  List<BattleChallenge> get activeBattles =>
      _battles.where((b) => b.isActive).toList();

  /// Only completed battles.
  List<BattleChallenge> get completedBattles =>
      _battles.where((b) => b.status == BattleStatus.completed).toList();

  /// The battle currently shown in the detail screen. Null if none.
  BattleChallenge? get selectedBattle => _selected;

  /// True while the initial battle list is loading.
  /// Use to show a full-screen spinner before any data is available.
  bool get isLoading => _loading;

  /// True while any write operation (create / add / remove / delete) is running.
  /// Use to disable action buttons while a request is in flight.
  bool get isBusy => _busy;

  /// Compatibility getter for isInitialized (with 'z')
  bool get isInitialized => _initialised;

  /// Compatibility getter for isRefreshing
  bool get isRefreshing => _busy;

  /// Remaining slots for adding competitors (max 5)
  int get remainingSlots => (5 - competitorCount).clamp(0, 5);

  /// True if currently adding a competitor
  bool get isAddingCompetitor => _busy;

  /// Error message if last operation failed
  String? get error => _error;

  /// Total number of unique competitors the current user is battling with.
  int get competitorCount {
    if (_userId.isEmpty) return 0;
    final competitors = <String>{};
    for (final battle in _battles) {
      if (battle.isActive) {
        if (battle.userId != _userId) competitors.add(battle.userId);
        if (battle.member1Id != null && battle.member1Id != _userId) {
          competitors.add(battle.member1Id!);
        }
        if (battle.member2Id != null && battle.member2Id != _userId) {
          competitors.add(battle.member2Id!);
        }
        if (battle.member3Id != null && battle.member3Id != _userId) {
          competitors.add(battle.member3Id!);
        }
        if (battle.member4Id != null && battle.member4Id != _userId) {
          competitors.add(battle.member4Id!);
        }
        if (battle.member5Id != null && battle.member5Id != _userId) {
          competitors.add(battle.member5Id!);
        }
      }
    }
    return competitors.length;
  }

  /// Total number of unique users who have added the current user to their battles.
  /// Matches the logic in CompetitionsListScreen (Followers).
  int get battlingMeCount {
    if (_userId.isEmpty) return 0;
    final owners = <String>{};
    for (final battle in _battles) {
      if (battle.isActive &&
          battle.userId != _userId &&
          battle.isParticipant(_userId)) {
        owners.add(battle.userId);
      }
    }
    return owners.length;
  }

  /// Stats for the current user as the "owner" (creator) of their primary battle.
  BattleMemberStats? get ownerScore => userStats;

  /// Display name for the current user.
  String get ownerDisplayName => userStats?.username ?? 'You';

  /// Avatar URL for the current user.
  String get ownerAvatarUrl => userStats?.profileUrl ?? '';

  /// Check if the target user is a member of the current user's active battle.
  bool isCompetingWith(String targetUserId) {
    if (_userId.isEmpty || targetUserId.isEmpty) return false;
    // We only count it as "Competing" if WE added THEM to our battle.
    // This ensures the "Add/Remove" button logic on their profile is consistent with our RPC.
    return _battles.any(
      (b) =>
          b.isActive &&
          b.userId == _userId &&
          (b.member1Id == targetUserId ||
              b.member2Id == targetUserId ||
              b.member3Id == targetUserId ||
              b.member4Id == targetUserId ||
              b.member5Id == targetUserId),
    );
  }

  /// Search for users to add as competitors.
  Future<List<UserSearchResult>> searchUsers(String query, {int limit = 20}) async {
    return _repo.searchUsers(query, limit: limit);
  }

  /// Toggle competition with the target user (add or remove).
  Future<bool> addCompetitor(String targetUserId) async {
    return _toggleCompetitor(targetUserId);
  }

  /// Toggle competition with the target user (add or remove).
  Future<bool> removeCompetitor(String targetUserId) async {
    return _toggleCompetitor(targetUserId);
  }

  /// Internal helper to toggle competitor using the new RPC.
  Future<bool> _toggleCompetitor(String targetUserId) async {
    if (_userId.isEmpty || targetUserId.isEmpty) return false;
    _setBusy(true);
    _clearError();

    try {
      final result = await _repo.toggleCompetitor(targetUserId);

      if (result.success) {
        logI('✅ [Battle Provider] competitor toggled: ${result.action}');
        if (result.battleId != null) {
          await refreshBattle(result.battleId!);
        }
        return true;
      }

      _setError(result.error ?? 'Failed to toggle competitor');
      return false;
    } catch (e, s) {
      logE(
        '❌ [Battle Provider] toggleCompetitor error',
        error: e,
        stackTrace: s,
      );
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  /// Stats for the current user in their primary active battle (if any).
  BattleMemberStats? get userStats {
    if (_userId.isEmpty) return null;
    // Look for the first active battle where the user has stats
    for (final battle in _battles) {
      if (battle.isActive) {
        final stats = battle.statsForUser(_userId);
        if (stats != null) return stats;
      }
    }
    return null;
  }

  /// All competitors from all active battles, with their profile and latest score.
  List<CompetitorWithProfile> get competitorsWithProfiles {
    if (_userId.isEmpty) return [];
    final Map<String, CompetitorWithProfile> map = {};

    for (final battle in _battles) {
      if (!battle.isActive) continue;

      final allStats = battle.allMemberStats;
      for (final stats in allStats) {
        final uid = stats.profile.id;
        if (uid == _userId) continue;

        // If we haven't seen this competitor yet, or this battle is newer
        if (!map.containsKey(uid)) {
          map[uid] = CompetitorWithProfile(
            competitor: stats.profile,
            score: stats,
            displayName: stats.displayName,
            profileUrl: stats.profile.profileUrl,
          );
        }
      }
    }
    return map.values.toList();
  }

  /// True if there is at least one active challenge.
  bool get hasChallenge => activeBattles.isNotEmpty;

  /// Time of last successful list refresh.
  DateTime? get lastRefreshed =>
      _battles.isNotEmpty ? _battles.first.updatedAt : null;

  /// Refresh all battle data.
  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    await initialize(_userId);
  }

  // ================================================================
  // SELECTED BATTLE CONVENIENCE GETTERS
  // All null-safe: return sensible defaults when nothing is selected.
  // ================================================================

  /// Ranked leaderboard entries for the selected battle.
  /// Sorted by competition_rank ASC (rank 1 = highest total_points).
  List<BattleLeaderboardEntry> get leaderboard => _selected != null
      ? BattleLeaderboardEntry.fromBattle(_selected!)
      : const [];

  /// How many member slots are still empty in the selected battle.
  int get availableSlots => _selected?.availableSlots ?? 0;

  /// True if the current user created the selected battle.
  bool get isOwnerOfSelected => _selected?.isOwner(_userId) ?? false;

  /// True if the selected battle has no empty member slots.
  bool get selectedIsFull => _selected?.isFull ?? false;

  /// Stats snapshot for the current user in the selected battle.
  /// Null if the user is not a participant.
  BattleMemberStats? get myStatsInSelected => _selected?.statsForUser(_userId);

  // ================================================================
  // INITIALIZATION
  // ================================================================

  /// Called by [AppSetup] update to keep userId in sync.
  void updateAuth(AuthProvider auth) {
    final newId = auth.currentUser?.id ?? '';
    if (newId.isNotEmpty && newId != _userId) {
      logI('🔄 [Battle Provider] Auth update: $newId');
      initialize(newId);
    }
  }

  /// Initial load of battles for the user.
  Future<void> initialize(String userId) async {
    if (userId.isEmpty) {
      logE('❌ [Battle Provider] initialize: userId is empty');
      return;
    }

    // Already watching this user — nothing to do
    if (_initialised && _userId == userId) {
      logI('ℹ️ [Battle Provider] already initialised for $userId');
      return;
    }

    _userId = userId;
    _clearError();

    // Show spinner only if we have no data yet
    if (_battles.isEmpty) _setLoading(true);

    try {
      // Step 1: load from local cache immediately (no network)
      final cached = await _repo.getBattlesForUser(userId);
      if (cached.isNotEmpty) {
        _battles = cached;
        _setLoading(false);
        _notify();
        logI('✅ [Battle Provider] ${cached.length} battles from local cache');
      }

      _initialised = true;
    } catch (e, s) {
      logE('❌ [Battle Provider] initialize error', error: e, stackTrace: s);
      _setError('Failed to load battles');
    } finally {
      if (_loading) _setLoading(false);
    }

    // Step 2: subscribe to real-time updates
    _startListStream(userId);
  }

  // ================================================================
  // LOAD BATTLE — for detail screen
  // Loads one specific battle. Refreshes from server if stale.
  // Starts a detail stream for real-time updates.
  // ================================================================

  Future<void> loadBattle(String battleId) async {
    if (battleId.isEmpty) return;
    _clearError();

    try {
      logI('🔍 [Battle Provider] loading battle $battleId');

      final stale = await _repo.needsRefresh(battleId);
      final battle = await _repo.getBattleById(battleId, forceServer: stale);

      if (battle != null) {
        _selected = battle;
        _updateBattleInList(battle);
        _notify();
        logI('✅ [Battle Provider] battle loaded: $battleId');
      } else {
        _setError('Battle not found');
      }
    } catch (e, s) {
      logE('❌ [Battle Provider] loadBattle error', error: e, stackTrace: s);
      _setError('Failed to load battle');
    }

    // Start streaming real-time updates for this battle
    _startDetailStream(battleId);
  }

  // ================================================================
  // REFRESH BATTLE — force-refresh from server
  // Call on pull-to-refresh in the detail screen.
  // ================================================================

  Future<void> refreshBattle(String battleId) async {
    if (battleId.isEmpty) return;
    _clearError();

    try {
      logI('🔄 [Battle Provider] refreshing battle $battleId');
      final fresh = await _repo.getBattleById(battleId, forceServer: true);

      if (fresh != null) {
        _selected = fresh;
        _updateBattleInList(fresh);
        _notify();
        logI('✅ [Battle Provider] battle refreshed: $battleId');
      }
    } catch (e, s) {
      logE('❌ [Battle Provider] refreshBattle error', error: e, stackTrace: s);
    }
  }

  // ================================================================
  // CREATE BATTLE
  // Returns the created battle on success, null on failure.
  // ================================================================

  Future<BattleChallenge?> createBattle({
    required String title,
    String? description,
    DateTime? endsAt,
  }) async {
    if (title.trim().isEmpty) {
      _setError('Title cannot be empty');
      return null;
    }
    _setBusy(true);
    _clearError();

    try {
      logI('📝 [Battle Provider] creating: $title');

      final battle = await _repo.createBattle(
        title: title.trim(),
        description: description?.trim(),
        endsAt: endsAt,
      );

      if (battle != null) {
        _addBattleToList(battle);
        _notify();
        logI('✅ [Battle Provider] battle created: ${battle.id}');
        return battle;
      }

      _setError('Failed to create battle');
      return null;
    } catch (e, s) {
      logE('❌ [Battle Provider] createBattle error', error: e, stackTrace: s);
      _setError('Failed to create battle');
      return null;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // ADD MEMBER
  // Only the creator of the selected battle can call this.
  // Returns null on success, or an error message string on failure.
  // ================================================================

  Future<String?> addMember({
    required String battleId,
    required String memberUserId,
  }) async {
    _setBusy(true);
    _clearError();

    try {
      logI('➕ [Battle Provider] adding $memberUserId to $battleId');

      final result = await _repo.addMember(
        battleId: battleId,
        memberUserId: memberUserId,
      );

      if (result.success) {
        // Refresh to get the new member's full stats snapshot
        await refreshBattle(battleId);
        logI('✅ [Battle Provider] member added');
        return null; // null = success
      }

      final msg = result.error ?? 'Failed to add member';
      _setError(msg);
      return msg;
    } catch (e, s) {
      logE('❌ [Battle Provider] addMember error', error: e, stackTrace: s);
      const msg = 'Failed to add member';
      _setError(msg);
      return msg;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // REMOVE MEMBER
  // Only the creator can call this.
  // Returns null on success, or an error message string on failure.
  // ================================================================

  Future<String?> removeMember({
    required String battleId,
    required String memberUserId,
  }) async {
    _setBusy(true);
    _clearError();

    try {
      logI('➖ [Battle Provider] removing $memberUserId from $battleId');

      final result = await _repo.removeMember(
        battleId: battleId,
        memberUserId: memberUserId,
      );

      if (result.success) {
        await refreshBattle(battleId);
        logI('✅ [Battle Provider] member removed');
        return null;
      }

      final msg = result.error ?? 'Failed to remove member';
      _setError(msg);
      return msg;
    } catch (e, s) {
      logE('❌ [Battle Provider] removeMember error', error: e, stackTrace: s);
      const msg = 'Failed to remove member';
      _setError(msg);
      return msg;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // UPDATE STATUS — complete or cancel a battle
  // ================================================================

  Future<bool> updateStatus(String battleId, BattleStatus status) async {
    _setBusy(true);
    _clearError();

    try {
      logI('🔄 [Battle Provider] setting ${status.value} on $battleId');

      final ok = await _repo.updateStatus(battleId, status);
      if (ok) {
        // Update local state immediately without waiting for stream
        if (_selected?.id == battleId) {
          _selected = _selected!.copyWith(status: status);
        }
        _battles = _battles
            .map((b) => b.id == battleId ? b.copyWith(status: status) : b)
            .toList();
        _notify();
      } else {
        _setError('Failed to update status');
      }
      return ok;
    } catch (e, s) {
      logE('❌ [Battle Provider] updateStatus error', error: e, stackTrace: s);
      _setError('Failed to update status');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // UPDATE METADATA — title / description / ends_at
  // ================================================================

  Future<bool> updateBattleMetadata(
    String battleId, {
    String? title,
    String? description,
    DateTime? endsAt,
  }) async {
    _setBusy(true);
    _clearError();

    try {
      final ok = await _repo.updateBattleMetadata(
        battleId,
        title: title,
        description: description,
        endsAt: endsAt,
      );

      if (ok && _selected?.id == battleId) {
        // Optimistically update the selected battle
        _selected = BattleChallenge(
          id: battleId,
          userId: _selected!.userId,
          title: title ?? _selected!.title,
          description: description ?? _selected!.description,
          status: _selected!.status,
          startsAt: _selected!.startsAt,
          endsAt: endsAt ?? _selected!.endsAt,
          member1Id: _selected!.member1Id,
          member2Id: _selected!.member2Id,
          member3Id: _selected!.member3Id,
          member4Id: _selected!.member4Id,
          member5Id: _selected!.member5Id,
          userStats: _selected!.userStats,
          member1Stats: _selected!.member1Stats,
          member2Stats: _selected!.member2Stats,
          member3Stats: _selected!.member3Stats,
          member4Stats: _selected!.member4Stats,
          member5Stats: _selected!.member5Stats,
          createdAt: _selected!.createdAt,
          updatedAt: DateTime.now(),
        );
        _updateBattleInList(_selected!);
        _notify();
        logI('✅ [Battle Provider] metadata updated for $battleId');
      }
      return ok;
    } catch (e, s) {
      logE(
        '❌ [Battle Provider] updateBattleMetadata error',
        error: e,
        stackTrace: s,
      );
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // DELETE BATTLE
  // ================================================================

  Future<bool> deleteBattle(String battleId) async {
    _setBusy(true);
    _clearError();

    try {
      logI('🗑 [Battle Provider] deleting $battleId');

      final ok = await _repo.deleteBattle(battleId);
      if (ok) {
        _battles = _battles.where((b) => b.id != battleId).toList();
        if (_selected?.id == battleId) {
          _selected = null;
          _detailSub?.cancel();
          _detailSub = null;
        }
        _notify();
        logI('✅ [Battle Provider] battle deleted');
      }
      return ok;
    } catch (e, s) {
      logE('❌ [Battle Provider] deleteBattle error', error: e, stackTrace: s);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ================================================================
  // CLEAR SELECTED — call when leaving the detail screen
  // ================================================================

  void clearSelectedBattle() {
    _selected = null;
    _detailSub?.cancel();
    _detailSub = null;
    _clearError();
    _notify();
  }

  // ================================================================
  // EXPOSE STREAMS — for widgets that use StreamBuilder directly
  // ================================================================

  /// Real-time stream of one specific battle.
  Stream<BattleChallenge?> watchBattle(String battleId) =>
      _repo.watchBattle(battleId);

  /// Real-time stream of all battles for a user.
  Stream<List<BattleChallenge>> watchBattles(String userId) =>
      _repo.watchBattlesForUser(userId);

  // ================================================================
  // INTERNAL: STREAM SUBSCRIPTIONS
  // ================================================================

  void _startListStream(String userId) {
    _listSub?.cancel();
    _listSub = _repo.watchBattlesForUser(userId).listen(
      (incoming) {
        // Accept if we have no data, or if incoming has content
        if (_battles.isEmpty || incoming.isNotEmpty) {
          _battles = incoming;

          // Keep selectedBattle in sync if it appears in the list
          if (_selected != null) {
            final match = incoming.where((b) => b.id == _selected!.id).toList();
            if (match.isNotEmpty) {
              _selected = match.first;
            }
          }
          // Notifications are now handled by the backend/modular architecture
          _notify();
          logI('📡 [Battle Provider] list stream: ${incoming.length} battles');
        }
      },
      onError: (Object e) =>
          logE('❌ [Battle Provider] list stream error', error: e),
    );
  }

  void _startDetailStream(String battleId) {
    _detailSub?.cancel();
    _detailSub = _repo.watchBattle(battleId).listen(
      (incoming) {
        if (incoming == null) return;

        // Staleness guard removed to ensure live updates from performance_analytics triggers propagate instantly
        _selected = incoming;
        _updateBattleInList(incoming);
        _notify();
        logI('📡 [Battle Provider] detail stream update: $battleId');
      },
      onError: (Object e) =>
          logE('❌ [Battle Provider] detail stream error', error: e),
    );
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  /// Add a battle at the top of the list (newest first).
  void _addBattleToList(BattleChallenge battle) {
    _battles = [battle, ..._battles.where((b) => b.id != battle.id)];
  }

  /// Replace an existing battle in the list, or add it if not found.
  void _updateBattleInList(BattleChallenge battle) {
    final idx = _battles.indexWhere((b) => b.id == battle.id);
    if (idx >= 0) {
      final updated = List<BattleChallenge>.from(_battles);
      updated[idx] = battle;
      _battles = updated;
    } else {
      _addBattleToList(battle);
    }
  }

  void _setLoading(bool v) {
    if (_loading == v) return;
    _loading = v;
    _notify();
  }

  void _setBusy(bool v) {
    if (_busy == v) return;
    _busy = v;
    _notify();
  }

  void _setError(String msg) {
    _error = msg;
    _notify();
  }

  void _clearError() {
    _error = null;
  }

  void _notify() {
    _debounce?.cancel();
    _debounce = Timer(_kDebounce, () {
      if (!_disposed) notifyListeners();
    });
  }

  // ================================================================
  // RESET — call on logout
  // ================================================================

  void reset() {
    logI('🔁 [Battle Provider] resetting');
    _listSub?.cancel();
    _detailSub?.cancel();
    _debounce?.cancel();
    _listSub = null;
    _detailSub = null;
    _debounce = null;
    _battles = [];
    _selected = null;
    _loading = false;
    _busy = false;
    _initialised = false;
    _error = null;
    _userId = '';
    if (!_disposed) notifyListeners();
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    logI('🗑 [Battle Provider] disposing');
    _disposed = true;
    _listSub?.cancel();
    _detailSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

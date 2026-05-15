// ================================================================
// FILE: lib/features/analytics/leaderboard/providers/leaderboard_provider.dart
//
// ChangeNotifier provider for the unified global leaderboard.
// Sorted by totalPoints descending (only one ranking mode).
//
// LIFECYCLE:
//   initialize() → Subscribe to Supabase Stream → build ranked list
//   auto-updates live via Supabase Realtime
//   reset() on logout
//   dispose() cleans up subscriptions
//
// EXPOSES:
//   leaderboard          → full sorted list of LeaderboardEntry
//   currentUserRank      → 1-indexed rank of the logged-in user (0 if absent)
//   currentUserEntry     → LeaderboardEntry for the logged-in user
//   podium               → top 3 entries
//   restOfLeaderboard    → entries from rank 4 onward
//   totalParticipants    → count of all users in the leaderboard
//   isLoading / error    → UI state flags
// ================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../widgets/logger.dart';
import '../models/user_stats_model.dart';
import '../repositories/user_stats_repository.dart';


// ── Constants ────────────────────────────────────────────────────
const Duration _kDebounce = Duration(milliseconds: 16);

// ================================================================
// PROVIDER
// ================================================================

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({LeaderboardRepository? repository})
      : _repo = repository ?? LeaderboardRepository();

  final LeaderboardRepository _repo;


  // ── State ─────────────────────────────────────────────────────
  List<LeaderboardEntry> _leaderboard  = [];
  bool   _loading      = false;
  bool   _initialised  = false;
  String? _error;
  DateTime? _lastFetched;
  bool   _disposed     = false;


  // ── Subscriptions ─────────────────────────────────────────────
  StreamSubscription<List<LeaderboardEntry>>? _streamSub;
  Timer? _debounceTimer;

  // ================================================================
  // PUBLIC GETTERS
  // ================================================================

  /// Full leaderboard sorted by totalPoints descending.
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  bool  get isLoading    => _loading;
  bool  get isInitialised => _initialised;
  String? get error      => _error;
  DateTime? get lastFetched => _lastFetched;
  bool  get hasData      => _leaderboard.isNotEmpty;

  /// Total number of users in the leaderboard.
  int get totalParticipants => _leaderboard.length;

  /// The authenticated user's ID.
  String get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  /// The current user's 1-indexed rank (0 if not found in the list).
  int get currentUserRank {
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i].userId == currentUserId) return i + 1;
    }
    return 0;
  }

  /// The current user's entry, or null if not in the list.
  LeaderboardEntry? get currentUserEntry {
    try {
      return _leaderboard.firstWhere((e) => e.userId == currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// Top 3 entries for the podium display.
  List<LeaderboardEntry> get podium => _leaderboard.take(3).toList();

  /// Entries ranked 4th and below.
  List<LeaderboardEntry> get restOfLeaderboard =>
      _leaderboard.length > 3 ? _leaderboard.sublist(3) : [];

  // ── Convenience: is a given entry the current user? ───────────
  bool isCurrentUser(LeaderboardEntry entry) =>
      entry.userId == currentUserId;

  // ================================================================
  // INITIALISE
  // ================================================================

  Future<void> initialize() async {
    if (_initialised) return;

    _setLoading(true);
    _startStream();
    _initialised = true;
  }

  // ================================================================
  // REFRESH (manual trigger)
  // ================================================================

  Future<void> refresh() async {
    _setLoading(true);
    try {
      final entries = await _repo.getLeaderboard();
      _leaderboard = entries;
      _lastFetched = DateTime.now();
      _notifyDebounced();
    } catch (e) {
      logE('[LeaderboardProvider] Refresh error', error: e);
      _error = 'Refresh failed';
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // PRIVATE: STREAM
  // ================================================================

  void _startStream() {
    _streamSub?.cancel();
    _streamSub = _repo.watchLeaderboard().listen(
      (entries) {
        if (_disposed) return;
        _leaderboard = entries;
        _lastFetched = DateTime.now();
        _error = null;
        _setLoading(false);

        // Notifications are now handled by the backend/modular architecture

        _notifyDebounced();
        logI('[LeaderboardProvider] Received live update: ${entries.length} entries');
      },
      onError: (e) {
        logE('[LeaderboardProvider] Stream error', error: e);
        if (_leaderboard.isEmpty) {
          _error = 'Failed to load live leaderboard';
          _setLoading(false);
          _notifyDebounced();
        }
      },
    );
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    _notifyDebounced();
  }

  void _notifyDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kDebounce, () {
      if (!_disposed) notifyListeners();
    });
  }

  // ================================================================
  // RESET — call on user logout
  // ================================================================

  void reset() {
    logI('[LeaderboardProvider] resetting');
    _streamSub?.cancel();
    _debounceTimer?.cancel();
    _streamSub     = null;
    _debounceTimer = null;
    _leaderboard   = [];
    _loading       = false;
    _initialised   = false;
    _error         = null;
    _lastFetched   = null;

    if (!_disposed) notifyListeners();
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    logI('[LeaderboardProvider] disposing');
    _disposed = true;
    _streamSub?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
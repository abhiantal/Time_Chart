// ================================================================
// FILE: lib/features/personal/dashboard/providers/user_dashboard_provider.dart
//
// ChangeNotifier provider that manages the full dashboard lifecycle:
//   • local-first init (PowerSync) → server RPC if stale/missing
//   • real-time PowerSync stream with staleness guard
//   • auto-refresh every 5 minutes via a periodic timer
//   • 16 ms debounce on notifyListeners (one frame, avoids tree spam)
//   • typed section getters for every dashboard column
//   • convenience metrics map consumed by widgets
//   • reset() on logout, dispose() on widget tree removal
//
// DEPENDS ON:
//   dashboard_model.dart         → UserDashboard + all section classes
//   user_dashboard_repository.dart → data layer (PowerSync + Supabase)
//   logger.dart                  → logI / logW / logE helpers
// ================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../widgets/logger.dart';
import '../models/dashboard_model.dart';
import '../repositories/user_dashboard_repository.dart';


// ── Auto-refresh interval ────────────────────────────────────────
// Dashboard data is refreshed from the server every 5 minutes
// even when the stream has not emitted a new event.
const Duration _kRefreshInterval = Duration(minutes: 5);

// ── Debounce window for notifyListeners ──────────────────────────
// All state mutations go through _notifyDebounced() which collapses
// multiple rapid writes (e.g. stream + timer firing together) into
// a single rebuild at the next frame boundary (≈16 ms).
const Duration _kDebounce = Duration(milliseconds: 16);

// ================================================================
// PROVIDER
// ================================================================

class UserDashboardProvider extends ChangeNotifier {
  // ── Constructor ───────────────────────────────────────────────
  // Accepts an optional repository for testing/injection.
  // In production, no argument is needed — the singleton instance
  // of UserDashboardRepository is used automatically.
  UserDashboardProvider({UserDashboardRepository? repository})
    : _repo = repository ?? UserDashboardRepository();

  final UserDashboardRepository _repo;


  // ── Internal State ────────────────────────────────────────────
  UserDashboard? _dashboard; // null = not yet loaded
  bool _loading = false;
  bool _initialised = false;
  String? _error;
  String _userId = '';
  bool _newRewardEarned = false; // Added
  bool _disposed = false;

  // ── Subscriptions & Timers ────────────────────────────────────
  StreamSubscription<UserDashboard?>? _streamSub;
  StreamSubscription<List<Map<String, dynamic>>>? _dbChangesSub;
  Timer? _refreshTimer;
  Timer? _debounceTimer;

  // ================================================================
  // PUBLIC READ-ONLY STATE
  // ================================================================

  /// The fully-parsed dashboard. Null until the first load completes.
  UserDashboard? get userDashboard => _dashboard;

  /// True while the initial load (or a forced refresh) is in flight
  /// AND no cached data is available yet.
  bool get isLoading => _loading;

  /// True once initialize() has completed its first full cycle.
  bool get isInitialised => _initialised;

  /// Non-null when the last operation failed.
  String? get error => _error;

  /// The user ID this provider is currently watching.
  String get userId => _userId;

  /// Shorthand: whether we have any dashboard data at all.
  bool get hasData => _dashboard != null;

  /// True when a reward has just been earned. UI should clear this after showing celebration.
  bool get newRewardEarned => _newRewardEarned;

  void clearNewReward() {
    _newRewardEarned = false;
    _notifyDebounced();
  }

  // ================================================================
  // TYPED SECTION GETTERS
  // Each getter returns an empty/default object when dashboard is
  // not yet loaded, so widgets never receive null.
  // ================================================================

  // --- DB column: overview ---
  // Contains summary + 4 per-task-type stat blocks
  DashboardOverview get overview =>
      _dashboard?.overview ?? DashboardOverview.empty();

  // --- DB column: today ---
  // Contains day_tasks + week_tasks + long_goals + diary + buckets for today
  TodaySummary get today => _dashboard?.today ?? TodaySummary.empty();

  // --- DB column: active_items ---
  // Only inProgress items across all 4 task types
  ActiveItems get activeItems => _dashboard?.activeItems ?? ActiveItems.empty();

  // --- DB column: progress_history ---
  // 30-day daily_stats consolidated array + trend/best/worst day
  ProgressHistory get progressHistory =>
      _dashboard?.progressHistory ?? ProgressHistory.empty();

  // --- DB column: weekly_history ---
  // 12-week weekly_stats consolidated array + best/worst week
  WeeklyHistory get weeklyHistory =>
      _dashboard?.weeklyHistory ?? WeeklyHistory.empty();

  // --- DB column: category_stats ---
  // Points + completion per category_type (day + weekly tasks combined)
  CategoryStats get categoryStats =>
      _dashboard?.categoryStats ?? CategoryStats.empty();

  // --- DB column: rewards ---
  // summary + earned_rewards_no (all-time counts) + unlocked_rewards list
  Rewards get rewards => _dashboard?.rewards ?? Rewards.empty();

  // --- DB column: streaks ---
  // current / longest / next_milestone / risk / history / stats
  Streaks get streaks => _dashboard?.streaks ?? Streaks.empty();

  // --- DB column: mood ---
  // Sourced from diary_entries.mood, 1–10 scale
  Mood get mood => _dashboard?.mood ?? Mood.empty();

  // --- DB column: recent_activity ---
  // Last 15 days of activity across all 5 source tables
  List<RecentActivityItem> get recentActivity =>
      _dashboard?.recentActivity ?? const [];

  // ================================================================
  // CONVENIENCE METRICS MAP
  // Consumed by widgets that need a quick flat snapshot without
  // navigating nested objects.
  // Key names are snake_case to match DB column naming convention.
  // ================================================================

  Map<String, dynamic> get dashboardMetrics => {
    // overview.summary fields
    'total_points': overview.summary.totalPoints,
    'points_today': overview.summary.pointsToday,
    'points_this_week': overview.summary.pointsThisWeek,
    'current_streak': overview.summary.currentStreak,
    'longest_streak': overview.summary.longestStreak,
    'global_rank': overview.summary.globalRank,
    'rank_label': overview.summary.rankLabel,
    'completion_today': overview.summary.completionRateToday,
    'completion_week': overview.summary.completionRateWeek,
    'completion_all': overview.summary.completionRateAll,
    'average_rating': overview.summary.averageRating,
    'best_tier': overview.summary.bestTierAchieved,
    'best_tier_emoji': overview.summary.bestTierEmoji,
    'total_rewards': overview.summary.totalRewards,

    // streaks — from Streaks.current and Streaks.nextMilestone
    'streak_is_active': streaks.isActive,
    'streak_at_risk': streaks.isAtRisk,
    'streak_emoji': streaks.streakEmoji,
    'next_milestone_target': streaks.nextMilestone.target,
    'next_milestone_pct': streaks.nextMilestone.progressPercent,

    // mood — from Mood.averageMoodLast7Days
    'mood_avg_7d': mood.averageMoodLast7Days,
    'mood_avg_30d': mood.averageMoodLast30Days,
    'mood_trend': mood.trend,
    'most_common_mood': mood.mostCommonMood,

    // active items — from ActiveItems.totalActiveCount
    'active_items_count': activeItems.totalActiveCount,

    // progress history — from ProgressHistory.trend
    'progress_trend': progressHistory.trend,
    'avg_progress': progressHistory.averageProgress,

    // rewards — from Rewards.summary
    'rewards_earned': rewards.summary.totalRewardsEarned,
    'rewards_best_tier': rewards.summary.bestTierAchieved,
    'rewards_worst_tier': rewards.summary.worstTierAchieved,
    'rewards_total_points': rewards.summary.allRewardsPoints,
  };

  // ── Human-readable "last updated" label used in the dashboard header ──
  String _cachedLastUpdatedLabel = 'Never';
  DateTime? _lastCacheTime;

  String get lastUpdatedLabel {
    final dt = _dashboard?.updatedAt;
    if (dt == null) return 'Never';
    
    // Cache the label for 1 minute to avoid micro-stutters during 60fps rebuilds
    final now = DateTime.now();
    if (_lastCacheTime != null && now.difference(_lastCacheTime!).inMinutes < 1) {
      return _cachedLastUpdatedLabel;
    }

    _lastCacheTime = now;
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) {
      _cachedLastUpdatedLabel = 'Just now';
    } else if (diff.inMinutes < 60) {
      _cachedLastUpdatedLabel = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      _cachedLastUpdatedLabel = '${diff.inHours}h ago';
    } else {
      _cachedLastUpdatedLabel = '${dt.day}/${dt.month}/${dt.year}';
    }
    
    return _cachedLastUpdatedLabel;
  }

  // ================================================================
  // INITIALISE
  // Full lifecycle:
  //   1. Load from local PowerSync cache immediately (zero-latency)
  //   2. Check if data is stale → call server RPC if yes
  //   3. Subscribe to PowerSync real-time stream
  //   4. Start 5-minute auto-refresh timer
  //
  // If called again for the same userId (e.g. hot-reload), the
  // method is idempotent — it only refreshes if data is stale.
  // If called for a different userId (e.g. account switch), it
  // fully reinitialises.
  // ================================================================

  Future<void> initialize(String userId) async {
    if (userId.isEmpty) {
      logE('❌ [Provider] initialize: userId is empty — aborting');
      return;
    }

    // ── Already watching this user → staleness check only ─────────
    if (_initialised && _userId == userId) {
      logI(
        'ℹ️ [Provider] already initialised for $userId — checking staleness',
      );
      final stale = await _repo.needsRefresh(userId);
      if (stale) await refreshDashboard(userId);
      return;
    }

    // ── New user or first init ─────────────────────────────────────
    _userId = userId;
    _clearError();

    // Only show the full-screen spinner when we have no cached data yet.
    // If we already have data (e.g. provider was reused), we refresh
    // silently in the background so the UI never goes blank.
    if (_dashboard == null) {
      _setLoading(true);
    }

    try {
      // ── Step 1: local cache (instant, no network) ──────────────
      final cached = await _repo.getUserDashboardByUserId(userId);
      if (cached != null) {
        _dashboard = cached;
        _setLoading(false); // show cached data right away
        _notifyDebounced();
        logI('✅ [Provider] loaded from local cache');
      }

      // ── Step 2: call ensure_user_analytics RPC ─────────────────
      // Guarantees the server row exists. Creates it if missing.
      await _repo.ensureUserAnalytics(userId);

      // ── Step 3: refresh if stale or no local data ──────────────
      final stale = await _repo.needsRefresh(userId);
      if (stale || cached == null) {
        logI('🔄 [Provider] data is stale/missing — refreshing from server');
        await refreshDashboard(userId);
      }

      _initialised = true;
    } catch (e, s) {
      logE('❌ [Provider] initialize error', error: e, stackTrace: s);
      _setError('Failed to load dashboard');
    } finally {
      // Always dismiss the loading spinner even on error
      if (_loading) _setLoading(false);
    }

    // ── Step 4: subscribe to real-time stream ──────────────────────
    _startStream(userId);

    // ── Step 5: start 5-minute background refresh timer ───────────
    _startRefreshTimer(userId);
  }

  // ================================================================
  // REFRESH
  // Calls the server RPC (get_dashboard with force_refresh=true)
  // then re-reads the result into _dashboard.
  // Called by: initialize, timer, manual pull-to-refresh.
  // ================================================================

  Future<void> refreshDashboard(String userId) async {
    if (userId.isEmpty) return;
    try {
      logI('🔄 [Provider] refreshing dashboard for $userId');

      // forceServer = true → bypasses local cache, calls get_dashboard RPC
      final fresh = await _repo.getUserDashboardByUserId(
        userId,
        forceServer: true,
      );

      if (fresh != null) {
        _dashboard = fresh;
        _clearError();
        _notifyDebounced();
        logI('✅ [Provider] dashboard refreshed successfully');
      } else {
        logW('⚠️ [Provider] refresh returned null — keeping existing data');
      }
    } catch (e, s) {
      logE('❌ [Provider] refresh error', error: e, stackTrace: s);
      // Only show error to UI if we have nothing to show at all
      if (_dashboard == null) {
        _error = 'Refresh failed';
        _notifyDebounced();
      }
    }
  }

  // ================================================================
  // SECTION UPDATE
  // Optimistic local write for a single JSONB column.
  // The trigger on the source table will produce a full server-side
  // refresh asynchronously; this just updates the local copy fast.
  //
  // section: one of the column names, e.g. 'today', 'overview'
  // data:    the new JSONB content for that column
  // ================================================================

  Future<bool> updateDashboardSection(
    String section,
    Map<String, dynamic> data,
  ) async {
    if (_userId.isEmpty) {
      logW('⚠️ [Provider] updateDashboardSection: userId empty');
      return false;
    }
    try {
      final ok = await _repo.updateDashboardSection(_userId, section, data);
      if (ok) {
        logI('✅ [Provider] section "$section" updated locally');
      } else {
        logW('⚠️ [Provider] section "$section" update returned false');
      }
      return ok;
    } catch (e, s) {
      logE(
        '❌ [Provider] updateDashboardSection error',
        error: e,
        stackTrace: s,
      );
      _error = 'Failed to sync changes. Please check your connection.';
      _notifyDebounced();
      return false;
    }
  }

  // ================================================================
  // STREAM — real-time PowerSync subscription
  //
  // Guard logic: only accept a stream event if it is NEWER than
  // what we already have. This prevents a stale local-cache write
  // (from a previous session's PowerSync sync) from overwriting
  // a fresh RPC result that was just loaded.
  // ================================================================

  void _startStream(String userId) {
    _streamSub?.cancel();
    _streamSub = _repo
        .watchUserDashboardByUserId(userId)
        .listen(
          (incoming) {
            if (incoming == null) return;

            final currentTs = _dashboard?.updatedAt;
            final incomingTs = incoming.updatedAt;

            // Accept if: we have nothing, or the incoming is the same age
            // (e.g. same millisecond), or it is genuinely newer.
            final shouldAccept =
                currentTs == null ||
                incomingTs == null ||
                !incomingTs.isBefore(currentTs);

            if (shouldAccept) {
              logI('📡 [Provider] stream update accepted');

              // ── Reward Celebration Logic ─────────────────────────────
              if (_dashboard != null && incoming != null) {
                final oldRewards = _dashboard!.rewards.summary.totalRewardsEarned;
                final newRewards = incoming.rewards.summary.totalRewardsEarned;
                if (newRewards > oldRewards) {
                  logI('🎉 [Provider] NEW REWARD DETECTED!');
                  _newRewardEarned = true;
                  // Notifications are now handled by the backend/modular architecture
                  // Flag will be cleared by the UI or after a delay
                }
              }

              _dashboard = incoming;
              _clearError();
              _notifyDebounced();
            } else {
              logW('📡 [Provider] stream update ignored (older than current)');
            }
          },
          onError: (Object e) {
            logE('❌ [Provider] stream error', error: e);
            // Do not surface stream errors to UI if we have data
          },
        );

    Timer? dbDebounce;
    _dbChangesSub?.cancel();
    _dbChangesSub = _repo.watchDatabaseChanges().listen(
      (_) {
        dbDebounce?.cancel();
        dbDebounce = Timer(const Duration(milliseconds: 1500), () {
          logI('🔔 [Provider] Debounced database change - auto-refreshing dashboard...');
          refreshDashboard(userId);
        });
      },
      onError: (Object e) {
        logE('❌ [Provider] db changes stream error', error: e);
      },
    );
  }

  // ================================================================
  // AUTO-REFRESH TIMER
  // Fires every 5 minutes to re-fetch from the server even when
  // no source-table trigger has fired (e.g. user is just viewing).
  // ================================================================

  void _startRefreshTimer(String userId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_kRefreshInterval, (_) {
      logI('⏱ [Provider] auto-refresh timer fired');
      refreshDashboard(userId);
    });
  }

  // ================================================================
  // WATCH — expose streams to UI widgets that need section streams
  // (e.g. an isolated chart widget watching only progress_history)
  // ================================================================

  /// Stream of the full dashboard object. Backed by PowerSync.
  Stream<UserDashboard?> watchDashboard(String userId) =>
      _repo.watchUserDashboardByUserId(userId);

  /// Stream of a single JSONB column as a raw map.
  /// column must be one of the 10 JSONB column names.
  Stream<Map<String, dynamic>> watchSection(String userId, String column) =>
      _repo.watchDashboardSection(userId, column);

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    _notifyDebounced();
  }

  void _setError(String message) {
    _error = message;
    _notifyDebounced();
  }

  void _clearError() {
    // Only trigger a rebuild if the error was previously non-null
    if (_error != null) {
      _error = null;
      // No notifyDebounced here — caller will trigger one
    }
  }

  /// Collapses rapid successive calls into a single notifyListeners()
  /// at the next frame boundary (~16 ms).
  void _notifyDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kDebounce, () {
      if (!_disposed) notifyListeners();
    });
  }

  // ================================================================
  // RESET — call on user logout
  // Cancels all subscriptions, clears all state.
  // After reset(), the provider can be re-used for a new login by
  // calling initialize() again.
  // ================================================================

  void reset() {
    logI('🔁 [Provider] resetting dashboard state');
    _streamSub?.cancel();
    _dbChangesSub?.cancel();
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    _streamSub = null;
    _dbChangesSub = null;
    _refreshTimer = null;
    _debounceTimer = null;
    _dashboard = null;
    _loading = false;
    _initialised = false;
    _error = null;
    _userId = '';
    if (!_disposed) notifyListeners();
  }

  // ================================================================
  // DISPOSE — called by the widget tree when provider is removed
  // ================================================================

  @override
  void dispose() {
    logI('🗑 [Provider] disposing');
    _disposed = true;
    _streamSub?.cancel();
    _dbChangesSub?.cancel();
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

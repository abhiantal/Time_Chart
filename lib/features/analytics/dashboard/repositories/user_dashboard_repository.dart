// ================================================================
// FILE: lib/features/personal/dashboard/repositories/user_dashboard_repository.dart
//
// Data layer for the performance_analytics table.
// Architecture: local-first (PowerSync SQLite) with Supabase RPC fallback.
//
// READ FLOW:
//   1. Try PowerSync local SQLite cache first (zero-latency, offline-safe)
//   2. If not cached or forced → call get_dashboard RPC on Supabase
//   3. Write RPC result back to local cache (optimistic sync)
//   4. Apply mentee privacy filter if reading another user's dashboard
//
// WRITE FLOW:
//   • Section updates go directly to local PowerSync
//   • PowerSync syncs to Supabase in the background automatically
//   • Full refresh is triggered via Supabase RPC, not local write
//
// JSONB NOTE:
//   Supabase stores the column values as JSONB.
//   PowerSync SQLite stores them as JSON text strings.
//   _encode() serialises Maps/Lists to strings before writing to SQLite.
//   _decode() deserialises them back to Maps/Lists after reading from SQLite.
//
// DEPENDS ON:
//   dashboard_model.dart           → UserDashboard + all section classes
//   powersync_service.dart         → local SQLite via PowerSync
//   supabase_service.dart          → Supabase client
//   mentorship_repository.dart     → MenteePermissions + canAccess check
//   logger.dart                    → logI / logW / logE helpers
//   error_handler.dart             → snackbar helpers
// ================================================================

import 'dart:async';
import 'dart:convert';

import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

import '../../../../widgets/error_handler.dart';
import '../../../../widgets/logger.dart';
import '../models/dashboard_model.dart';
import '../../mentoring/repositories/mentorship_repository.dart';

// ================================================================
// MENTEE PERMISSIONS
// Controls which dashboard sections a mentor is allowed to see
// when reading another user's dashboard.
// This is checked in _applyMenteeFilter() before returning data.
// ================================================================

class MenteePermissions {
  final bool showMood; // mood column
  final bool showRewards; // rewards column
  final bool showStreak; // streaks column
  final bool showProgress; // progress_history + weekly_history columns
  final bool showTasks; // today + active_items columns
  final bool showTaskDetails; // reserved for fine-grained control

  const MenteePermissions({
    this.showMood = false,
    this.showRewards = false,
    this.showStreak = false,
    this.showProgress = false,
    this.showTasks = false,
    this.showTaskDetails = false,
  });
}

// ================================================================
// REPOSITORY
// ================================================================

class UserDashboardRepository {
  final PowerSyncService _ps;

  // ── DB table name ─────────────────────────────────────────────
  static const String _table = 'performance_analytics';

  // ── JSONB column names ────────────────────────────────────────
  // These are the columns stored as JSONB in Supabase and as text
  // in SQLite. All encode/decode logic is gated on this list.
  static const List<String> _jsonbCols = [
    'overview',
    'today',
    'active_items',
    'progress_history',
    'weekly_history',
    'category_stats',
    'rewards',
    'streaks',
    'mood',
    'recent_activity',
    'last_notified',
  ];

  // SQLite Columns matching PowerSync database_schema.dart for performance_analytics table
  static const List<String> _sqliteCols = [
    'id',
    'user_id',
    'overview',
    'today',
    'active_items',
    'progress_history',
    'weekly_history',
    'category_stats',
    'rewards',
    'streaks',
    'mood',
    'recent_activity',
    'snapshot_at',
    'updated_at',
    'created_at',
  ];

  // ── Singleton ─────────────────────────────────────────────────
  // Normal app usage: UserDashboardRepository() → returns the singleton.
  // Test usage: UserDashboardRepository(powerSync: mockService) → new instance.
  static final UserDashboardRepository _instance =
      UserDashboardRepository._internal();

  factory UserDashboardRepository({PowerSyncService? powerSync}) =>
      powerSync != null
      ? UserDashboardRepository._withService(powerSync)
      : _instance;

  UserDashboardRepository._internal() : _ps = PowerSyncService();

  UserDashboardRepository._withService(this._ps);

  // ── Current logged-in user ID (from PowerSync auth) ───────────
  String get _currentUserId => _ps.currentUserId ?? '';

  // ================================================================
  // CREATE
  // Used when bootstrapping a brand-new user row locally.
  // In normal flow, the server creates the row via ensure_user_analytics.
  // This is a local-only fallback.
  // ================================================================

  Future<UserDashboard?> createUserDashboard(UserDashboard dashboard) async {
    try {
      logI('📝 [Repo] creating dashboard row for ${dashboard.userId}');

      final data = _encode(dashboard.toJson());

      // Ensure required fields are present
      data['id'] ??= const Uuid().v4();
      data['created_at'] ??= DateTime.now().toIso8601String();
      data['updated_at'] ??= DateTime.now().toIso8601String();

      // Safety: use current auth user if user_id is missing
      if ((data['user_id'] as String?)?.isEmpty ?? true) {
        data['user_id'] = _currentUserId;
      }

      await _ps.insert(_table, data);
      logI('✅ [Repo] dashboard row created locally');
      return dashboard;
    } catch (e, s) {
      logE('❌ [Repo] createUserDashboard error', error: e, stackTrace: s);
      ErrorHandler.showErrorSnackbar('Could not create dashboard');
      return null;
    }
  }

  // ================================================================
  // READ — local-first with Supabase RPC fallback
  //
  // forceServer = false → try local cache first (default)
  // forceServer = true  → skip cache, call get_dashboard RPC directly
  //
  // The get_dashboard RPC (defined in performance_analytics_v2.sql)
  // automatically refreshes data if it is more than 5 minutes old,
  // so we do not need to call refresh_performance_analytics separately.
  // ================================================================

  Future<UserDashboard?> getUserDashboardByUserId(
    String userId, {
    bool forceServer = false,
  }) async {
    if (userId.isEmpty) {
      logE('❌ [Repo] getUserDashboardByUserId: userId is empty');
      return null;
    }

    try {
      Map<String, dynamic>? raw;

      // ── Step 1: local SQLite via PowerSync ──────────────────────
      if (!forceServer && _ps.isReady) {
        final rows = await _ps.executeQuery(
          'SELECT * FROM $_table WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        );

        if (rows.isNotEmpty) {
          raw = _decode(rows.first);
          logI('✅ [Repo] loaded from local SQLite cache');
        }
      }

      // ── Step 2: Supabase RPC fallback ───────────────────────────
      // Called when:  forced refresh, or local cache is empty
      if (raw == null || forceServer) {
        logI(
          '🔍 [Repo] ${forceServer ? "forced" : "cache miss"} → calling get_dashboard RPC',
        );

        final supabase = SupabaseService();
        if (!supabase.isInitialized) {
          logE('❌ [Repo] Supabase not initialised');
          return raw != null ? UserDashboard.fromJson(raw) : null;
        }

        // get_dashboard RPC returns the full row as JSONB
        // p_refresh=true tells the server to rebuild all columns
        try {
          final result = await supabase.client
              .rpc(
                'get_dashboard',
                params: {'p_user_id': userId, 'p_refresh': forceServer},
              )
              .timeout(const Duration(seconds: 10));

          if (result == null) {
            logW('⚠️ [Repo] get_dashboard RPC returned null');
            // Return stale local data if we have it
            return raw != null ? UserDashboard.fromJson(raw) : null;
          }

          raw = _decode(Map<String, dynamic>.from(result as Map));
          logI('✅ [Repo] loaded from Supabase RPC');
        } on TimeoutException {
          logW('⚠️ [Repo] get_dashboard RPC timed out - using local data');
          return raw != null ? UserDashboard.fromJson(raw) : null;
        } catch (e) {
          // If it's a network error, log briefly and use local data
          final errMsg = e.toString();
          if (errMsg.contains('SocketException') ||
              errMsg.contains('Failed host lookup') ||
              errMsg.contains('HandshakeException')) {
            logW(
              '📡 [Repo] Network unavailable for dashboard refresh - using local data',
            );
            return raw != null ? UserDashboard.fromJson(raw) : null;
          }
          rethrow; // Re-catch in outer block for real errors
        }

        // ── Step 3: write RPC result back to local cache ───────────
        // This ensures PowerSync's local SQLite is up to date so the
        // next load is instant even offline.
        if (_ps.isReady) {
          try {
            final localData = _encode(raw);
            final id = localData['id'] as String? ?? '';
            final existsLocally = id.isNotEmpty && await _ps.exists(_table, id);

            if (existsLocally) {
              await _ps.update(_table, localData, id);
            } else {
              await _ps.insert(_table, localData);
            }
            logI('✅ [Repo] optimistic local cache update done');
          } catch (e) {
            // Non-fatal: local cache update failed but we still have RPC data
            logW('⚠️ [Repo] optimistic local cache update failed: $e');
          }
        }
      }

      // ── Step 4: mentee privacy filter ──────────────────────────
      // If reading another user's dashboard, strip sections the
      // current user is not permitted to see.
      if (userId != _currentUserId) {
        final filtered = await _applyMenteeFilter(userId, raw);
        if (filtered == null) {
          logW('⚠️ [Repo] mentee filter denied access to $userId');
          return null;
        }
        raw = filtered;
      }

      // ── Step 5: parse and return ────────────────────────────────
      final dashboard = UserDashboard.fromJson(raw);
      logI(
        '[Repo] parsed — '
        'points=${dashboard.overview.summary.totalPoints}, '
        'streak=${dashboard.streaks.currentDays}, '
        'mood7d=${dashboard.mood.averageMoodLast7Days}',
      );
      return dashboard;
    } catch (e, s) {
      logE('❌ [Repo] getUserDashboardByUserId error', error: e, stackTrace: s);
      return null;
    }
  }

  // ================================================================
  // WATCH — real-time stream via PowerSync
  // Emits a new UserDashboard every time the local SQLite row changes.
  // For other users (mentees) or when PowerSync is not ready,
  // falls back to a single-shot Future stream.
  // ================================================================

  Stream<UserDashboard?> watchUserDashboardByUserId(String userId) {
    // Can only stream own data via PowerSync; other users need RPC
    if (userId != _currentUserId || !_ps.isReady) {
      logI(
        'ℹ️ [Repo] watchUserDashboardByUserId: falling back to Future stream',
      );
      return Stream.fromFuture(getUserDashboardByUserId(userId));
    }

    return _ps
        .watchQuery(
          'SELECT * FROM $_table WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        )
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          try {
            return UserDashboard.fromJson(_decode(rows.first));
          } catch (e) {
            logE('❌ [Repo] watchUserDashboardByUserId parse error', error: e);
            return null;
          }
        });
  }

  Stream<List<Map<String, dynamic>>> watchDatabaseChanges() {
    if (!_ps.isReady) return const Stream.empty();
    return _ps.watchQuery('''
      SELECT 
        (SELECT COUNT(*) FROM day_tasks) as t1,
        (SELECT COUNT(*) FROM weekly_tasks) as t2,
        (SELECT COUNT(*) FROM long_goals) as t3,
        (SELECT COUNT(*) FROM bucket_models) as t4,
        (SELECT COUNT(*) FROM diary_entries) as t5
    ''');
  }

  // ================================================================
  // SECTION READ — fetch one JSONB column as a raw map
  // Useful for widgets that only need a specific column (e.g. a
  // dedicated chart screen that only needs progress_history).
  // ================================================================

  Future<Map<String, dynamic>> getDashboardSection(
    String userId,
    String column,
  ) async {
    try {
      // Try local cache first
      if (_ps.isReady) {
        final rows = await _ps.executeQuery(
          'SELECT $column FROM $_table WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        );
        if (rows.isNotEmpty) {
          return _decodeColumn(rows.first[column]);
        }
      }

      // Supabase fallback — get the full row and extract the column
      final supabase = SupabaseService();
      if (!supabase.isInitialized) return {};

      final result = await supabase.client.rpc(
        'get_dashboard',
        params: {'p_user_id': userId, 'p_refresh': false},
      );
      if (result == null) return {};

      final full = _decode(Map<String, dynamic>.from(result as Map));
      return _decodeColumn(full[column]);
    } catch (e) {
      logE('❌ [Repo] getDashboardSection($column) error', error: e);
      return {};
    }
  }

  // ── Named convenience methods for common sections ──────────────

  /// Fetch the overview column (summary + 4 stat blocks).
  Future<Map<String, dynamic>> getDashboardOverview(String userId) =>
      getDashboardSection(userId, 'overview');

  /// Fetch the today column (day_tasks + week_tasks + buckets + diary).
  Future<Map<String, dynamic>> getTodayTasks(String userId) =>
      getDashboardSection(userId, 'today');

  /// Fetch the active_items column (inProgress tasks only).
  Future<Map<String, dynamic>> getActiveItems(String userId) =>
      getDashboardSection(userId, 'active_items');

  // ================================================================
  // SECTION WATCH — real-time stream for a single JSONB column
  // ================================================================

  Stream<Map<String, dynamic>> watchDashboardSection(
    String userId,
    String column,
  ) {
    if (userId != _currentUserId || !_ps.isReady) {
      return Stream.fromFuture(getDashboardSection(userId, column));
    }

    return _ps
        .watchQuery(
          'SELECT $column FROM $_table WHERE user_id = ? LIMIT 1',
          parameters: [userId],
        )
        .map(
          (rows) => rows.isEmpty
              ? <String, dynamic>{}
              : _decodeColumn(rows.first[column]),
        );
  }

  /// Stream of the overview column.
  Stream<Map<String, dynamic>> watchDashboardOverview(String userId) =>
      watchDashboardSection(userId, 'overview');

  /// Stream of the today column.
  Stream<Map<String, dynamic>> watchTodayTasks(String userId) =>
      watchDashboardSection(userId, 'today');

  // ================================================================
  // UPDATE — full UserDashboard object
  // Writes the entire row to local SQLite.
  // Strips created_at to avoid overwriting the original create time.
  // ================================================================

  Future<UserDashboard?> updateUserDashboard(UserDashboard dashboard) async {
    try {
      if (dashboard.id.isEmpty) {
        logE('❌ [Repo] updateUserDashboard: id is empty');
        return null;
      }
      if (!_ps.isReady) {
        logW('⚠️ [Repo] updateUserDashboard: PowerSync not ready — skipping');
        return dashboard;
      }

      logI('🔄 [Repo] updating dashboard row ${dashboard.id}');

      final data = _encode(dashboard.toJson())
        ..remove('created_at') // never overwrite
        ..['updated_at'] = DateTime.now().toIso8601String()
        ..['snapshot_at'] = DateTime.now().toIso8601String();

      await _ps.update(_table, data, dashboard.id);
      logI('✅ [Repo] dashboard row updated locally');
      return dashboard.copyWith(updatedAt: DateTime.now());
    } catch (e, s) {
      logE('❌ [Repo] updateUserDashboard error', error: e, stackTrace: s);
      ErrorHandler.showErrorSnackbar('Could not update dashboard');
      return null;
    }
  }

  // ================================================================
  // UPDATE — single JSONB section (optimistic local write)
  // Writes only one column without touching the rest of the row.
  // Used by the provider's updateDashboardSection() for quick partial
  // updates (e.g. updating the today column after a task is completed).
  // ================================================================

  Future<bool> updateDashboardSection(
    String userId,
    String section,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!_ps.isReady) {
        logW('⚠️ [Repo] updateDashboardSection: PowerSync not ready');
        return false;
      }

      logI('📊 [Repo] updating section "$section" for $userId');

      // Encode the section data to a JSON string for SQLite
      final encoded = _encodeValue(data);

      await _ps.updateWhere(
        _table,
        {section: encoded, 'updated_at': DateTime.now().toIso8601String()},
        'user_id = ?',
        [userId],
      );

      logI('✅ [Repo] section "$section" updated locally');
      return true;
    } catch (e, s) {
      logE('❌ [Repo] updateDashboardSection error', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // REFRESH — trigger full server-side rebuild
  // Calls refresh_performance_analytics RPC.
  // The RPC recalculates ALL 10 columns from source tables.
  // After this call, the next read will return fresh data.
  // Note: get_dashboard already handles auto-refresh when stale,
  // so this is only needed when you want an immediate forced rebuild.
  // ================================================================

  Future<bool> refreshUserDashboard(String userId) async {
    try {
      logI('🔄 [Repo] calling refresh_performance_analytics for $userId');
      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        logE('❌ [Repo] Supabase not initialised');
        return false;
      }

      await supabase.client.rpc(
        'refresh_performance_analytics',
        params: {'p_user_id': userId},
      );

      logI('✅ [Repo] refresh_performance_analytics RPC completed');
      return true;
    } catch (e, s) {
      logE('❌ [Repo] refreshUserDashboard error', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // ENSURE — called on login/init
  // Calls ensure_user_analytics RPC which:
  //   • Creates the analytics row if it doesn't exist
  //   • Refreshes if data is older than 5 minutes
  //   • Does nothing if data is fresh
  // ================================================================

  Future<bool> ensureUserAnalytics(String userId) async {
    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        logE('❌ [Repo] ensureUserAnalytics: Supabase not initialised');
        return false;
      }

      await supabase.client
          .rpc('ensure_user_analytics', params: {'p_user_id': userId})
          .timeout(const Duration(seconds: 10));

      logI('✅ [Repo] ensure_user_analytics RPC completed');
      return true;
    } catch (e, s) {
      final errMsg = e.toString();
      if (errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup') ||
          errMsg.contains('Timeout')) {
        logW(
          '📡 [Repo] ensureUserAnalytics: Network unavailable, skipping RPC',
        );
        return false;
      }
      logE('❌ [Repo] ensureUserAnalytics error', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // STALE CHECK — 5-minute threshold
  // Reads the updated_at field from local SQLite and compares it to
  // now. Returns true if:
  //   • No local row exists (must fetch from server)
  //   • Row exists but updated_at is > 5 minutes ago
  //
  // SQLite DATETIME('now', '-5 minutes') is safe on all platforms.
  // ================================================================

  Future<bool> needsRefresh(String userId) async {
    try {
      if (!_ps.isReady) return true; // can't check → assume stale

      final rows = await _ps.executeQuery(
        "SELECT CASE "
        "  WHEN datetime(updated_at) < datetime('now', '-5 minutes') THEN 1 "
        "  ELSE 0 "
        "END AS stale "
        "FROM $_table WHERE user_id = ? LIMIT 1",
        parameters: [userId],
      );

      if (rows.isEmpty) return true; // no row = definitely stale

      final v = rows.first['stale'];
      // PowerSync may return int, bool, or string depending on platform
      return v == 1 || v == true || v == '1';
    } catch (e) {
      logW('⚠️ [Repo] needsRefresh check failed, assuming stale: $e');
      return true;
    }
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<bool> deleteUserDashboard(String userId) async {
    try {
      await _ps.deleteWhere(_table, 'user_id = ?', [userId]);
      logI('✅ [Repo] dashboard row deleted for $userId');
      return true;
    } catch (e, s) {
      logE('❌ [Repo] deleteUserDashboard error', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // MENTEE PRIVACY FILTER
  // Called when reading another user's dashboard.
  // Checks the active mentorship connection and strips columns that
  // the current user (mentor) is not permitted to see.
  // Returns null if no active connection exists.
  // ================================================================

  Future<Map<String, dynamic>?> _applyMenteeFilter(
    String targetUserId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Look up the active mentorship connection for this pair
      final connection = await MentorshipRepository()
          .getActiveConnectionForPair(targetUserId, _currentUserId);

      // No connection or access not granted → deny
      if (connection == null || !connection.canAccess) {
        logW(
          '⚠️ [Repo] _applyMenteeFilter: no active connection or access denied',
        );
        return null;
      }

      // Cast the permissions object to MenteePermissions
      final p = connection.permissions as MenteePermissions;
      final filtered = Map<String, dynamic>.from(data);

      // Null out sections the mentor is not allowed to see
      // The model's fromJson handles null values gracefully (returns empty)
      if (!p.showMood) filtered['mood'] = null;
      if (!p.showRewards) filtered['rewards'] = null;
      if (!p.showStreak) filtered['streaks'] = null;
      if (!p.showProgress) {
        filtered['progress_history'] = null;
        filtered['weekly_history'] = null;
      }
      if (!p.showTasks) {
        filtered['today'] = null;
        filtered['active_items'] = null;
      }

      return filtered;
    } catch (e) {
      logE('❌ [Repo] _applyMenteeFilter error', error: e);
      return null;
    }
  }

  // ================================================================
  // JSONB ENCODE / DECODE
  //
  // WHY:
  //   Supabase stores dashboard columns as JSONB (rich objects).
  //   PowerSync serialises JSONB → text strings when writing to SQLite.
  //   We must encode Map/List → JSON string before inserting/updating,
  //   and decode JSON string → Map/List after reading.
  //
  // _encode()       → full row Map, converts JSONB columns to strings
  // _decode()       → full row Map, converts strings back to Maps/Lists
  // _decodeColumn() → single column value, handles any input type
  // _encodeValue()  → single value, converts Map/List to JSON string
  // ================================================================

  /// Encode a full dashboard row for writing to SQLite.
  /// Converts Map/List JSONB columns to JSON strings.
  /// Converts DateTime values to ISO-8601 strings.
  Map<String, dynamic> _encode(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (!_sqliteCols.contains(key)) {
        return; // skip columns that do not exist in local SQLite schema (e.g. last_notified)
      }
      if (_jsonbCols.contains(key) && (value is Map || value is List)) {
        // JSONB column: serialise to string for SQLite
        out[key] = _encodeValue(value);
      } else if (value is DateTime) {
        out[key] = value.toIso8601String();
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Encode a single Map or List value to a JSON string.
  /// Used for section updates and _encode().
  String _encodeValue(dynamic value) {
    try {
      return jsonEncode(
        value,
        toEncodable: (obj) {
          // Handle DateTime fields inside the nested JSONB structures
          if (obj is DateTime) return obj.toIso8601String();
          return obj.toString();
        },
      );
    } catch (_) {
      return '{}'; // safe fallback — model will parse as empty
    }
  }

  /// Decode a full dashboard row read from SQLite.
  /// Converts JSON string JSONB columns back to Map/List.
  Map<String, dynamic> _decode(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (_jsonbCols.contains(key)) {
        if (value is String && value.isNotEmpty) {
          // String from SQLite → parse back to Map/List
          try {
            final decoded = jsonDecode(value);
            out[key] = decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : decoded;
          } catch (_) {
            // Keep raw string if JSON parse fails (model will handle it)
            out[key] = value;
          }
        } else if (value is Map) {
          // Already a Map (came from Supabase RPC, not SQLite)
          out[key] = Map<String, dynamic>.from(value);
        } else {
          // null or unexpected type — pass through; model handles null
          out[key] = value;
        }
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Decode a single column value regardless of its type.
  /// Used by getDashboardSection() and watchDashboardSection().
  Map<String, dynamic> _decodeColumn(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }
}

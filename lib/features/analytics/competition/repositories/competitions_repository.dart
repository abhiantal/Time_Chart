// ================================================================
// FILE: lib/features/personal/battle/repositories/battle_challenge_repository.dart
//
// Data layer for the battle_challenges table.
// Architecture: local-first (PowerSync SQLite) with Supabase RPC fallback.
//
// READ FLOW:
//   1. Try local PowerSync SQLite cache first (instant, offline-safe)
//   2. If not cached or forced → call get_battle RPC on Supabase
//   3. Write RPC result back to local cache
//
// WRITE FLOW (creator only):
//   createBattle    → local insert → PowerSync syncs to Supabase
//   addMember       → add_battle_member RPC (server builds stats)
//   removeMember    → remove_battle_member RPC
//   updateStatus    → local update
//   deleteBattle    → local delete
//
// JSONB NOTE:
//   Supabase stores creator_stats/member1_stats.../member5_stats as JSONB.
//   PowerSync SQLite stores them as JSON text strings.
//   _encode() serialises Map/List → string before writing to SQLite.
//   _decode() deserialises string → Map/List after reading from SQLite.
//
// DEPENDS ON:
//   battle_challenge_model.dart  → BattleChallenge + all sub-models
//   powersync_service.dart       → local SQLite via PowerSync
//   supabase_service.dart        → Supabase client
//   logger.dart                  → logI / logW / logE helpers
//   error_handler.dart           → snackbar helpers
// ================================================================

import 'dart:async';
import 'dart:convert';

import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

import '../../../../widgets/error_handler.dart';
import '../../../../widgets/logger.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';
import '../models/competition_model.dart';

class BattleChallengeRepository {
  final PowerSyncService _ps;

  static const String _table = 'battle_challenges';

  // JSONB columns: stored as text strings in SQLite, objects in Supabase
  static const List<String> _jsonbCols = [
    'user_stats',
    'member1_stats',
    'member2_stats',
    'member3_stats',
    'member4_stats',
    'member5_stats',
  ];

  // ── Singleton ─────────────────────────────────────────────────
  static final BattleChallengeRepository _instance =
      BattleChallengeRepository._internal();

  factory BattleChallengeRepository({PowerSyncService? powerSync}) =>
      powerSync != null
      ? BattleChallengeRepository._withService(powerSync)
      : _instance;

  BattleChallengeRepository._internal() : _ps = PowerSyncService();
  BattleChallengeRepository._withService(this._ps);

  String get _currentUserId => _ps.currentUserId ?? '';

  // ================================================================
  // CREATE
  // Creates the battle row locally. PowerSync syncs to Supabase.
  // After insert, calls refresh_battle_stats_for_user to build
  // the creator's initial stats snapshot on the server.
  // ================================================================

  Future<BattleChallenge?> createBattle({
    required String title,
    String? description,
    DateTime? endsAt,
  }) async {
    if (_currentUserId.isEmpty) {
      logE('❌ [Battle Repo] createBattle: not logged in');
      return null;
    }
    try {
      logI('📝 [Battle Repo] creating battle: $title');

      final id = const Uuid().v4();
      final now = DateTime.now();

      await _ps.insert(
        _table,
        _encode({
          'id': id,
          'user_id': _currentUserId,
          'title': title,
          'description': description,
          'status': BattleStatus.active.value,
          'starts_at': now.toIso8601String(),
          'ends_at': endsAt?.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
      );

      logI('✅ [Battle Repo] battle created locally: $id');

      // Build the creator's initial stats snapshot server-side.
      // Non-fatal if it fails — the trigger rebuilds on next PA update.
      await _refreshServerStats(_currentUserId);

      return getBattleById(id);
    } catch (e, s) {
      logE('❌ [Battle Repo] createBattle error', error: e, stackTrace: s);
      ErrorHandler.showErrorSnackbar('Could not create battle');
      return null;
    }
  }

  // ================================================================
  // READ — single battle, local-first with RPC fallback
  // ================================================================

  Future<BattleChallenge?> getBattleById(
    String battleId, {
    bool forceServer = false,
  }) async {
    if (battleId.isEmpty) {
      logE('❌ [Battle Repo] getBattleById: battleId empty');
      return null;
    }
    try {
      Map<String, dynamic>? raw;

      // ── Step 1: local SQLite ───────────────────────────────────
      if (!forceServer && _ps.isReady) {
        final rows = await _ps.executeQuery(
          'SELECT * FROM $_table WHERE id = ? LIMIT 1',
          parameters: [battleId],
        );
        if (rows.isNotEmpty) {
          raw = _decode(rows.first);
          logI('✅ [Battle Repo] loaded from local cache: $battleId');
        }
      }

      // ── Step 2: Supabase RPC fallback ──────────────────────────
      if (raw == null || forceServer) {
        logI(
          '🔍 [Battle Repo] ${forceServer ? "forced" : "cache miss"} → get_battle RPC',
        );

        final supabase = SupabaseService();
        if (!supabase.isInitialized) {
          logE('❌ [Battle Repo] Supabase not initialised');
          return raw != null ? BattleChallenge.fromJson(raw) : null;
        }

        final result = await supabase.client.rpc(
          'get_battle',
          params: {'p_battle_id': battleId},
        );

        if (result == null) {
          logW('⚠️ [Battle Repo] get_battle RPC returned null');
          return raw != null ? BattleChallenge.fromJson(raw) : null;
        }

        final resMap = Map<String, dynamic>.from(result as Map);
        if (resMap['error'] != null) {
          logW('⚠️ [Battle Repo] get_battle RPC error: ${resMap['error']}');
          return raw != null ? BattleChallenge.fromJson(raw) : null;
        }

        raw = _decode(resMap);
        logI('✅ [Battle Repo] loaded from Supabase RPC: $battleId');

        // ── Step 3: write RPC result to local cache ────────────────
        if (_ps.isReady) {
          try {
            final localData = _encode(raw);
            final exists = await _ps.exists(_table, battleId);
            if (exists) {
              await _ps.update(_table, localData, battleId);
            } else {
              await _ps.insert(_table, localData);
            }
            logI('✅ [Battle Repo] local cache updated: $battleId');
          } catch (e) {
            logW('⚠️ [Battle Repo] local cache update failed (non-fatal): $e');
          }
        }
      }
      return BattleChallenge.fromJson(raw);
    } catch (e, s) {
      logE('❌ [Battle Repo] getBattleById error', error: e, stackTrace: s);
      return null;
    }
  }

  // ================================================================
  // READ — all battles for a user
  // ================================================================

  Future<List<BattleChallenge>> getBattlesForUser(String userId) async {
    if (userId.isEmpty) return [];
    try {
      List<Map<String, dynamic>> rows = [];

      if (_ps.isReady) {
        rows = await _ps.executeQuery('''
          SELECT * FROM $_table
          WHERE  user_id = ?
             OR  member1_id = ?
             OR  member2_id = ?
             OR  member3_id = ?
             OR  member4_id = ?
             OR  member5_id = ?
          ORDER BY updated_at DESC
          ''', parameters: List.filled(6, userId));
      }

      if (rows.isEmpty) {
        // Supabase direct query fallback (RLS filters by participant)
        final supabase = SupabaseService();
        if (!supabase.isInitialized) return [];

        final result = await supabase.client
            .from(_table)
            .select()
            .or(
              'user_id.eq.$userId,'
              'member1_id.eq.$userId,'
              'member2_id.eq.$userId,'
              'member3_id.eq.$userId,'
              'member4_id.eq.$userId,'
              'member5_id.eq.$userId',
            )
            .order('updated_at', ascending: false);

        rows = List<Map<String, dynamic>>.from(result as List);
        logI(
          '✅ [Battle Repo] ${rows.length} battles from Supabase for $userId',
        );
      } else {
        logI(
          '✅ [Battle Repo] ${rows.length} battles from local cache for $userId',
        );
      }

      return rows.map((r) => BattleChallenge.fromJson(_decode(r))).toList();
    } catch (e, s) {
      logE('❌ [Battle Repo] getBattlesForUser error', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // WATCH — real-time stream for one battle
  // ================================================================

  Stream<BattleChallenge?> watchBattle(String battleId) {
    if (!_ps.isReady) {
      return Stream.fromFuture(getBattleById(battleId));
    }
    return _ps
        .watchQuery(
          'SELECT * FROM $_table WHERE id = ? LIMIT 1',
          parameters: [battleId],
        )
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          try {
            return BattleChallenge.fromJson(_decode(rows.first));
          } catch (e) {
            logE('❌ [Battle Repo] watchBattle parse error', error: e);
            return null;
          }
        });
  }

  // ================================================================
  // WATCH — real-time stream of all battles for a user
  // ================================================================

  Stream<List<BattleChallenge>> watchBattlesForUser(String userId) {
    if (userId.isEmpty || !_ps.isReady) {
      return Stream.fromFuture(getBattlesForUser(userId));
    }
    return _ps
        .watchQuery('''
          SELECT * FROM $_table
          WHERE  user_id = ?
             OR  member1_id = ?
             OR  member2_id = ?
             OR  member3_id = ?
             OR  member4_id = ?
             OR  member5_id = ?
          ORDER BY updated_at DESC
          ''', parameters: List.filled(6, userId))
        .map(
          (rows) =>
              rows.map((r) => BattleChallenge.fromJson(_decode(r))).toList(),
        );
  }

  // ================================================================
  // TOGGLE COMPETITOR — calls toggle_battle_competitor RPC
  // Finds or creates the single active battle for the creator.
  // Adds or removes the target user automatically.
  // ================================================================

  Future<({bool success, String? error, String? action, String? battleId})>
  toggleCompetitor(String targetUserId) async {
    try {
      logI('🔄 [Battle Repo] toggling competitor $targetUserId');

      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        return (
          success: false,
          error: 'Not connected to server',
          action: null,
          battleId: null,
        );
      }

      final result = await supabase.client.rpc(
        'toggle_battle_competitor',
        params: {'p_target_id': targetUserId},
      );

      if (result == null) {
        return (
          success: false,
          error: 'No response from server',
          action: null,
          battleId: null,
        );
      }

      final res = Map<String, dynamic>.from(result as Map);
      if (res['error'] != null) {
        logW('⚠️ [Battle Repo] toggleCompetitor RPC error: ${res['error']}');
        return (
          success: false,
          error: res['error'].toString(),
          action: null,
          battleId: null,
        );
      }

      final battleId = res['battle_id']?.toString();
      final action = res['action']?.toString();

      logI('✅ [Battle Repo] toggle success: $action (battle: $battleId)');

      // Refresh local cache with updated battle data
      if (battleId != null) {
        await getBattleById(battleId, forceServer: true);
      }

      return (
        success: true,
        error: null,
        action: action,
        battleId: battleId,
      );
    } catch (e, s) {
      logE('❌ [Battle Repo] toggleCompetitor error', error: e, stackTrace: s);
      return (
        success: false,
        error: 'Failed to toggle competitor',
        action: null,
        battleId: null,
      );
    }
  }

  // ================================================================
  // ADD MEMBER — calls add_battle_member RPC
  // Server: validates, assigns slot, builds stats, recomputes ranks.
  // Returns (success: true) or (success: false, error: "message").
  // ================================================================

  Future<({bool success, String? error})> addMember({
    required String battleId,
    required String memberUserId,
  }) async {
    try {
      logI('➕ [Battle Repo] adding $memberUserId to $battleId');

      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        return (success: false, error: 'Not connected to server');
      }

      final result = await supabase.client.rpc(
        'add_battle_member',
        params: {'p_battle_id': battleId, 'p_member_id': memberUserId},
      );

      if (result == null) {
        return (success: false, error: 'No response from server');
      }

      final res = Map<String, dynamic>.from(result as Map);
      if (res['error'] != null) {
        logW('⚠️ [Battle Repo] addMember RPC error: ${res['error']}');
        return (success: false, error: res['error'].toString());
      }

      logI('✅ [Battle Repo] member added to slot ${res['slot']}');

      // Refresh local cache with updated battle data
      await getBattleById(battleId, forceServer: true);

      return (success: true, error: null);
    } catch (e, s) {
      logE('❌ [Battle Repo] addMember error', error: e, stackTrace: s);
      return (success: false, error: 'Failed to add member');
    }
  }

  // ================================================================
  // SEARCH USERS
  // ================================================================

  Future<List<UserSearchResult>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];
    try {
      logI('🔍 [Battle Repo] searching users: $query (limit $limit)');
      final profiles = await ProfileRepository().searchProfiles(query, limit: limit);

      return profiles.map((p) {
        return UserSearchResult(
          id: p.id,
          username: p.username,
          displayName: p.displayName,
          profileUrl: p.profileUrl,
          email: p.email,
          score: p.score,
        );
      }).toList();
    } catch (e, s) {
      logE('❌ [Battle Repo] searchUsers error', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // REMOVE MEMBER — calls remove_battle_member RPC
  // Server: validates, nulls slot, recomputes ranks.
  // ================================================================

  Future<({bool success, String? error})> removeMember({
    required String battleId,
    required String memberUserId,
  }) async {
    try {
      logI('➖ [Battle Repo] removing $memberUserId from $battleId');

      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        return (success: false, error: 'Not connected to server');
      }

      final result = await supabase.client.rpc(
        'remove_battle_member',
        params: {'p_battle_id': battleId, 'p_member_id': memberUserId},
      );

      if (result == null) {
        return (success: false, error: 'No response from server');
      }

      final res = Map<String, dynamic>.from(result as Map);
      if (res['error'] != null) {
        logW('⚠️ [Battle Repo] removeMember RPC error: ${res['error']}');
        return (success: false, error: res['error'].toString());
      }

      logI('✅ [Battle Repo] member removed: ${res['removed']}');

      // Refresh local cache
      await getBattleById(battleId, forceServer: true);

      return (success: true, error: null);
    } catch (e, s) {
      logE('❌ [Battle Repo] removeMember error', error: e, stackTrace: s);
      return (success: false, error: 'Failed to remove member');
    }
  }

  // ================================================================
  // UPDATE STATUS
  // ================================================================

  Future<bool> updateStatus(String battleId, BattleStatus status) async {
    try {
      if (!_ps.isReady) {
        logW('⚠️ [Battle Repo] updateStatus: PowerSync not ready');
        return false;
      }
      await _ps.updateWhere(
        _table,
        {
          'status': status.value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [battleId],
      );
      logI('✅ [Battle Repo] status updated to ${status.value}');
      return true;
    } catch (e, s) {
      logE('❌ [Battle Repo] updateStatus error', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // UPDATE METADATA (title / description / ends_at)
  // ================================================================

  Future<bool> updateBattleMetadata(
    String battleId, {
    String? title,
    String? description,
    DateTime? endsAt,
  }) async {
    try {
      if (!_ps.isReady) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (endsAt != null) updates['ends_at'] = endsAt.toIso8601String();

      if (updates.length == 1) return true; // nothing to update

      await _ps.updateWhere(_table, updates, 'id = ?', [battleId]);
      logI('✅ [Battle Repo] metadata updated for $battleId');
      return true;
    } catch (e, s) {
      logE(
        '❌ [Battle Repo] updateBattleMetadata error',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<bool> deleteBattle(String battleId) async {
    try {
      await _ps.deleteWhere(_table, 'id = ?', [battleId]);
      logI('✅ [Battle Repo] battle deleted: $battleId');
      return true;
    } catch (e, s) {
      logE('❌ [Battle Repo] deleteBattle error', error: e, stackTrace: s);
      ErrorHandler.showErrorSnackbar('Could not delete battle');
      return false;
    }
  }

  // ================================================================
  // STALE CHECK — 5-minute threshold
  // ================================================================

  Future<bool> needsRefresh(String battleId) async {
    try {
      if (!_ps.isReady) return true;
      final rows = await _ps.executeQuery(
        "SELECT CASE "
        "  WHEN datetime(updated_at) < datetime('now', '-5 minutes') THEN 1 "
        "  ELSE 0 "
        "END AS stale "
        "FROM $_table WHERE id = ? LIMIT 1",
        parameters: [battleId],
      );
      if (rows.isEmpty) return true;
      final v = rows.first['stale'];
      return v == 1 || v == true || v == '1';
    } catch (e) {
      logW('⚠️ [Battle Repo] needsRefresh failed, assuming stale: $e');
      return true;
    }
  }

  // ================================================================
  // PRIVATE: call refresh_battle_stats_for_user RPC
  // Used after createBattle to populate user_stats immediately.
  // Non-fatal if it fails.
  // ================================================================

  Future<void> _refreshServerStats(String userId) async {
    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized) return;
      await supabase.client.rpc(
        'refresh_battle_stats_for_user',
        params: {'p_user_id': userId},
      );
      logI('✅ [Battle Repo] server stats refreshed for $userId');
    } catch (e) {
      logW('⚠️ [Battle Repo] _refreshServerStats failed (non-fatal): $e');
    }
  }

  // ================================================================
  // JSONB ENCODE / DECODE
  // Same pattern as UserDashboardRepository.
  //
  // Supabase stores stats columns as JSONB objects.
  // PowerSync serialises JSONB → text strings in SQLite.
  // We must encode before writing and decode after reading.
  // ================================================================

  /// Encode a full battle row for SQLite.
  /// Converts all 6 stats JSONB columns from Map → JSON string.
  Map<String, dynamic> _encode(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (_jsonbCols.contains(key) && (value is Map || value is List)) {
        out[key] = _encodeValue(value);
      } else if (value is DateTime) {
        out[key] = value.toIso8601String();
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Encode a single Map/List value to a JSON string.
  String _encodeValue(dynamic value) {
    try {
      return jsonEncode(
        value,
        toEncodable: (obj) {
          if (obj is DateTime) return obj.toIso8601String();
          return obj.toString();
        },
      );
    } catch (_) {
      return '{}';
    }
  }

  /// Decode a full battle row from SQLite.
  /// Converts JSON string stats columns back to Maps.
  Map<String, dynamic> _decode(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      if (_jsonbCols.contains(key)) {
        if (value is String && value.isNotEmpty) {
          try {
            final decoded = jsonDecode(value);
            out[key] = decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : decoded;
          } catch (_) {
            out[key] = value;
          }
        } else if (value is Map) {
          out[key] = Map<String, dynamic>.from(value);
        } else {
          out[key] = value; // null → model handles gracefully
        }
      } else {
        out[key] = value;
      }
    });
    return out;
  }
}

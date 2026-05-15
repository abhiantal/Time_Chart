// ================================================================
// FILE: lib/features/analytics/leaderboard/repositories/leaderboard_repository.dart
//
// Fetches leaderboard data live from Supabase for ALL authenticated
// users whose profiles are public.
//
// NOT synced via PowerSync — PowerSync only holds the current user's
// own row, so we always go directly to Supabase for a global view.
//
// FETCH FLOW:
//   1. Query performance_analytics (RLS filters to public profiles)
//      selecting only id, user_id, overview, updated_at
//   2. Sort client-side by totalPoints descending
//   3. Assign sequential ranks (1, 2, 3 …) after sort
//   4. Batch-fetch user_profiles for display names / avatars
//   5. Build LeaderboardEntry per row with RewardManager.forGlobalRank()
// ================================================================

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../widgets/logger.dart';
import '../models/user_stats_model.dart';

class LeaderboardRepository {
  // ── Singleton ─────────────────────────────────────────────────
  static final LeaderboardRepository _instance =
  LeaderboardRepository._internal();
  factory LeaderboardRepository() => _instance;
  LeaderboardRepository._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  static const String _analyticsTable = 'performance_analytics';
  static const String _profilesTable  = 'user_profiles';

  // Max rows to fetch per request. 200 covers most apps comfortably.
  static const int _defaultLimit = 200;

  // ================================================================
  // GET LEADERBOARD (Static)
  // ================================================================

  Future<List<LeaderboardEntry>> getLeaderboard({
    int limit = _defaultLimit,
  }) async {
    try {
      final analyticsRows = await _supabase
          .from(_analyticsTable)
          .select('id, user_id, overview, rewards, updated_at')
          .limit(limit);

      return await _processRows(analyticsRows as List<dynamic>);
    } catch (e, s) {
      logE('[LeaderboardRepo] getLeaderboard error', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // WATCH LEADERBOARD (Real-time Stream)
  // Uses Supabase Realtime to push updates immediately.
  // ================================================================

  Stream<List<LeaderboardEntry>> watchLeaderboard({
    int limit = _defaultLimit,
  }) {
    return _supabase
        .from(_analyticsTable)
        .stream(primaryKey: ['id'])
        .limit(limit)
        .asyncMap((rows) async {
          logI('[LeaderboardRepo] Real-time stream event: ${rows.length} rows');
          return await _processRows(rows);
        });
  }

  // ================================================================
  // PRIVATE: PROCESS ROWS
  // Unified logic for both static fetch and real-time stream.
  // ================================================================

  Future<List<LeaderboardEntry>> _processRows(List<dynamic> rawRows) async {
    if (rawRows.isEmpty) return [];

    // 1. Decode and prepare
    final decoded = rawRows
        .map((r) => _decodeRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    // 2. Sort by totalPoints descending
    decoded.sort((a, b) {
      final apts = _summaryInt(a, 'total_points');
      final bpts = _summaryInt(b, 'total_points');
      return bpts.compareTo(apts);
    });

    final total = decoded.length;

    // 3. Batch-fetch profiles
    final userIds = decoded
        .map((r) => r['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profileMap = {};
    if (userIds.isNotEmpty) {
      try {
        final profiles = await _supabase
            .from(_profilesTable)
            .select('user_id, username, display_name, profile_url')
            .inFilter('user_id', userIds);

        for (final p in (profiles as List)) {
          final uid = p['user_id']?.toString() ?? '';
          if (uid.isNotEmpty) {
            profileMap[uid] = Map<String, dynamic>.from(p as Map);
          }
        }
      } catch (e) {
        logW('[LeaderboardRepo] Profile fetch failed: $e');
      }
    }

    // 4. Build LeaderboardEntry per row
    final List<LeaderboardEntry> entries = [];
    for (int i = 0; i < decoded.length; i++) {
      try {
        final row     = decoded[i];
        final rank    = i + 1;
        final uid     = row['user_id']?.toString() ?? '';
        final profile = profileMap[uid];

        entries.add(LeaderboardEntry.fromRow(
          row,
          username:          profile?['username']     as String? ?? '',
          displayName:       profile?['display_name'] as String?,
          avatarUrl:         profile?['profile_url']  as String?,
          rank:              rank,
          totalParticipants: total,
        ));
      } catch (e) {
        logW('[LeaderboardRepo] Failed to parse row $i: $e');
      }
    }

    return entries;
  }

  // ================================================================
  // GET SINGLE USER ENTRY
  // Refreshes just the current user's row and returns their entry
  // with the correct rank from the provided [currentRank].
  // Used by the provider to update the current user tile after they
  // complete a task without re-fetching the entire leaderboard.
  // ================================================================

  Future<LeaderboardEntry?> getUserEntry({
    required String userId,
    required int currentRank,
    required int totalParticipants,
  }) async {
    if (userId.isEmpty) return null;
    try {
      final rows = await _supabase
          .from(_analyticsTable)
          .select('id, user_id, overview, rewards, updated_at')
          .eq('user_id', userId)
          .limit(1);

      if ((rows as List).isEmpty) return null;

      final row = _decodeRow(Map<String, dynamic>.from(rows.first as Map));

      // Fetch profile separately
      String  username    = '';
      String? displayName;
      String? avatarUrl;
      try {
        final p = await _supabase
            .from(_profilesTable)
            .select('username, display_name, profile_url')
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();

        if (p != null) {
          username    = p['username']     as String? ?? '';
          displayName = p['display_name'] as String?;
          avatarUrl   = p['profile_url']  as String?;
        }
      } catch (_) {}

      return LeaderboardEntry.fromRow(
        row,
        username:          username,
        displayName:       displayName,
        avatarUrl:         avatarUrl,
        rank:              currentRank > 0 ? currentRank : 1,
        totalParticipants: totalParticipants,
      );
    } catch (e, s) {
      logE('[LeaderboardRepo] getUserEntry error', error: e, stackTrace: s);
      return null;
    }
  }

  // ================================================================
  // PRIVATE HELPERS
  // ================================================================

  /// Decode the overview column: may arrive as a JSON string (SQLite)
  /// or already as a Map (Supabase JSONB).
  Map<String, dynamic> _decodeRow(Map<String, dynamic> row) {
    final raw = row['overview'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        row['overview'] = d is Map ? Map<String, dynamic>.from(d) : {};
      } catch (_) {
        row['overview'] = {};
      }
    } else if (raw is Map && raw is! Map<String, dynamic>) {
      row['overview'] = Map<String, dynamic>.from(raw);
    }
    return row;
  }

  /// Read an int from overview → summary safely.
  int _summaryInt(Map<String, dynamic> row, String key) {
    try {
      final overview = row['overview'];
      if (overview is! Map) return 0;
      final summary = overview['summary'];
      if (summary is! Map) return 0;
      return (summary[key] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
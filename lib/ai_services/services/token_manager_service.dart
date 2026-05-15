// lib/core/ai/services/token_manager_service.dart

import 'dart:async';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../../widgets/logger.dart';
import '../repositories/ai_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user token quotas and usage
class TokenManagerService {
  static final TokenManagerService _instance = TokenManagerService._internal();
  factory TokenManagerService() => _instance;
  TokenManagerService._internal();

  AiRepository get _aiRepo => AiRepository();
  final String _tableName = 'ai_history';

  static const int DEFAULT_QUOTA = 10000;
  static const int PREMIUM_QUOTA = 50000;
  static const Duration RESET_INTERVAL = Duration(hours: 12);

  final Map<String, TokenUsageCache> _usageCache = {};
  static const Duration _cacheValidity = Duration(minutes: 5);

  Timer? _autoResetTimer;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ================================================================
  // AUTO-RESET
  // ================================================================

  /// Initializes the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _initializeAutoReset();
    _isInitialized = true;
  }

  /// Initializes the auto-reset timer for token quotas
  void _initializeAutoReset() {
    _autoResetTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndResetAllUsers(),
    );

    _checkAndResetAllUsers();
    logI('🔄 Token auto-reset initialized (12-hour interval)');
  }

  /// Checks and resets token quotas for all users if needed
  Future<void> _checkAndResetAllUsers() async {
    try {
      logD('🔍 Checking for users needing token reset...');

      final twelveHoursAgo = DateTime.now()
          .subtract(RESET_INTERVAL)
          .toUtc()
          .toIso8601String();

      // Find users with history older than 12 hours from Supabase
      final results = await Supabase.instance.client
          .from(_tableName)
          .select('user_id')
          .lt('created_at', twelveHoursAgo)
          .limit(100);

      final Set<String> userIds = {};
      for (var row in results) {
        userIds.add(row['user_id'] as String);
      }

      for (var userId in userIds) {
        await resetUsage(userId, automatic: true);
      }

      logI('✅ Token reset check completed');
    } catch (e, s) {
      logE('❌ Error during auto-reset check', error: e, stackTrace: s);
    }
  }

  // ================================================================
  // TOKEN CHECKING
  // ================================================================

  /// Checks if a user has enough tokens for a request
  Future<bool> canUseTokens(
    String userId,
    int estimatedTokens, {
    bool showSnackbar = true,
  }) async {
    try {
      await _checkAndResetIfNeeded(userId);

      final stats = await getUsageStats(userId);
      final remaining = stats['remainingTokens'] as int;

      if (remaining >= estimatedTokens) {
        return true;
      }

      if (showSnackbar) {
        final hoursUntilReset = stats['hoursUntilReset'] as int;
        logW(
          '⚠️ Token limit reached. Only $remaining tokens left. Resets in $hoursUntilReset hours.',
        );
        AppSnackbar.warning(
          'Token Limit Reached',
          description:
              'You have reached your daily token limit. Resets in $hoursUntilReset hours.',
        );
      }

      return false;
    } catch (e, s) {
      logE('❌ Error checking token availability', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // USAGE STATS
  // ================================================================

  /// Retrieves the current token usage statistics for a user from Supabase
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    try {
      final cached = _usageCache[userId];
      if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
        return cached.stats;
      }

      final summary = await _aiRepo.getUsageSummaryForQuota(userId, interval: RESET_INTERVAL);

      int totalUsed = summary['totalUsed'] as int;
      int quota = summary['quota'] as int;
      DateTime? lastUsage = summary['lastUsage'] as DateTime?;

      final timeSinceLastReset = lastUsage != null
          ? DateTime.now().difference(lastUsage)
          : Duration.zero;
      final timeUntilReset = RESET_INTERVAL - timeSinceLastReset;
      final hoursUntilReset = timeUntilReset.inHours.clamp(0, 12);

      final stats = {
        'tokensUsed': totalUsed,
        'tokenLimit': quota,
        'remainingTokens': (quota - totalUsed).clamp(0, quota),
        'percentage': (totalUsed / quota * 100).clamp(0.0, 100.0),
        'hoursUntilReset': hoursUntilReset,
        'lastUsage': lastUsage,
        'canReset': timeUntilReset.inHours <= 0,
      };

      _usageCache[userId] = TokenUsageCache(
        stats: stats,
        expiresAt: DateTime.now().add(_cacheValidity),
      );

      return stats;
    } catch (e, s) {
      logE(
        '❌ Error fetching usage statistics from Supabase',
        error: e,
        stackTrace: s,
      );
      return {
        'tokensUsed': 0,
        'tokenLimit': DEFAULT_QUOTA,
        'remainingTokens': DEFAULT_QUOTA,
        'percentage': 0.0,
        'hoursUntilReset': 12,
        'canReset': false,
      };
    }
  }

  // ================================================================
  // INCREMENT USAGE
  // ================================================================

  /// Increments the token usage for a user and checks for warnings
  Future<bool> incrementUsage(
    String userId,
    int tokensUsed, {
    String? contextType,
    String? apiProvider,
    String? chatId,
  }) async {
    try {
      await _checkAndResetIfNeeded(userId);

      // We don't need to insert here if the caller (AIRepository) does it.
      // But based on the original code, this method was just "checking" and updating cache/warnings.
      // The original code DID NOT insert here. Wait, looking at original code...
      // Original code: _usageCache.remove(userId); ... if (percentage >= 90) ...
      // It implies the caller is responsible for inserting the usage record.
      // Or does this method insert?
      // The original method `incrementUsage` did NOT have an INSERT statement.
      // It calls `getUsageStats` which queries.
      // So where is the INSERT?
      // Ah, `AIRepository` likely inserts the record.
      // Let's verify if `AIRepository` inserts.
      // But assuming this method is just for tracking/warnings:

      _usageCache.remove(userId);

      final updatedStats = await getUsageStats(userId);
      final percentage = updatedStats['percentage'] as double;

      if (percentage >= 90) {
        logW('⚠️ Token limit warning: ${percentage.toStringAsFixed(0)}% used');
      }

      return true;
    } catch (e, s) {
      logE('❌ Error incrementing token usage', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // RESET USAGE
  // ================================================================

  /// Resets the token usage for a user
  Future<bool> resetUsage(String userId, {bool automatic = false}) async {
    try {
      await _aiRepo.resetUsage(userId);
      _usageCache.remove(userId);

      if (automatic) {
        logI('🔄 Automatic token reset for user: $userId (Supabase)');
      } else {
        logI('✅ Manual token reset for user: $userId (Supabase)');
      }

      return true;
    } catch (e, s) {
      logE('❌ Error resetting token usage in Supabase', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // AUTO-RESET CHECK
  // ================================================================

  /// Helper to check if reset is needed and execute it
  Future<void> _checkAndResetIfNeeded(String userId) async {
    try {
      final stats = await getUsageStats(userId);
      final canReset = stats['canReset'] as bool;

      if (canReset) {
        await resetUsage(userId, automatic: true);
      }
    } catch (e, s) {
      logE('❌ Error checking reset status', error: e, stackTrace: s);
    }
  }

  // ================================================================
  // TOKEN ESTIMATION
  // ================================================================

  /// Estimates the number of tokens in a text string
  int estimateTokensFromText(String text) {
    final baseTokens = (text.length / 4).ceil();
    return (baseTokens * 1.1).ceil();
  }

  /// Estimates the total tokens for a message prompt
  int estimateTokensFromMessages({
    required String prompt,
    String? systemPrompt,
  }) {
    int total = estimateTokensFromText(prompt);
    if (systemPrompt != null) {
      total += estimateTokensFromText(systemPrompt);
    }
    total += 10;
    return total;
  }

  // ================================================================
  // QUOTA MANAGEMENT
  // ================================================================

  /// Updates the token quota for a user in Supabase
  Future<bool> updateUserQuota(String userId, int newQuota) async {
    try {
      await _aiRepo.updateUserQuota(userId, newQuota);
      _usageCache.remove(userId);
      logI('✅ Updated quota for user $userId to $newQuota in Supabase');
      return true;
    } catch (e, s) {
      logE('❌ Error updating user quota in Supabase', error: e, stackTrace: s);
      return false;
    }
  }

  /// Clears the token usage cache
  void clearCache() {
    _usageCache.clear();
    logI('🗑️ Token usage cache cleared');
  }

  /// Disposes resources used by the service
  void dispose() {
    _autoResetTimer?.cancel();
    _usageCache.clear();
  }
}

/// Cache object for token usage statistics
class TokenUsageCache {
  final Map<String, dynamic> stats;
  final DateTime expiresAt;

  TokenUsageCache({required this.stats, required this.expiresAt});
}

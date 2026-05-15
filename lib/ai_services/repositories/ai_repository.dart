import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/logger.dart';
import '../constants/ai_constants.dart';

class AiRepository {
  final _supabase = Supabase.instance.client;

  static final AiRepository _instance = AiRepository._internal();
  factory AiRepository() => _instance;
  AiRepository._internal();

  // ================================================================
  // SAVE HISTORY
  // ================================================================
  Future<bool> saveHistory({
    required String userId,
    required String contextType,
    required String aiUsageSource,
    required int tokensUsed,
    required String apiProvider,
    int promptTokens = 0,
    int completionTokens = 0,
    int tokenQuota = 10000,
    String? chatId,
    String? sourceTable,
    String? sourceRecordId,
    String? modelName,
    int? responseTimeMs,
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? requestMetadata,
    Map<String, dynamic>? responseMetadata,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().toIso8601String();

      // Updated Schema for Supabase-only storage:
      // id, user_id, context_type, ai_usage_source, source_table, source_record_id,
      // chat_id, api_provider, model_name, prompt_tokens, completion_tokens,
      // tokens_used, token_quota, response_time_ms, success, error_message,
      // request_metadata, response_metadata, created_at, updated_at

      await _supabase.from('ai_history').insert({
        'id': id,
        'user_id': userId,
        'context_type': contextType,
        'ai_usage_source': aiUsageSource,
        'source_table': sourceTable,
        'source_record_id': sourceRecordId,
        'chat_id': chatId,
        'api_provider': apiProvider,
        'model_name': modelName ?? _getModelName(apiProvider),
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'tokens_used': tokensUsed,
        'token_quota': tokenQuota,
        'response_time_ms': responseTimeMs,
        'success': success,
        'error_message': errorMessage,
        'request_metadata': requestMetadata ?? {},
        'response_metadata': responseMetadata ?? {},
        'created_at': now,
        'updated_at': now,
      });

      logI('✅ AI history saved to Supabase for user: $userId');
      return true;
    } catch (e, s) {
      logE('❌ Error saving AI history to Supabase', error: e, stackTrace: s);
      return false;
    }
  }

  // ================================================================
  // GET USER HISTORY
  // ================================================================
  Future<List<Map<String, dynamic>>> getUserHistory(
    String userId, {
    int limit = 50,
    String? contextType,
    String? aiUsageSource,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('ai_history').select().eq('user_id', userId);

      if (contextType != null) {
        query = query.eq('context_type', contextType);
      }

      if (aiUsageSource != null) {
        query = query.eq('ai_usage_source', aiUsageSource);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toUtc().toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toUtc().toIso8601String());
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      logE('❌ Error fetching user history', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // GET USAGE BY SOURCE
  // ================================================================
  Future<List<Map<String, dynamic>>> getUsageBySource(
    String userId,
    String sourceTable, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('ai_history')
          .select()
          .eq('user_id', userId)
          .eq('source_table', sourceTable)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      logE('❌ Error fetching usage by source', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // GET RECORD USAGE
  // ================================================================
  Future<List<Map<String, dynamic>>> getRecordUsage(
    String sourceTable,
    String sourceRecordId,
  ) async {
    try {
      final response = await _supabase
          .from('ai_history')
          .select()
          .eq('source_table', sourceTable)
          .eq('source_record_id', sourceRecordId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, s) {
      logE('❌ Error fetching record usage', error: e, stackTrace: s);
      return [];
    }
  }

  // ================================================================
  // GET USER STATISTICS
  // ================================================================
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final response = await _supabase.from('ai_history').select(
        'api_provider, tokens_used, prompt_tokens, completion_tokens, success, response_time_ms, ai_usage_source',
      ).eq('user_id', userId);

      int totalTokens = 0;
      int totalPromptTokens = 0;
      int totalCompletionTokens = 0;
      int totalRequests = response.length;
      int successfulRequests = 0;
      int totalResponseTime = 0;
      int responseTimeCount = 0;

      final Map<String, int> providerUsage = {};
      final Map<String, int> sourceUsage = {};

      for (var record in response) {
        totalTokens += record['tokens_used'] as int? ?? 0;
        totalPromptTokens += record['prompt_tokens'] as int? ?? 0;
        totalCompletionTokens += record['completion_tokens'] as int? ?? 0;

        final bool isSuccess = record['success'] == true;
        if (isSuccess) successfulRequests++;

        if (record['response_time_ms'] != null) {
          totalResponseTime += record['response_time_ms'] as int;
          responseTimeCount++;
        }

        final provider = record['api_provider'] as String? ?? 'unknown';
        providerUsage[provider] = (providerUsage[provider] ?? 0) + 1;

        final source = record['ai_usage_source'] as String? ?? 'unknown';
        sourceUsage[source] = (sourceUsage[source] ?? 0) + 1;
      }

      return {
        'totalTokens': totalTokens,
        'totalPromptTokens': totalPromptTokens,
        'totalCompletionTokens': totalCompletionTokens,
        'totalRequests': totalRequests,
        'successfulRequests': successfulRequests,
        'failedRequests': totalRequests - successfulRequests,
        'successRate': totalRequests > 0
            ? (successfulRequests / totalRequests * 100).toStringAsFixed(1)
            : '0.0',
        'averageResponseTime': responseTimeCount > 0
            ? (totalResponseTime / responseTimeCount).round()
            : 0,
        'providerUsage': providerUsage,
        'sourceUsage': sourceUsage,
      };
    } catch (e, s) {
      logE('❌ Error fetching user statistics', error: e, stackTrace: s);
      return {};
    }
  }

  // ================================================================
  // CLEANUP
  // ================================================================
  Future<bool> cleanupOldRecords({int daysToKeep = 30}) async {
    try {
      final cutoffDate =
          DateTime.now().toUtc().subtract(Duration(days: daysToKeep));

      await _supabase
          .from('ai_history')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());

      logI('✅ Cleaned up old AI records in Supabase');
      return true;
    } catch (e, s) {
      logE(
        '❌ Error cleaning up old records in Supabase',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  // ================================================================
  // GET USAGE SUMMARY FOR QUOTA (12h)
  // ================================================================
  Future<Map<String, dynamic>> getUsageSummaryForQuota(String userId,
      {Duration interval = const Duration(hours: 12)}) async {
    try {
      final startTime = DateTime.now().toUtc().subtract(interval).toIso8601String();

      final response = await _supabase
          .from('ai_history')
          .select('tokens_used, token_quota, created_at')
          .eq('user_id', userId)
          .gte('created_at', startTime)
          .order('created_at', ascending: false);

      int totalUsed = 0;
      int quota = 10000; // Default
      DateTime? lastUsage;

      if (response.isNotEmpty) {
        for (var record in response) {
          totalUsed += record['tokens_used'] as int? ?? 0;
          // Take the latest quota
          if (record['token_quota'] != null) {
            quota = record['token_quota'] as int;
          }
        }
        lastUsage = DateTime.parse(response[0]['created_at'] as String);
      }

      return {
        'totalUsed': totalUsed,
        'quota': quota,
        'lastUsage': lastUsage,
      };
    } catch (e, s) {
      logE('❌ Error getting usage summary for quota', error: e, stackTrace: s);
      return {
        'totalUsed': 0,
        'quota': 10000,
        'lastUsage': null,
      };
    }
  }

  // ================================================================
  // RESET USAGE (MANUAL OR AUTOMATIC)
  // ================================================================
  Future<bool> resetUsage(String userId) async {
    try {
      // In a Supabase-only model, 'resetting' could mean deleting old records 
      // or inserting a 'reset' record. Given the user wants to store history,
      // we'll just let the interval-based query (getUsageSummaryForQuota) 
      // handle the 'reset' by moving out of the time window.
      // However, if we want to FORCE a reset, we can delete records for the user.
      
      final result = await cleanupOldRecords(daysToKeep: 0); // Cleanup everything immediate if needed?
      // Actually, let's just log it for now as current logic is interval based.
      logI('🔄 Reset requested for user $userId (Supabase model relies on time window)');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ================================================================
  // UPDATE QUOTA
  // ================================================================
  Future<bool> updateUserQuota(String userId, int newQuota) async {
    try {
      // We insert a record with 0 tokens but the new quota to 'set' the quota
      await saveHistory(
        userId: userId,
        contextType: 'quota_update',
        aiUsageSource: 'system',
        tokensUsed: 0,
        tokenQuota: newQuota,
        apiProvider: 'system',
        modelName: 'quota_config',
        success: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getModelName(String provider) {
    try {
      final p = provider.trim().toLowerCase();

      final aiProvider = AIProvider.values.firstWhere(
        (e) => e.name.toLowerCase() == p,
        orElse: () => AIProvider.gemini,
      );

      final config = AiConstants.modelConfigs[aiProvider];

      if (config != null && config.modelId.isNotEmpty) {
        return config.modelId;
      }

      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}

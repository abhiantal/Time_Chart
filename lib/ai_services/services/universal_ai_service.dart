// lib/core/ai/services/universal_ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/logger.dart';
import '../../widgets/error_handler.dart';
import '../models/ai_response_model.dart';
import '../constants/ai_constants.dart';
import '../repositories/ai_repository.dart';
import 'token_manager_service.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';

class UniversalAIService {
  static final UniversalAIService _instance = UniversalAIService._internal();
  factory UniversalAIService() => _instance;
  UniversalAIService._internal();

  AIProvider currentProvider = AiConstants.defaultProvider;

  final Map<AIProvider, ProviderHealth> _providerHealth = {
    AIProvider.gemini: ProviderHealth(),
    AIProvider.groq: ProviderHealth(),
    AIProvider.openai: ProviderHealth(),
    AIProvider.claude: ProviderHealth(),
  };

  final Map<String, CachedResponse> _responseCache = {};
  static const Duration _cacheTTL = Duration(hours: 1);
  static const int _maxCacheSize = 100;

  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  // ================================================================
  // SPECIALIZED METHODS
  // ================================================================

  /// Verify task completion using media analysis
  Future<Map<String, dynamic>> verifyTaskWithMedia({
    required List<String> mediaUrls,
    required String taskDescription,
    required Map<String, dynamic> timeline,
    required String expectedOutcome,
  }) async {
    final prompt =
        '''
Analyze these media items to verify task completion.
Task: $taskDescription
Outcome: $expectedOutcome
Timeline: ${jsonEncode(timeline)}
Media URLs:
${mediaUrls.map((u) => '- $u').join('\n')}

STRICT AUTHENTICITY CHECK:
1. RELEVANCE: Is the media clearly related to the task "$taskDescription"? If it's random/generic (e.g., a selfie when the task is "Coding", or random text), it FAILS.
2. SUFFICIENCY: Consider the task duration. A 5-hour task requires substantial evidence. One low-effort feedback item for a long task should result in lower progress/rating.
3. AUTHENTICITY: Is this evidence genuine proof of work?

Media priority: Video > Image > Audio > Text.

Return ONLY a JSON object with this structure:
{
  "progress": 0-100, (Be strict. High progress only for high-quality, relevant evidence)
  "rating": 1.0-5.0, (1.0 for fakes, 5.0 for perfect proof)
  "summary": "2 sentences summary of proof quality",
  "isCompleted": boolean, (False if evidence is random, fake, or totally insufficient)
  "confidence": 0-100,
  "reason": "Brief explanation of authenticity/relevance finding"
}
''';

    final response = await generateResponse(
      prompt: prompt,
      systemPrompt: 'You are a strict task verification AI. Output JSON only.',
      maxTokens: 500,
      temperature: 0.3,
      contextType: 'verification',
      aiUsageSource: 'task_verification',
    );

    if (response.isSuccess) {
      try {
        final cleanJson = response.response
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanJson);
      } catch (e) {
        logE('Failed to parse verification JSON: $e');
      }
    }

    // Fallback
    return {
      'progress': 0,
      'rating': 0.0,
      'summary': 'Verification failed due to AI error.',
      'isCompleted': false,
      'confidence': 0,
      'reason': 'AI service unavailable',
    };
  }

  /// Verify multiple feedback items for a task in a single AI call
  Future<List<Map<String, dynamic>>> batchVerifyFeedbacks({
    required String taskDescription,
    required List<Map<String, dynamic>> feedbacks,
    required Map<String, dynamic> timeline,
    required String expectedOutcome,
  }) async {
    if (feedbacks.isEmpty) return [];

    final feedbacksJson = jsonEncode(feedbacks.map((f) => {
      'text': f['text'],
      'mediaUrls': f['mediaUrls'],
      'timestamp': f['timestamp'],
    }).toList());

    final prompt = '''
Analyze these feedback entries for the task: "$taskDescription".
Expected Outcome: $expectedOutcome
Timeline: ${jsonEncode(timeline)}

Feedbacks to verify:
$feedbacksJson

STRICT AUTHENTICITY CHECK:
For EACH feedback entry, determine if it is a PASS or FAIL based on:
1. RELEVANCE: Does the text and media provide genuine proof of working on "$taskDescription"?
2. AUTHENTICITY: Is this unique evidence, or just random filler?

Return a JSON object with a "results" array. Each item in "results" must match the index of the feedback provided:
{
  "results": [
    {
      "index": 0,
      "isPass": boolean,
      "reason": "Brief explanation"
    },
    ...
  ]
}
''';

    final response = await generateResponse(
      prompt: prompt,
      systemPrompt: 'You are a strict task verification AI. Output JSON only.',
      maxTokens: 1000,
      temperature: 0.2,
      contextType: 'verification',
      aiUsageSource: 'batch_task_verification',
    );

    if (response.isSuccess) {
      try {
        final cleanJson = response.response
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final data = jsonDecode(cleanJson);
        return List<Map<String, dynamic>>.from(data['results']);
      } catch (e) {
        logE('Failed to parse batch verification JSON: $e');
      }
    }

    // Fallback: Fail all if AI fails
    return feedbacks.asMap().entries.map((e) => {
      'index': e.key,
      'isPass': false,
      'reason': 'AI verification failed'
    }).toList();
  }


  // ================================================================
  // MAIN METHOD
  // ================================================================
  Future<AiResponseModel> generateResponse({
    required String prompt,
    String? systemPrompt,
    bool useCache = true,
    AIProvider? preferredProvider,
    int maxTokens = 2048,
    double temperature = 0.7,
    String? chatId,
    String? sourceTable,
    String? sourceRecordId,
    String contextType = 'chat',
    String aiUsageSource = 'app',
  }) async {
    // 1. Check if AI is enabled in settings
    final settings = SettingsProvider();
    if (!settings.ai.enabled) {
      logW('AI request blocked: AI features are disabled in settings');
      return AiResponseModel(
        isSuccess: false,
        response: 'AI features are disabled in App Settings.',
        error: 'AI Disabled',
        totalTokens: 0,
        provider: preferredProvider ?? currentProvider,
        processingTime: Duration.zero,
      );
    }

    // 2. Apply Response Style from settings
    final style = settings.ai.responseStyle;
    String styleInstruction = '';
    switch (style.name) {
      case 'concise':
        styleInstruction =
            'Response Style: concise, direct, and to the point. Avoid fluff.';
        break;
      case 'detailed':
        styleInstruction =
            'Response Style: detailed, comprehensive, and explanatory.';
        break;
      case 'creative':
        styleInstruction =
            'Response Style: creative, engaging, and imaginative.';
        break;
      case 'formal':
        styleInstruction =
            'Response Style: formal, professional, and structured.';
        break;
      // 'normal' or default adds nothing/default behavior
    }

    final effectiveSystemPrompt = systemPrompt != null
        ? '$systemPrompt\n\n$styleInstruction'
        : styleInstruction;

    final startTime = DateTime.now();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      final estimatedTokens = TokenManagerService().estimateTokensFromMessages(
        prompt: prompt,
        systemPrompt: effectiveSystemPrompt,
      );

      final canUse = await TokenManagerService().canUseTokens(
        userId,
        estimatedTokens,
      );

      if (!canUse) {
        return AiResponseModel(
          isSuccess: false,
          response: 'Token limit reached',
          error: 'Token limit reached',
          totalTokens: 0,
          provider: preferredProvider ?? currentProvider,
          processingTime: Duration.zero,
        );
      }
    }

    try {
      final provider = preferredProvider ?? currentProvider;

      logI(
        '🤖 AI Request - Provider: ${provider.name}, Prompt length: ${prompt.length}',
      );

      // Check cache
      if (useCache) {
        final cacheKey = _generateCacheKey(prompt + effectiveSystemPrompt);
        final cached = _getCachedResponse(cacheKey);

        if (cached != null) {
          logD('✅ Cache hit - returning cached response');

          return AiResponseModel(
            isSuccess: true,
            response: cached,
            totalTokens: 0,
            provider: provider,
            processingTime: Duration(milliseconds: 1),
            fromCache: true,
          );
        }
      }

      // FIXED: Check provider health BEFORE trying
      if (_providerHealth[provider]!.health < 20) {
        logW('! Provider ${provider.name} health too low, switching...');
        currentProvider = _getBestProvider();
      }

      // Try primary provider with retries
      final result = await _callProviderWithRetry(
        provider: currentProvider, // Use currentProvider (may have switched)
        prompt: prompt,
        systemPrompt: effectiveSystemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      if (result != null) {
        final processingTime = DateTime.now().difference(startTime);

        // Cache successful response
        if (useCache) {
          final cacheKey = _generateCacheKey(prompt + effectiveSystemPrompt);
          _cacheResponse(cacheKey, result['response']);
        }

        _updateProviderHealth(currentProvider, true);

        if (userId != null) {
          await AiRepository().saveHistory(
            userId: userId,
            contextType: contextType,
            aiUsageSource: aiUsageSource,
            tokensUsed: result['tokens'] ?? 0,
            promptTokens: result['prompt_tokens'] ?? 0,
            completionTokens: result['completion_tokens'] ?? 0,
            apiProvider: currentProvider.name,
            sourceTable: sourceTable,
            sourceRecordId: sourceRecordId,
            responseTimeMs: processingTime.inMilliseconds,
            success: true,
            requestMetadata: {
              'prompt_length': prompt.length,
              'system_prompt_length': effectiveSystemPrompt.length,
              'temperature': temperature,
              'max_tokens': maxTokens,
            },
            responseMetadata: {
              'from_cache': false,
            },
          );

          await TokenManagerService().incrementUsage(
            userId,
            result['tokens'] ?? 0,
            chatId: chatId,
            apiProvider: currentProvider.name,
          );
        }

        logI(
          '✅ AI Response - Tokens: ${result['tokens']}, Time: ${processingTime.inMilliseconds}ms',
        );

        return AiResponseModel(
          isSuccess: true,
          response: result['response'],
          totalTokens: result['tokens'] ?? 0,
          provider: currentProvider,
          processingTime: processingTime,
        );
      }

      // FIXED: Try fallbacks with better logic
      if (AiConstants.enableAutoFallback) {
        logW('! Primary provider failed, trying fallbacks...');

        for (final fallback in AiConstants.fallbackOrder) {
          // Skip if it's the provider we just tried
          if (fallback == currentProvider) continue;

          // Skip if provider is not configured
          final config = AiConstants.modelConfigs[fallback];
          if (config == null ||
              config.apiKey.isEmpty ||
              config.apiKey.startsWith('YOUR_')) {
            logD('⚠️ Skipping ${fallback.name}: Not configured');
            continue;
          }

          // FIXED: Only skip if health is 0 AND it failed recently (within last 5 minutes)
          final health = _providerHealth[fallback]!;
          if (health.health == 0 && health.lastFailure != null) {
            final timeSinceFailure = DateTime.now().difference(
              health.lastFailure!,
            );
            if (timeSinceFailure.inMinutes < 5) {
              logD(
                '⚠️ Skipping ${fallback.name}: Recently failed (${timeSinceFailure.inMinutes}m ago)',
              );
              continue;
            } else {
              // Been a while, let's try again
              logI(
                '🔄 Retrying ${fallback.name} (last failure was ${timeSinceFailure.inMinutes}m ago)',
              );
              health.health = 50; // Give it another chance
            }
          }

          logI('🔄 Trying fallback provider: ${fallback.name}');

          final fallbackResult = await _callProviderWithRetry(
            provider: fallback,
            prompt: prompt,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            temperature: temperature,
          );

          if (fallbackResult != null) {
            _updateProviderHealth(fallback, true);
            currentProvider = fallback; // Switch to working provider
            logI('✅ Fallback successful with ${fallback.name}');

            if (userId != null) {
              final fallbackTime = DateTime.now().difference(startTime).inMilliseconds;
              await AiRepository().saveHistory(
                userId: userId,
                contextType: contextType,
                aiUsageSource: aiUsageSource,
                tokensUsed: fallbackResult['tokens'] ?? 0,
                promptTokens: fallbackResult['prompt_tokens'] ?? 0,
                completionTokens: fallbackResult['completion_tokens'] ?? 0,
                apiProvider: fallback.name,
                sourceTable: sourceTable,
                sourceRecordId: sourceRecordId,
                responseTimeMs: fallbackTime,
                success: true,
                requestMetadata: {
                  'prompt_length': prompt.length,
                  'system_prompt_length': systemPrompt?.length ?? 0,
                  'temperature': temperature,
                  'max_tokens': maxTokens,
                  'is_fallback': true,
                  'primary_provider': provider.name,
                },
                responseMetadata: {
                  'from_cache': false,
                },
              );

              await TokenManagerService().incrementUsage(
                userId,
                fallbackResult['tokens'] ?? 0,
                chatId: chatId,
                apiProvider: fallback.name,
              );
            }

            return AiResponseModel(
              isSuccess: true,
              response: fallbackResult['response'],
              totalTokens: fallbackResult['tokens'] ?? 0,
              provider: fallback,
              processingTime: DateTime.now().difference(startTime),
            );
          } else {
            logW('❌ Fallback ${fallback.name} also failed');
          }
        }
      }

      throw Exception('All AI providers failed');
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'UniversalAIService.generateResponse',
      );

      return AiResponseModel(
        isSuccess: false,
        response: 'An unexpected error occurred while generating the response.',
        error: e.toString(),
        totalTokens: 0,
        provider: preferredProvider ?? currentProvider,
        processingTime: DateTime.now().difference(startTime),
      );
    }
  }

  // ================================================================
  // RETRY LOGIC - FIXED
  // ================================================================
  Future<Map<String, dynamic>?> _callProviderWithRetry({
    required AIProvider provider,
    required String prompt,
    String? systemPrompt,
    int maxTokens = 2048,
    double temperature = 0.7,
    int retryCount = 0,
  }) async {
    try {
      return await _callProvider(
        provider: provider,
        prompt: prompt,
        systemPrompt: systemPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      // FIXED: Don't retry on rate limit errors (429) or auth errors (401, 403)
      final errorStr = e.toString().toLowerCase();
      final is429 =
          errorStr.contains('429') || errorStr.contains('quota exceeded');
      final isAuthError = errorStr.contains('401') || errorStr.contains('403');

      if (is429 || isAuthError) {
        logE('❌ Provider ${provider.name} error (no retry): $e');
        _updateProviderHealth(provider, false);
        return null;
      }

      // Retry for other errors
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (retryCount + 1);
        logW(
          '! Retry attempt ${retryCount + 1}/$_maxRetries after ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);

        return _callProviderWithRetry(
          provider: provider,
          prompt: prompt,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          temperature: temperature,
          retryCount: retryCount + 1,
        );
      }

      logE('❌ Max retries reached for ${provider.name}');
      return null;
    }
  }

  // ================================================================
  // PROVIDER ROUTING
  // ================================================================
  Future<Map<String, dynamic>?> _callProvider({
    required AIProvider provider,
    required String prompt,
    String? systemPrompt,
    int maxTokens = 2048,
    double temperature = 0.7,
  }) async {
    final config = AiConstants.modelConfigs[provider];
    if (config == null ||
        config.apiKey.isEmpty ||
        config.apiKey.startsWith('YOUR_')) {
      logW('⚠️ Provider ${provider.name} not configured');
      return null;
    }

    try {
      switch (provider) {
        case AIProvider.groq:
          return await _callGroq(
            prompt,
            systemPrompt,
            config,
            maxTokens,
            temperature,
          );
        case AIProvider.gemini:
          return await _callGemini(
            prompt,
            systemPrompt,
            config,
            maxTokens,
            temperature,
          );
        case AIProvider.openai:
          return await _callOpenAI(
            prompt,
            systemPrompt,
            config,
            maxTokens,
            temperature,
          );
        case AIProvider.claude:
          return await _callClaude(
            prompt,
            systemPrompt,
            config,
            maxTokens,
            temperature,
          );
        case AIProvider.mistral:
          return await _callMistral(
            prompt,
            systemPrompt,
            config,
            maxTokens,
            temperature,
          );
      }
    } catch (e) {
      _updateProviderHealth(provider, false);
      logW('❌ Provider ${provider.name} call failed: $e');
      rethrow;
    }
  }

  // ================================================================
  // MISTRAL
  // ================================================================
  Future<Map<String, dynamic>?> _callMistral(
    String prompt,
    String? systemPrompt,
    AIModelConfig config,
    int maxTokens,
    double temperature,
  ) async {
    final url = Uri.parse('${config.baseUrl}/chat/completions');

    final messages = [
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          body: jsonEncode({
            'models': config.modelId,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'response': data['choices'][0]['message']['content'],
        'tokens': data['usage']['total_tokens'] ?? 0,
        'prompt_tokens': data['usage']['prompt_tokens'] ?? 0,
        'completion_tokens': data['usage']['completion_tokens'] ?? 0,
      };
    } else {
      throw Exception(
        'Mistral API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ================================================================
  // GROQ
  // ================================================================
  Future<Map<String, dynamic>?> _callGroq(
    String prompt,
    String? systemPrompt,
    AIModelConfig config,
    int maxTokens,
    double temperature,
  ) async {
    final url = Uri.parse('${config.baseUrl}/chat/completions');

    final messages = [
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          body: jsonEncode({
            'model': config.modelId,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'response': data['choices'][0]['message']['content'],
        'tokens': data['usage']['total_tokens'] ?? 0,
        'prompt_tokens': data['usage']['prompt_tokens'] ?? 0,
        'completion_tokens': data['usage']['completion_tokens'] ?? 0,
      };
    } else {
      throw Exception(
        'Groq API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ================================================================
  // GEMINI
  // ================================================================
  Future<Map<String, dynamic>?> _callGemini(
    String prompt,
    String? systemPrompt,
    AIModelConfig config,
    int maxTokens,
    double temperature,
  ) async {
    final url = Uri.parse(
      '${config.baseUrl}/models/${config.modelId}:generateContent',
    );

    final fullPrompt = systemPrompt != null
        ? '$systemPrompt\n\n$prompt'
        : prompt;

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': config.apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': fullPrompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': temperature,
              'maxOutputTokens': maxTokens,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      final totalTokens = _estimateTokens(fullPrompt + text);
      return {
        'response': text,
        'tokens': totalTokens,
        'prompt_tokens': _estimateTokens(fullPrompt),
        'completion_tokens': _estimateTokens(text),
      };
    } else {
      throw Exception(
        'Gemini API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ================================================================
  // OPENAI
  // ================================================================
  Future<Map<String, dynamic>?> _callOpenAI(
    String prompt,
    String? systemPrompt,
    AIModelConfig config,
    int maxTokens,
    double temperature,
  ) async {
    final url = Uri.parse('${config.baseUrl}/chat/completions');

    final messages = [
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': prompt},
    ];

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          body: jsonEncode({
            'models': config.modelId,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'response': data['choices'][0]['message']['content'],
        'tokens': data['usage']['total_tokens'] ?? 0,
        'prompt_tokens': data['usage']['prompt_tokens'] ?? 0,
        'completion_tokens': data['usage']['completion_tokens'] ?? 0,
      };
    } else {
      throw Exception(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ================================================================
  // CLAUDE
  // ================================================================
  Future<Map<String, dynamic>?> _callClaude(
    String prompt,
    String? systemPrompt,
    AIModelConfig config,
    int maxTokens,
    double temperature,
  ) async {
    final url = Uri.parse('${config.baseUrl}/messages');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'models': config.modelId,
            'max_tokens': maxTokens,
            'temperature': temperature,
            if (systemPrompt != null) 'system': systemPrompt,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'response': data['content'][0]['text'],
        'tokens':
            data['usage']['input_tokens'] + data['usage']['output_tokens'],
        'prompt_tokens': data['usage']['input_tokens'] ?? 0,
        'completion_tokens': data['usage']['output_tokens'] ?? 0,
      };
    } else {
      throw Exception(
        'Claude API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ================================================================
  // CACHE
  // ================================================================
  String? _getCachedResponse(String key) {
    final cached = _responseCache[key];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.response;
    }
    if (cached != null) {
      _responseCache.remove(key);
    }
    return null;
  }

  void _cacheResponse(String key, String response) {
    if (_responseCache.length >= _maxCacheSize) {
      final oldestKey = _responseCache.keys.first;
      _responseCache.remove(oldestKey);
    }

    _responseCache[key] = CachedResponse(
      response: response,
      expiresAt: DateTime.now().add(_cacheTTL),
    );
  }

  // ================================================================
  // HEALTH - FIXED
  // ================================================================
  void _updateProviderHealth(AIProvider provider, bool success) {
    final health = _providerHealth[provider]!;

    if (success) {
      health.health = (health.health + 10).clamp(0, 100);
      health.consecutiveFailures = 0;
      health.lastSuccess = DateTime.now();
      logI('✅ ${provider.name} health: ${health.health}');
    } else {
      health.health = (health.health - 25).clamp(0, 100);
      health.consecutiveFailures++;
      health.lastFailure = DateTime.now();
      logW(
        '⚠️ ${provider.name} health: ${health.health} (failures: ${health.consecutiveFailures})',
      );
    }
  }

  AIProvider _getBestProvider() {
    var bestProvider = currentProvider;
    var bestHealth = 0;

    for (final entry in _providerHealth.entries) {
      // Check if provider is configured
      final config = AiConstants.modelConfigs[entry.key];
      if (config == null ||
          config.apiKey.isEmpty ||
          config.apiKey.startsWith('YOUR_')) {
        continue;
      }

      if (entry.value.health > bestHealth) {
        bestHealth = entry.value.health;
        bestProvider = entry.key;
      }
    }

    logI(
      '🔄 Switching to best provider: ${bestProvider.name} (health: $bestHealth)',
    );
    return bestProvider;
  }

  // ================================================================
  // UTILITY
  // ================================================================
  void switchProvider(AIProvider provider) {
    currentProvider = provider;
    logI('🔄 Manually switched to provider: ${provider.name}');
  }

  Map<AIProvider, int> getProviderHealth() {
    return Map.fromEntries(
      _providerHealth.entries.map((e) => MapEntry(e.key, e.value.health)),
    );
  }

  void clearCache() {
    _responseCache.clear();
    logI('🗑️ Cache cleared');
  }

  void resetAllProviderHealth() {
    for (final provider in _providerHealth.keys) {
      _providerHealth[provider]!.health = 100;
      _providerHealth[provider]!.consecutiveFailures = 0;
    }
    logI('🔄 All provider health reset to 100');
  }

  String _generateCacheKey(String input) => input.hashCode.toString();
  int _estimateTokens(String text) => (text.length / 4).ceil();
}

// ================================================================
// HELPER CLASSES
// ================================================================
class CachedResponse {
  final String response;
  final DateTime expiresAt;

  CachedResponse({required this.response, required this.expiresAt});
}

class ProviderHealth {
  int health;
  int consecutiveFailures;
  DateTime? lastSuccess;
  DateTime? lastFailure;

  ProviderHealth({
    this.health = 100,
    this.consecutiveFailures = 0,
    this.lastSuccess,
    this.lastFailure,
  });
}

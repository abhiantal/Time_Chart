// lib/core/ai/constants/ai_constants.dart
import 'package:the_time_chart/widgets/logger.dart';

import '../../config/env_config.dart';

enum AIProvider { groq, gemini, openai, claude, mistral }

class AIModelConfig {
  final String apiKey;
  final String baseUrl;
  final String modelId;
  final int maxTokens;
  final double temperature;

  const AIModelConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.modelId,
    this.maxTokens = 4096,
    this.temperature = 0.7,
  });

  // Check if this provider is properly configured
  bool get isConfigured =>
      apiKey.isNotEmpty && !apiKey.startsWith('YOUR_') && apiKey.length > 10;
}

class AiConstants {
  // ================================================================
  // IMPORTANT: Set this to a provider you have configured!
  // ================================================================
  static const AIProvider defaultProvider = AIProvider.groq;

  // Enable automatic fallback to other providers
  static const bool enableAutoFallback = true;

  // Fallback order when primary provider fails
  static const List<AIProvider> fallbackOrder = [
    AIProvider.groq, // Try Groq first (free & fast)
    AIProvider.gemini, // Then Gemini (free tier)
    AIProvider.openai, // Then OpenAI (paid but reliable)
    AIProvider.claude, // Finally Claude (paid, high quality)
  ];

  // ========================
  // 🔐 Model configurations
  // ========================
  static Map<AIProvider, AIModelConfig> get modelConfigs {
    // final configs = {
    //
    //   AIProvider.groq: AIModelConfig(
    //     apiKey: EnvConfig.groqApiKey,
    //     baseUrl: 'https://api.groq.com/openai/v1',
    //     modelId: 'llama-3.3-70b-versatile',
    //     maxTokens: 4096,
    //     temperature: 0.7,
    //   ),
    //   AIProvider.gemini: AIModelConfig(
    //     apiKey: EnvConfig.geminiApiKey,
    //     baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    //     modelId: 'gemini-1.5-flash',
    //     maxTokens: 8192,
    //     temperature: 0.7,
    //   ),
    //   AIProvider.openai: AIModelConfig(
    //     apiKey: EnvConfig.openaiApiKey,
    //     baseUrl: 'https://api.openai.com/v1',
    //     modelId: 'gpt-4o-mini',
    //     maxTokens: 4096,
    //     temperature: 0.7,
    //   ),
    //   AIProvider.claude: AIModelConfig(
    //     apiKey: EnvConfig.claudeApiKey,
    //     baseUrl: 'https://api.anthropic.com/v1',
    //     modelId: 'claude-3-5-sonnet-20241022',
    //     maxTokens: 4096,
    //     temperature: 0.7,
    //   ),
    // };

    // DEBUG: Print which providers are configured

    final configs = {
      // ⚡ HIGH-VOLUME TASKS (90% LOAD)
      // Suggestions, planning, chat, summaries
      AIProvider.groq: AIModelConfig(
        apiKey: EnvConfig.groqApiKey,
        baseUrl: 'https://api.groq.com/openai/v1',
        modelId: 'llama-3.3-70b-versatile',
        maxTokens: 4096,
        temperature: 0.6,
      ),

      // 👀 MEDIA VISION FALLBACK
      // Image / video understanding when OpenAI is busy
      AIProvider.gemini: AIModelConfig(
        apiKey: EnvConfig.geminiApiKey,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        modelId: 'gemini-1.5-flash',
        maxTokens: 8192,
        temperature: 0.5,
      ),

      // 🔥 FINAL TASK & BUCKET JUDGE (CRITICAL)
      // Image + video + audio + final decision
      AIProvider.openai: AIModelConfig(
        apiKey: EnvConfig.openaiApiKey,
        baseUrl: 'https://api.openai.com/v1',
        modelId: 'gpt-4o', // 👈 IMPORTANT CHANGE
        maxTokens: 2048, // smaller = faster & cheaper
        temperature: 0.2, // 👈 judge must be deterministic
      ),

      // 🧠 DEEP REASONING & REPORTS
      // Weekly/monthly summaries, explanations, audits
      AIProvider.claude: AIModelConfig(
        apiKey: EnvConfig.claudeApiKey,
        baseUrl: 'https://api.anthropic.com/v1',
        modelId: 'claude-3-5-sonnet-20241022',
        maxTokens: 4096,
        temperature: 0.5,
      ),

      // 🔁 FALLBACK / EXTRA SCALE
      // Simple reasoning, classification, redundancy
      AIProvider.mistral: AIModelConfig(
        apiKey: EnvConfig.mistralApiKey,
        baseUrl: 'https://api.mistral.ai/v1',
        modelId: 'mixtral-8x7b',
        maxTokens: 4096,
        temperature: 0.6,
      ),
    };

    _printConfigStatus(configs);

    return configs;
  }

  // ========================
  // 🐛 Debug Helper
  // ========================
  static void _printConfigStatus(Map<AIProvider, AIModelConfig> configs) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln(
      '╔═══════════════════════════════════════════════════════════╗',
    );
    buffer.writeln(
      '║  AI Provider Configuration Status                         ║',
    );
    buffer.writeln(
      '╠═══════════════════════════════════════════════════════════╣',
    );

    for (final entry in configs.entries) {
      final provider = entry.key;
      final config = entry.value;
      final status = config.isConfigured ? '✅ CONFIGURED' : '❌ NOT CONFIGURED';
      final isDefault = provider == defaultProvider ? ' (DEFAULT)' : '';

      buffer.writeln('║  ${provider.name.padRight(10)} : $status$isDefault');
    }

    buffer.writeln(
      '╚═══════════════════════════════════════════════════════════╝',
    );

    // Check if default provider is configured
    final defaultConfig = configs[defaultProvider];
    if (defaultConfig != null && !defaultConfig.isConfigured) {
      buffer.writeln('');
      buffer.writeln(
        '⚠️  WARNING: Default provider (${defaultProvider.name}) is NOT configured!',
      );
      buffer.writeln('   Please add your API key in env_config.dart');
      buffer.writeln('');
      buffer.writeln('   Quick Fix:');
      buffer.writeln(
        '   1. Get a FREE Groq API key: https://console.groq.com/',
      );
      buffer.writeln('   2. Add it to EnvConfig.groqApiKey');
      buffer.writeln('   3. Restart your app');
      buffer.writeln('');
    }

    // Check if ANY provider is configured
    final hasAnyConfigured = configs.values.any((c) => c.isConfigured);
    if (!hasAnyConfigured) {
      buffer.writeln('');
      buffer.writeln('❌ ERROR: NO AI providers are configured!');
      buffer.writeln('   Your app needs at least ONE API key to work.');
      buffer.writeln('');
      buffer.writeln('   Recommended: Get a FREE Groq API key');
      buffer.writeln('   → https://console.groq.com/');
      buffer.writeln('   → Add to EnvConfig.groqApiKey');
      buffer.writeln('   → Set defaultProvider = AIProvider.groq');
      buffer.writeln('');
    }

    logD(buffer.toString());
  }

  // ========================
  // 🧩 Context types
  // ========================
  static const String contextChat = 'chat';
  static const String contextSummary = 'summary';
  static const String contextAnalysis = 'analysis';
  static const String contextGeneration = 'generation';
  static const String contextFeedback = 'feedback';
  static const String contextVerification = 'verification';

  // ========================
  // 🎟️ Token limits
  // ========================
  static const int defaultQuota = 10000;
  static const int premiumQuota = 50000;
  static const Duration resetInterval = Duration(hours: 12);
}

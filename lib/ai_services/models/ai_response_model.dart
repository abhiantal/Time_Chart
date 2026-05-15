// lib/core/ai/models/ai_response_model.dart

import '../constants/ai_constants.dart';

class AiResponseModel {
  final bool isSuccess;
  final String response;
  final String? error;
  final int totalTokens;
  final AIProvider provider;
  final Duration processingTime;
  final bool fromCache;
  final DateTime timestamp;

  AiResponseModel({
    required this.isSuccess,
    required this.response,
    this.error,
    required this.totalTokens,
    required this.provider,
    required this.processingTime,
    this.fromCache = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'isSuccess': isSuccess,
    'response': response,
    'error': error,
    'totalTokens': totalTokens,
    'provider': provider.name,
    'processingTime': processingTime.inMilliseconds,
    'fromCache': fromCache,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AiResponseModel.fromJson(Map<String, dynamic> json) =>
      AiResponseModel(
        isSuccess: json['isSuccess'],
        response: json['response'],
        error: json['error'],
        totalTokens: json['totalTokens'],
        provider: AIProvider.values.firstWhere(
          (e) => e.name == json['provider'],
          orElse: () => AIProvider.gemini,
        ),
        processingTime: Duration(milliseconds: json['processingTime']),
        fromCache: json['fromCache'] ?? false,
        timestamp: DateTime.parse(json['timestamp']),
      );

  @override
  String toString() =>
      'AiResponseModel(success: $isSuccess, tokens: $totalTokens, '
      'provider: ${provider.name}, time: ${processingTime.inMilliseconds}ms, '
      'cached: $fromCache)';
}

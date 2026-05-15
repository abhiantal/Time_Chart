import 'dart:convert';
import 'package:the_time_chart/ai_services/constants/ai_constants.dart';
import 'package:the_time_chart/ai_services/services/token_manager_service.dart';
import 'package:the_time_chart/ai_services/services/universal_ai_service.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';

class SummaryInfo {
  final String summary;
  final String suggestion;
  final List<String> aiPlan;
  SummaryInfo({
    required this.summary,
    required this.suggestion,
    required this.aiPlan,
  });
}

class BucketAiService {
  static final BucketAiService _instance = BucketAiService._internal();
  factory BucketAiService() => _instance;
  BucketAiService._internal();

  final _aiService = UniversalAIService();
  final _tokenManager = TokenManagerService();

  Future<String?> generateCaption(
    BucketModel bucket,
    String userId, {
    bool isLive = false,
  }) async {
    try {
      final completed = bucket.checklist.where((i) => i.done).length;
      final total = bucket.checklist.length;
      final progress = bucket.metadata.averageProgress.round();
      final rating = bucket.metadata.averageRating.toStringAsFixed(1);
      final context =
          '''
Bucket: ${bucket.title}
Status: ${bucket.isCompleted ? 'completed' : 'inProgress'}
Checklist: $completed/$total
Progress: $progress%
Rating: $rating
Post Type: ${isLive ? 'Live Update' : 'Snapshot'}
''';
      final prompt =
          '''
Generate a short, engaging caption (under 120 chars) for sharing this bucket.
$context
''';
      final estimated = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimated)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'Write catchy, motivational captions for bucket updates.',
          maxTokens: 100,
          temperature: 0.7,
          sourceTable: 'bucket_models',
          sourceRecordId: bucket.bucketId,
          contextType: AiConstants.contextGeneration,
          aiUsageSource: 'caption_generation',
        );
        if (res.isSuccess) {
          return res.response.trim();
        }
      }
      return null;
    } catch (e) {
      logE('❌ bucket caption error: $e');
      return null;
    }
  }

  Future<String?> generateMotivation({
    required BucketModel bucket,
    required String userId,
  }) async {
    try {
      final allDone =
          bucket.checklist.isNotEmpty && bucket.checklist.every((i) => i.done);
      if (!(bucket.isCompleted || allDone)) return null;

      final completed = bucket.checklist.where((i) => i.done).length;
      final total = bucket.checklist.length;
      final progress = bucket.metadata.averageProgress.round();
      final rating = bucket.metadata.averageRating.toStringAsFixed(1);

      final context =
          '''
Bucket: ${bucket.title}
Category: ${bucket.categoryType ?? ''} / ${bucket.subTypes ?? ''}
Checklist: $completed/$total completed
Progress: $progress%
Rating: $rating
Description: ${bucket.details.description}
Motivation: ${bucket.details.motivation}
Outcome: ${bucket.details.outCome}
Due: ${bucket.timeline.dueDate?.toIso8601String() ?? ''}
''';

      final prompt =
          '''
Provide one concise motivational quote for a completed bucket.
Return plain text only, under 24 words.
Context:
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'Return a short, uplifting motivational quote for achievement.',
          maxTokens: 60,
          temperature: 0.7,
          sourceTable: 'bucket_models',
          sourceRecordId: bucket.bucketId,
          contextType: AiConstants.contextGeneration,
          aiUsageSource: 'bucket_motivation',
        );
        if (res.isSuccess && res.response.trim().isNotEmpty) {
          return res.response.trim();
        }
      }

      return _fallbackMotivation(bucket);
    } catch (e) {
      logE('❌ bucket motivation error: $e');
      AppSnackbar.error('Bucket motivation error: $e');
      return _fallbackMotivation(bucket);
    }
  }

  String? getMotivationalQuote({required BucketModel bucket}) {
    final allDone =
        bucket.checklist.isNotEmpty && bucket.checklist.every((i) => i.done);
    if (!(bucket.isCompleted || allDone)) return null;

    final quotes = [
      'Every challenge conquered makes the next one easier.',
      'Your dedication turned goals into achievements. Celebrate this win!',
      'Consistency creates momentum. You finished strong—keep building.',
      'Excellence is a habit. This completion proves your discipline.',
      'You didn’t just complete a task—you raised your standards.',
    ];
    return quotes[DateTime.now().millisecond % quotes.length];
  }

  Future<({bool success, String feedback})> verifyFeedback({
    required String taskDescription,
    required String feedbackText,
    required List<String> mediaUrls,
    required String userId,
    required String bucketId,
  }) async {
    try {
      final context = '''
Task: $taskDescription
User Feedback: $feedbackText
Media Attached: ${mediaUrls.length} items
''';
      final prompt = '''
Verify if the user feedback and attached media reasonably demonstrate completion or progress of the task.
Be objective but encouraging.
Return JSON: {"pass": true/false, "explanation": "..."}
$context
''';

      final estimated = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimated)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt: 'You are a task verification assistant. Verify task authenticity.',
          maxTokens: 150,
          temperature: 0.3,
          sourceTable: 'bucket_models',
          sourceRecordId: bucketId,
          contextType: AiConstants.contextVerification,
          aiUsageSource: 'feedback_verification',
        );

        if (res.isSuccess) {
          final cleaned = res.response.trim();
          final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
          if (match != null) {
            final parsed = jsonDecode(match.group(0)!) as Map<String, dynamic>;
            return (
              success: parsed['pass'] as bool? ?? false,
              feedback: parsed['explanation']?.toString() ?? 'Verification completed.'
            );
          }
        }
      }
      return (success: true, feedback: 'AI verification skipped.');
    } catch (e) {
      logE('❌ feedback verification error: $e');
      return (success: true, feedback: 'Verification unavailable.');
    }
  }

  List<String> getWeeklySuggestions({required BucketModel bucket}) {
    final remaining = bucket.checklist.where((i) => !i.done).length;
    final progress = bucket.metadata.averageProgress.toInt();
    final rating = bucket.metadata.averageRating;

    final suggestions = <String>[];

    if (remaining > 0) {
      suggestions.add('Prioritize top 3 remaining tasks and timebox each.');
    }
    if (progress < 50) {
      suggestions.add('Schedule two focused 45-min sessions this week.');
    } else if (progress < 80) {
      suggestions.add('Convert medium tasks into smaller, 20-min actions.');
    } else {
      suggestions.add('Refine outcomes and add a closing reflection.');
    }

    if (rating < 3.5) {
      suggestions.add('Improve quality: add feedback notes to each task.');
    } else {
      suggestions.add('Document learnings and share a snapshot of progress.');
    }

    suggestions.add('Attach one relevant media item to each completed task.');
    return suggestions;
  }

  Future<SummaryInfo?> generateBucketSummary({
    required BucketModel bucket,
    required String userId,
  }) async {
    try {
      final completed = bucket.checklist.where((i) => i.done).length;
      final total = bucket.checklist.length;
      final progress = bucket.metadata.averageProgress.toInt();
      final rating = bucket.metadata.averageRating.toStringAsFixed(1);
      
      final allFeedbacks = bucket.checklist
          .expand((i) => i.feedbacks)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      final recentNotes = allFeedbacks
          .map((f) => f.text)
          .take(5)
          .toList();

      final tag = bucket.metadata.rewardPackage?.tagName ?? '';
      final reward = bucket.metadata.rewardPackage?.tier.name ?? '';
      final points = bucket.metadata.totalPointsEarned;
      final social = bucket.socialInfo?.isPosted == true ? 'posted' : 'not_posted';
      final shared = bucket.shareInfo?.isShare == true ? 'shared' : 'not_shared';

      final context = '''
Bucket: ${bucket.title}
Category: ${bucket.categoryType ?? ''} / ${bucket.subTypes ?? ''}
Completed: $completed/$total
Progress: $progress%
Rating: $rating
Description: ${bucket.details.description}
Motivation: ${bucket.details.motivation}
Outcome: ${bucket.details.outCome}
Start: ${bucket.timeline.startDate?.toIso8601String() ?? ''}
Due: ${bucket.timeline.dueDate?.toIso8601String() ?? ''}
Points: $points, Tag: $tag, Reward: $reward
Social: $social, Shared: $shared
Recent Notes: ${recentNotes.join(' | ')}
''';

      final prompt =
          '''
Analyze this bucket and produce practical guidance tailored to its context.
Return compact JSON:
{"summary":"...", "suggestion":"...", "ai_plan":["...", "...", "..."]}.
Use bucket data strictly; avoid generic advice.
Context:
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'Return concise JSON summary with suggestion and ai_plan.',
          maxTokens: 180,
          temperature: 0.5,
          sourceTable: 'bucket_models',
          sourceRecordId: bucket.bucketId,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'bucket_summary',
        );
        if (res.isSuccess && res.response.trim().isNotEmpty) {
          String cleaned = res.response.trim();
          final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
          if (match != null) {
            cleaned = match.group(0)!;
          } else {
            cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '');
          }

          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          final summary = (parsed['summary'] ?? '').toString();
          final suggestion = (parsed['suggestion'] ?? '').toString();
          final plan = List<String>.from(parsed['ai_plan'] ?? []);
          return SummaryInfo(
            summary: summary,
            suggestion: suggestion,
            aiPlan: plan,
          );
        }
      }

      return _fallbackSummary(bucket);
    } catch (e) {
      logE('❌ bucket summary error: $e');
      AppSnackbar.error('Bucket summary error: $e');
      return _fallbackSummary(bucket);
    }
  }

  String progressString(BucketModel bucket) =>
      '${bucket.metadata.averageProgress.toInt()}%';

  SummaryInfo _fallbackSummary(BucketModel bucket) {
    final completed = bucket.checklist.where((i) => i.done).length;
    final total = bucket.checklist.length;
    final summary =
        'Progress ${progressString(bucket)}. Completed $completed of $total tasks.';
    final suggestion = 'Next: focus on remaining tasks and capture feedback.';
    final plan = getWeeklySuggestions(bucket: bucket);
    return SummaryInfo(summary: summary, suggestion: suggestion, aiPlan: plan);
  }

  String _fallbackMotivation(BucketModel bucket) {
    final p = bucket.metadata.averageProgress.round();
    final r = bucket.metadata.averageRating;
    if (p >= 85 && r >= 4.0) {
      return 'Strong finish on ${bucket.title}. Capture learnings and share a snapshot.';
    }
    if (p >= 60) {
      return 'Momentum is building. Convert remaining tasks into small actions.';
    }
    return 'Time-block two focused sessions and push ${bucket.title} forward.';
  }
}

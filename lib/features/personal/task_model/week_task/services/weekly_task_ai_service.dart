import 'dart:convert';
import '../../../../../../ai_services/constants/ai_constants.dart';
import '../../../../../../ai_services/services/token_manager_service.dart';
import '../../../../../../ai_services/services/universal_ai_service.dart';
import '../../../../../../widgets/logger.dart';
import '../models/week_task_model.dart';

class WeeklyTaskAIService {
  static final WeeklyTaskAIService _instance = WeeklyTaskAIService._internal();
  factory WeeklyTaskAIService() => _instance;
  WeeklyTaskAIService._internal();

  final _aiService = UniversalAIService();
  final _tokenManager = TokenManagerService();

  Future<String?> generateCaption(
    WeekTaskModel task,
    String userId, {
    bool isLive = false,
  }) async {
    try {
      final context =
          '''
Task: ${task.aboutTask.taskName}
Status: ${task.indicators.status}
Progress: ${task.summary.progress}%
Post Type: ${isLive ? 'Live Update' : 'Snapshot'}
Completed: ${task.summary.completedDays} / ${task.timeline.totalScheduledDays}
''';
      final prompt =
          '''
Generate a short, engaging caption (under 120 chars) for sharing this weekly task update.
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt: 'Write catchy, motivational captions for task updates.',
          maxTokens: 100,
          temperature: 0.7,
          sourceTable: 'week_tasks',
          sourceRecordId: task.id,
          contextType: AiConstants.contextGeneration,
          aiUsageSource: 'caption_generation',
        );
        if (response.isSuccess) {
          return response.response.trim();
        }
      }
      return null;
    } catch (e) {
      logE('âŒ Error generating caption: $e');
      return null;
    }
  }

  Future<String?> generateWeeklySuggestion(
    WeekTaskModel weekTask,
    String userId,
  ) async {
    try {
      final avgProgress = weekTask.summary.progress;
      final avgRating = weekTask.summary.rating;


      final context =
          '''
Task: ${weekTask.aboutTask.taskName}
Week Range: ${weekTask.timeline.startingTime.toIso8601String().split('T')[0]} â†’ ${weekTask.timeline.endingTime.toIso8601String().split('T')[0]}
Scheduled Days: ${weekTask.timeline.taskDays}
Completed: ${weekTask.summary.completedDays} / ${weekTask.timeline.totalScheduledDays}
Missed: ${weekTask.summary.pendingGoalDays}
Average Progress: $avgProgress%
Average Rating: ${avgRating.toStringAsFixed(1)}
Tags Earned: ${weekTask.summary.dailyRewards.map((r) => r.tagName).where((t) => t.isNotEmpty).toSet().join(', ')}
Rewards Earned: ${weekTask.summary.dailyRewards.map((r) => r.rewardDisplayName).where((n) => n.isNotEmpty).toSet().join(', ')}

''';

      final prompt =
          '''
Based on the weekly performance context, provide 1 specific suggestion
to improve next week's results. Keep it under 18 words, practical, and
refer to the observed patterns (best/worst day, missed vs completed).

Return only the suggestion line.

Context:
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'Provide concise, actionable weekly improvement suggestions.',
          maxTokens: 80,
          temperature: 0.6,
          sourceTable: 'week_tasks',
          sourceRecordId: weekTask.id,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'weekly_suggestion',
        );

        if (response.isSuccess && response.response.trim().isNotEmpty) {
          return response.response.trim();
        }
      }

      return _fallbackSuggestion(
        avgProgress,
        avgRating,
        weekTask.summary.completedDays,
        weekTask.summary.pendingGoalDays,
      );
    } catch (e) {
      logE('âŒ Weekly suggestion error: $e');
      return _fallbackSuggestion(
        weekTask.summary.progress,
        weekTask.summary.rating,
        weekTask.summary.completedDays,
        weekTask.summary.pendingGoalDays,
      );
    }
  }

  Future<DailyFeedback> verifyDailyFeedback(
    WeekTaskModel task,
    DailyFeedback feedback,
    String userId,
  ) async {
    try {
      final prompt = '''
Verify if this feedback is authentic and relevant to the task.
Task Name: ${task.aboutTask.taskName}
Task Description: ${task.aboutTask.taskDescription ?? 'N/A'}
Feedback Text: ${feedback.text}
Has Media: ${feedback.hasMedia ? 'Yes' : 'No'}

Return JSON:
{
  "is_pass": true/false,
  "reason": "Brief explanation"
}
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt: 'You are a strict authenticity verifier. Only pass if the feedback matches the task intent.',
          maxTokens: 150,
          temperature: 0.3,
          sourceTable: 'week_tasks',
          sourceRecordId: task.id,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'feedback_verification',
        );

        if (response.isSuccess) {
          try {
            final data = jsonDecode(response.response);
            return DailyFeedback(
              feedbackNumber: feedback.feedbackNumber,
              text: feedback.text,
              mediaUrl: feedback.mediaUrl,
              timestamp: feedback.timestamp,
              isPass: data['is_pass'] == true,
              verificationReason: data['reason'],
            );
          } catch (_) {
            logE('âŒ AI response parsing failed');
          }
        }
      }
      return feedback; // Fallback to original
    } catch (e) {
      logE('âŒ AI Verification error: $e');
      return feedback;
    }
  }

  String _fallbackSuggestion(
    int progress,
    double rating,
    int completed,
    int missed,
  ) {
    if (progress < 40) {
      return 'Plan shorter sessions and log brief updates daily to build consistency.';
    }
    if (missed > completed) {
      return 'Reduce scope and protect time blocks to avoid misses.';
    }
    if (rating < 3.5 && progress >= 60) {
      return 'Add richer final notes to raise quality and boost rating.';
    }
    if (progress >= 85) {
      return 'Maintain your routine and schedule similar blocks for the week.';
    }
    return 'Schedule a midweek review and adjust tasks based on early feedback.';
  }
}

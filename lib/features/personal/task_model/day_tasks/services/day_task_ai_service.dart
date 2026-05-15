import 'dart:async';
import 'dart:convert';
import '../../../../../../ai_services/constants/ai_constants.dart';
import '../../../../../../ai_services/services/token_manager_service.dart';
import '../../../../../../ai_services/services/universal_ai_service.dart';
import '../../../../../../user_settings/providers/settings_provider.dart';
import '../../../../../../user_settings/models/settings_model.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../../widgets/error_handler.dart';
import '../models/day_task_model.dart';

class DayTaskAIService {
  static final DayTaskAIService _instance = DayTaskAIService._internal();
  factory DayTaskAIService() => _instance;
  DayTaskAIService._internal();

  final _aiService = UniversalAIService();
  final _tokenManager = TokenManagerService();

  Future<String?> generateCaption(
    DayTaskModel task,
    String userId, {
    bool isLive = false,
  }) async {
    try {
      final aiSettings = SettingsProvider().ai;
      if (!aiSettings.enabled || !aiSettings.useFor.taskSuggestions) {
        logI('AI caption generation disabled by settings');
        return null;
      }

      double temperature;
      switch (aiSettings.responseStyle) {
        case ResponseStyle.concise:
          temperature = 0.3;
          break;
        case ResponseStyle.detailed:
          temperature = 0.9;
          break;
        case ResponseStyle.balanced:
        default:
          temperature = 0.7;
          break;
      }



      final context =
          '''
Task: ${task.aboutTask.taskName}
Status: ${task.indicators.status}
Progress: ${task.metadata.progress}%
Post Type: ${isLive ? 'Live Update' : 'Snapshot'}
''';
      final prompt =
          '''
Generate a short, engaging caption (under 120 chars) for sharing this task.
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,

          systemPrompt: 'Write catchy, motivational captions for task updates.',
          maxTokens: 100,
          temperature: temperature,
          sourceTable: 'day_tasks',
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
      logE('❌ Error generating caption: $e');
      return null;
    }
  }

  Future<String?> generateSummary(
    DayTaskModel task,
    String userId, {
    String status = 'completed',
    bool? hasFeedback,
    bool? isOverdue,
  }) {
    return generateTaskSummary(
      task,
      userId,
      status,
      hasFeedback ?? task.feedback.comments.isNotEmpty,
      isOverdue ??
          DateTime.now().isAfter(
            DateTime(
              task.timeline.endingTime.year,
              task.timeline.endingTime.month,
              task.timeline.endingTime.day,
              23,
              59,
              59,
            ),
          ),
    );
  }

  Future<String> generateSuggestions(
    DayTaskModel task,
    String userId, {
    int maxItems = 3,
  }) async {
    try {
      final aiSettings = SettingsProvider().ai;
      if (!aiSettings.enabled ||
          !aiSettings.useFor.taskSuggestions ||
          !aiSettings.autoSuggestions) {
        logI('AI suggestions disabled by settings; using fallback suggestions');
        return _fallbackSuggestions(task, maxItems);
      }

      double temperature;
      switch (aiSettings.responseStyle) {
        case ResponseStyle.concise:
          temperature = 0.4;
          break;
        case ResponseStyle.detailed:
          temperature = 0.8;
          break;
        case ResponseStyle.balanced:
        default:
          temperature = 0.6;
          break;
      }



      final context =
          '''
Task: ${task.aboutTask.taskName}
Priority: ${task.indicators.priority}
Status: ${task.indicators.status}
Progress: ${task.metadata.progress}%
Points: ${task.metadata.pointsEarned}
Penalty: ${task.metadata.penalty?.penaltyPoints ?? 0}
Rating: ${task.metadata.rating.toStringAsFixed(1)}
Overdue: ${task.timeline.overdue}
Feedback entries: ${task.feedback.comments.length}
Recent feedback:
${task.feedback.comments.take(3).map((c) => '- ${c.text}').join('\n')}
''';

      final prompt =
          '''
Based on the task context, generate $maxItems short, actionable suggestions
to improve performance for the next similar task.

Constraints:
- Keep each suggestion under 16 words
- Be specific and practical
- Consider priority, feedback pattern, and penalties
- No generic advice; refer to the context

Format:
- Bullet list with exactly $maxItems items

Context:
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,

          systemPrompt: 'Provide concise, practical productivity suggestions.',
          maxTokens: 160,
          temperature: temperature,
          sourceTable: 'day_tasks',
          sourceRecordId: task.id,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'suggestions_generation',
        );

        if (response.isSuccess && response.response.trim().isNotEmpty) {
          return response.response.trim();
        }
      }

      return _fallbackSuggestions(task, maxItems);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'DayTaskAIService.generateSuggestions',
      );
      return _fallbackSuggestions(task, maxItems);
    }
  }

  String _fallbackSuggestions(DayTaskModel task, int maxItems) {
    final List<String> suggestions = [];
    suggestions.add('Schedule a midpoint check to avoid end-of-day rush.');
    suggestions.add('Add brief updates with media for clearer tracking.');
    if (task.timeline.overdue) {
      suggestions.add('Set earlier cutoff to prevent overdue penalties.');
    } else {
      suggestions.add('Block 30 minutes for final task review.');
    }
    return suggestions.take(maxItems).map((s) => '- $s').join('\n');
  }

  Future<DayTaskModel?> processTaskCompletion(
    DayTaskModel task,
    String userId, {
    String autoStatus = 'completed',
    String taskType = 'day_task',
    int? taskStack,
    int? completedDays,
    bool? hasFeedback,
    bool? isOverdue,
  }) async {
    try {
      final aiSettings = SettingsProvider().ai;
      final bool enableStrictAiVerification =
          aiSettings.enabled &&
          aiSettings.useFor.productivityInsights &&
          aiSettings.dataUsage.learnFromHistory;

      // ================================================================
      // AI VERIFICATION (Strict Mode)
      // ================================================================


      // 1. Collect all feedbacks for batch verification

      final List<Map<String, dynamic>> feedbacksToVerify = task.feedback.comments.map((c) => {
        'text': c.text,
        'mediaUrls': c.hasMedia ? [c.mediaUrl!] : <String>[],
        'timestamp': c.timestamp.toIso8601String(),
      }).toList();

      List<Comment> updatedComments = List.from(task.feedback.comments);

      // 2. Perform Batch AI Verification (ONE TIME PER TASK)
      if (enableStrictAiVerification && feedbacksToVerify.isNotEmpty) {
        logI('🕵️ Starting batch feedback verification for task: ${task.id}');
        
        final results = await _aiService.batchVerifyFeedbacks(
          taskDescription: task.aboutTask.taskName,
          feedbacks: feedbacksToVerify,
          timeline: task.timeline.toJson(),
          expectedOutcome: task.aboutTask.taskDescription ?? '',
        );

        // Map results back to comments
        for (var result in results) {
          final index = result['index'] as int;
          if (index >= 0 && index < updatedComments.length) {
            updatedComments[index] = updatedComments[index].copyWith(
              isPass: result['isPass'] == true,
              verificationReason: result['reason'] ?? (result['isPass'] == true ? 'PASS' : 'FAIL'),
            );
          }
        }
      }

      // 3. Create temp task for final evaluation
      final tempTask = task.copyWith(
        feedback: task.feedback.copyWith(comments: updatedComments),
      );

      final now = DateTime.now();
      
      // 4. Perform final evaluation using the new model method
      final evaluation = tempTask.evaluateTask(now: now);
      
      final int pointsEarned = evaluation['points_earned'];
      final int penaltyPoints = evaluation['penalty'];
      final double progress = evaluation['progress'].toDouble();
      final double rating = evaluation['rating'];
      final String finalStatus = evaluation['status'];

      // 5. Generate AI Tags & Summary (Secondary pass, but part of the same "completion" process)
      final summary = await generateTaskSummary(
        tempTask,
        userId,
        finalStatus,
        updatedComments.isNotEmpty,
        evaluation['breakdown']['overduePenalty'] > 0,
      );


      // 6. Final state assembly
      final updatedMetadata = task.metadata.copyWith(
        progress: progress.toInt(),
        pointsEarned: pointsEarned,
        rating: rating,
        penalty: PenaltyInfo(
          penaltyPoints: penaltyPoints,
          reason: 'Final Batch AI Evaluation',
        ),
        isComplete: finalStatus == 'completed',
        summary: summary ?? evaluation['breakdown'].toString(),
      );

      final updatedTimeline = task.timeline.copyWith(
        completionTime: now,
        overdue: evaluation['breakdown']['overduePenalty'] > 0,
      );

      final updatedIndicators = task.indicators.copyWith(
        status: finalStatus,
      );

      var completedTask = task.copyWith(
        timeline: updatedTimeline,
        indicators: updatedIndicators,
        metadata: updatedMetadata,
        feedback: task.feedback.copyWith(comments: updatedComments),
        updatedAt: now,
      );

      // 7. Calculate and attach final RewardPackage
      completedTask = completedTask.copyWith(
        metadata: completedTask.metadata.copyWith(
          rewardPackage: completedTask.calculateRewardPackage(),
        ),
      );


      logI('✅ Task evaluation complete for ${task.id}. Status: $finalStatus, Score: ${evaluation['final_score']}');
      return completedTask;

    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'DayTaskAIService.processTaskCompletion',
      );
      return null;
    }
  }

  // ❌ REMOVED: Duplicated logic moved to DayTaskModel
  // _calculatePointsEarned
  // _calculatePenalty
  // _calculateRating
  // _calculateProgressFromPoints



  Future<String?> generateTaskSummary(
    DayTaskModel task,
    String userId,
    String autoStatus,
    bool hasFeedback,
    bool isOverdue,
  ) async {
    try {
      final aiSettings = SettingsProvider().ai;
      if (!aiSettings.enabled || !aiSettings.useFor.taskSuggestions) {
        logI('AI summary generation disabled by settings');
        return _generateFallbackSummary(task, autoStatus, hasFeedback);
      }

      double temperature;
      switch (aiSettings.responseStyle) {
        case ResponseStyle.concise:
          temperature = 0.3;
          break;
        case ResponseStyle.detailed:
          temperature = 0.9;
          break;
        case ResponseStyle.balanced:
        default:
          temperature = 0.7;
          break;
      }



      final context =
          '''
Task: ${task.aboutTask.taskName}
Status: $autoStatus
Feedback: ${hasFeedback ? '${task.feedback.comments.length} entries' : 'None'}
Overdue: $isOverdue
''';
      final prompt =
          '''
Generate a two-sentence summary of this task completion.
$context
''';
      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,

          systemPrompt: 'Create brief, encouraging task summaries.',
          maxTokens: 100,
          temperature: temperature,
          sourceTable: 'day_tasks',
          sourceRecordId: task.id,
          contextType: AiConstants.contextGeneration,
          aiUsageSource: 'summary_generation',
        );
        if (response.isSuccess) {
          return response.response.trim();
        }
      }
      return _generateFallbackSummary(task, autoStatus, hasFeedback);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(
        e,
        stackTrace,
        'DayTaskAIService.generateTaskSummary',
      );
      return _generateFallbackSummary(task, autoStatus, hasFeedback);
    }
  }

  String _generateFallbackSummary(
    DayTaskModel task,
    String autoStatus,
    bool hasFeedback,
  ) {
    final name = task.aboutTask.taskName;
    final feedbackCount = task.feedback.comments.length;
    if (hasFeedback) {
      return '$name was $autoStatus with $feedbackCount documented updates.';
    } else {
      return '$name was $autoStatus.';
    }
  }
}

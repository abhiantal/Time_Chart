import 'dart:convert';
import '../../../../../../ai_services/constants/ai_constants.dart';
import '../../../../../../ai_services/services/token_manager_service.dart';
import '../../../../../../ai_services/services/universal_ai_service.dart';
import '../../../../../../widgets/logger.dart';
import '../models/long_goal_model.dart';

class LongGoalAIService {
  static final LongGoalAIService _instance = LongGoalAIService._internal();
  factory LongGoalAIService() => _instance;
  LongGoalAIService._internal();

  final _aiService = UniversalAIService();
  final _tokenManager = TokenManagerService();

  Future<String?> generateCaption(
    LongGoalModel goal,
    String userId, {
    bool isLive = false,
  }) async {
    try {
      final completedWeeks = goal.indicators.weeklyPlans
          .where((p) => p.isCompleted)
          .length;
      final context =
          '''
Goal: ${goal.title}
Status: ${goal.indicators.status}
Progress: ${goal.analysis.averageProgress.round()}%
Post Type: ${isLive ? 'Live Update' : 'Snapshot'}
Completed Weeks: $completedWeeks
''';
      final prompt =
          '''
Generate a short, engaging caption (under 120 chars) for sharing this goal update.
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final response = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt: 'Write catchy, motivational captions for goal updates.',
          maxTokens: 100,
          temperature: 0.7,
          sourceTable: 'long_goals',
          sourceRecordId: goal.goalId,
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

  Future<Map<String, String>?> generateWeeklyGoal({
    required String userId,
    required String goalTitle,
    required String need,
    required String motivation,
    required String outcome,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> workDays,
    required int hoursPerDay,
    String? categoryType,
    String? subTypes,
    required int weekNumber,
  }) async {
    try {
      final context =
          '''
Goal: $goalTitle
Need: $need
Motivation: $motivation
Outcome: $outcome
Timeline: ${startDate.toIso8601String().split('T')[0]} → ${endDate.toIso8601String().split('T')[0]}
Work Days: ${workDays.join(', ')}
Hours/Day: $hoursPerDay
Category: ${categoryType ?? 'N/A'} / ${subTypes ?? 'N/A'}
Week #: $weekNumber
''';
      final prompt =
          '''
Propose a practical weekly milestone and mood for this goal context.
Return JSON: {"weekly_goal": "...", "mood": "..."}.
Keep weekly_goal under 14 words; mood one word like "motivated".
Context:
$context
''';
      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,

          systemPrompt: 'Return concise JSON with weekly_goal and mood.',
          maxTokens: 120,
          temperature: 0.6,
          sourceTable: 'long_goals',
          sourceRecordId: 'goal_generation',
          contextType: AiConstants.contextGeneration,
          aiUsageSource: 'weekly_goal_generation',
        );
        if (res.isSuccess && res.response.trim().isNotEmpty) {
          final text = res.response
              .trim()
              .replaceAll('```json', '')
              .replaceAll('```', '');
          final parsed = jsonDecode(text) as Map<String, dynamic>;
          return {
            'weekly_goal': (parsed['weekly_goal'] ?? '').toString(),
            'mood': (parsed['mood'] ?? 'focused').toString(),
          };
        }
      }
      return {
        'weekly_goal': 'Advance core milestone and review outcomes',
        'mood': 'focused',
      };
    } catch (e) {
      logE('❌ generateWeeklyGoal error: $e');
      return {
        'weekly_goal': 'Complete core tasks and reflect briefly',
        'mood': 'motivated',
      };
    }
  }

  Future<String?> generateWeeklySuggestion(
    LongGoalModel goal,
    String userId,
  ) async {
    try {
      final completedWeeks = goal.indicators.weeklyPlans
          .where((p) => p.isCompleted)
          .length;
      final missedWeeks = goal.indicators.weeklyPlans.length - completedWeeks;
      final avgProgress = goal.analysis.averageProgress.round();
      final avgRating = goal.analysis.averageRating;
      final bestWeek = _bestWeekName(goal);
      final worstWeek = _worstWeekName(goal);

      final context =
          '''
Goal: ${goal.title}
Completed Weeks: $completedWeeks / ${goal.goalLog.weeklyLogs.length}
Average Progress: $avgProgress%
Average Rating: ${avgRating.toStringAsFixed(1)}
Best Week: $bestWeek
Worst Week: $worstWeek
''';
      final prompt =
          '''
Provide one concise suggestion to improve next week.
Max 18 words, refer to context patterns. Return plain text line.
Context:
$context
''';
      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'Provide concise, practical weekly improvement suggestions.',
          maxTokens: 80,
          temperature: 0.6,
          sourceTable: 'long_goals',
          sourceRecordId: goal.goalId,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'weekly_suggestion',
        );
        if (res.isSuccess && res.response.trim().isNotEmpty) {
          return res.response.trim();
        }
      }
      return _fallbackWeeklySuggestion(
        avgProgress,
        avgRating,
        completedWeeks,
        missedWeeks,
        bestWeek,
        worstWeek,
      );
    } catch (e) {
      logE('❌ weekly suggestion error: $e');
      return _fallbackWeeklySuggestion(
        goal.analysis.averageProgress.round(),
        goal.analysis.averageRating,
        goal.indicators.weeklyPlans.where((p) => p.isCompleted).length,
        goal.indicators.weeklyPlans.length -
            goal.indicators.weeklyPlans.where((p) => p.isCompleted).length,
        _bestWeekName(goal),
        _worstWeekName(goal),
      );
    }
  }

  Future<List<String>> generateSuggestionsList(
    LongGoalModel goal,
    String userId, {
    int count = 3,
  }) async {
    try {
      final suggestion = await generateWeeklySuggestion(goal, userId);
      if (suggestion != null && suggestion.isNotEmpty) {
        return [suggestion];
      }
      return _fallbackSuggestionsList(goal, count);
    } catch (e) {
      logE('❌ suggestions list error: $e');
      return _fallbackSuggestionsList(goal, count);
    }
  }

  Future<List<String>?> generateSuggestions({
    required String userId,
    required LongGoalModel goal,
  }) async {
    try {
      final list = await generateSuggestionsList(goal, userId, count: 3);
      return list;
    } catch (e) {
      logE('❌ generateSuggestions error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeFeedback({
    required String userId,
    required LongGoalModel goal,
  }) async {
    try {
      final avgProgress = goal.analysis.averageProgress.round();
      final avgRating = goal.analysis.averageRating;
      final completedWeeks = goal.indicators.weeklyPlans
          .where((p) => p.isCompleted)
          .length;
      final missedWeeks = goal.indicators.weeklyPlans.length - completedWeeks;

      final recentNotes = goal.goalLog.weeklyLogs.isNotEmpty
          ? goal.goalLog.weeklyLogs.last.dailyFeedback
                .take(3)
                .map((f) => f.feedbackText)
                .where((t) => t.isNotEmpty)
                .toList()
          : <String>[];

      final context =
          '''
Goal: ${goal.title}
Average Progress: $avgProgress%
Average Rating: ${avgRating.toStringAsFixed(1)}
Completed Weeks: $completedWeeks
Missed Weeks: $missedWeeks
Recent Notes: ${recentNotes.join(' | ')}
''';

      final prompt =
          '''
Analyze the goal feedback. Return JSON with keys:
summary (string), strengths (array), weaknesses (array), next_steps (array).
Keep items short and practical.
Context:
$context
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt: 'Return concise JSON analysis of performance.',
          maxTokens: 180,
          temperature: 0.5,
          sourceTable: 'long_goals',
          sourceRecordId: goal.goalId,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'feedback_analysis',
        );
        if (res.isSuccess && res.response.trim().isNotEmpty) {
          final cleaned = res.response
              .trim()
              .replaceAll('```json', '')
              .replaceAll('```', '');
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          return parsed;
        }
      }

      return {
        'summary': 'Consistent progress with room to improve note quality.',
        'strengths': ['Regular updates', 'Steady progress'],
        'weaknesses': ['Inconsistent depth of notes', 'Misses on weaker days'],
        'next_steps': [
          'Protect time on weaker days',
          'Add brief end-of-day reflection',
          'Plan one extra focused block',
        ],
      };
    } catch (e) {
      logE('❌ analyzeFeedback error: $e');
      return {
        'summary': 'Progress is acceptable; focus on consistency and quality.',
        'strengths': ['Good momentum'],
        'weaknesses': ['Irregular detail'],
        'next_steps': ['Schedule midweek review', 'Improve final notes'],
      };
    }
  }

  String _fallbackWeeklySuggestion(
    int progress,
    double rating,
    int completed,
    int missed,
    String best,
    String worst,
  ) {
    if (progress < 40) {
      return 'Shorten scope and schedule small daily blocks to build consistency.';
    }
    if (missed > completed) {
      return 'Protect time blocks on $worst and reduce task load to avoid misses.';
    }
    if (rating < 3.5 && progress >= 60) {
      return 'Enrich final notes and media to raise quality and rating.';
    }
    if (progress >= 85) {
      return 'Replicate $best schedule and plan similar focused blocks next week.';
    }
    return 'Add a midweek review and adjust based on early feedback trends.';
  }

  Future<DailyProgress> verifyDailyProgress({
    required String userId,
    required LongGoalModel goal,
    required DailyFeedback feedback,
  }) async {
    try {
      // Sanitize input to prevent prompt injection
      final sanitizedFeedback = feedback.feedbackText
          .replaceAll('"', '\\"')
          .replaceAll('\n', ' ')
          .trim();

      final prompt =
          '''
Verify if this completion feedback is authentic and directly relevant to the goal: "${goal.title}".
Goal Context:
- Description: ${goal.description.need}
- Outcome: ${goal.description.outcome}

User Feedback:
- Text: "$sanitizedFeedback"
- Media Attached: ${feedback.hasMedia ? 'YES' : 'NO'}

STRICT VERIFICATION RULES:
1. If the feedback text is generic (e.g., "done", "ok", "good"), RANDOM, or irrelevant to the goal's specific "Need" or "Outcome", mark as UNAUTHENTIC.
2. If unauthentic: is_authentic=false, progress=0, points_earned=0, rating=0, is_complete=false.
3. If authentic:
   - Calculate points_earned based on: 5 (base) + 5 (if media) + (word_count * 3) + priority_bonus(${goal.indicators.priority}).
   - rating: 0.0-5.0 based on quality and depth.
   - progress: 0-100 based on effort relative to the goal's requirements.
   - is_complete: true.

Return JSON:
{
  "is_authentic": bool,
  "verification_reason": "string",
  "progress": int,
  "points_earned": int,
  "rating": double,
  "is_complete": bool,
  "motivational_quote": "string"
}
''';

      final estimatedTokens = _tokenManager.estimateTokensFromText(prompt);
      if (await _tokenManager.canUseTokens(userId, estimatedTokens)) {
        final res = await _aiService.generateResponse(
          prompt: prompt,
          systemPrompt:
              'You are an authenticity verification agent for task completions.',
          maxTokens: 250,
          temperature: 0.4,
          sourceTable: 'long_goals',
          sourceRecordId: goal.id,
          contextType: AiConstants.contextAnalysis,
          aiUsageSource: 'authenticity_verification',
        );

        if (res.isSuccess && res.response.trim().isNotEmpty) {
          final cleaned = res.response
              .trim()
              .replaceAll('```json', '')
              .replaceAll('```', '');
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

          return DailyProgress(
            progress: (parsed['progress'] as num?)?.toInt() ?? 0,
            pointsEarned: (parsed['points_earned'] as num?)?.toInt() ?? 0,
            rating: (parsed['rating'] as num?)?.toDouble() ?? 0.0,
            isComplete: (parsed['is_complete'] as bool?) ?? false,
            isAuthentic: (parsed['is_authentic'] as bool?) ?? true,
            verificationReason: (parsed['verification_reason'] as String?),
            motivationalQuote: (parsed['motivational_quote'] as String?),
          );
        }
      }

      // Fallback if AI fails
      return DailyProgress.calculateForDay(
        weekId: feedback.weekId,
        dayFeedbacks: [feedback],
        hoursPerDay: goal.timeline.workSchedule.hoursPerDay,
      );
    } catch (e) {
      logE('❌ verifyDailyProgress error: $e');
      return DailyProgress.calculateForDay(
        weekId: feedback.weekId,
        dayFeedbacks: [feedback],
        hoursPerDay: goal.timeline.workSchedule.hoursPerDay,
      );
    }
  }

  List<String> _fallbackSuggestionsList(LongGoalModel goal, int count) {
    final p = goal.analysis.averageProgress.round();
    final r = goal.analysis.averageRating;
    final suggestions = <String>[
      'Plan two focused blocks and log brief updates.',
      'Add short final reflection to raise quality.',
      'Protect time on weaker days to avoid misses.',
    ];
    if (p >= 85) {
      suggestions.insert(0, 'Replicate best routine and set similar sessions.');
    }
    if (r < 3.5) {
      suggestions.add('Include richer media to improve clarity and rating.');
    }
    return suggestions.take(count).toList();
  }

  String _bestWeekName(LongGoalModel goal) {
    int bestIndex = -1;
    double bestScore = -1;
    for (var i = 0; i < goal.goalLog.weeklyLogs.length; i++) {
      final week = goal.goalLog.weeklyLogs[i];
      final score = week.dailyFeedback
          .fold<int>(
            0,
            (sum, f) =>
                sum +
                (f.mediaUrl != null ? 5 : 0) +
                (f.feedbackText.isNotEmpty ? 10 : 0),
          )
          .toDouble();
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex >= 0 ? 'Week ${bestIndex + 1}' : 'N/A';
  }

  String _worstWeekName(LongGoalModel goal) {
    int worstIndex = -1;
    double worstScore = double.infinity;
    for (var i = 0; i < goal.goalLog.weeklyLogs.length; i++) {
      final week = goal.goalLog.weeklyLogs[i];
      final score = week.dailyFeedback
          .fold<int>(
            0,
            (sum, f) =>
                sum +
                (f.mediaUrl != null ? 5 : 0) +
                (f.feedbackText.isNotEmpty ? 10 : 0),
          )
          .toDouble();
      if (score < worstScore) {
        worstScore = score;
        worstIndex = i;
      }
    }
    return worstIndex >= 0 ? 'Week ${worstIndex + 1}' : 'N/A';
  }
}

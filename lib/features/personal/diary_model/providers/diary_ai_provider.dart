// lib/features/diary/providers/diary_ai_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';

// Import your custom message_bubbles
import '../../../../widgets/error_handler.dart';
import '../../../../../widgets/logger.dart';

import '../../../../../ai_services/services/universal_ai_service.dart';
import '../repositories/diary_repository.dart';

class DiaryAIProvider extends ChangeNotifier {
  final UniversalAIService _aiService = UniversalAIService();
  final DiaryRepository _diaryRepo = DiaryRepository();

  bool _isGeneratingQuestions = false;
  bool _isGeneratingSummary = false;
  String? _error;

  bool get isGeneratingQuestions => _isGeneratingQuestions;
  bool get isGeneratingSummary => _isGeneratingSummary;
  String? get error => _error;
  bool get isLoading => _isGeneratingQuestions || _isGeneratingSummary;

  // ================================================================
  // 📝 GENERATE DAILY QUESTIONS
  // ================================================================
  Future<List<Map<String, String>>> generateDailyQuestions({
    required String userId,
    List<Map<String, dynamic>>? linkedGoals,
    List<Map<String, dynamic>>? linkedTasks,
    DateTime? entryDate,
    bool showLoadingIndicator = true,
  }) async {
    _isGeneratingQuestions = true;
    _error = null;
    notifyListeners();

    // Show loading snackbar
    if (showLoadingIndicator) {
      ErrorHandler.showLoading('Generating reflection questions...');
    }

    try {
      logI('📝 Starting diary questions generation for user: \$userId');

      final date = entryDate ?? DateTime.now();

      // Build context about user's goals and tasks
      String goalsContext = '';
      if (linkedGoals != null && linkedGoals.isNotEmpty) {
        goalsContext = '\n\nUser\'s Active Goals:\n';
        for (var goal in linkedGoals.take(3)) {
          goalsContext += '- ${goal['title'] ?? goal['goal_text']}\n';
        }
        logD('Goals context built with ${linkedGoals.length} goals');
      }

      String tasksContext = '';
      if (linkedTasks != null && linkedTasks.isNotEmpty) {
        tasksContext = '\n\nUser\'s Tasks for Today:\n';
        for (var task in linkedTasks.take(5)) {
          tasksContext += '- ${task['title'] ?? task['task_text']}\n';
        }
        logD('Tasks context built with ${linkedTasks.length} tasks');
      }

      final prompt =
          '''
Generate 4 unique and engaging journal reflection questions for \$dayOfWeek, ${date.day} \$monthName.

Context:
- Date: \$dayOfWeek, ${date.day} \$monthName ${date.year}
- Time of day: ${_getTimeOfDay(date)}
$goalsContext\$tasksContext

Requirements:
1. Create exactly 4 questions
2. Mix question types:
   - 2 Multiple Choice Questions (MCQ) with 4 options each
   - 2 Short Answer Questions (open-ended)
3. Make questions:
   - Relevant to the date and day of week
   - Personal and reflective
   - Related to user's goals/tasks when applicable
   - Varied (emotions, achievements, challenges, gratitude, growth)
4. MCQ options should be diverse and realistic
5. Questions should encourage meaningful self-reflection

Return ONLY a JSON array with this EXACT structure (no markdown, no explanation):
[
  {
    "qna_number": 1,
    "type": "mcq",
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "answer": ""
  },
  {
    "qna_number": 2,
    "type": "short_answer",
    "question": "Question text here?",
    "answer": ""
  },
  {
    "qna_number": 3,
    "type": "mcq",
    "question": "Question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "answer": ""
  },
  {
    "qna_number": 4,
    "type": "short_answer",
    "question": "Question text here?",
    "answer": ""
  }
]
''';

      final systemPrompt = '''
You are a thoughtful journal coach who creates personalized reflection questions.
Generate varied, meaningful questions that help users gain insights about their day.
Consider the day of week, user's goals, and tasks to make questions relevant.
Always return valid JSON only, no additional text or markdown.
''';

      logD('Sending prompt to AI service...');

      final result = await _aiService.generateResponse(
        prompt: prompt,
        systemPrompt: systemPrompt,
        contextType: 'generation',
        aiUsageSource: 'diary_questions',
        sourceTable: 'diary_entries',
        maxTokens: 1500,
        temperature: 0.9,
      );

      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Failed to generate questions');
      }

      // Parse the JSON response
      final cleanResponse = _cleanJsonResponse(result.response);
      final List<dynamic> questionsJson = jsonDecode(cleanResponse);

      final questions = questionsJson.map((q) {
        return {
          'qna_number': q['qna_number'].toString(),
          'type': q['type'] as String,
          'question': q['question'] as String,
          if (q['type'] == 'mcq')
            'options': (q['options'] as List).cast<String>().join('|'),
          'answer': q['answer'] as String? ?? '',
        };
      }).toList();

      logI('✅ Generated ${questions.length} diary questions successfully');

      // Hide loading and show success
      if (showLoadingIndicator) {
        ErrorHandler.hideLoading();
        ErrorHandler.showSuccessSnackbar(
          'Questions Ready ${questions.length} reflection questions generated',
        );
      }

      _isGeneratingQuestions = false;
      notifyListeners();

      return questions;
    } catch (e, stackTrace) {
      logE(
        '❌ Error generating diary questions',
        error: e,
        stackTrace: stackTrace,
      );

      _error = e.toString();
      _isGeneratingQuestions = false;
      notifyListeners();

      // Hide loading and show error
      if (showLoadingIndicator) {
        ErrorHandler.hideLoading();
      }

      ErrorHandler.handleError(e, stackTrace, 'Generate diary questions');
      ErrorHandler.showWarningSnackbar(
        'Using default questions',
        title: 'AI Unavailable',
      );

      // Return fallback questions
      return _getFallbackQuestions();
    }
  }

  // ================================================================
  // 📊 GENERATE DIARY SUMMARY
  // ================================================================
  Future<String?> generateDiarySummary({
    required String userId,
    required String entryId,
    required String content,
    String? title,
    Map<String, dynamic>? mood,
    List<Map<String, dynamic>>? qnaAnswers,
    List<Map<String, dynamic>>? linkedGoals,
    List<Map<String, dynamic>>? linkedTasks,
    bool showLoadingIndicator = true,
  }) async {
    _isGeneratingSummary = true;
    _error = null;
    notifyListeners();

    if (showLoadingIndicator) {
      ErrorHandler.showLoading('Creating AI summary...');
    }

    try {
      logI('📊 Starting diary summary generation for entry: \$entryId');

      if (content.trim().isEmpty) {
        logW('No content provided for summary');
        _isGeneratingSummary = false;
        notifyListeners();

        if (showLoadingIndicator) {
          ErrorHandler.hideLoading();
        }

        return 'No content provided for summary.';
      }

      // Build Q&A context
      String qnaContext = '';
      if (qnaAnswers != null && qnaAnswers.isNotEmpty) {
        qnaContext = '\n\nReflection Answers:\n';
        int answeredCount = 0;
        for (var qa in qnaAnswers) {
          if (qa['answer']?.toString().trim().isNotEmpty ?? false) {
            qnaContext += 'Q: ${qa['question']}\n';
            qnaContext += 'A: ${qa['answer']}\n\n';
            answeredCount++;
          }
        }
        logD('Q&A context built with \$answeredCount answers');
      }

      // Build mood context
      String moodContext = '';
      if (mood != null && mood['label'] != null) {
        moodContext = '\nMood: ${mood['label']} (${mood['rating']}/10)';
        logD('Mood context: ${mood['label']}');
      }

      // Build goals context
      String goalsContext = '';
      if (linkedGoals != null && linkedGoals.isNotEmpty) {
        goalsContext = '\n\nActive Goals:\n';
        for (var goal in linkedGoals) {
          goalsContext += '- ${goal['title'] ?? goal['goal_text']}\n';
        }
      }

      // Build tasks context
      String tasksContext = '';
      if (linkedTasks != null && linkedTasks.isNotEmpty) {
        tasksContext = '\n\nTasks for Today:\n';
        for (var task in linkedTasks) {
          final status = task['is_completed'] == true ? '✓' : '○';
          tasksContext += '\$status ${task['title'] ?? task['task_text']}\n';
        }
      }

      final prompt =
          '''
Create a concise, insightful summary of this diary entry.

Title: ${title ?? 'Untitled Entry'}
\$moodContext

Diary Content:
\$content
$qnaContext$goalsContext\$tasksContext

Create a 2-3 sentence summary that:
1. Captures the main theme/events of the day
2. Notes emotional tone and significant moments
3. Highlights progress on goals/tasks if applicable
4. Is written in third person (e.g., "They felt...", "The day was...")
5. Is empathetic and encouraging

Return ONLY the summary text, no labels or formatting.
''';

      final systemPrompt = '''
You are an empathetic journal assistant who creates meaningful summaries.
Write concise, insightful summaries that capture the essence of someone's day.
Be warm, understanding, and focus on growth and positive patterns.
Keep summaries between 2-3 sentences, maximum 100 words.
''';

      logD('Sending summary prompt to AI service...');

      final result = await _aiService.generateResponse(
        prompt: prompt,
        systemPrompt: systemPrompt,
        contextType: 'summary',
        aiUsageSource: 'diary_summary',
        sourceTable: 'diary_entries',
        sourceRecordId: entryId,
        maxTokens: 200,
        temperature: 0.7,
      );

      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Failed to generate summary');
      }

      final summary = result.response.trim();
      logI(
        '✅ Generated diary summary: ${summary.substring(0, summary.length.clamp(0, 50))}...',
      );

      // Save summary to database
      final saved = await _diaryRepo.updateAISummary(
        entryId: entryId,
        summary: summary,
      );

      if (saved) {
        logD('Summary saved to database');
      } else {
        logW('Failed to save summary to database');
      }

      if (showLoadingIndicator) {
        ErrorHandler.hideLoading();
        ErrorHandler.showSuccessSnackbar(
          'Summary Created: AI summary has been generated',
        );
      }

      _isGeneratingSummary = false;
      notifyListeners();

      return summary;
    } catch (e, stackTrace) {
      logE(
        '❌ Error generating diary summary',
        error: e,
        stackTrace: stackTrace,
      );

      _error = e.toString();
      _isGeneratingSummary = false;
      notifyListeners();

      if (showLoadingIndicator) {
        ErrorHandler.hideLoading();
      }

      ErrorHandler.handleError(e, stackTrace, 'Generate diary summary');
      ErrorHandler.showErrorSnackbar(
        'Could not create AI summary',
        title: 'Summary Failed',
      );

      return null;
    }
  }

  // ================================================================
  // 🔄 REGENERATE QUESTIONS
  // ================================================================
  Future<List<Map<String, String>>> regenerateQuestions({
    required String userId,
    List<Map<String, dynamic>>? linkedGoals,
    List<Map<String, dynamic>>? linkedTasks,
    DateTime? entryDate,
  }) async {
    logI('🔄 Regenerating questions...');
    ErrorHandler.showInfoSnackbar('Regenerating: Creating new questions...');

    return generateDailyQuestions(
      userId: userId,
      linkedGoals: linkedGoals,
      linkedTasks: linkedTasks,
      entryDate: entryDate,
      showLoadingIndicator: false,
    );
  }

  // ================================================================
  // 🔄 REGENERATE SUMMARY
  // ================================================================
  Future<String?> regenerateSummary({
    required String userId,
    required String entryId,
    required String content,
    String? title,
    Map<String, dynamic>? mood,
    List<Map<String, dynamic>>? qnaAnswers,
    List<Map<String, dynamic>>? linkedGoals,
    List<Map<String, dynamic>>? linkedTasks,
  }) async {
    logI('🔄 Regenerating summary...');
    ErrorHandler.showInfoSnackbar('Regenerating: Creating new summary...');

    return generateDiarySummary(
      userId: userId,
      entryId: entryId,
      content: content,
      title: title,
      mood: mood,
      qnaAnswers: qnaAnswers,
      linkedGoals: linkedGoals,
      linkedTasks: linkedTasks,
      showLoadingIndicator: false,
    );
  }

  // ================================================================
  // 🛠️ HELPER METHODS
  // ================================================================
  String _cleanJsonResponse(String response) {
    logT('Cleaning JSON response...');

    String cleaned = response
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final startIndex = cleaned.indexOf('[');
    final endIndex = cleaned.lastIndexOf(']');

    if (startIndex != -1 && endIndex != -1) {
      cleaned = cleaned.substring(startIndex, endIndex + 1);
    }

    return cleaned;
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  List<Map<String, String>> _getFallbackQuestions() {
    logD('Using fallback questions');
    final random = DateTime.now().millisecondsSinceEpoch % 3;

    final questionSets = [
      [
        {
          'qna_number': '1',
          'type': 'mcq',
          'question': 'How would you describe your energy level today?',
          'options':
              'Energized and motivated|Balanced and steady|Tired but managing|Exhausted and drained',
          'answer': '',
        },
        {
          'qna_number': '2',
          'type': 'short_answer',
          'question': 'What was one thing that made you smile today?',
          'answer': '',
        },
        {
          'qna_number': '3',
          'type': 'mcq',
          'question': 'Did you make progress on any of your goals today?',
          'options':
              'Yes, significant progress|Yes, small steps|Not today|I need to refocus',
          'answer': '',
        },
        {
          'qna_number': '4',
          'type': 'short_answer',
          'question': 'What is one thing you learned about yourself today?',
          'answer': '',
        },
      ],
      [
        {
          'qna_number': '1',
          'type': 'mcq',
          'question':
              'How satisfied are you with how you spent your time today?',
          'options':
              'Very satisfied|Mostly satisfied|Somewhat satisfied|Not satisfied',
          'answer': '',
        },
        {
          'qna_number': '2',
          'type': 'short_answer',
          'question':
              'What challenge did you face today and how did you handle it?',
          'answer': '',
        },
        {
          'qna_number': '3',
          'type': 'mcq',
          'question': 'What was your biggest win today?',
          'options':
              'Completed an important task|Had a meaningful conversation|Took care of myself|Made progress on a goal',
          'answer': '',
        },
        {
          'qna_number': '4',
          'type': 'short_answer',
          'question': 'What are you grateful for today?',
          'answer': '',
        },
      ],
      [
        {
          'qna_number': '1',
          'type': 'mcq',
          'question': 'How well did you balance work and personal time today?',
          'options':
              'Excellent balance|Good balance|Slightly unbalanced|Very unbalanced',
          'answer': '',
        },
        {
          'qna_number': '2',
          'type': 'short_answer',
          'question':
              'What would you do differently if you could relive today?',
          'answer': '',
        },
        {
          'qna_number': '3',
          'type': 'mcq',
          'question': 'How connected did you feel to others today?',
          'options': 'Very connected|Somewhat connected|Neutral|Disconnected',
          'answer': '',
        },
        {
          'qna_number': '4',
          'type': 'short_answer',
          'question': 'What are you looking forward to tomorrow?',
          'answer': '',
        },
      ],
    ];

    return questionSets[random];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    logD('DiaryAIProvider disposed');
    super.dispose();
  }
}

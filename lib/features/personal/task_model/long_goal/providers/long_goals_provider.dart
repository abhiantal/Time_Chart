// lib/features/long_goals/providers/long_goals_provider.dart

import 'package:flutter/foundation.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/logger.dart';
import '../models/long_goal_model.dart';
import '../repositories/long_goals_repository.dart';
import '../services/long_goal_ai_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing Long Goals state with AI integration
/// Uses ChangeNotifier for state management
class LongGoalsProvider extends ChangeNotifier {
  final _repository = LongGoalsRepository();
  final _aiService = LongGoalAIService();

  // State
  bool _isLoading = false;
  bool _isAiGenerating = false;
  List<LongGoalModel> _goals = [];
  LongGoalModel? _currentGoal;
  String? _userId;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAiGenerating => _isAiGenerating;
  List<LongGoalModel> get goals => _goals;

  List<LongGoalModel> get activeGoals => _goals
      .where(
        (g) =>
            g.indicators.status == 'inProgress' ||
            g.indicators.status == 'upcoming' ||
            g.indicators.status == 'pending',
      )
      .toList();

  List<LongGoalModel> get completedGoals =>
      _goals.where((g) => g.indicators.status == 'completed').toList();

  LongGoalModel? get currentGoal => _currentGoal;
  String? get error => _error;
  String? get userId => _userId;

  // Computed getters
  int get totalGoalsCount => _goals.length;
  int get activeGoalsCount => activeGoals.length;
  int get completedGoalsCount => completedGoals.length;

  double get overallProgress {
    if (_goals.isEmpty) return 0.0;
    final totalProgress = _goals.fold<double>(
      0.0,
      (sum, goal) => sum + goal.analysis.averageProgress,
    );
    return totalProgress / _goals.length;
  }

  double get overallRating {
    if (_goals.isEmpty) return 0.0;
    final totalRating = _goals.fold<double>(
      0.0,
      (sum, goal) => sum + goal.analysis.averageRating,
    );
    return totalRating / _goals.length;
  }

  int get totalPointsEarned {
    return _goals.fold<int>(0, (sum, goal) => sum + goal.analysis.pointsEarned);
  }

  // ================================================================
  // GET GOAL BY ID
  // ================================================================
  Future<LongGoalModel?> getLongGoal(String goalId) async {
    // 1. Check local cache
    for (final g in _goals) {
      if (g.goalId == goalId) return g;
    }

    // 2. Fetch from repository
    try {
      final goal = await _repository.getGoalById(id: goalId);
      if (goal != null) {
        // Update local cache
        final index = _goals.indexWhere((g) => g.goalId == goal.goalId);
        if (index != -1) {
          _goals[index] = goal;
        } else {
          _goals.add(goal);
        }
        notifyListeners();
      }
      return goal;
    } catch (e) {
      logE('Error fetching long goal by ID', error: e);
      return null;
    }
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================
  Future<void> initialize(String userId) async {
    _userId = userId;
    await loadUserGoals();
  }

  // ================================================================
  // LOAD USER GOALS
  // ================================================================
  Future<void> loadUserGoals() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _clearError();

      final allGoals = await _repository.getUserGoals(userId: _userId!);
      _goals = allGoals;

      logI('✅ Loaded ${allGoals.length} goals');
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error loading goals');
      _setError('Failed to load goals');
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // CREATE GOAL
  // ================================================================
  // In long_goals_provider.dart

  Future<LongGoalModel?> createGoal({
    required String title,
    required String need,
    required String motivation,
    required String outcome,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> workDays,
    required int hoursPerDay,
    required DateTime preferredStartTime,
    required DateTime preferredEndTime,
    String? categoryId,
    String? categoryType,
    String? subTypes,
    String priority = 'normal',
    List<WeeklyPlan>? weeklyGoals,
  }) async {
    logI('🔍 Provider createGoal called - userId: $_userId');

    if (_userId == null) {
      logE(
        '❌ ERROR: userId is null! Provider not initialized. Call initialize(userId) first.',
      );
      return null;
    }

    try {
      _setLoading(true);
      _clearError();

      // Calculate total days
      final totalDays = endDate.difference(startDate).inDays;

      // Create new goal models with weekly goals
      final goal = LongGoalModel(
        id: const Uuid().v4(),
        userId: _userId!,
        title: title,
        categoryId: categoryId,
        categoryType: categoryType,
        subTypes: subTypes,
        description: GoalDescription(
          need: need,
          motivation: motivation,
          outcome: outcome,
        ),
        timeline: GoalTimeline(
          isUnspecified: false,
          startDate: startDate,
          endDate: endDate,
          workSchedule: WorkSchedule(
            workDays: workDays,
            hoursPerDay: hoursPerDay,
            preferredTimeSlot: TimeSlot(
              startingTime: preferredStartTime,
              endingTime: preferredEndTime,
            ),
          ),
        ),
        indicators: Indicators(
          status: 'pending',
          priority: priority,
          weeklyPlans: weeklyGoals ?? [],
        ),
        metrics: GoalMetrics(
          totalDays: totalDays,
          completedDays: 0,
          tasksPending: weeklyGoals?.length ?? 0,
        ),
        analysis: const GoalAnalysis(
          averageProgress: 0.0,
          averageRating: 0.0,
          pointsEarned: 0,
          suggestions: [],
        ),
        goalLog: GoalLog(
          weeklyLogs: weeklyGoals
                  ?.map((p) => WeeklyGoalLog(weekId: p.weekId, dailyFeedback: []))
                  .toList() ??
              [],
        ),
        socialInfo: const SocialInfo(isPosted: false),
        shareInfo: const ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Saves to database
      final createdGoal = await _repository.createGoal(
        userId: _userId!,
        goal: goal,
      );

      if (createdGoal != null) {
        _goals.add(createdGoal);
        _currentGoal = createdGoal;
        notifyListeners();
      }

      return createdGoal;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error creating goal');
      _setError('Failed to create goal');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // UPDATE GOAL DETAILS
  // ================================================================
  Future<LongGoalModel?> updateGoalDetails({
    required String goalId,
    String? title,
    String? need,
    String? motivation,
    String? outcome,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? workDays,
    int? hoursPerDay,
    DateTime? preferredStartTime,
    DateTime? preferredEndTime,
    String? categoryId,
    String? categoryType,
    String? subTypes,
    String? priority,
    bool? isUnspecified,
    List<WeeklyPlan>? weeklyGoals,
  }) async {
    logI('🔍 Provider updateGoalDetails called - userId: $_userId');

    if (_userId == null) {
      logE('❌ ERROR: userId is null! Provider not initialized.');
      return null;
    }

    try {
      _setLoading(true);
      _clearError();

      final existing = getGoalById(goalId);
      if (existing == null) {
        _setError('Goal not found');
        return null;
      }

      final updatedWorkSchedule = WorkSchedule(
        workDays: workDays ?? existing.timeline.workSchedule.workDays,
        hoursPerDay: hoursPerDay ?? existing.timeline.workSchedule.hoursPerDay,
        preferredTimeSlot:
            (preferredStartTime != null && preferredEndTime != null)
            ? TimeSlot(
                startingTime: preferredStartTime,
                endingTime: preferredEndTime,
              )
            : existing.timeline.workSchedule.preferredTimeSlot,
      );

      final updatedTimeline = existing.timeline.copyWith(
        isUnspecified: isUnspecified ?? existing.timeline.isUnspecified,
        startDate: startDate ?? existing.timeline.startDate,
        endDate: endDate ?? existing.timeline.endDate,
        workSchedule: updatedWorkSchedule,
      );

      final updatedIndicators = existing.indicators.copyWith(
        priority: priority ?? existing.indicators.priority,
      );

      final updatedDescription = GoalDescription(
        need: need ?? existing.description.need,
        motivation: motivation ?? existing.description.motivation,
        outcome: outcome ?? existing.description.outcome,
      );

      // Merge weekly plans if provided (preserve completion)
      List<WeeklyPlan> updatedWeeklyPlans = List.from(
        existing.indicators.weeklyPlans,
      );
      if (weeklyGoals != null && weeklyGoals.isNotEmpty) {
        for (var incoming in weeklyGoals) {
          final idx = updatedWeeklyPlans.indexWhere(
            (p) => p.weekId == incoming.weekId,
          );
          if (idx != -1) {
            updatedWeeklyPlans[idx] = updatedWeeklyPlans[idx].copyWith(
              weeklyGoal: incoming.weeklyGoal,
              mood: incoming.mood,
              isCompleted: incoming.isCompleted,
            );
          } else {
            updatedWeeklyPlans.add(incoming);
          }
        }
      }

      final updated = existing
          .copyWith(
            title: title ?? existing.title,
            categoryId: categoryId ?? existing.categoryId,
            categoryType: categoryType ?? existing.categoryType,
            subTypes: subTypes ?? existing.subTypes,
            description: updatedDescription,
            timeline: updatedTimeline,
            indicators: updatedIndicators.copyWith(
              weeklyPlans: updatedWeeklyPlans,
            ),
            updatedAt: DateTime.now(),
          )
          .recalculate();

      final saved = await _repository.updateGoal(goal: updated);
      if (saved != null) {
        _updateGoalInLists(saved);
        notifyListeners();
      } else {
        _setError('Failed to save changes');
      }

      return saved;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error updating goal');
      _setError('Failed to update goal');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // GENERATE WEEKLY GOAL WITH AI
  // ================================================================
  Future<WeeklyGoalLog?> generateWeeklyGoalWithAi({
    required LongGoalModel goal,
    required int weekNumber,
  }) async {
    if (_userId == null) return null;

    try {
      _setAiGenerating(true);
      _clearError();
      ErrorHandler.showLoading('Generating weekly goal with AI...');

      final result = await _aiService.generateWeeklyGoal(
        userId: _userId!,
        goalTitle: goal.title,
        need: goal.description.need,
        motivation: goal.description.motivation,
        outcome: goal.description.outcome,
        startDate: goal.timeline.startDate!,
        endDate: goal.timeline.endDate!,
        workDays: goal.timeline.workSchedule.workDays,
        hoursPerDay: goal.timeline.workSchedule.hoursPerDay,
        categoryType: goal.categoryType,
        subTypes: goal.subTypes,
        weekNumber: weekNumber,
      );

      ErrorHandler.hideLoading();

      if (result == null) {
        _setError('Failed to generate weekly goal');
        return null;
      }

      // Create weekly log from AI response
      final weekLog = WeeklyGoalLog(
        weekId: 'w$weekNumber',
        dailyFeedback: [],
      );

      logI('✅ Weekly goal generated with AI');
      ErrorHandler.showSuccessSnackbar(
        'AI has created your weekly plan',
        title: 'Weekly Goal Generated',
      );

      return weekLog;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error generating weekly goal');
      ErrorHandler.hideLoading();
      _setError('Failed to generate weekly goal');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  // ================================================================
  // ADD WEEKLY LOG
  // ================================================================
  Future<bool> addWeeklyLog({
    required String goalId,
    required WeeklyGoalLog weekLog,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedGoal = await _repository.addWeeklyLog(
        id: goalId,
        weekLog: weekLog,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to add weekly log');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error adding weekly log');
      _setError('Failed to add weekly log');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // ADD DAILY FEEDBACK
  // ================================================================
  Future<bool> addDailyFeedback({
    required String goalId,
    required String weekId,
    required String feedbackText,
    String? mediaUrl,
    int? feedbackDay,
    String? feedbackCount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Get current goal to determine feedback number
      final goal = _goals.firstWhere(
        (g) => g.goalId == goalId,
        orElse: () => throw Exception('Goal not found'),
      );

      final week = goal.goalLog.weeklyLogs.firstWhere(
        (w) => w.weekId == weekId,
        orElse: () => throw Exception('Week not found'),
      );

      final finalFeedbackCount =
          feedbackCount ?? (week.dailyFeedback.length + 1).toString();
      final finalFeedbackDay =
          feedbackDay ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      final feedback = DailyFeedback(
        weekId: weekId,
        feedbackDay: DateTime.fromMillisecondsSinceEpoch(finalFeedbackDay * 1000),
        feedbackCount: finalFeedbackCount,
        feedbackText: feedbackText,
        mediaUrl: mediaUrl,
      );

      final updatedGoal = await _repository.addDailyFeedback(
        id: goalId,
        weekId: weekId,
        feedback: feedback,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to add feedback');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error adding daily feedback');
      _setError('Failed to add feedback');
      return false;
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  // ================================================================
  // MARK WEEK COMPLETE
  // ================================================================
  Future<bool> markWeekComplete({
    required String goalId,
    required String weekId,
  }) async {
    if (_userId == null) {
      logE('❌ ERROR: userId is null! Cannot mark week complete.');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final updatedGoal = await _repository.markWeekComplete(
        id: goalId,
        weekId: weekId,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to mark week complete');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error marking week complete');
      _setError('Failed to mark week complete');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // GENERATE SUGGESTIONS WITH AI
  // ================================================================
  Future<List<String>?> generateSuggestions(LongGoalModel goal) async {
    if (_userId == null) return null;

    try {
      _setAiGenerating(true);
      _clearError();
      ErrorHandler.showLoading('Generating suggestions...');

      final suggestions = await _aiService.generateSuggestions(
        userId: _userId!,
        goal: goal,
      );

      ErrorHandler.hideLoading();

      if (suggestions != null && suggestions.isNotEmpty) {
        ErrorHandler.showSuccessSnackbar(
          'AI has analyzed your progress',
          title: 'Suggestions Ready',
        );
      }

      return suggestions;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error generating suggestions');
      ErrorHandler.hideLoading();
      _setError('Failed to generate suggestions');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  // ================================================================
  // ANALYZE WEEKLY FEEDBACK WITH AI
  // ================================================================
  Future<Map<String, dynamic>?> analyzeWeeklyFeedback({
    required LongGoalModel goal,
    required WeeklyGoalLog weekLog,
  }) async {
    if (_userId == null) return null;

    try {
      _setAiGenerating(true);
      _clearError();
      ErrorHandler.showLoading('Analyzing week performance...');

      final analysis = await _aiService.analyzeFeedback(
        userId: _userId!,
        goal: goal,
      );

      ErrorHandler.hideLoading();

      if (analysis != null) {
        ErrorHandler.showSuccessSnackbar(
          'Week performance analyzed',
          title: 'Analysis Complete',
        );
      }

      return analysis;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error analyzing feedback');
      ErrorHandler.hideLoading();
      _setError('Failed to analyze feedback');
      return null;
    } finally {
      _setAiGenerating(false);
    }
  }

  // ================================================================
  // SHARE VIA CHAT
  // ================================================================
  Future<bool> shareGoalViaChat({
    required String goalId,
    required String chatId,
    String? messageText,
    bool isLive = false,
  }) async {
    if (_userId == null) return false;

    try {
      _setLoading(true);

      // 1. Send Message
      final chatRepo = ChatRepository();
      await chatRepo.sendSharedContent(
        chatId: chatId,
        contentType: SharedContentType.longGoal,
        contentId: goalId,
        caption: messageText,
        mode: isLive ? 'live' : 'snapshot',
      );

      // 2. Update Goal Share Info
      final goal = getGoalById(goalId);
      if (goal != null) {
        final currentShareInfo = goal.shareInfo;
        final updatedShareInfo = currentShareInfo.copyWith(
          isShare: true,
          shareId:
              currentShareInfo.shareId?.copyWith(
                withId: chatId,
                live: isLive,
                time: DateTime.now(),
              ) ??
              SharedInfo(
                live: isLive,
                snapshotUrl: '',
                withId: chatId,
                time: DateTime.now(),
              ),
        );

        await _repository.updateShareInfo(
          id: goalId,
          shareInfo: updatedShareInfo,
        );

        // Update local state
        final updatedGoal = goal.copyWith(shareInfo: updatedShareInfo);
        _updateGoalInLists(updatedGoal);
        notifyListeners();
      }

      logI('✅ Goal shared via chat: $chatId');
      return true;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error sharing goal via chat');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // UPDATE STATUS
  // ================================================================
  Future<bool> updateGoalStatus({
    required String goalId,
    required String newStatus,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedGoal = await _repository.updateStatus(
        id: goalId,
        newStatus: newStatus,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to update status');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error updating status');
      _setError('Failed to update status');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // UPDATE SOCIAL INFO
  // ================================================================
  Future<bool> updateSocialInfo({
    required String goalId,
    required bool isPosted,
    bool? live,
    String? snapshotUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final socialInfo = SocialInfo(
        isPosted: isPosted,
        posted: isPosted && live != null
            ? PostedInfo(
                live: live,
                snapshotUrl: snapshotUrl,
                time: DateTime.now(),
              )
            : null,
      );

      final updatedGoal = await _repository.updateSocialInfo(
        id: goalId,
        socialInfo: socialInfo,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to update social info');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error updating social info');
      _setError('Failed to update social info');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // UPDATE SHARE INFO
  // ================================================================
  Future<bool> updateShareInfo({
    required String goalId,
    required bool isShare,
    String? withId,
    bool? live,
    String? snapshotUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final goal = getGoalById(goalId);
      if (goal == null) {
        _setError('Goal not found');
        return false;
      }

      final currentShareInfo = goal.shareInfo;
      final updatedShareInfo = currentShareInfo.copyWith(
        isShare: isShare,
        shareId: isShare && (withId != null || currentShareInfo.shareId != null)
            ? (currentShareInfo.shareId?.copyWith(
                    live: live,
                    snapshotUrl: snapshotUrl,
                    withId: withId,
                    time: DateTime.now(),
                  ) ??
                  SharedInfo(
                    live: live ?? false,
                    snapshotUrl: snapshotUrl,
                    withId: withId ?? '',
                    time: DateTime.now(),
                  ))
            : null,
      );

      final updatedGoal = await _repository.updateShareInfo(
        id: goalId,
        shareInfo: updatedShareInfo,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to update share info');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error updating share info');
      _setError('Failed to update share info');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // POST LONG GOAL
  // ================================================================
  Future<bool> postLongGoal({
    required String goalId,
    required bool isLive,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedGoal = await _repository.postLongGoal(
        id: goalId,
        isLive: isLive,
        caption: caption,
        visibility: visibility,
      );

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to post long goal');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error posting long goal');
      _setError('Failed to post long goal');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // DELETE POST
  // ================================================================
  Future<bool> deletePost(String postId) async {
    try {
      _setLoading(true);
      _clearError();

      // Find goal with this post
      final goal = _goals.firstWhere(
        (g) => g.socialInfo.posted?.postId == postId,
        orElse: () => throw Exception('Goal with post not found'),
      );

      final success = await _repository.deletePost(id: goal.goalId);

      if (success) {
        final refreshed = await _repository.getGoalById(id: goal.goalId);
        if (refreshed != null) {
          _updateGoalInLists(refreshed);
          notifyListeners();
        } else {
          await loadUserGoals();
        }
        return true;
      }

      _setError('Failed to delete post');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error deleting post');
      _setError('Failed to delete post');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // DELETE GOAL
  // ================================================================
  Future<bool> deleteGoal(String goalId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.deleteGoal(id: goalId);

      if (success) {
        _goals.removeWhere((g) => g.goalId == goalId);

        if (_currentGoal?.goalId == goalId) {
          _currentGoal = null;
        }

        notifyListeners();
      }

      return success;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error deleting goal');
      _setError('Failed to delete goal');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // RECALCULATE GOAL
  // ================================================================
  Future<bool> recalculateGoal(String goalId) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedGoal = await _repository.recalculateGoal(id: goalId);

      if (updatedGoal != null) {
        _updateGoalInLists(updatedGoal);
        notifyListeners();
        return true;
      }

      _setError('Failed to recalculate goal');
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error recalculating goal');
      _setError('Failed to recalculate goal');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ================================================================
  // SEARCH GOALS
  // ================================================================
  Future<List<LongGoalModel>> searchGoals(String query) async {
    if (_userId == null) return [];

    try {
      _clearError();
      return await _repository.searchGoals(userId: _userId!, query: query);
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace, 'Error searching goals');
      _setError('Failed to search goals');
      return [];
    }
  }

  // ================================================================
  // SET CURRENT GOAL
  // ================================================================
  void setCurrentGoal(LongGoalModel? goal) {
    _currentGoal = goal;
    notifyListeners();
  }

  // ================================================================
  // GET GOAL BY ID
  // ================================================================
  LongGoalModel? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((g) => g.goalId == goalId);
    } catch (e) {
      return null;
    }
  }

  // ================================================================
  // FILTER GOALS
  // ================================================================
  List<LongGoalModel> filterGoals({
    String? status,
    String? priority,
    String? categoryType,
  }) {
    var filtered = _goals;

    if (status != null) {
      filtered = filtered.where((g) => g.indicators.status == status).toList();
    }

    if (priority != null) {
      filtered = filtered
          .where((g) => g.indicators.priority == priority)
          .toList();
    }

    if (categoryType != null) {
      filtered = filtered.where((g) => g.categoryType == categoryType).toList();
    }

    return filtered;
  }

  // ================================================================
  // HELPER: UPDATE GOAL IN LISTS
  // ================================================================
  void _updateGoalInLists(LongGoalModel updatedGoal) {
    final index = _goals.indexWhere((g) => g.goalId == updatedGoal.goalId);
    if (index != -1) {
      _goals[index] = updatedGoal;
    }

    if (_currentGoal?.goalId == updatedGoal.goalId) {
      _currentGoal = updatedGoal;
    }
  }

  // ================================================================
  // STATE MANAGEMENT HELPERS
  // ================================================================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setAiGenerating(bool value) {
    _isAiGenerating = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      ErrorHandler.logError('Provider error: $error', null);
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // ================================================================
  // REFRESH
  // ================================================================
  Future<void> refresh() async {
    await loadUserGoals();
  }

  // ================================================================
  // CLEAR ALL DATA
  // ================================================================
  void clear() {
    _goals.clear();
    _currentGoal = null;
    _userId = null;
    _error = null;
    _isLoading = false;
    _isAiGenerating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    logI('🛑 LongGoalsProvider disposed');
    super.dispose();
  }
}

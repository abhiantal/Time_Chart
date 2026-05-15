// lib/features/personal/task_model/long_goal/repositories/long_goals_repository.dart

import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:uuid/uuid.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import '../models/long_goal_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';
import '../services/long_goal_ai_service.dart';


class LongGoalsRepository {
  final String? currentUserId;
  final PowerSyncService _powerSync;

  LongGoalsRepository({this.currentUserId, PowerSyncService? powerSync})
    : _powerSync = powerSync ?? PowerSyncService();

  static const String _tableName = 'long_goals';
  final UniversalMediaService _mediaService = UniversalMediaService();

  final _jsonbColumns = [
    'description',
    'timeline',
    'indicators',
    'metrics',
    'analysis',
    'goal_log',
    'social_info',
    'share_info',
  ];

  // ================================================================
  // CRUD OPERATIONS
  // ================================================================

  Future<List<LongGoalModel>> getUserGoals({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      logI(
        '📥 Fetching long goals for user: $userId (limit: $limit, offset: $offset)',
      );
      final query =
          '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
      ''';
      final results = await _powerSync.executeQuery(
        query,
        parameters: [userId, _tableName, limit, offset],
      );

      return results
          .map((row) => _rowToModel(row))
          .whereType<LongGoalModel>()
          .toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch user long goals');
      return [];
    }
  }

  Future<LongGoalModel?> getGoalById({required String id}) async {
    try {
      // Check if excluded locally
      final excluded = await _powerSync.executeQuery(
        'SELECT 1 FROM local_sync_exclusions WHERE excluded_id = ? AND table_name = ?',
        parameters: [id, _tableName],
      );
      if (excluded.isNotEmpty) {
        logI('🚫 Goal $id is excluded locally');
        return null;
      }

      final result = await _powerSync.getById(_tableName, id);
      if (result == null) return null;
      return _rowToModel(result);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch long goal by ID');
      return null;
    }
  }

  Future<LongGoalModel?> createGoal({
    required String userId,
    required LongGoalModel goal,
  }) async {
    try {
      logI('📝 Creating long goal: ${goal.title}');

      final data = goal.toJson();
      data['user_id'] = userId;
      data['id'] = goal.id.isNotEmpty ? goal.id : const Uuid().v4();

      await _powerSync.insert(_tableName, data);
      logI('✅ Long goal created locally');
      final newGoal = goal.copyWith(id: data['id']);

      // Schedule notifications
      // Notifications are now handled by the backend/modular architecture

      return newGoal;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Create long goal');
      return null;
    }
  }

  Future<LongGoalModel?> updateGoal({required LongGoalModel goal}) async {
    try {
      logI('🔄 Updating long goal: ${goal.id}');
      final data = goal.toJson();

      await _powerSync.update(_tableName, data, goal.id);
      logI('✅ Long goal updated locally');

      // Update notifications
      // Notifications are now handled by the backend/modular architecture

      return goal;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Update long goal');
      return null;
    }
  }

  Future<bool> deleteGoal({required String id}) async {
    try {
      logI('🗑️ Deleting long goal: $id');

      // Record exclusion before actual delete from local store
      await _recordExclusion(id);

      // Cancel notifications
      // Notifications are now handled by the backend/modular architecture

      await _powerSync.delete(_tableName, id);
      return true;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Delete long goal');
      return false;
    }
  }

  // ================================================================
  // RECORD EXCLUSION
  // ================================================================
  Future<void> _recordExclusion(String id) async {
    try {
      await _powerSync.insert('local_sync_exclusions', {
        'excluded_id': id,
        'table_name': _tableName,
        'created_at': DateTime.now().toIso8601String(),
      });
      logI('📍 Recorded local exclusion for $id');
    } catch (e) {
      logE('❌ Error recording exclusion', error: e);
    }
  }

  Future<List<LongGoalModel>> searchGoals({
    required String query,
    required String userId,
    int limit = 20,
  }) async {
    try {
      // In a real 1M user app, we'd use FTS or a server-side search.
      // For PowerSync/SQLite local, we can do a LIKE query.
      final sqlQuery =
          '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND title LIKE ?
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
        ORDER BY created_at DESC
        LIMIT ?
      ''';
      final results = await _powerSync.executeQuery(
        sqlQuery,
        parameters: [userId, '%$query%', _tableName, limit],
      );

      return results
          .map((row) => _rowToModel(row))
          .whereType<LongGoalModel>()
          .toList();
    } catch (e) {
      logE('Error searching goals', error: e);
      return [];
    }
  }

  Future<LongGoalModel?> recalculateGoal({required String id}) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final updatedGoal = goal.recalculate();
      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Recalculate goal');
      return null;
    }
  }

  // ================================================================
  // SOCIAL & SHARING
  // ================================================================

  Future<LongGoalModel?> postLongGoal({
    required String id,
    required bool isLive,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final postRepository = PostRepository();
      final post = await postRepository.createPostFromSource(
        sourceType: 'long_goal',
        sourceId: id,
        caption: caption ?? goal.title,
        visibility: visibility,
        isLive: isLive,
      );

      if (post != null) {
        final updatedSocial = goal.socialInfo.copyWith(
          isPosted: true,
          posted: PostedInfo(
            postId: post.id,
            live: isLive,
            time: DateTime.now(),
            snapshotUrl: post.media.isNotEmpty ? post.media.first.url : null,
          ),
        );
        final updatedGoal = goal.copyWith(socialInfo: updatedSocial);
        return await updateGoal(goal: updatedGoal);
      }
      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Post long goal');
      return null;
    }
  }

  Future<bool> deletePost({required String id}) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null || goal.socialInfo.posted?.postId == null) return false;

      final postRepository = PostRepository();
      final success = await postRepository.deletePost(
        goal.socialInfo.posted!.postId,
      );
      if (success) {
        final updatedSocial = goal.socialInfo.copyWith(
          isPosted: false,
          posted: null,
        );
        final updatedGoal = goal.copyWith(socialInfo: updatedSocial);
        await updateGoal(goal: updatedGoal);
        return true;
      }
      return false;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Delete post');
      return false;
    }
  }

  Future<LongGoalModel?> updateSocialInfo({
    required String id,
    required SocialInfo socialInfo,
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final updatedGoal = goal.copyWith(socialInfo: socialInfo);
      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Update social info');
      return null;
    }
  }

  Future<LongGoalModel?> updateShareInfo({
    required String id,
    required ShareInfo shareInfo,
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final updatedGoal = goal.copyWith(shareInfo: shareInfo);
      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Update share info');
      return null;
    }
  }

  Future<LongGoalModel?> updateStatus({
    required String id,
    required String newStatus,
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final updatedGoal = goal.copyWith(
        indicators: goal.indicators.copyWith(status: newStatus),
      );
      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Update status');
      return null;
    }
  }

  // ================================================================
  // GOAL LOG & FEEDBACK
  // ================================================================

  Future<LongGoalModel?> addWeeklyLog({
    required String id,
    required WeeklyGoalLog weekLog,
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final updatedLogs = List<WeeklyGoalLog>.from(goal.goalLog.weeklyLogs)
        ..add(weekLog);
      final updatedGoal = goal
          .copyWith(goalLog: GoalLog(weeklyLogs: updatedLogs))
          .recalculate();

      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Add weekly log');
      return null;
    }
  }

  Future<LongGoalModel?> addDailyFeedback({
    required String id,
    required String weekId,
    required DailyFeedback feedback,
  }) async {
    try {
      logI('💬 Adding daily feedback to goal: $id, week: $weekId');
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      // 1. AI Verification
      final aiService = LongGoalAIService();
      final verifiedProgress = await aiService.verifyDailyProgress(
        userId: currentUserId ?? goal.userId,
        goal: goal,
        feedback: feedback,
      );

      final enrichedFeedback = feedback.copyWith(
        dailyProgress: verifiedProgress,
      );

      // 2. Update Goal Log
      List<WeeklyGoalLog> logs = List.from(goal.goalLog.weeklyLogs);
      int weekIndex = logs.indexWhere((w) => w.weekId == weekId);

      if (weekIndex >= 0) {
        final week = logs[weekIndex];
        final updatedFeedbacks = List<DailyFeedback>.from(week.dailyFeedback)
          ..add(enrichedFeedback);
        logs[weekIndex] = week.copyWith(dailyFeedback: updatedFeedbacks);
      } else {
        logI('📅 Week $weekId not found, creating new entry');
        final newWeek = WeeklyGoalLog(
          weekId: weekId,
          dailyFeedback: [enrichedFeedback],
        );
        logs.add(newWeek);
      }

      // 3. Ensure WeeklyPlan exists in Indicators
      List<WeeklyPlan> weeklyPlans = List.from(goal.indicators.weeklyPlans);
      if (!weeklyPlans.any((p) => p.weekId == weekId)) {
        final newPlanRes = await aiService.generateWeeklyGoal(
          userId: currentUserId ?? goal.userId,
          goalTitle: goal.title,
          need: goal.description.need,
          motivation: goal.description.motivation,
          outcome: goal.description.outcome,
          startDate: goal.timeline.startDate ?? DateTime.now(),
          endDate: goal.timeline.endDate ?? DateTime.now(),
          workDays: goal.timeline.workSchedule.workDays,
          hoursPerDay: goal.timeline.workSchedule.hoursPerDay,
          weekNumber: weeklyPlans.length + 1,
        );

        weeklyPlans.add(
          WeeklyPlan(
            weekId: weekId,
            weeklyGoal: newPlanRes?['weekly_goal'] ?? 'New Week Milestone',
            mood: newPlanRes?['mood'] ?? 'focused',
            isCompleted: false,
          ),
        );
      }

      final updatedGoal = goal
          .copyWith(
            goalLog: GoalLog(weeklyLogs: logs),
            indicators: goal.indicators.copyWith(weeklyPlans: weeklyPlans),
          )
          .recalculate();

      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Add daily feedback');
      return null;
    }
  }

  Future<LongGoalModel?> markWeekComplete({
    required String id,
    required String weekId,
  }) async {
    try {
      final goal = await getGoalById(id: id);
      if (goal == null) return null;

      final weeklyPlans = List<WeeklyPlan>.from(goal.indicators.weeklyPlans);
      final index = weeklyPlans.indexWhere((p) => p.weekId == weekId);

      if (index == -1) return null;

      weeklyPlans[index] = weeklyPlans[index].copyWith(isCompleted: true);

      final updatedIndicators = goal.indicators.copyWith(
        weeklyPlans: weeklyPlans,
      );
      final updatedGoal = goal
          .copyWith(indicators: updatedIndicators)
          .recalculate();

      return await updateGoal(goal: updatedGoal);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Mark week complete');
      return null;
    }
  }

  // ================================================================
  // HELPERS
  // ================================================================

  LongGoalModel? _rowToModel(Map<String, dynamic> row) {
    try {
      final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
      return LongGoalModel.fromJson(map);
    } catch (e, stack) {
      logE(
        'Error converting row to LongGoalModel',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}

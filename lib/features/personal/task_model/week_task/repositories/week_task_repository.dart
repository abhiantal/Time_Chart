// lib/features/personal/task_model/week_task/repositories/week_task_repository.dart

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import 'package:uuid/uuid.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import '../models/week_task_model.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';

class WeekTaskRepository {
  final String? currentUserId;

  WeekTaskRepository({this.currentUserId});

  final _powerSync = PowerSyncService();
  static const String _tableName = 'weekly_tasks';
  final UniversalMediaService _mediaService = UniversalMediaService();

  final _jsonbColumns = [
    'sub_types',
    'about_task',
    'indicators',
    'timeline',
    'feedback',
    'metadata',
    'social_info',
    'share_info',
  ];

  // ================================================================
  // MEDIA UPLOAD
  // ================================================================

  /// Upload feedback media (image/video)
  Future<String?> uploadFeedbackMedia({
    required String userId,
    required String taskId,
    required String filePath,
    required String fileName,
    String? taskDate,
  }) async {
    try {
      logI('ðŸ“¤ Uploading feedback media: $fileName');

      final file = File(filePath);
      if (!file.existsSync()) {
        logW('âŒ File not found: $filePath');
        return null;
      }

      // Use UniversalMediaService for offline-first upload
      // It handles queueing, caching, and background sync
      final urls = await _mediaService.uploadTaskMedia(
        files: [file],
        taskType: 'weekly',
        taskId: taskId,
      );

      if (urls.isNotEmpty) {
        final url = urls.first;
        logI('âœ… Media queued/uploaded: $url');
        return url;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Upload feedback media');
      return null;
    }
  }

  /// Delete media from storage
  Future<bool> deleteMedia(String mediaPath) async {
    try {
      logI('ðŸ—‘ï¸ Deleting media: $mediaPath');

      return await _mediaService.deleteSingle(
        mediaUrl: mediaPath,
        bucket: MediaBucket.weeklyTaskMedia,
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Delete media');
      return false;
    }
  }

  // ================================================================
  // TASK CRUD OPERATIONS
  // ================================================================

  /// Watch user tasks (Real-time stream)
  Stream<List<WeekTaskModel>> watchUserTasks(
    String userId, {
    String? status,
    int limit = 50,
  }) {
    var query = '''
      SELECT * FROM $_tableName 
      WHERE user_id = ? 
      AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
    ''';
    final args = [userId, _tableName];

    if (status != null) {
      query += " AND json_extract(indicators, '\$.status') = ?";
      args.add(status);
    }

    query += ' ORDER BY created_at DESC LIMIT ?';
    args.add(limit.toString());

    return _powerSync.watchQuery(query, parameters: args).map((results) {
      return results
          .map((row) => _rowToModel(row))
          .whereType<WeekTaskModel>()
          .toList();
    });
  }

  /// Create new week task
  Future<WeekTaskModel?> createTask(WeekTaskModel task) async {
    try {
      logI('ðŸ“ Creating weekly task locally: ${task.aboutTask.taskName}');

      final taskData = task.toJson();

      // Ensure task_id exists
      if (taskData['task_id'] == null ||
          taskData['task_id'] == '' ||
          taskData['task_id'].toString().isEmpty) {
        taskData['task_id'] = const Uuid().v4();
      }

      // Map to DB column 'id' and remove legacy key
      taskData['id'] = taskData['task_id'];
      taskData.remove('task_id');

      // Map model fields to DB columns
      if (taskData.containsKey('daily_progress')) {
        taskData['feedback'] = taskData['daily_progress'];
        taskData.remove('daily_progress');
      }
      if (taskData.containsKey('summary')) {
        taskData['metadata'] = taskData['summary'];
        taskData.remove('summary');
      }

      // Ensure user_id exists
      if (taskData['user_id'] == null ||
          taskData['user_id'].toString().trim().isEmpty) {
        if (currentUserId != null && currentUserId!.isNotEmpty) {
          taskData['user_id'] = currentUserId;
        } else {
          logE(
            'âŒ Action denied: Cannot create weekly task without active user session (RLS violation)',
          );
          ErrorHandler.showErrorSnackbar(
            'You must be logged in to create a task',
            title: 'Session Error',
          );
          return null;
        }
      }

      await _powerSync.insert(_tableName, taskData);

      logI(
        'âœ… Weekly task created locally: ${task.id.isNotEmpty ? task.id : taskData['id']}',
      );

      // Return the model with the generated ID if it was missing
      if (task.id.isEmpty) {
        return task.copyWith(id: taskData['id']);
      }
      return task;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Create weekly task');
      return null;
    }
  }

  /// Update existing task
  Future<bool> updateTask(WeekTaskModel task) async {
    try {
      logI('ðŸ”„ Updating weekly task locally: ${task.id}');

      final taskData = task.toJson();
      taskData.remove('task_id'); // Don't update task_id

      // Rename keys to match DB schema
      if (taskData.containsKey('daily_progress')) {
        taskData['feedback'] = taskData['daily_progress'];
        taskData.remove('daily_progress');
      }
      if (taskData.containsKey('summary')) {
        taskData['metadata'] = taskData['summary'];
        taskData.remove('summary');
      }

      await _powerSync.update(_tableName, taskData, task.id);

      logI('âœ… Weekly task updated locally');
      return true;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Update weekly task');
      return false;
    }
  }

  /// Get task by ID
  Future<WeekTaskModel?> getTaskById(String taskId) async {
    try {
      logI('ðŸ“¥ Fetching task locally: $taskId');

      // Check if excluded locally
      final excluded = await _powerSync.executeQuery(
        'SELECT 1 FROM local_sync_exclusions WHERE excluded_id = ? AND table_name = ?',
        parameters: [taskId, _tableName],
      );
      if (excluded.isNotEmpty) {
        logI('ðŸš« Task $taskId is excluded locally');
        return null;
      }

      final result = await _powerSync.getById(_tableName, taskId);

      if (result == null) return null;

      return _rowToModel(result);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch weekly task');
      return null;
    }
  }

  /// Get all user tasks
  Future<List<WeekTaskModel>> getUserTasks(
    String userId, {
    String? status,
    int limit = 50,
    bool includeCompleted = true,
  }) async {
    try {
      logI('ðŸ“¥ Fetching user tasks locally: $userId');

      String query = '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
      ''';
      final args = [userId, _tableName];

      query += ' ORDER BY created_at DESC LIMIT ?';
      args.add(limit.toString());

      final results = await _powerSync.executeQuery(query, parameters: args);

      var tasks = results
          .map((row) => _rowToModel(row))
          .whereType<WeekTaskModel>()
          .toList();

      if (status != null) {
        tasks = tasks.where((t) => t.indicators.status == status).toList();
      }

      logI('âœ… Fetched ${tasks.length} tasks');
      return tasks;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch user tasks');
      return [];
    }
  }

  /// Helper to convert SQLite row to WeekTaskModel
  WeekTaskModel? _rowToModel(Map<String, dynamic> row) {
    try {
      final map = _powerSync.parseJsonbFields(row, _jsonbColumns);

      // Map DB id -> model task_id
      if (map['task_id'] == null && map['id'] != null) {
        map['task_id'] = map['id'];
      }

      return WeekTaskModel.fromJson(map);
    } catch (e, stack) {
      logE(
        'Error converting row to WeekTaskModel',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get tasks scheduled for today
  Future<List<WeekTaskModel>> getTasksForToday(String userId) async {
    try {
      final today = _getCurrentDayName();
      logI('ðŸ“… Fetching tasks for: $today');

      final allTasks = await getUserTasks(userId);

      return allTasks.where((task) {
        return task.isDateScheduled(DateTime.now()) && task.isActive;
      }).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch today tasks');
      return [];
    }
  }

  /// Get tasks for a specific date
  Future<List<WeekTaskModel>> getTasksForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dayName = DateFormat('EEEE').format(date).toLowerCase();
      logI('ðŸ“… Fetching tasks for: $dayName');

      final allTasks = await getUserTasks(userId);

      return allTasks.where((task) {
        return task.isDateScheduled(date) && task.isActive;
      }).toList();
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Fetch tasks for date');
      return [];
    }
  }

  /// Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      logI('ðŸ—‘ï¸ Deleting task: $taskId');

      // First, delete all associated media
      final task = await getTaskById(taskId);
      if (task != null) {
        for (var progress in task.dailyProgress) {
          for (var feedback in progress.feedbacks) {
            if (feedback.mediaUrl != null && feedback.mediaUrl!.isNotEmpty) {
              try {
                await deleteMedia(feedback.mediaUrl!);
              } catch (me) {
                logW('âš ï¸ Failed to delete media during task deletion: $me');
                // Continue with task deletion regardless
              }
            }
          }
        }
      }

      // Record exclusion before actual delete from local store
      await _recordExclusion(taskId);

      await _powerSync.delete(_tableName, taskId);

      logI('âœ… Task deleted locally');
      return true;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Delete task');
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
      logI('ðŸ“ Recorded local exclusion for $id');
    } catch (e) {
      logE('âŒ Error recording exclusion', error: e);
    }
  }

  String _getCurrentDayName() {
    return DateFormat('EEEE').format(DateTime.now()).toLowerCase();
  }

  // ================================================================
  // DAILY PROGRESS & FEEDBACK
  // ================================================================

  /// Add media feedback to a specific day
  Future<WeekTaskModel?> addMediaFeedback({
    required String taskId,
    required DateTime date,
    required String mediaUrl,
  }) async {
    try {
      logI('ðŸ“¸ Adding media feedback to task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) {
        logE('âŒ Task not found: $taskId');
        return null;
      }

      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final dayName = DateFormat('EEEE').format(date);

      // Find or create daily progress
      List<DailyProgress> updatedProgress = List.from(task.dailyProgress);
      int existingIndex = updatedProgress.indexWhere(
        (p) => p.taskDate == dateStr,
      );

      DailyProgress dayProgress;
      if (existingIndex >= 0) {
        dayProgress = updatedProgress[existingIndex];
      } else {
        dayProgress = DailyProgress(
          taskDate: dateStr,
          dayName: dayName,
          feedbacks: [],
          dailyMetrics: DayMetrics.empty,
        );
      }

      // Create new feedback

      final newFeedback = DailyFeedback(
        feedbackNumber: (dayProgress.feedbacks.length + 1).toString(),
        text: '',
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
      );

      // Update day progress
      final updatedFeedbacks = [...dayProgress.feedbacks, newFeedback];
      dayProgress = dayProgress.copyWith(
        feedbacks: updatedFeedbacks,
        dailyMetrics: dayProgress.dailyMetrics.copyWith(
          isComplete: true, // At least one feedback = complete
        ),
      );

      // Manual recalculation removed - task.recalculate() handles it below
      
      // Update list
      if (existingIndex >= 0) {
        updatedProgress[existingIndex] = dayProgress;
      } else {
        updatedProgress.add(dayProgress);
      }

      // Recalculate and save
      final updatedTask = task
          .copyWith(feedback: task.feedback.copyWith(dailyProgress: updatedProgress))
          .recalculate();

      final success = await updateTask(updatedTask);
      if (success) {
        logI('âœ… Media feedback added successfully');
        return updatedTask;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Add media feedback');
      return null;
    }
  }

  /// Add final text to a day (only allowed once, at the end)
  Future<WeekTaskModel?> addFinalText({
    required String taskId,
    required DateTime date,
    required String text,
  }) async {
    try {
      logI('ðŸ“ Adding final text to task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) {
        logE('âŒ Task not found: $taskId');
        return null;
      }

      final dateStr = DateFormat('dd-MM-yyyy').format(date);

      List<DailyProgress> updatedProgress = List.from(task.dailyProgress);
      int existingIndex = updatedProgress.indexWhere(
        (p) => p.taskDate == dateStr,
      );

      if (existingIndex < 0) {
        logW('âŒ No progress found for this date. Add media first.');
        return null;
      }

      DailyProgress dayProgress = updatedProgress[existingIndex];

      // Update with final text (Add as a special feedback or update last one)
      final updatedFeedbacks = [...dayProgress.feedbacks];
      if (updatedFeedbacks.isNotEmpty) {
        final last = updatedFeedbacks.removeLast();
        updatedFeedbacks.add(DailyFeedback(
          feedbackNumber: last.feedbackNumber,
          text: text,
          mediaUrl: last.mediaUrl,
          timestamp: last.timestamp,
          isPass: last.isPass,
          verificationReason: last.verificationReason,
        ));
      } else {
        updatedFeedbacks.add(DailyFeedback(
          feedbackNumber: '1',
          text: text,
          mediaUrl: null,
          timestamp: DateTime.now(),
        ));
      }

      dayProgress = dayProgress.copyWith(feedbacks: updatedFeedbacks);
      // Manual recalculation removed - task.recalculate() handles it below
      
      updatedProgress[existingIndex] = dayProgress;

      final updatedTask = task
          .copyWith(feedback: task.feedback.copyWith(dailyProgress: updatedProgress))
          .recalculate();

      final success = await updateTask(updatedTask);
      if (success) {
        logI('âœ… Final text added successfully (+10 points)');
        return updatedTask;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Add final text');
      return null;
    }
  }

  /// Mark a day as missed (applies -50 penalty)
  Future<WeekTaskModel?> markDayAsMissed({
    required String taskId,
    required DateTime date,
  }) async {
    try {
      logI('âš ï¸ Marking day as missed: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) return null;

      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final dayName = DateFormat('EEEE').format(date);

      List<DailyProgress> updatedProgress = List.from(task.dailyProgress);
      int existingIndex = updatedProgress.indexWhere(
        (p) => p.taskDate == dateStr,
      );

      DailyProgress dayProgress;
      if (existingIndex >= 0) {
        dayProgress = updatedProgress[existingIndex].copyWith(
          dailyMetrics: updatedProgress[existingIndex].dailyMetrics.copyWith(
            isComplete: false,
          ),
        );
      } else {
        dayProgress = DailyProgress(
          taskDate: dateStr,
          dayName: dayName,
          feedbacks: [],
          dailyMetrics: DayMetrics.empty,
        );
      }

      // Manual recalculation removed - task.recalculate() handles it below
      
      if (existingIndex >= 0) {
        updatedProgress[existingIndex] = dayProgress;
      } else {
        updatedProgress.add(dayProgress);
      }

      final updatedTask = task
          .copyWith(feedback: task.feedback.copyWith(dailyProgress: updatedProgress))
          .recalculate();

      final success = await updateTask(updatedTask);
      if (success) {
        logI('âœ… Day marked as missed (-50 penalty applied)');
        return updatedTask;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Mark day as missed');
      return null;
    }
  }

  /// Get progress for a specific date
  Future<DailyProgress?> getDailyProgress({
    required String taskId,
    required DateTime date,
  }) async {
    try {
      final task = await getTaskById(taskId);
      return task?.getProgressForDate(date);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Get daily progress');
      return null;
    }
  }

  /// Check if can add feedback (cooldown check)
  /// Cooldown check (removed)
  Future<bool> canAddFeedback({
    required String taskId,
    required DateTime date,
  }) async {
    return true;
  }

  /// Time until next feedback (removed)
  Future<Duration> getTimeUntilNextFeedback({
    required String taskId,
    required DateTime date,
  }) async {
    return Duration.zero;
  }

  // ================================================================
  // AUTO-MARK MISSED DAYS
  // ================================================================

  /// Auto-mark all missed days (call daily or on app start)
  Future<void> autoMarkMissedDays(String userId) async {
    try {
      logI('ðŸ” Auto-checking missed days for user: $userId');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final tasks = await getUserTasks(userId);

      for (var task in tasks) {
        if (!task.isActive) continue;

        DateTime current = task.timeline.startingTime;
        bool hasChanges = false;

        while (current.isBefore(today)) {
          if (task.isDateScheduled(current)) {
            final progress = task.getProgressForDate(current);
            if (progress == null || progress.feedbacks.isEmpty) {
              // This day was missed
              await markDayAsMissed(taskId: task.id, date: current);
              hasChanges = true;
            }
          }
          current = current.add(const Duration(days: 1));
        }

        if (hasChanges) {
          logI('âš ï¸ Missed days marked for task: ${task.aboutTask.taskName}');
        }
      }

      logI('âœ… Missed days check completed');
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Auto-mark missed days');
    }
  }

  // ================================================================
  // TASK COMPLETION
  // ================================================================

  /// Complete entire week task
  Future<WeekTaskModel?> completeWeekTask({
    required String taskId,
    String? finalSummary,
  }) async {
    try {
      logI('âœ… Completing weekly task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) return null;

      // Update indicators
      final updatedIndicators = task.indicators.copyWith(status: 'completed');

      // Update summary with completion data
      final updatedSummary = WeeklySummary.calculate(
        dailyProgress: task.dailyProgress,
        timeline: task.timeline,
        scheduledDays: task.scheduledDays,
        taskStack: task.taskStack,
        createdAt: task.createdAt,
      );

      final now = DateTime.now();
      final adjustedEnd = DateTime(
        now.year,
        now.month,
        now.day,
        task.timeline.endingTime.hour,
        task.timeline.endingTime.minute,
        task.timeline.endingTime.second,
      );
      final updatedTask = task.copyWith(
        indicators: updatedIndicators,
        summary: updatedSummary,
        timeline: task.timeline.copyWith(endingTime: adjustedEnd),
      );

      final success = await updateTask(updatedTask);
      if (success) {
        logI('âœ… Weekly task completed');
        return updatedTask;
      }

      return null;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Complete weekly task');
      return null;
    }
  }

  // ================================================================
  // AUTO-REPEAT TASK (WEEKLY)
  // ================================================================

  /// Repeat task for next week
  Future<WeekTaskModel?> repeatTask(String taskId) async {
    try {
      logI('ðŸ”„ Auto-repeating task: $taskId');

      final originalTask = await getTaskById(taskId);
      if (originalTask == null) return null;

      final baseStartDate = originalTask.timeline.startingDate;
      final baseEndDate = originalTask.timeline.expectedEndingDate;
      final baseStartTime = originalTask.timeline.startingTime;
      final baseEndTime = originalTask.timeline.endingTime;

      final nextWeekStartDate = baseStartDate.add(const Duration(days: 7));
      final nextWeekEndDate = baseEndDate.add(const Duration(days: 7));

      final nextWeekStartTime = DateTime(
        nextWeekStartDate.year,
        nextWeekStartDate.month,
        nextWeekStartDate.day,
        baseStartTime.hour,
        baseStartTime.minute,
        baseStartTime.second,
      );
      final nextWeekEndTime = DateTime(
        nextWeekEndDate.year,
        nextWeekEndDate.month,
        nextWeekEndDate.day,
        baseEndTime.hour,
        baseEndTime.minute,
        baseEndTime.second,
      );

      final newTask = WeekTaskModel(
        id: const Uuid().v4(),
        userId: originalTask.userId,
        categoryId: originalTask.categoryId,
        categoryType: originalTask.categoryType,
        subTypes: originalTask.subTypes,
        aboutTask: originalTask.aboutTask,
        indicators: Indicators(
          status: 'pending',
          priority: originalTask.indicators.priority,
        ),
        timeline: TaskTimeline(
          taskDays: originalTask.timeline.taskDays,
          startingDate: nextWeekStartDate,
          expectedEndingDate: nextWeekEndDate,
          startingTime: nextWeekStartTime,
          endingTime: nextWeekEndTime,
          taskDuration: originalTask.timeline.taskDuration,
        ),
        feedback: WeekTaskFeedback(dailyProgress: []),
        summary: WeeklySummary.empty,
        socialInfo: const SocialInfo(isPosted: false),
        shareInfo: const ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createTask(newTask);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Repeat task');
      return null;
    }
  }

  // ================================================================
  // MISSING METHODS IMPLEMENTATION
  // ================================================================

  Future<void> checkAndRepeatTasks(String userId) async {
    await autoMarkMissedDays(userId);
    // Logic to check for completed/expired tasks and repeat them if needed
    // For now, just a placeholder as autoMarkMissedDays is the main periodic check
  }

  Future<Map<String, dynamic>> getTaskStats(String userId) async {
    final tasks = await getUserTasks(userId);
    int completed = tasks
        .where((t) => t.indicators.status == 'completed')
        .length;
    int pending = tasks.where((t) => t.isActive).length;
    return {'completed': completed, 'pending': pending, 'total': tasks.length};
  }

  Future<Map<String, dynamic>> getStreakStats(String userId) async {
    // Placeholder for streak calculation
    return {'current_streak': 0, 'best_streak': 0};
  }

  Future<String?> createPostFromTask(
    WeekTaskModel task, {
    required bool isLive,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      final postRepository = PostRepository();
      final post = await postRepository.createPostFromSource(
        sourceType: 'weekly_task',
        sourceId: task.id,
        isLive: isLive,
        caption: caption,
        visibility: visibility,
      );
      return post?.id;
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'createPostFromTask');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPostWithFullData(
    String postId,
    String userId,
  ) async {
    // Delegate to PostRepository
    return null;
  }

  Future<bool> togglePostLiveStatus(String postId, bool isLive) async {
    // Delegate to PostRepository
    return false;
  }

  Future<bool> updatePostCaption(String postId, String caption) async {
    // Delegate to PostRepository
    return false;
  }

  Future<bool> deletePost(String postId, String userId) async {
    try {
      final postRepository = PostRepository();
      return await postRepository.deletePost(postId);
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'deletePost');
      return false;
    }
  }

  Future<bool> shareTaskViaChat(
    String taskId,
    String chatId,
    String message,
  ) async {
    // Create a message with task attachment
    // Delegate to ChatMessageRepository
    return false;
  }

  Future<bool> unshareTaskFromChat(String taskId, String chatId) async {
    // Remove task attachment from chat
    return false;
  }

  Future<List<WeekTaskModel>> getSharedTasksInChat(
    String chatId,
    String userId,
  ) async {
    // Get tasks shared in this chat
    return [];
  }

  Future<bool> isTaskSharedInChat(String taskId, {String? chatId}) async {
    return false;
  }
}

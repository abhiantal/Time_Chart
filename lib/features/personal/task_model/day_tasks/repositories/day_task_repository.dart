// lib/features/personal/task_model/day_tasks/repositories/day_task_repository.dart

import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/models/day_task_model.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';
import 'package:uuid/uuid.dart';

class DayTaskRepository {
  final _powerSync = PowerSyncService();
  static const String _tableName = 'day_tasks';

  // Singleton pattern
  static final DayTaskRepository _instance = DayTaskRepository._internal();
  factory DayTaskRepository() => _instance;
  DayTaskRepository._internal();

  /// Get current user ID from PowerSync service or Supabase
  String get currentUserId => PowerSyncService().currentUserId ?? '';

  final _jsonbColumns = [
    'about_task',
    'indicators',
    'timeline',
    'feedback',
    'metadata',
    'social_info',
    'share_info',
  ];

  // ================================================================
  // CREATE TASK
  // ================================================================
  Future<DayTaskModel?> createTask(DayTaskModel task) async {
    try {
      logI('📝 Creating day task locally: ${task.aboutTask.taskName}');

      final taskData = task.toJson();

      // Ensure id exists
      if (taskData['task_id'] == null ||
          taskData['task_id'] == '' ||
          taskData['task_id'].toString().isEmpty) {
        taskData['task_id'] = const Uuid().v4();
      }

      // Map to DB column 'id' and remove legacy key
      final generatedId = taskData['task_id'];
      taskData['id'] = generatedId;
      taskData.remove('task_id');

      // Ensure user_id exists FIRST to satisfy Supabase RLS policies
      if (taskData['user_id'] == null ||
          taskData['user_id'].toString().trim().isEmpty) {
        final currentId = currentUserId;
        if (currentId.isNotEmpty) {
          taskData['user_id'] = currentId;
        } else {
          logE(
            '❌ Action denied: Cannot create task without active user session (RLS violation)',
          );
          ErrorHandler.showErrorSnackbar(
            'You must be logged in to create a task',
            title: 'Session Error',
          );
          return null;
        }
      }

      await _powerSync.insert(_tableName, taskData);

      logI('✅ Task created locally');

      // Return the model with the generated ID if it was missing
      if (task.id.isEmpty) {
        return task.copyWith(id: generatedId);
      }
      return task;
    } catch (e, stack) {
      logE('❌ Error creating task', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Could not create task', title: 'Error');
      return null;
    }
  }

  // ================================================================
  // UPDATE TASK
  // ================================================================
  Future<DayTaskModel?> updateTask(DayTaskModel task) async {
    try {
      logI('🔄 Updating task locally: ${task.id}');

      if (task.id.isEmpty) {
        logE('❌ Cannot update task: id is empty');
        return null;
      }

      final taskData = task.toJson();

      // Removed obsolete feedback looping for clean media URLs, handled by models now if needed.

      taskData.remove('created_at'); // Don't update created_at
      taskData.remove('task_id'); // Don't update task_id (it's id)
      taskData['updated_at'] = DateTime.now().toIso8601String();

      await _powerSync.update(_tableName, taskData, task.id);

      logI('✅ Task updated locally');
      return task.copyWith(updatedAt: DateTime.parse(taskData['updated_at']));
    } catch (e, stack) {
      logE('❌ Error updating task', error: e, stackTrace: stack);
      ErrorHandler.showErrorSnackbar('Could not update task', title: 'Error');
      return null;
    }
  }

  // ================================================================
  // GET TASK BY ID
  // ================================================================
  Future<DayTaskModel?> getTaskById(String taskId) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot fetch task: id is empty');
        return null;
      }

      // Check if excluded locally
      final excluded = await _powerSync.executeQuery(
        'SELECT 1 FROM local_sync_exclusions WHERE excluded_id = ? AND table_name = ?',
        parameters: [taskId, _tableName],
      );
      if (excluded.isNotEmpty) {
        logI('🚫 Task $taskId is excluded locally');
        return null;
      }

      final result = await _powerSync.getById(_tableName, taskId);

      if (result == null) return null;

      // Map DB id -> model task_id
      final map = _powerSync.parseJsonbFields(result, _jsonbColumns);
      if (map['task_id'] == null && map['id'] != null) {
        map['task_id'] = map['id'];
      }

      return DayTaskModel.fromJson(map);
    } catch (e, stack) {
      logE('❌ Error fetching task', error: e, stackTrace: stack);
      return null;
    }
  }

  // ================================================================
  // GET USER TASKS
  // ================================================================
  Future<List<DayTaskModel>> getUserTasks(
    String userId, {
    DateTime? date,
    String? status,
    int limit = 50,
  }) async {
    try {
      if (userId.isEmpty) {
        logE('❌ Cannot fetch tasks: user_id is empty');
        return [];
      }

      logI('📥 Fetching tasks locally for user: $userId');

      var query = '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
      ''';
      final List<Object?> args = [userId, _tableName];

      if (date != null) {
        final dateStr = date.toIso8601String().split('T')[0];
        query += " AND json_extract(timeline, '\$.task_date') = ?";
        args.add(dateStr);
        logI('🗓️ Filtering by date: $dateStr');
      }

      if (status != null) {
        query += " AND json_extract(indicators, '\$.status') = ?";
        args.add(status);
        logI('📊 Filtering by status: $status');
      }

      query += ' ORDER BY created_at DESC LIMIT ?';
      args.add(limit.toString());

      final results = await _powerSync.executeQuery(query, parameters: args);

      final tasks = results.map((row) {
        final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
        if (map['task_id'] == null && map['id'] != null) {
          map['task_id'] = map['id'];
        }
        return DayTaskModel.fromJson(map);
      }).toList();

      logI('✅ Fetched ${tasks.length} tasks locally');
      return tasks;
    } catch (e, stack) {
      logE('❌ Error fetching user tasks', error: e, stackTrace: stack);
      return [];
    }
  }

  // ================================================================
  // WATCH USER TASKS
  // ================================================================
  Stream<List<DayTaskModel>> watchUserTasks(
    String userId, {
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 1000,
  }) {
    var query = '''
      SELECT * FROM $_tableName 
      WHERE user_id = ? 
      AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
    ''';
    final List<Object?> args = [userId, _tableName];

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query += " AND json_extract(timeline, '\$.task_date') = ?";
      args.add(dateStr);
    } else {
      if (startDate != null) {
        final startStr = startDate.toIso8601String().split('T')[0];
        query += " AND json_extract(timeline, '\$.task_date') >= ?";
        args.add(startStr);
      }
      if (endDate != null) {
        final endStr = endDate.toIso8601String().split('T')[0];
        query += " AND json_extract(timeline, '\$.task_date') <= ?";
        args.add(endStr);
      }
    }

    if (status != null) {
      query += " AND json_extract(indicators, '\$.status') = ?";
      args.add(status);
    }

    query += ' ORDER BY created_at DESC LIMIT ?';
    args.add(limit.toString());

    return _powerSync.watchQuery(query, parameters: args).map((results) {
      return results.map((row) {
        final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
        if (map['task_id'] == null && map['id'] != null) {
          map['task_id'] = map['id'];
        }
        return DayTaskModel.fromJson(map);
      }).toList();
    });
  }

  // ================================================================
  // ADD FEEDBACK - Simplified
  // ================================================================
  Future<DayTaskModel?> addFeedback(String taskId, Comment comment) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot add feedback: task_id is empty');
        return null;
      }

      logI('💬 Adding feedback to task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) {
        logE('❌ Task not found: $taskId');
        return null;
      }

      // Append comment
      final List<Comment> updatedComments = [
        ...task.feedback.comments,
        comment,
      ];
      final updatedFeedback = Feedback(comments: updatedComments);

      // Status update: if currently pending/upcoming, transition to inProgress
      final currentStatus = task.indicators.status;
      final newStatus = (currentStatus == 'pending' || currentStatus == 'upcoming')
          ? 'inProgress'
          : currentStatus;

      final updatedIndicators = Indicators(
        status: newStatus,
        priority: task.indicators.priority,
      );

      final updatedTask = task.copyWith(
        feedback: updatedFeedback,
        indicators: updatedIndicators,
        updatedAt: DateTime.now(),
      );

      return await updateTask(updatedTask);
    } catch (e, stack) {
      logE('❌ Error adding feedback', error: e, stackTrace: stack);
      return null;
    }
  }

  // ================================================================
  // UPDATE PROGRESS - Uses model's recalculate method
  // ================================================================
  Future<bool> updateProgress(String taskId, int progress) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot update progress: task_id is empty');
        return false;
      }

      if (progress < 0 || progress > 100) {
        logE('❌ Invalid progress value: $progress (must be 0-100)');
        return false;
      }

      logI('📊 Updating progress for task: $taskId to $progress%');

      final task = await getTaskById(taskId);
      if (task == null) {
        logE('❌ Task not found: $taskId');
        return false;
      }

      // Update metadata with new progress
      final updatedMetadata = task.metadata.copyWith(
        progress: progress,
        isComplete: progress >= 100,
      );

      final updatedTask = task.copyWith(metadata: updatedMetadata);

      // Use model's recalculate method
      final recalculatedTask = updatedTask.recalculate();

      final result = await updateTask(recalculatedTask);
      return result != null;
    } catch (e, stack) {
      logE('❌ Error updating progress', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // COMPLETE TASK - Uses model's recalculate method
  // ================================================================
  Future<bool> completeTask(String taskId, String summary) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot complete task: task_id is empty');
        return false;
      }

      logI('✅ Completing task: $taskId');

      final task = await getTaskById(taskId);
      if (task == null) {
        logE('❌ Task not found: $taskId');
        return false;
      }

      final now = DateTime.now();

      // Check if user has feedback
      final hasFeedback = task.feedback.comments.isNotEmpty;
      final actuallyOverdue =
          now.isAfter(task.timeline.endingTime) && !hasFeedback;

      final updatedTimeline = Timeline(
        taskDate: task.timeline.taskDate,
        startingTime: task.timeline.startingTime,
        endingTime: task.timeline.endingTime,
        completionTime: now,
        overdue: actuallyOverdue,
        isUnspecified: task.timeline.isUnspecified,
      );

      final updatedIndicators = Indicators(
        status: 'completed',
        priority: task.indicators.priority,
      );

      // Calculate penalty
      int penaltyPoints = task.metadata.penalty?.penaltyPoints ?? 0;
      String penaltyReason = task.metadata.penalty?.reason ?? '';
      if (actuallyOverdue) {
        final hoursOverdue = now.difference(task.timeline.endingTime).inHours;
        if (hoursOverdue > 0) {
          penaltyPoints += hoursOverdue * 10;
          penaltyReason = 'Completed late by ${hoursOverdue}h';
        }
      }

      final updatedMetadata = task.metadata.copyWith(
        penalty: penaltyPoints > 0
            ? PenaltyInfo(penaltyPoints: penaltyPoints, reason: penaltyReason)
            : null,
        isComplete: true,
        summary: summary.isNotEmpty ? summary : null,
      );

      final intermediateTask = task.copyWith(
        timeline: updatedTimeline,
        indicators: updatedIndicators,
        metadata: updatedMetadata,
      );

      // Use model's recalculate method
      final recalculatedTask = intermediateTask.recalculate();

      // Override summary if provided
      final finalTask = summary.isNotEmpty
          ? recalculatedTask.copyWith(
              metadata: recalculatedTask.metadata.copyWith(summary: summary),
            )
          : recalculatedTask;

      final result = await updateTask(finalTask);
      if (result != null) {
        logI('✅ Task completed successfully: $taskId');
        if (finalTask.metadata.hasReward) {
          logI(
            '🎉 Reward earned: ${finalTask.metadata.tagName} - ${finalTask.metadata.rewardDisplayName}',
          );
          logI('💎 Tier: ${finalTask.metadata.tierLevel}/8');
        }
        return true;
      }
      return false;
    } catch (e, stack) {
      logE('❌ Error completing task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // POST TASK
  // ================================================================
  Future<bool> postTask({
    required String taskId,
    required bool isLive,
    String? snapshotUrl,
    String? caption,
    String visibility = 'public',
  }) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot post task: task_id is empty');
        return false;
      }

      logI('📤 Posting task: $taskId (live: $isLive)');

      final postRepository = PostRepository();
      final post = await postRepository.createPostFromSource(
        sourceType: 'day_task',
        sourceId: taskId,
        isLive: isLive,
        caption: caption,
        visibility: visibility,
      );

      if (post != null) {
        logI('✅ Task posted successfully: $taskId');
        return true;
      } else {
        logE('❌ Failed to create post locally');
        return false;
      }
    } catch (e, stack) {
      logE('❌ Error posting task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // DELETE TASK
  // ================================================================
  Future<bool> deleteTask(String taskId) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot delete task: task_id is empty');
        return false;
      }

      logI('🗑️ Deleting task locally: $taskId');

      // Record exclusion before actual delete from local store
      await _recordExclusion(taskId);

      await _powerSync.delete(_tableName, taskId);

      logI('✅ Task deleted locally');
      return true;
    } catch (e, stack) {
      logE('❌ Error deleting task', error: e, stackTrace: stack);
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

  // ================================================================
  // GET OVERDUE TASKS
  // ================================================================
  Future<List<DayTaskModel>> getOverdueTasks(String userId) async {
    try {
      if (userId.isEmpty) {
        logE('❌ Cannot fetch overdue tasks: user_id is empty');
        return [];
      }

      logI('⏰ Fetching overdue tasks locally for user: $userId');

      final now = DateTime.now().toIso8601String();

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
        AND (json_extract(metadata, '\$.is_complete') = 0 OR json_extract(metadata, '\$.is_complete') = 'false')
        AND json_extract(timeline, '\$.ending_time') < ?
        ORDER BY json_extract(timeline, '\$.ending_time') ASC
        ''',
        parameters: [userId, _tableName, now],
      );

      final tasks = results.map((row) {
        final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
        if (map['task_id'] == null && map['id'] != null) {
          map['task_id'] = map['id'];
        }
        return DayTaskModel.fromJson(map);
      }).toList();

      logI('✅ Found ${tasks.length} overdue tasks locally');
      return tasks;
    } catch (e, stack) {
      logE('❌ Error fetching overdue tasks', error: e, stackTrace: stack);
      return [];
    }
  }

  // ================================================================
  // GET TASKS BY DATE RANGE
  // ================================================================
  Future<List<DayTaskModel>> getTasksByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (userId.isEmpty) {
        logE('❌ Cannot fetch tasks: user_id is empty');
        return [];
      }

      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      logI('📅 Fetching tasks locally from $startStr to $endStr');

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
        AND json_extract(timeline, '\$.task_date') >= ? 
        AND json_extract(timeline, '\$.task_date') <= ?
        ORDER BY json_extract(timeline, '\$.starting_time') ASC
        ''',
        parameters: [userId, _tableName, startStr, endStr],
      );

      final tasks = results.map((row) {
        final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
        if (map['task_id'] == null && map['id'] != null) {
          map['task_id'] = map['id'];
        }
        return DayTaskModel.fromJson(map);
      }).toList();

      logI('✅ Fetched ${tasks.length} tasks locally in date range');
      return tasks;
    } catch (e, stack) {
      logE('❌ Error fetching tasks by date range', error: e, stackTrace: stack);
      return [];
    }
  }

  // ================================================================
  // SEARCH TASKS
  // ================================================================
  Future<List<DayTaskModel>> searchTasks(
    String userId,
    String searchTerm,
  ) async {
    try {
      if (userId.isEmpty) {
        logE('❌ Cannot search tasks: user_id is empty');
        return [];
      }

      if (searchTerm.trim().isEmpty) {
        return getUserTasks(userId);
      }

      logI('🔍 Searching tasks locally for: "$searchTerm"');

      final searchPattern = '%$searchTerm%';

      final results = await _powerSync.executeQuery(
        '''
        SELECT * FROM $_tableName 
        WHERE user_id = ? 
        AND id NOT IN (SELECT excluded_id FROM local_sync_exclusions WHERE table_name = ?)
        AND (
          json_extract(about_task, '\$.task_name') LIKE ? OR 
          json_extract(about_task, '\$.task_description') LIKE ?
        )
        ORDER BY created_at DESC
        ''',
        parameters: [userId, _tableName, searchPattern, searchPattern],
      );

      final tasks = results.map((row) {
        final map = _powerSync.parseJsonbFields(row, _jsonbColumns);
        if (map['task_id'] == null && map['id'] != null) {
          map['task_id'] = map['id'];
        }
        return DayTaskModel.fromJson(map);
      }).toList();

      logI('✅ Found ${tasks.length} matching tasks locally');
      return tasks;
    } catch (e, stack) {
      logE('❌ Error searching tasks', error: e, stackTrace: stack);
      return [];
    }
  }
}

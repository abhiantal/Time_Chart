// ================================================================
// FILE: lib/features/day_task/providers/day_task_provider.dart
// REFACTORED - Uses model methods for reward/color calculations
// ================================================================

import 'package:flutter/material.dart' hide Feedback;
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'package:intl/intl.dart';
import '../../../../../../widgets/logger.dart';
import '../models/day_task_model.dart';
import '../repositories/day_task_repository.dart';
import '../services/day_task_ai_service.dart';

class DayTaskProvider extends ChangeNotifier {
  DayTaskRepository _repository = DayTaskRepository();
  final _aiService = DayTaskAIService();
  StreamSubscription<List<DayTaskModel>>? _tasksSubscription;

  List<DayTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<DayTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed Getters
  List<DayTaskModel> get todayTasks {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    return _tasks.where((t) => t.timeline.taskDate == todayStr).toList();
  }

  List<DayTaskModel> get activeTasks =>
      _tasks.where((t) => !t.metadata.isComplete).toList();

  List<DayTaskModel> get completedTasks =>
      _tasks.where((t) => t.metadata.isComplete).toList();

  int get totalPoints =>
      _tasks.fold(0, (sum, t) => sum + t.metadata.pointsEarned);

  // ================================================================
  // INITIALIZATION
  // ================================================================

  DayTaskProvider() {
    // Timers removed to prevent massive background SQLite write loops.
    // Statuses evaluated during loadTasks() and explicitly on user interaction.
  }

  void updateAuth(AuthProvider auth) {
    final newUserId = auth.currentUser?.id;
    if (newUserId != null && newUserId != _currentUserId) {
      setUserId(newUserId);
    }
  }

  void setUserId(String userId) {
    _currentUserId = userId;
    loadTasks();
  }

  // ================================================================
  // FEEDBACK VALIDATION
  // ================================================================
  bool canAddMediaFeedback(DayTaskModel task) {
    if (task.feedback.comments.isEmpty) return true;

    final mediaComments = task.feedback.comments
        .where((c) => c.mediaUrl != null && c.mediaUrl!.isNotEmpty)
        .toList();

    if (mediaComments.isEmpty) return true;

    final lastMediaTime = mediaComments.last.timestamp;
    final now = DateTime.now();
    final difference = now.difference(lastMediaTime).inMinutes;

    return difference >= 20;
  }

  // ================================================================
  // GET TASK BY ID
  // ================================================================
  Future<DayTaskModel?> getDayTask(String taskId) async {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      try {
        final task = await _repository.getTaskById(taskId);
        if (task != null) {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = task;
          } else {
            _tasks.add(task);
          }
          notifyListeners();
        }
        return task;
      } catch (e) {
        logE('Error fetching task by ID', error: e);
        return null;
      }
    }
  }

  // ================================================================
  // ADD FEEDBACK
  // ================================================================
  Future<bool> addFeedback({
    required String taskId,
    required String feedbackText,
    String? mediaUrl,
  }) async {
    try {
      if (taskId.isEmpty) {
        logE('❌ Cannot add feedback: task_id is empty');
        return false;
      }

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        logE('❌ Task not found locally: $taskId');
        return false;
      }

      final task = _tasks[taskIndex];

      final comment = Comment(
        feedbackNumber: (task.feedback.comments.length + 1).toString(),
        text: feedbackText,
        mediaUrl: mediaUrl,
        timestamp: DateTime.now(),
      );

      if (comment.mediaUrl != null && comment.mediaUrl!.isNotEmpty) {
        if (!canAddMediaFeedback(task)) {
          final mediaComments = task.feedback.comments
              .where((c) => c.mediaUrl != null && c.mediaUrl!.isNotEmpty)
              .toList();
          final lastTime = mediaComments.last.timestamp;
          final nextTime = lastTime.add(const Duration(minutes: 20));
          final remaining = nextTime.difference(DateTime.now()).inMinutes;

          _error = '⏳ Please wait $remaining min before adding media feedback';
          logI(_error!);
          notifyListeners();
          return false;
        }
      }

      logI('💬 Adding feedback: $taskId');

      final result = await _repository.addFeedback(taskId, comment);

      if (result != null) {
        final idx = _tasks.indexWhere((t) => t.id == taskId);
        if (idx != -1) {
          _tasks[idx] = result;
          notifyListeners();

          // Log reward status using model's method
          if (result.metadata.hasReward) {
            logI(
              '🎉 Reward earned: ${result.metadata.tagName} - ${result.metadata.rewardDisplayName}',
            );
          }

          logI('✅ Feedback added and UI updated immediately');
        }
        return true;
      }

      return false;
    } catch (e, stack) {
      logE('❌ Error adding feedback', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // UPDATE TASK STATUSES
  // ================================================================
  Future<void> _updateTaskStatuses() async {
    try {
      _currentUserId ??= Supabase.instance.client.auth.currentUser?.id;

      if (_tasks.isEmpty || _currentUserId == null) return;

      final now = DateTime.now();
      bool hasUpdates = false;
      final List<DayTaskModel> updatedTasks = List.from(_tasks);

      for (var i = 0; i < updatedTasks.length; i++) {
        var task = updatedTasks[i];

        bool needsUpdate = false;
        String newStatus = task.indicators.status;
        Timeline newTimeline = task.timeline;
        Metadata newMetadata = task.metadata;

        final taskDateEnd = DateTime(
          task.timeline.endingTime.year,
          task.timeline.endingTime.month,
          task.timeline.endingTime.day,
          23,
          59,
          59,
        );

        if (now.isAfter(taskDateEnd) && !task.metadata.isComplete) {
          // Task day has ended, and task is not complete: transition to failed/missed with -100 missed penalty
          newStatus = task.indicators.priority == 'high' ? 'failed' : 'missed';
          needsUpdate = true;

          newMetadata = newMetadata.copyWith(
            penalty: PenaltyInfo(
              penaltyPoints: 100,
              reason: 'Missed Task Penalty (-100)',
            ),
            pointsEarned: 0,
            rating: 0.0,
            progress: 0,
            isComplete: true,
          );

          newTimeline = newTimeline.copyWith(
            overdue: false,
            completionTime: taskDateEnd,
          );
        } else if (!task.metadata.isComplete) {
          final minutesUntilStart = task.timeline.startingTime
              .difference(now)
              .inMinutes;
          final minutesUntilEnd = task.timeline.endingTime
              .difference(now)
              .inMinutes;
          final minutesAfterEnd = now
              .difference(task.timeline.endingTime)
              .inMinutes;

          if (minutesAfterEnd > 0) {
            final hasFeedback = task.feedbackCount > 0;

            if (hasFeedback) {
              // Task has feedback and deadline has passed: trigger single-pass AI completion
              logI('⏰ Task deadline reached with feedback. Processing automatic completion: ${task.id}');
              _aiService.processTaskCompletion(
                task,
                _currentUserId!,
                autoStatus: 'completed',
                isOverdue: false,
              ).then((processedTask) {
                if (processedTask != null) {
                  final recalculated = processedTask.copyWith(
                    timeline: processedTask.timeline.copyWith(
                      completionTime: task.timeline.endingTime,
                      overdue: false,
                    ),
                  ).recalculate();
                  updateTask(recalculated);
                }
              }).catchError((e) {
                logE('Async AI verify failed for automatic completion', error: e);
              });
              continue; // Skip synchronous processing for this task to let async update handle it
            } else {
              // No feedback: Mark as overdue
              if (!task.timeline.overdue || task.indicators.status != 'overdue') {
                newStatus = 'overdue';
                newTimeline = newTimeline.copyWith(overdue: true);
                needsUpdate = true;
                logI('⏰ Marked task as overdue (no feedback): ${task.id}');
              }
            }
          } else if (minutesUntilStart <= 0 && minutesUntilEnd > 0) {
            if (task.indicators.status != 'inProgress') {
              newStatus = 'inProgress';
              needsUpdate = true;
            }
          } else if (minutesUntilStart > 0 && minutesUntilStart <= 60) {
            if (task.indicators.status != 'upcoming') {
              newStatus = 'upcoming';
              needsUpdate = true;
            }
          } else if (minutesUntilStart > 60) {
            if (task.indicators.status != 'pending') {
              newStatus = 'pending';
              needsUpdate = true;
            }
          }
        }

        if (needsUpdate) {
          // Use model's method to get color
          final tempTask = task.copyWith(
            indicators: Indicators(
              status: newStatus,
              priority: task.indicators.priority,
            ),
            metadata: newMetadata,
          );
          final colorString = _colorToHex(tempTask.progressColor);

          newMetadata = newMetadata.copyWith(taskColor: colorString);

          final updatedTask = task.copyWith(
            indicators: Indicators(
              status: newStatus,
              priority: task.indicators.priority,
            ),
            timeline: newTimeline,
            metadata: newMetadata,
            updatedAt: DateTime.now(),
          );

          updatedTasks[i] = updatedTask;
          await _repository.updateTask(updatedTask);
          hasUpdates = true;

          logI(
            '✅ Auto-updated task ${task.id}: $newStatus, Overdue: ${newTimeline.overdue}',
          );
        }
      }

      if (hasUpdates) {
        _tasks = updatedTasks;
        notifyListeners();
      }
    } catch (e, stack) {
      logE('❌ Error updating task statuses', error: e, stackTrace: stack);
    }
  }

  // ================================================================
  // AUTO COMPLETE MISSED TASKS
  // ================================================================
  Future<void> _autoCompleteMissedTasks() async {
    try {
      _currentUserId ??= Supabase.instance.client.auth.currentUser?.id;

      if (_tasks.isEmpty || _currentUserId == null) return;

      final now = DateTime.now();

      for (var task in _tasks) {
        if (task.indicators.status == 'missed' &&
            !task.metadata.isComplete &&
            task.metadata.pointsEarned == 0) {
          final minutesOverdue = now
              .difference(task.timeline.endingTime)
              .inMinutes;

          if (minutesOverdue >= 5) {
            logI('🤖 Auto-processing missed task: ${task.id}');
            await _processTaskAutomatically(task, 'missed');
          }
        }
      }
    } catch (e, stack) {
      logE('❌ Error in auto-complete check', error: e, stackTrace: stack);
    }
  }

  Future<void> _processTaskAutomatically(
    DayTaskModel task,
    String finalStatus,
  ) async {
    try {
      logI('🤖 Auto-processing task: ${task.id} with status: $finalStatus');

      final now = DateTime.now();
      final isOverdue = now.isAfter(task.timeline.endingTime);

      final processedTask = await _aiService.processTaskCompletion(
        task,
        _currentUserId!,
        autoStatus: finalStatus,
        isOverdue: isOverdue,
      );

      if (processedTask != null) {
        // Use model's recalculate method
        final recalculatedTask = processedTask
            .copyWith(
              metadata: processedTask.metadata.copyWith(isComplete: true),
              timeline: Timeline(
                taskDate: task.timeline.taskDate,
                startingTime: task.timeline.startingTime,
                endingTime: task.timeline.endingTime,
                completionTime: now,
                overdue: isOverdue,
                isUnspecified: task.timeline.isUnspecified,
              ),
            )
            .recalculate();

        final completedTask = recalculatedTask.copyWith(
          indicators: Indicators(
            status: finalStatus,
            priority: task.indicators.priority,
          ),
        );

        final result = await _repository.updateTask(completedTask);

        if (result != null) {
          final idx = _tasks.indexWhere((t) => t.id == task.id);
          if (idx != -1) {
            _tasks[idx] = result;
            notifyListeners();
          }
        }

        logI(
          '✅ Task auto-processed: Points=${completedTask.metadata.pointsEarned}, Rating=${completedTask.metadata.rating}',
        );

        if (completedTask.metadata.hasReward) {
          logI(
            '🎉 Reward: ${completedTask.metadata.tagName} - ${completedTask.metadata.rewardDisplayName}',
          );
        }
      }
    } catch (e, stack) {
      logE('❌ Error auto-processing task', error: e, stackTrace: stack);
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  // ================================================================
  // LOAD TASKS
  // ================================================================
  Future<void> loadTasks({
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    // Try to get user from Supabase directly if not set (User Request: use flutter package)
    _currentUserId ??= Supabase.instance.client.auth.currentUser?.id;

    if (_currentUserId == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tasksSubscription?.cancel();

      _tasksSubscription = _repository
          .watchUserTasks(
            _currentUserId!,
            date: date,
            startDate: startDate,
            endDate: endDate,
            status: status,
          )
          .listen(
            (tasks) {
              _tasks = tasks;
              _isLoading = false;
              _autoCompleteMissedTasks();
              _updateTaskStatuses();
              notifyListeners();
            },
            onError: (e) {
              _error = e.toString();
              _isLoading = false;
              logE('Error watching tasks', error: e);
              notifyListeners();
            },
          );
    } catch (e, stack) {
      _error = e.toString();
      _isLoading = false;
      logE('Error loading tasks', error: e, stackTrace: stack);
      notifyListeners();
    }
  }

  // ================================================================
  // CREATE TASK
  // ================================================================
  Future<bool> createTask({
    required String taskName,
    String? taskDescription,
    required DateTime taskDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String priority,
    String? categoryId,
    String? categoryType,
    String? subTypes,
  }) async {
    _currentUserId ??= Supabase.instance.client.auth.currentUser?.id;

    if (_currentUserId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        startTime.hour,
        startTime.minute,
      );
      final endDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        endTime.hour,
        endTime.minute,
      );

      String initialStatus = _calculateInitialStatus(
        now,
        startDateTime,
        endDateTime,
      );

      // Create task first, then use model's method to get color
      final task = DayTaskModel(
        id: '',
        userId: _currentUserId!,
        categoryId: categoryId ?? 'default',
        categoryType: categoryType ?? 'General',
        subTypes: subTypes ?? 'Other',
        aboutTask: AboutTask(
          taskName: taskName,
          taskDescription: taskDescription,
        ),
        indicators: Indicators(status: initialStatus, priority: priority),
        timeline: Timeline(
          taskDate: taskDate.toIso8601String().split('T')[0],
          startingTime: startDateTime,
          endingTime: endDateTime,
          overdue: now.isAfter(endDateTime),
          isUnspecified: false,
        ),
        feedback: Feedback(comments: []),
        metadata: Metadata(
          progress: 0,
          pointsEarned: 0,
          rating: 0.0,
          taskColor: '#667EEA', // Default, will be updated
          isComplete: false,
        ),
        socialInfo: SocialInfo(isPosted: false, posted: null),
        shareInfo: const ShareInfo(isShare: false, shareId: null),
        createdAt: now,
        updatedAt: now,
      );

      // Use model's method to get proper color
      final initialColor = _colorToHex(task.priorityColor);
      final taskWithColor = task.copyWith(
        metadata: task.metadata.copyWith(taskColor: initialColor),
      );

      final created = await _repository.createTask(taskWithColor);

      if (created != null) {
        _tasks.insert(0, created);
        _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        logI('✅ Task created with status: $initialStatus');
        return true;
      }

      _error = 'Failed to create task';
      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error creating task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _calculateInitialStatus(DateTime now, DateTime start, DateTime end) {
    final minToStart = start.difference(now).inMinutes;
    final minToEnd = end.difference(now).inMinutes;

    final taskDateOnly = DateTime(end.year, end.month, end.day);
    final endOfDay = DateTime(
      taskDateOnly.year,
      taskDateOnly.month,
      taskDateOnly.day,
      23,
      59,
      59,
    );
    final isPastTaskDay = now.isAfter(endOfDay);

    if (isPastTaskDay) {
      return 'missed';
    } else if (minToStart <= 0 && minToEnd > 0) {
      return 'inProgress';
    } else if (minToStart > 0 && minToStart <= 60) {
      return 'upcoming';
    } else {
      return 'pending';
    }
  }

  // ================================================================
  // COMPLETE TASK MANUALLY
  // ================================================================
  Future<bool> completeTaskManually(String taskId) async {
    try {
      _currentUserId ??= Supabase.instance.client.auth.currentUser?.id;

      if (_currentUserId == null) {
        logE('Cannot complete task: No user authenticated');
        return false;
      }

      logI('✅ Manually completing task: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final now = DateTime.now();

      final taskDate = DateTime.parse(task.timeline.taskDate);
      final isSameDay =
          now.year == taskDate.year &&
          now.month == taskDate.month &&
          now.day == taskDate.day;
      final isOverdue = isSameDay
          ? false
          : now.isAfter(task.timeline.endingTime);

      final taskWithTimeline = task.copyWith(
        indicators: Indicators(
          status: 'completed',
          priority: task.indicators.priority,
        ),
        metadata: task.metadata.copyWith(isComplete: true),
        timeline: Timeline(
          taskDate: task.timeline.taskDate,
          startingTime: task.timeline.startingTime,
          endingTime: task.timeline.endingTime,
          completionTime: now,
          overdue: isOverdue,
          isUnspecified: task.timeline.isUnspecified,
        ),
      );

      final completedTask = taskWithTimeline.recalculate();

      final success = await updateTask(completedTask);
      if (success) {
        logI(
          '✅ Task completed: Points=${completedTask.metadata.pointsEarned}, Rating=${completedTask.metadata.rating}',
        );

        if (completedTask.metadata.hasReward) {
          logI(
            '🎉 Earned: ${completedTask.metadata.tagName} - ${completedTask.metadata.rewardDisplayName}',
          );
          logI('💎 Tier: ${completedTask.metadata.tierLevel}/8');
        }

        // Run AI validation in background quietly
        _aiService.processTaskCompletion(
          task, // pass the original uncompleted task for AI verification
          _currentUserId!,
          autoStatus: 'completed',
          isOverdue: isOverdue,
        ).then((processedTask) {
          if (processedTask != null) {
             updateTask(processedTask.copyWith(timeline: completedTask.timeline).recalculate());
          }
        }).catchError((e) {
          logE('Async AI verify failed', error: e);
        });
      }
      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error completing task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // MARK AS FAILED
  // ================================================================
  Future<bool> markTaskAsFailed(String taskId, {String? reason}) async {
    try {
      logI('❌ Marking task as failed: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);

      final now = DateTime.now();
      final hasFeedback = task.feedback.comments.isNotEmpty;
      final actuallyOverdue =
          now.isAfter(task.timeline.endingTime) && !hasFeedback;

      final taskWithTimeline = task.copyWith(
        indicators: Indicators(
          status: 'failed',
          priority: task.indicators.priority,
        ),
        metadata: task.metadata.copyWith(isComplete: true),
        timeline: Timeline(
          taskDate: task.timeline.taskDate,
          startingTime: task.timeline.startingTime,
          endingTime: task.timeline.endingTime,
          completionTime: now,
          overdue: actuallyOverdue,
          isUnspecified: task.timeline.isUnspecified,
        ),
      );

      final failedTask = taskWithTimeline.recalculate();

      final success = await updateTask(failedTask);
      if (success) {
        logI(
          '✅ Task marked as failed: Points=${failedTask.metadata.pointsEarned}',
        );

        _aiService.processTaskCompletion(
          task,
          _currentUserId!,
          autoStatus: 'failed',
        ).then((processedTask) {
          if (processedTask != null) {
             updateTask(processedTask.copyWith(timeline: failedTask.timeline).recalculate());
          }
        }).catchError((e) {
          logE('Async AI verify failed', error: e);
        });
      }
      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error marking task as failed', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // CANCEL TASK
  // ================================================================
  Future<bool> cancelTask(String taskId) async {
    try {
      logI('🚫 Cancelling task: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final now = DateTime.now();

      final cancelledTask = task.copyWith(
        indicators: Indicators(
          status: 'cancelled',
          priority: task.indicators.priority,
        ),
        metadata: task.metadata.copyWith(
          isComplete: true,
          summary: 'Task cancelled',
          progress: 0,
          pointsEarned: 0,
          rating: 0.0,
        ),
        timeline: Timeline(
          taskDate: task.timeline.taskDate,
          startingTime: task.timeline.startingTime,
          endingTime: task.timeline.endingTime,
          completionTime: now,
          overdue: false,
          isUnspecified: task.timeline.isUnspecified,
        ),
      );

      final success = await updateTask(cancelledTask);
      if (success) {
        logI(
          '✅ Task cancelled: Points=${cancelledTask.metadata.pointsEarned}',
        );

        _aiService.processTaskCompletion(
          task,
          _currentUserId!,
          autoStatus: 'cancelled',
        ).then((processedTask) {
          if (processedTask != null) {
            updateTask(processedTask.copyWith(timeline: cancelledTask.timeline).recalculate());
          }
        }).catchError((e) {
          logE('Async AI verify failed', error: e);
        });
      }
      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error cancelling task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // START TASK
  // ================================================================
  Future<bool> startTask(String taskId) async {
    try {
      logI('▶️ Starting task: $taskId');

      final task = _tasks.firstWhere((t) => t.id == taskId);

      final updatedTask = task.copyWith(
        indicators: Indicators(
          status: 'inProgress',
          priority: task.indicators.priority,
        ),
        updatedAt: DateTime.now(),
      );

      return await updateTask(updatedTask);
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error starting task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // HOLD TASK
  // ================================================================
  Future<bool> holdTask(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        indicators: Indicators(
          status: 'hold',
          priority: task.indicators.priority,
        ),
        updatedAt: DateTime.now(),
      );
      return await updateTask(updatedTask);
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error holding task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // UPDATE PROGRESS
  // ================================================================
  Future<bool> updateProgress(String taskId, int progress) async {
    try {
      logI('📊 Updating progress for task: $taskId to $progress%');

      final success = await _repository.updateProgress(taskId, progress);

      if (success) {
        final updatedTask = await _repository.getTaskById(taskId);
        if (updatedTask != null) {
          final idx = _tasks.indexWhere((t) => t.id == taskId);
          if (idx != -1) {
            _tasks[idx] = updatedTask;
            notifyListeners();
          }
        }
        return true;
      }

      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error updating progress', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // UPDATE TASK
  // ================================================================
  Future<bool> updateTask(DayTaskModel task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateTask(task);
      if (updated != null) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updated;
          _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        notifyListeners();
        return true;
      }

      _error = 'Failed to update task';
      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error updating task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // POST TASK
  // ================================================================
  Future<bool> postTask({
    required String taskId,
    required bool isLive,
    String? caption,
    String? visibility,
  }) async {
    try {
      logI('🚀 Posting task: $taskId');

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        logE('❌ Task not found: $taskId');
        return false;
      }
      final task = _tasks[taskIndex];

      String? finalCaption = caption;
      if (finalCaption == null && _currentUserId != null) {
        finalCaption = await _aiService.generateCaption(
          task,
          _currentUserId!,
          isLive: isLive,
        );
      }

      final postRepo = PostRepository();
      final post = await postRepo.createPostFromSource(
        sourceType: 'day_task',
        sourceId: taskId,
        isLive: isLive,
        caption: finalCaption,
        visibility: visibility ?? 'public',
      );

      if (post != null) {
        final postedInfo = PostedInfo(
          postId: post.id,
          live: isLive,
          time: DateTime.now(),
        );

        final updatedTask = task.copyWith(
          socialInfo: task.socialInfo.copyWith(
            isPosted: true,
            posted: postedInfo,
          ),
        );

        final updateSuccess = await updateTask(updatedTask);
        if (updateSuccess) {
          logI('✅ Task posted successfully: ${post.id}');
          return true;
        }
      }

      return false;
    } catch (e, stack) {
      logE('❌ Error posting task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // REMOVE POST
  // ================================================================
  Future<bool> removePost(String taskId) async {
    try {
      logI('🗑️ Removing post for task: $taskId');

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        logE('❌ Task not found locally: $taskId');
        return false;
      }
      final task = _tasks[taskIndex];

      if (!task.socialInfo.isPosted || task.socialInfo.posted == null) {
        logW('⚠️ Task is not posted: $taskId');
        return false;
      }

      final postId = task.socialInfo.posted!.postId;

      final postRepo = PostRepository();
      final success = await postRepo.deletePost(postId);

      if (success) {
        final updatedTask = task.copyWith(
          socialInfo: task.socialInfo.copyWith(isPosted: false, posted: null),
        );

        final updateSuccess = await updateTask(updatedTask);
        if (updateSuccess) {
          logI('✅ Post removed successfully');
          return true;
        }
      }

      return false;
    } catch (e, stack) {
      logE('❌ Error removing post', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // SHARE TASK VIA CHAT
  // ================================================================
  Future<bool> shareTaskViaChat({
    required String taskId,
    required String chatId,
    required String messageText,
    required bool isLive,
  }) async {
    try {
      logI('📤 Sharing task $taskId to chat $chatId');

      final chatRepo = ChatRepository();
      await chatRepo.sendSharedContent(
        chatId: chatId,
        contentType: SharedContentType.dayTask,
        contentId: taskId,
        caption: messageText,
        mode: isLive ? 'live' : 'snapshot',
      );

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) {
        return true;
      }
      final task = _tasks[taskIndex];

      final sharedInfo = DaySharedInfo(
        live: isLive,
        snapshotUrl: '',
        withId: chatId,
        time: DateTime.now(),
      );

      final updatedTask = task.copyWith(
        shareInfo: task.shareInfo.copyWith(isShare: true, shareId: sharedInfo),
      );

      final result = await _repository.updateTask(updatedTask);

      if (result != null) {
        _tasks[taskIndex] = result;
        notifyListeners();
      }

      logI('✅ Task shared successfully');
      return true;
    } catch (e, stack) {
      logE('❌ Error sharing task', error: e, stackTrace: stack);
      return false;
    }
  }

  // ================================================================
  // DELETE TASK
  // ================================================================
  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deleted = await _repository.deleteTask(taskId);
      if (deleted) {
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        return true;
      }

      _error = 'Failed to delete task';
      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('❌ Error deleting task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  String _colorToHex(Color color) {
    return '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';
  }

  // ================================================================
  // FILTERED GETTERS
  // ================================================================

  List<DayTaskModel> get pendingTasks =>
      _tasks.where((t) => t.indicators.status == 'pending').toList();

  List<DayTaskModel> get upcomingTasks =>
      _tasks.where((t) => t.indicators.status == 'upcoming').toList();

  List<DayTaskModel> get inProgressTasks =>
      _tasks.where((t) => t.indicators.status == 'inProgress').toList();

  List<DayTaskModel> get missedTasks =>
      _tasks.where((t) => t.indicators.status == 'missed').toList();

  List<DayTaskModel> get failedTasks =>
      _tasks.where((t) => t.indicators.status == 'failed').toList();

  List<DayTaskModel> get cancelledTasks =>
      _tasks.where((t) => t.indicators.status == 'cancelled').toList();

  List<DayTaskModel> get skippedTasks =>
      _tasks.where((t) => t.indicators.status == 'skipped').toList();

  // ================================================================
  // REWARD GETTERS
  // ================================================================

  /// Get tasks with rewards earned
  List<DayTaskModel> get tasksWithRewards =>
      _tasks.where((t) => t.metadata.hasReward).toList();

  /// Get best tier earned today
  int get bestTierLevelToday {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayWithRewards = _tasks
        .where((t) => t.timeline.taskDate == today && t.metadata.hasReward)
        .toList();

    if (todayWithRewards.isEmpty) return 0;

    int best = 0;
    for (var task in todayWithRewards) {
      if (task.metadata.tierLevel > best) {
        best = task.metadata.tierLevel;
      }
    }
    return best;
  }

  /// Get total rewards earned
  int get totalRewardsEarned => tasksWithRewards.length;

  // ================================================================
  // STATISTICS
  // ================================================================

  double get averageRating {
    if (_tasks.isEmpty) return 0.0;
    final total = _tasks.fold(0.0, (sum, task) => sum + task.metadata.rating);
    return total / _tasks.length;
  }

  int get completionRate {
    if (_tasks.isEmpty) return 0;
    final completed = _tasks.where((t) => t.metadata.isComplete).length;
    return ((completed / _tasks.length) * 100).round();
  }

  Map<String, int> get tasksByStatus {
    return {
      'pending': pendingTasks.length,
      'upcoming': upcomingTasks.length,
      'inProgress': inProgressTasks.length,
      'completed': completedTasks.length,
      'missed': missedTasks.length,
      'failed': failedTasks.length,
      'cancelled': cancelledTasks.length,
      'skipped': skippedTasks.length,
    };
  }

  Map<String, int> get rewardsByTier {
    final map = <String, int>{};
    for (var task in _tasks) {
      if (task.metadata.hasReward) {
        final tierName = task.tierName;
        map[tierName] = (map[tierName] ?? 0) + 1;
      }
    }
    return map;
  }

}


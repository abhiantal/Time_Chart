// ================================================================
// FILE: lib/features/week_task/providers/week_task_provider.dart
// COMPLETE PROVIDER WITH DAILY PROGRESS + POST/SHARE
// ================================================================

import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../chats/model/chat_message_model.dart';
import '../../../../chats/repositories/chat_repository.dart';
import '../models/week_task_model.dart';
import '../repositories/week_task_repository.dart';

class WeekTaskProvider extends ChangeNotifier {
  WeekTaskRepository _repository = WeekTaskRepository(currentUserId: null);

  void updateAuth(AuthProvider auth) {
    final newUserId = auth.currentUser?.id;
    _repository = WeekTaskRepository(currentUserId: newUserId);
    if (newUserId != null) {
      setUserId(newUserId);
    }
  }

  // State
  List<WeekTaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  Timer? _cooldownTimer;

  // Getters
  List<WeekTaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _currentUserId;

  // Computed Getters
  List<WeekTaskModel> get todayTasks =>
      _tasks.where((t) => t.isDateScheduled(DateTime.now()) && t.isActive).toList();

  List<WeekTaskModel> get activeTasks =>
      _tasks.where((t) => t.indicators.status != 'completed').toList();

  List<WeekTaskModel> get completedTasks =>
      _tasks.where((t) => t.indicators.status == 'completed').toList();

  int get totalPoints => _tasks.fold(0, (sum, t) => sum + t.summary.pointsEarned);

  // ================================================================
  // INITIALIZATION
  // ================================================================

  void setUserId(String userId) {
    _currentUserId = userId;
    loadTasks();
    _autoMarkMissedDays();
  }

  Future<void> _autoMarkMissedDays() async {
    if (_currentUserId != null) {
      await _repository.autoMarkMissedDays(_currentUserId!);
      await loadTasks();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ================================================================
  // GET TASK BY ID
  // ================================================================
  Future<WeekTaskModel?> getWeekTask(String taskId) async {
    // 1. Check local cache
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      // 2. Fetch from repository
      try {
        final task = await _repository.getTaskById(taskId);
        if (task != null) {
          // Update local cache
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
        logE('Error fetching week task by ID', error: e);
        return null;
      }
    }
  }

  // ================================================================
  // BASIC CRUD OPERATIONS
  // ================================================================

  Future<void> loadTasks({String? status}) async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _repository.getUserTasks(_currentUserId!, status: status);
      logI('âœ… Loaded ${_tasks.length} tasks');
    } catch (e, stack) {
      _error = e.toString();
      logE('Error loading weekly tasks', error: e, stackTrace: stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(WeekTaskModel task) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _repository.createTask(task);
      if (created != null) {
        _tasks.add(created);
        notifyListeners();
        logI('âœ… Task created: ${created.id}');
        return true;
      }
      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error creating weekly task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask(WeekTaskModel task) async {
    try {
      final success = await _repository.updateTask(task);
      if (success) {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          notifyListeners();
        }
      }
      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error updating task', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deleteTask(taskId);
      if (success) {
        _tasks.removeWhere((t) => t.id == taskId);
        logI('âœ… Task deleted: $taskId');
      }
      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error deleting task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  WeekTaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // DAILY PROGRESS & FEEDBACK
  // ================================================================

  /// Add media feedback (every 20 min, +5 points)
  Future<bool> addMediaFeedback({
    required String taskId,
    required String mediaUrl,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();

      logI('ðŸ“¸ Adding media feedback: $taskId');

      final updatedTask = await _repository.addMediaFeedback(
        taskId: taskId,
        date: targetDate,
        mediaUrl: mediaUrl,
      );

      if (updatedTask != null) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
        logI('âœ… Media feedback added (+5 points)');
        return true;
      }

      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error adding media feedback', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Upload and add media feedback
  Future<bool> uploadAndAddMediaFeedback({
    required String taskId,
    required String filePath,
    required String fileName,
    DateTime? date,
  }) async {
    if (_currentUserId == null) return false;

    // VALIDATION: Fail fast before upload
    final task = getTaskById(taskId);
    if (task == null) {
      logE('âŒ Task not found locally: $taskId');
      return false;
    }
    if (!task.isActive) {
      logW('âŒ Cannot upload feedback: Task is not active');
      return false;
    }
    if (task.indicators.status == 'completed') {
      logW('âŒ Cannot upload feedback: Task is completed');
      return false;
    }
    final targetDate = date ?? DateTime.now();
    final dayName = DateFormat('EEEE').format(targetDate).toLowerCase();
    if (!task.timeline.scheduledDays.contains(dayName)) {
      logW('âŒ Cannot upload feedback: Not a scheduled day');
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final dateStr = DateFormat('dd-MM-yyyy').format(targetDate);

      // Upload media first
      final mediaUrl = await _repository.uploadFeedbackMedia(
        userId: _currentUserId!,
        taskId: taskId,
        filePath: filePath,
        fileName: fileName,
        taskDate: dateStr,
      );

      if (mediaUrl == null) {
        logE('âŒ Failed to upload media');
        return false;
      }

      // Then add feedback
      return await addMediaFeedback(
        taskId: taskId,
        mediaUrl: mediaUrl,
        date: targetDate,
      );
    } catch (e, stack) {
      _error = e.toString();
      logE('Error uploading media feedback', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add final text feedback (+10 points)
  Future<bool> addFinalText({
    required String taskId,
    required String text,
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();

      // VALIDATION
      final task = getTaskById(taskId);
      if (task != null) {
        if (!task.isActive) {
          logW('âŒ Cannot add final text: Task is not active');
          return false;
        }
        if (task.indicators.status == 'completed') {
          logW('âŒ Cannot add final text: Task is completed');
          return false;
        }
        final dayName = DateFormat('EEEE').format(targetDate).toLowerCase();
        if (!task.timeline.scheduledDays.contains(dayName)) {
          logW('âŒ Cannot add final text: Not a scheduled day');
          return false;
        }
      }

      logI('ðŸ“ Adding final text: $taskId');

      final updatedTask = await _repository.addFinalText(
        taskId: taskId,
        date: targetDate,
        text: text,
      );

      if (updatedTask != null) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
        logI('âœ… Final text added (+10 points)');
        return true;
      }

      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error adding final text', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check if can add feedback now
  Future<bool> canAddFeedback(String taskId, {DateTime? date}) async {
    try {
      return await _repository.canAddFeedback(
        taskId: taskId,
        date: date ?? DateTime.now(),
      );
    } catch (e) {
      return true;
    }
  }

  /// Get time until next feedback allowed
  Future<Duration> getTimeUntilNextFeedback(
    String taskId, {
    DateTime? date,
  }) async {
    try {
      return await _repository.getTimeUntilNextFeedback(
        taskId: taskId,
        date: date ?? DateTime.now(),
      );
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Start cooldown timer for UI updates
  void startCooldownTimer({
    required String taskId,
    required VoidCallback onTick,
    required VoidCallback onComplete,
  }) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = await getTimeUntilNextFeedback(taskId);
      if (remaining <= Duration.zero) {
        timer.cancel();
        onComplete();
      } else {
        onTick();
      }
    });
  }

  /// Mark day as missed (applies -50 penalty)
  Future<bool> markDayAsMissed({
    required String taskId,
    required DateTime date,
  }) async {
    try {
      final updatedTask = await _repository.markDayAsMissed(
        taskId: taskId,
        date: date,
      );

      if (updatedTask != null) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
        return true;
      }

      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error marking day as missed', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Get today's progress for a task
  DailyProgress? getTodayProgress(String taskId) {
    final task = getTaskById(taskId);
    return task?.todayProgress;
  }

  /// Get progress for a specific date
  DailyProgress? getProgressForDate(String taskId, DateTime date) {
    final task = getTaskById(taskId);
    return task?.getProgressForDate(date);
  }

  /// Get today's feedback count
  int getTodayFeedbackCount(String taskId) {
    final progress = getTodayProgress(taskId);
    return progress?.feedbacks.length ?? 0;
  }

  /// Get today's points
  int getTodayPoints(String taskId) {
    final progress = getTodayProgress(taskId);
    return progress?.dailyMetrics.pointsEarned ?? 0;
  }

  // ================================================================
  // TASK COMPLETION
  // ================================================================

  Future<bool> completeWeekTask({
    required String taskId,
    String? summary,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedTask = await _repository.completeWeekTask(
        taskId: taskId,
        finalSummary: summary,
      );

      if (updatedTask != null) {
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }

        // Schedule auto-repeat for next week
        _repository.repeatTask(taskId).then((_) {
          loadTasks(); // optionally reload to show it in upcoming
        });

        logI('âœ… Weekly task completed');
        return true;
      }

      return false;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error completing weekly task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // STATISTICS
  // ================================================================

  Future<Map<String, dynamic>> getTaskStats() async {
    if (_currentUserId == null) return {};
    return await _repository.getTaskStats(_currentUserId!);
  }

  Future<Map<String, dynamic>> getStreakStats() async {
    if (_currentUserId == null) return {};
    return await _repository.getStreakStats(_currentUserId!);
  }

  // ================================================================
  // POST FUNCTIONALITY
  // ================================================================

  /// Create a LIVE post from weekly task
  Future<String?> createLivePost({
    required String taskId,
    String? caption,
    String visibility = 'public',
    List<String> tags = const [],
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    if (_currentUserId == null) {
      _error = 'User not authenticated';
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      logI('ðŸ“¤ Creating LIVE post for task: $taskId');

      final task = getTaskById(taskId);
      if (task == null) return null;

      final postId = await _repository.createPostFromTask(
        task,
        isLive: true,
        caption: caption,
        visibility: visibility,
      );

      if (postId != null) {
        final updatedTask = task.copyWith(
          socialInfo: SocialInfo(
            isPosted: true,
            posted: PostedInfo(
              postId: postId,
              live: true,
              time: DateTime.now(),
            ),
          ),
        );
        await _repository.updateTask(updatedTask);
        await loadTasks();
        logI('âœ… LIVE post created: $postId');
      }

      return postId;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error creating live post', error: e, stackTrace: stack);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a SNAPSHOT post from weekly task
  Future<String?> createSnapshotPost({
    required String taskId,
    String? caption,
    String visibility = 'public',
    List<String> tags = const [],
    List<String> hashtags = const [],
    List<String> mentions = const [],
  }) async {
    if (_currentUserId == null) {
      _error = 'User not authenticated';
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      logI('ðŸ“¸ Creating SNAPSHOT post for task: $taskId');

      final task = getTaskById(taskId);
      if (task == null) return null;

      final postId = await _repository.createPostFromTask(
        task,
        isLive: false,
        caption: caption,
        visibility: visibility,
      );

      if (postId != null) {
        final updatedTask = task.copyWith(
          socialInfo: SocialInfo(
            isPosted: true,
            posted: PostedInfo(
              postId: postId,
              live: false,
              time: DateTime.now(),
            ),
          ),
        );
        await _repository.updateTask(updatedTask);
        await loadTasks();
        logI('âœ… SNAPSHOT post created: $postId');
      }

      return postId;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error creating snapshot post', error: e, stackTrace: stack);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get post with full data
  Future<Map<String, dynamic>?> getPostWithFullData(String postId) async {
    if (_currentUserId == null) return null;

    try {
      return await _repository.getPostWithFullData(postId, _currentUserId!);
    } catch (e, stack) {
      _error = e.toString();
      logE('Error fetching post', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Toggle post between live and snapshot
  Future<bool> togglePostLiveStatus(String postId, bool toLive) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.togglePostLiveStatus(postId, toLive);

      if (success) {
        logI('âœ… Post toggled to ${toLive ? 'LIVE' : 'SNAPSHOT'}');
      }

      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error toggling post status', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update post caption
  Future<bool> updatePostCaption(String postId, String caption) async {
    if (_currentUserId == null) return false;

    try {
      return await _repository.updatePostCaption(postId, caption);
    } catch (e, stack) {
      _error = e.toString();
      logE('Error updating post caption', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> deletePost(String postId, String taskId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deletePost(postId, _currentUserId!);

      if (success) {
        final task = getTaskById(taskId);
        if (task != null) {
          final updatedSocialInfo = SocialInfo(isPosted: false, posted: null);
          final updatedTask = task.copyWith(socialInfo: updatedSocialInfo);
          await _repository.updateTask(updatedTask);
        }
        await loadTasks();
        logI('âœ… Post deleted & task social info updated');
      }

      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error deleting post', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // TASK STATUS MANAGEMENT (HOLD/CONTINUE)
  // ================================================================

  /// Hold task (pause)
  Future<bool> holdTask(String taskId) async {
    // Ensure we are not in a build phase
    await Future.delayed(Duration.zero);

    try {
      _isLoading = true;
      notifyListeners();

      final task = _tasks.firstWhere((t) => t.id == taskId);
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
        indicators: Indicators(
          status: 'onHold',
          priority: task.indicators.priority,
        ),
        timeline: TaskTimeline(
          taskDays: task.timeline.taskDays,
          startingDate: task.timeline.startingDate,
          expectedEndingDate: adjustedEnd,
          startingTime: task.timeline.startingTime,
          endingTime: adjustedEnd,
          taskDuration: task.timeline.taskDuration,
        ),
        updatedAt: DateTime.now(),
      );

      await _repository.updateTask(updatedTask);

      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      await _repository.repeatTask(taskId);
      logI('â¸ï¸ Task put on hold: $taskId');
      return true;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error holding task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Continue task (resume)
  Future<bool> continueTask(String taskId) async {
    // Ensure we are not in a build phase
    await Future.delayed(Duration.zero);

    try {
      _isLoading = true;
      notifyListeners();

      final task = _tasks.firstWhere((t) => t.id == taskId);
      final now = DateTime.now();

      // Recalculate status based on current time
      String newStatus = 'pending';
      final isOverdue = now.isAfter(task.timeline.endingTime);
      final isStarted = now.isAfter(task.timeline.startingTime);

      if (isOverdue) {
        newStatus = 'missed';
      } else if (isStarted) {
        newStatus = 'inProgress';
      } else {
        newStatus = 'upcoming';
      }

      final updatedTask = task.copyWith(
        indicators: Indicators(
          status: newStatus,
          priority: task.indicators.priority,
        ),
        updatedAt: DateTime.now(),
      );

      await _repository.updateTask(updatedTask);

      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      logI('â–¶ï¸ Task continued: $taskId (Status: $newStatus)');
      return true;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error continuing task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================================================================
  // SHARE FUNCTIONALITY
  // ================================================================

  /// Share task via chat
  Future<bool> shareTaskViaChat({
    required String taskId,
    required String chatId,
    String? messageText,
    List<String>? shareWithIds,
    bool isLive = false,
  }) async {
    if (_currentUserId == null) {
      _error = 'User not authenticated';
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      logI('ðŸ’¬ Sharing task via chat: $taskId');

      final chatRepo = ChatRepository();
      await chatRepo.sendSharedContent(
        chatId: chatId,
        contentType: SharedContentType.weeklyTask,
        contentId: taskId,
        caption: messageText,
        mode: isLive ? 'live' : 'snapshot',
      );

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return true;

      final updatedTask = _tasks[taskIndex].copyWith(
        shareInfo: ShareInfo(
          isShare: true,
          shareId: SharedData(
            live: isLive,
            snapshotUrl: '',
            withId: chatId,
            time: DateTime.now(),
          ),
        ),
      );

      _tasks[taskIndex] = updatedTask;
      await _repository.updateTask(updatedTask);

      logI('âœ… Task shared successfully');

      return true;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error sharing task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Unshare task from chat
  Future<bool> unshareTaskFromChat({
    required String taskId,
    String? chatId,
  }) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.unshareTaskFromChat(
        taskId,
        chatId ?? '',
      );

      if (success) {
        await loadTasks();
        logI('âœ… Task unshared');
      }

      return success;
    } catch (e, stack) {
      _error = e.toString();
      logE('Error unsharing task', error: e, stackTrace: stack);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get shared tasks in chat
  Future<List<Map<String, dynamic>>> getSharedTasksInChat(String chatId) async {
    if (_currentUserId == null) return [];

    try {
      final tasks = await _repository.getSharedTasksInChat(
        chatId,
        _currentUserId!,
      );
      return tasks.map((t) => t.toJson()).toList();
    } catch (e, stack) {
      _error = e.toString();
      logE('Error fetching shared tasks', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Check if task is shared in chat
  Future<bool> isTaskSharedInChat(String taskId, {String? chatId}) async {
    try {
      return await _repository.isTaskSharedInChat(taskId, chatId: chatId);
    } catch (e) {
      return false;
    }
  }

  // ================================================================
  // FILTERED GETTERS
  // ================================================================

  /// Pending tasks
  List<WeekTaskModel> get pendingTasks {
    return _tasks.where((t) => t.indicators.status == 'pending').toList();
  }

  /// In-progress tasks
  List<WeekTaskModel> get inProgressTasks {
    return _tasks.where((t) => t.indicators.status == 'inProgress').toList();
  }

  /// Posted tasks
  List<WeekTaskModel> get postedTasks {
    return _tasks.where((t) => t.socialInfo.isPosted).toList();
  }

  /// Shared tasks
  List<WeekTaskModel> get sharedTasks {
    return _tasks.where((t) => t.shareInfo.isShare).toList();
  }

  /// High performing tasks (progress > 70%)
  List<WeekTaskModel> get highPerformingTasks {
    return _tasks.where((t) => t.summary.progress >= 70).toList();
  }

  /// Tasks needing attention (low progress or missed days)
  List<WeekTaskModel> get tasksNeedingAttention {
    return _tasks.where((t) {
      return t.isActive &&
          (t.summary.progress < 30 || t.summary.pendingGoalDays > 0);
    }).toList();
  }



  // ================================================================
  // UTILITY METHODS
  // ================================================================

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _autoMarkMissedDays();
    await loadTasks();
  }

  /// Get formatted cooldown time
  Future<String> getFormattedCooldown(String taskId) async {
    final remaining = await getTimeUntilNextFeedback(taskId);
    if (remaining <= Duration.zero) return 'Ready';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

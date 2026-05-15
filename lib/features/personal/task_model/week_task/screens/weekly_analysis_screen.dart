// ================================================================
// FILE: lib/features/week_task/screens_widgets/weekly_analysis_screen.dart
// Daily Analysis Summary with AI Insights for Weekly Tasks - COMPLETE & FIXED
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Import your custom message_bubbles
import '../../../../../../helpers/card_color_helper.dart';
import '../../../../../media_utility/media_display.dart';

// Import models
import '../../../../../widgets/circular_progress_indicator.dart';
import '../models/week_task_model.dart';
import '../repositories/week_task_repository.dart';

// Simple GetX Controller
class WeekTaskController extends GetxController {
  final repository = WeekTaskRepository();
  final tasks = <WeekTaskModel>[].obs;
  final isLoading = false.obs;

  WeekTaskModel? getTaskById(String taskId) {
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadTask(String taskId) async {
    try {
      isLoading.value = true;
      final task = await repository.getTaskById(taskId);
      if (task != null) {
        final index = tasks.indexWhere((t) => t.id == taskId);
        if (index >= 0) {
          tasks[index] = task;
        } else {
          tasks.add(task);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<WeekTaskModel?> addFinalText({
    required String taskId,
    required DateTime date,
    required String text,
  }) async {
    final result = await repository.addFinalText(
      taskId: taskId,
      date: date,
      text: text,
    );
    if (result != null) {
      await loadTask(taskId);
    }
    return result;
  }

  Future<bool> deleteTask(String taskId) async {
    final success = await repository.deleteTask(taskId);
    if (success) {
      tasks.removeWhere((task) => task.id == taskId);
    }
    return success;
  }
}

class WeeklyTaskDailyAnalysisScreen extends StatefulWidget {
  final String taskId;
  final DateTime selectedDate;

  const WeeklyTaskDailyAnalysisScreen({
    super.key,
    required this.taskId,
    required this.selectedDate,
  });

  @override
  State<WeeklyTaskDailyAnalysisScreen> createState() =>
      _WeeklyTaskDailyAnalysisScreenState();
}

class _WeeklyTaskDailyAnalysisScreenState
    extends State<WeeklyTaskDailyAnalysisScreen>
    with TickerProviderStateMixin {
  late WeekTaskController _controller;

  late AnimationController _animController;
  late AnimationController _fabController;

  String? _aiSummary;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    if (!Get.isRegistered<WeekTaskController>()) {
      Get.put(WeekTaskController());
    }
    _controller = Get.find<WeekTaskController>();

    // Load task data
    _controller.loadTask(widget.taskId);

    // Animation controllers
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animController.forward();
    _generateAISummary();
  }

  @override
  void dispose() {
    _animController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  WeekTaskModel? get _task => _controller.getTaskById(widget.taskId);

  // ================================================================
  // HELPER METHODS - FIXED
  // ================================================================

  DailyProgress? _getDailyProgressForDate(WeekTaskModel task, DateTime date) {
    return task.getProgressForDate(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calculate current streak helper
  int _calculateCurrentStreak(WeekTaskModel task) {
    int streak = 0;
    final sortedProgress = task.dailyProgress.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var progress in sortedProgress) {
      if (progress.dailyMetrics.isComplete) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // Calculate longest streak helper
  int _calculateLongestStreak(WeekTaskModel task) {
    int longest = 0;
    int current = 0;

    for (var progress in task.dailyProgress) {
      if (progress.dailyMetrics.isComplete) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  // ================================================================
  // AI SUMMARY GENERATION
  // ================================================================

  Future<void> _generateAISummary() async {
    if (_task == null) return;

    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(seconds: 2));

    final summary = _buildAISummary(_task!);

    if (mounted) {
      setState(() {
        _aiSummary = summary;
        _isGenerating = false;
      });
    }
  }

  String _buildAISummary(WeekTaskModel task) {
    final isScheduledToday = task.isDateScheduled(widget.selectedDate);
    final dailyProgress = _getDailyProgressForDate(task, widget.selectedDate);
    final isCompletedToday = dailyProgress?.dailyMetrics.isComplete ?? false;
    final progressToday = dailyProgress?.dailyMetrics.progress ?? 0;
    final currentStreak = _calculateCurrentStreak(task);
    final totalProgress = task.summary.progress;

    String summary = '';

    // Opening & Status
    if (isCompletedToday) {
      summary +=
          'ðŸŽ‰ Great job! You completed "${task.aboutTask.taskName}" today. ';
    } else if (isScheduledToday && progressToday > 0) {
      summary +=
          'ðŸ‘ You made progress on "${task.aboutTask.taskName}" today ($progressToday%). ';
    } else if (isScheduledToday) {
      summary +=
          'ðŸ“‹ "${task.aboutTask.taskName}" is scheduled for today but not started yet. ';
    } else {
      summary +=
          'ðŸ“… Reviewing "${task.aboutTask.taskName}" - not scheduled for today. ';
    }

    // Streak & Consistency
    if (currentStreak >= 3) {
      summary += 'Your $currentStreak-day streak shows excellent consistency! ';
    } else if (currentStreak > 0) {
      summary += 'You\'re building momentum with a $currentStreak-day streak. ';
    }

    // Progress Analysis
    if (totalProgress >= 100) {
      summary += 'Full completion demonstrates strong commitment. ';
    } else if (totalProgress >= 75) {
      summary += 'Near-complete weekly progress shows dedication. ';
    } else if (totalProgress >= 50) {
      summary += 'Halfway through the week - solid progress! ';
    } else if (totalProgress > 0) {
      summary += 'Every step forward counts. ';
    }

    // Priority Impact
    if (task.indicators.priority.toLowerCase() == 'high' ||
        task.indicators.priority.toLowerCase() == 'urgent') {
      summary +=
          'As a ${task.indicators.priority}-priority task, staying on track is crucial. ';
    }

    // Feedback Analysis
    final feedbackCount = dailyProgress?.feedbacks.length ?? 0;
    if (feedbackCount > 0) {
      summary += 'You\'ve added $feedbackCount feedback entries today! ';
    }

    // Actionable Suggestions
    summary += '\n\nðŸ’¡ Suggestions:\n';

    if (!isCompletedToday && isScheduledToday) {
      summary += 'â€¢ Complete this task today to maintain your streak\n';
      summary += 'â€¢ Set aside ${_estimateTimeNeeded(task)} to finish\n';
    } else if (isCompletedToday) {
      summary += 'â€¢ Add feedback to track what worked well\n';
      summary += 'â€¢ Prepare for the next scheduled day\n';
    } else {
      summary += 'â€¢ Review your weekly schedule\n';
      summary += 'â€¢ Plan time blocks for upcoming tasks\n';
    }

    summary += 'â€¢ Keep your ${currentStreak + 1}-day streak alive!';

    return summary;
  }

  String _estimateTimeNeeded(WeekTaskModel task) {
    final start = task.timeline.startingTime;
    final end = task.timeline.endingTime;
    final duration = end.difference(start);

    if (duration.inHours >= 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    }
    return '${duration.inMinutes}min';
  }

  // ================================================================
  // BUILD METHOD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final task = _task;
      if (task == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Analysis')),
          body: _buildNotFoundState(context),
        );
      }

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, task),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(context, task),
                    const SizedBox(height: 24),
                    _buildDailyMetrics(context, task),
                    const SizedBox(height: 24),
                    _buildProgressComparison(context, task),
                    const SizedBox(height: 24),
                    _buildAISummaryCard(context, task),
                    const SizedBox(height: 24),
                    _buildSelectedDayFeedback(context, task),
                    const SizedBox(height: 32),
                    _buildWeeklyFeedbackDetails(context, task),
                    const SizedBox(height: 32),
                    _buildStreakVisualization(context, task),
                    const SizedBox(height: 24),
                    _buildWeeklyOverview(context, task),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ================================================================
  // NOT FOUND STATE
  // ================================================================

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.errorContainer.withValues(alpha: 0.5),
                    colorScheme.errorContainer.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Task Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The task you\'re looking for doesn\'t exist or has been deleted.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SLIVER APP BAR
  // ================================================================

  Widget _buildSliverAppBar(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = _getPriorityColor(task.indicators.priority);
    final statusColor = _getStatusColor(task.indicators.status);

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        title: Text(
          'Daily Analysis',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: CardColorHelper.getTaskCardGradient(
                priority: task.indicators.priority,
                status: task.indicators.status,
                progress: task.summary.progress,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Task info
              Positioned(
                left: 20,
                right: 20,
                bottom: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.task_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              task.aboutTask.taskName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.flag_rounded,
                          label: task.indicators.priority.capitalize!,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: _getStatusIcon(task.indicators.status),
                          label: _formatStatus(task.indicators.status),
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  // ================================================================
  // DATE HEADER
  // ================================================================

  Widget _buildDateHeader(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isToday = _isSameDay(widget.selectedDate, DateTime.now());
    final isScheduled = task.isDateScheduled(widget.selectedDate);
    final dailyProgress = _getDailyProgressForDate(task, widget.selectedDate);
    final progressToday =
        dailyProgress?.dailyMetrics.progress ?? task.summary.progress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: CardColorHelper.getTaskCardGradient(
            priority: task.indicators.priority,
            status: task.indicators.status,
            progress: progressToday,
            isDarkMode: isDark,
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: CardColorHelper.getTaskCardGradient(
                  priority: task.indicators.priority,
                  status: task.indicators.status,
                  progress: progressToday,
                  isDarkMode: isDark,
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(widget.selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(widget.selectedDate).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(widget.selectedDate),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy').format(widget.selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isToday)
                      _buildStatusChip(
                        label: 'TODAY',
                        color: colorScheme.primary,
                        icon: Icons.today_rounded,
                      ),
                    if (isToday) const SizedBox(width: 8),
                    _buildStatusChip(
                      label: isScheduled ? 'SCHEDULED' : 'NOT SCHEDULED',
                      color: isScheduled ? Colors.green : Colors.grey,
                      icon: isScheduled
                          ? Icons.event_available_rounded
                          : Icons.event_busy_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DAILY METRICS
  // ================================================================

  Widget _buildDailyMetrics(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isScheduled = task.isDateScheduled(widget.selectedDate);
    final dailyProgress = _getDailyProgressForDate(task, widget.selectedDate);
    final isCompleted = dailyProgress?.dailyMetrics.isComplete ?? false;
    final progressPercent = dailyProgress?.dailyMetrics.progress ?? 0;
    final feedbackCount = dailyProgress?.feedbacks.length ?? 0;
    final currentStreak = _calculateCurrentStreak(task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Today\'s Metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.event_available_rounded,
                      label: 'Scheduled',
                      value: isScheduled ? 'Yes' : 'No',
                      color: isScheduled
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      value: isCompleted ? 'Yes' : 'No',
                      color: isCompleted
                          ? const Color(0xFF3B82F6)
                          : Colors.grey,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.trending_up_rounded,
                      label: 'Progress',
                      value: '$progressPercent%',
                      color: CardColorHelper.getProgressColor(progressPercent),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.feedback_rounded,
                      label: 'Feedback',
                      value: '$feedbackCount',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '$currentStreak',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.star_rounded,
                      label: 'Weekly',
                      value: '${task.summary.progress}%',
                      color: Colors.amber,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.15),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PROGRESS COMPARISON
  // ================================================================

  Widget _buildProgressComparison(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dailyProgress = _getDailyProgressForDate(task, widget.selectedDate);
    final todayProgress = dailyProgress?.dailyMetrics.progress ?? 0;
    final weeklyProgress = task.summary.progress;
    final longestStreak = _calculateLongestStreak(task);

    return ScaleTransition(
      scale: _fabController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Progress Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                AdvancedProgressIndicator(
                  progress: weeklyProgress / 100,
                  size: 110,
                  shape: ProgressShape.circular,
                  labelStyle: ProgressLabelStyle.percentage,
                  strokeWidth: 12,
                  gradientColors: [Colors.white, Colors.white.withValues(alpha: 0.7)],
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  animated: true,
                  animationDuration: const Duration(milliseconds: 1500),
                  showGlow: true,
                  glowRadius: 15,
                  labelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressRow(
                        label: 'Today',
                        value: todayProgress,
                        icon: Icons.today_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressRow(
                        label: 'This Week',
                        value: weeklyProgress,
                        icon: Icons.date_range_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressRow(
                        label: 'Best Streak',
                        value: longestStreak,
                        icon: Icons.emoji_events_rounded,
                        isCount: true,
                        suffix: ' days',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int value,
    required IconData icon,
    bool isCount = false,
    String suffix = '%',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$value$suffix',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (!isCount) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // AI SUMMARY CARD
  // ================================================================

  Widget _buildAISummaryCard(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalized insights',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isGenerating)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _generateAISummary,
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                  tooltip: 'Regenerate',
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isGenerating)
            Column(
              children: [
                _buildShimmerLine(context, 1.0),
                const SizedBox(height: 10),
                _buildShimmerLine(context, 0.95),
                const SizedBox(height: 10),
                _buildShimmerLine(context, 0.85),
                const SizedBox(height: 10),
                _buildShimmerLine(context, 0.9),
                const SizedBox(height: 10),
                _buildShimmerLine(context, 0.7),
              ],
            )
          else if (_aiSummary != null)
            FadeTransition(
              opacity: _animController,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  _aiSummary!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.7,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLine(BuildContext context, double widthFactor) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width * widthFactor * 0.7,
      height: 14,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.outline.withValues(alpha: 0.1),
            theme.colorScheme.outline.withValues(alpha: 0.2),
            theme.colorScheme.outline.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  // ================================================================
  // TODAY'S FEEDBACK
  // ================================================================

  Widget _buildSelectedDayFeedback(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dailyProgress = _getDailyProgressForDate(task, widget.selectedDate);
    final feedbackList = dailyProgress?.feedbacks ?? [];
    final finalText = feedbackList.isNotEmpty ? feedbackList.last.finalText : null;

    final isScheduled = task.isDateScheduled(widget.selectedDate);
    final isToday = _isSameDay(widget.selectedDate, DateTime.now());

    final canAddFeedback =
        isScheduled &&
        task.indicators.status != 'completed' &&
        _canAddFeedbackToday(task, dailyProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.feedback_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isToday ? 'Today\'s Feedback' : 'Day Feedback',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (feedbackList.isEmpty && finalText == null)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.comment_outlined,
                      size: 40,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No feedback added today',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canAddFeedback
                        ? 'Tap the button above to add your progress'
                        : 'Feedback can be added on scheduled days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ...feedbackList.asMap().entries.map((entry) {
                final index = entry.key;
                final feedback = entry.value;
                return _buildFeedbackItem(
                  context,
                  index: index,
                  feedback: feedback,
                  isDark: isDark,
                );
              }),

              if (finalText != null && finalText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(
                      alpha: isDark ? 0.3 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notes_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Notes',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              finalText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildFeedbackItem(
    BuildContext context, {
    required int index,
    required DailyFeedback feedback,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_rounded,
                  color: colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback #${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Feedback #${index + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '#${feedback.feedbackCount}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (feedback.mediaUrl != null && feedback.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: EnhancedMediaDisplay(
                mediaFiles: [
                  EnhancedMediaFile.fromUrl(
                    id: 'fb_media_\$index',
                    url: feedback.mediaUrl ?? '',
                  ),
                ],
                isLoading: false,
                config: const MediaDisplayConfig(
                  layoutMode: MediaLayoutMode.single,
                  borderRadius: 12,
                  maxHeight: 200,
                  allowDelete: false,
                  allowFullScreen: true,
                  showFileName: false,
                  showFileSize: false,
                  showDate: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // STREAK VISUALIZATION
  // ================================================================

  Widget _buildStreakVisualization(BuildContext context, WeekTaskModel task) {
    final currentStreak = _calculateCurrentStreak(task);
    final longestStreak = _calculateLongestStreak(task);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange,
            Colors.red.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentStreak Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Best: $longestStreak days',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final isActive = index < currentStreak;
                final isCurrent = index == currentStreak - 1;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    width: isCurrent ? 40 : 36,
                    height: isCurrent ? 40 : 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.yellow, width: 3)
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: isCurrent ? 22 : 18,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),

          if (currentStreak >= 5) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentStreak >= 7
                        ? '🏆 Weekly Champion!'
                        : '🔥 Consistency Master!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // WEEKLY OVERVIEW
  // ================================================================

  Widget _buildWeeklyOverview(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final scheduledDays = task.scheduledDays;
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.tertiary, colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_view_week_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Weekly Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayName = fullDayNames[index];
              final isScheduled =
                  scheduledDays.contains(dayName) ||
                  scheduledDays.contains(dayName.substring(0, 3));
              final isToday = DateTime.now().weekday == index + 1;
              final isSelected = widget.selectedDate.weekday == index + 1;

              final dayDate = _getDateForWeekday(index + 1);
              final dailyProgress = _getDailyProgressForDate(task, dayDate);
              final isCompleted =
                  dailyProgress?.dailyMetrics.isComplete ?? false;

              return GestureDetector(
                onTap: isScheduled
                    ? () => _onDayTapped(context, dayDate)
                    : null,
                child: Column(
                  children: [
                    Text(
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : isCompleted
                            ? const Color(0xFF10B981)
                            : isScheduled
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : Icon(
                                isScheduled
                                    ? Icons.event_rounded
                                    : Icons.remove_rounded,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : isScheduled
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  DateTime _getDateForWeekday(int weekday) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    final diff = weekday - currentWeekday;
    return DateTime(now.year, now.month, now.day + diff);
  }

  void _onDayTapped(BuildContext context, DateTime date) {
    if (_isSameDay(date, widget.selectedDate)) return;

    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyTaskDailyAnalysisScreen(
          taskId: widget.taskId,
          selectedDate: date,
        ),
      ),
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'missed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'inprogress':
      case 'in_progress':
        return Icons.play_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'missed':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      default:
        return status.capitalize ?? status;
    }
  }

  Widget _buildWeeklyFeedbackDetails(BuildContext context, WeekTaskModel task) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Get all feedbacks from all days, sorted by date
    final allDailyProgress = task.dailyProgress.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (allDailyProgress.every(
      (p) =>
          p.feedbacks.isEmpty || p.feedbacks.every((f) => f.finalText.isEmpty),
    )) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Weekly Activity Log',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Weekly Feedback Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                'Weekly Feedbacks',
                '${task.totalFeedbacks}',
                Icons.history_rounded,
                Colors.purple,
              ),
              _buildSummaryItem(
                context,
                'Total Points',
                '${task.totalPointsEarned}',
                Icons.diamond_rounded,
                Colors.green,
              ),
              _buildSummaryItem(
                context,
                'Avg. Rating',
                task.summary.rating.toStringAsFixed(1),
                Icons.star_rounded,
                Colors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // List of day cards
        ...allDailyProgress.map((day) {
          if (day.feedbacks.isEmpty ||
              day.feedbacks.every((f) => f.finalText.isEmpty)) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header with Stats
                _buildDayCardHeader(context, day, isDark),

                // Feedbacks
                if (day.feedbacks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Feedbacks',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: day.feedbacks.length,
                    itemBuilder: (context, fbIndex) {
                      return _buildWeeklyFeedbackItem(
                        context,
                        feedback: day.feedbacks[fbIndex],
                        index: fbIndex,
                        isDark: isDark,
                        day: day,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Final Notes
                if (day.feedbacks.isNotEmpty && day.feedbacks.last.finalText.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                  _buildDayNotesSection(context, day, isDark),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCardHeader(
    BuildContext context,
    DailyProgress day,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Date Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.taskDate.split('-').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(day.date).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.dayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat(
                      Icons.star_rounded,
                      day.dailyMetrics.rating.toStringAsFixed(1),
                      Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniStat(
                      Icons.bolt_rounded,
                      '${day.dailyMetrics.progress}%',
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${day.dailyMetrics.pointsEarned} pts',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayNotesSection(
    BuildContext context,
    DailyProgress day,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 14, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                'Day Summary',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            day.feedbacks.isNotEmpty ? day.feedbacks.last.finalText ?? '' : '',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyFeedbackItem(
    BuildContext context, {
    required DailyFeedback feedback,
    required int index,
    required bool isDark,
    required DailyProgress day,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Index and Time
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Entry #${feedback.feedbackCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.hasMedia
                      ? 'Visual Verification'
                      : 'Status Checkpoint',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (feedback.hasMedia) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: EnhancedMediaDisplay(
                        mediaFiles: [
                          EnhancedMediaFile(
                            id: 'fb_${day.taskDate}_$index',
                            url: feedback.mediaUrl ?? '',
                            type: EnhancedMediaFile.detectMediaType(
                              feedback.mediaUrl ?? '',
                            ),
                          ),
                        ],
                        config: const MediaDisplayConfig(
                          layoutMode: MediaLayoutMode.single,
                          showDetails: false,
                          allowFullScreen: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddFeedbackToday(WeekTaskModel task, DailyProgress? dailyProgress) {
    if (dailyProgress == null) return true;

    // Check cooldown
    return dailyProgress.canAddFeedback();
  }


  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PATTERN PAINTER
// ================================================================

class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// lib/features/day_task/screens_widgets/day_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/logger.dart';
import '../../tasks_sidebar.dart';
import '../widgets/day_task_calendar_dialog.dart';
import '../widgets/day_task_card.dart';
import 'task_form_bottom_sheet.dart';
import '../models/day_task_model.dart';
import '../providers/day_task_provider.dart';
import '../../../../../widgets/feature_info_widgets.dart';

class DayScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;
  const DayScheduleScreen({super.key, this.initialDate});

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  List<DayTaskModel> tasks = [];
  List<DateTime> timeLabels = [];
  List<bool> _expandedStates = [];
  late DateTime selectedDate;

  String get formattedDate {
    final dayName = DateFormat('EEEE').format(selectedDate);
    final date = DateFormat('dd/MM/yyyy').format(selectedDate);
    return "$dayName $date";
  }

  // ── Feature Info Data ──
  // Relocated to EliteFeatures.dayTasks

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DayTaskProvider>().loadTasks(
          startDate: DateTime(selectedDate.year, selectedDate.month, 1),
          endDate: DateTime(selectedDate.year, selectedDate.month + 1, 0),
        );
      }
    });
  }

  // ================================================================
  // DATE PICKER
  // ================================================================

  Future<void> _pickDate() async {
    try {
      await DayTaskCalendarDialog.show(
        context,
        onDayTap: (picked) {
          if (picked != selectedDate) {
            final oldMonth = DateTime(selectedDate.year, selectedDate.month);
            final newMonth = DateTime(picked.year, picked.month);
            setState(() => selectedDate = picked);
            if (oldMonth != newMonth) {
              context.read<DayTaskProvider>().loadTasks(
                startDate: DateTime(picked.year, picked.month, 1),
                endDate: DateTime(picked.year, picked.month + 1, 0),
              );
            }
          }
        },
      );
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Calendar Dialog');
      if (mounted) {
        ErrorHandler.showErrorSnackbar(
          'Failed to open calendar. Please try again.',
          context: context,
        );
      }
    }
  }

  // ================================================================
  // TASK HELPERS
  // ================================================================

  bool isSameDay(DateTime a, String bString) {
    if (bString.isEmpty) return false;
    try {
      DateTime b;
      if (bString.length == 10 && bString[2] == '-' && bString[5] == '-') {
        b = DateFormat('dd-MM-yyyy').parse(bString);
      } else {
        b = DateTime.parse(bString);
      }
      return a.year == b.year && a.month == b.month && a.day == b.day;
    } catch (e) {
      return false;
    }
  }

  DateTime _getStartTime(DayTaskModel task) => task.timeline.startingTime;
  DateTime _getEndTime(DayTaskModel task) => task.timeline.endingTime;
  String _getTaskDay(DayTaskModel task) => task.timeline.taskDate;

  // ================================================================
  // CARD TOGGLE
  // ================================================================

  void _toggleCard(int index) {
    if (index < 0 || index >= _expandedStates.length) {
      ErrorHandler.logError('Invalid card index', index);
      return;
    }
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
  }

  // ================================================================
  // OPEN CREATE TASK FORM
  // ================================================================

  Future<void> _openCreateTaskForm() async {
    try {
      logI('📝 Opening create task form');
      await TaskFormBottomSheet.showCreateTask(context);
      if (mounted) {
        context.read<DayTaskProvider>().loadTasks(
          startDate: DateTime(selectedDate.year, selectedDate.month, 1),
          endDate: DateTime(selectedDate.year, selectedDate.month + 1, 0),
        );
        logI('✅ Task form closed, tasks refreshed');
      }
    } catch (e, stack) {
      ErrorHandler.handleError(e, stack, 'Open Create Task Form');
      if (mounted) {
        ErrorHandler.showErrorSnackbar('Failed to load schedule.');
      }
    }
  }

  // ================================================================
  // BUILD UI
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<DayTaskProvider>(
      builder: (context, provider, child) {
        // Automatically sync the UI with the provider's task list
        final allTasks = provider.tasks.where((t) {
          final taskDay = _getTaskDay(t);
          return isSameDay(selectedDate, taskDay);
        }).toList();

        allTasks.sort((a, b) {
          final aTime = _getStartTime(a);
          final bTime = _getStartTime(b);
          return aTime.compareTo(bTime);
        });

        // Ensure expanded states array matches the number of tasks
        if (_expandedStates.length != allTasks.length) {
          _expandedStates = List.filled(allTasks.length, false);
        }

        Set<DateTime> labels = {};
        for (var task in allTasks) {
          final start = _getStartTime(task);
          final end = _getEndTime(task);
          labels.add(start);
          if (end != start) labels.add(end);
        }

        this.tasks = allTasks;
        this.timeLabels = labels.toList()..sort();

        return SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: _buildAppBar(colorScheme, textTheme),
            body: _buildBody(provider, colorScheme, textTheme),
            floatingActionButton: _buildFAB(colorScheme, textTheme),
          ),
        );
      },
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.dashboard_outlined,
          color: Colors.blueAccent,
          size: 22,
        ),
        onPressed: () => TaskSidebarController.to.toggleSidebar(),
      ),

      title: Column(
        children: [
          Text(
            formattedDate.split(' ')[0],
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            formattedDate.split(' ')[1],
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month_rounded, size: 24),
          tooltip: 'Calendar',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            foregroundColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ================================================================
  // BODY
  // ================================================================

  Widget _buildBody(
    DayTaskProvider provider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return RefreshIndicator(
      onRefresh: () => provider.loadTasks(
        startDate: DateTime(selectedDate.year, selectedDate.month, 1),
        endDate: DateTime(selectedDate.year, selectedDate.month + 1, 0),
      ),
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: provider.isLoading && tasks.isEmpty
            ? _buildLoadingState(colorScheme, textTheme)
            : provider.error != null && tasks.isEmpty
            ? _buildErrorState(provider.error!, colorScheme, textTheme)
            : tasks.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FeatureInfoCard(feature: EliteFeatures.dayTasks),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsSummary(colorScheme, textTheme),
                          const SizedBox(height: 16),
                          _buildTimeline(colorScheme, textTheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ================================================================
  // STATS SUMMARY
  // ================================================================

  Widget _buildStatsSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final completed = tasks.where((t) => t.metadata.isComplete).length;
    final pending = tasks.where((t) => !t.metadata.isComplete).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.task_alt_rounded,
              label: 'Total',
              value: tasks.length.toString(),
              color: colorScheme.primary,
              textTheme: textTheme,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_rounded,
              label: 'Done',
              value: completed.toString(),
              color: Colors.green,
              textTheme: textTheme,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.pending_rounded,
              label: 'Pending',
              value: pending.toString(),
              color: Colors.orange,
              textTheme: textTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required TextTheme textTheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  // ================================================================
  // STATE BUILDERS
  // ================================================================

  Widget _buildLoadingState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String error,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              ErrorHandler.formatErrorMessage(error),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () =>
                context.read<DayTaskProvider>().loadTasks(
                  startDate: DateTime(selectedDate.year, selectedDate.month, 1),
                  endDate: DateTime(selectedDate.year, selectedDate.month + 1, 0),
                ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TIMELINE
  // ================================================================

  Widget _buildTimeline(ColorScheme colorScheme, TextTheme textTheme) {
    final renderedTasks = <DayTaskModel>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < timeLabels.length; i++)
          _buildTimelineSegment(
            i,
            timeLabels[i],
            renderedTasks,
            colorScheme,
            textTheme,
          ),
      ],
    );
  }

  Widget _buildTimelineSegment(
    int index,
    DateTime timeLabel,
    Set<DayTaskModel> renderedTasks,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final tasksInSegment = tasks.where((task) {
      if (renderedTasks.contains(task)) return false;
      final start = _getStartTime(task);
      final end = _getEndTime(task);
      return !(end.isBefore(timeLabel) || start.isAfter(timeLabel));
    }).toList();

    renderedTasks.addAll(tasksInSegment);

    if (tasksInSegment.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: _calculateSegmentHeight(tasksInSegment),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.5),
                      colorScheme.outlineVariant,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var task in tasksInSegment)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTaskItem(task, colorScheme, textTheme),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(
    DayTaskModel task,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final taskIndex = tasks.indexOf(task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('h:mm a').format(_getStartTime(task)),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DayTaskCard(
          task: task,
          isExpanded: taskIndex != -1 ? _expandedStates[taskIndex] : false,
          onToggle: () => _toggleCard(taskIndex),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('h:mm a').format(_getEndTime(task)),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateSegmentHeight(List<DayTaskModel> tasksInSegment) {
    if (tasksInSegment.isEmpty) return 60.0;
    double totalHeight = 0.0;
    for (var task in tasksInSegment) {
      totalHeight += 190.0;
      final taskIndex = tasks.indexOf(task);
      if (taskIndex != -1 && _expandedStates[taskIndex]) {
        totalHeight += 260.0;
      }
      totalHeight += 16.0;
    }
    return totalHeight;
  }

  // ================================================================
  // FAB
  // ================================================================

  Widget _buildFAB(ColorScheme colorScheme, TextTheme textTheme) {
    return FloatingActionButton.extended(
      onPressed: _openCreateTaskForm,
      heroTag: 'day_task_add_fab',
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Task',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// lib/features/long_goals/message_bubbles/long_goal_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../helpers/card_color_helper.dart';
import '../../../../../widgets/metric_indicators.dart';
import '../models/long_goal_model.dart';
import 'long_goal_calendar_widget.dart';
import 'long_goals_options_menu.dart';
import 'weekly_checklist_preview.dart';

/// Professional Long Goal Card with comprehensive information display
/// Uses TaskMetricIndicator system for consistent visual indicators
class LongGoalCard extends StatefulWidget {
  final LongGoalModel goal;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onAddFeedbackTap;

  const LongGoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCalendarTap,
    this.onAddFeedbackTap,
  });

  @override
  State<LongGoalCard> createState() => _LongGoalCardState();
}

class _LongGoalCardState extends State<LongGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  List<Color>? _headerGradientColors;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _statusKey(TaskStatus status) {
    return switch (status) {
      TaskStatus.completed => 'completed',
      TaskStatus.inProgress => 'inProgress',
      TaskStatus.pending => 'pending',
      TaskStatus.postponed => 'postponed',
      TaskStatus.upcoming => 'upcoming',
      TaskStatus.missed => 'missed',
      TaskStatus.failed => 'failed',
      TaskStatus.cancelled => 'cancelled',
      TaskStatus.skipped => 'skipped',
      TaskStatus.hold => 'hold',
      TaskStatus.unknown => 'unknown',
    };
  }

  // Calculate overall progress
  double get _overallProgress {
    if (widget.goal.metrics.totalDays > 0) {
      return (widget.goal.metrics.completedDays / widget.goal.metrics.totalDays)
          .clamp(0.0, 1.0);
    }
    return (widget.goal.analysis.averageProgress / 100).clamp(0.0, 1.0);
  }

  int get _progressPercent => (_overallProgress * 100).round();

  // Parse status to TaskStatus enum
  TaskStatus get _taskStatus {
    final status = widget.goal.indicators.status.toLowerCase();
    return switch (status) {
      'completed' || 'complete' => TaskStatus.completed,
      'inprogress' || 'in_progress' || 'in progress' => TaskStatus.inProgress,
      'pending' => TaskStatus.pending,
      'paused' || 'on_hold' => TaskStatus.postponed,
      'upcoming' => TaskStatus.upcoming,
      'missed' || 'overdue' => TaskStatus.missed,
      'failed' => TaskStatus.failed,
      'cancelled' || 'canceled' => TaskStatus.cancelled,
      'skipped' => TaskStatus.skipped,
      _ => TaskStatus.unknown,
    };
  }

  // Get priority string
  String get _priority => widget.goal.indicators.priority;

  /// Show calendar view
  void _handleCalendarTap() {
    HapticFeedback.mediumImpact();

    if (widget.onCalendarTap != null) {
      widget.onCalendarTap!();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LongGoalCalendarWidget(
        goal: widget.goal,
        onAddFeedback: (date) => LongGoalsOptionsMenu.navigateToAddFeedback(
          context,
          widget.goal,
          date: date,
        ),
      ),
    );
  }

  /// Show add feedback screen
  void _handleAddFeedbackTap() {
    HapticFeedback.mediumImpact();
    if (widget.onAddFeedbackTap != null) {
      widget.onAddFeedbackTap!();
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    _headerGradientColors ??= CardColorHelper.getTaskCardGradient(
      priority: _priority,
      status: widget.goal.indicators.status,
      progress: (_overallProgress * 100).round(),
      isDarkMode: theme.brightness == Brightness.dark,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(0), // Remove if you have padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(theme, colors),
                  const SizedBox(height: 16),
                  _buildProgressSection(theme, colors),
                  _buildDescriptionSection(theme, colors),
                  _buildTimelineSection(theme, colors),
                  _buildActionButtons(theme, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ============================================
  // HEADER SECTION
  // ============================================

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _headerGradientColors!,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Indicator using TaskMetricIndicator
              TaskMetricIndicator(
                type: TaskMetricType.status,
                value: _taskStatus,
                size: 36,
                showLabel: false,
                recordId: widget.goal.goalId,
              ),
              const SizedBox(width: 12),
              // Priority Indicator using TaskMetricIndicator
              TaskMetricIndicator(
                type: TaskMetricType.priority,
                value: _priority,
                size: 36,
                showLabel: false,
                recordId: widget.goal.goalId,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => WeeklyChecklistPreview(
                      goal: widget.goal,
                      colorScheme: colors,
                    ),
                  );
                },
                icon: Icon(Icons.list_alt_rounded, color: colors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  LongGoalsOptionsMenu.showFromContext(
                    context: context,
                    goal: widget.goal,
                  );
                },
                icon: Icon(Icons.more_vert_rounded, color: colors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category Tag
          if (widget.goal.categoryType != null) ...[
            // Status and Priority Labels
            _buildStatusPriorityLabels(theme, colors),
            const SizedBox(height: 12),
          ],
          // Title
          Text(
            widget.goal.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          _buildQuickMetricsRow(theme, colors),
        ],
      ),
    );
  }

  Widget _buildStatusPriorityLabels(ThemeData theme, ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _buildSmallLabel(
          label: widget.goal.categoryType!,
          color: CardColorHelper.getStatusColor(_statusKey(_taskStatus)),
          theme: theme,
        ),
        _buildSmallLabel(
          label: widget.goal.subTypes!,
          color: CardColorHelper.getPriorityColor(_priority),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildSmallLabel({
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Removed legacy status/priority color methods in favor of CardColorHelper

  // ============================================
  // QUICK METRICS ROW (New Section)
  // ============================================

  Widget _buildQuickMetricsRow(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: TaskMetricIndicatorRow(
          spacing: 12,
          indicators: [
            // Progress
            TaskMetricIndicator(
              type: TaskMetricType.progress,
              value: _progressPercent,
              size: 44,
              showLabel: true,
              customLabel: 'Progress',
            ),
            // Rating
            if (widget.goal.analysis.averageRating > 0)
              TaskMetricIndicator(
                type: TaskMetricType.rating,
                value: widget.goal.analysis.averageRating,
                size: 24,
                showLabel: true,
                customLabel: 'Rating',
              ),
            // Points Earned
            if (widget.goal.analysis.pointsEarned > 0)
              TaskMetricIndicator(
                type: TaskMetricType.pointsEarned,
                value: widget.goal.analysis.pointsEarned,
                size: 28,
                showLabel: true,
              ),
            // Posted Indicator
            if (widget.goal.socialInfo.isPosted)
              TaskMetricIndicator(
                type: TaskMetricType.posted,
                value: {'live': widget.goal.socialInfo.posted?.live ?? false},
                size: 28,
                showLabel: true,
              ),
            // Shared Indicator
            if (widget.goal.shareInfo.isShare)
              TaskMetricIndicator(
                type: TaskMetricType.shared,
                value: {
                  'live': widget.goal.shareInfo.shareId?.live ?? false,
                  'count': widget.goal.shareInfo.isShare ? 1 : 0,
                },
                size: 28,
                showLabel: true,
              ),
            // Penalty Indicator
            if (widget.goal.analysis.totalPenalty != null &&
                widget.goal.analysis.totalPenalty!.penaltyPoints > 0)
              TaskMetricIndicator(
                type: TaskMetricType.penalty,
                value: widget.goal.analysis.totalPenalty!.penaltyPoints,
                size: 28,
                showLabel: true,
                customLabel:
                    'Penalty: ${widget.goal.analysis.totalPenalty!.reason}',
              ),
            // Reward Indicator
            if (widget.goal.analysis.rewardPackage != null &&
                widget.goal.analysis.rewardPackage!.earned)
              TaskMetricIndicator(
                type: TaskMetricType.reward,
                value: widget.goal.analysis.rewardPackage!.points.toDouble(),
                size: 28,
                showLabel: true,
                customLabel:
                    'Reward: ${widget.goal.analysis.rewardPackage!.tagName}',
              ),
            // Overdue Indicator
            if (_isOverdue)
              TaskMetricIndicator(
                type: TaskMetricType.overdue,
                value: true,
                size: 28,
                showLabel: true,
              ),
          ],
        ),
      ),
    );
  }

  bool get _isOverdue {
    if (widget.goal.timeline.isUnspecified ||
        widget.goal.timeline.endDate == null) {
      return false;
    }
    return widget.goal.timeline.endDate!.isBefore(DateTime.now()) &&
        _taskStatus != TaskStatus.completed;
  }

  // ============================================
  // DESCRIPTION SECTION (EXPANDABLE)
  // ============================================

  Widget _buildDescriptionSection(ThemeData theme, ColorScheme colors) {
    final hasDescription =
        widget.goal.description.outcome.isNotEmpty ||
        widget.goal.description.need.isNotEmpty ||
        widget.goal.description.motivation.isNotEmpty;

    if (!hasDescription) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with expand/collapse
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goal Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  // Collapsed Preview
                  if (!_isExpanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.goal.description.outcome.isNotEmpty
                          ? widget.goal.description.outcome
                          : widget.goal.description.need,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Expanded Content
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          if (widget.goal.description.need.isNotEmpty)
                            _buildInfoSection(
                              theme: theme,
                              colors: colors,
                              icon: Icons.flag_rounded,
                              title: 'Goal',
                              content: widget.goal.description.need,
                            ),
                          if (widget
                              .goal
                              .description
                              .motivation
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoSection(
                              theme: theme,
                              colors: colors,
                              icon: Icons.emoji_events_rounded,
                              title: 'Motivation',
                              content: widget.goal.description.motivation,
                            ),
                          ],
                          if (widget.goal.description.outcome.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoSection(
                              theme: theme,
                              colors: colors,
                              icon: Icons.track_changes_rounded,
                              title: 'Outcome',
                              content: widget.goal.description.outcome,
                            ),
                          ],
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required ColorScheme colors,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // PROGRESS SECTION
  // ============================================

  Widget _buildProgressSection(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.08),
              colors.secondary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Use Progress Indicator
                    TaskMetricIndicator(
                      type: TaskMetricType.progress,
                      value: _progressPercent,
                      size: 48,
                      showLabel: false,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.goal.metrics.completedDays} of ${widget.goal.metrics.totalDays} days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Efficiency Indicator
                if (widget.goal.analysis.averageProgress > 0)
                  TaskMetricIndicator(
                    type: TaskMetricType.progress,
                    value: widget.goal.analysis.averageProgress,
                    size: 40,
                    showLabel: true,
                    customLabel: 'Average Progress',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Row with Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStatWithIndicator(
                  theme: theme,
                  colors: colors,
                  metricType: TaskMetricType.status,
                  metricValue: TaskStatus.completed,
                  label: 'Completed',
                  value: '${widget.goal.metrics.completedDays}',
                ),
                _buildProgressStatWithIndicator(
                  theme: theme,
                  colors: colors,
                  metricType: TaskMetricType.status,
                  metricValue: TaskStatus.inProgress,
                  label: 'Total Days',
                  value: '${widget.goal.metrics.totalDays}',
                ),
                _buildProgressStatWithIndicator(
                  theme: theme,
                  colors: colors,
                  metricType: TaskMetricType.status,
                  metricValue: TaskStatus.pending,
                  label: 'Pending',
                  value: '${widget.goal.metrics.tasksPending}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatWithIndicator({
    required ThemeData theme,
    required ColorScheme colors,
    required TaskMetricType metricType,
    required dynamic metricValue,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        TaskMetricIndicator(
          type: metricType,
          value: metricValue,
          size: 28,
          showLabel: false,
          animate: false,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================
  // TIMELINE SECTION (FIXED)
  // ============================================

  Widget _buildTimelineSection(ThemeData theme, ColorScheme colors) {
    if (widget.goal.timeline.isUnspecified ||
        widget.goal.timeline.startDate == null ||
        widget.goal.timeline.endDate == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              TaskMetricIndicator(
                type: TaskMetricType.deadline,
                value: null,
                size: 32,
                showLabel: false,
              ),
              const SizedBox(width: 12),
              Text(
                'No timeline specified',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final startDate = widget.goal.timeline.startDate!;
    final endDate = widget.goal.timeline.endDate!;
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;
    final totalDays = endDate.difference(startDate).inDays;
    final daysElapsed = now.difference(startDate).inDays.clamp(0, totalDays);
    final hoursPerDay = widget.goal.timeline.workSchedule.hoursPerDay;

    // Get preferred time slot (can be null)
    final preferredTimeSlot =
        widget.goal.timeline.workSchedule.preferredTimeSlot;
    final accent = CardColorHelper.getStatusColor(_statusKey(_taskStatus));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.secondary.withValues(alpha: 0.08),
              accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Calendar Icon with Deadline Indicator
                TaskMetricIndicator(
                  type: TaskMetricType.deadline,
                  value: endDate,
                  size: 36,
                  showLabel: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM d, yyyy').format(startDate)} → ${DateFormat('MMM d, yyyy').format(endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time Left or Overdue Indicator
                _buildTimeRemainingIndicator(daysRemaining),
              ],
            ),
            const SizedBox(height: 16),
            // Timeline Progress Bar
            _buildTimelineProgressBar(
              theme: theme,
              colors: colors,
              daysElapsed: daysElapsed,
              totalDays: totalDays,
            ),
            const SizedBox(height: 16),
            // Stats Row with Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimelineStat(
                  theme: theme,
                  colors: colors,
                  icon: Icons.calendar_month_rounded,
                  label: 'Duration',
                  value: '$totalDays days',
                ),
                _buildTimelineStat(
                  theme: theme,
                  colors: colors,
                  icon: Icons.history_rounded,
                  label: 'Elapsed',
                  value: '$daysElapsed days',
                ),
                _buildTimelineStat(
                  theme: theme,
                  colors: colors,
                  icon: Icons.schedule_rounded,
                  label: 'Hours/Day',
                  value: '${hoursPerDay}h',
                ),
              ],
            ),
            // Start/End Time Indicators - FIXED: Use preferredTimeSlot
            if (preferredTimeSlot != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimeIndicatorCard(
                    theme: theme,
                    colors: colors,
                    type: TaskMetricType.startingTime,
                    time: preferredTimeSlot.startingTime,
                    label: 'Start Time',
                  ),
                  _buildTimeIndicatorCard(
                    theme: theme,
                    colors: colors,
                    type: TaskMetricType.endingTime,
                    time: preferredTimeSlot.endingTime,
                    label: 'End Time',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRemainingIndicator(int daysRemaining) {
    if (daysRemaining < 0) {
      // Overdue
      return TaskMetricIndicator(
        type: TaskMetricType.overdue,
        value: true,
        size: 28,
        showLabel: false,
      );
    }

    // Time Left
    String timeLeftText;
    if (daysRemaining == 0) {
      timeLeftText = 'Due today';
    } else if (daysRemaining == 1) {
      timeLeftText = '1 day left';
    } else if (daysRemaining < 7) {
      timeLeftText = '$daysRemaining days left';
    } else if (daysRemaining < 30) {
      final weeks = (daysRemaining / 7).floor();
      timeLeftText = '$weeks week${weeks > 1 ? 's' : ''} left';
    } else {
      final months = (daysRemaining / 30).floor();
      timeLeftText = '$months month${months > 1 ? 's' : ''} left';
    }

    return TaskMetricIndicator(
      type: TaskMetricType.timeLeft,
      value: timeLeftText,
      size: 28,
      showLabel: false,
    );
  }

  Widget _buildTimelineProgressBar({
    required ThemeData theme,
    required ColorScheme colors,
    required int daysElapsed,
    required int totalDays,
  }) {
    final progress = totalDays > 0
        ? (daysElapsed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              progress > 0.8 && _overallProgress < progress
                  ? Colors
                        .orange // Behind schedule
                  : colors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStat({
    required ThemeData theme,
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.secondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.secondary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeIndicatorCard({
    required ThemeData theme,
    required ColorScheme colors,
    required TaskMetricType type,
    required DateTime time,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TaskMetricIndicator(
            type: type,
            value: time,
            size: 28,
            showLabel: false,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(time),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTION BUTTONS
  // ============================================

  Widget _buildActionButtons(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Calendar + Add Feedback Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleCalendarTap,
                  icon: const Icon(Icons.calendar_view_month_rounded, size: 20),
                  label: const Text('Calendar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (widget.onAddFeedbackTap != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleAddFeedbackTap,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Feedback'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.secondary,
                      side: BorderSide(color: colors.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onTap();
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: const Text('View Full Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for String capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

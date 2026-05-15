// lib/features/long_goals/message_bubbles/long_goal_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../personal/task_model/long_goal/models/long_goal_model.dart';
import '../../personal/task_model/long_goal/widgets/long_goal_calendar_widget.dart';
import 'long_goal_metadata_popup.dart';

/// Professional Long Goal Card with comprehensive information display
/// Uses TaskMetricIndicator system for consistent visual indicators
class PostSharedLongGoalCard extends StatefulWidget {
  final LongGoalModel goal;
  final bool isLive;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PostSharedLongGoalCard({
    super.key,
    required this.goal,
    this.isLive = false,
    this.margin,
    this.onTap,
  });

  @override
  State<PostSharedLongGoalCard> createState() => _PostSharedLongGoalCardState();
}

class _PostSharedLongGoalCardState extends State<PostSharedLongGoalCard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _expandController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  bool _isExpanded = false;
  List<Color>? _headerGradientColors;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    // Expand/Collapse animation
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _expandController.dispose();
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

  double get _overallProgress {
    if (widget.goal.metrics.totalDays > 0) {
      return (widget.goal.metrics.completedDays / widget.goal.metrics.totalDays)
          .clamp(0.0, 1.0);
    }
    return (widget.goal.analysis.averageProgress / 100).clamp(0.0, 1.0);
  }

  int get _progressPercent => (_overallProgress * 100).round();

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

  String get _priority => widget.goal.indicators.priority;

  void _toggleExpanded() {
    HapticFeedback.mediumImpact();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _showCalendarDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => LongGoalCalendarWidget(goal: widget.goal),
    );
  }

  void _showMetadataPopup() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => LongGoalMetadataPopup(goal: widget.goal),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _headerGradientColors ??= CardColorHelper.getTaskCardGradient(
      priority: _priority,
      status: widget.goal.indicators.status,
      progress: (_overallProgress * 100).round(),
      isDarkMode: isDark,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: colors.secondary.withOpacity(0.05),
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
              widget.onTap?.call();
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme, colors),
                const SizedBox(height: 16),
                _buildProgressSection(theme, colors),
                _buildExpandableContent(theme, colors),
                _buildTimelineSection(theme, colors),
                _buildActionButtons(theme, colors),
              ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), // Reduced from 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _headerGradientColors![0],
            _headerGradientColors![1].withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: _headerGradientColors![0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TaskMetricIndicator(
                    type: TaskMetricType.status,
                    value: _taskStatus,
                    size: 32,
                    showLabel: false,
                    recordId: widget.goal.goalId,
                  ),
                  const SizedBox(width: 8),
                  TaskMetricIndicator(
                    type: TaskMetricType.priority,
                    value: _priority,
                    size: 32,
                    showLabel: false,
                    recordId: widget.goal.goalId,
                  ),
                  const SizedBox(width: 8),
                  TaskMetricIndicator(
                    type: TaskMetricType.category,
                    value: 'Long Goal',
                    size: 32,
                    showLabel: false,
                    recordId: widget.goal.goalId,
                  ),
                ],
              ),
              TaskMetricIndicator(
                type: TaskMetricType.liveSnapshot,
                value: widget.isLive,
                size: 28,
                showLabel: false,
              ),
              Spacer(),
              const SizedBox(width: 8),
              _buildExpandButton(theme, colors),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.goal.categoryType != null ||
              widget.goal.subTypes != null) ...[
            _buildStatusPriorityLabels(theme, colors),
            const SizedBox(height: 12),
          ],
          Text(
            widget.goal.title.isEmpty || widget.goal.title == 'null'
                ? 'Untitled Goal'
                : widget.goal.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          _buildQuickMetricsRow(theme, colors),
        ],
      ),
    );
  }

  Widget _buildExpandButton(ThemeData theme, ColorScheme colors) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isExpanded
                    ? [colors.primary, colors.secondary]
                    : [
                        colors.primary.withOpacity(0.15),
                        colors.secondary.withOpacity(0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isExpanded
                    ? Colors.white.withOpacity(0.3)
                    : colors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: _isExpanded
                  ? [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _isExpanded ? Colors.white : colors.primary,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPriorityLabels(ThemeData theme, ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (widget.goal.categoryType != null)
          _buildSmallLabel(
            label: widget.goal.categoryType!,
            color: CardColorHelper.getStatusColor(_statusKey(_taskStatus)),
            theme: theme,
          ),
        if (widget.goal.subTypes != null)
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildQuickMetricsRow(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: TaskMetricIndicatorRow(
          spacing: 16,
          indicators: [
            // Progress
            TaskMetricIndicator(
              type: TaskMetricType.progress,
              value: _progressPercent,
              size: 40,
              showLabel: true,
              customLabel: 'Progress',
            ),
            // Efficiency (Overall completion rate)
            if (widget.goal.metrics.totalDays > 0)
              TaskMetricIndicator(
                type: TaskMetricType.efficiency,
                value: (widget.goal.consistencyScore / 100),
                size: 32,
                showLabel: true,
                customLabel: 'Efficiency',
              ),
            // Points Earned
            if (widget.goal.analysis.pointsEarned > 0)
              TaskMetricIndicator(
                type: TaskMetricType.pointsEarned,
                value: widget.goal.analysis.pointsEarned,
                size: 32,
                showLabel: true,
              ),
            // Rating
            if (widget.goal.analysis.averageRating > 0)
              TaskMetricIndicator(
                type: TaskMetricType.rating,
                value: widget.goal.analysis.averageRating,
                size: 20,
                showLabel: true,
                customLabel: 'Rating',
              ),
            // Tag
            if (widget.goal.analysis.tagName.isNotEmpty)
              TaskMetricIndicator(
                type: TaskMetricType.tag,
                value: [widget.goal.analysis.tagName],
                size: 24,
                showLabel: true,
                customLabel: 'Tag',
              ),
            // Posted Indicator
            TaskMetricIndicator(
              type: TaskMetricType.posted,
              value: {'live': widget.goal.socialInfo.posted?.live ?? false},
              size: 28,
              showLabel: true,
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
              colors.primary.withOpacity(0.08),
              colors.secondary.withOpacity(0.04),
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
  // EXPANDABLE CONTENT SECTION
  // ============================================

  Widget _buildExpandableContent(ThemeData theme, ColorScheme colors) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Column(children: [_buildDescriptionSection(theme, colors)]),
      ),
    );
  }

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Goal Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.goal.description.need.isNotEmpty)
                  _buildInfoSection(
                    theme: theme,
                    colors: colors,
                    icon: Icons.flag_rounded,
                    title: 'Goal',
                    content: widget.goal.description.need,
                  ),
                if (widget.goal.description.motivation.isNotEmpty) ...[
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
            color: colors.primary.withOpacity(0.1),
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
  // TIMELINE SECTION
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
              colors.secondary.withOpacity(0.08),
              accent.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.secondary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
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
                _buildTimeRemainingIndicator(daysRemaining),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineProgressBar(
              theme: theme,
              colors: colors,
              daysElapsed: daysElapsed,
              totalDays: totalDays,
            ),
            const SizedBox(height: 16),
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
      return TaskMetricIndicator(
        type: TaskMetricType.overdue,
        value: true,
        size: 28,
        showLabel: false,
      );
    }

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
                  ? Colors.orange
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
            color: colors.secondary.withOpacity(0.1),
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
        color: colors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary.withOpacity(0.2)),
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showCalendarDialog,
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
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showMetadataPopup,
              icon: const Icon(Icons.analytics_rounded, size: 20),
              label: const Text('Statistics'),
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

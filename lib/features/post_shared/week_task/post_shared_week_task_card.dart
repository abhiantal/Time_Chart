// lib/features/social/message_bubbles/post_shared_week_task_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../personal/task_model/week_task/models/week_task_model.dart';
import '../../personal/category_model/models/category_model.dart';
import '../../personal/task_model/week_task/widgets/week_task_calendar_widget.dart';
import 'week_task_metadata_popup.dart';

/// Premium Post Shared Week Task Card with comprehensive information display
/// Matches PostSharedLongGoalCard design patterns exactly
class PostSharedWeekTaskCard extends StatefulWidget {
  final WeekTaskModel task;
  final Category? category;
  final bool isLive;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const PostSharedWeekTaskCard({
    super.key,
    required this.task,
    this.category,
    this.isLive = false,
    this.margin,
    this.onTap,
  });

  @override
  State<PostSharedWeekTaskCard> createState() => _PostSharedWeekTaskCardState();
}

class _PostSharedWeekTaskCardState extends State<PostSharedWeekTaskCard>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _entryController;
  late AnimationController _expandController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;

  bool _isExpanded = false;
  List<Color>? _headerGradientColors;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Entry animation
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
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

    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Float animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _expandController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ============================================
  // HELPER METHODS & GETTERS
  // ============================================

  String _statusKey(String status) {
    return switch (status.toLowerCase()) {
      'completed' => 'completed',
      'inprogress' || 'in_progress' => 'inProgress',
      'pending' => 'pending',
      'postponed' => 'postponed',
      'upcoming' => 'upcoming',
      'missed' || 'overdue' => 'missed',
      'cancelled' => 'cancelled',
      'skipped' => 'skipped',
      _ => 'unknown',
    };
  }

  TaskStatus get _taskStatus {
    final status = widget.task.indicators.status.toLowerCase();
    return switch (status) {
      'completed' => TaskStatus.completed,
      'inprogress' || 'in_progress' => TaskStatus.inProgress,
      'pending' => TaskStatus.pending,
      'postponed' || 'paused' || 'onhold' => TaskStatus.postponed,
      'upcoming' => TaskStatus.upcoming,
      'missed' || 'overdue' => TaskStatus.missed,
      'failed' => TaskStatus.failed,
      'cancelled' => TaskStatus.cancelled,
      'skipped' => TaskStatus.skipped,
      _ => TaskStatus.unknown,
    };
  }

  String get _priority => widget.task.indicators.priority;

  double get _overallProgress {
    final totalScheduled = widget.task.timeline.totalScheduledDays;
    if (totalScheduled > 0) {
      return (widget.task.totalCompletedDays / totalScheduled).clamp(0.0, 1.0);
    }
    return (widget.task.summary.progress / 100).clamp(0.0, 1.0);
  }

  int get _progressPercent => (_overallProgress * 100).round();

  bool get _isOverdue {
    return widget.task.timeline.isOverdue &&
        _taskStatus != TaskStatus.completed;
  }

  void _toggleExpanded() {
    HapticFeedback.mediumImpact();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _showMetadataPopup() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => WeekTaskMetadataPopup(task: widget.task),
    );
  }

  void _showCalendarDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => WeekTaskCalendarWidget(task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _headerGradientColors ??= CardColorHelper.getTaskCardGradient(
      priority: _priority,
      status: widget.task.indicators.status,
      progress: _progressPercent,
      isDarkMode: isDark,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                  _buildHeader(theme, colors, isDark),
                  const SizedBox(height: 16),
                  _buildProgressSection(theme, colors),
                  _buildExpandableContent(theme, colors, isDark),
                  _buildWeeklyProgressSection(theme, colors, isDark),
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
  // HEADER SECTION (Matching LongGoalCard)
  // ============================================

  Widget _buildHeader(ThemeData theme, ColorScheme colors, bool isDark) {
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
          // Top Row - Indicators
          Row(
            children: [
              // Status Indicator
              TaskMetricIndicator(
                type: TaskMetricType.status,
                value: _taskStatus,
                size: 36,
                showLabel: false,
                recordId: widget.task.id,
              ),
              const SizedBox(width: 12),
              // Priority Indicator
              TaskMetricIndicator(
                type: TaskMetricType.priority,
                value: _priority,
                size: 36,
                showLabel: false,
                recordId: widget.task.id,
              ),
              const SizedBox(width: 12),
              // Category Indicator
              TaskMetricIndicator(
                type: TaskMetricType.category,
                value: 'Week Task',
                size: 36,
                showLabel: false,
                recordId: widget.task.id,
              ),
              const Spacer(),
              TaskMetricIndicator(
                type: TaskMetricType.liveSnapshot,
                value: widget.isLive,
                size: 28,
                showLabel: false,
              ),
              const SizedBox(width: 8),
              _buildExpandButton(theme, colors),
            ],
          ),
          const SizedBox(height: 16),

          // Category Labels
          if (widget.task.categoryType.isNotEmpty ||
              widget.task.subTypes.isNotEmpty) ...[
            _buildStatusPriorityLabels(theme, colors),
            const SizedBox(height: 12),
          ],

          // Title
          Text(
            widget.task.aboutTask.taskName,
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

          // Quick Metrics Row
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
      alignment: WrapAlignment.start,
      children: [
        if (widget.task.categoryType.isNotEmpty)
          _buildSmallLabel(
            label: widget.task.categoryType,
            color: CardColorHelper.getStatusColor(
              _statusKey(widget.task.indicators.status),
            ),
            theme: theme,
          ),
        if (widget.task.subTypes.isNotEmpty)
          _buildSmallLabel(
            label: widget.task.subTypes,
            color: CardColorHelper.getPriorityColor(_priority),
            theme: theme,
          ),
        if (widget.task.summary.bestTag.isNotEmpty)
          _buildSmallLabel(
            label: widget.task.summary.bestTag,
            color: colors.tertiary,
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

  // ============================================
  // QUICK METRICS ROW (All Indicators)
  // ============================================

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
              value: widget.task.summary.progress,
              size: 40,
              showLabel: true,
              customLabel: 'Progress',
            ),
            // Efficiency (Tasks completed ratio or specific metric if available)
            if (widget.task.summary.completedDays > 0)
              TaskMetricIndicator(
                type: TaskMetricType.efficiency,
                value:
                    widget.task.summary.completedDays /
                    (widget.task.timeline.totalScheduledDays > 0
                        ? widget.task.timeline.totalScheduledDays
                        : 1),
                size: 32,
                showLabel: true,
                customLabel: 'Efficiency',
              ),
            // Points Earned
            if (widget.task.summary.pointsEarned > 0)
              TaskMetricIndicator(
                type: TaskMetricType.pointsEarned,
                value: widget.task.summary.pointsEarned,
                size: 32,
                showLabel: true,
              ),
            // Rating
            if (widget.task.summary.rating > 0)
              TaskMetricIndicator(
                type: TaskMetricType.rating,
                value: widget.task.summary.rating,
                size: 20,
                showLabel: true,
                customLabel: 'Rating',
              ),
            // Feedback Count
            if (widget.task.dailyProgress.isNotEmpty)
              TaskMetricIndicator(
                type: TaskMetricType.feedbackCount,
                value: widget.task.dailyProgress.fold<int>(
                  0,
                  (sum, day) => sum + day.feedbacks.length,
                ),
                size: 28,
                showLabel: true,
                customLabel: 'Feedbacks',
              ),
            // Media Count (count feedbacks that have media)
            if (widget.task.dailyProgress.any(
              (d) => d.feedbacks.any((f) => f.hasMedia),
            ))
              TaskMetricIndicator(
                type: TaskMetricType.mediaCount,
                value: widget.task.dailyProgress.fold<int>(
                  0,
                  (sum, day) =>
                      sum + day.feedbacks.where((f) => f.hasMedia).length,
                ),
                size: 28,
                showLabel: true,
              ),
            // Tag
            if (widget.task.summary.bestTag.isNotEmpty)
              TaskMetricIndicator(
                type: TaskMetricType.tag,
                value: [widget.task.summary.bestTag],
                size: 24,
                showLabel: true,
                customLabel: 'Top Tag',
              ),
            // Milestone
            if (widget.task.taskStack >= 4)
              TaskMetricIndicator(
                type: TaskMetricType.milestone,
                value: true,
                size: 28,
                showLabel: true,
              ),
            // Posted Indicator
            TaskMetricIndicator(
              type: TaskMetricType.posted,
              value: {'live': widget.task.socialInfo.posted?.live ?? false},
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

  // ============================================
  // PROGRESS SECTION (Matching LongGoalCard)
  // ============================================

  Widget _buildProgressSection(ThemeData theme, ColorScheme colors) {
    final totalScheduled = widget.task.timeline.totalScheduledDays;
    final completed = widget.task.totalCompletedDays;

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
                    // Progress Indicator
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
                          '$completed of $totalScheduled days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Average Progress Indicator
                if (widget.task.summary.progress > 0)
                  TaskMetricIndicator(
                    type: TaskMetricType.progress,
                    value: widget.task.summary.progress,
                    size: 40,
                    showLabel: true,
                    customLabel: 'Avg Progress',
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
                  value: '$completed',
                ),
                _buildProgressStatWithIndicator(
                  theme: theme,
                  colors: colors,
                  metricType: TaskMetricType.status,
                  metricValue: TaskStatus.inProgress,
                  label: 'Total Days',
                  value: '$totalScheduled',
                ),
                _buildProgressStatWithIndicator(
                  theme: theme,
                  colors: colors,
                  metricType: TaskMetricType.status,
                  metricValue: TaskStatus.pending,
                  label: 'Pending',
                  value:
                      '${(totalScheduled - completed).clamp(0, totalScheduled)}',
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

  Widget _buildExpandableContent(
    ThemeData theme,
    ColorScheme colors,
    bool isDark,
  ) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Column(
          children: [
            _buildDescriptionSection(theme, colors),
            _buildTimelineSection(theme, colors),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DESCRIPTION SECTION
  // ============================================

  Widget _buildDescriptionSection(ThemeData theme, ColorScheme colors) {
    final hasDescription =
        widget.task.aboutTask.taskDescription?.isNotEmpty ?? false;

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
                      'Task Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  theme: theme,
                  colors: colors,
                  icon: Icons.task_alt_rounded,
                  title: 'Description',
                  content: widget.task.aboutTask.taskDescription!,
                ),
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
  // TIMELINE SECTION (Matching LongGoalCard)
  // ============================================

  Widget _buildTimelineSection(ThemeData theme, ColorScheme colors) {
    final startDate = widget.task.timeline.startingTime;
    final endDate = widget.task.timeline.endingTime;
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;
    final totalDays = endDate.difference(startDate).inDays;
    final daysElapsed = now.difference(startDate).inDays.clamp(0, totalDays);
    final hoursPerDay = widget.task.estimatedHoursPerDay;
    final accent = CardColorHelper.getStatusColor(
      _statusKey(widget.task.indicators.status),
    );

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
            // Header Row
            Row(
              children: [
                // Deadline Indicator
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
            // Stats Row
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
            // Time Indicators
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
                  time: widget.task.timeline.startingTime,
                  label: 'Start Time',
                ),
                _buildTimeIndicatorCard(
                  theme: theme,
                  colors: colors,
                  type: TaskMetricType.endingTime,
                  time: widget.task.timeline.endingTime,
                  label: 'End Time',
                ),
              ],
            ),
            // Schedule Days
            const SizedBox(height: 16),
            _buildScheduleDays(theme, colors),
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

  Widget _buildScheduleDays(ThemeData theme, ColorScheme colors) {
    final scheduledDays = widget.task.scheduledDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_repeat_rounded, size: 16, color: colors.secondary),
            const SizedBox(width: 8),
            Text(
              'Scheduled Days',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: scheduledDays.map((day) {
            final isToday = _isTodayScheduled(day);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? colors.secondary.withOpacity(0.2)
                    : colors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isToday
                      ? colors.secondary
                      : colors.secondary.withOpacity(0.3),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Text(
                _getDayAbbreviation(day),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                  color: isToday
                      ? colors.secondary
                      : colors.secondary.withOpacity(0.8),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================
  // WEEKLY PROGRESS SECTION (Enhanced)
  // ============================================

  Widget _buildWeeklyProgressSection(
    ThemeData theme,
    ColorScheme colors,
    bool isDark,
  ) {
    final completedCount = widget.task.totalCompletedDays;
    final totalScheduled = widget.task.timeline.totalScheduledDays;
    final progressPercent = totalScheduled > 0
        ? ((completedCount / totalScheduled) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colors.primary.withOpacity(0.12),
                        colors.secondary.withOpacity(0.08),
                        colors.tertiary.withOpacity(0.05),
                      ]
                    : [
                        colors.primary.withOpacity(0.08),
                        colors.secondary.withOpacity(0.05),
                        colors.tertiary.withOpacity(0.03),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 2,
                color: colors.primary.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with progress
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.view_week_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedCount of $totalScheduled days completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: progressPercent >= 100
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [colors.primary, colors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (progressPercent >= 100
                                    ? Colors.green
                                    : colors.primary)
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (progressPercent >= 100)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      if (progressPercent >= 100) const SizedBox(width: 4),
                      Text(
                        '$progressPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progressPercent / 100),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: progressPercent >= 100
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [colors.primary, colors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (progressPercent >= 100
                                            ? Colors.green
                                            : colors.primary)
                                        .withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildWeeklyMetricChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Completed',
                    value: '$completedCount',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildWeeklyMetricChip(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: widget.task.summary.rating.toStringAsFixed(1),
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _buildWeeklyMetricChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'Points',
                    value: '${widget.task.summary.pointsEarned}',
                    color: Colors.purple,
                  ),
                  if (widget.task.taskStack > 0) ...[
                    const SizedBox(width: 12),
                    _buildWeeklyMetricChip(
                      icon: Icons.layers_rounded,
                      label: 'Stack',
                      value: '${widget.task.taskStack}',
                      color: Colors.blue,
                    ),
                  ],
                  if (widget.task.summary.bestTag != null &&
                      widget.task.summary.bestTag!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    _buildWeeklyMetricChip(
                      icon: Icons.local_offer_rounded,
                      label: 'Tag',
                      value: widget.task.summary.bestTag!,
                      color: colors.tertiary,
                      isWide: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colors.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Days Grid
            _buildDaysGrid(theme, colors, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(ThemeData theme, ColorScheme colors, bool isDark) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final scheduledDays = widget.task.scheduledDays;
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((day) {
            final isScheduled = scheduledDays.any(
              (d) =>
                  d.toLowerCase() == day.toLowerCase() ||
                  d.toLowerCase() == _getFullDayName(day).toLowerCase(),
            );
            final isToday = DateFormat('EEE').format(now) == day;

            // Check if completed
            final dayProgress = widget.task.dailyProgress.where((p) {
              return DateFormat('EEE').format(p.date) == day;
            }).toList();
            final isCompleted = dayProgress.any((p) => p.isComplete);
            final hasProgress = dayProgress.isNotEmpty;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: 300 + weekDays.indexOf(day) * 50,
                  ),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.center,
                    height: 56,
                    decoration: _getDayDecoration(
                      isScheduled: isScheduled,
                      isToday: isToday,
                      isCompleted: isCompleted,
                      hasProgress: hasProgress,
                      colors: colors,
                      isDark: isDark,
                    ),
                    child: _buildDayContent(
                      day: day,
                      isToday: isToday,
                      isCompleted: isCompleted,
                      hasProgress: hasProgress,
                      textColor: _getDayTextColor(
                        isScheduled: isScheduled,
                        isToday: isToday,
                        isCompleted: isCompleted,
                        hasProgress: hasProgress,
                        colors: colors,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getDayTextColor({
    required bool isScheduled,
    required bool isToday,
    required bool isCompleted,
    required bool hasProgress,
    required ColorScheme colors,
    required bool isDark,
  }) {
    if (isCompleted || hasProgress || (isToday && isScheduled)) {
      return Colors.white;
    } else if (isScheduled) {
      return colors.primary;
    }
    return isDark ? Colors.white38 : Colors.black38;
  }

  BoxDecoration _getDayDecoration({
    required bool isScheduled,
    required bool isToday,
    required bool isCompleted,
    required bool hasProgress,
    required ColorScheme colors,
    required bool isDark,
  }) {
    Color bgColor;
    Color borderColor;

    if (isCompleted) {
      bgColor = Colors.green;
      borderColor = Colors.green.shade300;
    } else if (hasProgress) {
      bgColor = colors.primary;
      borderColor = colors.primary.withOpacity(0.5);
    } else if (isToday && isScheduled) {
      bgColor = colors.secondary;
      borderColor = colors.secondary.withOpacity(0.5);
    } else if (isScheduled) {
      bgColor = colors.primary.withOpacity(0.15);
      borderColor = colors.primary.withOpacity(0.4);
    } else {
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.1);
      borderColor = isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.withOpacity(0.2);
    }

    return BoxDecoration(
      gradient: (isCompleted || hasProgress || (isToday && isScheduled))
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgColor, bgColor.withOpacity(0.8)],
            )
          : null,
      color: (isCompleted || hasProgress || (isToday && isScheduled))
          ? null
          : bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: (isCompleted || hasProgress || (isToday && isScheduled))
          ? [
              BoxShadow(
                color: bgColor.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );
  }

  Widget _buildDayContent({
    required String day,
    required bool isToday,
    required bool isCompleted,
    required bool hasProgress,
    required Color textColor,
  }) {
    IconData? icon;
    if (isCompleted) {
      icon = Icons.check_rounded;
    } else if (hasProgress) {
      icon = Icons.more_horiz_rounded;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          Icon(icon, color: textColor, size: 16)
        else
          Text(
            day[0],
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 2),
        if (isToday)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
      ],
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

  // ============================================
  // HELPER METHODS
  // ============================================

  bool _isTodayScheduled(String day) {
    final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    return day.toLowerCase() == today ||
        day.toLowerCase() == today.substring(0, 3);
  }

  String _getDayAbbreviation(String day) {
    return switch (day.toLowerCase()) {
      'monday' => 'Mon',
      'tuesday' => 'Tue',
      'wednesday' => 'Wed',
      'thursday' => 'Thu',
      'friday' => 'Fri',
      'saturday' => 'Sat',
      'sunday' => 'Sun',
      'mon' => 'Mon',
      'tue' => 'Tue',
      'wed' => 'Wed',
      'thu' => 'Thu',
      'fri' => 'Fri',
      'sat' => 'Sat',
      'sun' => 'Sun',
      _ => day.length >= 3 ? day.substring(0, 3).capitalize() : day,
    };
  }

  String _getFullDayName(String abbreviation) {
    return switch (abbreviation.toLowerCase()) {
      'mon' => 'monday',
      'tue' => 'tuesday',
      'wed' => 'wednesday',
      'thu' => 'thursday',
      'fri' => 'friday',
      'sat' => 'saturday',
      'sun' => 'sunday',
      _ => abbreviation,
    };
  }
}

// Extension for String capitalization
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

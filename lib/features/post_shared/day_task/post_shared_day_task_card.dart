// lib/features/post_shared/cards/day_task/post_shared_day_task_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../personal/task_model/day_tasks/models/day_task_model.dart';
import 'day_task_feedback_popup.dart';

/// Premium Post Shared Day Task Card with comprehensive information display
class PostSharedDayTaskCard extends StatefulWidget {
  final DayTaskModel task;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const PostSharedDayTaskCard({
    super.key,
    required this.task,
    this.margin,
    this.onTap,
  });

  @override
  State<PostSharedDayTaskCard> createState() => _PostSharedDayTaskCardState();
}

class _PostSharedDayTaskCardState extends State<PostSharedDayTaskCard>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _expandController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;
  List<Color>? _headerGradientColors;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  String _statusKey(String status) {
    return switch (status.toLowerCase()) {
      'completed' => 'completed',
      'inprogress' || 'in_progress' => 'inProgress',
      'pending' => 'pending',
      'postponed' => 'postponed',
      'upcoming' => 'upcoming',
      'missed' || 'failed' => 'missed',
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
      'postponed' || 'paused' => TaskStatus.postponed,
      'upcoming' => TaskStatus.upcoming,
      'missed' || 'overdue' => TaskStatus.missed,
      'failed' => TaskStatus.failed,
      'cancelled' => TaskStatus.cancelled,
      'skipped' => TaskStatus.skipped,
      _ => TaskStatus.unknown,
    };
  }

  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _showFeedbackPopup() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => DayTaskFeedbackPopup(task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    _headerGradientColors ??= CardColorHelper.getTaskCardGradient(
      priority: widget.task.indicators.priority,
      status: widget.task.indicators.status,
      progress: widget.task.metadata.progress,
      isDarkMode: theme.brightness == Brightness.dark,
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
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
                widget.onTap?.call();
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(theme, colors),
                    const SizedBox(height: 16),
                    _buildProgressSection(theme, colors),
                    _buildDescriptionSection(theme, colors),
                    _buildTimelineSection(theme, colors),
                    _buildFeedbackSection(theme, colors),
                    _buildActionButtons(theme, colors),
                  ],
                ),
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
                value: widget.task.indicators.priority,
                size: 36,
                showLabel: false,
                recordId: widget.task.id,
              ),
              const SizedBox(width: 12),
              // Priority Indicator
              TaskMetricIndicator(
                type: TaskMetricType.category,
                value: 'Day Task',
                size: 36,
                showLabel: false,
                recordId: widget.task.id,
              ),
              const Spacer(),

              // Category Icon
              const SizedBox(width: 8),
              // Expand Button
              IconButton(
                onPressed: _toggleExpand,
                icon: Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: colors.primary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category Tags
          _buildCategoryLabels(theme, colors),
          const SizedBox(height: 12),
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
          _buildQuickMetricsRow(theme, colors),
        ],
      ),
    );
  }

  Widget _buildCategoryLabels(ThemeData theme, ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
            color: CardColorHelper.getPriorityColor(
              widget.task.indicators.priority,
            ),
            theme: theme,
          ),
        if (widget.task.metadata.hasReward)
          _buildSmallLabel(
            label: widget.task.metadata.tagName,
            color: widget.task.metadata.tierColor,
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
              value: widget.task.metadata.progress,
              size: 40,
              showLabel: true,
              customLabel: 'Progress',
            ),
            // Points Earned
            if (widget.task.metadata.pointsEarned > 0)
              TaskMetricIndicator(
                type: TaskMetricType.pointsEarned,
                value: widget.task.metadata.pointsEarned,
                size: 32,
                showLabel: true,
              ),
            // Rating
            if (widget.task.metadata.rating > 0)
              TaskMetricIndicator(
                type: TaskMetricType.rating,
                value: widget.task.metadata.rating,
                size: 20,
                showLabel: true,
                customLabel: 'Rating',
              ),
            // Feedback Count
            if (widget.task.feedbackCount > 0)
              TaskMetricIndicator(
                type: TaskMetricType.feedbackCount,
                value: widget.task.feedbackCount,
                size: 28,
                showLabel: true,
              ),
            // Tag
            if (widget.task.metadata.tagName.isNotEmpty)
              TaskMetricIndicator(
                type: TaskMetricType.tag,
                value: [widget.task.metadata.tagName],
                size: 24,
                showLabel: true,
                customLabel: 'Tag',
              ),
            // Posted Indicator
            TaskMetricIndicator(
              type: TaskMetricType.posted,
              value: {'live': widget.task.socialInfo.posted?.live ?? false},
              size: 28,
              showLabel: true,
            ),
            // Overdue Indicator
            if (widget.task.isOverdue)
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
  // PROGRESS SECTION
  // ============================================

  Widget _buildProgressSection(ThemeData theme, ColorScheme colors) {
    final progress = widget.task.metadata.progress;
    final progressColor = CardColorHelper.getProgressColor(progress);

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
                    TaskMetricIndicator(
                      type: TaskMetricType.progress,
                      value: progress,
                      size: 48,
                      showLabel: false,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Progress',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.task.metadata.isComplete
                              ? 'Completed'
                              : 'In Progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.task.metadata.pointsEarned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: progressColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: progressColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.task.metadata.pointsEarned} pts',
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat(
                  theme: theme,
                  value: '${widget.task.feedbackCount}',
                  label: 'Feedbacks',
                  color: colors.primary,
                ),
                _buildProgressStat(
                  theme: theme,
                  value: '${widget.task.timelineHours}h',
                  label: 'Duration',
                  color: colors.secondary,
                ),
                if (widget.task.metadata.rating > 0)
                  _buildProgressStat(
                    theme: theme,
                    value: widget.task.metadata.rating.toStringAsFixed(1),
                    label: 'Rating',
                    color: colors.secondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat({
    required ThemeData theme,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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
  // DESCRIPTION SECTION
  // ============================================

  Widget _buildDescriptionSection(ThemeData theme, ColorScheme colors) {
    final hasDescription =
        widget.task.aboutTask.taskDescription?.isNotEmpty ?? false;

    if (!hasDescription) return const SizedBox.shrink();

    return SizeTransition(
      axisAlignment: -1.0,
      sizeFactor: _expandController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task.aboutTask.taskDescription!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TIMELINE SECTION
  // ============================================

  Widget _buildTimelineSection(ThemeData theme, ColorScheme colors) {
    final startTime = widget.task.timeline.startingTime;
    final endTime = widget.task.timeline.endingTime;
    final now = DateTime.now();
    final timeProgress = widget.task.timeline.timeProgress;
    final isActive = widget.task.timeline.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.secondary.withValues(alpha: 0.08),
              colors.secondary.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.timer_rounded : Icons.schedule_rounded,
                  color: colors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Slot',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.task.timeline.completionTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CardColorHelper.getStatusColor(
                        'completed',
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CardColorHelper.getStatusColor(
                          'completed',
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: CardColorHelper.getStatusColor('completed'),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: CardColorHelper.getStatusColor('completed'),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
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
                      '${timeProgress.toStringAsFixed(0)}%',
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
                    value: timeProgress / 100,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      widget.task.timeline.overdue
                          ? Theme.of(context).colorScheme.error
                          : colors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FEEDBACK SECTION
  // ============================================

  Widget _buildFeedbackSection(ThemeData theme, ColorScheme colors) {
    if (widget.task.feedback.comments.isEmpty) return const SizedBox.shrink();

    final lastComment = widget.task.feedback.comments.last;

    return SizeTransition(
      axisAlignment: -1.0,
      sizeFactor: _expandController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showFeedbackPopup,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latest Feedback',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.task.feedbackCount} total feedbacks',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (lastComment.text.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastComment.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastComment.hasMedia) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.image_rounded,
                            size: 14,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
          if (widget.task.feedbackCount > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showFeedbackPopup,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                label: const Text('View Feedback'),
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
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return switch (category.toLowerCase()) {
      'health' || 'fitness' => Icons.favorite_rounded,
      'work' || 'productivity' => Icons.work_rounded,
      'education' || 'learning' => Icons.school_rounded,
      'personal' => Icons.person_rounded,
      'home' => Icons.home_rounded,
      'social' => Icons.people_rounded,
      'creative' => Icons.palette_rounded,
      'finance' => Icons.attach_money_rounded,
      _ => Icons.task_alt_rounded,
    };
  }
}

// Extension for String capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

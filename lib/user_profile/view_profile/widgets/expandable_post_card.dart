import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../features/personal/bucket_model/models/bucket_model.dart';
import '../../../features/personal/task_model/day_tasks/models/day_task_model.dart';
import '../../../features/personal/task_model/long_goal/models/long_goal_model.dart';
import '../../../features/personal/task_model/week_task/models/week_task_model.dart';
import '../../../features/social/post/models/post_model.dart';
import '../../../features/personal/bucket_model/repositories/bucket_repository.dart';
import '../../../features/personal/task_model/day_tasks/repositories/day_task_repository.dart';
import '../../../features/personal/task_model/long_goal/repositories/long_goals_repository.dart';
import '../../../features/personal/task_model/week_task/repositories/week_task_repository.dart';
import '../../../../widgets/metric_indicators.dart';

class ExpandablePostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const ExpandablePostCard({super.key, required this.post, this.onTap});

  @override
  State<ExpandablePostCard> createState() => _ExpandablePostCardState();
}

class _ExpandablePostCardState extends State<ExpandablePostCard> {
  bool _isExpanded = false;
  Map<String, dynamic>? _resolvedData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resolveData();
  }

  Future<void> _resolveData() async {
    // If we already have snapshot data, use it immediately
    if (widget.post.sourceData != null && widget.post.sourceData!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedData = widget.post.sourceData;
        });
      }
      return;
    }

    // If no source ID, we can't do anything
    if (widget.post.sourceId == null || widget.post.sourceType == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final type = widget.post.sourceType!.toLowerCase();
      final id = widget.post.sourceId!;
      Map<String, dynamic>? data;

      if (type == 'day_task' || type == 'daytask') {
        final task = await DayTaskRepository().getTaskById(id);
        data = task?.toJson();
      } else if (type == 'bucket_model' || type == 'bucket') {
        final bucket = await BucketRepository().getBucket(id);
        data = bucket?.toJson();
      } else if (type == 'long_goal' || type == 'longgoal') {
        final goal = await LongGoalsRepository().getGoalById(id: id);
        data = goal?.toJson();
      } else if (type == 'week_task' || type == 'weekly_task') {
        final task = await WeekTaskRepository().getTaskById(id);
        data = task?.toJson();
      }

      if (mounted) {
        setState(() {
          _resolvedData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      logE('Error resolving live data for ExpandablePostCard', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // ================================================================
  // COLOR LOGIC - Enhanced to handle all types
  // ================================================================
  List<Color> _getGradient(BuildContext context) {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    try {
      if (sourceType == 'day_task') {
        final task = DayTaskModel.fromJson(data);
        return CardColorHelper.getTaskCardGradient(
          priority: task.indicators.priority,
          status: task.indicators.status,
          progress: task.metadata.progress.toInt(),
          isDarkMode: isDarkMode,
        );
      }

      if (sourceType == 'bucket_model') {
        final bucket = BucketModel.fromJson(data);
        final baseColor = CardColorHelper.getBucketColor(bucket.bucketId);
        return [baseColor, baseColor.withOpacity(0.8)];
      }

      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return CardColorHelper.getTaskCardGradient(
          priority: goal.indicators.priority,
          status: goal.indicators.status,
          progress: goal.analysis.averageProgress.round(),
          isDarkMode: isDarkMode,
        );
      }

      if (sourceType == 'week_task') {
        final task = WeekTaskModel.fromJson(data);
        return CardColorHelper.getTaskCardGradient(
          priority: task.indicators.priority,
          status: task.indicators.status,
          progress: task.summary.progress.toInt(),
          isDarkMode: isDarkMode,
        );
      }
    } catch (e) {
      logE('Error parsing model for color', error: e);
    }

    return [Colors.grey, Colors.blueGrey];
  }

  // ================================================================
  // DATA EXTRACTION - Enhanced with all fields
  // ================================================================

  /// Get category and subtype info
  Map<String, String?> _getCategoryInfo() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        final task = DayTaskModel.fromJson(data);
        return {'category': task.categoryType, 'subType': task.subTypes};
      }
      if (sourceType == 'bucket_model') {
        final bucket = BucketModel.fromJson(data);
        return {'category': bucket.categoryType, 'subType': bucket.subTypes};
      }
      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return {'category': goal.categoryType, 'subType': goal.subTypes};
      }
      if (sourceType == 'week_task') {
        final task = WeekTaskModel.fromJson(data);
        return {'category': task.categoryType, 'subType': task.subTypes};
      }
    } catch (e) {
      logE('Error getting category info', error: e);
    }

    return {'category': null, 'subType': null};
  }

  /// Get title
  String _getTitle() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        return DayTaskModel.fromJson(data).aboutTask.taskName;
      }
      if (sourceType == 'bucket_model') {
        return BucketModel.fromJson(data).title;
      }
      if (sourceType == 'long_goal') {
        return LongGoalModel.fromJson(data).title;
      }
      if (sourceType == 'week_task') {
        return WeekTaskModel.fromJson(data).aboutTask.taskName;
      }
    } catch (e) {
      logE('Error getting title', error: e);
    }

    return widget.post.content.text.isNotEmpty
        ? widget.post.content.text
        : 'Untitled Post';
  }

  /// Get description
  String? _getDescription() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        return DayTaskModel.fromJson(data).aboutTask.taskDescription;
      }
      if (sourceType == 'bucket_model') {
        return BucketModel.fromJson(data).details.description;
      }
      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return goal.description.need.isNotEmpty
            ? goal.description.need
            : goal.description.outcome;
      }
      if (sourceType == 'week_task') {
        return WeekTaskModel.fromJson(data).aboutTask.taskDescription;
      }
    } catch (e) {
      logE('Error getting description', error: e);
    }

    return widget.post.content.text;
  }

  /// Get timeline info
  Map<String, dynamic> _getTimelineInfo() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        final task = DayTaskModel.fromJson(data);
        return {
          'start': task.timeline.startingTime,
          'end': task.timeline.endingTime,
          'duration': task.timeline.duration,
          'isActive': task.isActive,
          'isOverdue': task.isOverdue,
        };
      }
      if (sourceType == 'bucket_model') {
        final bucket = BucketModel.fromJson(data);
        return {
          'start': bucket.timeline.startDate,
          'end': bucket.timeline.dueDate,
          'completed': bucket.timeline.completeDate,
          'isCompleted': bucket.isCompleted,
        };
      }
      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return {
          'start': goal.timeline.startDate,
          'end': goal.timeline.endDate,
          'isActive': goal.isActive,
          'isOverdue': goal.isOverdue,
        };
      }
      if (sourceType == 'week_task') {
        final task = WeekTaskModel.fromJson(data);
        return {
          'start': task.timeline.startingTime,
          'end': task.timeline.endingTime,
          'days': task.timeline.taskDays,
          'isActive': task.isActive,
          'isOverdue': task.isOverdue,
        };
      }
    } catch (e) {
      logE('Error getting timeline info', error: e);
    }

    return {};
  }

  /// Get status and priority
  Map<String, String> _getStatusInfo() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        final task = DayTaskModel.fromJson(data);
        return {
          'status': task.indicators.status,
          'priority': task.indicators.priority,
        };
      }
      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return {
          'status': goal.indicators.status,
          'priority': goal.indicators.priority,
        };
      }
      if (sourceType == 'week_task') {
        final task = WeekTaskModel.fromJson(data);
        return {
          'status': task.indicators.status,
          'priority': task.indicators.priority,
        };
      }
      if (sourceType == 'bucket_model') {
        final bucket = BucketModel.fromJson(data);
        return {
          'status': bucket.isCompleted ? 'completed' : 'in_progress',
          'priority': bucket.metadata.priority,
        };
      }
    } catch (e) {
      logE('Error getting status info', error: e);
    }

    return {'status': 'unknown', 'priority': 'medium'};
  }

  /// Get progress metrics
  Map<String, dynamic> _getProgressMetrics() {
    final data = _resolvedData ?? {};
    final sourceType = widget.post.sourceType;

    try {
      if (sourceType == 'day_task') {
        final task = DayTaskModel.fromJson(data);
        return {
          'progress': task.metadata.progress,
          'points': task.metadata.pointsEarned,
          'rating': task.metadata.rating,
        };
      }
      if (sourceType == 'bucket_model') {
        final bucket = BucketModel.fromJson(data);
        return {
          'progress': bucket.metadata.averageProgress,
          'points': bucket.metadata.totalPointsEarned,
          'rating': bucket.metadata.averageRating,
          'completed': bucket.checklist.where((c) => c.done).length,
          'total': bucket.checklist.length,
        };
      }
      if (sourceType == 'long_goal') {
        final goal = LongGoalModel.fromJson(data);
        return {
          'progress': goal.analysis.averageProgress.toInt(),
          'points': goal.analysis.pointsEarned,
          'rating': goal.analysis.averageRating,
          'completedWeeks': goal.completedWeeks,
          'totalWeeks': goal.totalWeeks,
        };
      }
      if (sourceType == 'week_task') {
        final task = WeekTaskModel.fromJson(data);
        return {
          'progress': task.summary.progress,
          'points': task.summary.pointsEarned,
          'rating': task.summary.rating,
          'completedDays': task.summary.completedDays,
          'totalDays': task.summary.totalScheduledDays,
        };
      }
    } catch (e) {
      logE('Error getting progress metrics', error: e);
    }

    return {'progress': 0, 'points': 0, 'rating': 0.0};
  }

  /// Navigate to userPostFeed with the post
  void _handleTap() {
    // Call custom onTap if provided
    widget.onTap?.call();

    // Navigate to feed
    if (mounted) {
      context.pushNamed(
        'userPostFeed',
        extra: {
          'userId': widget.post.userId,
          'initialIndex': 0,
          'preloadedPosts': [widget.post],
          'title': _getTitle(),
          'isLive': widget.post.isLive,
        },
      );
    }
  }

  // ================================================================
  // BUILD METHODS
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final gradientColors = _getGradient(context);

    if (_isLoading && _resolvedData == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSection(context, theme, textTheme, gradientColors),
                if (_isExpanded) _buildExpandedSection(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the top gradient section with main info
  Widget _buildTopSection(
    BuildContext context,
    ThemeData theme,
    TextTheme textTheme,
    List<Color> gradientColors,
  ) {
    final categoryInfo = _getCategoryInfo();
    final statusInfo = _getStatusInfo();
    final timelineInfo = _getTimelineInfo();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: _isExpanded
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            : BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Subtype Row
                    _buildCategoryRow(categoryInfo, textTheme),

                    // Title
                    Text(
                      _getTitle(),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Metric Indicators Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          TaskMetricIndicator(
                            type: TaskMetricType.category,
                            value: widget.post.sourceType?.replaceAll('_', ' '),
                            size: 24,
                            showLabel: false,
                          ),
                          const SizedBox(width: 8),
                          TaskMetricIndicator(
                            type: TaskMetricType.liveSnapshot,
                            value: widget.post.isLive,
                            size: 24,
                            showLabel: false,
                          ),
                          const SizedBox(width: 8),
                          TaskMetricIndicator(
                            type: TaskMetricType.status,
                            value: statusInfo['status'],
                            size: 24,
                            showLabel: false,
                          ),
                          const SizedBox(width: 8),
                          TaskMetricIndicator(
                            type: TaskMetricType.priority,
                            value: statusInfo['priority'],
                            size: 24,
                            showLabel: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Status & Priority Pills
                    _buildStatusPills(statusInfo, textTheme),

                    // Description (if exists)
                    if (_getDescription() != null &&
                        _getDescription()!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getDescription()!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: _isExpanded ? 10 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Timeline Info
                    if (timelineInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTimelineInfo(timelineInfo, textTheme),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Expand Toggle Button
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build category and subtype row
  Widget _buildCategoryRow(Map<String, String?> info, TextTheme textTheme) {
    final category = info['category'];
    final subType = info['subType'];

    if (category == null && subType == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (category != null && category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          if (category != null && subType != null && subType.isNotEmpty)
            const SizedBox(width: 8),
          if (subType != null && subType.isNotEmpty)
            Expanded(
              child: Text(
                subType,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Build status and priority pills
  Widget _buildStatusPills(Map<String, String> info, TextTheme textTheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildPill(
          info['status']!,
          CardColorHelper.getStatusColor(info['status']!),
          textTheme,
        ),
        _buildPill(
          info['priority']!,
          CardColorHelper.getPriorityColor(info['priority']!),
          textTheme,
        ),
      ],
    );
  }

  /// Build individual pill
  Widget _buildPill(String text, Color color, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Build timeline information
  Widget _buildTimelineInfo(Map<String, dynamic> info, TextTheme textTheme) {
    final List<Widget> widgets = [];

    if (info['start'] != null) {
      widgets.add(
        _buildTimelineItem(
          Icons.play_circle_outline,
          'Start: ${_formatDate(info['start'])}',
          textTheme,
        ),
      );
    }

    if (info['end'] != null) {
      widgets.add(
        _buildTimelineItem(
          Icons.flag_outlined,
          'End: ${_formatDate(info['end'])}',
          textTheme,
        ),
      );
    }

    if (info['days'] != null) {
      widgets.add(
        _buildTimelineItem(Icons.calendar_today, info['days'], textTheme),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 12, runSpacing: 4, children: widgets);
  }

  /// Build timeline item
  Widget _buildTimelineItem(IconData icon, String text, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Build expanded section with metrics and engagement
  Widget _buildExpandedSection(BuildContext context, ThemeData theme) {
    final metrics = _getProgressMetrics();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Metrics Section
          _buildMetricsSection(context, metrics),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Engagement Stats Section
          _buildEngagementSection(context),
        ],
      ),
    );
  }

  /// Build progress metrics section
  Widget _buildMetricsSection(
    BuildContext context,
    Map<String, dynamic> metrics,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Metrics',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMetric(
                context,
                'Progress',
                metrics['progress'] ?? 0,
                CardColorHelper.getProgressColor(
                  (metrics['progress'] ?? 0).toInt(),
                ),
                isPercentage: true,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Points',
                metrics['points'] ?? 0,
                Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Rating',
                (metrics['rating'] ?? 0.0).toDouble(),
                Colors.orange,
                maxValue: 5.0,
              ),
              if (metrics.containsKey('completed') &&
                  metrics.containsKey('total')) ...[
                const SizedBox(width: 16),
                _buildMetric(
                  context,
                  'Completed',
                  metrics['completed'] ?? 0,
                  Colors.green,
                  subtitle: '/ ${metrics['total']}',
                ),
              ],
              if (metrics.containsKey('completedWeeks')) ...[
                const SizedBox(width: 16),
                _buildMetric(
                  context,
                  'Weeks',
                  metrics['completedWeeks'] ?? 0,
                  Colors.purple,
                  subtitle: '/ ${metrics['totalWeeks']}',
                ),
              ],
              if (metrics.containsKey('completedDays')) ...[
                const SizedBox(width: 16),
                _buildMetric(
                  context,
                  'Days',
                  metrics['completedDays'] ?? 0,
                  Colors.cyan,
                  subtitle: '/ ${metrics['totalDays']}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build engagement stats section
  Widget _buildEngagementSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Stats',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildMetric(
                context,
                'Views',
                widget.post.metrics.views,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Impressions',
                widget.post.metrics.impressions,
                Colors.purple,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Likes',
                widget.post.metrics.likesCount,
                Colors.red,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Saves',
                widget.post.metrics.savesCount,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Shares',
                widget.post.metrics.sharesCount,
                Colors.teal,
              ),
              const SizedBox(width: 16),
              _buildMetric(
                context,
                'Comments',
                widget.post.metrics.commentsCount,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual metric with circular progress
  Widget _buildMetric(
    BuildContext context,
    String label,
    num value,
    Color color, {
    bool isPercentage = false,
    double maxValue = 100.0,
    String? subtitle,
  }) {
    final displayValue = value is double ? value : value.toInt();
    final progress = isPercentage
        ? (displayValue / maxValue).clamp(0.0, 1.0)
        : (value > 0 ? 1.0 : 0.0);

    String formattedValue;
    if (isPercentage) {
      formattedValue = '${displayValue.toInt()}%';
    } else if (value is double) {
      formattedValue = value.toStringAsFixed(1);
    } else {
      formattedValue = _formatNumber(value.toInt());
    }

    return Column(
      children: [
        AdvancedProgressIndicator(
          progress: progress,
          size: 50,
          strokeWidth: 4,
          shape: ProgressShape.circular,
          gradientColors: [color.withOpacity(0.5), color],
          backgroundColor: color.withOpacity(0.1),
          labelStyle: ProgressLabelStyle.custom,
          customLabel: formattedValue,
          labelTextStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          animated: true,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

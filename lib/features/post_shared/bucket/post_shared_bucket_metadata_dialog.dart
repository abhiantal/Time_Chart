// ============================================================================
// FILE: lib/features/post_shared/cards/bucket/post_shared_bucket_metadata_dialog.dart
// DETAILED ANALYTICS DIALOG — NO DUPLICATE DATA FROM MAIN CARD
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../personal/bucket_model/models/bucket_model.dart';

class SharedBucketMetadataDialog extends StatefulWidget {
  final BucketModel bucket;

  const SharedBucketMetadataDialog({super.key, required this.bucket});

  @override
  State<SharedBucketMetadataDialog> createState() =>
      _SharedBucketMetadataDialogState();
}

class _SharedBucketMetadataDialogState extends State<SharedBucketMetadataDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  BucketModel get bucket => widget.bucket;

  int get _completedTasks => bucket.checklist.where((i) => i.done).length;
  int get _totalTasks => bucket.checklist.length;
  double get _progressValue =>
      _totalTasks == 0 ? 0.0 : (_completedTasks / _totalTasks);

  bool get _isOverdue =>
      bucket.timeline.dueDate != null &&
      DateTime.now().isAfter(bucket.timeline.dueDate!) &&
      !bucket.isCompleted;

  TaskStatus get _taskStatus {
    if (bucket.isCompleted) return TaskStatus.completed;
    if (_isOverdue) return TaskStatus.missed;
    if (_progressValue > 0) return TaskStatus.inProgress;
    return TaskStatus.pending;
  }

  int get _feedbackCount =>
      bucket.checklist.where((i) => i.feedbacks.isNotEmpty).length;

  int get _mediaItemCount =>
      bucket.checklist.fold<int>(0, (sum, i) => sum + i.allMedia.length);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final gradient = bucket.getCardGradient(isDarkMode: isDark);
    final primary = gradient.first;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenW > 600 ? 520 : screenW * 0.93,
                  maxHeight: screenH * 0.85,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(isDark ? 0.95 : 0.98),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: primary.withOpacity(isDark ? 0.3 : 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(theme, isDark, gradient, primary),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        physics: const BouncingScrollPhysics(),
                        child: _buildContent(theme, isDark, primary),
                      ),
                    ),
                    _buildFooter(theme, primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HEADER — Quick context (not detailed duplication)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    List<Color> gradient,
    Color primary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Analytics',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bucket.title.isEmpty || bucket.title == 'null'
                          ? 'Untitled Bucket'
                          : bucket.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick status row in header
          Row(
            children: [
              TaskMetricIndicator(
                type: TaskMetricType.status,
                value: _taskStatus,
                size: 26,
                showLabel: true,
              ),
              const SizedBox(width: 12),
              TaskMetricIndicator(
                type: TaskMetricType.priority,
                value: bucket.metadata.priority,
                size: 26,
                showLabel: true,
                customLabel: '${bucket.metadata.priority} Priority',
              ),
              const SizedBox(width: 12),
              TaskMetricIndicator(
                type: TaskMetricType.category,
                value: bucket.categoryType ?? 'Bucket',
                size: 26,
                showLabel: true,
                customLabel: bucket.categoryType ?? 'Bucket',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // CONTENT — Only unique data NOT on main card
  // ══════════════════════════════════════════════════════════════════
  Widget _buildContent(ThemeData theme, bool isDark, Color primary) {
    final hasAnySections =
        bucket.metadata.summary != null ||
        bucket.checklist.isNotEmpty ||
        (bucket.metadata.rewardPackage?.tagName.isNotEmpty ?? false) ||
        (bucket.metadata.rewardPackage?.earned == true) ||
        bucket.socialInfo != null ||
        bucket.shareInfo != null ||
        bucket.details.mediaUrl.length > 1 ||
        bucket.details.motivation.isNotEmpty ||
        bucket.details.outCome.isNotEmpty;

    if (!hasAnySections) {
      return _buildEmptyState(theme, primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. PROGRESS BREAKDOWN (large visual)
        _buildProgressBreakdown(theme, primary),
        const SizedBox(height: 22),

        // 2. MOTIVATION (if exists)
        if (bucket.details.motivation.isNotEmpty) ...[
          _buildMotivationSection(theme, primary),
          const SizedBox(height: 22),
        ],

        // 3. EXPECTED OUTCOME (if exists)
        if (bucket.details.outCome.isNotEmpty) ...[
          _buildOutcomeSection(theme, primary),
          const SizedBox(height: 22),
        ],

        // 4. PERFORMANCE SUMMARY (not on main card)
        if (bucket.metadata.summary != null) ...[
          _buildPerformanceSummary(theme, primary),
          const SizedBox(height: 22),
        ],

        // 5. CHECKLIST DETAIL BREAKDOWN (full feedback + media per item)
        if (bucket.checklist.isNotEmpty) ...[
          _buildChecklistBreakdown(theme, isDark, primary),
          const SizedBox(height: 22),
        ],

        // 6. TIMELINE (detailed)
        _buildTimeline(theme, primary),
        const SizedBox(height: 22),

        // 8. TAGS & ACHIEVEMENTS (not on main card)
        if (bucket.metadata.rewardPackage?.tagName.isNotEmpty ?? false) ...[
          _buildTagsAchievements(theme, primary),
          const SizedBox(height: 22),
        ],

        // 9. REWARD DETAILS (not on main card)
        if (bucket.metadata.rewardPackage?.earned == true) ...[
          _buildRewardDetails(theme, primary),
          const SizedBox(height: 22),
        ],

        // 11. SOCIAL & SHARE (detailed info not on card)
        if (bucket.socialInfo != null || bucket.shareInfo != null) ...[
          _buildSocialShareDetails(theme, isDark, primary),
          const SizedBox(height: 22),
        ],

        // 12. MEDIA GALLERY (not on main card)
        if (bucket.details.mediaUrl.length > 1) ...[
          _buildMediaGallery(theme, primary),
          const SizedBox(height: 22),
        ],

        // 14. METADATA FOOTER
        _buildMetadataInfo(theme, primary),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: primary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No detailed data available yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 1. PROGRESS BREAKDOWN
  // ══════════════════════════════════════════════════════════════════
  Widget _buildProgressBreakdown(ThemeData theme, Color primary) {
    return _Section(
      theme: theme,
      primary: primary,
      icon: Icons.pie_chart_rounded,
      title: 'Progress Breakdown',
      child: Column(
        children: [
          // Large progress indicator
          Center(
            child: TaskMetricIndicator(
              type: TaskMetricType.progress,
              value: bucket.metadata.averageProgress,
              size: 80,
              showLabel: false,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.check_circle_rounded,
                    label: 'Done',
                    value: '$_completedTasks',
                    color: Colors.green,
                    theme: theme,
                  ),
                ),
                _vertDivider(theme),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.pending_rounded,
                    label: 'Left',
                    value: '${_totalTasks - _completedTasks}',
                    color: Colors.orange,
                    theme: theme,
                  ),
                ),
                _vertDivider(theme),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.list_rounded,
                    label: 'Total',
                    value: '$_totalTasks',
                    color: primary,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Indicators row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: TaskMetricIndicatorRow(
              spacing: 14,
              indicators: [
                TaskMetricIndicator(
                  type: TaskMetricType.efficiency,
                  value: _progressValue,
                  size: 34,
                  showLabel: true,
                  customLabel: '${(_progressValue * 100).toInt()}% Efficiency',
                ),
                if (bucket.metadata.averageRating > 0)
                  TaskMetricIndicator(
                    type: TaskMetricType.rating,
                    value: bucket.metadata.averageRating,
                    size: 18,
                    showLabel: true,
                    customLabel:
                        '${bucket.metadata.averageRating.toStringAsFixed(1)} Rating',
                  ),
                if (bucket.metadata.totalPointsEarned > 0)
                  TaskMetricIndicator(
                    type: TaskMetricType.pointsEarned,
                    value: bucket.metadata.totalPointsEarned.toDouble(),
                    size: 30,
                    showLabel: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 2. MOTIVATION
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMotivationSection(ThemeData theme, Color primary) {
    return _Section(
      theme: theme,
      primary: primary,
      icon: Icons.format_quote_rounded,
      title: 'Motivation',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: primary.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bucket.details.motivation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 3. EXPECTED OUTCOME
  // ══════════════════════════════════════════════════════════════════
  Widget _buildOutcomeSection(ThemeData theme, Color primary) {
    return _Section(
      theme: theme,
      primary: Colors.teal,
      icon: Icons.flag_rounded,
      title: 'Expected Outcome',
      child: Text(
        bucket.details.outCome,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.75),
          height: 1.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 4. PERFORMANCE SUMMARY
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPerformanceSummary(ThemeData theme, Color primary) {
    final summary = bucket.metadata.summary!;

    return _Section(
      theme: theme,
      primary: Colors.indigo,
      icon: Icons.insights_rounded,
      title: 'Performance Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.summary.isNotEmpty) ...[
            Text(
              summary.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (summary.suggestion.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.suggestion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (summary.plan.isNotEmpty) ...[
            Text(
              'Action Plan',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.plan.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 5. CHECKLIST DETAIL BREAKDOWN
  // ══════════════════════════════════════════════════════════════════
  Widget _buildChecklistBreakdown(ThemeData theme, bool isDark, Color primary) {
    return _Section(
      theme: theme,
      primary: primary,
      icon: Icons.fact_check_rounded,
      title: 'Checklist Details',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$_completedTasks/$_totalTasks',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
      child: Column(
        children: bucket.checklist.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final hasFeedback = item.feedbacks.isNotEmpty;
          final hasMedia = item.allMedia.isNotEmpty;

          return Container(
            margin: EdgeInsets.only(
              bottom: idx < bucket.checklist.length - 1 ? 10 : 0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.done
                  ? Colors.green.withOpacity(isDark ? 0.1 : 0.05)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.done
                    ? Colors.green.withOpacity(0.2)
                    : theme.dividerColor.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task row
                Row(
                  children: [
                    TaskMetricIndicator(
                      type: TaskMetricType.status,
                      value: item.done
                          ? TaskStatus.completed
                          : TaskStatus.pending,
                      size: 22,
                      showLabel: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.task,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: item.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.done
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.done
                              ? Colors.green.withOpacity(0.15)
                              : primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 12,
                              color: item.done ? Colors.green : primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '+${item.points}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.done ? Colors.green : primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Feedback
                if (hasFeedback) ...[
                  const SizedBox(height: 10),
                  ...item.feedbacks.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.65,
                                ),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ],

                // Bottom row: date + media
                if (item.date != null || hasMedia) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.date != null) ...[
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fmtDate(item.date!),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                      if (item.date != null && hasMedia)
                        const SizedBox(width: 12),
                      if (hasMedia)
                        TaskMetricIndicator(
                          type: TaskMetricType.mediaCount,
                          value: item.allMedia.length,
                          size: 20,
                          showLabel: true,
                          customLabel: '${item.allMedia.length} files',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 6. TIMELINE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTimeline(ThemeData theme, Color primary) {
    return _Section(
      theme: theme,
      primary: primary,
      icon: Icons.timeline_rounded,
      title: 'Timeline',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            _timeRow(
              theme,
              Icons.add_circle_outline_rounded,
              'Added',
              bucket.timeline.addedDate,
              Colors.blueGrey,
            ),
            if (bucket.timeline.startDate != null) ...[
              const SizedBox(height: 12),
              _timeRow(
                theme,
                Icons.play_arrow_rounded,
                'Started',
                bucket.timeline.startDate!,
                Colors.green,
                metricType: TaskMetricType.startingTime,
              ),
            ],
            if (bucket.timeline.dueDate != null) ...[
              const SizedBox(height: 12),
              _timeRow(
                theme,
                Icons.event_rounded,
                'Due Date',
                bucket.timeline.dueDate!,
                _isOverdue ? Colors.red : primary,
                metricType: TaskMetricType.deadline,
              ),
            ],
            if (bucket.timeline.completeDate != null) ...[
              const SizedBox(height: 12),
              _timeRow(
                theme,
                Icons.check_circle_rounded,
                'Completed',
                bucket.timeline.completeDate!,
                Colors.green,
                metricType: TaskMetricType.completionTime,
              ),
            ],
            if (bucket.timeline.startDate == null &&
                bucket.timeline.dueDate == null &&
                bucket.timeline.completeDate == null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No timeline specified',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeRow(
    ThemeData theme,
    IconData icon,
    String label,
    DateTime date,
    Color color, {
    TaskMetricType? metricType,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              Text(
                _fmtDateTime(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (metricType != null)
          TaskMetricIndicator(
            type: metricType,
            value: date,
            size: 26,
            showLabel: false,
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 7. FINAL FEEDBACK
  // ══════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════
  // 8. TAGS & ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTagsAchievements(ThemeData theme, Color primary) {
    final rw = bucket.metadata.rewardPackage!;

    return _Section(
      theme: theme,
      primary: Colors.amber,
      icon: Icons.workspace_premium_rounded,
      title: 'Tags & Achievements',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TaskMetricIndicator(
                  type: TaskMetricType.milestone,
                  value: true,
                  size: 30,
                  showLabel: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rw.tagName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Text(
                        'Tier: ${rw.tier.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rw.tagReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rw.tagReason,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 9. REWARD DETAILS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildRewardDetails(ThemeData theme, Color primary) {
    final rw = bucket.metadata.rewardPackage!;

    return _Section(
      theme: theme,
      primary: Colors.deepPurple,
      icon: Icons.diamond_rounded,
      title: 'Reward Details',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.1),
              Colors.pink.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            TaskMetricIndicator(
              type: TaskMetricType.reward,
              value: bucket.metadata.totalPointsEarned.toDouble(),
              size: 30,
              showLabel: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rw.rewardDisplayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tier: ${rw.tier.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.deepPurple.shade300,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (rw.suggestion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      rw.suggestion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 10. PENALTY DETAILS
  // ══════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════
  // 11. SOCIAL & SHARE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSocialShareDetails(ThemeData theme, bool isDark, Color primary) {
    return _Section(
      theme: theme,
      primary: primary,
      icon: Icons.share_rounded,
      title: 'Social & Sharing',
      child: Column(
        children: [
          if (bucket.socialInfo != null)
            _socialRow(
              theme: theme,
              indicator: TaskMetricIndicator(
                type: TaskMetricType.posted,
                value: {'live': bucket.socialInfo?.posted?.live ?? false},
                size: 28,
                showLabel: false,
              ),
              title: bucket.socialInfo!.isPosted ? 'Posted' : 'Not Posted',
              subtitle: bucket.socialInfo?.posted?.live == true
                  ? 'Currently live'
                  : bucket.socialInfo!.isPosted
                  ? 'Posted as snapshot • ID: ${bucket.socialInfo?.posted?.postId ?? 'N/A'}'
                  : 'Not posted yet',
              time: bucket.socialInfo?.posted?.time,
            ),
          if (bucket.socialInfo != null && bucket.shareInfo != null)
            Divider(height: 24, color: theme.dividerColor.withOpacity(0.1)),
          if (bucket.shareInfo != null)
            _socialRow(
              theme: theme,
              indicator: TaskMetricIndicator(
                type: TaskMetricType.shared,
                value: {'live': bucket.shareInfo?.shareId?.live ?? false},
                size: 28,
                showLabel: false,
              ),
              title: bucket.shareInfo!.isShare ? 'Shared' : 'Not Shared',
              subtitle: bucket.shareInfo?.shareId?.live == true
                  ? 'Live sharing active'
                  : bucket.shareInfo!.isShare
                  ? 'Shared as snapshot'
                  : 'Not shared yet',
              time: bucket.shareInfo?.shareId?.time,
            ),
        ],
      ),
    );
  }

  Widget _socialRow({
    required ThemeData theme,
    required Widget indicator,
    required String title,
    required String subtitle,
    DateTime? time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        indicator,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 4),
                Text(
                  _fmtDateTime(time),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 12. MEDIA GALLERY
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMediaGallery(ThemeData theme, Color primary) {
    return _Section(
      theme: theme,
      primary: Colors.purple,
      icon: Icons.photo_library_rounded,
      title: 'Media (${bucket.details.mediaUrl.length})',
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: bucket.details.mediaUrl.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: FutureBuilder<String?>(
                  future: UniversalMediaService().getValidSignedUrl(
                    bucket.details.mediaUrl[i],
                  ),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary.withOpacity(0.5),
                          ),
                        ),
                      );
                    }
                    final url = snap.data ?? bucket.details.mediaUrl[i];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 28,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 13. MOTIVATIONAL QUOTE
  // ══════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════
  // 14. METADATA INFO
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMetadataInfo(ThemeData theme, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _metaRow(
            theme,
            Icons.create_rounded,
            'Created: ${_fmtDateTime(bucket.createdAt)}',
          ),
          const SizedBox(height: 6),
          _metaRow(
            theme,
            Icons.update_rounded,
            'Updated: ${_fmtDateTime(bucket.updatedAt)}',
          ),
          if (bucket.id.isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(
              theme,
              Icons.fingerprint_rounded,
              'ID: ${bucket.id}',
              mono: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(
    ThemeData theme,
    IconData icon,
    String text, {
    bool mono = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: mono ? 10 : 11,
              fontFamily: mono ? 'monospace' : null,
              color: theme.colorScheme.onSurface.withOpacity(mono ? 0.35 : 0.5),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // FOOTER
  // ══════════════════════════════════════════════════════════════════
  Widget _buildFooter(ThemeData theme, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════
  Widget _vertDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.dividerColor.withOpacity(0.15),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  String _fmtDateTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} • $h:${d.minute.toString().padLeft(2, '0')} $p';
  }
}

// ══════════════════════════════════════════════════════════════════════
// REUSABLE SECTION WIDGET
// ══════════════════════════════════════════════════════════════════════
class _Section extends StatelessWidget {
  final ThemeData theme;
  final Color primary;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.theme,
    required this.primary,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// MINI STAT
// ══════════════════════════════════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

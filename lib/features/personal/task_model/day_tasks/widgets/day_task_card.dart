// lib/features/day_task/message_bubbles/day_task_card.dart

import 'package:flutter/material.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../../../../../media_utility/media_display.dart';
import '../../../../../../widgets/metric_indicators.dart';
import '../../../../../../widgets/logger.dart';
import '../models/day_task_model.dart';
import 'task_options_menu.dart' hide BorderRadius;

class DayTaskCard extends StatelessWidget {
  final DayTaskModel task;
  final bool isExpanded;
  final VoidCallback onToggle;

  const DayTaskCard({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isCompleted = task.metadata.isComplete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ TOP PART - Gradient Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: task.getCardGradient(
                        isDarkMode: theme.brightness == Brightness.dark,
                      ),
                    ),
                    borderRadius: isExpanded
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          )
                        : BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Task Title Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.aboutTask.taskName,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (task.aboutTask.taskDescription != null &&
                                    task
                                        .aboutTask
                                        .taskDescription!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    task.aboutTask.taskDescription!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    maxLines: isExpanded ? 10 : 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: GestureDetector(
                                  onTapDown: (details) => showTaskOptionsMenu(
                                    context,
                                    task,
                                    position: details.globalPosition,
                                  ),
                                  child: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onToggle,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isExpanded
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

                      const SizedBox(height: 16),

                      // ✅ Metric Indicators Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            TaskMetricIndicator(
                              type: TaskMetricType.status,
                              value: task.calculateStatus(),
                              size: 28,
                              animate: false,
                              adaptToTheme: false,
                            ),
                            const SizedBox(width: 8),
                            TaskMetricIndicator(
                              type: TaskMetricType.priority,
                              value: task.indicators.priority,
                              size: 28,
                              animate: false,
                              adaptToTheme: false,
                            ),
                            const SizedBox(width: 8),
                            if (task.socialInfo.isPosted) ...[
                              TaskMetricIndicator(
                                type: TaskMetricType.posted,
                                value: task.socialInfo.isPosted,
                                size: 28,
                                animate: false,
                                adaptToTheme: false,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (task.shareInfo.isShare) ...[
                              TaskMetricIndicator(
                                type: TaskMetricType.shared,
                                value: task.shareInfo.isShare,
                                size: 28,
                                animate: false,
                                adaptToTheme: false,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (task.feedback.comments.isNotEmpty) ...[
                              TaskMetricIndicator(
                                type: TaskMetricType.feedbackCount,
                                value: task.feedback.comments.length,
                                size: 28,
                                animate: false,
                                adaptToTheme: false,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (task.metadata.pointsEarned > 0) ...[
                              TaskMetricIndicator(
                                type: TaskMetricType.pointsEarned,
                                value: task.metadata.pointsEarned,
                                size: 28,
                                animate: false,
                                adaptToTheme: false,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (task.timeline.overdue)
                              TaskMetricIndicator(
                                type: TaskMetricType.overdue,
                                value: true,
                                size: 28,
                                animate: false,
                                adaptToTheme: false,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (task.metadata.rating > 0) ...[
                        TaskMetricIndicator(
                          type: TaskMetricType.rating,
                          value: task.metadata.rating,
                          size: 28,
                          animate: true,
                          adaptToTheme: false,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),

                // ✅ BOTTOM PART - Expanded Content
                if (isExpanded) ...[
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.feedback.comments.isEmpty) ...[
                          _buildSectionTitle(
                            context,
                            icon: Icons.feedback_outlined,
                            title: 'No feedback yet',
                            useThemeColor: true,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hourglass_bottom_rounded,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Add media updates every 20 minutes. Final text at end time.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (task.feedback.comments.isNotEmpty) ...[
                          _buildSectionTitle(
                            context,
                            icon: Icons.comment_rounded,
                            title:
                                'Feedback (${task.feedback.comments.length})',
                            useThemeColor: true,
                          ),
                          const SizedBox(height: 12),
                          ..._buildAggregatedFeedback(context, task),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HELPER WIDGETS
  // ================================================================

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool useThemeColor = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final iconColor = useThemeColor ? colorScheme.primary : Colors.white;
    final textColor = useThemeColor ? colorScheme.onSurface : Colors.white;
    final bgColor = useThemeColor
        ? colorScheme.primaryContainer
        : Colors.white.withValues(alpha: 0.2);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackItem(BuildContext context, Comment comment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // ✅ Parse comma-separated media URLs
    final mediaFiles = _parseMediaUrls(comment.mediaUrl);

    final hasText = comment.text.trim().isNotEmpty;
    final hasMedia = mediaFiles.isNotEmpty;

    final gridColumns = mediaFiles.isEmpty
        ? 1
        : mediaFiles.length == 1
        ? 1
        : mediaFiles.length == 2
        ? 2
        : 3;

    if (!hasText && !hasMedia) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasText)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.comment,
                    color: colorScheme.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasMedia)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: EnhancedMediaDisplay(
              mediaFiles: mediaFiles,
              config: MediaDisplayConfig(
                layoutMode: MediaLayoutMode.grid,
                gridColumns: gridColumns,
                mediaBucket: MediaBucket.dailyTaskMedia,
                allowDelete: false,
                allowFullScreen: true,
                showFileName: false,
                showFileSize: false,
                showDate: false,
                spacing: 8,
                borderRadius: 10,
                imageFit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildAggregatedFeedback(
    BuildContext context,
    DayTaskModel task,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final textComments = task.feedback.comments
        .where((c) => c.text.trim().isNotEmpty)
        .toList();

    final allMedia = <EnhancedMediaFile>[];
    for (final c in task.feedback.comments) {
      allMedia.addAll(_parseMediaUrls(c.mediaUrl));
    }

    final widgets = <Widget>[];

    if (textComments.isNotEmpty) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: textComments.map((comment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        comment.text,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (allMedia.isNotEmpty) {
      final gridColumns = allMedia.length == 1
          ? 1
          : allMedia.length == 2
          ? 2
          : 3;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: EnhancedMediaDisplay(
            mediaFiles: allMedia,
            config: MediaDisplayConfig(
              layoutMode: MediaLayoutMode.grid,
              gridColumns: gridColumns,
              mediaBucket: MediaBucket.dailyTaskMedia,
              allowDelete: false,
              allowFullScreen: true,
              showFileName: false,
              showFileSize: false,
              showDate: false,
              spacing: 8,
              borderRadius: 10,
              imageFit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Helper: Parse comma-separated media URLs into EnhancedMediaFile list
  List<EnhancedMediaFile> _parseMediaUrls(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      return [];
    }

    try {
      // Split by comma and clean up whitespace
      final urls = mediaUrl
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      return urls.asMap().entries.map((entry) {
        return EnhancedMediaFile.fromUrl(
          id: 'feedback_media_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          url: entry.value,
        );
      }).toList();
    } catch (e) {
      logE('Error parsing media URLs', error: e);
      return [];
    }
  }
}

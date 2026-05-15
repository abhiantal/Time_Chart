// lib/features/personal/post_shared/task_model/week_task/message_bubbles/grid_task_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/features/personal/category_model/models/category_model.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../../../../../../helpers/card_color_helper.dart';
import '../../../../../../widgets/bar_progress_indicator.dart';
import '../../../../../../widgets/metric_indicators.dart';

import '../models/week_task_model.dart';
import 'weekly_task_options_menu.dart';

class GridTaskCard extends StatelessWidget {
  final WeekTaskModel task;

  final Category? category;
  final DateTime? date;

  const GridTaskCard({super.key, required this.task, this.category, this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Fetch Day Progress if date is provided
    final dayProgress = date != null ? task.getProgressForDate(date!) : null;

    // 2. Derive Metrics: Use day-specific metrics if date is provided, fallback to weekly summary ONLY if date is null
    final metrics = date != null
        ? (dayProgress?.dailyMetrics ?? DayMetrics.empty)
        : DayMetrics(
            progress: task.summary.progress,
            pointsEarned: task.summary.pointsEarned,
            rating: task.summary.rating,
            isComplete: task.indicators.status == 'completed',
            rewardPackage: task.calculateRewardPackage(),
          );

    // 3. Determine Status and Gradient Colors
    final String displayPriority =
        dayProgress != null ? 'medium' : task.indicators.priority;
    final String displayStatus;

    if (date != null) {
      // For a specific day, status depends on day completion
      displayStatus =
          metrics.isComplete
              ? 'completed'
              : (metrics.progress > 0 ? 'inProgress' : 'pending');
    } else {
      // For general view, use task global status
      displayStatus = task.indicators.status;
    }

    final gradientColors = CardColorHelper.getTaskCardGradient(
      priority: displayPriority,
      status: displayStatus,
      progress: metrics.progress,
      isDarkMode: isDark,
    );

    final hasMedia =
        task.aboutTask.mediaUrl != null && task.aboutTask.mediaUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showOptionsMenu(context);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _showOptionsMenu(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ROW 1: Icon/Media + Task Title + Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMedia) _buildCompactMedia() else _buildCompactIcon(),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.aboutTask.taskName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (metrics.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              metrics.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Reward/Penalty Badge
                if (metrics.rewardPackage?.earned == true)
                  const Text('ðŸŽ', style: TextStyle(fontSize: 12))
                else if (metrics.penalty != null)
                  const Text('âš ï¸', style: TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 4),

            // ROW 2: Task Description (Compact)
            Text(
              task.aboutTask.taskDescription ?? 'Weekly Task',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 8.5,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // ROW 3: Indicators & Category
            Row(
              children: [
                TaskMetricIndicator(
                  type: TaskMetricType.status,
                  value:
                      dayProgress != null
                          ? (metrics.isComplete ? 'completed' : 'inProgress')
                          : task.indicators.status,
                  size: 14,
                  showLabel: false,
                ),
                const SizedBox(width: 4),
                if (metrics.pointsEarned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 9,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${metrics.pointsEarned}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.categoryType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ROW 4: Custom Progress Bar
            CustomProgressIndicator(
              progress: metrics.progress / 100,
              orientation: ProgressOrientation.horizontal,
              baseHeight: 4,
              maxHeightIncrease: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              progressColor: Colors.white.withValues(alpha: 0.9),
              borderRadius: 3,
              progressBarName: '',
              nameLabelPosition: LabelPosition.center,
              progressLabelDisplay: ProgressLabelDisplay.none,
              animated: true,
              animationDuration: const Duration(milliseconds: 600),
              animationCurve: Curves.easeInOut,
            ),

            const SizedBox(height: 3),

            // ROW 5: Progress percentage and streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${metrics.progress}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (task.taskStack > 0)
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 9),
                      const SizedBox(width: 1),
                      Text(
                        '${task.taskStack}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show options menu on card tap
  void _showOptionsMenu(BuildContext context) {
    WeeklyTaskOptionsMenu.show(
      context: context,
      task: task,
      selectedDate: date,
    );
  }

  /// Compact Media (28x28)
  Widget _buildCompactMedia() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        color: Colors.white.withValues(alpha: 0.15),
        child: EnhancedMediaDisplay(
          mediaFiles: [
            EnhancedMediaFile.fromUrl(
              id: 'grid_task_media_${task.id}',
              url: task.aboutTask.mediaUrl!,
            ),
          ],
          config: MediaDisplayConfig(
            layoutMode: MediaLayoutMode.single,
            mediaBucket: MediaBucket.weeklyTaskMedia,
            allowFullScreen: true,
            showFileName: false,
            showFileSize: false,
            showDate: false,
            allowDelete: false,
            imageFit: BoxFit.cover,
            borderRadius: 6,
            enableAnimations: false,
            showDetails: false,
          ),
        ),
      ),
    );
  }

  /// Compact Icon (28x28)
  Widget _buildCompactIcon() {
    final icon = category?.icon ?? _getFallbackIconEmoji();

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(child: _buildIconContent(icon)),
    );
  }

  /// Icon Content
  Widget _buildIconContent(String icon) {
    if (icon.length <= 4 && _isEmoji(icon)) {
      return Text(icon, style: const TextStyle(fontSize: 16));
    }

    return Icon(_getFallbackIcon(), color: Colors.white, size: 16);
  }

  /// Check if emoji
  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    final runes = text.runes.toList();
    return runes.any(
      (rune) =>
          (rune >= 0x1F300 && rune <= 0x1F9FF) ||
          (rune >= 0x2600 && rune <= 0x26FF) ||
          (rune >= 0x2700 && rune <= 0x27BF),
    );
  }

  /// Fallback emoji
  String _getFallbackIconEmoji() {
    switch (task.categoryType.toLowerCase()) {
      case 'health':
      case 'fitness':
        return 'ðŸ’ª';
      case 'work':
      case 'career':
        return 'ðŸ’¼';
      case 'education':
      case 'learning':
        return 'ðŸ“š';
      case 'personal':
        return 'ðŸ‘¤';
      case 'finance':
        return 'ðŸ’°';
      case 'social':
        return 'ðŸ‘¥';
      case 'hobby':
        return 'ðŸŽ¨';
      default:
        return 'ðŸ“‹';
    }
  }

  /// Fallback Material icon
  IconData _getFallbackIcon() {
    switch (task.categoryType.toLowerCase()) {
      case 'health':
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'work':
      case 'career':
        return Icons.work_rounded;
      case 'education':
      case 'learning':
        return Icons.school_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'finance':
        return Icons.attach_money_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'hobby':
        return Icons.palette_rounded;
      default:
        return Icons.calendar_view_week_rounded;
    }
  }
}

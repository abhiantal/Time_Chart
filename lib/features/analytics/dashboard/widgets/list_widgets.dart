// ================================================================
// FILE: lib/features/personal/dashboard/widgets/list_widgets.dart
// LIST ITEMS & TIMELINE WIDGETS
// ================================================================

import 'package:flutter/material.dart';
import '../../../../helpers/card_color_helper.dart';
import 'shared_widgets.dart';
import '../../../../widgets/bar_progress_indicator.dart';

// ================================================================
// 1. GENERIC STAT LIST ITEM
// ================================================================

/// Generic list item for statistics display
class StatListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final String? subtitle;
  final double? progress;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const StatListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.subtitle,
    this.progress,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: theme.textTheme.labelLarge,
          ),
          subtitle: subtitle != null
              ? Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          )
              : null,
          trailing: trailing ??
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
          onTap: onTap,
        ),
        if (progress != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: CustomProgressIndicator(
              progress: (progress! / 100).clamp(0, 1),
              progressBarName: '',
              baseHeight: 4,
              maxHeightIncrease: 0,
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              progressColor: iconColor,
              gradientColors: [
                iconColor,
                iconColor.withValues(alpha: 0.7),
              ],
              borderRadius: 2,
              progressLabelDisplay: ProgressLabelDisplay.none,
              animated: true,
            ),
          ),
        ],
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

// ================================================================
// 2. TASK COMPACT CARD
// ================================================================

/// Compact card for displaying a task/goal
class TaskCompactCard extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String? category;
  final int points;
  final int progress;
  final String? priority;
  final String? reward;
  final bool hasPenalty;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool isDarkMode;
  final bool showBackground;
  final String? summary;

  const TaskCompactCard({
    super.key,
    required this.id,
    required this.title,
    required this.status,
    this.category,
    this.points = 0,
    this.progress = 0,
    this.priority,
    this.reward,
    this.hasPenalty = false,
    this.onTap,
    this.onEdit,
    required this.isDarkMode,
    this.showBackground = true,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = CardColorHelper.getTaskCardGradient(
      priority: priority,
      status: status,
      progress: progress,
      isDarkMode: isDarkMode,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (summary != null && summary!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        summary!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(status: status),
                      const SizedBox(width: 6),
                      if (priority != null)
                        PriorityBadge(priority: priority!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PointsBadge(points: points),
                if (reward != null) ...[
                  const SizedBox(height: 4),
                  RewardBadge(tier: reward!, emoji: '🏆'),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomProgressIndicator(
          progress: (progress / 100).clamp(0, 1),
          baseHeight: 8,
          maxHeightIncrease: 0,
          backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          gradientColors: [
            Color(0xFFeab308),
            Color(0xFF43e97b),
          ],
          borderRadius: 2,
          progressBarName: '',
          progressLabelDisplay: ProgressLabelDisplay.none,
          animated: true,
        ),
        const SizedBox(height: 8),
        if (hasPenalty)
          Row(
            children: [
              Icon(Icons.warning_rounded,
                  size: 14,
                  color: theme.colorScheme.error),
              const SizedBox(width: 4),
              Text(
                'Penalty Applied',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );

    if (!showBackground) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    return GradientCard(
      colors: colors,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: content,
    );
  }
}

// ================================================================
// 3. ACTIVITY TIMELINE ITEM
// ================================================================

/// Timeline item for activity feed
class ActivityTimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final int? points;
  final bool isMilestone;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const ActivityTimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    this.points,
    this.isMilestone = false,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          SizedBox(
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  Positioned(
                    top: 50,
                    child: Container(
                      width: 2,
                      height: 40,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isMilestone
                        ? iconColor.withValues(alpha: 0.2)
                        : iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isMilestone
                        ? Border.all(color: iconColor, width: 2)
                        : null,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (points != null && points! > 0) ...[
                        const SizedBox(width: 8),
                        PointsBadge(points: points!, animate: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ================================================================
// 5. REWARD ITEM
// ================================================================

/// Display item for earned rewards
class RewardListItem extends StatelessWidget {
  final String tier;
  final String? emoji;
  final String? tagName;
  final String? taskName;
  final int points;
  final String earnedFrom;
  final String timeAgo;
  final Color? tierColor;
  final VoidCallback? onTap;
  final bool showBackground;

  const RewardListItem({
    super.key,
    required this.tier,
    this.emoji,
    this.tagName,
    this.taskName,
    required this.points,
    required this.earnedFrom,
    required this.timeAgo,
    this.tierColor,
    this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tierColor ?? CardColorHelper.getTierColor(tier);

    final content = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(emoji ?? '🏆', style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tagName ?? tier,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$earnedFrom • $timeAgo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (taskName != null) ...[
                const SizedBox(height: 2),
                Text(
                  taskName!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PointsBadge(points: points, animate: false),
          ],
        ),
      ],
    );

    if (!showBackground) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    return GradientCard(
      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: content,
    );
  }
}

// ================================================================
// 6. MOOD HISTORY ITEM
// ================================================================

/// Timeline item for mood history
class MoodHistoryItem extends StatelessWidget {
  final DateTime date;
  final double moodRating;
  final String? moodLabel;
  final String? entry;
  final int? wordCount;
  final VoidCallback? onTap;
  final bool showBackground;

  const MoodHistoryItem({
    super.key,
    required this.date,
    required this.moodRating,
    this.moodLabel,
    this.entry,
    this.wordCount,
    this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodEmoji = _getMoodEmoji(moodRating);
    final moodColor = CardColorHelper.moodColorForValue(moodRating);

    final content = Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: moodColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(moodEmoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    moodLabel ?? 'Mood Entry',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${moodRating.toStringAsFixed(1)}/10',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: moodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(date),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (entry != null && entry!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (wordCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$wordCount words',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!showBackground) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      );
    }

    return GradientCard(
      colors: [moodColor.withValues(alpha: 0.1), moodColor.withValues(alpha: 0.05)],
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: content,
    );
  }

  String _getMoodEmoji(double rating) {
    if (rating >= 9) return '😄';
    if (rating >= 7) return '😊';
    if (rating >= 5) return '😐';
    if (rating >= 3) return '😔';
    return '😢';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ================================================================
// 7. STREAK MILESTONE ITEM
// ================================================================

/// Display item for streak milestones
class StreakMilestoneItem extends StatelessWidget {
  final int days;
  final bool achieved;
  final String? emoji;
  final Color? color;
  final VoidCallback? onTap;
  final bool showBackground;

  const StreakMilestoneItem({
    super.key,
    required this.days,
    required this.achieved,
    this.emoji,
    this.color,
    this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemColor = color ??
        (achieved ? const Color(0xFF43E97B) : const Color(0xFFCFD8DC));

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: achieved
                      ? Border.all(color: itemColor, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(emoji ?? '🎯',
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$days days',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      achieved ? 'ACHIEVED' : 'LOCKED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: itemColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (achieved)
          Icon(Icons.check_circle_rounded, color: itemColor, size: 20),
      ],
    );

    if (!showBackground) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return GradientCard(
      colors: [
        itemColor.withValues(alpha: achieved ? 0.15 : 0.08),
        itemColor.withValues(alpha: achieved ? 0.05 : 0.02),
      ],
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: content,
    );
  }
}
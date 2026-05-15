// ================================================================
// FILE: lib/features/personal/dashboard/widgets/mood_streak_activity_widgets.dart
// MOOD, STREAKS & ACTIVITY WIDGETS
// ── NEW additions at bottom: MoodAverageCircles, MoodFrequencyBars,
//    MoodSummaryStrip, ActivityFilterBar, ActivityHeroStats
// ================================================================

import 'package:flutter/material.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../models/dashboard_model.dart';
import 'shared_widgets.dart';
import 'list_widgets.dart';

import '../../../../helpers/card_color_helper.dart';

// ================================================================
// EXISTING: MoodFrequencyChart  (pie — kept for backward compat)
// ================================================================

class MoodFrequencyChart extends StatelessWidget {
  final Map<String, int> moodFrequency;
  final bool showBackground;
  final bool showShadow;

  const MoodFrequencyChart({
    super.key,
    required this.moodFrequency,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (moodFrequency.isEmpty) {
      return GradientCard(
        colors: [theme.colorScheme.surface, theme.colorScheme.surface],
        child: SizedBox(
          height: 200,
          child: EmptyStateWidget(
            icon: Icons.pie_chart_rounded,
            title: 'No Data',
            subtitle: 'Log your mood to see distribution',
          ),
        ),
      );
    }
    // Delegate to bar version for consistency
    return MoodFrequencyBars(
      moodFrequency: moodFrequency,
      showBackground: showBackground,
      showShadow: showShadow,
    );
  }
}

// ================================================================
// EXISTING: CurrentStreakRing
// ================================================================

class CurrentStreakRing extends StatelessWidget {
  final int currentDays;
  final bool isActive;
  final String emoji;
  final bool showBackground;
  final bool showShadow;
  final String? title;
  final String? subtitle;
  final String? label;
  final String? value;
  final String? description;
  final double? progress;
  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final Color? iconBgColor;
  final StreakNextMilestone? nextMilestone;
  final VoidCallback? onViewAll;

  const CurrentStreakRing({
    super.key,
    required this.currentDays,
    required this.isActive,
    this.emoji = '🔥',
    this.showBackground = true,
    this.showShadow = true,
    this.nextMilestone,
    this.onViewAll,
    this.title,
    this.subtitle,
    this.label,
    this.value,
    this.description,
    this.progress,
    this.icon,
    this.color,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor =
        color ?? (isActive ? const Color(0xFFEF4444) : const Color(0xFFCFD8DC));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: (iconBgColor ??
                        displayColor.withOpacity(0.15))
                    ,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon ?? Icons.local_fire_department_rounded,
                    color: iconColor ?? displayColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title ?? 'Streaks',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle ?? 'Consistency tracking',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10)),
              ]),
            ]),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View All',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: theme.colorScheme.primary),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        StyledDivider(height: 0.5),
        const SizedBox(height: 12),
        Center(
          child: AdvancedProgressIndicator(
            progress:
            progress ?? (currentDays / 30).clamp(0.0, 1.0),
            size: 120,
            strokeWidth: 10,
            gradientColors: [displayColor, displayColor.withOpacity(0.6)],
            labelStyle: ProgressLabelStyle.custom,
            customLabel: value ?? currentDays.toString(),
            labelTextStyle: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, color: displayColor),
            name: label ?? 'days',
            nameTextStyle: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            showGlow: isActive,
            glowRadius: 10,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            description ??
                (isActive ? 'Keep it up! 🔥' : 'Start a new streak today!'),
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (!showBackground) return content;
    return GradientCard(
      colors: [theme.colorScheme.surface, theme.colorScheme.surface],
      showShadow: showShadow,
      padding: const EdgeInsets.all(16),
      onTap: onViewAll,
      child: content,
    );
  }
}

// ================================================================
// EXISTING: LongestStreakCard
// ================================================================

class LongestStreakCard extends StatelessWidget {
  final int longestDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showBackground;
  final bool showShadow;

  const LongestStreakCard({
    super.key,
    required this.longestDays,
    this.startDate,
    this.endDate,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF10B981);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🏆 Longest Streak',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(longestDays.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Text('days',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
        if (startDate != null && endDate != null) ...[
          const SizedBox(height: 8),
          StyledDivider(height: 0.5),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DateCol(label: 'Started', date: startDate!, theme: theme),
              _DateCol(label: 'Ended', date: endDate!, theme: theme),
            ],
          ),
        ],
      ],
    );

    if (!showBackground) return content;
    return GradientCard(
      colors: [
        color.withOpacity(0.15),
        color.withOpacity(0.05),
      ],
      showShadow: showShadow,
      child: content,
    );
  }
}

class _DateCol extends StatelessWidget {
  final String label;
  final DateTime date;
  final ThemeData theme;
  const _DateCol(
      {required this.label, required this.date, required this.theme});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6))),
      Text('${date.day}/${date.month}/${date.year}',
          style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ],
  );
}

// ================================================================
// EXISTING: StreakMilestonesGrid
// ================================================================

class StreakMilestonesGrid extends StatelessWidget {
  final List<int> milestones;
  final int currentStreak;

  const StreakMilestonesGrid(
      {super.key, required this.milestones, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final achieved = currentStreak >= milestone;
        return StreakMilestoneItem(
          days: milestone,
          achieved: achieved,
          emoji: _milestoneEmoji(milestone),
          color: achieved
              ? const Color(0xFF10B981)
              : const Color(0xFFCFD8DC),
          showBackground: false,
        );
      },
    );
  }

  String _milestoneEmoji(int d) {
    if (d == 3) return '🌱';
    if (d == 7) return '🌿';
    if (d == 14) return '🌳';
    if (d == 21) return '🏔️';
    if (d == 30) return '⛰️';
    if (d == 60) return '🗻';
    if (d == 90) return '🚀';
    if (d == 180) return '🌍';
    if (d == 365) return '🌟';
    return '🎯';
  }
}

// ================================================================
// EXISTING: ActivityFeedSection
// ================================================================

class ActivityFeedSection extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final Function(String)? onActivityTap;
  final VoidCallback? onViewAll;

  const ActivityFeedSection({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyStateWidget(
          icon: Icons.history_rounded,
          title: 'No Activity',
          subtitle: 'Your activity will appear here',
        ),
      );
    }

    final grouped = ActivityGroup.groupByDate(activities);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final group = grouped[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
              child: StyledDivider(label: group.label),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.items.length,
              itemBuilder: (context, i) {
                final activity = group.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivityTimelineItem(
                    title: activity.message,
                    subtitle: activity.action,
                    timestamp: activity.timeAgo,
                    icon: activity.actionIcon,
                    iconColor: activity.actionColor,
                    points: activity.points,
                    isMilestone: activity.isMilestone,
                    isLast: i == group.items.length - 1,
                    onTap: () => onActivityTap?.call(activity.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// EXISTING: ActivityStatisticsCard
// ================================================================

class ActivityStatisticsCard extends StatelessWidget {
  final int totalActivities;
  final int totalMilestones;
  final String mostCommonAction;
  final int totalPoints;
  final bool showBackground;
  final bool showShadow;

  const ActivityStatisticsCard({
    super.key,
    required this.totalActivities,
    required this.totalMilestones,
    required this.mostCommonAction,
    required this.totalPoints,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final boxes = [
      _AStatBox(
          label: 'Total Activities',
          value: totalActivities.toString(),
          icon: Icons.history_rounded,
          color: const Color(0xFF3B82F6),
          showBackground: showBackground,
          showShadow: showShadow),
      _AStatBox(
          label: 'Milestones',
          value: totalMilestones.toString(),
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFFFA500),
          showBackground: showBackground,
          showShadow: showShadow),
      _AStatBox(
          label: 'Most Common',
          value: mostCommonAction.replaceAll('_', ' '),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
          showBackground: showBackground,
          showShadow: showShadow),
      _AStatBox(
          label: 'Total Points',
          value: totalPoints.toString(),
          icon: Icons.star_rounded,
          color: const Color(0xFFFFD700),
          showBackground: showBackground,
          showShadow: showShadow),
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊 Activity Statistics',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StyledDivider(height: 0.5),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: boxes,
        ),
      ],
    );

    if (!showBackground) return content;
    return GradientCard(
      colors: [
        const Color(0xFF8B5CF6).withOpacity(0.15),
        const Color(0xFF8B5CF6).withOpacity(0.05),
      ],
      showShadow: showShadow,
      child: content,
    );
  }
}

class _AStatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool showBackground, showShadow;

  const _AStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.showBackground,
    required this.showShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(showBackground ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: (showBackground && showShadow)
            ? Border.all(color: color.withOpacity(0.2))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ],
      ),
    );
  }
}

// ================================================================
// ── NEW SHARED WIDGETS ──────────────────────────────────────────
// ================================================================

// ================================================================
// NEW: MoodAverageCircles
// Used by MoodDetailScreen to display 7d / 30d averages
// as AdvancedProgressIndicator circular rings
// ================================================================

class MoodAverageCircles extends StatelessWidget {
  final double avg7d;
  final double avg30d;
  final String trend;
  final ThemeData theme;
  final bool isDark;

  const MoodAverageCircles({
    super.key,
    required this.avg7d,
    required this.avg30d,
    required this.trend,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color7 = CardColorHelper.moodColorForValue(avg7d);
    final color30 = CardColorHelper.moodColorForValue(avg30d);
    final trendUp = trend.toLowerCase() == 'improving';
    final trendDown = trend.toLowerCase() == 'declining';
    final trendColor = trendUp
        ? const Color(0xFF10B981)
        : trendDown
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);
    final trendIcon = trendUp
        ? Icons.trending_up_rounded
        : trendDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // 7-day avg circle
          Expanded(
            child: Column(
              children: [
                AdvancedProgressIndicator(
                  progress: (avg7d / 10).clamp(0.0, 1.0),
                  size: 96,
                  strokeWidth: 9,
                  shape: ProgressShape.circular,
                  gradientColors: [color7, color7.withOpacity(0.5)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200,
                  labelStyle: ProgressLabelStyle.custom,
                  customLabel: avg7d.toStringAsFixed(1),
                  labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: color7),
                  showGlow: true,
                  glowRadius: 6,
                  animationDuration: const Duration(milliseconds: 1400),
                ),
                const SizedBox(height: 6),
                Text(_moodEmoji(avg7d),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 3),
                Text('7-Day Average',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Divider + trend
          Column(
            children: [
              Container(
                  width: 1,
                  height: 60,
                  color: theme.colorScheme.outline.withOpacity(0.15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Icon(trendIcon, color: trendColor, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                trend.isEmpty ? 'Stable' : _capitalize(trend),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: trendColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                  width: 1,
                  height: 30,
                  color: theme.colorScheme.outline.withOpacity(0.15)),
            ],
          ),
          // 30-day avg circle
          Expanded(
            child: Column(
              children: [
                AdvancedProgressIndicator(
                  progress: (avg30d / 10).clamp(0.0, 1.0),
                  size: 96,
                  strokeWidth: 9,
                  shape: ProgressShape.circular,
                  gradientColors: [color30, color30.withOpacity(0.5)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200,
                  labelStyle: ProgressLabelStyle.custom,
                  customLabel: avg30d.toStringAsFixed(1),
                  labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: color30),
                  showGlow: true,
                  glowRadius: 6,
                  animationDuration: const Duration(milliseconds: 1600),
                ),
                const SizedBox(height: 6),
                Text(_moodEmoji(avg30d),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 3),
                Text('30-Day Average',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _moodEmoji(double v) {
    if (v >= 9) return '🤩';
    if (v >= 7.5) return '😄';
    if (v >= 6) return '😊';
    if (v >= 4.5) return '😐';
    if (v >= 3) return '😔';
    return '😢';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ================================================================
// NEW: MoodFrequencyBars
// Used by MoodDetailScreen — CustomProgressIndicator bars
// ================================================================

class MoodFrequencyBars extends StatelessWidget {
  final Map<String, int> moodFrequency;
  final bool showBackground;
  final bool showShadow;

  const MoodFrequencyBars({
    super.key,
    required this.moodFrequency,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (moodFrequency.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.bar_chart_rounded,
        title: 'No Mood Data',
        subtitle: 'Start logging your mood to see distribution',
      );
    }

    final total =
    moodFrequency.values.fold<int>(0, (s, v) => s + v);
    final sorted = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final moodColors = <String, Color>{
      'great': const Color(0xFF43E97B),
      'good': const Color(0xFF10B981),
      'okay': const Color(0xFFFFD54F),
      'bad': const Color(0xFFFFA726),
      'terrible': const Color(0xFFEF4444),
    };
    final moodEmojis = <String, String>{
      'great': '🤩',
      'good': '😊',
      'okay': '😐',
      'bad': '😔',
      'terrible': '😢',
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('📊', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text('Mood Distribution',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$total entries',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ]),
        const SizedBox(height: 16),
        ...sorted.map((entry) {
          final color = moodColors[entry.key.toLowerCase()] ??
              const Color(0xFF94A3B8);
          final emoji = moodEmojis[entry.key.toLowerCase()] ?? '😐';
          final fraction = total > 0 ? entry.value / total : 0.0;
          final pct = (fraction * 100).toStringAsFixed(0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text(emoji,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        _capitalize(entry.key),
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    Row(children: [
                      Text('x${entry.value}',
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: color)),
                      const SizedBox(width: 6),
                      Text('($pct%)',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4))),
                    ]),
                  ],
                ),
                const SizedBox(height: 6),
                CustomProgressIndicator(
                  progress: fraction.clamp(0.0, 1.0),
                  progressBarName: '',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 10,
                  maxHeightIncrease: 3,
                  gradientColors: [color, color.withOpacity(0.55)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: 8,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  animateNameLabel: false,
                  animationDuration:
                  const Duration(milliseconds: 1200),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          );
        }),
      ],
    );

    if (!showBackground) return content;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: content,
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ================================================================
// NEW: MoodSummaryStrip
// Quick headline strip: total entries, highest, lowest, most common
// ================================================================

class MoodSummaryStrip extends StatelessWidget {
  final Mood mood;
  final ThemeData theme;
  final bool isDark;

  const MoodSummaryStrip({
    super.key,
    required this.mood,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalEntries = mood.moodHistory.length;
    final highs = mood.moodHistory.isEmpty
        ? 0.0
        : mood.moodHistory.map((e) => e.value).reduce(
            (a, b) => a > b ? a : b);
    final lows = mood.moodHistory.isEmpty
        ? 0.0
        : mood.moodHistory
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    // Most common mood label
    String mostCommon = '-';
    if (mood.moodFrequency.isNotEmpty) {
      final top = mood.moodFrequency.entries.reduce(
              (a, b) => a.value > b.value ? a : b);
      mostCommon = _capitalize(top.key);
    }

    final tiles = [
      _MSTile(
          emoji: '📝',
          value: totalEntries.toString(),
          label: 'Entries',
          color: const Color(0xFF667EEA)),
      _MSTile(
          emoji: '🤩',
          value: highs.toStringAsFixed(1),
          label: 'Highest',
          color: const Color(0xFF10B981)),
      _MSTile(
          emoji: '😢',
          value: lows.toStringAsFixed(1),
          label: 'Lowest',
          color: const Color(0xFFEF4444)),
      _MSTile(
          emoji: '😊',
          value: mostCommon,
          label: 'Most Common',
          color: const Color(0xFFF59E0B)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: tiles.map((t) {
          return Expanded(
            child: Column(children: [
              Text(t.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text(t.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: t.color)),
              Text(t.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontSize: 9)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _MSTile {
  final String emoji, value, label;
  final Color color;
  const _MSTile(
      {required this.emoji,
        required this.value,
        required this.label,
        required this.color});
}

// ================================================================
// NEW: ActivityFilterBar  (used by RecentActivityDetailScreen)
// ================================================================

class ActivityFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const ActivityFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filters = [
      ('all', 'All', Icons.apps_rounded),
      ('task_completed', 'Completed', Icons.check_circle_outline_rounded),
      ('reward_earned', 'Rewards', Icons.emoji_events_outlined),
      ('milestone', 'Milestones', Icons.flag_outlined),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          final color = theme.colorScheme.primary;
          return GestureDetector(
            onTap: () => onChanged(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : isDark
                    ? color.withOpacity(0.1)
                    : color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? color
                        : color.withOpacity(0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(f.$3,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 5),
                Text(f.$2,
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.65))),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// NEW: ActivityHeroStats  (used by RecentActivityDetailScreen)
// Uses AdvancedProgressIndicator arcs for milestones
// ================================================================

class ActivityHeroStats extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final ThemeData theme;
  final bool isDark;

  const ActivityHeroStats({
    super.key,
    required this.activities,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = activities.length;
    final milestones =
        activities.where((a) => a.isMilestone).length;
    final totalPoints =
    activities.fold<int>(0, (s, a) => s + a.points);
    final completed = activities
        .where((a) => a.action == 'task_completed')
        .length;
    final rewards = activities
        .where((a) => a.action == 'reward_earned')
        .length;

    final milestoneFraction =
    total > 0 ? milestones / total : 0.0;
    final completedFraction =
    total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Top row: two arcs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ArcStat(
                progress: completedFraction,
                label: 'Completed',
                value: completed.toString(),
                total: total,
                gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                theme: theme,
                isDark: isDark,
              ),
              _ArcStat(
                progress: milestoneFraction,
                label: 'Milestones',
                value: milestones.toString(),
                total: total,
                gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Bottom: three stat pills
          Row(children: [
            Expanded(
                child: _APill(
                    label: 'Total',
                    value: total.toString(),
                    color: const Color(0xFF3B82F6),
                    icon: Icons.history_rounded,
                    theme: theme,
                    isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _APill(
                    label: 'Points',
                    value: totalPoints.toString(),
                    color: const Color(0xFFFFD700),
                    icon: Icons.star_rounded,
                    theme: theme,
                    isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _APill(
                    label: 'Rewards',
                    value: rewards.toString(),
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.emoji_events_rounded,
                    theme: theme,
                    isDark: isDark)),
          ]),
        ],
      ),
    );
  }
}

class _ArcStat extends StatelessWidget {
  final double progress;
  final String label, value;
  final int total;
  final List<Color> gradient;
  final ThemeData theme;
  final bool isDark;

  const _ArcStat({
    required this.progress,
    required this.label,
    required this.value,
    required this.total,
    required this.gradient,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdvancedProgressIndicator(
          progress: progress.clamp(0.0, 1.0),
          size: 90,
          strokeWidth: 9,
          shape: ProgressShape.arc,
          arcStartAngle: 180,
          arcSweepAngle: 180,
          gradientColors: gradient,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.shade200,
          labelStyle: ProgressLabelStyle.custom,
          customLabel: value,
          labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900, color: gradient.first),
          animationDuration: const Duration(milliseconds: 1400),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
                fontWeight: FontWeight.w600)),
        Text(
          total > 0
              ? '${(progress * 100).toStringAsFixed(0)}% of $total'
              : '-',
          style: theme.textTheme.labelSmall?.copyWith(
              color: gradient.first.withOpacity(0.7), fontSize: 9),
        ),
      ],
    );
  }
}

class _APill extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  final bool isDark;

  const _APill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 9)),
        ]),
      ]),
    );
  }
}

// ================================================================
// NEW: MoodRatingScaleBar  (full 1-10 scale, arc per rating bucket)
// ================================================================

class MoodRatingScaleBar extends StatelessWidget {
  final List<MoodDataPoint> history;
  final ThemeData theme;
  final bool isDark;

  const MoodRatingScaleBar({
    super.key,
    required this.history,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Bucket into 1-10 ranges
    final counts = <int, int>{};
    for (int i = 1; i <= 10; i++) {
      counts[i] = history.where((e) => e.value.round() == i).length;
    }
    final maxCount =
    counts.values.fold<int>(1, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text('Rating Distribution (1–10)',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(10, (i) {
              final rating = i + 1;
              final count = counts[rating] ?? 0;
              final frac = maxCount > 0 ? count / maxCount : 0.0;
              final color = CardColorHelper.moodColorForValue(
                  rating.toDouble());
              return Expanded(
                child: Column(
                  children: [
                    if (count > 0)
                      Text(count.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    const SizedBox(height: 3),
                    Container(
                      height: 60 * frac + 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color, color.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$rating',
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.5))),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
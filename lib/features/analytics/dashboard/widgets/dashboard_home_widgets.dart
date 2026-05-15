// ================================================================
// FILE: lib/features/personal/dashboard/widgets/dashboard_home_widgets.dart
// HOME SCREEN SPECIFIC WIDGETS - Dashboard Overview Cards
// ================================================================

import 'package:flutter/material.dart';
import '../../../../helpers/card_color_helper.dart';
import '../models/dashboard_model.dart';
import 'shared_widgets.dart';
import '../../../../widgets/bar_progress_indicator.dart';

// ================================================================
// 1. DASHBOARD HEADER CARD
// ================================================================

/// Main header card showing global rank, streak, and key metrics
class DashboardHeaderCard extends StatelessWidget {
  final DashboardSummary summary;
  final Mood mood;
  final String lastUpdated;
  final VoidCallback? onRefresh;
  final VoidCallback? onTap;
  final bool showShadow;

  const DashboardHeaderCard({
    super.key,
    required this.summary,
    required this.mood,
    required this.lastUpdated,
    this.onRefresh,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GradientCard(
      colors: isDark
          ? [
              colorScheme.primary.withValues(alpha: 0.15),
              colorScheme.primary.withValues(alpha: 0.05),
            ]
          : [Colors.white, Colors.white],
      showShadow: showShadow,
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Welcome + Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last updated: $lastUpdated',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Highlight Section: Points Today & Global Rank
          Row(
            children: [
              Expanded(
                child: _MainMetricCard(
                  label: "Today's Points",
                  value: summary.pointsToday.toString(),
                  subtitle: "Keep it up!",
                  icon: Icons.stars_rounded,
                  color: const Color(0xFFFFB84D),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MainMetricCard(
                  label: "Global Rank",
                  value: '#${summary.globalRank}',
                  subtitle: "Top ${summary.completionRateAll.toInt()}%",
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 12),

          // Secondary Stats Grid (Scrollable Row)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _StatCard(
                  label: "Today's Completion",
                  value: '${summary.completionRateToday.toInt()}%',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Current Streak',
                  value: '${summary.currentStreak}d',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Total Rewards',
                  value: summary.totalRewards.toString(),
                  icon: Icons.card_giftcard_rounded,
                  color: const Color(0xFFEC4899),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Average Progress',
                  value: '${summary.averageProgress}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF06B6D4),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Points This Week',
                  value: summary.pointsThisWeek.toString(),
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Best Tier',
                  value: _formatTier(summary.bestTierAchieved),
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Average Rating',
                  value: summary.averageRating.toStringAsFixed(1),
                  icon: Icons.star_outline_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Current Mood',
                  value: mood.todayMood?.label ?? 'N/A',
                  icon: mood.todayMood?.emoji == '😐'
                      ? Icons.face_rounded
                      : null,
                  emoji: mood.todayMood?.emoji,
                  color: mood.todayMood?.color ?? const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTier(String tier) {
    if (tier == 'none') return 'None';
    return tier.substring(0, 1).toUpperCase() + tier.substring(1).toLowerCase();
  }
}

/// A larger card for the most important metrics
class _MainMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MainMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? emoji;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color.withValues(alpha: 0.1);

    return Container(
      width: 120, // slightly wider for full labels
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 16))
                : Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 2. BEST TIER ACHIEVED CARD
// ================================================================

/// Display card for best reward tier achieved
class BestTierAchievedCard extends StatelessWidget {
  final String bestTier;
  final int totalRewards;
  final int totalPoints;
  final VoidCallback? onTap;

  final bool showShadow;

  const BestTierAchievedCard({
    super.key,
    required this.bestTier,
    required this.totalRewards,
    required this.totalPoints,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = CardColorHelper.getTierColor(bestTier);
    final tierEmoji = _getTierEmoji(bestTier);

    return GradientCard(
      colors: [
        tierColor.withValues(alpha: 0.2),
        tierColor.withValues(alpha: 0.05),
      ],
      onTap: onTap,
      showShadow: showShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏆 Best Tier Achieved',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(tierEmoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bestTier.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: tierColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Rewards',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    totalRewards.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reward Points',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    totalPoints.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTierEmoji(String tier) {
    switch (tier.toLowerCase()) {
      case 'nova':
        return '⭐';
      case 'radiant':
        return '👑';
      case 'prism':
        return '🔮';
      case 'crystal':
        return '💎';
      case 'blaze':
        return '⚡';
      case 'ember':
        return '🌿';
      case 'flame':
        return '🔥';
      case 'spark':
        return '✨';
      default:
        return '🏆';
    }
  }
}

// ================================================================
// 5. SECTION PREVIEW CARD
// ================================================================

class SectionPreviewCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final VoidCallback onViewAll;
  final VoidCallback? onTap;
  final int itemCount;
  final bool showBackground;
  final bool showShadow;

  const SectionPreviewCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.onViewAll,
    this.onTap,
    this.itemCount = 0,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (itemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  itemCount.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        StyledDivider(height: 0.5),
        const SizedBox(height: 12),
        child,
        if (onTap == null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View All'),
            ),
          ),
        ],
      ],
    );

    if (!showBackground) {
      return Padding(padding: const EdgeInsets.all(16), child: content);
    }

    return GradientCard(
      colors: [theme.colorScheme.surface, theme.colorScheme.surface],
      onTap: onTap,
      showShadow: showShadow,
      child: content,
    );
  }
}

// ================================================================
// 6. RECENT ACTIVITY PREVIEW
// ================================================================

/// Preview of recent activities on home screen
class RecentActivityPreview extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final VoidCallback onViewAll;

  const RecentActivityPreview({
    super.key,
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return GradientCard(
      colors: [theme.colorScheme.surface, theme.colorScheme.surface],

      padding: const EdgeInsets.all(16),
      onTap: onViewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF06B6D4),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Your achievements',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.take(3).length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityPreviewItem(activity: activity),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityPreviewItem extends StatelessWidget {
  final RecentActivityItem activity;

  const _ActivityPreviewItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: activity.actionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: activity.actionColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              activity.actionIcon,
              size: 14,
              color: activity.actionColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (activity.hasPoints) ...[
            const SizedBox(width: 8),
            Text(
              activity.pointsLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFFFA500),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// 7. MOTIVATIONAL BANNER
// ================================================================

/// Motivational banner at top of home screen
class MotivationalBanner extends StatelessWidget {
  final String userName;
  final int currentStreak;
  final String nextMilestone;

  const MotivationalBanner({
    super.key,
    required this.userName,
    required this.currentStreak,
    required this.nextMilestone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientCard(
      colors: [
        const Color(0xFF667EEA).withValues(alpha: 0.15),
        const Color(0xFF764BA2).withValues(alpha: 0.05),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Keep it up, $userName!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re on a $currentStreak day streak!\nNext milestone: $nextMilestone days',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('🚀', style: const TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

// ================================================================
// 7. PROGRESS HISTORY PREVIEW (REDESIGNED)
// ================================================================

class ProgressHistoryPreview extends StatelessWidget {
  final ProgressHistory history;
  final VoidCallback? onViewAll;

  const ProgressHistoryPreview({
    super.key,
    required this.history,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientCard(
      colors: [theme.colorScheme.surface, theme.colorScheme.surface],

      padding: const EdgeInsets.all(16),
      onTap: onViewAll,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: history.trendIconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: history.trendIconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '30-Day Progress',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Performance trend',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${history.averageProgress.toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: history.trendIconColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: history.trendIconColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                history.trendIcon,
                                size: 14,
                                color: history.trendIconColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                history.trend.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: history.trendIconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            // child: BarChartWidget(
            //   title: '',
            //   labels: recentStats.map((s) => s.shortDate).toList(),
            //   values: recentStats.map((s) => s.points.toDouble()).toList(),
            //   barColor: history.trendIconColor,
            //   showBackground: false,
            //   showShadow: false,
            //   height: 100,
            // ),
          ),
        ],
      ),
    );
  }
}

extension ProgressHistoryExtension on ProgressHistory {
  IconData get trendIcon {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color get trendIconColor {
    switch (trend.toLowerCase()) {
      case 'improving':
        return const Color(0xFF10B981);
      case 'declining':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

// ================================================================
// 8. WEEKLY OVERVIEW PREVIEW (REDESIGNED)
// ================================================================

class WeeklyOverviewPreview extends StatelessWidget {
  final WeeklyHistory history;
  final VoidCallback? onViewAll;

  const WeeklyOverviewPreview({
    super.key,
    required this.history,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = history.weekOverWeekChange;
    final isPositive = change >= 0;
    final changeColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return GradientCard(
      colors: [theme.colorScheme.surface, theme.colorScheme.surface],

      padding: const EdgeInsets.all(16),
      onTap: onViewAll,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_view_week_rounded,
                      color: Color(0xFF3B82F6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Overview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Last 4 weeks',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CompactWeekBox(
                label: 'This Week',
                value: history.currentWeekPoints.toString(),
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _CompactWeekBox(
                label: 'Last Week',
                value: history.lastWeekPoints.toString(),
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Change',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: changeColor,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            // child: BarChartWidget(
            //   title: '',
            //   labels: recentWeeks.map((s) => s.shortDate).toList(),
            //   values: recentWeeks.map((s) => s.points.toDouble()).toList(),
            //   barColor: changeColor,
            //   showBackground: false,
            //   showShadow: false,
            //   height: 100,
            // ),
          ),
        ],
      ),
    );
  }
}

class _CompactWeekBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactWeekBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

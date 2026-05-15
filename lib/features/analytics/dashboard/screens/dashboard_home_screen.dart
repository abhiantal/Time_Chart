// ================================================================
// FILE: dashboard_home_screen.dart
// MAIN DASHBOARD HOME SCREEN — Full redesign
// All 10 nav routes have matching preview cards:
//   overview, today, active_items, progress_history,
//   weekly_history, category_stats, rewards, mood,
//   streaks, recent_activity
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';
import '../../../../widgets/feature_info_widgets.dart';

// ── Progress widgets ─────────────────────────────────────────────
import '../../../../core/Mode/Mode_bottom_sheet.dart';
import '../../../../widgets/bar_progress_indicator.dart';
// ── Productivity clock ────────────────────────────────────────────
import '../widgets/productivity_clock.dart';

// ── Dashboard widgets ─────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/streak_mood_widgets.dart';
import '../utils/skeleton_widgets.dart';
import '../models/dashboard_model.dart';
import '../../../../helpers/card_color_helper.dart';

// ── Screen imports (navigation unchanged) ────────────────────────
import 'active_items_detail_screen.dart';
import 'category_stats_detail_screen.dart';
import 'mood_detail_screen.dart';
import 'overview_detail_screen.dart';
import 'recent_activity_detail_screen.dart';
import 'rewards_detail_screen.dart';
import 'progress_history_detail_screen.dart';
import 'streaks_detail_screen.dart';
import 'today_detail_screen.dart';
import 'weekly_history_detail_screen.dart';

// ================================================================
// SCREEN
// ================================================================

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<UserDashboardProvider>();
      final userId = auth.currentUser?.id;
      if (userId != null && !provider.isInitialised) {
        provider.initialize(userId);
      }
      _headerCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Consumer<UserDashboardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && !provider.hasData) {
              return const FullDashboardSkeleton();
            }
            if (provider.error != null && !provider.hasData) {
              return ErrorStateWidget(
                message: provider.error!,
                onRetry: () => provider.refreshDashboard(provider.userId),
              );
            }
            if (!provider.hasData) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FeatureInfoCard(feature: EliteFeatures.dashboard),
                ),
              );
            }

            final dashboard = provider.userDashboard!;
            final summary = dashboard.overview.summary;
            final today = dashboard.today;
            final streaks = dashboard.streaks;
            final mood = dashboard.mood;
            // Build clock segments from today's tasks
            final taskSegments = _buildTaskSegments(today);
            final dailyProgress = today.summary.totalScheduledTask > 0
                ? (today.summary.completed / today.summary.totalScheduledTask)
                      .clamp(0.0, 1.0)
                : 0.0;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── APP BAR ───────────────────────────────────────
                SliverAppBar(
                  centerTitle: false,
                  pinned: true,
                  floating: true,
                  elevation: 0,
                  backgroundColor: theme.colorScheme.surface,
                  title: Text(
                    'Dashboard',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => FeatureInfoCard.showEliteDialog(
                        context,
                        EliteFeatures.dashboard,
                      ),
                      icon: Icon(
                        Icons.help_outline_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 22,
                      ),
                      tooltip: 'How It Works',
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Customize App',
                      onPressed: () {
                        ModeBottomSheet.show(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () =>
                          provider.refreshDashboard(provider.userId),
                    ),
                  ],
                ),

                // ── 1. HERO HEADER (overview) ─────────────────────
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: _SectionWrapper(
                        topPad: 8,
                        child: _DHeroHeader(
                          summary: summary,
                          mood: mood,
                          isDark: isDark,
                          theme: theme,
                          lastUpdated: provider.lastUpdatedLabel,
                          onTap: () => _nav(context, 'overview'),
                          onRefresh: () =>
                              provider.refreshDashboard(provider.userId),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 2. MOTIVATIONAL BANNER ────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _MotivationalBanner(
                      streaks: streaks,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ),

                // ── 3. TODAY ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _TodayCard(
                      today: today,
                      dailyProgress: dailyProgress,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'today'),
                    ),
                  ),
                ),

                // ── 4. PRODUCTIVITY CLOCK ─────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _ClockCard(
                      taskSegments: taskSegments,
                      dailyProgress: dailyProgress,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'today'),
                      tier: summary.bestTierAchieved,
                    ),
                  ),
                ),

                // ── 5. ACTIVE ITEMS ───────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _ActiveItemsCard(
                      activeItems: dashboard.activeItems,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'active_items'),
                    ),
                  ),
                ),

                // ── 6. CATEGORY STATS ─────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _CategoryStatsCard(
                      stats: dashboard.categoryStats,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'category_stats'),
                    ),
                  ),
                ),

                // ── 7. REWARDS ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _RewardsCard(
                      rewards: dashboard.rewards,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'rewards'),
                    ),
                  ),
                ),

                // ── 8. PROGRESS HISTORY ───────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _ProgressHistoryCard(
                      history: dashboard.progressHistory,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'progress_history'),
                    ),
                  ),
                ),

                // ── 9. WEEKLY OVERVIEW ────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: _WeeklyCard(
                      history: dashboard.weeklyHistory,
                      isDark: isDark,
                      theme: theme,
                      onTap: () => _nav(context, 'weekly_history'),
                    ),
                  ),
                ),

                // ── 10. MOOD ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: MoodTrendChart(
                      mood: mood,
                      showFrequency: false,
                      onTap: () => _nav(context, 'mood'),
                    ),
                  ),
                ),

                // 11. STREAKS CALENDAR ──────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: StreakCalendarWidget(
                      streaks: streaks,
                      onTap: () => _nav(context, 'streaks'),
                    ),
                  ),
                ),

                // ── 12. RECENT ACTIVITY ───────────────────────────
                SliverToBoxAdapter(
                  child: _SectionWrapper(
                    child: dashboard.recentActivity.isEmpty
                        ? _HomeCard(
                            child: EmptyStateWidget(
                              icon: Icons.history_rounded,
                              title: 'No Recent Activity',
                              subtitle: 'Your activities will appear here.',
                            ),
                          )
                        : _RecentActivityCard(
                            activities: dashboard.recentActivity,
                            isDark: isDark,
                            theme: theme,
                            onTap: () => _nav(context, 'recent_activity'),
                          ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Navigation (unchanged) ───────────────────────────────────────

  void _nav(BuildContext context, String type) {
    late Widget screen;
    switch (type) {
      case 'today':
        screen = const TodayDetailScreen();
        break;
      case 'overview':
        screen = const OverviewDetailScreen();
        break;
      case 'active_items':
        screen = const ActiveItemsDetailScreen();
        break;
      case 'progress_history':
        screen = const ProgressHistoryDetailScreen();
        break;
      case 'weekly_history':
        screen = const WeeklyHistoryDetailScreen();
        break;
      case 'category_stats':
        screen = const CategoryStatsDetailScreen();
        break;
      case 'rewards':
        screen = const RewardsDetailScreen();
        break;
      case 'mood':
        screen = const MoodDetailScreen();
        break;
      case 'streaks':
        screen = const StreaksDetailScreen();
        break;
      case 'recent_activity':
        screen = const RecentActivityDetailScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ── Task segments helper ─────────────────────────────────────────

  List<TaskSegment> _buildTaskSegments(TodaySummary today) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final segments = <TaskSegment>[];

    for (final t in today.dayTasks) {
      segments.add(
        TaskSegment(
          id: t.id,
          title: t.title,
          startTime: t.timeStart ?? base.add(const Duration(hours: 9)),
          endTime: t.timeEnd ?? base.add(const Duration(hours: 11)),
          priority: t.priority ?? 'medium',
          status: t.isComplete ? 'completed' : t.status,
          progress: t.progress,
          points: t.points,
          categoryType: t.categoryType,
          reward: t.reward,
          taskType: 'Day Task',
        ),
      );
    }
    for (final t in today.weekTasksDueToday) {
      segments.add(
        TaskSegment(
          id: t.id,
          title: t.title,
          startTime: t.timeStart ?? base.add(const Duration(hours: 13)),
          endTime: t.timeEnd ?? base.add(const Duration(hours: 14)),
          priority: t.priority ?? 'medium',
          status: t.isComplete ? 'completed' : t.status,
          progress: t.progress,
          points: t.points,
          categoryType: t.categoryType,
          reward: t.reward,
          taskType: 'Weekly Task',
        ),
      );
    }
    for (final g in today.longGoalsDueToday) {
      var s = g.timeStart ?? base.add(const Duration(hours: 14));
      var e = g.timeEnd ?? base.add(const Duration(hours: 15));
      if (e.difference(s).inHours > 24) {
        s = base.add(const Duration(hours: 14));
        e = base.add(const Duration(hours: 15));
      }

      segments.add(
        TaskSegment(
          id: g.id,
          title: g.title,
          startTime: s,
          endTime: e,
          priority: g.priority ?? 'medium',
          status: g.isComplete ? 'completed' : g.status,
          progress: g.progress,
          points: g.points,
          categoryType: g.categoryType,
          reward: g.reward,
          taskType: 'Long Goal',
        ),
      );
    }
    for (final b in today.bucketsEntry) {
      segments.add(
        TaskSegment(
          id: b.id,
          title: b.title,
          startTime: b.doneTime ?? base.add(const Duration(hours: 16)),
          endTime: (b.doneTime ?? base).add(const Duration(hours: 1)),
          priority: b.priority ?? 'medium',
          status: b.status,
          progress: b.progress,
          points: b.points,
          reward: b.reward,
          taskType: 'Bucket',
        ),
      );
    }
    if (today.diaryEntry.hasEntry) {
      segments.add(
        TaskSegment(
          id: 'diary_entry_today',
          title: 'Diary Entry',
          startTime: base.add(const Duration(hours: 23)),
          endTime: base.add(const Duration(hours: 23, minutes: 30)),
          priority: 'medium',
          status: 'completed',
          progress: 100,
          points: 0,
          taskType: 'Diary',
        ),
      );
    }
    return segments;
  }
}

// ================================================================
// ── SHARED PRIMITIVES ────────────────────────────────────────────
// ================================================================

class _SectionWrapper extends StatelessWidget {
  final Widget child;
  final double topPad;
  const _SectionWrapper({required this.child, this.topPad = 0});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.fromLTRB(16, topPad, 16, 14), child: child);
}

class _HomeCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final List<Color>? gradient;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const _HomeCard({
    required this.child,
    this.accentColor,
    this.gradient,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient!,
                )
              : null,
          color: gradient == null
              ? (isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surface)
              : null,
          borderRadius: BorderRadius.circular(20),
          border: accentColor != null
              ? Border.all(color: accentColor!.withOpacity(0.22))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _HomeLabel extends StatelessWidget {
  final String label;
  final Color? color;
  final Widget? trailing;
  const _HomeLabel({required this.label, this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ViewAllBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View All',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _MetricTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 3),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 1. HERO HEADER
// ================================================================

class _DHeroHeader extends StatelessWidget {
  final DashboardSummary summary;
  final Mood mood;
  final String lastUpdated;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const _DHeroHeader({
    required this.summary,
    required this.mood,
    required this.lastUpdated,
    required this.isDark,
    required this.theme,
    this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF0A0A14)]
                : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.white.withOpacity(0.55),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated $lastUpdated',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onRefresh != null)
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Two big metric cards
            Row(
              children: [
                Expanded(
                  child: _BigMetricCard(
                    emoji: '⭐',
                    label: "Today's Points",
                    value: summary.pointsToday.toString(),
                    sub: 'Keep it up!',
                    color: const Color(0xFFFFB84D),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigMetricCard(
                    emoji: '🏆',
                    label: 'Global Rank',
                    value: '#${summary.globalRank}',
                    sub: 'Top ${summary.completionRateAll.toInt()}%',
                    color: const Color(0xFFA78BFA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.15), height: 1),
            const SizedBox(height: 12),

            // Scrollable stats strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _HeroStat(
                    label: 'Today %',
                    value: '${summary.completionRateToday.toInt()}%',
                    icon: '✅',
                  ),
                  _HeroStat(
                    label: 'Streak',
                    value: '${summary.currentStreak}d',
                    icon: '🔥',
                  ),
                  _HeroStat(
                    label: 'Rewards',
                    value: summary.totalRewards.toString(),
                    icon: '🎁',
                  ),
                  _HeroStat(
                    label: 'Avg Progress',
                    value: '${summary.averageProgress}%',
                    icon: '📈',
                  ),
                  _HeroStat(
                    label: 'This Week',
                    value: summary.pointsThisWeek.toString(),
                    icon: '📅',
                  ),
                  _HeroStat(
                    label: 'Best Tier',
                    value: _fmt(summary.bestTierAchieved),
                    icon: '👑',
                  ),
                  _HeroStat(
                    label: 'Rating',
                    value: summary.averageRating.toStringAsFixed(1),
                    icon: '⭐',
                  ),
                  _HeroStat(
                    label: 'Mood',
                    value: mood.todayMood?.label ?? 'N/A',
                    icon: mood.todayMood?.emoji ?? '😐',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Completion bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Completion",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
                Text(
                  '${summary.completionRateToday.toInt()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomProgressIndicator(
              progress: (summary.completionRateToday / 100).clamp(0.0, 1.0),
              progressBarName: '',
              orientation: ProgressOrientation.horizontal,
              baseHeight: 8,
              maxHeightIncrease: 3,
              gradientColors: const [Color(0xFFFFFFFF), Color(0xFFD8B4FE)],
              backgroundColor: Colors.white.withOpacity(0.15),
              borderRadius: 6,
              progressLabelDisplay: ProgressLabelDisplay.none,
              nameLabelPosition: LabelPosition.bottom,
              animateNameLabel: false,
              animationDuration: const Duration(milliseconds: 1500),
              animationCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(String tier) => tier == 'none'
      ? 'None'
      : '${tier[0].toUpperCase()}${tier.substring(1).toLowerCase()}';
}

class _BigMetricCard extends StatelessWidget {
  final String emoji, label, value, sub;
  final Color color;
  const _BigMetricCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Text(
                sub,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String icon, label, value;
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 2. MOTIVATIONAL BANNER
// ================================================================

class _MotivationalBanner extends StatelessWidget {
  final Streaks streaks;
  final bool isDark;
  final ThemeData theme;
  const _MotivationalBanner({
    required this.streaks,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = streaks.isActive;
    final current = streaks.currentDays;
    final target = streaks.nextMilestone.target;
    const color = Color(0xFF667EEA);

    return _HomeCard(
      gradient: [
        color.withOpacity(isDark ? 0.18 : 0.1),
        const Color(0xFF764BA2).withOpacity(isDark ? 0.08 : 0.04),
      ],
      accentColor: color,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? '🌟 Keep it up!' : '💡 Start your streak today!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'You\'re on a $current-day streak!\nNext milestone: ${target > 0 ? '$target days' : 'All done! 🎉'}'
                      : 'Complete a task to build your streak.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                CustomProgressIndicator(
                  progress: target > 0
                      ? (current / target).clamp(0.0, 1.0)
                      : 1.0,
                  progressBarName:
                      '$current / ${target > 0 ? target : current} days',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 7,
                  maxHeightIncrease: 2,
                  gradientColors: const [Color(0xFF667EEA), Color(0xFFA78BFA)],
                  backgroundColor: color.withOpacity(0.1),
                  borderRadius: 5,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 9,
                  ),
                  animateNameLabel: true,
                  animationDuration: const Duration(milliseconds: 1300),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AdvancedProgressIndicator(
            progress: target > 0 ? (current / target).clamp(0.0, 1.0) : 1.0,
            size: 72,
            strokeWidth: 6,
            shape: ProgressShape.circular,
            gradientColors: const [Color(0xFF667EEA), Color(0xFFA78BFA)],
            backgroundColor: color.withOpacity(0.1),
            labelStyle: ProgressLabelStyle.custom,
            customLabel: isActive ? streaks.streakEmoji : '💤',
            labelTextStyle: const TextStyle(fontSize: 22),
            showGlow: isActive,
            glowRadius: 6,
            animationDuration: const Duration(milliseconds: 1400),
            name: '${current}d',
            namePosition: ProgressLabelPosition.bottom,
            nameTextStyle: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 3. TODAY CARD
// ================================================================

class _TodayCard extends StatelessWidget {
  final TodaySummary today;
  final double dailyProgress;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _TodayCard({
    required this.today,
    required this.dailyProgress,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3B82F6);
    final done = today.summary.completed;
    final total = today.summary.totalScheduledTask;

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '☀️ Today\'s Schedule',
            color: blue,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AdvancedProgressIndicator(
                progress: dailyProgress,
                size: 90,
                strokeWidth: 9,
                shape: ProgressShape.circular,
                gradientColors: [blue, blue.withOpacity(0.55)],
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade200,
                labelStyle: ProgressLabelStyle.custom,
                customLabel: '${(dailyProgress * 100).toStringAsFixed(0)}%',
                labelTextStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: blue,
                ),
                showGlow: dailyProgress > 0.5,
                glowRadius: 7,
                animationDuration: const Duration(milliseconds: 1400),
                name: 'done',
                namePosition: ProgressLabelPosition.bottom,
                nameTextStyle: theme.textTheme.labelSmall?.copyWith(
                  color: blue.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            emoji: '✅',
                            label: 'Done',
                            value: '$done/$total',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            emoji: '⭐',
                            label: 'Points',
                            value: today.summary.pointsEarned.toString(),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            emoji: '📅',
                            label: 'Day Tasks',
                            value: today.dayTasks.length.toString(),
                            color: blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricTile(
                            emoji: '🎯',
                            label: 'Goals',
                            value: today.longGoalsDueToday.length.toString(),
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completion',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              Text(
                '$done / $total tasks',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CustomProgressIndicator(
            progress: dailyProgress,
            progressBarName: '',
            orientation: ProgressOrientation.horizontal,
            baseHeight: 10,
            maxHeightIncrease: 4,
            gradientColors: [blue, blue.withOpacity(0.55)],
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade200,
            borderRadius: 7,
            progressLabelDisplay: ProgressLabelDisplay.bubble,
            progressLabelBackgroundColor: blue,
            nameLabelPosition: LabelPosition.bottom,
            animateNameLabel: false,
            animationDuration: const Duration(milliseconds: 1400),
            animationCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 4. PRODUCTIVITY CLOCK CARD
// ================================================================

class _ClockCard extends StatelessWidget {
  final List<TaskSegment> taskSegments;
  final double dailyProgress;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final String tier;
  const _ClockCard({
    required this.taskSegments,
    required this.dailyProgress,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '⏰ 24-Hour Productivity Clock',
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any segment for task details',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Productivity24HourClock(
              tasks: taskSegments,
              dailyProgress: dailyProgress,
              isDarkMode: isDark,
              size: w - 96,
              onTaskSelected: (_) {},
              tier: tier,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 5. ACTIVE ITEMS CARD
// ================================================================

class _ActiveItemsCard extends StatelessWidget {
  final ActiveItems activeItems;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _ActiveItemsCard({
    required this.activeItems,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];
  static const _emojis = ['✅', '📅', '🎯', '🎁'];
  static const _labels = ['Day', 'Weekly', 'Goals', 'Buckets'];

  @override
  Widget build(BuildContext context) {
    final ai = activeItems;
    final counts = [
      ai.activeDayTasks.length,
      ai.activeWeekTasks.length,
      ai.activeLongGoals.length,
      ai.activeBuckets.length,
    ];
    final total = counts.fold<int>(0, (s, c) => s + c);
    final allItems = [
      ...ai.activeDayTasks,
      ...ai.activeWeekTasks,
      ...ai.activeLongGoals,
      ...ai.activeBuckets,
    ];
    final avg = allItems.isEmpty
        ? 0.0
        : allItems.fold<int>(0, (s, item) {
                if (item is ActiveDayTask) return s + item.progress;
                if (item is ActiveWeekTask) return s + item.progress;
                if (item is ActiveLongGoal) return s + item.progress;
                if (item is ActiveBucket) return s + item.progress;
                return s;
              }) /
              allItems.length;
    final maxC = counts.fold<int>(1, (m, c) => c > m ? c : m);
    const purple = Color(0xFF667EEA);

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '⚡ Active Items ($total)',
            color: purple,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AdvancedProgressIndicator(
                progress: (avg / 100).clamp(0.0, 1.0),
                size: 80,
                strokeWidth: 8,
                shape: ProgressShape.circular,
                gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade200,
                labelStyle: ProgressLabelStyle.custom,
                customLabel: '${avg.toStringAsFixed(0)}%',
                labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: purple,
                ),
                showGlow: avg > 60,
                glowRadius: 5,
                animationDuration: const Duration(milliseconds: 1400),
                name: 'avg',
                namePosition: ProgressLabelPosition.bottom,
                nameTextStyle: theme.textTheme.labelSmall?.copyWith(
                  color: purple.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.0,
                  children: List.generate(
                    4,
                    (i) => _MetricTile(
                      emoji: _emojis[i],
                      label: _labels[i],
                      value: counts[i].toString(),
                      color: _colors[i],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...List.generate(4, (i) {
            final frac = maxC > 0 ? counts[i] / maxC : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            _emojis[i],
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _labels[i],
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.65,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        counts[i].toString(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _colors[i],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomProgressIndicator(
                    progress: frac.clamp(0.0, 1.0),
                    progressBarName: '',
                    orientation: ProgressOrientation.horizontal,
                    baseHeight: 7,
                    maxHeightIncrease: 2,
                    gradientColors: [_colors[i], _colors[i].withOpacity(0.55)],
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade200,
                    borderRadius: 5,
                    progressLabelDisplay: ProgressLabelDisplay.none,
                    nameLabelPosition: LabelPosition.bottom,
                    animateNameLabel: false,
                    animationDuration: const Duration(milliseconds: 1200),
                    animationCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ================================================================
// 6. CATEGORY STATS CARD
// ================================================================

class _CategoryStatsCard extends StatelessWidget {
  final CategoryStats stats;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _CategoryStatsCard({
    required this.stats,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF14B8A6);
    final items = stats.stats;
    final top = items.isEmpty ? null : items.first;

    if (items.isEmpty) {
      return _HomeCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeLabel(
              label: '📊 Category Stats',
              color: teal,
              trailing: _ViewAllBtn(onTap: onTap),
            ),
            const SizedBox(height: 20),
            EmptyStateWidget(
              icon: Icons.category_rounded,
              title: 'No Categories Yet',
              subtitle: 'Create tasks to see category stats.',
            ),
          ],
        ),
      );
    }

    final maxPts = items
        .map((c) => c.points)
        .fold<int>(1, (m, v) => v > m ? v : m);
    final totalPts = items.fold<int>(0, (s, c) => s + c.points);
    final avgCompletion = items.isEmpty
        ? 0.0
        : items.fold<double>(0, (s, c) => s + c.completionRate) / items.length;

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '📊 Category Stats (${items.length})',
            color: teal,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),

          // Summary strip
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  emoji: '📁',
                  label: 'Categories',
                  value: items.length.toString(),
                  color: teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  emoji: '⭐',
                  label: 'Total Pts',
                  value: totalPts.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  emoji: '✅',
                  label: 'Avg Done',
                  value: '${avgCompletion.toStringAsFixed(0)}%',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Top category spotlight
          if (top != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    top.displayColor.withOpacity(isDark ? 0.22 : 0.14),
                    top.displayColor.withOpacity(isDark ? 0.08 : 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: top.displayColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(top.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🥇 ${top.categoryName}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: top.displayColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: top.displayColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${top.completionRate.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: top.displayColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${top.points} pts  •  ${top.tasksCompleted}/${top.totalTasks} tasks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomProgressIndicator(
                    progress: (top.completionRate / 100).clamp(0.0, 1.0),
                    progressBarName: '',
                    orientation: ProgressOrientation.horizontal,
                    baseHeight: 8,
                    maxHeightIncrease: 2,
                    gradientColors: [
                      top.displayColor,
                      top.displayColor.withOpacity(0.55),
                    ],
                    backgroundColor: top.displayColor.withOpacity(0.1),
                    borderRadius: 6,
                    progressLabelDisplay: ProgressLabelDisplay.none,
                    nameLabelPosition: LabelPosition.bottom,
                    animateNameLabel: false,
                    animationDuration: const Duration(milliseconds: 1300),
                    animationCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Points bars for all categories (max 5)
          ...items.take(5).map((cat) {
            final frac = maxPts > 0 ? cat.points / maxPts : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            cat.categoryName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${cat.points} pts',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cat.displayColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomProgressIndicator(
                    progress: frac.clamp(0.0, 1.0),
                    progressBarName: '',
                    orientation: ProgressOrientation.horizontal,
                    baseHeight: 7,
                    maxHeightIncrease: 2,
                    gradientColors: [
                      cat.displayColor,
                      cat.displayColor.withOpacity(0.55),
                    ],
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade200,
                    borderRadius: 5,
                    progressLabelDisplay: ProgressLabelDisplay.none,
                    nameLabelPosition: LabelPosition.bottom,
                    animateNameLabel: false,
                    animationDuration: const Duration(milliseconds: 1200),
                    animationCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            );
          }),
          if (items.length > 5) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '+ ${items.length - 5} more categories',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// 7. REWARDS CARD
// ================================================================

class _RewardsCard extends StatelessWidget {
  final Rewards rewards;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _RewardsCard({
    required this.rewards,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bestTier = rewards.bestTierAchieved;
    final tierColor = CardColorHelper.getTierColor(bestTier);
    final tierEmoji = CardColorHelper.getTierEmoji(bestTier);

    // Points toward next reward (0–1)
    final nextProgress = rewards.totalPoints > 0
        ? (rewards.totalPoints % 100) / 100.0
        : 0.0;

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '🎁 Rewards & Tiers',
            color: tierColor,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),

          // Best tier spotlight
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tierColor.withOpacity(isDark ? 0.28 : 0.18),
                  tierColor.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tierColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                // Tier ring
                AdvancedProgressIndicator(
                  progress:
                      (rewards.totalRewardsEarned /
                              (rewards.totalRewardsEarned + 10).toDouble())
                          .clamp(0.0, 1.0),
                  size: 76,
                  strokeWidth: 7,
                  shape: ProgressShape.circular,
                  gradientColors: [tierColor, tierColor.withOpacity(0.5)],
                  backgroundColor: tierColor.withOpacity(0.1),
                  labelStyle: ProgressLabelStyle.custom,
                  customLabel: tierEmoji,
                  labelTextStyle: const TextStyle(fontSize: 22),
                  showGlow: true,
                  glowRadius: 8,
                  animationDuration: const Duration(milliseconds: 1400),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Tier Achieved',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        bestTier == 'none'
                            ? 'None Yet'
                            : '${bestTier[0].toUpperCase()}${bestTier.substring(1)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: tierColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _RewardPill(
                            label: 'Earned',
                            value: rewards.totalRewardsEarned.toString(),
                            color: tierColor,
                          ),
                          const SizedBox(width: 8),
                          _RewardPill(
                            label: 'Points',
                            value: rewards.totalPoints.toString(),
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Summary tiles
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  emoji: '🏅',
                  label: 'Total Earned',
                  value: rewards.totalRewardsEarned.toString(),
                  color: tierColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  emoji: '⭐',
                  label: 'Reward Pts',
                  value: rewards.totalPoints.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  emoji: '🔓',
                  label: 'Tiers',
                  value: rewards.earnedRewardsNo.length.toString(),
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Next reward progress
          if (rewards.summary.nextRewards.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Reward Progress',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  '${(nextProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tierColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomProgressIndicator(
              progress: nextProgress.clamp(0.0, 1.0),
              progressBarName: 'Next: ${rewards.summary.nextRewards}',
              orientation: ProgressOrientation.horizontal,
              baseHeight: 9,
              maxHeightIncrease: 3,
              gradientColors: [tierColor, tierColor.withOpacity(0.55)],
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade200,
              borderRadius: 7,
              progressLabelDisplay: ProgressLabelDisplay.none,
              nameLabelPosition: LabelPosition.bottom,
              nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
                fontSize: 9,
              ),
              animateNameLabel: true,
              animationDuration: const Duration(milliseconds: 1400),
              animationCurve: Curves.easeOutCubic,
            ),
            if (rewards.summary.suggestion?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rewards.summary.suggestion ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RewardPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withOpacity(0.65),
                fontSize: 9,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 8. PROGRESS HISTORY CARD
// ================================================================

class _ProgressHistoryCard extends StatelessWidget {
  final ProgressHistory history;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _ProgressHistoryCard({
    required this.history,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = history.trend.toLowerCase() == 'improving';
    final isDown = history.trend.toLowerCase() == 'declining';
    final color = isUp
        ? const Color(0xFF10B981)
        : isDown
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);
    final max30 = history.dailyStats.isEmpty
        ? 1
        : history.dailyStats
              .map((d) => d.points)
              .reduce((a, b) => a > b ? a : b);
    final recent = history.dailyStats.reversed
        .take(14)
        .toList()
        .reversed
        .toList();

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '📈 30-Day Progress',
            color: color,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AdvancedProgressIndicator(
                progress: (history.averageProgress / 100).clamp(0.0, 1.0),
                size: 88,
                strokeWidth: 8,
                shape: ProgressShape.arc,
                arcStartAngle: 180,
                arcSweepAngle: 180,
                gradientColors: [color, color.withOpacity(0.5)],
                backgroundColor: color.withOpacity(0.1),
                labelStyle: ProgressLabelStyle.custom,
                customLabel: '${history.averageProgress.toStringAsFixed(0)}%',
                labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                animationDuration: const Duration(milliseconds: 1400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Daily Progress',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${history.averageProgress.toStringAsFixed(1)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUp
                                    ? Icons.trending_up_rounded
                                    : isDown
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_flat_rounded,
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                history.trend.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomProgressIndicator(
                      progress: (history.averageProgress / 100).clamp(0.0, 1.0),
                      progressBarName:
                          '${history.dailyStats.length} days tracked',
                      orientation: ProgressOrientation.horizontal,
                      baseHeight: 8,
                      maxHeightIncrease: 2,
                      gradientColors: [color, color.withOpacity(0.5)],
                      backgroundColor: color.withOpacity(0.1),
                      borderRadius: 6,
                      progressLabelDisplay: ProgressLabelDisplay.none,
                      nameLabelPosition: LabelPosition.bottom,
                      nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 9,
                      ),
                      animateNameLabel: true,
                      animationDuration: const Duration(milliseconds: 1300),
                      animationCurve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Last ${recent.length} days',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: recent.map((d) {
                  final frac = max30 > 0 ? d.points / max30 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 42 * frac + (d.points > 0 ? 4 : 2),
                            decoration: BoxDecoration(
                              gradient: d.points > 0
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [color, color.withOpacity(0.55)],
                                    )
                                  : null,
                              color: d.points > 0
                                  ? null
                                  : (isDark
                                        ? Colors.white.withOpacity(0.07)
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// 9. WEEKLY CARD
// ================================================================

class _WeeklyCard extends StatelessWidget {
  final WeeklyHistory history;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _WeeklyCard({
    required this.history,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = history.weekOverWeekChange >= 0;
    final cc = isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    const blue = Color(0xFF3B82F6);
    const purple = Color(0xFF8B5CF6);
    final maxW = history.currentWeekPoints > history.lastWeekPoints
        ? history.currentWeekPoints
        : history.lastWeekPoints;
    final safeMax = maxW == 0 ? 1 : maxW;

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '📅 Weekly Overview',
            color: blue,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: cc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cc.withOpacity(0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPos
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: cc,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPos ? '+' : ''}${history.weekOverWeekChange.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cc,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WBar(
            label: 'This Week',
            emoji: '📅',
            pts: history.currentWeekPoints,
            fraction: history.currentWeekPoints / safeMax,
            color: blue,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _WBar(
            label: 'Last Week',
            emoji: '📆',
            pts: history.lastWeekPoints,
            fraction: history.lastWeekPoints / safeMax,
            color: purple,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Avg Weekly: ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                history.averageWeeklyPoints.toStringAsFixed(0),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: blue,
                ),
              ),
              Text(
                ' pts',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: blue.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WBar extends StatelessWidget {
  final String label, emoji;
  final int pts;
  final double fraction;
  final Color color;
  final bool isDark;
  final ThemeData theme;
  const _WBar({
    required this.label,
    required this.emoji,
    required this.pts,
    required this.fraction,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '+$pts pts',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
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
        borderRadius: 7,
        progressLabelDisplay: ProgressLabelDisplay.none,
        nameLabelPosition: LabelPosition.bottom,
        animateNameLabel: false,
        animationDuration: const Duration(milliseconds: 1300),
        animationCurve: Curves.easeOutCubic,
      ),
    ],
  );
}

// ================================================================
// 10. RECENT ACTIVITY CARD
// ================================================================

class _RecentActivityCard extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  const _RecentActivityCard({
    required this.activities,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF06B6D4);
    final shown = activities.take(4).toList();

    return _HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeLabel(
            label: '📜 Recent Activity',
            color: cyan,
            trailing: _ViewAllBtn(onTap: onTap),
          ),
          const SizedBox(height: 14),
          ...shown.asMap().entries.map((e) {
            final act = e.value;
            final isLast = e.key == shown.length - 1;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: act.actionColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        act.actionIcon,
                        color: act.actionColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            act.timeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (act.hasPoints) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA500).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          act.pointsLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFFFA500),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }),
          if (activities.length > 4) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '+ ${activities.length - 4} more activities',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// FILE: weekly_history_detail_screen.dart
// 12-WEEK HISTORY SCREEN
// Uses: CustomProgressIndicator, AdvancedProgressIndicator,
//       progress_history_shared_widgets.dart,
//       shared_widgets.dart
// NO chart_widgets.dart / fl_chart dependency
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Shared history widgets ────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/progress_history_shared_widgets.dart';

// ── Dashboard shared ─────────────────────────────────────────────
import '../widgets/shared_widgets.dart';

// ── Data + provider ──────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class WeeklyHistoryDetailScreen extends StatefulWidget {
  const WeeklyHistoryDetailScreen({super.key});

  @override
  State<WeeklyHistoryDetailScreen> createState() =>
      _WeeklyHistoryDetailScreenState();
}

class _WeeklyHistoryDetailScreenState extends State<WeeklyHistoryDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _bodyCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _bodyFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _bodyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _bodyFade = CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _heroCtrl.forward();
      Future.delayed(const Duration(milliseconds: 260), () {
        if (mounted) _bodyCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<UserDashboardProvider>(
        builder: (context, provider, _) {
          if (!provider.hasData) return const ChartLoadingSkeleton();
          final history = provider.weeklyHistory;

          // Derived data
          final totalPoints = history.weeklyStats.fold<int>(
            0,
            (s, w) => s + w.points,
          );
          final maxPoints = history.weeklyStats.isEmpty
              ? 0
              : history.weeklyStats
                    .map((w) => w.points)
                    .reduce((a, b) => a > b ? a : b);
          final values = history.weeklyStats
              .map((w) => w.points as num)
              .toList();
          final labels = history.weeklyStats
              .map((w) => 'W${w.weekNumber}')
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: _WeeklyHeroHeader(
                    history: history,
                    totalPoints: totalPoints,
                    maxPoints: maxPoints,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    'Weekly History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── BODY ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Week Compare Strip ─────────────
                          PHSectionLabel(label: 'Week-over-Week'),
                          const SizedBox(height: 12),
                          PHWeekCompareStrip(
                            currentWeekPoints: history.currentWeekPoints,
                            lastWeekPoints: history.lastWeekPoints,
                            weekOverWeekChange: history.weekOverWeekChange,
                          ),
                          const SizedBox(height: 24),

                          // ── 2. Summary Stats Grid ─────────────
                          PHSectionLabel(label: '12-Week Summary'),
                          const SizedBox(height: 12),
                          PHStatSummaryGrid(
                            tiles: [
                              PHStatTileData(
                                emoji: '⭐',
                                label: 'Total Points',
                                value: totalPoints.toString(),
                                color: const Color(0xFFF59E0B),
                              ),
                              PHStatTileData(
                                emoji: '📅',
                                label: 'Weeks Tracked',
                                value: history.weeklyStats.length.toString(),
                                color: const Color(0xFF3B82F6),
                              ),
                              PHStatTileData(
                                emoji: '🔝',
                                label: 'Best Week Pts',
                                value: maxPoints.toString(),
                                color: const Color(0xFF10B981),
                              ),
                              PHStatTileData(
                                emoji: '📊',
                                label: 'Avg Weekly Pts',
                                value: history.averageWeeklyPoints
                                    .toStringAsFixed(0),
                                color: const Color(0xFF8B5CF6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── 3. Sparkline Chart ────────────────
                          PHSectionLabel(label: 'Weekly Points — 12 Weeks'),
                          const SizedBox(height: 12),
                          PHSparklineChart(
                            title: 'Points per Week',
                            subtitle:
                                '${history.weeklyStats.length} weeks of data',
                            values: values,
                            labels: labels,
                            lineColor: const Color(0xFF10B981),
                            height: 200,
                            showDots: true,
                          ),
                          const SizedBox(height: 24),

                          // ── 4. Average Weekly Arc ─────────────
                          PHSectionLabel(label: 'Average Performance'),
                          const SizedBox(height: 12),
                          PHAverageArc(
                            title: 'Average Weekly Points',
                            value: history.averageWeeklyPoints.toStringAsFixed(
                              0,
                            ),
                            unit: 'pts/week',
                            progress: maxPoints > 0
                                ? history.averageWeeklyPoints / maxPoints
                                : 0.0,
                            color: const Color(0xFF8B5CF6),
                            emoji: '📊',
                          ),
                          const SizedBox(height: 24),

                          // ── 5. Week over week % change ────────
                          PHSectionLabel(label: 'Momentum'),
                          const SizedBox(height: 12),
                          _MomentumCard(
                            history: history,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 6. Best / Worst Week ──────────────
                          if (history.bestWeek != null ||
                              history.worstWeek != null) ...[
                            PHSectionLabel(label: 'Week Highlights'),
                            const SizedBox(height: 12),
                            if (history.bestWeek != null)
                              PHHighlightCard(
                                label: '🏆 Best Week',
                                dateLabel:
                                    'Week ${history.bestWeek!.weekNumber}',
                                points: history.bestWeek!.points,
                                tasksCompleted:
                                    history.bestWeek!.tasksCompleted,
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            if (history.bestWeek != null &&
                                history.worstWeek != null)
                              const SizedBox(height: 10),
                            if (history.worstWeek != null)
                              PHHighlightCard(
                                label: '📉 Worst Week',
                                dateLabel:
                                    'Week ${history.worstWeek!.weekNumber}',
                                points: history.worstWeek!.points,
                                tasksCompleted:
                                    history.worstWeek!.tasksCompleted,
                                icon: Icons.trending_down_rounded,
                                color: const Color(0xFFEF4444),
                              ),
                            const SizedBox(height: 24),
                          ],

                          // ── 7. All-Weeks Breakdown Bars ───────
                          PHSectionLabel(label: 'All Weeks Breakdown'),
                          const SizedBox(height: 12),
                          _AllWeeksBreakdown(
                            weeklyStats: history.weeklyStats,
                            maxPoints: maxPoints,
                            currentWeekPoints: history.currentWeekPoints,
                            theme: theme,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================================================
// HERO HEADER
// ================================================================

class _WeeklyHeroHeader extends StatelessWidget {
  final WeeklyHistory history;
  final int totalPoints, maxPoints;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _WeeklyHeroHeader({
    required this.history,
    required this.totalPoints,
    required this.maxPoints,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = history.weekOverWeekChange >= 0;
    final c1 = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final c2 = isPositive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(c1, const Color(0xFF0A0A14), 0.72)!,
                  const Color(0xFF0A0A14),
                ]
              : [c1, c2],
        ),
      ),
      child: SlideTransition(
        position: heroSlide,
        child: FadeTransition(
          opacity: heroFade,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly History',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '12 weeks of performance insights',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // WoW badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPositive ? '📈' : '📉',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isPositive ? '+' : ''}${history.weekOverWeekChange.toStringAsFixed(1)}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        PHHeroStat(
                          value: history.currentWeekPoints.toString(),
                          label: 'This Week',
                          icon: '📅',
                        ),
                        const PHHeroDiv(),
                        PHHeroStat(
                          value: history.lastWeekPoints.toString(),
                          label: 'Last Week',
                          icon: '📆',
                        ),
                        const PHHeroDiv(),
                        PHHeroStat(
                          value: maxPoints.toString(),
                          label: 'Best Week',
                          icon: '🏆',
                        ),
                        const PHHeroDiv(),
                        PHHeroStat(
                          value: history.averageWeeklyPoints.toStringAsFixed(0),
                          label: 'Avg/Week',
                          icon: '📊',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MOMENTUM CARD
// ================================================================

class _MomentumCard extends StatelessWidget {
  final WeeklyHistory history;
  final ThemeData theme;
  final bool isDark;

  const _MomentumCard({
    required this.history,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = history.weekOverWeekChange >= 0;
    final changeColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final absChange = history.weekOverWeekChange.abs();
    // Normalise change to 0–1 for the progress arc (cap at 100%)
    final fraction = (absChange / 100).clamp(0.0, 1.0);

    return PHCardShell(
      accentColor: changeColor,
      gradient: [
        changeColor.withOpacity(isDark ? 0.2 : 0.12),
        changeColor.withOpacity(isDark ? 0.07 : 0.03),
      ],
      child: Row(
        children: [
          // Arc for WoW change magnitude
          AdvancedProgressIndicator(
            progress: fraction,
            size: 100,
            strokeWidth: 9,
            shape: ProgressShape.circular,
            gradientColors: [changeColor, changeColor.withOpacity(0.5)],
            backgroundColor: changeColor.withOpacity(0.1),
            labelStyle: ProgressLabelStyle.custom,
            customLabel:
                '${isPositive ? '+' : ''}${history.weekOverWeekChange.toStringAsFixed(1)}%',
            labelTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: changeColor,
            ),
            showGlow: isPositive,
            glowRadius: 7,
            animationDuration: const Duration(milliseconds: 1400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? '📈 Growing Momentum!' : '📉 Momentum Slipping',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: changeColor,
                  ),
                ),
                const SizedBox(height: 6),
                _MRow(
                  label: 'This Week',
                  value: '${history.currentWeekPoints} pts',
                  color: const Color(0xFF3B82F6),
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _MRow(
                  label: 'Last Week',
                  value: '${history.lastWeekPoints} pts',
                  color: const Color(0xFF8B5CF6),
                  theme: theme,
                ),
                const SizedBox(height: 4),
                _MRow(
                  label: 'Difference',
                  value:
                      '${isPositive ? '+' : ''}${history.currentWeekPoints - history.lastWeekPoints} pts',
                  color: changeColor,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;
  const _MRow({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// ALL WEEKS BREAKDOWN BARS
// ================================================================

class _AllWeeksBreakdown extends StatelessWidget {
  final List<WeeklyStatPoint> weeklyStats;
  final int maxPoints, currentWeekPoints;
  final ThemeData theme;
  final bool isDark;

  const _AllWeeksBreakdown({
    required this.weeklyStats,
    required this.maxPoints,
    required this.currentWeekPoints,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyStats.isEmpty) {
      return PHCardShell(
        child: EmptyStateWidget(
          icon: Icons.bar_chart_rounded,
          title: 'No Weekly Data',
          subtitle: 'Start completing tasks to build weekly history',
        ),
      );
    }

    final safeMax = maxPoints == 0 ? 1 : maxPoints;

    return PHCardShell(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeklyStats.map((week) {
          final fraction = week.points / safeMax;
          final isCurrent =
              week.points == currentWeekPoints && weeklyStats.last == week;
          final color = isCurrent
              ? const Color(0xFF3B82F6)
              : const Color(0xFF8B5CF6);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCurrent ? '📅' : '📆',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Week ${week.weekNumber}${isCurrent ? '  (current)' : ''}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isCurrent
                                ? color
                                : theme.colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '+${week.points}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'pts',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${week.tasksCompleted} tasks',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.4,
                            ),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CustomProgressIndicator(
                  progress: fraction.clamp(0.0, 1.0),
                  progressBarName: '',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: isCurrent ? 11 : 8,
                  maxHeightIncrease: isCurrent ? 3 : 2,
                  gradientColors: [color, color.withOpacity(0.55)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: 7,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  animateNameLabel: false,
                  animationDuration: const Duration(milliseconds: 1200),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

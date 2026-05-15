// ================================================================
// FILE: progress_history_detail_screen.dart
// 30-DAY PROGRESS HISTORY SCREEN
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
// ── Data + provider ──────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class ProgressHistoryDetailScreen extends StatefulWidget {
  const ProgressHistoryDetailScreen({super.key});

  @override
  State<ProgressHistoryDetailScreen> createState() =>
      _ProgressHistoryDetailScreenState();
}

class _ProgressHistoryDetailScreenState
    extends State<ProgressHistoryDetailScreen>
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
        vsync: this, duration: const Duration(milliseconds: 650));
    _bodyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _bodyFade = CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _heroCtrl.forward();
      Future.delayed(const Duration(milliseconds: 260),
              () { if (mounted) _bodyCtrl.forward(); });
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
          final history = provider.progressHistory;

          // Derived data
          final totalPoints = history.dailyStats
              .fold<int>(0, (s, d) => s + d.points);
          final maxPoints = history.dailyStats.isEmpty
              ? 0
              : history.dailyStats
              .map((d) => d.points)
              .reduce((a, b) => a > b ? a : b);
          final activeDays = history.dailyStats
              .where((d) => d.points > 0)
              .length;
          final values = history.dailyStats.map((d) => d.points as num).toList();
          final labels = history.dailyStats.map((d) => d.shortDate).toList();

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
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: _Prog30HeroHeader(
                    history: history,
                    totalPoints: totalPoints,
                    maxPoints: maxPoints,
                    activeDays: activeDays,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('30-Day Progress',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
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
                          // ── 1. Trend Banner ───────────────────
                          PHTrendBanner(
                            trend: history.trend,
                            trendIcon: history.trendIcon,
                            subtitle: _trendSubtitle(
                                history.trend, history.averageProgress),
                          ),
                          const SizedBox(height: 24),

                          // ── 2. Summary Stats Grid ─────────────
                          PHSectionLabel(label: 'Period Summary'),
                          const SizedBox(height: 12),
                          PHStatSummaryGrid(tiles: [
                            PHStatTileData(
                                emoji: '⭐',
                                label: 'Total Points',
                                value: totalPoints.toString(),
                                color: const Color(0xFFF59E0B)),
                            PHStatTileData(
                                emoji: '📅',
                                label: 'Active Days',
                                value: '$activeDays / ${history.dailyStats.length}',
                                color: const Color(0xFF3B82F6)),
                            PHStatTileData(
                                emoji: '🔝',
                                label: 'Best Day Points',
                                value: maxPoints.toString(),
                                color: const Color(0xFF10B981)),
                            PHStatTileData(
                                emoji: '📊',
                                label: 'Avg Daily Progress',
                                value:
                                '${history.averageProgress.toStringAsFixed(1)}%',
                                color: const Color(0xFF8B5CF6)),
                          ]),
                          const SizedBox(height: 24),

                          // ── 3. Sparkline Chart ────────────────
                          PHSectionLabel(label: 'Daily Points — 30 Days'),
                          const SizedBox(height: 12),
                          PHSparklineChart(
                            title: 'Points per Day',
                            subtitle: '${history.dailyStats.length} data points',
                            values: values,
                            labels: labels,
                            lineColor: const Color(0xFF3B82F6),
                            height: 200,
                            showDots: history.dailyStats.length <= 15,
                          ),
                          const SizedBox(height: 24),

                          // ── 4. Average Progress Arc ───────────
                          PHSectionLabel(label: 'Average Performance'),
                          const SizedBox(height: 12),
                          PHAverageArc(
                            title: 'Average Daily Progress',
                            value:
                            '${history.averageProgress.toStringAsFixed(1)}',
                            unit: '%',
                            progress: history.averageProgress / 100,
                            color: const Color(0xFF8B5CF6),
                            emoji: '📈',
                          ),
                          const SizedBox(height: 24),

                          // ── 5. Activity Rate Bar ──────────────
                          PHSectionLabel(label: 'Activity Rate'),
                          const SizedBox(height: 12),
                          _ActivityRateCard(
                            activeDays: activeDays,
                            totalDays: history.dailyStats.length,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 6. Best / Worst Day ───────────────
                          if (history.bestDay != null ||
                              history.worstDay != null) ...[
                            PHSectionLabel(label: 'Day Highlights'),
                            const SizedBox(height: 12),
                            if (history.bestDay != null)
                              PHHighlightCard(
                                label: '🏆 Best Day',
                                dateLabel: history.bestDay!.formattedDate,
                                points: history.bestDay!.value,
                                tasksCompleted:
                                history.bestDay!.tasksCompleted,
                                icon: Icons.trending_up_rounded,
                                color: const Color(0xFF10B981),
                              ),
                            if (history.bestDay != null &&
                                history.worstDay != null)
                              const SizedBox(height: 10),
                            if (history.worstDay != null)
                              PHHighlightCard(
                                label: '📉 Worst Day',
                                dateLabel: history.worstDay!.formattedDate,
                                points: history.worstDay!.value,
                                tasksCompleted:
                                history.worstDay!.tasksCompleted,
                                icon: Icons.trending_down_rounded,
                                color: const Color(0xFFEF4444),
                              ),
                            const SizedBox(height: 24),
                          ],

                          // ── 7. Points vs Activity Scatter ─────
                          PHSectionLabel(label: 'Day-by-Day Breakdown'),
                          const SizedBox(height: 12),
                          _DayByDayBars(
                            dailyStats: history.dailyStats,
                            maxPoints: maxPoints,
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

  String _trendSubtitle(String trend, double avg) {
    final isUp = trend.toLowerCase() == 'improving';
    final isDown = trend.toLowerCase() == 'declining';
    if (isUp) return 'Great momentum! Avg daily progress: ${avg.toStringAsFixed(1)}%';
    if (isDown) return 'Let\'s push harder. Avg daily progress: ${avg.toStringAsFixed(1)}%';
    return 'Consistent performance. Avg daily progress: ${avg.toStringAsFixed(1)}%';
  }
}

// ================================================================
// HERO HEADER
// ================================================================

class _Prog30HeroHeader extends StatelessWidget {
  final ProgressHistory history;
  final int totalPoints, maxPoints, activeDays;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _Prog30HeroHeader({
    required this.history,
    required this.totalPoints,
    required this.maxPoints,
    required this.activeDays,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = history.trend.toLowerCase() == 'improving';
    final isDown = history.trend.toLowerCase() == 'declining';
    final c1 = isUp
        ? const Color(0xFF10B981)
        : isDown
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);
    final c2 = isUp
        ? const Color(0xFF34D399)
        : isDown
        ? const Color(0xFFFB923C)
        : const Color(0xFF8B5CF6);

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
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('30-Day Progress',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8)
                                  ])),
                          const SizedBox(height: 3),
                          Text('Your daily performance over 30 days',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.72))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(history.trendIcon,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          history.trend.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      PHHeroStat(
                          value: totalPoints.toString(),
                          label: 'Total Pts',
                          icon: '⭐'),
                      const PHHeroDiv(),
                      PHHeroStat(
                          value: '$activeDays',
                          label: 'Active Days',
                          icon: '📅'),
                      const PHHeroDiv(),
                      PHHeroStat(
                          value: maxPoints.toString(),
                          label: 'Best Day',
                          icon: '🔝'),
                      const PHHeroDiv(),
                      PHHeroStat(
                          value:
                          '${history.averageProgress.toStringAsFixed(0)}%',
                          label: 'Avg Progress',
                          icon: '📊'),
                    ]),
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
// ACTIVITY RATE CARD
// ================================================================

class _ActivityRateCard extends StatelessWidget {
  final int activeDays, totalDays;
  final ThemeData theme;
  final bool isDark;

  const _ActivityRateCard({
    required this.activeDays,
    required this.totalDays,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction =
    totalDays > 0 ? activeDays / totalDays : 0.0;
    const color = Color(0xFF3B82F6);

    return PHCardShell(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Text('📅', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text('Activity Rate',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            Text(
              '$activeDays / $totalDays days',
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: color),
            ),
          ]),
          const SizedBox(height: 12),
          // Circular indicator + bar
          Row(children: [
            AdvancedProgressIndicator(
              progress: fraction.clamp(0.0, 1.0),
              size: 80,
              strokeWidth: 8,
              shape: ProgressShape.circular,
              gradientColors: [color, color.withOpacity(0.5)],
              backgroundColor: color.withOpacity(0.1),
              labelStyle: ProgressLabelStyle.custom,
              customLabel: '${(fraction * 100).toStringAsFixed(0)}%',
              labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900, color: color),
              showGlow: fraction > 0.7,
              glowRadius: 6,
              animationDuration: const Duration(milliseconds: 1400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fraction >= 0.8
                        ? 'Excellent consistency! 🔥'
                        : fraction >= 0.6
                        ? 'Good effort, keep pushing!'
                        : 'Room to improve — stay consistent!',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.65),
                        height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  CustomProgressIndicator(
                    progress: fraction.clamp(0.0, 1.0),
                    progressBarName: 'Active days rate',
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
                    nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontSize: 9),
                    animateNameLabel: true,
                    animationDuration: const Duration(milliseconds: 1300),
                    animationCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ================================================================
// DAY-BY-DAY BARS  (compact vertical bar chart)
// ================================================================

class _DayByDayBars extends StatelessWidget {
  final List<DailyStatPoint> dailyStats;
  final int maxPoints;
  final ThemeData theme;
  final bool isDark;

  const _DayByDayBars({
    required this.dailyStats,
    required this.maxPoints,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = maxPoints == 0 ? 1 : maxPoints;

    return PHCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Daily Points Distribution',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('${dailyStats.length} days',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ]),
          const SizedBox(height: 14),
          // Color legend
          Row(children: [
            _LegendDot(color: const Color(0xFF3B82F6)),
            const SizedBox(width: 4),
            Text('Active',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55))),
            const SizedBox(width: 12),
            _LegendDot(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade300),
            const SizedBox(width: 4),
            Text('No Activity',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55))),
          ]),
          const SizedBox(height: 12),
          // Vertical mini bars
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyStats.map((d) {
                final frac = d.points / safeMax;
                final color = d.points > 0
                    ? const Color(0xFF3B82F6)
                    : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 70 * frac + (d.points > 0 ? 6 : 3),
                          decoration: BoxDecoration(
                            gradient: d.points > 0
                                ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF3B82F6),
                                const Color(0xFF3B82F6)
                                    .withOpacity(0.6),
                              ],
                            )
                                : null,
                            color: d.points > 0 ? null : color,
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
          const SizedBox(height: 8),
          // Date label at start and end
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              dailyStats.isNotEmpty ? dailyStats.first.shortDate : '',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withOpacity(0.45)),
            ),
            Text(
              dailyStats.isNotEmpty ? dailyStats.last.shortDate : '',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withOpacity(0.45)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
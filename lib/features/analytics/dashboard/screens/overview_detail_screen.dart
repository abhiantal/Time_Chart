// ================================================================
// FILE: overview_detail_screen.dart
// OVERVIEW DETAIL SCREEN — Full DashboardOverview Statistics
// NO overview_widgets.dart dependency
// Uses: CustomProgressIndicator + AdvancedProgressIndicator
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Data + provider ─────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class OverviewDetailScreen extends StatefulWidget {
  const OverviewDetailScreen({super.key});

  @override
  State<OverviewDetailScreen> createState() => _OverviewDetailScreenState();
}

class _OverviewDetailScreenState extends State<OverviewDetailScreen>
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
        vsync: this, duration: const Duration(milliseconds: 800));

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
          if (!provider.hasData) return const OverviewCardSkeleton();
          final ov = provider.overview;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ─────────────────────────────────
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
                  background: _HeroHeader(
                    summary: ov.summary,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('Overview',
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
                          // ── 1. Completion Rate Circles ───────
                          _SectionLabel(label: 'Completion Rates'),
                          const SizedBox(height: 12),
                          _CompletionRateCircles(
                              summary: ov.summary,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 2. Points Breakdown Bars ─────────
                          _SectionLabel(label: 'Points Breakdown'),
                          const SizedBox(height: 12),
                          _PointsBreakdownBars(
                              summary: ov.summary,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 3. Streaks Arc Indicators ────────
                          _SectionLabel(label: 'Streaks & Performance'),
                          const SizedBox(height: 12),
                          _StreakArcCard(
                              summary: ov.summary,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 4. Daily Tasks ────────────────────
                          _SectionLabel(label: 'Daily Tasks'),
                          const SizedBox(height: 12),
                          _DailyTasksCard(
                              stats: ov.dailyTasksStats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 5. Weekly Tasks ───────────────────
                          _SectionLabel(label: 'Weekly Tasks'),
                          const SizedBox(height: 12),
                          _WeeklyTasksCard(
                              stats: ov.weeklyTasksStats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 6. Long Goals ─────────────────────
                          _SectionLabel(label: 'Long Goals'),
                          const SizedBox(height: 12),
                          _LongGoalsCard(
                              stats: ov.longGoalsStats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 7. Bucket List ────────────────────
                          _SectionLabel(label: 'Bucket List'),
                          const SizedBox(height: 12),
                          _BucketListCard(
                              stats: ov.bucketListStats,
                              theme: theme,
                              isDark: isDark),
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

class _HeroHeader extends StatelessWidget {
  final DashboardSummary summary;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _HeroHeader({
    required this.summary,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1F3C), const Color(0xFF0F172A)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
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
                            Text('Overview Statistics',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 3),
                            Text('Your all-time performance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.65))),
                          ],
                        ),
                      ),
                      // Rank badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text(summary.rankLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Quick stats strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                            value: summary.totalPoints.toString(),
                            label: 'Total Pts',
                            icon: '⭐'),
                        _HeroStatDivider(),
                        _HeroStat(
                            value: '${summary.currentStreak}d',
                            label: 'Streak',
                            icon: summary.streakEmoji),
                        _HeroStatDivider(),
                        _HeroStat(
                            value: summary.totalRewards.toString(),
                            label: 'Rewards',
                            icon: '🎁'),
                        _HeroStatDivider(),
                        _HeroStat(
                            value:
                            '${summary.averageRating.toStringAsFixed(1)}★',
                            label: 'Avg Rating',
                            icon: '📊'),
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

class _HeroStat extends StatelessWidget {
  final String value, label, icon;
  const _HeroStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HeroStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.2));
}

// ================================================================
// SECTION LABEL
// ================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ],
    );
  }
}

// ================================================================
// SHARED CARD SHELL
// ================================================================

class _CardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final ThemeData theme;
  final Color? accentColor;

  const _CardShell({
    required this.child,
    required this.isDark,
    required this.theme,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.18))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// 1. COMPLETION RATE CIRCLES  (AdvancedProgressIndicator circular)
// ================================================================

class _CompletionRateCircles extends StatelessWidget {
  final DashboardSummary summary;
  final ThemeData theme;
  final bool isDark;

  const _CompletionRateCircles(
      {required this.summary, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rates = [
      _CircleData(
        label: 'Today',
        icon: '☀️',
        value: summary.completionRateToday / 100,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      ),
      _CircleData(
        label: 'This Week',
        icon: '📅',
        value: summary.completionRateWeek / 100,
        gradient: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      ),
      _CircleData(
        label: 'All Time',
        icon: '🌟',
        value: summary.completionRateAll / 100,
        gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
      ),
    ];

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rates.map((r) {
          return Column(
            children: [
              AdvancedProgressIndicator(
                progress: r.value.clamp(0.0, 1.0),
                size: 88,
                strokeWidth: 9,
                shape: ProgressShape.circular,
                gradientColors: r.gradient,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade200,
                labelStyle: ProgressLabelStyle.percentage,
                labelTextStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: r.gradient.first),
                showGlow: true,
                glowRadius: 6,
                animationDuration: const Duration(milliseconds: 1400),
                animationCurve: Curves.easeOutCubic,
              ),
              const SizedBox(height: 6),
              Text(r.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(r.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CircleData {
  final String label, icon;
  final double value;
  final List<Color> gradient;
  const _CircleData({
    required this.label,
    required this.icon,
    required this.value,
    required this.gradient,
  });
}

// ================================================================
// 2. POINTS BREAKDOWN BARS  (CustomProgressIndicator horizontal)
// ================================================================

class _PointsBreakdownBars extends StatelessWidget {
  final DashboardSummary summary;
  final ThemeData theme;
  final bool isDark;

  const _PointsBreakdownBars(
      {required this.summary, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxPts = [
      summary.dailyTasksPoints,
      summary.weeklyTasksPoints,
      summary.longGoalsPoints,
      summary.bucketListPoints,
    ].fold<int>(1, (a, b) => b > a ? b : a);

    final bars = [
      _BarData(
        label: 'Daily Tasks',
        emoji: '✅',
        points: summary.dailyTasksPoints,
        fraction: summary.dailyTasksPoints / maxPts,
        gradient: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
        color: const Color(0xFF3B82F6),
      ),
      _BarData(
        label: 'Weekly Tasks',
        emoji: '📅',
        points: summary.weeklyTasksPoints,
        fraction: summary.weeklyTasksPoints / maxPts,
        gradient: [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
        color: const Color(0xFF8B5CF6),
      ),
      _BarData(
        label: 'Long Goals',
        emoji: '🎯',
        points: summary.longGoalsPoints,
        fraction: summary.longGoalsPoints / maxPts,
        gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
        color: const Color(0xFF10B981),
      ),
      _BarData(
        label: 'Bucket List',
        emoji: '🎁',
        points: summary.bucketListPoints,
        fraction: summary.bucketListPoints / maxPts,
        gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
        color: const Color(0xFFF59E0B),
      ),
    ];

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Points',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(summary.totalPoints.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF667EEA))),
            ],
          ),
          const SizedBox(height: 14),
          ...bars.map((b) =>
              _PointsBarRow(bar: b, theme: theme, isDark: isDark)),
          const Divider(height: 20),
          // Today / Week chips
          Row(
            children: [
              _SmallChip(
                label: 'Today',
                value: '+${summary.pointsToday}',
                color: const Color(0xFF10B981),
                theme: theme,
              ),
              const SizedBox(width: 10),
              _SmallChip(
                label: 'This Week',
                value: '+${summary.pointsThisWeek}',
                color: const Color(0xFF3B82F6),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label, emoji;
  final int points;
  final double fraction;
  final List<Color> gradient;
  final Color color;
  const _BarData({
    required this.label,
    required this.emoji,
    required this.points,
    required this.fraction,
    required this.gradient,
    required this.color,
  });
}

class _PointsBarRow extends StatelessWidget {
  final _BarData bar;
  final ThemeData theme;
  final bool isDark;

  const _PointsBarRow(
      {required this.bar, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(bar.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(bar.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.75))),
              ]),
              Text(bar.points.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: bar.color)),
            ],
          ),
          const SizedBox(height: 6),
          CustomProgressIndicator(
            progress: bar.fraction.clamp(0.0, 1.0),
            progressBarName: '',
            orientation: ProgressOrientation.horizontal,
            baseHeight: 10,
            maxHeightIncrease: 4,
            gradientColors: bar.gradient,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.grey.shade200,
            borderRadius: 8,
            progressLabelDisplay: ProgressLabelDisplay.none,
            nameLabelPosition: LabelPosition.bottom,
            animateNameLabel: false,
            animationDuration: const Duration(milliseconds: 1200),
            animationCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;

  const _SmallChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color.withOpacity(0.7))),
          TextSpan(
              text: value,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

// ================================================================
// 3. STREAKS  (AdvancedProgressIndicator arc)
// ================================================================

class _StreakArcCard extends StatelessWidget {
  final DashboardSummary summary;
  final ThemeData theme;
  final bool isDark;

  const _StreakArcCard(
      {required this.summary, required this.theme, required this.isDark});

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final maxStreak =
    summary.longestStreak == 0 ? 1 : summary.longestStreak;
    final currentFraction =
    (summary.currentStreak / maxStreak).clamp(0.0, 1.0);

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: const Color(0xFFFF6B35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current streak arc
          AdvancedProgressIndicator(
            progress: currentFraction,
            size: 114,
            strokeWidth: 11,
            shape: ProgressShape.arc,
            arcStartAngle: 180,
            arcSweepAngle: 180,
            gradientColors: const [Color(0xFFFF6B35), Color(0xFFFFA500)],
            backgroundColor: Colors.orange.withOpacity(0.12),
            labelStyle: ProgressLabelStyle.custom,
            customLabel: '${summary.currentStreak}d',
            labelTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF6B35)),
            showGlow: true,
            glowRadius: 8,
            animationDuration: const Duration(milliseconds: 1400),
            name: '🔥 Current Streak',
            namePosition: ProgressLabelPosition.bottom,
            nameTextStyle: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          // Right column: metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(
                  icon: '⚡',
                  label: 'Longest Streak',
                  value: '${summary.longestStreak} days',
                  valueColor: const Color(0xFFFFA500),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  icon: '🏆',
                  label: 'Best Tier',
                  value:
                  '${summary.bestTierEmoji} ${_cap(summary.bestTierAchieved)}',
                  valueColor: summary.bestTierColor,
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  icon: '📈',
                  label: 'Avg Progress',
                  value: '${summary.averageProgress}%',
                  valueColor: const Color(0xFF667EEA),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  icon: '⭐',
                  label: 'Avg Rating',
                  value: '${summary.averageRating.toStringAsFixed(2)}★',
                  valueColor: const Color(0xFF10B981),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  icon: '🌐',
                  label: 'Global Rank',
                  value: summary.rankLabel,
                  valueColor: const Color(0xFF3B82F6),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  icon: '🎁',
                  label: 'Total Rewards',
                  value: summary.totalRewards.toString(),
                  valueColor: const Color(0xFFF59E0B),
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

class _MetricRow extends StatelessWidget {
  final String icon, label, value;
  final Color valueColor;
  final ThemeData theme;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 9)),
              Text(value,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: valueColor)),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// 4. DAILY TASKS CARD
// ================================================================

class _DailyTasksCard extends StatelessWidget {
  final DailyTasksStats stats;
  final ThemeData theme;
  final bool isDark;

  const _DailyTasksCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF3B82F6);
    final completionVal = stats.totalDayTasks == 0
        ? 0.0
        : stats.dayTasksCompleted / stats.totalDayTasks;

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskCardHeader(
            emoji: '✅',
            title: 'Daily Tasks',
            total: stats.totalDayTasks,
            totalPoints: stats.totalDayTasksPoints,
            pointsColor: color,
            theme: theme,
          ),
          const SizedBox(height: 14),
          // Circular + stat tiles
          Row(
            children: [
              AdvancedProgressIndicator(
                progress: completionVal.clamp(0.0, 1.0),
                size: 92,
                strokeWidth: 9,
                shape: ProgressShape.circular,
                gradientColors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                backgroundColor: color.withOpacity(0.1),
                labelStyle: ProgressLabelStyle.percentage,
                labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: color),
                showGlow: true,
                glowRadius: 5,
                name: 'Completion',
                namePosition: ProgressLabelPosition.bottom,
                nameTextStyle: theme.textTheme.labelSmall
                    ?.copyWith(color: color.withOpacity(0.7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Completed',
                              value: stats.dayTasksCompleted.toString(),
                              color: const Color(0xFF10B981),
                              theme: theme,
                              isDark: isDark)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatTile(
                              label: 'Not Done',
                              value: stats.dayTasksNotCompleted.toString(),
                              color: const Color(0xFFEF4444),
                              theme: theme,
                              isDark: isDark)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Avg Rating',
                              value:
                              '${stats.dayTasksCompletionRating.toStringAsFixed(1)}★',
                              color: const Color(0xFFFFA500),
                              theme: theme,
                              isDark: isDark)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatTile(
                              label: 'Progress',
                              value: '${stats.totalDayTasksProgress}%',
                              color: const Color(0xFF667EEA),
                              theme: theme,
                              isDark: isDark)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RateBarRow(
            label: "Today's Rate",
            emoji: '☀️',
            value: (stats.completionRateToday / 100).clamp(0.0, 1.0),
            gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _RateBarRow(
            label: 'All-Time Rate',
            emoji: '🌟',
            value: (stats.dayTasksCompletionRate / 100).clamp(0.0, 1.0),
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 5. WEEKLY TASKS CARD
// ================================================================

class _WeeklyTasksCard extends StatelessWidget {
  final WeeklyTasksStats stats;
  final ThemeData theme;
  final bool isDark;

  const _WeeklyTasksCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8B5CF6);
    final completionVal = stats.totalWeekTasks == 0
        ? 0.0
        : stats.weekTasksCompleted / stats.totalWeekTasks;

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskCardHeader(
            emoji: '📅',
            title: 'Weekly Tasks',
            total: stats.totalWeekTasks,
            totalPoints: stats.totalWeekTasksPoints,
            pointsColor: color,
            theme: theme,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AdvancedProgressIndicator(
                progress: completionVal.clamp(0.0, 1.0),
                size: 92,
                strokeWidth: 9,
                shape: ProgressShape.circular,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                backgroundColor: color.withOpacity(0.1),
                labelStyle: ProgressLabelStyle.percentage,
                labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: color),
                showGlow: true,
                glowRadius: 5,
                name: 'Completion',
                namePosition: ProgressLabelPosition.bottom,
                nameTextStyle: theme.textTheme.labelSmall
                    ?.copyWith(color: color.withOpacity(0.7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Completed',
                              value: stats.weekTasksCompleted.toString(),
                              color: const Color(0xFF10B981),
                              theme: theme,
                              isDark: isDark)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatTile(
                              label: 'Not Done',
                              value: stats.weekTasksNotCompleted.toString(),
                              color: const Color(0xFFEF4444),
                              theme: theme,
                              isDark: isDark)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Avg Rating',
                              value:
                              '${stats.weekTasksCompletionRating.toStringAsFixed(1)}★',
                              color: const Color(0xFFFFA500),
                              theme: theme,
                              isDark: isDark)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatTile(
                              label: 'Progress',
                              value: '${stats.totalWeekTasksProgress}%',
                              color: const Color(0xFF667EEA),
                              theme: theme,
                              isDark: isDark)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RateBarRow(
            label: 'Completion Rate',
            emoji: '📊',
            value: (stats.weekTasksCompletionRate / 100).clamp(0.0, 1.0),
            gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 6. LONG GOALS CARD
// ================================================================

class _LongGoalsCard extends StatelessWidget {
  final LongGoalsStats stats;
  final ThemeData theme;
  final bool isDark;

  const _LongGoalsCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF10B981);

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskCardHeader(
            emoji: '🎯',
            title: 'Long Goals',
            total: stats.totalLongGoals,
            totalPoints: stats.totalLongGoalsPoints,
            pointsColor: color,
            theme: theme,
          ),
          const SizedBox(height: 16),
          // 3 arc indicators: Active / Completed / Not Started
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GoalArcItem(
                label: 'Active',
                count: stats.longGoalsActive,
                total: stats.totalLongGoals,
                gradient: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                theme: theme,
                isDark: isDark,
              ),
              _GoalArcItem(
                label: 'Completed',
                count: stats.longGoalsCompleted,
                total: stats.totalLongGoals,
                gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                theme: theme,
                isDark: isDark,
              ),
              _GoalArcItem(
                label: 'Not Started',
                count: stats.longGoalsNotStarted,
                total: stats.totalLongGoals,
                gradient: const [Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RateBarRow(
            label: 'Avg Goal Progress',
            emoji: '📈',
            value: stats.longGoalsAverageProgress.clamp(0.0, 1.0),
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _RateBarRow(
            label: 'Completion Rate',
            emoji: '✅',
            value: (stats.longGoalsCompletionRate / 100).clamp(0.0, 1.0),
            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _StatTile(
                    label: 'Avg Rating',
                    value:
                    '${stats.longGoalsCompletionRating.toStringAsFixed(1)}★',
                    color: const Color(0xFFFFA500),
                    theme: theme,
                    isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatTile(
                    label: 'Total Progress',
                    value:
                    '${stats.totalLongGoalsProgress.toStringAsFixed(1)}%',
                    color: color,
                    theme: theme,
                    isDark: isDark)),
          ]),
        ],
      ),
    );
  }
}

class _GoalArcItem extends StatelessWidget {
  final String label;
  final int count, total;
  final List<Color> gradient;
  final ThemeData theme;
  final bool isDark;

  const _GoalArcItem({
    required this.label,
    required this.count,
    required this.total,
    required this.gradient,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Column(
      children: [
        AdvancedProgressIndicator(
          progress: fraction,
          size: 76,
          strokeWidth: 8,
          shape: ProgressShape.arc,
          arcStartAngle: 180,
          arcSweepAngle: 180,
          gradientColors: gradient,
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.shade200,
          labelStyle: ProgressLabelStyle.custom,
          customLabel: count.toString(),
          labelTextStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900, color: gradient.first),
          animationDuration: const Duration(milliseconds: 1300),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55))),
      ],
    );
  }
}

// ================================================================
// 7. BUCKET LIST CARD
// ================================================================

class _BucketListCard extends StatelessWidget {
  final BucketListStats stats;
  final ThemeData theme;
  final bool isDark;

  const _BucketListCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF59E0B);
    final total = stats.totalBucketItems == 0 ? 1 : stats.totalBucketItems;

    final segments = [
      _BucketSeg(
          label: 'Completed',
          count: stats.bucketItemsCompleted,
          fraction: stats.bucketItemsCompleted / total,
          gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
          color: const Color(0xFF10B981)),
      _BucketSeg(
          label: 'In Progress',
          count: stats.bucketItemsInProgress,
          fraction: stats.bucketItemsInProgress / total,
          gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
          color: const Color(0xFF4FACFE)),
      _BucketSeg(
          label: 'Not Started',
          count: stats.bucketItemsNotStarted,
          fraction: stats.bucketItemsNotStarted / total,
          gradient: [const Color(0xFFCFD8DC), const Color(0xFFB0BEC5)],
          color: const Color(0xFFCFD8DC)),
    ];

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskCardHeader(
            emoji: '🎁',
            title: 'Bucket List',
            total: stats.totalBucketItems,
            totalPoints: stats.totalBucketPoints,
            pointsColor: color,
            theme: theme,
          ),
          const SizedBox(height: 16),
          // Segmented bars using CustomProgressIndicator
          ...segments.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(s.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7))),
                    ]),
                    Text(s.count.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800, color: s.color)),
                  ],
                ),
                const SizedBox(height: 4),
                CustomProgressIndicator(
                  progress: s.fraction.clamp(0.0, 1.0),
                  progressBarName: '',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 8,
                  maxHeightIncrease: 3,
                  gradientColors: s.gradient,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: 6,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  animateNameLabel: false,
                  animationDuration: const Duration(milliseconds: 1300),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          )),
          const SizedBox(height: 4),
          _RateBarRow(
            label: 'Overall Completion',
            emoji: '🏁',
            value: (stats.bucketCompletionRate / 100).clamp(0.0, 1.0),
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _StatTile(
                    label: 'Avg Progress',
                    value:
                    '${(stats.bucketAverageProgress * 100).toStringAsFixed(1)}%',
                    color: color,
                    theme: theme,
                    isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatTile(
                    label: 'Avg Rating',
                    value:
                    '${stats.bucketCompletionRating.toStringAsFixed(1)}★',
                    color: const Color(0xFF8B5CF6),
                    theme: theme,
                    isDark: isDark)),
          ]),
        ],
      ),
    );
  }
}

class _BucketSeg {
  final String label;
  final int count;
  final double fraction;
  final List<Color> gradient;
  final Color color;
  const _BucketSeg({
    required this.label,
    required this.count,
    required this.fraction,
    required this.gradient,
    required this.color,
  });
}

// ================================================================
// SHARED SMALL WIDGETS
// ================================================================

class _TaskCardHeader extends StatelessWidget {
  final String emoji, title;
  final int total, totalPoints;
  final Color pointsColor;
  final ThemeData theme;

  const _TaskCardHeader({
    required this.emoji,
    required this.title,
    required this.total,
    required this.totalPoints,
    required this.pointsColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text('$total items total',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 10)),
          ]),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: pointsColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pointsColor.withOpacity(0.25)),
          ),
          child: Text('+$totalPoints pts',
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: pointsColor)),
        ),
      ],
    );
  }
}

class _RateBarRow extends StatelessWidget {
  final String label, emoji;
  final double value;
  final List<Color> gradient;
  final bool isDark;

  const _RateBarRow({
    required this.label,
    required this.emoji,
    required this.value,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65))),
            ]),
            Text('${(value * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: gradient.first)),
          ],
        ),
        const SizedBox(height: 5),
        CustomProgressIndicator(
          progress: value.clamp(0.0, 1.0),
          progressBarName: '',
          orientation: ProgressOrientation.horizontal,
          baseHeight: 9,
          maxHeightIncrease: 3,
          gradientColors: gradient,
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
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;
  final bool isDark;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
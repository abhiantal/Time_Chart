// ================================================================
// FILE: category_stats_detail_screen.dart
// CATEGORY STATS DETAIL SCREEN — Full CategoryStats data
// • NO category_widgets.dart dependency — all widgets inline
// • Imports: shared_widgets.dart
// • Uses: CustomProgressIndicator + AdvancedProgressIndicator
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/bar_progress_indicator.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';

// ── Shared reusable components ──────────────────────────────────
import '../widgets/shared_widgets.dart';

// ── Data + provider ─────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class CategoryStatsDetailScreen extends StatefulWidget {
  const CategoryStatsDetailScreen({super.key});

  @override
  State<CategoryStatsDetailScreen> createState() =>
      _CategoryStatsDetailScreenState();
}

class _CategoryStatsDetailScreenState extends State<CategoryStatsDetailScreen>
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
          if (!provider.hasData) {
            return const CategoryStatsCardSkeleton();
          }

          final stats = provider.categoryStats;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
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
                  background: _CategoryHeroHeader(
                    stats: stats,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('Categories',
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
                      child: stats.stats.isEmpty
                          ? _EmptyCategories(theme: theme)
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Summary Tiles ──────────
                          _SectionLabel(label: 'Summary'),
                          const SizedBox(height: 12),
                          _SummaryTilesRow(
                              stats: stats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 2. Top Category Spotlight ─
                          _SectionLabel(label: 'Top Category'),
                          const SizedBox(height: 12),
                          _TopCategorySpotlight(
                              stats: stats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 3. Points Distribution Bars
                          _SectionLabel(
                              label: 'Points Distribution'),
                          const SizedBox(height: 12),
                          _PointsDistributionCard(
                              stats: stats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 4. Completion Rate Arcs ───
                          _SectionLabel(
                              label: 'Completion Rates'),
                          const SizedBox(height: 12),
                          _CompletionRateArcsCard(
                              stats: stats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 5. Category Grid ──────────
                          _SectionLabel(
                              label: 'All Categories'),
                          const SizedBox(height: 12),
                          _CategoryGridCards(
                              stats: stats,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 6. Detailed List ──────────
                          _SectionLabel(
                              label: 'Detailed Breakdown'),
                          const SizedBox(height: 12),
                          _CategoryDetailedList(
                              stats: stats,
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

class _CategoryHeroHeader extends StatelessWidget {
  final CategoryStats stats;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _CategoryHeroHeader({
    required this.stats,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final avgCompletion = stats.stats.isEmpty
        ? 0.0
        : stats.stats.fold<double>(0, (s, e) => s + e.completionRate) /
        stats.stats.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F2027), const Color(0xFF203A43),
            const Color(0xFF2C5364)]
              : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
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
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category Statistics',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 3),
                            Text('Performance by category',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.65))),
                          ],
                        ),
                      ),
                      // Category count badge
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
                            const Text('🗂️',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Text('${stats.stats.length} Categories',
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
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                            value: stats.totalPoints.toString(),
                            label: 'Total Pts',
                            icon: '⭐'),
                        _HeroStatDivider(),
                        _HeroStat(
                            value: stats.stats.length.toString(),
                            label: 'Categories',
                            icon: '🗂️'),
                        _HeroStatDivider(),
                        _HeroStat(
                            value: stats.topCategory.isEmpty
                                ? '-'
                                : stats.topCategory,
                            label: 'Top Category',
                            icon: '🏆'),
                        _HeroStatDivider(),
                        _HeroStat(
                            value:
                            '${avgCompletion.toStringAsFixed(0)}%',
                            label: 'Avg Done',
                            icon: '✅'),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
// CARD SHELL
// ================================================================

class _CardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final ThemeData theme;
  final Color? accentColor;
  final EdgeInsets? padding;

  const _CardShell({
    required this.child,
    required this.isDark,
    required this.theme,
    this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
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
// EMPTY STATE
// ================================================================

class _EmptyCategories extends StatelessWidget {
  final ThemeData theme;
  const _EmptyCategories({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: EmptyStateWidget(
        icon: Icons.category_rounded,
        title: 'No Categories Yet',
        subtitle:
        'Create tasks in different categories to see your stats here',
      ),
    );
  }
}

// ================================================================
// 1. SUMMARY TILES ROW
// ================================================================

class _SummaryTilesRow extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _SummaryTilesRow(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final avgCompletion = stats.stats.isEmpty
        ? 0.0
        : stats.stats.fold<double>(0, (s, e) => s + e.completionRate) /
        stats.stats.length;

    final totalTasks = stats.stats
        .fold<int>(0, (s, e) => s + e.totalTasks);
    final totalCompleted = stats.stats
        .fold<int>(0, (s, e) => s + e.tasksCompleted);

    final tiles = [
      _TileData(
          icon: Icons.category_rounded,
          label: 'Categories',
          value: stats.stats.length.toString(),
          color: const Color(0xFF667EEA)),
      _TileData(
          icon: Icons.star_rounded,
          label: 'Total Points',
          value: stats.totalPoints.toString(),
          color: const Color(0xFFF59E0B)),
      _TileData(
          icon: Icons.check_circle_rounded,
          label: 'Tasks Done',
          value: '$totalCompleted/$totalTasks',
          color: const Color(0xFF10B981)),
      _TileData(
          icon: Icons.trending_up_rounded,
          label: 'Avg Completion',
          value: '${avgCompletion.toStringAsFixed(1)}%',
          color: const Color(0xFF3B82F6)),
    ];

    return _CardShell(
      isDark: isDark,
      theme: theme,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        children: tiles.map((t) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.icon, color: t.color, size: 19),
                ),
                const SizedBox(height: 6),
                Text(t.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: t.color)),
                Text(t.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                        fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String label, value;
  final Color color;
  const _TileData(
      {required this.icon,
        required this.label,
        required this.value,
        required this.color});
}

// ================================================================
// 2. TOP CATEGORY SPOTLIGHT
// ================================================================

class _TopCategorySpotlight extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _TopCategorySpotlight(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top =
    stats.stats.reduce((a, b) => a.points > b.points ? a : b);
    final share = stats.totalPoints > 0
        ? (top.points / stats.totalPoints) * 100
        : 0.0;
    final color = top.displayColor;
    final completionFraction = (top.completionRate / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.25 : 0.18),
            color.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(top.icon,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('👑 Top Category',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(top.categoryName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${top.points}',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900, color: color)),
                  Text('points',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: color.withOpacity(0.7))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                  child: _SpotlightStat(
                      label: 'Tasks Done',
                      value: '${top.tasksCompleted}/${top.totalTasks}',
                      color: color,
                      theme: theme)),
              Expanded(
                  child: _SpotlightStat(
                      label: 'Points Share',
                      value: '${share.toStringAsFixed(1)}%',
                      color: color,
                      theme: theme)),
              Expanded(
                  child: _SpotlightStat(
                      label: 'Completion',
                      value: '${top.completionRate.toStringAsFixed(1)}%',
                      color: color,
                      theme: theme)),
            ],
          ),
          const SizedBox(height: 14),

          // Completion arc + bar side by side
          Row(
            children: [
              // Arc indicator
              AdvancedProgressIndicator(
                progress: completionFraction,
                size: 80,
                strokeWidth: 8,
                shape: ProgressShape.arc,
                arcStartAngle: 180,
                arcSweepAngle: 180,
                gradientColors: [color, color.withOpacity(0.5)],
                backgroundColor: color.withOpacity(0.12),
                labelStyle: ProgressLabelStyle.custom,
                customLabel:
                '${top.completionRate.toStringAsFixed(0)}%',
                labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: color),
                animationDuration: const Duration(milliseconds: 1300),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completion Rate',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6))),
                    const SizedBox(height: 6),
                    CustomProgressIndicator(
                      progress: completionFraction,
                      progressBarName: '',
                      orientation: ProgressOrientation.horizontal,
                      baseHeight: 11,
                      maxHeightIncrease: 4,
                      gradientColors: [color, color.withOpacity(0.6)],
                      backgroundColor: color.withOpacity(0.1),
                      borderRadius: 8,
                      progressLabelDisplay:
                      ProgressLabelDisplay.bubble,
                      progressLabelBackgroundColor: color,
                      nameLabelPosition: LabelPosition.bottom,
                      animateNameLabel: false,
                      animationDuration:
                      const Duration(milliseconds: 1300),
                      animationCurve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;

  const _SpotlightStat(
      {required this.label,
        required this.value,
        required this.color,
        required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 9)),
      ],
    );
  }
}

// ================================================================
// 3. POINTS DISTRIBUTION BARS  (CustomProgressIndicator)
// ================================================================

class _PointsDistributionCard extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _PointsDistributionCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxPts =
    stats.stats.fold<int>(1, (m, e) => e.points > m ? e.points : m);
    final sorted = List<CategoryStatItem>.from(stats.stats)
      ..sort((a, b) => b.points.compareTo(a.points));

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('⭐', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text('Points by Category',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              Text(stats.totalPoints.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.map((cat) {
            final fraction = maxPts == 0
                ? 0.0
                : (cat.points / maxPts).clamp(0.0, 1.0);
            final color = cat.displayColor;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Text(cat.icon,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(cat.categoryName,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.75))),
                      ]),
                      Row(children: [
                        Text(cat.points.toString(),
                            style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color)),
                        const SizedBox(width: 4),
                        Text(
                          stats.totalPoints > 0
                              ? '(${(cat.points / stats.totalPoints * 100).toStringAsFixed(0)}%)'
                              : '',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4)),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomProgressIndicator(
                    progress: fraction,
                    progressBarName: '',
                    orientation: ProgressOrientation.horizontal,
                    baseHeight: 10,
                    maxHeightIncrease: 4,
                    gradientColors: [
                      color,
                      color.withOpacity(0.55)
                    ],
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.07)
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
      ),
    );
  }
}

// ================================================================
// 4. COMPLETION RATE ARCS  (AdvancedProgressIndicator circular)
// ================================================================

class _CompletionRateArcsCard extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _CompletionRateArcsCard(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = List<CategoryStatItem>.from(stats.stats)
      ..sort((a, b) => b.completionRate.compareTo(a.completionRate));

    // Show max 6 in this row-wrap section
    final display = sorted.take(6).toList();

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📈', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text('Completion by Category',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: display.map((cat) {
              final fraction =
              (cat.completionRate / 100).clamp(0.0, 1.0);
              final color = cat.displayColor;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 3,
                child: Column(
                  children: [
                    AdvancedProgressIndicator(
                      progress: fraction,
                      size: 76,
                      strokeWidth: 7,
                      shape: ProgressShape.circular,
                      gradientColors: [
                        color,
                        color.withOpacity(0.5)
                      ],
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.grey.shade200,
                      labelStyle: ProgressLabelStyle.percentage,
                      labelTextStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color),
                      showGlow: true,
                      glowRadius: 5,
                      animationDuration:
                      const Duration(milliseconds: 1300),
                      animationCurve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: 5),
                    Text(cat.icon,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(cat.categoryName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                            fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 5. CATEGORY GRID CARDS
// ================================================================

class _CategoryGridCards extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _CategoryGridCards(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = List<CategoryStatItem>.from(stats.stats)
      ..sort((a, b) => b.points.compareTo(a.points));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final cat = sorted[i];
        final color = cat.displayColor;
        final fraction =
        (cat.completionRate / 100).clamp(0.0, 1.0);
        final rank = i + 1;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDark ? 0.22 : 0.14),
                color.withOpacity(isDark ? 0.08 : 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: emoji + rank badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat.icon,
                      style: const TextStyle(fontSize: 22)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank',
                      style: TextStyle(
                          fontSize: rank <= 3 ? 13 : 11,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Category name
              Text(cat.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${cat.tasksCompleted}/${cat.totalTasks} tasks',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10)),
              const Spacer(),
              // Progress bar
              CustomProgressIndicator(
                progress: fraction,
                progressBarName: '',
                orientation: ProgressOrientation.horizontal,
                baseHeight: 7,
                maxHeightIncrease: 2,
                gradientColors: [color, color.withOpacity(0.55)],
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade200,
                borderRadius: 6,
                progressLabelDisplay: ProgressLabelDisplay.none,
                nameLabelPosition: LabelPosition.bottom,
                animateNameLabel: false,
                animationDuration:
                const Duration(milliseconds: 1100),
                animationCurve: Curves.easeOutCubic,
              ),
              const SizedBox(height: 8),
              // Bottom: points + completion%
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('+${cat.points}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900, color: color)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${cat.completionRate.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 6. Detailed List ──────────────────────────

class _CategoryDetailedList extends StatelessWidget {
  final CategoryStats stats;
  final ThemeData theme;
  final bool isDark;

  const _CategoryDetailedList(
      {required this.stats, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = List<CategoryStatItem>.from(stats.stats)
      ..sort((a, b) => b.points.compareTo(a.points));

    return _CardShell(
      isDark: isDark,
      theme: theme,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          return Column(
            children: [
              // Header row for each item
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Text(cat.icon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.categoryName,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '${cat.tasksCompleted} / ${cat.totalTasks} tasks completed',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('+${cat.points}',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cat.displayColor)),
                        Text(
                          '${cat.completionRate.toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: cat.displayColor.withOpacity(0.75),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding:
                const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: CustomProgressIndicator(
                  progress:
                  (cat.completionRate / 100).clamp(0.0, 1.0),
                  progressBarName: '',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 8,
                  maxHeightIncrease: 3,
                  gradientColors: [
                    cat.displayColor,
                    cat.displayColor.withOpacity(0.5)
                  ],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: 7,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  animateNameLabel: false,
                  animationDuration:
                  const Duration(milliseconds: 1200),
                  animationCurve: Curves.easeOutCubic,
                ),
              ),
              if (i < sorted.length - 1)
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
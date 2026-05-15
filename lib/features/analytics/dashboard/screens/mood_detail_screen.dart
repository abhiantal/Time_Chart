// ================================================================
// FILE: mood_detail_screen.dart
// MOOD DETAIL SCREEN — Full emotional tracking data
// Uses: AdvancedProgressIndicator, CustomProgressIndicator,
//       MoodTrendChart (as-is), mood_streak_activity_widgets.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Dashboard widgets ────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/mood_streak_activity_widgets.dart';
import '../widgets/list_widgets.dart';
import '../widgets/streak_mood_widgets.dart'; // MoodTrendChart lives here

// ── Data + provider ─────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';
import '../../../../helpers/card_color_helper.dart';

// ================================================================
// SCREEN
// ================================================================

class MoodDetailScreen extends StatefulWidget {
  const MoodDetailScreen({super.key});

  @override
  State<MoodDetailScreen> createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen>
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
          if (!provider.hasData) return const MoodCardSkeleton();
          final mood = provider.mood;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
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
                  background: _MoodHeroHeader(
                    mood: mood,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('Mood Tracking',
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
                          // ── 1. Summary Strip ──────────────────
                          _SectionLabel(label: 'Overview'),
                          const SizedBox(height: 12),
                          MoodSummaryStrip(
                              mood: mood, theme: theme, isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 2. Average Circles ────────────────
                          _SectionLabel(label: 'Mood Averages'),
                          const SizedBox(height: 12),
                          MoodAverageCircles(
                            avg7d: mood.averageMoodLast7Days,
                            avg30d: mood.averageMoodLast30Days,
                            trend: mood.trend,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 3. MoodTrendChart (as-is) ─────────
                          _SectionLabel(label: 'Mood Trend Chart'),
                          const SizedBox(height: 12),
                          MoodTrendChart(
                            mood: mood,
                            maxPoints: 14,
                            showBackground: true,
                            showShadow: false,
                            showFrequency: false,
                          ),
                          const SizedBox(height: 24),

                          // ── 4. Frequency Bars ─────────────────
                          _SectionLabel(label: 'Mood Frequency'),
                          const SizedBox(height: 12),
                          MoodFrequencyBars(
                              moodFrequency: mood.moodFrequency),
                          const SizedBox(height: 24),

                          // ── 5. Rating Distribution ────────────
                          if (mood.moodHistory.isNotEmpty) ...[
                            _SectionLabel(label: 'Rating Distribution'),
                            const SizedBox(height: 12),
                            MoodRatingScaleBar(
                                history: mood.moodHistory,
                                theme: theme,
                                isDark: isDark),
                            const SizedBox(height: 24),
                          ],

                          // ── 6. Mood Streak Progress ───────────
                          _SectionLabel(label: 'Consistency'),
                          const SizedBox(height: 12),
                          _MoodConsistencyCard(
                              mood: mood, theme: theme, isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 7. Mood History List ──────────────
                          if (mood.moodHistory.isNotEmpty) ...[
                            _SectionLabel(
                                label:
                                'History (${mood.moodHistory.length} entries)'),
                            const SizedBox(height: 12),
                            _MoodHistorySection(
                                mood: mood, theme: theme, isDark: isDark),
                          ],
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

class _MoodHeroHeader extends StatelessWidget {
  final Mood mood;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _MoodHeroHeader({
    required this.mood,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  static String _moodEmoji(double v) {
    if (v >= 9) return '🤩';
    if (v >= 7.5) return '😄';
    if (v >= 6) return '😊';
    if (v >= 4.5) return '😐';
    if (v >= 3) return '😔';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    final avg = mood.averageMoodLast7Days;
    final moodColor = CardColorHelper.moodColorForValue(avg);
    final trendUp = mood.trend.toLowerCase() == 'improving';
    final trendDown = mood.trend.toLowerCase() == 'declining';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            Color.lerp(moodColor, const Color(0xFF0A0A14), 0.75)!,
            const Color(0xFF0A0A14),
          ]
              : [
            Color.lerp(moodColor, Colors.white, 0.1)!,
            Color.lerp(moodColor, Colors.white, 0.45)!,
          ],
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
                            Text('Mood Tracking',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                          color:
                                          Colors.black.withOpacity(0.25),
                                          blurRadius: 8)
                                    ])),
                            const SizedBox(height: 3),
                            Row(children: [
                              Icon(
                                trendUp
                                    ? Icons.trending_up_rounded
                                    : trendDown
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_flat_rounded,
                                size: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mood is ${mood.trend.isEmpty ? 'stable' : mood.trend}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                    Colors.white.withOpacity(0.75)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      // Current mood badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.35)),
                        ),
                        child: Column(
                          children: [
                            Text(_moodEmoji(avg),
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(avg.toStringAsFixed(1),
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                            Text('/10',
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                            value: mood.averageMoodLast7Days.toStringAsFixed(1),
                            label: '7-Day Avg',
                            icon: _moodEmoji(mood.averageMoodLast7Days)),
                        _HeroStatDiv(),
                        _HeroStat(
                            value: mood.averageMoodLast30Days
                                .toStringAsFixed(1),
                            label: '30-Day Avg',
                            icon: _moodEmoji(mood.averageMoodLast30Days)),
                        _HeroStatDiv(),
                        _HeroStat(
                            value: mood.moodHistory.length.toString(),
                            label: 'Entries',
                            icon: '📝'),
                        _HeroStatDiv(),
                        _HeroStat(
                            value: mood.moodFrequency.isNotEmpty
                                ? _capitalize(mood.moodFrequency.entries
                                .reduce((a, b) =>
                            a.value > b.value ? a : b)
                                .key)
                                : '-',
                            label: 'Most Common',
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

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _HeroStat extends StatelessWidget {
  final String value, label, icon;
  const _HeroStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _HeroStatDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.22));
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
          width: 3, height: 16,
          decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2)),
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
// MOOD CONSISTENCY CARD
// ================================================================

class _MoodConsistencyCard extends StatelessWidget {
  final Mood mood;
  final ThemeData theme;
  final bool isDark;

  const _MoodConsistencyCard(
      {required this.mood, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Days with mood entries in last 30 = rough consistency score
    final totalEntries = mood.moodHistory.length;
    final consistencyFraction = (totalEntries / 30).clamp(0.0, 1.0);
    final moodColor =
    CardColorHelper.moodColorForValue(mood.averageMoodLast7Days);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColor.withOpacity(isDark ? 0.22 : 0.14),
            moodColor.withOpacity(isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: moodColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Arc circle for consistency
          AdvancedProgressIndicator(
            progress: consistencyFraction,
            size: 100,
            strokeWidth: 9,
            shape: ProgressShape.circular,
            gradientColors: [moodColor, moodColor.withOpacity(0.5)],
            backgroundColor: moodColor.withOpacity(0.1),
            labelStyle: ProgressLabelStyle.custom,
            customLabel:
            '${(consistencyFraction * 100).toStringAsFixed(0)}%',
            labelTextStyle: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900, color: moodColor),
            showGlow: true,
            glowRadius: 7,
            animationDuration: const Duration(milliseconds: 1400),
            name: 'Logged',
            namePosition: ProgressLabelPosition.bottom,
            nameTextStyle: theme.textTheme.labelSmall?.copyWith(
                color: moodColor.withOpacity(0.7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood Logging\nConsistency',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _ConsistRow(
                    label: 'Total Entries',
                    value: totalEntries.toString(),
                    color: moodColor,
                    theme: theme),
                const SizedBox(height: 6),
                _ConsistRow(
                    label: 'Last 7d Avg',
                    value:
                    mood.averageMoodLast7Days.toStringAsFixed(1),
                    color: moodColor,
                    theme: theme),
                const SizedBox(height: 6),
                _ConsistRow(
                    label: 'Last 30d Avg',
                    value:
                    mood.averageMoodLast30Days.toStringAsFixed(1),
                    color: moodColor,
                    theme: theme),
                const SizedBox(height: 10),
                // Mini progress bar
                CustomProgressIndicator(
                  progress: consistencyFraction,
                  progressBarName: 'vs 30 entries',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 8,
                  maxHeightIncrease: 2,
                  gradientColors: [moodColor, moodColor.withOpacity(0.5)],
                  backgroundColor: moodColor.withOpacity(0.1),
                  borderRadius: 6,
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
        ],
      ),
    );
  }
}

class _ConsistRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;
  const _ConsistRow(
      {required this.label,
        required this.value,
        required this.color,
        required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55))),
        Text(value,
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

// ================================================================
// MOOD HISTORY SECTION
// ================================================================

class _MoodHistorySection extends StatefulWidget {
  final Mood mood;
  final ThemeData theme;
  final bool isDark;

  const _MoodHistorySection(
      {required this.mood, required this.theme, required this.isDark});

  @override
  State<_MoodHistorySection> createState() =>
      _MoodHistorySectionState();
}

class _MoodHistorySectionState extends State<_MoodHistorySection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final sorted = List<MoodDataPoint>.from(widget.mood.moodHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    final display = _showAll ? sorted : sorted.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.theme.colorScheme.surfaceContainerHighest
            : widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(widget.isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ...display.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  child: MoodHistoryItem(
                    date: m.date,
                    moodRating: m.value,
                    moodLabel: m.label,
                    showBackground: false,
                  ),
                ),
                if (i < display.length - 1)
                  Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: widget.theme.colorScheme.outline.withOpacity(0.08),
                  ),
              ],
            );
          }),
          // Show more / less
          if (sorted.length > 8)
            GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: widget.theme.colorScheme.outline
                            .withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAll
                          ? 'Show Less'
                          : 'Show All (${sorted.length})',
                      style: widget.theme.textTheme.labelMedium?.copyWith(
                          color: widget.theme.colorScheme.primary,
                          fontWeight: FontWeight.w700),
                    ),
                    Icon(
                      _showAll
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: widget.theme.colorScheme.primary,
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
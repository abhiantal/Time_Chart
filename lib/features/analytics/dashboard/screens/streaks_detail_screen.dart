// ================================================================
// FILE: streaks_detail_screen.dart
// STREAKS DETAIL SCREEN — Full consistency tracking data
// • NO progress_widgets.dart import
// • Uses: CustomProgressIndicator + AdvancedProgressIndicator
// • Keeps: StreakCalendarWidget (as-is), mood_streak_activity_widgets
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Dashboard widgets ────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/mood_streak_activity_widgets.dart';
// removed import
import '../widgets/streak_mood_widgets.dart'; // StreakCalendarWidget lives here

// ── Data + provider ──────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class StreaksDetailScreen extends StatefulWidget {
  const StreaksDetailScreen({super.key});

  @override
  State<StreaksDetailScreen> createState() => _StreaksDetailScreenState();
}

class _StreaksDetailScreenState extends State<StreaksDetailScreen>
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
          if (!provider.hasData) return const StreaksCardSkeleton();
          final streaks = provider.streaks;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 270,
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
                  background: _StreakHeroHeader(
                    streaks: streaks,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    'Streaks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // ── BODY ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Dual Streak Rings ───────────────
                          _SectionLabel(label: 'Streak Overview'),
                          const SizedBox(height: 12),
                          _DualStreakRingsCard(
                            streaks: streaks,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 2. Risk / Status Banner ────────────
                          if (streaks.isAtRisk || !streaks.isActive) ...[
                            _StreakStatusBanner(
                              streaks: streaks,
                              theme: theme,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── 3. Next Milestone Progress ─────────
                          _SectionLabel(label: 'Next Milestone'),
                          const SizedBox(height: 12),
                          _NextMilestoneCard(
                            streaks: streaks,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 4. Streak Stats Grid ───────────────
                          _SectionLabel(label: 'All-Time Stats'),

                          _StreakStatsGrid(
                            streaks: streaks,
                            theme: theme,
                            isDark: isDark,
                          ),

                          // ── 5. StreakCalendarWidget (as-is) ────
                          _SectionLabel(label: 'Activity Calendar'),

                        ],
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Calendar takes FULL WIDTH ─────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _bodyFade,
                  child: StreakCalendarWidget(streaks: provider.streaks),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 6. Longest Streak Detail ───────────
                          _SectionLabel(label: 'Longest Streak'),
                          const SizedBox(height: 12),
                          _LongestStreakDetailCard(
                            streaks: provider.streaks,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 7. Break Insights ──────────────────
                          _SectionLabel(label: 'Break Insights'),
                          const SizedBox(height: 12),
                          _BreakInsightsCard(
                            streaks: provider.streaks,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 8. Milestones Grid ─────────────────
                          _SectionLabel(
                            label:
                                'Milestones (${provider.streaks.milestones.length})',
                          ),
                          const SizedBox(height: 12),
                          StreakMilestonesGrid(
                            milestones: provider.streaks.milestones,
                            currentStreak: provider.streaks.currentDays,
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

class _StreakHeroHeader extends StatelessWidget {
  final Streaks streaks;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _StreakHeroHeader({
    required this.streaks,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = streaks.isActive;
    final current = streaks.currentDays;
    final fireColor = isActive
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(fireColor, const Color(0xFF0A0A14), 0.72)!,
                  const Color(0xFF0A0A14),
                ]
              : isActive
              ? [const Color(0xFFFF6B35), const Color(0xFFFF9A5C)]
              : [const Color(0xFF94A3B8), const Color(0xFFB0BEC5)],
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
                              'Streak Tracking',
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
                              isActive
                                  ? 'You\'re on fire! Keep going 🔥'
                                  : 'Start your streak today!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isActive ? '🔥' : '💤',
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Quick stats strip
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
                        _HStat(
                          value: '$current',
                          label: 'Current',
                          icon: streaks.streakEmoji,
                        ),
                        _HDiv(),
                        _HStat(
                          value: '${streaks.longestDays}',
                          label: 'Longest',
                          icon: '🏆',
                        ),
                        _HDiv(),
                        _HStat(
                          value: '${streaks.stats.totalActiveDaysAllTime}',
                          label: 'Total Days',
                          icon: '📅',
                        ),
                        _HDiv(),
                        _HStat(
                          value: streaks.nextMilestone.target > 0
                              ? '${streaks.nextMilestone.target}d'
                              : '✅',
                          label: 'Next Goal',
                          icon: '🎯',
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

class _HStat extends StatelessWidget {
  final String value, label, icon;
  const _HStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.22));
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
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
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
  final List<Color>? gradient;
  final EdgeInsets? padding;

  const _CardShell({
    required this.child,
    required this.isDark,
    required this.theme,
    this.accentColor,
    this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(18),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.22))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// 1. DUAL STREAK RINGS
// Two AdvancedProgressIndicator circular — current vs longest
// ================================================================

class _DualStreakRingsCard extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _DualStreakRingsCard({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fireColor = streaks.isActive
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);
    final longestColor = const Color(0xFF10B981);
    final maxDays = streaks.longestDays == 0 ? 1 : streaks.longestDays;
    final currentFraction = (streaks.currentDays / maxDays).clamp(0.0, 1.0);

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: fireColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Current streak
              Column(
                children: [
                  AdvancedProgressIndicator(
                    progress: currentFraction,
                    size: 118,
                    strokeWidth: 11,
                    shape: ProgressShape.circular,
                    gradientColors: [fireColor, fireColor.withOpacity(0.55)],
                    backgroundColor: fireColor.withOpacity(0.1),
                    labelStyle: ProgressLabelStyle.custom,
                    customLabel: '${streaks.currentDays}',
                    labelTextStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: fireColor,
                    ),
                    showGlow: streaks.isActive,
                    glowRadius: 12,
                    animationDuration: const Duration(milliseconds: 1500),
                    animationCurve: Curves.easeOutCubic,
                    name: streaks.streakEmoji,
                    namePosition: ProgressLabelPosition.bottom,
                    nameTextStyle: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Streak',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 120,
                color: theme.colorScheme.outline.withOpacity(0.15),
              ),

              // Longest streak
              Column(
                children: [
                  AdvancedProgressIndicator(
                    progress: 1.0,
                    size: 118,
                    strokeWidth: 11,
                    shape: ProgressShape.circular,
                    gradientColors: [
                      longestColor,
                      longestColor.withOpacity(0.55),
                    ],
                    backgroundColor: longestColor.withOpacity(0.1),
                    labelStyle: ProgressLabelStyle.custom,
                    customLabel: '${streaks.longestDays}',
                    labelTextStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: longestColor,
                    ),
                    showGlow: false,
                    animationDuration: const Duration(milliseconds: 1700),
                    animationCurve: Curves.easeOutCubic,
                    name: '🏆',
                    namePosition: ProgressLabelPosition.bottom,
                    nameTextStyle: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Longest Streak',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Progress bar: current vs longest
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current vs Longest',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${streaks.currentDays} / ${streaks.longestDays} days',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: fireColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomProgressIndicator(
                progress: currentFraction,
                progressBarName: '',
                orientation: ProgressOrientation.horizontal,
                baseHeight: 12,
                maxHeightIncrease: 4,
                gradientColors: [fireColor, fireColor.withOpacity(0.55)],
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade200,
                borderRadius: 8,
                progressLabelDisplay: ProgressLabelDisplay.bubble,
                progressLabelBackgroundColor: fireColor,
                nameLabelPosition: LabelPosition.bottom,
                animateNameLabel: false,
                animationDuration: const Duration(milliseconds: 1500),
                animationCurve: Curves.easeOutCubic,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 2. STREAK STATUS BANNER  (risk / inactive warning)
// ================================================================

class _StreakStatusBanner extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _StreakStatusBanner({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isAtRisk = streaks.isAtRisk;
    final color = isAtRisk ? const Color(0xFFEF4444) : const Color(0xFF94A3B8);
    final icon = isAtRisk ? '⚠️' : '💤';
    final title = isAtRisk ? 'Streak at Risk!' : 'Streak Inactive';
    final subtitle = isAtRisk
        ? (streaks.risk.hoursUntilBreak != null
              ? '${streaks.risk.hoursUntilBreak}h left — complete a task today!'
              : 'Your streak might break today!')
        : 'Complete a task to start a new streak.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isAtRisk && streaks.risk.hoursUntilBreak != null) ...[
            const SizedBox(width: 10),
            // Mini arc showing how much time is left today
            AdvancedProgressIndicator(
              progress: ((24 - (streaks.risk.hoursUntilBreak ?? 0)) / 24).clamp(
                0.0,
                1.0,
              ),
              size: 52,
              strokeWidth: 5,
              shape: ProgressShape.circular,
              foregroundColor: color,
              backgroundColor: color.withOpacity(0.12),
              labelStyle: ProgressLabelStyle.custom,
              customLabel: '${streaks.risk.hoursUntilBreak}h',
              labelTextStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              animated: true,
              animationDuration: const Duration(milliseconds: 1200),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// 3. NEXT MILESTONE CARD
// Uses CustomProgressIndicator + AdvancedProgressIndicator arc
// ================================================================

class _NextMilestoneCard extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _NextMilestoneCard({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final target = streaks.nextMilestone.target;
    final current = streaks.currentDays;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 1.0;
    final pct = streaks.nextMilestone.progressPercent;
    final remaining = target > current ? target - current : 0;
    const color = Color(0xFFFF6B35);

    if (target <= 0) {
      return _CardShell(
        isDark: isDark,
        theme: theme,
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Milestones Completed!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    'You\'ve reached every streak milestone. Incredible!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      gradient: [
        color.withOpacity(isDark ? 0.22 : 0.12),
        color.withOpacity(isDark ? 0.08 : 0.03),
      ],
      child: Row(
        children: [
          // Arc progress
          AdvancedProgressIndicator(
            progress: progress,
            size: 104,
            strokeWidth: 10,
            shape: ProgressShape.arc,
            arcStartAngle: 180,
            arcSweepAngle: 180,
            gradientColors: [color, color.withOpacity(0.5)],
            backgroundColor: color.withOpacity(0.1),
            labelStyle: ProgressLabelStyle.custom,
            customLabel: '$pct%',
            labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
            animationDuration: const Duration(milliseconds: 1400),
            animationCurve: Curves.easeOutCubic,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _milestoneEmoji(target),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$target-Day Goal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  remaining > 0 ? '$remaining days to go!' : 'Almost there!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                // Horizontal bar
                CustomProgressIndicator(
                  progress: progress,
                  progressBarName: '$current / $target days',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 9,
                  maxHeightIncrease: 3,
                  gradientColors: [color, color.withOpacity(0.55)],
                  backgroundColor: color.withOpacity(0.1),
                  borderRadius: 7,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 9,
                  ),
                  animateNameLabel: true,
                  animationDuration: const Duration(milliseconds: 1400),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _milestoneEmoji(int days) {
    if (days <= 3) return '🌱';
    if (days <= 7) return '🌿';
    if (days <= 14) return '🌳';
    if (days <= 21) return '🏔️';
    if (days <= 30) return '⛰️';
    if (days <= 60) return '🗻';
    if (days <= 90) return '🚀';
    if (days <= 180) return '🌍';
    return '🌟';
  }
}

// ================================================================
// 4. STREAK STATS GRID
// ================================================================

class _StreakStatsGrid extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _StreakStatsGrid({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stats = streaks.stats;

    final tiles = [
      _STile(
        icon: '📅',
        label: 'Total Active Days',
        value: stats.totalActiveDaysAllTime.toString(),
        color: const Color(0xFF3B82F6),
      ),
      _STile(
        icon: '📊',
        label: 'Average Streak',
        value: '${stats.averageStreak.toStringAsFixed(1)}d',
        color: const Color(0xFF8B5CF6),
      ),
      _STile(
        icon: '🔥',
        label: 'Current Streak',
        value: '${streaks.currentDays}d',
        color: const Color(0xFFEF4444),
      ),
      _STile(
        icon: '🏆',
        label: 'Longest Ever',
        value: '${streaks.longestDays}d',
        color: const Color(0xFF10B981),
      ),
      _STile(
        icon: '🎯',
        label: 'Next Milestone',
        value: streaks.nextMilestone.target > 0
            ? '${streaks.nextMilestone.target}d'
            : 'All Done!',
        color: const Color(0xFFFF6B35),
      ),
      _STile(
        icon: '💔',
        label: 'Common Break Day',
        value: stats.mostCommonBreakDay.isEmpty
            ? '—'
            : stats.mostCommonBreakDay,
        color: const Color(0xFFFFA500),
      ),
      _STile(
        icon: streaks.isActive ? '✅' : '❌',
        label: 'Status',
        value: streaks.isActive ? 'Active' : 'Inactive',
        color: streaks.isActive
            ? const Color(0xFF10B981)
            : const Color(0xFF94A3B8),
      ),
      _STile(
        icon: '⚡',
        label: 'Streak Emoji',
        value: streaks.streakEmoji,
        color: const Color(0xFF667EEA),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final t = tiles[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.color.withOpacity(isDark ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.icon, style: const TextStyle(fontSize: 18)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: t.color,
                    ),
                  ),
                  Text(
                    t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 9,
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

class _STile {
  final String icon, label, value;
  final Color color;
  const _STile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

// ================================================================
// 5. LONGEST STREAK DETAIL CARD
// ================================================================

class _LongestStreakDetailCard extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _LongestStreakDetailCard({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final longest = streaks.longest;
    const color = Color(0xFF10B981);
    final hasDate = longest.startedDate != null && longest.endedDate != null;

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      gradient: [
        color.withOpacity(isDark ? 0.2 : 0.12),
        color.withOpacity(isDark ? 0.07 : 0.03),
      ],
      child: Row(
        children: [
          // Full circle — always 100% for longest
          AdvancedProgressIndicator(
            progress: 1.0,
            size: 96,
            strokeWidth: 9,
            shape: ProgressShape.circular,
            gradientColors: [color, color.withOpacity(0.55)],
            backgroundColor: color.withOpacity(0.1),
            labelStyle: ProgressLabelStyle.custom,
            customLabel: '${streaks.longestDays}',
            labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
            showGlow: true,
            glowRadius: 8,
            animationDuration: const Duration(milliseconds: 1500),
            name: 'days',
            namePosition: ProgressLabelPosition.bottom,
            nameTextStyle: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Longest Streak',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasDate) ...[
                  _LRow(
                    label: 'Started',
                    value: _fmt(longest.startedDate!),
                    color: color,
                    theme: theme,
                  ),
                  const SizedBox(height: 4),
                  _LRow(
                    label: 'Ended',
                    value: _fmt(longest.endedDate!),
                    color: color,
                    theme: theme,
                  ),
                  const SizedBox(height: 4),
                  _LRow(
                    label: 'Duration',
                    value: '${streaks.longestDays} days',
                    color: color,
                    theme: theme,
                  ),
                ] else ...[
                  Text(
                    'Your best consistency achievement.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Bar showing longest vs a goal (e.g. 365)
                CustomProgressIndicator(
                  progress: (streaks.longestDays / 365).clamp(0.0, 1.0),
                  progressBarName: 'vs 365-day goal',
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
                  animationDuration: const Duration(milliseconds: 1400),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final ThemeData theme;
  const _LRow({
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
// 6. BREAK INSIGHTS CARD
// ================================================================

class _BreakInsightsCard extends StatelessWidget {
  final Streaks streaks;
  final ThemeData theme;
  final bool isDark;

  const _BreakInsightsCard({
    required this.streaks,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stats = streaks.stats;
    const amber = Color(0xFFFFA500);
    const red = Color(0xFFEF4444);

    // Consistency score: currentDays / longestDays
    final maxD = streaks.longestDays == 0 ? 1 : streaks.longestDays;
    final consistScore = (streaks.currentDays / maxD).clamp(0.0, 1.0);
    // Active ratio: totalActiveDays / estimated total days tracked
    final totalTracked = (stats.totalActiveDaysAllTime + streaks.longestDays)
        .clamp(1, 99999);
    final activeRatio = (stats.totalActiveDaysAllTime / totalTracked).clamp(
      0.0,
      1.0,
    );

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                'Streak Insights',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Most common break day
          if (stats.mostCommonBreakDay.isNotEmpty) ...[
            _InsightRow(
              emoji: '💔',
              label: 'Most Common Break Day',
              value: stats.mostCommonBreakDay,
              valueColor: red,
              theme: theme,
            ),
            const SizedBox(height: 14),
          ],

          // Average streak bar
          _InsightBar(
            emoji: '📊',
            label: 'Average Streak Length',
            value: '${stats.averageStreak.toStringAsFixed(1)} days',
            progress: (stats.averageStreak / maxD).clamp(0.0, 1.0),
            gradient: [amber, amber.withOpacity(0.55)],
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 14),

          // Consistency score bar
          _InsightBar(
            emoji: '🎯',
            label: 'Current Consistency Score',
            value: '${(consistScore * 100).toStringAsFixed(0)}%',
            progress: consistScore,
            gradient: [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 14),

          // Active ratio bar
          _InsightBar(
            emoji: '⚡',
            label: 'Activity Rate',
            value: '${(activeRatio * 100).toStringAsFixed(0)}%',
            progress: activeRatio,
            gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String emoji, label, value;
  final Color valueColor;
  final ThemeData theme;
  const _InsightRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InsightBar extends StatelessWidget {
  final String emoji, label, value;
  final double progress;
  final List<Color> gradient;
  final bool isDark;
  final ThemeData theme;
  const _InsightBar({
    required this.emoji,
    required this.label,
    required this.value,
    required this.progress,
    required this.gradient,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: gradient.first,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CustomProgressIndicator(
          progress: progress.clamp(0.0, 1.0),
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

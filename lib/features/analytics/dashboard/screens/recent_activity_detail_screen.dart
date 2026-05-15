// ================================================================
// FILE: recent_activity_detail_screen.dart
// RECENT ACTIVITY DETAIL SCREEN — Full activity feed + analytics
// Uses: AdvancedProgressIndicator, CustomProgressIndicator,
//       ActivityHeroStats, ActivityFilterBar,
//       ActivityFeedSection from mood_streak_activity_widgets.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Dashboard widgets ────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/mood_streak_activity_widgets.dart';
import '../widgets/shared_widgets.dart';

// ── Data + provider ─────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';

// ================================================================
// SCREEN
// ================================================================

class RecentActivityDetailScreen extends StatefulWidget {
  const RecentActivityDetailScreen({super.key});

  @override
  State<RecentActivityDetailScreen> createState() =>
      _RecentActivityDetailScreenState();
}

class _RecentActivityDetailScreenState
    extends State<RecentActivityDetailScreen>
    with TickerProviderStateMixin {
  String _filter = 'all';

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
            return const Center(child: CircularProgressIndicator());
          }

          final all = provider.recentActivity;
          final filtered = _applyFilter(all, _filter);

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
                  background: _ActivityHeroHeader(
                    activities: all,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('Recent Activity',
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
                          // ── 1. Hero stats ─────────────────────
                          _SectionLabel(label: 'Activity Snapshot'),
                          const SizedBox(height: 12),
                          ActivityHeroStats(
                              activities: all,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 2. Action breakdown bars ──────────
                          _SectionLabel(label: 'Action Breakdown'),
                          const SizedBox(height: 12),
                          _ActionBreakdownCard(
                              activities: all,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 3. Points over time ───────────────
                          _SectionLabel(
                              label: 'Points by Activity Type'),
                          const SizedBox(height: 12),
                          _PointsByTypeCard(
                              activities: all,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 4. Milestone spotlight ────────────
                          if (all.any((a) => a.isMilestone)) ...[
                            _SectionLabel(label: 'Milestone Highlights'),
                            const SizedBox(height: 12),
                            _MilestoneSpotlightCard(
                                activities: all,
                                theme: theme,
                                isDark: isDark),
                            const SizedBox(height: 24),
                          ],

                          // ── 5. Filter + Feed ──────────────────
                          _SectionLabel(
                              label:
                              'Activity Feed (${filtered.length})'),
                          const SizedBox(height: 12),
                          ActivityFilterBar(
                            selected: _filter,
                            onChanged: (v) =>
                                setState(() => _filter = v),
                          ),
                          const SizedBox(height: 12),
                          filtered.isEmpty
                              ? _EmptyFilter(theme: theme)
                              : ActivityFeedSection(
                              activities: filtered),
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

  List<RecentActivityItem> _applyFilter(
      List<RecentActivityItem> all, String filter) {
    if (filter == 'all') return all;
    if (filter == 'milestone') {
      return all.where((a) => a.isMilestone).toList();
    }
    return all.where((a) => a.action == filter).toList();
  }
}

// ================================================================
// HERO HEADER
// ================================================================

class _ActivityHeroHeader extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _ActivityHeroHeader({
    required this.activities,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final total = activities.length;
    final milestones = activities.where((a) => a.isMilestone).length;
    final totalPoints =
    activities.fold<int>(0, (s, a) => s + a.points);
    final completed =
        activities.where((a) => a.action == 'task_completed').length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1C3A), const Color(0xFF0D0F1E)]
              : [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
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
                            Text('Recent Activity',
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
                            Text('Your productivity timeline',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                    Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                      // Total badge
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
                          const Text('⚡',
                              style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text('$total Activities',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ]),
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
                        _HStat(
                            value: total.toString(),
                            label: 'Total',
                            icon: '📋'),
                        _HDiv(),
                        _HStat(
                            value: completed.toString(),
                            label: 'Completed',
                            icon: '✅'),
                        _HDiv(),
                        _HStat(
                            value: milestones.toString(),
                            label: 'Milestones',
                            icon: '🏆'),
                        _HDiv(),
                        _HStat(
                            value: totalPoints.toString(),
                            label: 'Points',
                            icon: '⭐'),
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
  const _HStat(
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
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _HDiv extends StatelessWidget {
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
// ACTION BREAKDOWN CARD  (CustomProgressIndicator)
// ================================================================

class _ActionBreakdownCard extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final ThemeData theme;
  final bool isDark;

  const _ActionBreakdownCard(
      {required this.activities, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = activities.isEmpty ? 1 : activities.length;

    // Group by action type
    final actionCounts = <String, int>{};
    for (final a in activities) {
      actionCounts[a.action] = (actionCounts[a.action] ?? 0) + 1;
    }
    final sorted = actionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final actionColors = <String, Color>{
      'task_completed': const Color(0xFF10B981),
      'reward_earned': const Color(0xFFF59E0B),
      'milestone': const Color(0xFF667EEA),
      'streak_extended': const Color(0xFFEF4444),
      'goal_updated': const Color(0xFF8B5CF6),
      'diary_written': const Color(0xFF3B82F6),
    };
    final actionEmojis = <String, String>{
      'task_completed': '✅',
      'reward_earned': '🏆',
      'milestone': '🎯',
      'streak_extended': '🔥',
      'goal_updated': '📈',
      'diary_written': '📔',
    };

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
        children: sorted.map((entry) {
          final color = actionColors[entry.key] ?? const Color(0xFF94A3B8);
          final emoji = actionEmojis[entry.key] ?? '📌';
          final fraction = entry.value / total;
          final label = entry.key.replaceAll('_', ' ');

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
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(_capitalize(label),
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700)),
                    ]),
                    Row(children: [
                      Text(entry.value.toString(),
                          style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(width: 4),
                      Text(
                          '(${(fraction * 100).toStringAsFixed(0)}%)',
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
                  baseHeight: 9,
                  maxHeightIncrease: 3,
                  gradientColors: [color, color.withOpacity(0.5)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
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
        }).toList(),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ================================================================
// POINTS BY TYPE CARD  (AdvancedProgressIndicator arc)
// ================================================================

class _PointsByTypeCard extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final ThemeData theme;
  final bool isDark;

  const _PointsByTypeCard(
      {required this.activities, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pointsByType = <String, int>{};
    for (final a in activities) {
      pointsByType[a.action] =
          (pointsByType[a.action] ?? 0) + a.points;
    }
    final totalPoints =
    pointsByType.values.fold<int>(0, (s, v) => s + v);
    final sorted = pointsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    final colors = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF667EEA),
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Point Sources',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('$totalPoints pts total',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: top3.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              final label = entry.value.key.replaceAll('_', ' ');
              final pts = entry.value.value;
              final frac = totalPoints > 0 ? pts / totalPoints : 0.0;

              return Column(children: [
                AdvancedProgressIndicator(
                  progress: frac.clamp(0.0, 1.0),
                  size: 76,
                  strokeWidth: 7,
                  shape: ProgressShape.arc,
                  arcStartAngle: 180,
                  arcSweepAngle: 180,
                  gradientColors: [color, color.withOpacity(0.5)],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200,
                  labelStyle: ProgressLabelStyle.custom,
                  customLabel: pts.toString(),
                  labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: color),
                  animationDuration: const Duration(milliseconds: 1300),
                ),
                const SizedBox(height: 4),
                Text(_capitalize(label),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 9)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ================================================================
// MILESTONE SPOTLIGHT CARD
// ================================================================

class _MilestoneSpotlightCard extends StatelessWidget {
  final List<RecentActivityItem> activities;
  final ThemeData theme;
  final bool isDark;

  const _MilestoneSpotlightCard(
      {required this.activities, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final milestones = activities
        .where((a) => a.isMilestone)
        .toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    final top = milestones.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF667EEA).withOpacity(0.2),
            const Color(0xFF667EEA).withOpacity(0.06)
          ]
              : [
            const Color(0xFF667EEA).withOpacity(0.12),
            const Color(0xFF667EEA).withOpacity(0.03)
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF667EEA).withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('${milestones.length} Milestones Achieved',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          ...top.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m.actionColor.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: m.actionColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: m.actionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m.actionIcon,
                      color: m.actionColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700)),
                        Text(m.timeAgo,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 10)),
                      ]),
                ),
                PointsBadge(points: m.points, animate: false),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

// ================================================================
// EMPTY FILTER STATE
// ================================================================

class _EmptyFilter extends StatelessWidget {
  final ThemeData theme;
  const _EmptyFilter({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: EmptyStateWidget(
        icon: Icons.filter_list_rounded,
        title: 'No Results',
        subtitle: 'No activities match this filter',
      ),
    );
  }
}
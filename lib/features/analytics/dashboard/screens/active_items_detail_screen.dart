// ================================================================
// FILE: active_items_detail_screen.dart
// ACTIVE ITEMS DETAIL SCREEN — In-progress tasks
// • NO active_items_widgets.dart dependency
// • Uses: CustomProgressIndicator, AdvancedProgressIndicator,
//         today_active_shared_widgets.dart,
//         shared_widgets.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Progress widgets ─────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';

// ── Shared (Today ↔ ActiveItems) ─────────────────────────────────
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/today_active_shared_widgets.dart';


// ── Dashboard shared ─────────────────────────────────────────────
import '../widgets/shared_widgets.dart';

// ── Helpers ──────────────────────────────────────────────────────
import '../../../../helpers/card_color_helper.dart';

// ── Data + provider ──────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// CONSTANTS
// ================================================================

const _kTabColors = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
];
const _kTabLabels = ['Day Tasks', 'Weekly', 'Goals', 'Buckets'];
const _kTabEmojis = ['✅', '📅', '🎯', '🎁'];

// ================================================================
// SCREEN
// ================================================================

class ActiveItemsDetailScreen extends StatefulWidget {
  const ActiveItemsDetailScreen({super.key});

  @override
  State<ActiveItemsDetailScreen> createState() =>
      _ActiveItemsDetailScreenState();
}

class _ActiveItemsDetailScreenState extends State<ActiveItemsDetailScreen>
    with TickerProviderStateMixin {
  int _tab = 0;

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
          if (!provider.hasData) return const ActiveItemsCardSkeleton();
          final activeItems = provider.activeItems;

          final counts = [
            activeItems.activeDayTasks.length,
            activeItems.activeWeekTasks.length,
            activeItems.activeLongGoals.length,
            activeItems.activeBuckets.length,
          ];
          final total = counts.fold<int>(0, (s, c) => s + c);
          final overdue = _countOverdue(activeItems);

          return Column(
            children: [
              // ── HERO (fixed) ──────────────────────────────────
              SlideTransition(
                position: _heroSlide,
                child: FadeTransition(
                  opacity: _heroFade,
                  child: _AIHero(
                    counts: counts,
                    total: total,
                    overdue: overdue,
                    selectedTab: _tab,
                    isDark: isDark,
                    theme: theme,
                    onBack: () => Navigator.pop(context),
                    onTabChanged: (i) => setState(() {
                      _tab = i;
                      _bodyCtrl
                        ..reset()
                        ..forward();
                    }),
                  ),
                ),
              ),

              // ── BODY (scrollable) ─────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _bodyFade,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Stats overview card
                            _AIStatsCard(
                              activeItems: activeItems,
                              counts: counts,
                              total: total,
                              overdue: overdue,
                              isDark: isDark,
                              theme: theme,
                            ),
                            const SizedBox(height: 20),

                            // Section label for tab
                            TASectionLabel(
                              label:
                              '${_kTabEmojis[_tab]} ${_kTabLabels[_tab]} (${counts[_tab]})',
                              color: _kTabColors[_tab],
                            ),
                            const SizedBox(height: 12),

                            // Animated tab content
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _AITabContent(
                                key: ValueKey(_tab),
                                tab: _tab,
                                activeItems: activeItems,
                                isDark: isDark,
                                theme: theme,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countOverdue(ActiveItems ai) =>
      ai.activeDayTasks.where((t) => t.isOverdue).length +
          ai.activeLongGoals.where((t) => t.isOverdue).length +
          ai.activeBuckets.where((b) => b.isOverdue).length;
}

// ================================================================
// HERO HEADER
// ================================================================

class _AIHero extends StatelessWidget {
  final List<int> counts;
  final int total, overdue, selectedTab;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onBack;
  final ValueChanged<int> onTabChanged;

  const _AIHero({
    required this.counts,
    required this.total,
    required this.overdue,
    required this.selectedTab,
    required this.isDark,
    required this.theme,
    required this.onBack,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _kTabColors[selectedTab];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            Color.lerp(activeColor, const Color(0xFF0A0A14), 0.72)!,
            const Color(0xFF0D0D1A),
          ]
              : [activeColor, Color.lerp(activeColor, Colors.white, 0.35)!],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // App bar row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Items',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      Text(
                        '$total in progress'
                            '${overdue > 0 ? ' • $overdue overdue' : ' • all on track'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withOpacity(0.7)),
                      ),
                    ]),
              ),
              // Status badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    overdue > 0
                        ? Icons.warning_rounded
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    overdue > 0 ? '$overdue Overdue' : 'All Good',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Animated tab switcher strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: List.generate(4, (i) {
                  final isSelected = i == selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_kTabEmojis[i],
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(counts[i].toString(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600)),
                            Text(_kTabLabels[i],
                                style: TextStyle(
                                    color: Colors.white.withOpacity(
                                        isSelected ? 0.95 : 0.6),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ================================================================
// STATS OVERVIEW CARD
// ================================================================

class _AIStatsCard extends StatelessWidget {
  final ActiveItems activeItems;
  final List<int> counts;
  final int total, overdue;
  final bool isDark;
  final ThemeData theme;

  const _AIStatsCard({
    required this.activeItems,
    required this.counts,
    required this.total,
    required this.overdue,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [
      ...activeItems.activeDayTasks,
      ...activeItems.activeWeekTasks,
      ...activeItems.activeLongGoals,
      ...activeItems.activeBuckets,
    ];

    final avgProgress = allItems.isEmpty
        ? 0.0
        : allItems.fold<int>(0, (s, item) {
      if (item is ActiveDayTask) return s + item.progress;
      if (item is ActiveWeekTask) return s + item.progress;
      if (item is ActiveLongGoal) return s + item.progress;
      if (item is ActiveBucket) return s + item.progress;
      return s;
    }) /
        allItems.length;

    final totalPoints = allItems.fold<int>(0, (s, item) {
      if (item is ActiveDayTask) return s + item.points;
      if (item is ActiveWeekTask) return s + item.points;
      if (item is ActiveLongGoal) return s + item.points;
      if (item is ActiveBucket) return s + item.points;
      return s;
    });

    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);

    return TACardShell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avg ring + pills
        Row(children: [
          AdvancedProgressIndicator(
            progress: (avgProgress / 100).clamp(0.0, 1.0),
            size: 92,
            strokeWidth: 9,
            shape: ProgressShape.circular,
            gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.grey.shade200,
            labelStyle: ProgressLabelStyle.custom,
            customLabel: '${avgProgress.toStringAsFixed(0)}%',
            labelTextStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF667EEA)),
            showGlow: avgProgress > 60,
            glowRadius: 6,
            animationDuration: const Duration(milliseconds: 1400),
            name: 'avg progress',
            namePosition: ProgressLabelPosition.bottom,
            nameTextStyle: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF667EEA).withOpacity(0.65),
                fontSize: 9),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4-tile grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 80,
                  ),
                  itemBuilder: (context, i) {
                    final tiles = [
                      TAStatTile(
                          emoji: '📋',
                          label: 'Total',
                          value: total.toString(),
                          color: const Color(0xFF667EEA)),
                      TAStatTile(
                          emoji: '⭐',
                          label: 'Points',
                          value: totalPoints.toString(),
                          color: const Color(0xFFF59E0B)),
                      TAStatTile(
                          emoji: overdue > 0 ? '⚠️' : '✅',
                          label: overdue > 0 ? 'Overdue' : 'On Track',
                          value: overdue > 0 ? overdue.toString() : 'All',
                          color: overdue > 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981)),
                      TAStatTile(
                          emoji: '📊',
                          label: 'Avg Done',
                          value: '${avgProgress.toStringAsFixed(0)}%',
                          color: const Color(0xFF8B5CF6)),
                    ];
                    return tiles[i];
                  },
                ),
                const SizedBox(height: 10),
                // Overall bar
                CustomProgressIndicator(
                  progress: (avgProgress / 100).clamp(0.0, 1.0),
                  progressBarName: 'Avg progress — all items',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 8,
                  maxHeightIncrease: 2,
                  gradientColors: const [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2)
                  ],
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                  borderRadius: 6,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                      color:
                      theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 9),
                  animateNameLabel: true,
                  animationDuration: const Duration(milliseconds: 1300),
                  animationCurve: Curves.easeOutCubic,
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // Per-category breakdown bars
        ...List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TACategoryBarRow(
            emoji: _kTabEmojis[i],
            label: _kTabLabels[i],
            count: counts[i],
            maxCount: maxCount,
            color: _kTabColors[i],
            isDark: isDark,
          ),
        )),
      ]),
    );
  }
}

// ================================================================
// TAB CONTENT SWITCHER
// ================================================================

class _AITabContent extends StatelessWidget {
  final int tab;
  final ActiveItems activeItems;
  final bool isDark;
  final ThemeData theme;

  const _AITabContent({
    super.key,
    required this.tab,
    required this.activeItems,
    required this.isDark,
    required this.theme,
  });

  static const _emptyIcons = [
    Icons.calendar_today_rounded,
    Icons.view_week_rounded,
    Icons.flag_rounded,
    Icons.inventory_2_rounded,
  ];
  static const _emptyTitles = [
    'No Active Day Tasks',
    'No Active Weekly Tasks',
    'No Active Goals',
    'No Active Buckets',
  ];
  static const _emptySubs = [
    "You're all caught up! 🥳",
    'Plan your week to stay ahead! 📅',
    'Dream big and start a goal! 🚀',
    'Fill your buckets with achievements! 🎁',
  ];

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 0:
        return _AIItemList<ActiveDayTask>(
          items: activeItems.activeDayTasks,
          color: _kTabColors[0],
          emptyIcon: _emptyIcons[0],
          emptyTitle: _emptyTitles[0],
          emptySub: _emptySubs[0],
          itemBuilder: (item) =>
              _AIDayTaskCard(task: item, isDark: isDark, theme: theme),
        );
      case 1:
        return _AIItemList<ActiveWeekTask>(
          items: activeItems.activeWeekTasks,
          color: _kTabColors[1],
          emptyIcon: _emptyIcons[1],
          emptyTitle: _emptyTitles[1],
          emptySub: _emptySubs[1],
          itemBuilder: (item) =>
              _AIWeekTaskCard(task: item, isDark: isDark, theme: theme),
        );
      case 2:
        return _AIItemList<ActiveLongGoal>(
          items: activeItems.activeLongGoals,
          color: _kTabColors[2],
          emptyIcon: _emptyIcons[2],
          emptyTitle: _emptyTitles[2],
          emptySub: _emptySubs[2],
          itemBuilder: (item) =>
              _AILongGoalCard(goal: item, isDark: isDark, theme: theme),
        );
      case 3:
        return _AIItemList<ActiveBucket>(
          items: activeItems.activeBuckets,
          color: _kTabColors[3],
          emptyIcon: _emptyIcons[3],
          emptyTitle: _emptyTitles[3],
          emptySub: _emptySubs[3],
          itemBuilder: (item) =>
              _AIBucketCard(bucket: item, isDark: isDark, theme: theme),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ================================================================
// GENERIC LIST WRAPPER
// ================================================================

class _AIItemList<T> extends StatelessWidget {
  final List<T> items;
  final Color color;
  final IconData emptyIcon;
  final String emptyTitle, emptySub;
  final Widget Function(T) itemBuilder;

  const _AIItemList({
    required this.items,
    required this.color,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySub,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyStateWidget(
          icon: emptyIcon,
          title: emptyTitle,
          subtitle: emptySub,
          iconColor: color.withOpacity(0.5),
        ),
      );
    }
    return Column(
      children: items
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: itemBuilder(item),
      ))
          .toList(),
    );
  }
}

// ================================================================
// ITEM CARDS
// ================================================================

class _AIDayTaskCard extends StatelessWidget {
  final ActiveDayTask task;
  final bool isDark;
  final ThemeData theme;

  const _AIDayTaskCard(
      {required this.task, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF3B82F6);
    return TAItemCardShell(
      accentColor: color,
      isDark: isDark,
      isOverdue: task.isOverdue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TATaskCardHeader(
          title: task.title,
          status: task.status,
          priority: task.priority,
          isOverdue: task.isOverdue,
          points: task.points,
          reward: task.reward,
        ),
        const SizedBox(height: 12),
        TAProgressRow(progress: task.progress, color: color, isDark: isDark),
        if (task.penalty != null) ...[
          const SizedBox(height: 8),
          const TAPenaltyBadge(),
        ],
      ]),
    );
  }
}

class _AIWeekTaskCard extends StatelessWidget {
  final ActiveWeekTask task;
  final bool isDark;
  final ThemeData theme;

  const _AIWeekTaskCard(
      {required this.task, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8B5CF6);
    return TAItemCardShell(
      accentColor: color,
      isDark: isDark,
      isOverdue: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TATaskCardHeader(
          title: task.title,
          status: task.status,
          priority: task.priority,
          isOverdue: false,
          points: task.points,
          reward: task.reward,
        ),
        const SizedBox(height: 12),
        TAProgressRow(progress: task.progress, color: color, isDark: isDark),
        if (task.penalty != null) ...[
          const SizedBox(height: 8),
          const TAPenaltyBadge(),
        ],
      ]),
    );
  }
}

class _AILongGoalCard extends StatelessWidget {
  final ActiveLongGoal goal;
  final bool isDark;
  final ThemeData theme;

  const _AILongGoalCard(
      {required this.goal, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF10B981);
    return TAItemCardShell(
      accentColor: color,
      isDark: isDark,
      isOverdue: goal.isOverdue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TATaskCardHeader(
          title: goal.title,
          status: goal.status,
          priority: goal.priority,
          isOverdue: goal.isOverdue,
          points: goal.points,
          reward: goal.reward,
        ),
        const SizedBox(height: 10),
        // Arc + bar from shared widget
        TAArcProgressCard(
          progress: goal.progress,
          color: color,
          isDark: isDark,
          rightChild: TAProgressRow(
              progress: goal.progress, color: color, isDark: isDark),
        ),
        if (goal.penalty != null) ...[
          const SizedBox(height: 8),
          const TAPenaltyBadge(),
        ],
      ]),
    );
  }
}

class _AIBucketCard extends StatelessWidget {
  final ActiveBucket bucket;
  final bool isDark;
  final ThemeData theme;

  const _AIBucketCard(
      {required this.bucket, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = CardColorHelper.getBucketColor(bucket.id);
    return TAItemCardShell(
      accentColor: color,
      isDark: isDark,
      isOverdue: bucket.isOverdue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bucket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 6, children: [
                    StatusBadge(status: bucket.status),
                    if (bucket.isOverdue) const TAOverdueBadge(),
                  ]),
                ]),
          ),
          const SizedBox(width: 8),
          PointsBadge(points: bucket.points, animate: false),
        ]),
        const SizedBox(height: 12),
        TAProgressRow(
          progress: bucket.progress,
          color: color,
          isDark: isDark,
          label: 'Checklist Progress',
        ),
        if (bucket.hasPenalty) ...[
          const SizedBox(height: 8),
          const TAPenaltyBadge(),
        ],
      ]),
    );
  }
}
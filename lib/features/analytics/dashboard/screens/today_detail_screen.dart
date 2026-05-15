// ================================================================
// FILE: today_detail_screen.dart
// TODAY DETAIL SCREEN — Full day schedule + 24-hour clock
// • NO today_widgets.dart dependency
// • Uses: CustomProgressIndicator, AdvancedProgressIndicator,
//         today_active_shared_widgets.dart,
//         Productivity24HourClock (as-is, no changes),
//         shared_widgets.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Progress widgets ─────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';

// ── Shared (Today ↔ ActiveItems) ─────────────────────────────────
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/today_active_shared_widgets.dart';

// ── Productivity clock (keep as-is) ──────────────────────────────
import '../widgets/productivity_clock.dart';

// ── Dashboard shared ─────────────────────────────────────────────
import '../widgets/shared_widgets.dart';

// ── Helpers ──────────────────────────────────────────────────────
import '../../../../helpers/card_color_helper.dart';

// ── Data + provider ──────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class TodayDetailScreen extends StatefulWidget {
  const TodayDetailScreen({super.key});

  @override
  State<TodayDetailScreen> createState() => _TodayDetailScreenState();
}

class _TodayDetailScreenState extends State<TodayDetailScreen>
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
          if (!provider.hasData) return const TodayTasksCardSkeleton();
          final today = provider.today;

          final totalScheduled = today.summary.totalScheduledTask;
          final completed = today.summary.completed;
          final dailyProgress = totalScheduled > 0
              ? (completed / totalScheduled).clamp(0.0, 1.0)
              : 0.0;
          final taskSegments = _convertToTaskSegments(today, isDark);
          final tier = provider.userDashboard?.overview.summary.bestTierAchieved ?? 'none';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ──────────────────────────────────
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
                  background: SlideTransition(
                    position: _heroSlide,
                    child: FadeTransition(
                      opacity: _heroFade,
                      child: _TodayHero(
                        today: today,
                        dailyProgress: dailyProgress,
                        completed: completed,
                        totalScheduled: totalScheduled,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text("Today's Schedule",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),

              // ── BODY top ─────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Quick summary tile row
                          _TodaySummaryTiles(
                              today: today,
                              dailyProgress: dailyProgress,
                              isDark: isDark,
                              theme: theme),
                          const SizedBox(height: 20),

                          // 2. Diary entry
                          TASectionLabel(label: '📔 Diary Entry'),
                          const SizedBox(height: 10),
                          _DiaryCard(
                              entry: today.diaryEntry,
                              isDark: isDark,
                              theme: theme),
                          const SizedBox(height: 20),

                          // 3. Clock heading
                          TASectionLabel(label: '⏰ 24-Hour Productivity Clock'),
                          const SizedBox(height: 4),
                          Text('Tap any segment to view task details',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5))),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Clock (full width, no side padding) ──────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _bodyFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Productivity24HourClock(
                      tasks: taskSegments,
                      dailyProgress: dailyProgress,
                      isDarkMode: isDark,
                      size: MediaQuery.of(context).size.width - 16,
                      tier: tier,
                    ),
                  ),
                ),
              ),

              // ── Task lists ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day tasks
                          if (today.dayTasks.isNotEmpty) ...[
                            TASectionLabel(
                              label:
                              '☀️ Day Tasks (${today.dayTasks.length})',
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 10),
                            _DayTasksList(
                                tasks: today.dayTasks,
                                isDark: isDark,
                                theme: theme),
                            const SizedBox(height: 20),
                          ],

                          // Weekly tasks
                          if (today.weekTasksDueToday.isNotEmpty) ...[
                            TASectionLabel(
                              label:
                              '📅 Weekly Tasks (${today.weekTasksDueToday.length})',
                              color: const Color(0xFF8B5CF6),
                            ),
                            const SizedBox(height: 10),
                            _WeeklyTasksList(
                                tasks: today.weekTasksDueToday,
                                isDark: isDark,
                                theme: theme),
                            const SizedBox(height: 20),
                          ],

                          // Long goals
                          if (today.longGoalsDueToday.isNotEmpty) ...[
                            TASectionLabel(
                              label:
                              '🎯 Goals Due Today (${today.longGoalsDueToday.length})',
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 10),
                            _LongGoalsList(
                                goals: today.longGoalsDueToday,
                                isDark: isDark,
                                theme: theme),
                            const SizedBox(height: 20),
                          ],

                          // Bucket entries
                          if (today.bucketsEntry.isNotEmpty) ...[
                            TASectionLabel(
                              label:
                              '🎁 Bucket Items (${today.bucketsEntry.length})',
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(height: 10),
                            _BucketList(
                                items: today.bucketsEntry,
                                isDark: isDark,
                                theme: theme),
                          ],

                          // Fully empty state
                          if (today.dayTasks.isEmpty &&
                              today.weekTasksDueToday.isEmpty &&
                              today.longGoalsDueToday.isEmpty &&
                              today.bucketsEntry.isEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 40),
                              child: EmptyStateWidget(
                                icon: Icons.calendar_today_rounded,
                                title: 'Nothing Scheduled Today',
                                subtitle:
                                'Enjoy your free day or add new tasks!',
                              ),
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

  // ── Segment builder ───────────────────────────────────────────

  List<TaskSegment> _convertToTaskSegments(
      TodaySummary today, bool isDark) {
    final segments = <TaskSegment>[];
    final now = DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day);

    for (final t in today.dayTasks) {
      segments.add(TaskSegment(
        id: t.id,
        title: t.title,
        startTime: t.timeStart ?? todayBase.add(const Duration(hours: 9)),
        endTime: t.timeEnd ?? todayBase.add(const Duration(hours: 11)),
        priority: t.priority ?? 'medium',
        status: t.status,
        progress: t.progress,
        points: t.points,
        categoryType: t.categoryType,
        reward: t.reward,
        taskType: 'Day Task',
      ));
    }
    for (final t in today.weekTasksDueToday) {
      segments.add(TaskSegment(
        id: t.id,
        title: t.title,
        startTime: t.timeStart ?? todayBase.add(const Duration(hours: 13)),
        endTime: t.timeEnd ?? todayBase.add(const Duration(hours: 14)),
        priority: t.priority ?? 'medium',
        status: t.status,
        progress: t.progress,
        points: t.points,
        categoryType: t.categoryType,
        reward: t.reward,
        taskType: 'Weekly Task',
      ));
    }
    for (final g in today.longGoalsDueToday) {
      segments.add(TaskSegment(
        id: g.id,
        title: g.title,
        startTime: g.timeStart ?? todayBase.add(const Duration(hours: 14)),
        endTime: g.timeEnd ?? todayBase.add(const Duration(hours: 15)),
        priority: g.priority ?? 'medium',
        status: g.status,
        progress: g.progress,
        points: g.points,
        categoryType: g.categoryType,
        reward: g.reward,
        taskType: 'Long Goal',
      ));
    }
    for (final b in today.bucketsEntry) {
      segments.add(TaskSegment(
        id: b.id,
        title: b.title,
        startTime: b.doneTime ?? todayBase.add(const Duration(hours: 16)),
        endTime:
        (b.doneTime ?? todayBase).add(const Duration(hours: 1)),
        priority: b.priority ?? 'medium',
        status: b.status,
        progress: b.progress,
        points: b.points,
        reward: b.reward,
        taskType: 'Bucket',
      ));
    }
    if (today.diaryEntry.hasEntry) {
      segments.add(TaskSegment(
        id: 'diary_entry_today',
        title: 'Diary Entry',
        startTime: todayBase.add(const Duration(hours: 23)),
        endTime: todayBase.add(const Duration(hours: 23, minutes: 30)),
        priority: 'medium',
        status: 'completed',
        progress: 100,
        points: 0,
        taskType: 'Diary',
      ));
    }
    return segments;
  }
}

// ================================================================
// HERO HEADER
// ================================================================

class _TodayHero extends StatelessWidget {
  final TodaySummary today;
  final double dailyProgress;
  final int completed, totalScheduled;
  final bool isDark;
  final ThemeData theme;

  const _TodayHero({
    required this.today,
    required this.dailyProgress,
    required this.completed,
    required this.totalScheduled,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = [
      'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
    ][now.weekday - 1];
    final month = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ][now.month - 1];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F1628), const Color(0xFF0A0A14)]
              : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
      ),
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
                      Text('$weekday, $month ${now.day}',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text("Today's Schedule",
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8)
                              ])),
                    ],
                  ),
                ),
                // Daily progress circular ring
                AdvancedProgressIndicator(
                  progress: dailyProgress,
                  size: 72,
                  strokeWidth: 7,
                  shape: ProgressShape.circular,
                  gradientColors: [
                    Colors.white,
                    Colors.white.withOpacity(0.55)
                  ],
                  backgroundColor: Colors.white.withOpacity(0.15),
                  labelStyle: ProgressLabelStyle.custom,
                  customLabel:
                  '${(dailyProgress * 100).toStringAsFixed(0)}%',
                  labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900, color: Colors.white),
                  showGlow: dailyProgress > 0.5,
                  glowRadius: 8,
                  animationDuration: const Duration(milliseconds: 1400),
                ),
              ]),
              const SizedBox(height: 16),
              TAHeroStrip(children: [
                TAHeroStat(
                    value: '$completed/$totalScheduled',
                    label: 'Done',
                    icon: '✅'),
                const TAHeroDiv(),
                TAHeroStat(
                    value: today.dayTasks.length.toString(),
                    label: 'Day Tasks',
                    icon: '☀️'),
                const TAHeroDiv(),
                TAHeroStat(
                    value: today.weekTasksDueToday.length.toString(),
                    label: 'Weekly',
                    icon: '📅'),
                const TAHeroDiv(),
                TAHeroStat(
                    value: today.longGoalsDueToday.length.toString(),
                    label: 'Goals',
                    icon: '🎯'),
                const TAHeroDiv(),
                TAHeroStat(
                    value: today.bucketsEntry.length.toString(),
                    label: 'Buckets',
                    icon: '🎁'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SUMMARY TILES ROW  (4 stat tiles)
// ================================================================

class _TodaySummaryTiles extends StatelessWidget {
  final TodaySummary today;
  final double dailyProgress;
  final bool isDark;
  final ThemeData theme;

  const _TodaySummaryTiles({
    required this.today,
    required this.dailyProgress,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final total = today.summary.totalScheduledTask;
    final done = today.summary.completed;
    final pts = today.summary.pointsEarned;
    final pending = total - done;

    final tiles = [
      TAStatTile(
          emoji: '📋', label: 'Total', value: total.toString(),
          color: const Color(0xFF667EEA)),
      TAStatTile(
          emoji: '✅', label: 'Done', value: done.toString(),
          color: const Color(0xFF10B981)),
      TAStatTile(
          emoji: '⏳', label: 'Pending', value: pending.toString(),
          color: const Color(0xFFF59E0B)),
      TAStatTile(
          emoji: '⭐', label: 'Points', value: pts.toString(),
          color: const Color(0xFFEF4444)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 95,
      ),
      itemBuilder: (context, i) => tiles[i],
    );
  }
}

// ================================================================
// DIARY CARD
// ================================================================

class _DiaryCard extends StatelessWidget {
  final TodayDiaryEntry entry;
  final bool isDark;
  final ThemeData theme;

  const _DiaryCard(
      {required this.entry, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (!entry.hasEntry) {
      return TACardShell(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_note_rounded,
                color: theme.colorScheme.outline, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Diary Entry Yet',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('Write today\'s thoughts to track your mood.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55))),
                ]),
          ),
        ]),
      );
    }

    final rating = entry.moodRating?.toDouble() ?? 5.0;
    final moodColor = CardColorHelper.moodColorForValue(rating);
    final moodEmoji = CardColorHelper.moodEmojiForValue(rating);

    return TACardShell(
      accentColor: moodColor,
      gradient: [
        moodColor.withOpacity(isDark ? 0.22 : 0.14),
        moodColor.withOpacity(isDark ? 0.07 : 0.03),
      ],
      child: Row(children: [
        // Mood arc
        AdvancedProgressIndicator(
          progress: (rating / 10).clamp(0.0, 1.0),
          size: 80,
          strokeWidth: 7,
          shape: ProgressShape.arc,
          arcStartAngle: 180,
          arcSweepAngle: 180,
          gradientColors: [moodColor, moodColor.withOpacity(0.5)],
          backgroundColor: moodColor.withOpacity(0.1),
          labelStyle: ProgressLabelStyle.custom,
          customLabel: moodEmoji,
          labelTextStyle: const TextStyle(fontSize: 22),
          animationDuration: const Duration(milliseconds: 1300),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text("Mood Today",
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${rating.toStringAsFixed(1)}/10',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: moodColor, fontWeight: FontWeight.w800)),
                  ),
                ]),
                if (entry.moodLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(entry.moodLabel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: moodColor.withOpacity(0.85),
                          fontWeight: FontWeight.w600)),
                ],
                if (entry.wordCount != null) ...[
                  const SizedBox(height: 2),
                  Text('${entry.wordCount} words written',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
                const SizedBox(height: 8),
                CustomProgressIndicator(
                  progress: (rating / 10).clamp(0.0, 1.0),
                  progressBarName: '',
                  orientation: ProgressOrientation.horizontal,
                  baseHeight: 7,
                  maxHeightIncrease: 2,
                  gradientColors: [moodColor, moodColor.withOpacity(0.5)],
                  backgroundColor: moodColor.withOpacity(0.1),
                  borderRadius: 5,
                  progressLabelDisplay: ProgressLabelDisplay.none,
                  nameLabelPosition: LabelPosition.bottom,
                  animateNameLabel: false,
                  animationDuration: const Duration(milliseconds: 1200),
                  animationCurve: Curves.easeOutCubic,
                ),
              ]),
        ),
      ]),
    );
  }
}

// ================================================================
// DAY TASKS LIST
// ================================================================

class _DayTasksList extends StatelessWidget {
  final List<TodayDayTask> tasks;
  final bool isDark;
  final ThemeData theme;

  const _DayTasksList(
      {required this.tasks, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks.map((task) {
        const color = Color(0xFF3B82F6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TAItemCardShell(
            accentColor: color,
            isDark: isDark,
            isOverdue: task.isOverdue,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TATaskCardHeader(
                    title: task.title,
                    status: task.status,
                    priority: task.priority,
                    isOverdue: task.isOverdue,
                    points: task.points,
                    reward: task.reward,
                  ),
                  if (task.timeStart != null) ...[
                    const SizedBox(height: 6),
                    TATimeChip(start: task.timeStart!, end: task.timeEnd),
                  ],
                  const SizedBox(height: 10),
                  TAProgressRow(
                      progress: task.progress, color: color, isDark: isDark),
                  if (task.penalty != null) ...[
                    const SizedBox(height: 8),
                    const TAPenaltyBadge(),
                  ],
                ]),
          ),
        );
      }).toList(),
    );
  }
}

// ================================================================
// WEEKLY TASKS LIST
// ================================================================

class _WeeklyTasksList extends StatelessWidget {
  final List<TodayWeekTask> tasks;
  final bool isDark;
  final ThemeData theme;

  const _WeeklyTasksList(
      {required this.tasks, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks.map((task) {
        const color = Color(0xFF8B5CF6);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TAItemCardShell(
            accentColor: color,
            isDark: isDark,
            isOverdue: false,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TATaskCardHeader(
                    title: task.title,
                    status: task.status,
                    priority: task.priority,
                    isOverdue: false,
                    points: task.points,
                    reward: task.reward,
                  ),
                  if (task.timeStart != null) ...[
                    const SizedBox(height: 6),
                    TATimeChip(start: task.timeStart!, end: task.timeEnd),
                  ],
                  const SizedBox(height: 10),
                  TAProgressRow(
                      progress: task.progress, color: color, isDark: isDark),
                  if (task.penalty != null) ...[
                    const SizedBox(height: 8),
                    const TAPenaltyBadge(),
                  ],
                ]),
          ),
        );
      }).toList(),
    );
  }
}

// ================================================================
// LONG GOALS LIST
// ================================================================

class _LongGoalsList extends StatelessWidget {
  final List<TodayLongGoal> goals;
  final bool isDark;
  final ThemeData theme;

  const _LongGoalsList(
      {required this.goals, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: goals.map((goal) {
        const color = Color(0xFF10B981);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TAItemCardShell(
            accentColor: color,
            isDark: isDark,
            isOverdue: goal.isOverdue,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TATaskCardHeader(
                    title: goal.title,
                    status: goal.status,
                    priority: goal.priority,
                    isOverdue: goal.isOverdue,
                    points: goal.points,
                    reward: goal.reward,
                  ),
                  const SizedBox(height: 10),
                  // Arc + bar side by side for long goals
                  TAArcProgressCard(
                    progress: goal.progress,
                    color: color,
                    isDark: isDark,
                    rightChild: TAProgressRow(
                        progress: goal.progress,
                        color: color,
                        isDark: isDark),
                  ),
                  if (goal.penalty != null) ...[
                    const SizedBox(height: 8),
                    const TAPenaltyBadge(),
                  ],
                ]),
          ),
        );
      }).toList(),
    );
  }
}

// ================================================================
// BUCKET LIST
// ================================================================

class _BucketList extends StatelessWidget {
  final List<TodayBucketEntry> items;
  final bool isDark;
  final ThemeData theme;

  const _BucketList(
      {required this.items, required this.isDark, required this.theme});

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final color = CardColorHelper.getBucketColor(item.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TAItemCardShell(
            accentColor: color,
            isDark: isDark,
            isOverdue: item.isOverdue,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Wrap(spacing: 6, children: [
                            StatusBadge(status: item.status),
                            if (item.isOverdue) const TAOverdueBadge(),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PointsBadge(points: item.points, animate: false),
                  ]),
                  const SizedBox(height: 10),
                  TAProgressRow(
                      progress: item.progress,
                      color: color,
                      isDark: isDark,
                      label: 'Checklist Progress'),
                  if (item.doneTime != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text('Done at ${_fmt(item.doneTime!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: color.withOpacity(0.8),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ]),
          ),
        );
      }).toList(),
    );
  }
}
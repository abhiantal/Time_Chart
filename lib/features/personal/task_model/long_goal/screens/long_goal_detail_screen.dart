// ============================================================
// FILE: lib/features/detail_screens/long_goal_detail_screen.dart
// NO shared_widgets imports — uses only custom widgets
// ============================================================

import 'package:flutter/material.dart';
import '../../../../../widgets/metric_indicators.dart';
import '../../../shared_widgets/detail_card_widgets.dart';
import '../../../shared_widgets/detail_chart_widgets.dart';
import '../../../shared_widgets/detail_shared_widgets.dart';
import '../models/long_goal_model.dart';

class LongGoalDetailScreen extends StatefulWidget {
  final LongGoalModel goal;
  const LongGoalDetailScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<LongGoalDetailScreen> createState() => _LongGoalDetailScreenState();
}

class _LongGoalDetailScreenState extends State<LongGoalDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tab;

  final _tabs = [
    tabDef('Plans',    Icons.view_week_rounded),
    tabDef('Timeline', Icons.schedule_rounded),
    tabDef('Feedback', Icons.chat_bubble_outline_rounded),
    tabDef('Analysis', Icons.analytics_rounded),
    tabDef('Social',   Icons.public_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

  LongGoalModel get g => widget.goal;

  Color get _accent {
    try {
      final hex = g.indicators.longGoalColor;
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  List<Color> get _grad {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return g.getCardGradient(isDarkMode: isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
            sliver: SliverToBoxAdapter(
              child: DetailAppBar(
                title: g.title,
                subtitle: '${g.categoryType ?? ''} · ${g.subTypes ?? ''}',
                gradientColors: _grad,
                tabController: _tab,
                tabs: _tabs,
                status: g.indicators.status,
                actions: [
                  TaskMetricIndicator(type: TaskMetricType.priority, value: g.indicators.priority, size: 32),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _PlansTab(g: g, accent: _accent),
            _TimelineTab(g: g, accent: _accent),
            _FeedbackTab(g: g, accent: _accent),
            _AnalysisTab(g: g, accent: _accent),
            DSocialTab(
              isPosted: g.socialInfo.isPosted,
              postedInfo: null,
              isShared: g.shareInfo.isShare,
              shareInfo: null,
              accentColor: _accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 1 — PLANS (merged weekly_plans + weekly_metrics)
// ============================================================
class _PlansTab extends StatelessWidget {
  final LongGoalModel g;
  final Color accent;
  const _PlansTab({required this.g, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans   = g.indicators.weeklyPlans;
    final metrics = g.metrics.weeklyMetrics;

    // merge by weekId
    final Map<String, Map<String, dynamic>> merged = {};
    for (final p in plans) {
      merged[p.weekId] = {'plan': p, 'metrics': null};
    }
    for (final m in metrics) {
      if (merged.containsKey(m.weekId)) {
        merged[m.weekId]!['metrics'] = m;
      } else {
        merged[m.weekId] = {'plan': null, 'metrics': m};
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Goal overview card
        DSectionCard(
          title: 'Goal Overview',
          icon: Icons.flag_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.help_outline_rounded,    label: 'Need',     value: g.description.need.isNotEmpty     ? g.description.need     : '—', color: accent),
            DInfoTile(icon: Icons.favorite_border_rounded, label: 'Motivation', value: g.description.motivation.isNotEmpty ? g.description.motivation : '—', color: Colors.pinkAccent),
            DInfoTile(icon: Icons.emoji_events_rounded,    label: 'Outcome',  value: g.description.outcome.isNotEmpty  ? g.description.outcome  : '—', color: DC.gold),
            DInfoTile(icon: Icons.category_rounded,        label: 'Category', value: '${g.categoryType ?? '—'} · ${g.subTypes ?? '—'}', color: accent),
          ],
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(DS.p16, DS.p16, DS.p16, DS.p8),
          child: Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: DS.p8),
              Text('WEEKLY BREAKDOWN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1.2),
              ),
              const Spacer(),
              Text('${g.completedWeeks}/${g.totalWeeks} done',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),

        // Weekly plan cards
        ...merged.entries.toList().asMap().entries.map((e) {
          final i    = e.key;
          final data = e.value.value;
          final plan = data['plan'] as WeeklyPlan?;
          final m    = data['metrics'] as WeekMetrics?;

          return WeeklyGoalPlanCard(
            weekId:            plan?.weekId ?? m?.weekId ?? 'w${i+1}',
            weeklyGoal:        plan?.weeklyGoal ?? 'Week ${i+1}',
            mood:              plan?.mood ?? 'focused',
            isCompleted:       plan?.isCompleted ?? false,
            progress:          m?.progress ?? 0,
            rating:            m?.rating ?? 1.0,
            pointsEarned:      m?.pointsEarned ?? 0,
            completedDays:     m?.completedDays ?? 0,
            totalScheduledDays: m?.totalScheduledDays ?? 0,
            pendingGoalDays:   m?.pendingGoalDays ?? 0,
            pendingDates:      m?.pendingDates ?? [],
            penalty: m?.penalty != null
                ? {'penalty_points': m!.penalty!.penaltyPoints, 'reason': m.penalty!.reason}
                : null,
            accentColor: accent,
            weekIndex:   i,
          );
        }),
      ],
    );
  }
}

// ============================================================
// TAB 2 — TIMELINE
// ============================================================
class _TimelineTab extends StatelessWidget {
  final LongGoalModel g;
  final Color accent;
  const _TimelineTab({required this.g, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tl = g.timeline;
    final ws = tl.workSchedule;
    final slot = ws.preferredTimeSlot;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Status + priority row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          child: Row(
            children: [
              TaskMetricIndicator(type: TaskMetricType.status,   value: g.indicators.status,   size: 44, showLabel: true),
              const SizedBox(width: DS.p12),
              TaskMetricIndicator(type: TaskMetricType.priority, value: g.indicators.priority, size: 44, showLabel: true),
              const Spacer(),
              if (g.isOverdue)
                TaskMetricIndicator(type: TaskMetricType.overdue, value: true, size: 36, showLabel: true),
            ],
          ),
        ),

        DTimelineCard(startDate: tl.startDate, endDate: tl.endDate, accentColor: accent),

        DSectionCard(
          title: 'Date Range',
          icon: Icons.date_range_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.play_circle_outline_rounded, label: 'Start Date',  value: DF.full(tl.startDate), color: DC.inProgress),
            DInfoTile(icon: Icons.flag_outlined,               label: 'End Date',    value: DF.full(tl.endDate),   color: g.isOverdue ? DC.missed : DC.completed),
            DInfoTile(icon: Icons.today_rounded,               label: 'Time Left',   value: DF.daysLeft(tl.endDate), color: g.isOverdue ? DC.missed : accent),
            DInfoTile(icon: Icons.calendar_month_rounded,      label: 'Total Days',  value: '${g.metrics.totalDays} days', color: accent),
          ],
        ),

        DSectionCard(
          title: 'Work Schedule',
          icon: Icons.work_outline_rounded,
          accentColor: accent,
          childPadding: const EdgeInsets.fromLTRB(DS.p8, DS.p12, DS.p8, DS.p16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DS.p8, vertical: DS.p4),
              child: WorkDaysRow(workDays: ws.workDays, color: accent),
            ),
            const SizedBox(height: DS.p8),
            DInfoTile(icon: Icons.access_time_rounded,    label: 'Hours / Day', value: '${ws.hoursPerDay} hours', color: accent),
            DInfoTile(icon: Icons.wb_sunny_outlined,    label: 'Start Time',  value: slot != null ? DF.time(slot.startingTime) : 'Not set', color: const Color(0xFFFF9800)),
            DInfoTile(icon: Icons.nightlight_rounded,   label: 'End Time',    value: slot != null ? DF.time(slot.endingTime)   : 'Not set', color: const Color(0xFF5C6BC0)),
          ],
        ),

        DSectionCard(
          title: 'Goal Metrics',
          icon: Icons.bar_chart_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.check_circle_outline_rounded, label: 'Completed Days', value: '${g.metrics.completedDays} / ${g.metrics.totalDays}', color: DC.completed),
            DInfoTile(icon: Icons.pending_actions_rounded,      label: 'Pending Tasks',  value: '${g.metrics.tasksPending}', color: DC.pending),
            DInfoTile(icon: Icons.calendar_view_week_rounded,   label: 'Total Weeks',    value: '${g.totalWeeks} weeks',     color: accent),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// TAB 3 — FEEDBACK
// ============================================================
class _FeedbackTab extends StatelessWidget {
  final LongGoalModel g;
  final Color accent;
  const _FeedbackTab({required this.g, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalLog = g.goalLog.weeklyLogs;
    final total = goalLog.fold<int>(0, (s, w) => s + w.dailyFeedback.length);

    if (total == 0) {
      return DEmptyState(
        title: 'No Feedback Yet',
        message: 'Start logging daily feedback to track your goal progress.',
        icon: Icons.chat_bubble_outline_rounded,
        color: accent,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Stats banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          child: Row(
            children: [
              _FStat(icon: Icons.chat_bubble_rounded,   value: '$total',                label: 'Total',   color: accent),
              const SizedBox(width: DS.p12),
              _FStat(icon: Icons.check_circle_rounded,  value: '${g.metrics.completedDays}', label: 'Done', color: DC.completed),
              const SizedBox(width: DS.p12),
              _FStat(icon: Icons.schedule_rounded,      value: '${g.metrics.tasksPending}',  label: 'Pending', color: DC.pending),
            ],
          ),
        ),

        ...goalLog.map((weekLog) {
          final hasFeedback = weekLog.dailyFeedback.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.p16, DS.p16, DS.p16, DS.p8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DS.r100),
                      ),
                      child: Text(weekLog.weekId.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: DS.p8),
                    Text('${weekLog.dailyFeedback.length} entry(s)',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              if (!hasFeedback)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p4),
                  child: Container(
                    padding: const EdgeInsets.all(DS.p12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(DS.r12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inbox_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
                        const SizedBox(width: DS.p8),
                        Text('No feedback logged this week',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...weekLog.dailyFeedback.map((fb) {
                final dp = fb.dailyProgress;
                return GoalDayFeedbackCard(
                  feedbackDay:      fb.feedbackDay,
                  feedbackText:     fb.feedbackText,
                  mediaUrl:         fb.mediaUrl,
                  progress:         dp?.progress ?? 0,
                  rating:           dp?.rating ?? 0,
                  pointsEarned:     dp?.pointsEarned ?? 0,
                  isComplete:       dp?.isComplete ?? false,
                  isAuthentic:      dp?.isAuthentic ?? true,
                  motivationalQuote: dp?.motivationalQuote,
                  accentColor:      accent,
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

class _FStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _FStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DS.p12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DS.r12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 4 — ANALYSIS
// ============================================================
class _AnalysisTab extends StatelessWidget {
  final LongGoalModel g;
  final Color accent;
  const _AnalysisTab({required this.g, required this.accent});

  @override
  Widget build(BuildContext context) {
    final a = g.analysis;
    final wm = g.metrics.weeklyMetrics;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        ProgressOverviewCard(
          progress:         a.averageProgress,
          rating:           a.averageRating,
          pointsEarned:     a.pointsEarned,
          consistencyScore: a.consistencyScore,
          completedDays:    g.metrics.completedDays,
          totalDays:        g.metrics.totalDays,
          accentColor:      accent,
        ),

        MultiMetricRings(
          progress:    a.averageProgress,
          rating:      a.averageRating,
          consistency: a.consistencyScore,
          accentColor: accent,
        ),

        if (wm.isNotEmpty)
          WeeklyBarChart(
            items: wm.map((m) => {
              'label':    m.weekId.toUpperCase(),
              'progress': m.progress,
            }).toList(),
            accentColor: accent,
            title: 'Week-by-Week Progress',
          ),

        AnalysisFullCard(
          averageProgress:  a.averageProgress,
          averageRating:    a.averageRating,
          pointsEarned:     a.pointsEarned,
          consistencyScore: a.consistencyScore,
          suggestions:      a.suggestions,
          penaltyData: a.totalPenalty != null
              ? {'penalty_points': a.totalPenalty!.penaltyPoints, 'reason': a.totalPenalty!.reason}
              : null,
          accentColor: accent,
        ),

        if (a.rewardPackage != null)
          DRewardBanner.from(
            earned:      a.rewardPackage!.earned,
            tier:        a.rewardPackage!.tier.name,
            tierLevel:   a.rewardPackage!.tierLevel,
            tagName:     a.rewardPackage!.tagName,
            tagReason:   a.rewardPackage!.tagReason ?? '',
            suggestion:  a.rewardPackage!.suggestion,
            rewardColor: null,
            points:      a.pointsEarned,
          ),
      ],
    );
  }
}

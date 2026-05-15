// ============================================================
// FILE: lib/features/detail_screens/week_task_detail_screen.dart
// NO shared_widgets imports
// ============================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../../../../../widgets/metric_indicators.dart';
import '../../../shared_widgets/detail_card_widgets.dart';
import '../../../shared_widgets/detail_chart_widgets.dart';
import '../../../shared_widgets/detail_shared_widgets.dart';
import '../models/week_task_model.dart';


class WeekTaskDetailScreen extends StatefulWidget {
  final WeekTaskModel task;
  const WeekTaskDetailScreen({super.key, required this.task});

  @override
  State<WeekTaskDetailScreen> createState() => _WeekTaskDetailScreenState();
}

class _WeekTaskDetailScreenState extends State<WeekTaskDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tab;

  final _tabs = [
    tabDef('About',    Icons.info_outline_rounded),
    tabDef('Timeline', Icons.schedule_rounded),
    tabDef('Feedback', Icons.chat_bubble_outline_rounded),
    tabDef('Summary',  Icons.analytics_rounded),
    tabDef('Social',   Icons.public_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

  WeekTaskModel get t => widget.task;

  Color get _accent => CardColorHelper.getPriorityColor(t.indicators.priority);

  List<Color> get _grad {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return t.getCardGradient(isDarkMode: isDark);
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
                title: t.aboutTask.taskName,
                subtitle: '${t.categoryType} · ${t.subTypes}',
                gradientColors: _grad,
                tabController: _tab,
                tabs: _tabs,
                status: t.indicators.status,
                actions: [
                  TaskMetricIndicator(type: TaskMetricType.priority, value: t.indicators.priority, size: 32),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _AboutTab(t: t, accent: _accent),
            _TimelineTab(t: t, accent: _accent),
            _FeedbackTab(t: t, accent: _accent),
            _SummaryTab(t: t, accent: _accent),
            DSocialTab(
              isPosted: t.socialInfo.isPosted,
              isShared: t.shareInfo.isShare,
              accentColor: _accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 1 — ABOUT
// ============================================================
class _AboutTab extends StatelessWidget {
  final WeekTaskModel t;
  final Color accent;
  const _AboutTab({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final about = t.aboutTask;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Cover image
        if (about.mediaUrl != null && about.mediaUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DS.r20),
              child: SizedBox(
                height: 200,
                child: EnhancedMediaDisplay(
                  mediaFiles: convertUrlsToEnhancedMedia([about.mediaUrl!]),
                  config: MediaDisplayConfig(
                    layoutMode: MediaLayoutMode.single,
                    mediaBucket: MediaBucket.weeklyTaskMedia,
                    allowDelete: false,
                    allowFullScreen: true,
                    borderRadius: DS.r20,
                    imageFit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

        // Task details
        DSectionCard(
          title: 'Task Details',
          icon: Icons.task_alt_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.drive_file_rename_outline_rounded, label: 'Task Name',   value: about.taskName, color: accent),
            DInfoTile(icon: Icons.description_outlined, label: 'Description', value: (about.taskDescription == null || about.taskDescription!.isEmpty) ? '—' : about.taskDescription!, color: accent),
            DInfoTile(icon: Icons.category_rounded, label: 'Category', value: '${t.categoryType} · ${t.subTypes}', color: accent),
          ],
        ),

        // Quick metric indicators row using TaskMetricIndicator
        DSectionCard(
          title: 'Quick Overview',
          icon: Icons.dashboard_rounded,
          accentColor: accent,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.p8),
              child: TaskMetricIndicatorRow(
                indicators: [
                  TaskMetricIndicator(type: TaskMetricType.status,   value: t.indicators.status,   size: 44, showLabel: true),
                  TaskMetricIndicator(type: TaskMetricType.priority, value: t.indicators.priority, size: 44, showLabel: true),
                  TaskMetricIndicator(type: TaskMetricType.progress, value: t.summary.progress,    size: 44, showLabel: true),
                  TaskMetricIndicator(type: TaskMetricType.rating,   value: t.summary.rating,      size: 44, showLabel: true),
                ],
                spacing: DS.p12,
                alignment: MainAxisAlignment.spaceEvenly,
              ),
            ),
          ],
        ),

        // Scheduled days
        DSectionCard(
          title: 'Scheduled Days',
          icon: Icons.calendar_view_week_rounded,
          accentColor: accent,
          childPadding: const EdgeInsets.fromLTRB(DS.p16, DS.p12, DS.p16, DS.p16),
          children: [
            WorkDaysRow(workDays: t.scheduledDays, color: accent),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// TAB 2 — TIMELINE
// ============================================================
class _TimelineTab extends StatelessWidget {
  final WeekTaskModel t;
  final Color accent;
  const _TimelineTab({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tl = t.timeline;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          child: Row(
            children: [
              TaskMetricIndicator(type: TaskMetricType.status, value: t.indicators.status, size: 44, showLabel: true),
              const SizedBox(width: DS.p12),
              if (t.isOverdue)
                TaskMetricIndicator(type: TaskMetricType.overdue, value: true, size: 36, showLabel: true),
              const Spacer(),
              TaskMetricIndicator(type: TaskMetricType.deadline, value: tl.expectedEndingDate, size: 36, showLabel: true),
            ],
          ),
        ),

        DTimelineCard(startDate: tl.startingDate, endDate: tl.expectedEndingDate, accentColor: accent),

        DSectionCard(
          title: 'Schedule',
          icon: Icons.date_range_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.play_circle_outline_rounded, label: 'Start Date', value: DF.full(tl.startingDate), color: DC.inProgress),
            DInfoTile(icon: Icons.flag_outlined,               label: 'End Date',   value: DF.full(tl.expectedEndingDate), color: t.isOverdue ? DC.missed : DC.completed),
            DInfoTile(icon: Icons.timelapse_rounded,           label: 'Remaining',  value: DF.daysLeft(tl.expectedEndingDate), color: t.isOverdue ? DC.missed : accent),
          ],
        ),

        DSectionCard(
          title: 'Daily Slot',
          icon: Icons.access_time_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.login_rounded,    label: 'Start Time', value: DF.time(tl.startingTime), color: const Color(0xFFFF9800)),
            DInfoTile(icon: Icons.logout_rounded,   label: 'End Time',   value: DF.time(tl.endingTime),   color: const Color(0xFF5C6BC0)),
            DInfoTile(icon: Icons.timelapse_rounded,label: 'Duration',   value: _fmtDuration(tl.taskDuration), color: accent),
            DInfoTile(icon: Icons.event_repeat_rounded, label: 'Total Scheduled', value: '${tl.totalScheduledDays} days', color: accent),
          ],
        ),

        DSectionCard(
          title: 'Work Days',
          icon: Icons.calendar_view_week_rounded,
          accentColor: accent,
          childPadding: const EdgeInsets.fromLTRB(DS.p16, DS.p12, DS.p16, DS.p16),
          children: [WorkDaysRow(workDays: t.scheduledDays, color: accent)],
        ),
      ],
    );
  }

  String _fmtDuration(DateTime dt) {
    final h = dt.hour; final m = dt.minute;
    if (h > 0 && m > 0) return '$h hr $m min';
    if (h > 0) return '$h hours';
    if (m > 0) return '$m minutes';
    return '—';
  }
}

// ============================================================
// TAB 3 — FEEDBACK
// ============================================================
class _FeedbackTab extends StatelessWidget {
  final WeekTaskModel t;
  final Color accent;
  const _FeedbackTab({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final daily = t.dailyProgress;

    if (daily.isEmpty) {
      return DEmptyState(
        title: 'No Feedback Yet',
        message: 'Log daily feedback to track your weekly task progress.',
        icon: Icons.chat_bubble_outline_rounded, color: accent,
      );
    }

    final sorted = [...daily]..sort((a, b) => b.taskDate.compareTo(a.taskDate));

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          child: Row(
            children: [
              _FStat(icon: Icons.check_rounded,       value: '${t.totalCompletedDays}',  label: 'Done',  color: DC.completed),
              const SizedBox(width: DS.p12),
              _FStat(icon: Icons.chat_rounded,         value: '${t.totalFeedbacks}',      label: 'Total', color: accent),
              const SizedBox(width: DS.p12),
              _FStat(icon: Icons.photo_library_rounded, value: '${_mediaCount(t)}',       label: 'Media', color: DC.purple),
            ],
          ),
        ),
        ...sorted.asMap().entries.map((e) {
          final dp = e.value;
          return WeekDayFeedbackCard(
            taskDate:    dp.taskDate,
            dayName:     dp.dayName,
            feedbacks:   dp.feedbacks.map((f) => {
              'mediaUrl': f.mediaUrl,
              'text':     f.finalText,
              'count':    f.feedbackCount,
            }).toList(),
            progress:    dp.dailyMetrics.progress,
            rating:      dp.dailyMetrics.rating,
            pointsEarned: dp.dailyMetrics.pointsEarned,
            isComplete:  dp.dailyMetrics.isComplete,
            accentColor: accent,
          );
        }),
      ],
    );
  }

  int _mediaCount(WeekTaskModel t) =>
      t.dailyProgress.fold(0, (s, d) => s + d.feedbacks.where((f) => f.mediaUrl != null && f.mediaUrl!.isNotEmpty).length);
}

class _FStat extends StatelessWidget {
  final IconData icon; final String value; final String label; final Color color;
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
// TAB 4 — SUMMARY
// ============================================================
class _SummaryTab extends StatelessWidget {
  final WeekTaskModel t;
  final Color accent;
  const _SummaryTab({required this.t, required this.accent});

  @override
  Widget build(BuildContext context) {
    final s = t.summary;
    final rp = s.rewardPackage;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        ProgressOverviewCard(
          progress:         s.progress.toDouble(),
          rating:           s.rating,
          pointsEarned:     s.pointsEarned,
          consistencyScore: s.completionRate,
          completedDays:    s.completedDays,
          totalDays:        s.totalScheduledDays,
          accentColor:      accent,
          statusText:       s.status,
        ),

        // Daily bar chart
        if (t.dailyProgress.isNotEmpty)
          WeeklyBarChart(
            items: t.dailyProgress.map((dp) => {
              'label':    dp.dayName.isNotEmpty ? dp.dayName.substring(0, 3) : dp.taskDate.substring(0, 3),
              'progress': dp.dailyMetrics.progress,
            }).toList(),
            accentColor: accent,
            title: 'Daily Progress',
          ),

        MultiMetricRings(
          progress:    s.progress.toDouble(),
          rating:      s.rating,
          consistency: s.completionRate,
          accentColor: accent,
        ),

        DSectionCard(
          title: 'Week Summary',
          icon: Icons.summarize_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.trending_up_rounded,        label: 'Status',      value: s.status.titleCase, color: accent),
            DInfoTile(icon: Icons.check_circle_rounded,       label: 'Completed',   value: '${s.completedDays} / ${s.totalScheduledDays}', color: DC.completed),
            DInfoTile(icon: Icons.schedule_rounded,           label: 'Pending',     value: '${s.pendingGoalDays}', color: DC.pending),
            if (s.bestDay  != 'N/A') DInfoTile(icon: Icons.emoji_events_rounded,        label: 'Best Day',  value: s.bestDay,  color: DC.gold),
            if (s.worstDay != 'N/A') DInfoTile(icon: Icons.sentiment_dissatisfied_rounded, label: 'Worst Day', value: s.worstDay, color: DC.missed),
          ],
        ),

        if (s.penalty != null && s.penalty!.penaltyPoints > 0)
          DPenaltyBanner(points: s.penalty!.penaltyPoints, reason: s.penalty!.reason),

        if (rp != null)
          DRewardBanner.from(
            earned:      rp.earned,
            tier:        rp.tier.name,
            tierLevel:   rp.tierLevel,
            tagName:     rp.tagName,
            tagReason:   s.weeklyTagName,
            suggestion:  rp.suggestion,
            rewardColor: null,
            points:      s.pointsEarned,
          ),
      ],
    );
  }
}

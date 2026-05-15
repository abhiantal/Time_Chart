// ============================================================
// FILE: lib/features/detail_screens/bucket_detail_screen.dart
// NO shared_widgets imports
// ============================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/media_utility/media_display.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../shared_widgets/detail_card_widgets.dart';
import '../../shared_widgets/detail_chart_widgets.dart';
import '../../shared_widgets/detail_shared_widgets.dart';
import '../models/bucket_model.dart';


class BucketDetailScreen extends StatefulWidget {
  final BucketModel bucket;
  const BucketDetailScreen({Key? key, required this.bucket}) : super(key: key);

  @override
  State<BucketDetailScreen> createState() => _BucketDetailScreenState();
}

class _BucketDetailScreenState extends State<BucketDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tab;

  final _tabs = [
    tabDef('Details',   Icons.info_outline_rounded),
    tabDef('Timeline',  Icons.schedule_rounded),
    tabDef('Checklist', Icons.checklist_rounded),
    tabDef('Analysis',  Icons.analytics_rounded),
    tabDef('Social',    Icons.public_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

  BucketModel get b => widget.bucket;

  Color get _accent => CardColorHelper.getPriorityColor(b.metadata.priority);

  List<Color> get _grad {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return b.getCardGradient(isDarkMode: isDark);
  }

  String get _status {
    if (b.isCompleted) return 'completed';
    final due = b.timeline.dueDate;
    if (due != null && DateTime.now().isAfter(due)) return 'missed';
    if (b.metadata.averageProgress > 0) return 'inProgress';
    return 'pending';
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
                title: b.title,
                subtitle: '${b.categoryType ?? ''} · ${b.subTypes ?? ''}',
                gradientColors: _grad,
                tabController: _tab,
                tabs: _tabs,
                status: _status,
                actions: [
                  TaskMetricIndicator(type: TaskMetricType.priority, value: b.metadata.priority, size: 32),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _DetailsTab(b: b, accent: _accent),
            _TimelineTab(b: b, accent: _accent),
            _ChecklistTab(b: b, accent: _accent),
            _AnalysisTab(b: b, accent: _accent),
            DSocialTab(
              isPosted: b.socialInfo?.isPosted ?? false,
              isShared: b.shareInfo?.isShare ?? false,
              accentColor: _accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 1 — DETAILS
// ============================================================
class _DetailsTab extends StatelessWidget {
  final BucketModel b;
  final Color accent;
  const _DetailsTab({required this.b, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = b.details;
    final doneCount = b.checklist.where((i) => i.done).length;
    final total = b.checklist.length;
    final pct = b.metadata.averageProgress;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Media gallery
        if (details.mediaUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DS.r20),
              child: SizedBox(
                height: 220,
                child: EnhancedMediaDisplay(
                  mediaFiles: convertUrlsToEnhancedMedia(details.mediaUrl),
                  config: MediaDisplayConfig(
                    layoutMode: details.mediaUrl.length == 1 ? MediaLayoutMode.single : MediaLayoutMode.carousel,
                    mediaBucket: MediaBucket.bucketMedia,
                    allowDelete: false, allowFullScreen: true,
                    borderRadius: DS.r20, imageFit: BoxFit.cover, maxHeight: 220,
                  ),
                ),
              ),
            ),
          ),

        // Progress + checklist stats
        Container(
          margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          padding: const EdgeInsets.all(DS.p16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(DS.r20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))],
          ),
          child: Row(
            children: [
              AdvancedProgressIndicator(
                progress: pct / 100, size: 90, strokeWidth: 8,
                shape: ProgressShape.circular,
                gradientColors: [accent.withOpacity(0.6), accent],
                backgroundColor: accent.withOpacity(0.12),
                labelStyle: ProgressLabelStyle.percentage,
                labelTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accent),
                animated: true,
              ),
              const SizedBox(width: DS.p20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DS.p8),
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, size: 13, color: accent),
                        const SizedBox(width: 4),
                        Text('$doneCount / $total tasks',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: DS.p8),
                    HProgressBar(
                      progress: total == 0 ? 0 : (doneCount / total * 100),
                      height: 6, color: accent,
                    ),
                    if (b.isCompleted) ...[
                      const SizedBox(height: DS.p8),
                      DBadge(label: 'Completed! 🎉', color: DC.completed),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick metrics using TaskMetricIndicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          child: Row(
            children: [
              TaskMetricIndicator(type: TaskMetricType.priority,    value: b.metadata.priority,          size: 44, showLabel: true),
              const SizedBox(width: DS.p12),
              TaskMetricIndicator(type: TaskMetricType.pointsEarned, value: b.metadata.totalPointsEarned, size: 44, showLabel: true, customLabel: 'Points'),
              const SizedBox(width: DS.p12),
              TaskMetricIndicator(type: TaskMetricType.rating,       value: b.metadata.averageRating,     size: 44, showLabel: true),
            ],
          ),
        ),

        // Description
        DSectionCard(
          title: 'About This Bucket',
          icon: Icons.info_outline_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.description_outlined,    label: 'Description', value: details.description.isNotEmpty ? details.description : '—', color: accent),
            DInfoTile(icon: Icons.favorite_border_rounded, label: 'Motivation',  value: details.motivation.isNotEmpty ? details.motivation : '—', color: Colors.pinkAccent),
            DInfoTile(icon: Icons.emoji_events_rounded,    label: 'Outcome',     value: details.outCome.isNotEmpty ? details.outCome : '—', color: DC.gold),
            DInfoTile(icon: Icons.category_rounded,          label: 'Category',    value: '${b.categoryType ?? '—'} · ${b.subTypes ?? '—'}', color: accent),
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
  final BucketModel b;
  final Color accent;
  const _TimelineTab({required this.b, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tl = b.timeline;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // No-timeline placeholder or visual
        if (!tl.isUnspecified && tl.startDate != null)
          DTimelineCard(startDate: tl.startDate, endDate: tl.dueDate, accentColor: accent)
        else
          Padding(
            padding: const EdgeInsets.all(DS.p16),
            child: Container(
              padding: const EdgeInsets.all(DS.p32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(DS.r20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.all_inclusive_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: DS.p16),
                  Text('Open-Ended Goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: DS.p8),
                  Text('No deadline set — complete at your own pace.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

        DSectionCard(
          title: 'Timeline Details',
          icon: Icons.date_range_rounded,
          accentColor: accent,
          children: [
            DInfoTile(icon: Icons.add_circle_outline_rounded,    label: 'Added On',   value: DF.full(tl.addedDate), color: accent),
            DInfoTile(
              icon: Icons.play_circle_outline_rounded, label: 'Start Date',
              value: tl.startDate != null ? DF.full(tl.startDate) : 'Not set',
              color: tl.startDate != null ? DC.inProgress : Colors.grey,
            ),
            DInfoTile(
              icon: Icons.flag_outlined, label: 'Due Date',
              value: tl.dueDate != null ? DF.full(tl.dueDate) : 'No deadline',
              color: tl.dueDate != null
                  ? (DateTime.now().isAfter(tl.dueDate!) ? DC.missed : DC.completed)
                  : Colors.grey,
            ),
            if (tl.completeDate != null)
              DInfoTile(icon: Icons.check_circle_rounded, label: 'Completed On', value: DF.full(tl.completeDate), color: DC.completed),
            DInfoTile(
              icon: Icons.all_inclusive_rounded, label: 'Type',
              value: tl.isUnspecified ? 'Open-ended (No deadline)' : 'Fixed timeline',
              color: accent,
            ),
          ],
        ),

        if (tl.dueDate != null && DateTime.now().isAfter(tl.dueDate!) && !b.isCompleted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
            child: TaskMetricIndicator(type: TaskMetricType.overdue, value: true, size: 36, showLabel: true),
          ),
      ],
    );
  }
}

// ============================================================
// TAB 3 — CHECKLIST (expandable DayTaskCard per item)
// ============================================================
class _ChecklistTab extends StatelessWidget {
  final BucketModel b;
  final Color accent;
  const _ChecklistTab({required this.b, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = b.checklist;
    final done = list.where((i) => i.done).toList();
    final pending = list.where((i) => !i.done).toList();
    final earnedPts = done.fold<int>(0, (s, i) => s + i.points);
    final totalPts  = list.fold<int>(0, (s, i) => s + i.points);

    if (list.isEmpty) {
      return DEmptyState(
        title: 'No Checklist Items',
        message: 'Add items to break down your bucket goal into steps.',
        icon: Icons.checklist_rounded, color: accent,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
          padding: const EdgeInsets.all(DS.p16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(DS.r16),
            border: Border.all(color: accent.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _CStat(icon: Icons.checklist_rounded, value: '${done.length} / ${list.length}', label: 'Done', color: accent)),
                  Expanded(child: _CStat(icon: Icons.bolt_rounded, value: '$earnedPts / $totalPts', label: 'Points', color: DC.purple)),
                ],
              ),
              const SizedBox(height: DS.p12),
              HProgressBar(
                progress: list.isEmpty ? 0 : (done.length / list.length * 100),
                height: 10, color: accent, showPercent: true,
              ),
            ],
          ),
        ),

        // Completed items
        if (done.isNotEmpty) ...[
          _SectionLabel(label: 'COMPLETED', count: done.length, color: DC.completed, icon: Icons.check_circle_rounded),
          ...done.asMap().entries.map((e) => BucketChecklistCard(
            id: e.value.id, task: e.value.task, done: e.value.done,
            points: e.value.points, feedbacks: e.value.feedbacks,
            date: e.value.date, accentColor: accent,
          )),
        ],

        // Pending items
        if (pending.isNotEmpty) ...[
          _SectionLabel(label: 'PENDING', count: pending.length, color: DC.pending, icon: Icons.radio_button_unchecked_rounded),
          ...pending.asMap().entries.map((e) => BucketChecklistCard(
            id: e.value.id, task: e.value.task, done: e.value.done,
            points: e.value.points, feedbacks: e.value.feedbacks,
            date: e.value.date, accentColor: accent,
          )),
        ],
      ],
    );
  }
}

class _CStat extends StatelessWidget {
  final IconData icon; final String value; final String label; final Color color;
  const _CStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label; final int count; final Color color; final IconData icon;
  const _SectionLabel({required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DS.p16, DS.p16, DS.p16, DS.p8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: DS.p8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
          const SizedBox(width: DS.p8),
          DBadge(label: '$count', color: color),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 4 — ANALYSIS
// ============================================================
class _AnalysisTab extends StatelessWidget {
  final BucketModel b;
  final Color accent;
  const _AnalysisTab({required this.b, required this.accent});

  @override
  Widget build(BuildContext context) {
    final meta = b.metadata;
    final summary = meta.summary;
    final rp = meta.rewardPackage;
    final doneCount = b.checklist.where((i) => i.done).length;

    return ListView(
      padding: const EdgeInsets.only(top: DS.p16, bottom: 100),
      children: [
        ProgressOverviewCard(
          progress:         meta.averageProgress,
          rating:           meta.averageRating,
          pointsEarned:     meta.totalPointsEarned,
          consistencyScore: b.checklist.isEmpty ? 0 : (doneCount / b.checklist.length * 100),
          completedDays:    doneCount,
          totalDays:        b.checklist.length,
          accentColor:      accent,
        ),

        // Checklist bar chart — each item as a bar
        if (b.checklist.isNotEmpty)
          WeeklyBarChart(
            items: b.checklist.asMap().entries.map((e) => {
              'label':    'T${e.key + 1}',
              'progress': e.value.done ? 100 : 0,
            }).toList(),
            accentColor: accent,
            title: 'Checklist Progress',
          ),

        MultiMetricRings(
          progress:    meta.averageProgress,
          rating:      meta.averageRating,
          consistency: b.checklist.isEmpty ? 0 : (doneCount / b.checklist.length * 100),
          accentColor: accent,
        ),

        // AI Summary
        if (summary != null)
          DSectionCard(
            title: 'AI Insight',
            icon: Icons.psychology_rounded,
            accentColor: accent,
            children: [
              if (summary.summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(DS.p8),
                  child: Text(summary.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              if (summary.plan.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DS.p8, vertical: DS.p4),
                  child: Text('Suggested Plan:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: accent),
                  ),
                ),
                ...summary.plan.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DS.p8, vertical: DS.p4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right_rounded, color: accent, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(step,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              if (summary.suggestion.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(DS.p8),
                  padding: const EdgeInsets.all(DS.p12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(DS.r12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, color: accent, size: 15),
                      const SizedBox(width: DS.p8),
                      Expanded(
                        child: Text(summary.suggestion,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        if (rp != null)
          DRewardBanner.from(
            earned:      rp.earned,
            tier:        rp.tier.name,
            tierLevel:   rp.tierLevel,
            tagName:     rp.tagName,
            tagReason:   rp.tagReason,
            suggestion:  rp.suggestion,
            rewardColor: null,
            points:      rp.points,
          ),
      ],
    );
  }
}
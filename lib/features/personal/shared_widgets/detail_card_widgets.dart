// ============================================================
// FILE: lib/features/detail_screens/shared/detail_card_widgets.dart
// Expandable feedback/checklist cards — NO shared_widgets imports
// Uses: AdvancedProgressIndicator, EnhancedMediaDisplay,
//       CardColorHelper + detail_shared_widgets
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/media_utility/media_display.dart';

import '../../../media_utility/universal_media_service.dart';
import '../../../widgets/circular_progress_indicator.dart';
import 'detail_shared_widgets.dart';
import 'detail_chart_widgets.dart';
import '../../personal/bucket_model/models/bucket_model.dart';

// ============================================================
// DAY TASK CARD — expandable base card for all 3 screens
// ============================================================
class DayTaskCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final int progress;          // 0–100
  final double rating;
  final int pointsEarned;
  final bool isComplete;
  final Color accentColor;
  final Widget expandedContent;
  final bool isInitiallyExpanded;
  final String? badge;

  const DayTaskCard({
    Key? key,
    required this.title, required this.subtitle,
    required this.progress, required this.rating,
    required this.pointsEarned, required this.isComplete,
    required this.accentColor, required this.expandedContent,
    this.isInitiallyExpanded = false, this.badge,
  }) : super(key: key);

  @override
  State<DayTaskCard> createState() => _DayTaskCardState();
}

class _DayTaskCardState extends State<DayTaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expand;
  late Animation<double> _rotate;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.isInitiallyExpanded;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(_expand);
    if (_open) _ctrl.value = 1;
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _open = !_open;
      _open ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  Color get _pColor => DC.forProgress(widget.progress);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DS.r16),
        border: Border.all(
          color: _open ? widget.accentColor.withOpacity(0.35) : theme.dividerColor.withOpacity(0.25),
          width: _open ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _open ? widget.accentColor.withOpacity(0.1) : Colors.black.withOpacity(0.04),
            blurRadius: _open ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(DS.r16),
              child: Padding(
                padding: const EdgeInsets.all(DS.p12),
                child: Row(
                  children: [
                    // Circular progress using AdvancedProgressIndicator
                    AdvancedProgressIndicator(
                      progress: widget.progress / 100,
                      size: 58,
                      strokeWidth: 5,
                      shape: ProgressShape.circular,
                      gradientColors: [_pColor.withOpacity(0.5), _pColor],
                      backgroundColor: _pColor.withOpacity(0.12),
                      labelStyle: ProgressLabelStyle.percentage,
                      labelTextStyle: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: _pColor,
                      ),
                      animated: true,
                      animationDuration: const Duration(milliseconds: 800),
                    ),
                    const SizedBox(width: DS.p12),
                    // Title area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              DBadge(
                                label: widget.isComplete ? 'Done' : 'Pending',
                                color: widget.isComplete ? DC.completed : DC.pending,
                                icon: widget.isComplete ? Icons.check_rounded : Icons.schedule_rounded,
                              ),
                              if (widget.badge != null) ...[
                                const SizedBox(width: DS.p8),
                                DBadge(label: widget.badge!, color: widget.accentColor),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DS.p8),
                    // Points + chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.pointsEarned > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: DC.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r100),
                            ),
                            child: Text('+${widget.pointsEarned}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DC.purple),
                            ),
                          ),
                        const SizedBox(height: 8),
                        RotationTransition(
                          turns: _rotate,
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Expanded content ──
          SizeTransition(
            sizeFactor: _expand,
            child: Column(
              children: [
                Divider(height: 1, color: widget.accentColor.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.all(DS.p12),
                  child: widget.expandedContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FEEDBACK EXPANDED CONTENT
// ============================================================
class FeedbackContent extends StatelessWidget {
  final List<Map<String, dynamic>> feedbacks; // {mediaUrl, text, count}
  final String? motivationalQuote;
  final double? rating;
  final MediaBucket mediaBucket;
  final Color accentColor;

  const FeedbackContent({
    Key? key,
    required this.feedbacks, this.motivationalQuote, this.rating,
    required this.mediaBucket, required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (feedbacks.isEmpty) {
      return Row(
        children: [
          Icon(Icons.inbox_outlined, color: theme.colorScheme.onSurface.withOpacity(0.3), size: 18),
          const SizedBox(width: DS.p8),
          Text('No feedback submitted yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4), fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating stars
        if (rating != null && rating! > 0) ...[
          Row(
            children: [
              Text('Rating: ',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              StarRating(rating: rating!, size: 16),
              const SizedBox(width: DS.p8),
              Text(rating!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DC.gold),
              ),
            ],
          ),
          const SizedBox(height: DS.p12),
        ],
        // Feedback entries
        ...feedbacks.map((fb) => _FeedbackEntry(
          mediaUrl: fb['mediaUrl'] as String?,
          text: fb['text'] as String?,
          count: fb['count'],
          mediaBucket: mediaBucket,
          accentColor: accentColor,
        )),
        // Motivational quote
        if (motivationalQuote != null && motivationalQuote!.isNotEmpty) ...[
          const SizedBox(height: DS.p8),
          Container(
            padding: const EdgeInsets.all(DS.p12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06), borderRadius: BorderRadius.circular(DS.r12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: accentColor, size: 15),
                const SizedBox(width: DS.p8),
                Expanded(
                  child: Text(motivationalQuote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                      fontStyle: FontStyle.italic, height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedbackEntry extends StatelessWidget {
  final String? mediaUrl;
  final String? text;
  final dynamic count;
  final MediaBucket mediaBucket;
  final Color accentColor;

  const _FeedbackEntry({
    this.mediaUrl, this.text, this.count,
    required this.mediaBucket, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = mediaUrl != null && mediaUrl!.isNotEmpty;
    final hasText  = text != null && text!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: DS.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DS.p4),
              child: Text('Feedback #$count',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor),
              ),
            ),
          if (hasMedia)
            ClipRRect(
              borderRadius: BorderRadius.circular(DS.r12),
              child: SizedBox(
                height: 160,
                child: EnhancedMediaDisplay(
                  mediaFiles: convertUrlsToEnhancedMedia([mediaUrl!]),
                  config: MediaDisplayConfig(
                    layoutMode: MediaLayoutMode.single,
                    mediaBucket: mediaBucket,
                    allowDelete: false,
                    allowFullScreen: true,
                    showDate: false,
                    borderRadius: DS.r12,
                    enableAnimations: false,
                  ),
                ),
              ),
            ),
          if (hasMedia && hasText) const SizedBox(height: DS.p8),
          if (hasText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DS.p12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(DS.r12),
              ),
              child: Text(text!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// WEEKLY GOAL PLAN CARD  (LongGoal Tab 1)
// Merged weekly_plans + weekly_metrics
// ============================================================
class WeeklyGoalPlanCard extends StatelessWidget {
  final String weekId;
  final String weeklyGoal;
  final String mood;
  final bool isCompleted;
  final int progress;
  final double rating;
  final int pointsEarned;
  final int completedDays;
  final int totalScheduledDays;
  final int pendingGoalDays;
  final List<String> pendingDates;
  final Map<String, dynamic>? penalty;
  final Color accentColor;
  final int weekIndex;

  const WeeklyGoalPlanCard({
    Key? key,
    required this.weekId, required this.weeklyGoal, required this.mood,
    required this.isCompleted, required this.progress, required this.rating,
    required this.pointsEarned, required this.completedDays,
    required this.totalScheduledDays, required this.pendingGoalDays,
    required this.pendingDates, this.penalty,
    required this.accentColor, required this.weekIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pColor = DC.forProgress(progress);
    final penaltyPts = (penalty?['penalty_points'] as int?) ?? 0;
    final moodEmoji = _emoji(mood);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + weekIndex * 80),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - v)), child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(DS.r20),
          border: Border.all(
            color: isCompleted ? DC.completed.withOpacity(0.4) : accentColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(DS.p16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [accentColor.withOpacity(0.18), accentColor.withOpacity(0.04)]
                      : [accentColor.withOpacity(0.07), Colors.transparent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.r20)),
              ),
              child: Row(
                children: [
                  // Week number
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))],
                    ),
                    child: Center(
                      child: Text('W${weekIndex + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: DS.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weeklyGoal,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(moodEmoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: DS.p4),
                            Text(mood.cap,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DBadge(
                    label: isCompleted ? 'Done' : 'Active',
                    color: isCompleted ? DC.completed : theme.colorScheme.onSurface.withOpacity(0.3),
                    icon: isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),

            // Body
            Padding(
              padding: const EdgeInsets.all(DS.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar using HProgressBar
                  Row(
                    children: [
                      Expanded(child: HProgressBar(progress: progress.toDouble(), height: 10, color: pColor)),
                      const SizedBox(width: DS.p12),
                      Text('$progress%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: DS.p16),

                  // Stats row
                  Row(
                    children: [
                      _WStat(icon: Icons.star_rounded,          value: rating.toStringAsFixed(1), label: 'Rating',  color: DC.gold),
                      _WStat(icon: Icons.bolt_rounded,           value: '$pointsEarned',           label: 'Points',  color: DC.purple),
                      _WStat(icon: Icons.check_circle_outline_rounded, value: '$completedDays/$totalScheduledDays', label: 'Days', color: pColor),
                      _WStat(
                        icon: Icons.schedule_rounded,
                        value: '$pendingGoalDays',
                        label: 'Pending',
                        color: pendingGoalDays > 0 ? DC.pending : DC.completed,
                      ),
                    ],
                  ),

                  // Penalty
                  if (penaltyPts > 0) ...[
                    const SizedBox(height: DS.p12),
                    DPenaltyBanner(points: penaltyPts, reason: penalty!['reason']?.toString() ?? ''),
                  ],

                  // Pending dates
                  if (pendingDates.isNotEmpty) ...[
                    const SizedBox(height: DS.p12),
                    PendingDatesRow(dates: pendingDates, color: DC.pending),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emoji(String m) {
    switch (m.toLowerCase()) {
      case 'happy': case 'excited': return '😄';
      case 'focused':   return '🎯';
      case 'tired':     return '😴';
      case 'stressed':  return '😰';
      case 'motivated': return '💪';
      case 'calm':      return '😊';
      default:          return '🙂';
    }
  }
}

class _WStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.45), fontSize: 9)),
        ],
      ),
    );
  }
}

// ============================================================
// LONG GOAL — Day feedback card
// ============================================================
class GoalDayFeedbackCard extends StatelessWidget {
  final DateTime feedbackDay;
  final String feedbackText;
  final String? mediaUrl;
  final int progress;
  final double rating;
  final int pointsEarned;
  final bool isComplete;
  final bool isAuthentic;
  final String? motivationalQuote;
  final Color accentColor;

  const GoalDayFeedbackCard({
    Key? key,
    required this.feedbackDay, required this.feedbackText, this.mediaUrl,
    required this.progress, required this.rating, required this.pointsEarned,
    required this.isComplete, required this.isAuthentic,
    this.motivationalQuote, required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DayTaskCard(
      title: DF.fmt(feedbackDay, p: 'MMM dd, yyyy'),
      subtitle: '${DF.fmt(feedbackDay, p: 'EEEE')} · ${DF.time(feedbackDay)}',
      progress: progress,
      rating: rating,
      pointsEarned: pointsEarned,
      isComplete: isComplete,
      accentColor: accentColor,
      badge: !isAuthentic ? '⚠ Unverified' : null,
      expandedContent: FeedbackContent(
        feedbacks: [{'mediaUrl': mediaUrl ?? '', 'text': feedbackText, 'count': 1}],
        motivationalQuote: motivationalQuote,
        rating: rating,
        mediaBucket: MediaBucket.longGoalsMedia,
        accentColor: accentColor,
      ),
    );
  }
}

// ============================================================
// WEEK TASK — Day feedback card
// ============================================================
class WeekDayFeedbackCard extends StatelessWidget {
  final String taskDate;   // "2026-03-21" or "21-03-2026"
  final String dayName;
  final List<Map<String, dynamic>> feedbacks;
  final int progress;
  final double rating;
  final int pointsEarned;
  final bool isComplete;
  final Color accentColor;

  const WeekDayFeedbackCard({
    Key? key,
    required this.taskDate, required this.dayName, required this.feedbacks,
    required this.progress, required this.rating, required this.pointsEarned,
    required this.isComplete, required this.accentColor,
  }) : super(key: key);

  DateTime? _parse() {
    try {
      final p = taskDate.split('-');
      if (p.length == 3 && p[2].length == 4) {
        return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      }
      return DateTime.parse(taskDate);
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final dt = _parse();
    return DayTaskCard(
      title: dayName.isNotEmpty ? dayName : taskDate,
      subtitle: dt != null ? DF.full(dt) : taskDate,
      progress: progress,
      rating: rating,
      pointsEarned: pointsEarned,
      isComplete: isComplete,
      accentColor: accentColor,
      badge: '${feedbacks.length} feedback${feedbacks.length != 1 ? 's' : ''}',
      expandedContent: FeedbackContent(
        feedbacks: feedbacks,
        rating: rating,
        mediaBucket: MediaBucket.weeklyTaskMedia,
        accentColor: accentColor,
      ),
    );
  }
}

// ============================================================
// BUCKET — Checklist item expandable card
// ============================================================
class BucketChecklistCard extends StatelessWidget {
  final String id;
  final String task;
  final bool done;
  final int points;
  final List<ChecklistFeedback> feedbacks;
  final DateTime? date;
  final Color accentColor;

  const BucketChecklistCard({
    Key? key,
    required this.id, required this.task, required this.done,
    required this.points, required this.feedbacks,
    this.date, required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DayTaskCard(
      title: task,
      subtitle: date != null
          ? 'Completed ${DF.smart(date)}'
          : (done ? 'Completed' : 'Not done yet'),
      progress: done ? 100 : 0,
      rating: done ? 5.0 : 0.0,
      pointsEarned: points,
      isComplete: done,
      accentColor: accentColor,
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points + date row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DC.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 13, color: DC.purple),
                    const SizedBox(width: 3),
                    Text('$points pts',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DC.purple),
                    ),
                  ],
                ),
              ),
              if (date != null) ...[
                const SizedBox(width: DS.p8),
                Icon(Icons.event_rounded, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(DF.fmt(date),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ],
          ),
          
          if (feedbacks.isNotEmpty) ...[
            const SizedBox(height: DS.p12),
            FeedbackContent(
              feedbacks: feedbacks.map((f) => {
                'mediaUrl': f.mediaUrls.isNotEmpty ? f.mediaUrls.first : '',
                'text': f.text,
                'count': feedbacks.indexOf(f) + 1,
              }).toList(),
              mediaBucket: MediaBucket.bucketMedia,
              accentColor: accentColor,
            ),
          ],

          if (!done && feedbacks.isEmpty)
            Text('This item is not completed yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4), fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
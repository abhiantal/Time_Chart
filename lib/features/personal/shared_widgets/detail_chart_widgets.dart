// ============================================================
// FILE: lib/features/detail_screens/shared/detail_chart_widgets.dart
// Charts & Analysis — NO shared_widgets imports
// Uses: AdvancedProgressIndicator, TaskMetricIndicator,
//       CardColorHelper, HProgressBar from detail_shared_widgets
// ============================================================

import 'package:flutter/material.dart';
import '../../../widgets/circular_progress_indicator.dart';
import '../../../widgets/metric_indicators.dart';
import 'detail_shared_widgets.dart';

// ============================================================
// PROGRESS OVERVIEW CARD
// Arc progress + 3 side metrics + days bar
// ============================================================
class ProgressOverviewCard extends StatelessWidget {
  final double progress;
  final double rating;
  final int pointsEarned;
  final double consistencyScore;
  final int completedDays;
  final int totalDays;
  final Color accentColor;
  final String statusText;

  const ProgressOverviewCard({
    Key? key,
    required this.progress, required this.rating,
    required this.pointsEarned, required this.consistencyScore,
    required this.completedDays, required this.totalDays,
    required this.accentColor, this.statusText = 'complete',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      padding: const EdgeInsets.all(DS.p16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [accentColor.withOpacity(0.2), accentColor.withOpacity(0.08)]
              : [accentColor.withOpacity(0.07), accentColor.withOpacity(0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DS.r20),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0,6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Arc progress using AdvancedProgressIndicator
              AdvancedProgressIndicator(
                progress: progress / 100,
                size: 120,
                strokeWidth: 10,
                shape: ProgressShape.arc,
                arcStartAngle: -200,
                arcSweepAngle: 220,
                gradientColors: [accentColor.withOpacity(0.6), accentColor],
                backgroundColor: accentColor.withOpacity(0.12),
                labelStyle: ProgressLabelStyle.percentage,
                labelTextStyle: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: accentColor,
                ),
                name: statusText,
                namePosition: ProgressLabelPosition.bottom,
                nameTextStyle: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                showGlow: progress > 50,
                animated: true,
              ),
              const SizedBox(width: DS.p20),
              Expanded(
                child: Column(
                  children: [
                    _SideStat(icon: Icons.star_rounded, label: 'Rating', value: rating.toStringAsFixed(1), color: DC.gold),
                    const SizedBox(height: DS.p12),
                    _SideStat(icon: Icons.bolt_rounded, label: 'Points', value: '$pointsEarned', color: DC.purple),
                    const SizedBox(height: DS.p12),
                    _SideStat(icon: Icons.track_changes_rounded, label: 'Consistency', value: '${consistencyScore.toInt()}%', color: DC.cyan),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DS.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Days Completed',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              Text('$completedDays / $totalDays',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: DS.p8),
          HProgressBar(
            progress: totalDays == 0 ? 0 : (completedDays / totalDays * 100).clamp(0, 100),
            height: 8,
            color: accentColor,
          ),
        ],
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SideStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: DS.p8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// CONSISTENCY RING  (replaces ConsistencyRing)
// Uses AdvancedProgressIndicator circular
// ============================================================
class ConsistencyRing extends StatelessWidget {
  final double score;
  final Color color;
  final double size;

  const ConsistencyRing({Key? key, required this.score, required this.color, this.size = 90}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdvancedProgressIndicator(
      progress: score / 100,
      size: size,
      strokeWidth: 8,
      shape: ProgressShape.circular,
      gradientColors: [color.withOpacity(0.6), color],
      backgroundColor: color.withOpacity(0.12),
      labelStyle: ProgressLabelStyle.percentage,
      labelTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
      name: 'Consistency',
      namePosition: ProgressLabelPosition.bottom,
      nameTextStyle: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
      showGlow: score > 70,
      animated: true,
    );
  }
}

// ============================================================
// MULTI METRIC RINGS  (replaces MultiRingProgress)
// 3 stacked AdvancedProgressIndicators
// ============================================================
class MultiMetricRings extends StatelessWidget {
  final double progress;
  final double rating;
  final double consistency;
  final Color accentColor;

  const MultiMetricRings({
    Key? key,
    required this.progress, required this.rating,
    required this.consistency, required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      padding: const EdgeInsets.all(DS.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DS.r16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Rings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: DS.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingItem(
                label: 'Progress', value: progress, color: accentColor, icon: Icons.trending_up_rounded,
              ),
              _RingItem(
                label: 'Rating', value: (rating / 5 * 100).clamp(0, 100), color: DC.gold, icon: Icons.star_rounded,
              ),
              _RingItem(
                label: 'Consistency', value: consistency, color: DC.cyan, icon: Icons.track_changes_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _RingItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AdvancedProgressIndicator(
          progress: value / 100,
          size: 80,
          strokeWidth: 7,
          shape: ProgressShape.circular,
          gradientColors: [color.withOpacity(0.5), color],
          backgroundColor: color.withOpacity(0.1),
          labelStyle: ProgressLabelStyle.percentage,
          labelTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          animated: true,
          showGlow: value > 60,
        ),
        const SizedBox(height: DS.p8),
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

// ============================================================
// WEEKLY BAR CHART  (replaces AnimatedBarChart)
// Custom horizontal bars using HProgressBar + AdvancedProgressIndicator
// ============================================================
class WeeklyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> items; // {label, progress, points, rating}
  final Color accentColor;
  final String title;
  final String barLabelPrefix;

  const WeeklyBarChart({
    Key? key,
    required this.items, required this.accentColor,
    this.title = 'Weekly Progress',
    this.barLabelPrefix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
      padding: const EdgeInsets.all(DS.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DS.r16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DS.p8),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(DS.r8)),
                child: Icon(Icons.bar_chart_rounded, color: accentColor, size: 17),
              ),
              const SizedBox(width: DS.p12),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: DS.p16),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final pct = ((item['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100).toDouble();
            final barColor = pct >= 70 ? DC.completed : pct >= 40 ? accentColor : DC.missed;
            final label = item['label']?.toString() ?? '${barLabelPrefix}${i + 1}';

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOut,
              builder: (_, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(offset: Offset(20 * (1 - val), 0), child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: DS.p12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: barColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: DS.p8),
                    Expanded(
                      child: HProgressBar(progress: pct, height: 22, color: barColor),
                    ),
                    const SizedBox(width: DS.p8),
                    SizedBox(
                      width: 38,
                      child: Text('${pct.toInt()}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: barColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: DS.p4),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(color: DC.completed, label: '≥70%'),
              const SizedBox(width: DS.p16),
              _Dot(color: accentColor,  label: '40–69%'),
              const SizedBox(width: DS.p16),
              _Dot(color: DC.missed,    label: '<40%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

// ============================================================
// FULL ANALYSIS CARD  (combines all analysis data)
// ============================================================
class AnalysisFullCard extends StatelessWidget {
  final double averageProgress;
  final double averageRating;
  final int pointsEarned;
  final double consistencyScore;
  final List<String> suggestions;
  final Map<String, dynamic>? penaltyData;
  final Color accentColor;

  const AnalysisFullCard({
    Key? key,
    required this.averageProgress, required this.averageRating,
    required this.pointsEarned, required this.consistencyScore,
    required this.suggestions, this.penaltyData,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final penaltyPts = (penaltyData?['penalty_points'] as int?) ?? 0;

    return Column(
      children: [
        // Metric indicators row using TaskMetricIndicator
        DSectionCard(
          title: 'Key Metrics',
          icon: Icons.analytics_rounded,
          accentColor: accentColor,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.p8),
              child: TaskMetricIndicatorRow(
                indicators: [
                  TaskMetricIndicator(
                    type: TaskMetricType.progress,
                    value: averageProgress.toInt(),
                    size: 46,
                    showLabel: true,
                    customLabel: 'Progress',
                  ),
                  TaskMetricIndicator(
                    type: TaskMetricType.rating,
                    value: averageRating,
                    size: 46,
                    showLabel: true,
                    customLabel: 'Rating',
                  ),
                  TaskMetricIndicator(
                    type: TaskMetricType.pointsEarned,
                    value: pointsEarned,
                    size: 46,
                    showLabel: true,
                    customLabel: 'Points',
                  ),
                ],
                spacing: DS.p12,
                alignment: MainAxisAlignment.spaceEvenly,
              ),
            ),
          ],
        ),

        // Consistency ring
        DSectionCard(
          title: 'Consistency',
          icon: Icons.track_changes_rounded,
          accentColor: DC.cyan,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.p8),
              child: Row(
                children: [
                  ConsistencyRing(score: consistencyScore, color: DC.cyan, size: 90),
                  const SizedBox(width: DS.p20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_consistencyLabel(consistencyScore),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Rating card
        DSectionCard(
          title: 'Rating',
          icon: Icons.star_rounded,
          accentColor: DC.gold,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.p8),
              child: Row(
                children: [
                  StarRating(rating: averageRating, size: 26),
                  const Spacer(),
                  Text(averageRating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: DC.gold),
                  ),
                  Text(' / 5',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Penalty
        if (penaltyPts > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: DS.p16, vertical: DS.p8),
            padding: const EdgeInsets.all(DS.p16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(DS.r16),
              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: DS.p8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penalty Applied',
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
                      ),
                      if (penaltyData?['reason'] != null)
                        Text(penaltyData!['reason'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error.withOpacity(0.7)),
                        ),
                    ],
                  ),
                ),
                Text('-$penaltyPts pts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.error),
                ),
              ],
            ),
          ),

        // Suggestions
        if (suggestions.isNotEmpty)
          DSectionCard(
            title: 'Suggestions',
            icon: Icons.lightbulb_rounded,
            accentColor: accentColor,
            children: [
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: DS.p4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right_rounded, color: accentColor, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(s,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
      ],
    );
  }

  String _consistencyLabel(double s) {
    if (s >= 80) return 'Excellent! Very consistent performance across all sessions.';
    if (s >= 60) return 'Good consistency. Keep up the regular check-ins.';
    if (s >= 40) return 'Moderate. Try to maintain more regular feedback patterns.';
    if (s > 0)   return 'Needs improvement. Log daily feedback to build consistency.';
    return 'No data yet. Start logging feedback to track your consistency.';
  }
}
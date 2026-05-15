// lib/features/personal/task_model/day_tasks/widgets/task_analysis_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart' hide Feedback;
import 'package:intl/intl.dart';
import '../../../../../../widgets/circular_progress_indicator.dart';
import '../models/day_task_model.dart';

class TaskAnalysisDialog extends StatelessWidget {
  final DayTaskModel task;

  const TaskAnalysisDialog({super.key, required this.task});

  static void show(BuildContext context, DayTaskModel task) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Task Analysis',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => TaskAnalysisDialog(task: task),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  RewardPackage get _rewardPackage {
    return task.metadata.rewardPackage ?? task.calculateRewardPackage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Material(
              color: isDark 
                  ? Colors.black.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.85),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: size.height * 0.8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.12) 
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusRow(context),
                            const SizedBox(height: 28),
                            _buildProgressSection(context),
                            const SizedBox(height: 28),
                            _buildMetricsGrid(context),
                            if (task.metadata.breakdown != null) ...[
                              const SizedBox(height: 28),
                              _buildBreakdownSection(context),
                            ],
                            if (task.metadata.penalty != null) ...[
                              const SizedBox(height: 28),
                              _buildPenaltySection(context),
                            ],
                            if (task.metadata.pointsEarned > 0 ||
                                task.metadata.hasReward) ...[
                              const SizedBox(height: 28),
                              _buildPointsSection(context),
                            ],
                            if (_rewardPackage.earned &&
                                _rewardPackage.tagName.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _buildTagsSection(context),
                            ],
                            if (task.metadata.summary != null &&
                                task.metadata.summary!.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _buildSummarySection(context),
                            ],

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: task.getCardGradient(isDarkMode: isDark).map((c) => c.withOpacity(0.9)).toList(),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TASK ANALYSIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  task.aboutTask.taskName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    final status = task.indicators.status;
    final statusColor = task.statusColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lens_rounded, color: statusColor, size: 10),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('MMM dd, yyyy').format(DateTime.parse(task.timeline.taskDate)),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPLETION',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey),
              ),
              Text(
                '${task.metadata.progress}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdvancedProgressIndicator(
            progress: task.metadata.progress / 100,
            size: 150,
            strokeWidth: 14,
            shape: ProgressShape.circular,
            labelStyle: ProgressLabelStyle.percentage,
            labelTextStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
            gradientColors: [colorScheme.primary, colorScheme.tertiary],
            showGlow: true,
            animated: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final totalMinutes = task.timeline.duration.inMinutes;
    final efficiency = totalMinutes > 0 ? (task.metadata.progress / 100) : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _metricItem(context, 'RATING', task.metadata.rating.toStringAsFixed(1), Icons.star_rounded, Colors.orange),
        _metricItem(context, 'EFFICIENCY', '${(efficiency * 100).toInt()}%', Icons.bolt_rounded, Colors.green),
        _metricItem(context, 'PRIORITY', task.indicators.priority.toUpperCase(), Icons.flag_rounded, Colors.red),
        _metricItem(context, 'FEEDBACK', '${task.feedbackCount}', Icons.chat_bubble_rounded, Colors.blue),
      ],
    );
  }

  Widget _metricItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildPenaltySection(BuildContext context) {
    final penalty = task.metadata.penalty!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PENALTY APPLIED',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '-${penalty.penaltyPoints} Pts',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  penalty.reason,
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(BuildContext context) {
    final package = _rewardPackage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.purple.shade400]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('POINTS EARNED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                  Text('${task.metadata.pointsEarned} Pts', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              if (package.earned) Text(task.metadata.rewardEmoji, style: const TextStyle(fontSize: 32)),
            ],
          ),
          if (package.earned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  package.rewardDisplayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final package = _rewardPackage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TAGS EARNED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              label: Text(package.tagName, style: const TextStyle(fontWeight: FontWeight.w900)),
              backgroundColor: Colors.amber.withOpacity(0.15),
              side: const BorderSide(color: Colors.amber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          ),
          child: Text(
            task.metadata.summary!,
            style: const TextStyle(height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {

    final breakdown = task.metadata.breakdown!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> items = [
      {'label': 'Verified Feedback', 'value': '+${breakdown['feedbackPoints'] ?? 0}', 'icon': Icons.check_circle_outline},
      {'label': 'Media Bonus', 'value': '+${breakdown['mediaPoints'] ?? 0}', 'icon': Icons.image_outlined},
      {'label': 'Detailed Text', 'value': '+${breakdown['textPoints'] ?? 0}', 'icon': Icons.text_fields},
      {'label': 'Priority Bonus', 'value': '+${breakdown['priorityPoints'] ?? 0}', 'icon': Icons.priority_high},
      {'label': 'On-Time Bonus', 'value': '+${breakdown['onTimeBonus'] ?? 0}', 'icon': Icons.timer_outlined},
      {'label': 'Duration Points', 'value': '+${breakdown['durationPoints'] ?? 0}', 'icon': Icons.hourglass_empty},
      if ((breakdown['slotPenalty'] ?? 0) > 0)
        {'label': 'Missed Slots', 'value': '-${breakdown['slotPenalty']}', 'icon': Icons.error_outline, 'color': Colors.red},
      if ((breakdown['overduePenalty'] ?? 0) > 0)
        {'label': 'Overdue Time', 'value': '-${breakdown['overduePenalty']}', 'icon': Icons.history_toggle_off, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCORE BREAKDOWN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
            itemBuilder: (context, index) {
              final item = items[index];
              final Color color = item['color'] ?? (isDark ? Colors.white : Colors.black87);
              
              return Row(
                children: [
                  Icon(item['icon'] as IconData, size: 18, color: color.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Text(
                    item['label'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
                  ),
                  const Spacer(),
                  Text(
                    item['value'] as String,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}


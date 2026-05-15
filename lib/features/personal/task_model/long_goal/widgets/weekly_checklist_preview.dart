// lib/features/long_goals/message_bubbles/weekly_checklist_preview.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/long_goal_model.dart';

/// Displays weekly tasks in a checklist format
class WeeklyChecklistPreview extends StatelessWidget {
  final LongGoalModel goal;
  final ColorScheme colorScheme;
  final bool compact;

  const WeeklyChecklistPreview({
    super.key,
    required this.goal,
    required this.colorScheme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (goal.goalLog.weeklyLogs.isEmpty) {
      return _buildEmptyState(context);
    }

    if (compact) {
      return _buildCompactView(context);
    }

    return _buildFullView(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No weekly tasks yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly tasks will appear here once added',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    final recentWeeks = goal.indicators.weeklyPlans.take(3).toList();

    return Column(
      children: recentWeeks.asMap().entries.map((entry) {
        final index = entry.key;
        final weekPlan = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < recentWeeks.length - 1 ? 8 : 0,
          ),
          child: _WeekChecklistItem(
            weekPlan: weekPlan,
            weekNumber: goal.indicators.weeklyPlans.indexOf(weekPlan) + 1,
            colorScheme: colorScheme,
            compact: true,
            onTap: () {
              HapticFeedback.lightImpact();
              // Navigate to weekly detail or calendar
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Tasks',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${goal.indicators.weeklyPlans.length} weeks planned',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Weeks List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              itemCount: goal.indicators.weeklyPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final weekPlan = goal.indicators.weeklyPlans[index];
                return _WeekChecklistItem(
                  weekPlan: weekPlan,
                  weekNumber: index + 1,
                  colorScheme: colorScheme,
                  compact: false,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    // Navigate to weekly detail
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChecklistItem extends StatelessWidget {
  final WeeklyPlan weekPlan;
  final int weekNumber;
  final ColorScheme colorScheme;
  final bool compact;
  final VoidCallback onTap;

  const _WeekChecklistItem({
    required this.weekPlan,
    required this.weekNumber,
    required this.colorScheme,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: weekPlan.isCompleted
                ? colorScheme.primary.withValues(alpha: 0.05)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: weekPlan.isCompleted
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: weekPlan.isCompleted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Week Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Week $weekNumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Completion Badge
                  if (weekPlan.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Mood Icon
                  if (weekPlan.mood.isNotEmpty) _getMoodIcon(weekPlan.mood),
                ],
              ),
              const SizedBox(height: 12),
              // Weekly Goal
              Text(
                weekPlan.weeklyGoal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getMoodIcon(String mood) {
    final (icon, color) = switch (mood.toLowerCase()) {
      'excited' || 'motivated' => (
        Icons.sentiment_very_satisfied_rounded,
        const Color(0xFF10B981),
      ),
      'happy' ||
      'good' => (Icons.sentiment_satisfied_rounded, const Color(0xFF0891B2)),
      'neutral' ||
      'okay' => (Icons.sentiment_neutral_rounded, const Color(0xFFF59E0B)),
      'tired' || 'struggling' => (
        Icons.sentiment_dissatisfied_rounded,
        const Color(0xFFEA580C),
      ),
      'frustrated' || 'overwhelmed' => (
        Icons.sentiment_very_dissatisfied_rounded,
        const Color(0xFFDC2626),
      ),
      _ => (Icons.sentiment_neutral_rounded, const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

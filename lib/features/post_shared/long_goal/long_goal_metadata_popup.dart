// ============================================================================
// FILE: lib/features/social/message_bubbles/long_goal_metadata_popup.dart
// ULTRA-PREMIUM ANALYTICS DIALOG FOR LONG GOAL — WITH ALL DATA
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';
import 'dart:ui';

import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../personal/task_model/long_goal/models/long_goal_model.dart';
import '../../../../reward_tags/reward_manager.dart';
import '../../../../reward_tags/reward_scratch_card.dart';

class LongGoalMetadataPopup extends StatefulWidget {
  final LongGoalModel goal;

  const LongGoalMetadataPopup({super.key, required this.goal});

  @override
  State<LongGoalMetadataPopup> createState() => _LongGoalMetadataPopupState();
}

class _LongGoalMetadataPopupState extends State<LongGoalMetadataPopup>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  LongGoalModel get goal => widget.goal;

  // Computed properties
  int get _totalWeeks => goal.totalWeeks;
  int get _completedWeeks => goal.completedWeeks;
  double get _progressValue =>
      _totalWeeks == 0 ? 0.0 : (_completedWeeks / _totalWeeks);
  double get _consistencyScore => goal.analysis.consistencyScore;

  bool get _hasReward => goal.hasEarnedReward;
  RewardTier get _rewardTier => goal.rewardTier;

  String get _status => goal.indicators.status;
  String get _priority => goal.indicators.priority;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
    );
    
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = goal.getCardGradient(isDarkMode: isDark);
    final primaryColor = gradient.first;
    final progressColor = CardColorHelper.getProgressColor(goal.analysis.averageProgress.round());

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E1E2E).withOpacity(0.95) 
                      : Colors.white.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(theme, isDark, gradient, primaryColor),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainMetrics(theme, primaryColor, progressColor),
                              const SizedBox(height: 24),
                              _buildGoalDescription(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildProgressVisualization(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildStatsGrid(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildRewardSection(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildWeeklyBreakdown(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildTimelineSection(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildInsightsSection(theme, primaryColor),
                            ],
                          ),
                        ),
                      ),
                      _buildFooter(theme, primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, List<Color> gradient, Color primaryColor) {
    final isActive = goal.isActive;
    final isOverdue = goal.isOverdue;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? Icons.flag_rounded : 
                      isOverdue ? Icons.warning_rounded : 
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'ACTIVE GOAL' : 
                      isOverdue ? 'OVERDUE' : 
                      _status.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.priority_high_rounded,
                          size: 12,
                          color: CardColorHelper.getPriorityColor(_priority),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _priority.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            goal.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: ${goal.id.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Created: ${DateFormat('MMM d, yyyy').format(goal.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(
    ThemeData theme,
    Color primaryColor,
    Color progressColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Strategic Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCircle(
                context,
                label: 'Progress',
                value: goal.analysis.averageProgress.round(),
                icon: Icons.pie_chart_rounded,
                color: progressColor,
                indicator: TaskMetricIndicator(
                  type: TaskMetricType.progress,
                  value: goal.analysis.averageProgress,
                  size: 70,
                  showLabel: false,
                ),
              ),
              _buildMetricCircle(
                context,
                label: 'Consistency',
                value: _consistencyScore.round(),
                icon: Icons.trending_up_rounded,
                color: Colors.amber,
                indicator: TaskMetricIndicator(
                  type: TaskMetricType.efficiency,
                  value: _consistencyScore / 100,
                  size: 50,
                  showLabel: false,
                ),
              ),
              _buildMetricCircle(
                context,
                label: 'Rating',
                value: goal.analysis.averageRating,
                icon: Icons.stars_rounded,
                color: Colors.purple,
                indicator: goal.analysis.averageRating > 0
                    ? TaskMetricIndicator(
                        type: TaskMetricType.rating,
                        value: goal.analysis.averageRating,
                        size: 24,
                        showLabel: false,
                      )
                    : const Icon(
                        Icons.star_border_rounded,
                        size: 30,
                        color: Colors.grey,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCircle(
    BuildContext context, {
    required String label,
    required dynamic value,
    required IconData icon,
    required Color color,
    required Widget indicator,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withOpacity(0.2), Colors.transparent],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(child: indicator),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
        ),
        Text(
          value is double ? value.toStringAsFixed(1) : '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDescription(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Goal Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDescriptionItem('🎯 Need', goal.description.need),
          const SizedBox(height: 8),
          _buildDescriptionItem('💪 Motivation', goal.description.motivation),
          const SizedBox(height: 8),
          _buildDescriptionItem('✨ Outcome', goal.description.outcome),
        ],
      ),
    );
  }

  Widget _buildDescriptionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildProgressVisualization(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Journey Tracker',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AdvancedProgressIndicator(
                  progress: goal.analysis.averageProgress / 100.0,
                  size: 100,
                  strokeWidth: 12,
                  shape: ProgressShape.circular,
                  gradientColors: goal.getCardGradient(
                    isDarkMode: theme.brightness == Brightness.dark,
                  ),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  labelStyle: ProgressLabelStyle.percentage,
                  labelTextStyle: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  showGlow: true,
                  animated: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildProgressStat(
                      'Weeks Completed',
                      '$_completedWeeks/$_totalWeeks',
                      Colors.green,
                      _progressValue,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressStat(
                      'Points Earned',
                      '${goal.analysis.pointsEarned}',
                      Colors.orange,
                      goal.analysis.pointsEarned / 100,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressStat(
                      'Task Stack',
                      '${goal.taskStack} weeks',
                      Colors.blue,
                      goal.taskStack / 52,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CustomProgressIndicator(
          progress: progress.clamp(0.0, 1.0),
          orientation: ProgressOrientation.horizontal,
          baseHeight: 6,
          maxHeightIncrease: 0,
          backgroundColor: Colors.grey.withOpacity(0.2),
          progressColor: color,
          borderRadius: 3,
          progressBarName: '',
          nameLabelPosition: LabelPosition.bottom,
          progressLabelDisplay: ProgressLabelDisplay.none,
          animated: true,
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeData theme, Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          theme,
          'Total Days',
          '${goal.metrics.totalDays}',
          Icons.calendar_month_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          theme,
          'Completed',
          '${goal.metrics.completedDays}',
          Icons.check_circle_rounded,
          Colors.green,
        ),
        _buildStatCard(
          theme,
          'Consistency',
          '${_consistencyScore.toStringAsFixed(1)}%',
          Icons.trending_up_rounded,
          Colors.amber,
        ),
        _buildStatCard(
          theme,
          'Penalty',
          '-${goal.analysis.totalPenalty?.penaltyPoints ?? 0}',
          Icons.warning_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSection(ThemeData theme, Color primaryColor) {
    if (!_hasReward && goal.analysis.rewardPackage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade300,
            Colors.orange.shade400,
            Colors.deepOrange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  goal.analysis.rewardPackage?.tagName ?? 'Milestone Reached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  goal.analysis.rewardPackage?.rewardDisplayName ??
                      'Tier ${goal.analysis.tierLevel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (goal.analysis.rewardPackage != null)
            PremiumRewardBox(
              taskId: goal.id,
              taskType: 'long_goal',
              taskTitle: goal.title,
              rewardPackage: goal.analysis.rewardPackage!,
              width: 80,
              height: 80,
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdown(ThemeData theme, Color primaryColor) {
    if (goal.goalLog.weeklyLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_week_rounded, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'Weekly Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...goal.goalLog.weeklyLogs.reversed
            .take(5)
            .map((week) => _buildWeekTile(theme, week, primaryColor)),
        if (goal.goalLog.weeklyLogs.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${goal.goalLog.weeklyLogs.length - 5} more weeks',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeekTile(
    ThemeData theme,
    WeeklyGoalLog week,
    Color primaryColor,
  ) {
    final weekNum = goal.goalLog.weeklyLogs.indexOf(week) + 1;
    final weekPlan = goal.indicators.weeklyPlans.firstWhere(
      (p) => p.weekId == week.weekId,
      orElse: () => WeeklyPlan(
        weekId: week.weekId,
        weeklyGoal: '',
        mood: '',
        isCompleted: false,
      ),
    );
    final weekMetrics = goal.metrics.weeklyMetrics.firstWhere(
      (m) => m.weekId == week.weekId,
      orElse: () => WeekMetrics(
        weekId: week.weekId,
        progress: 0,
        pointsEarned: 0,
        rating: 0,
        totalScheduledDays: 0,
        completedDays: 0,
        pendingGoalDays: 0,
        pendingDates: [],
      ),
    );
    final isCompleted = weekPlan.isCompleted;
    final weekColor = isCompleted ? Colors.green : Colors.blue;
    final progress = weekMetrics.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [weekColor.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  weekColor.withOpacity(0.2),
                  weekColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: weekColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                'W$weekNum',
                style: TextStyle(
                  color: weekColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Week $weekNum',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.mood_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        weekPlan.mood.isNotEmpty ? weekPlan.mood : 'No mood recorded',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (weekPlan.weeklyGoal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Goal: ${weekPlan.weeklyGoal}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              TaskMetricIndicator(
                type: TaskMetricType.progress,
                value: progress.toDouble(),
                size: 32,
                showLabel: false,
              ),
              Text(
                '$progress%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: weekColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, Color primaryColor) {
    final start = goal.timeline.startDate;
    final end = goal.timeline.endDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineRow(
            'Start',
            start != null ? DateFormat('MMM d, yyyy').format(start) : 'Not set',
            Icons.play_arrow_rounded,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            'End',
            end != null ? DateFormat('MMM d, yyyy').format(end) : 'Not set',
            Icons.stop_rounded,
            Colors.red,
          ),
          if (goal.timeline.workSchedule.hoursPerDay > 0) ...[
            const SizedBox(height: 12),
            _buildTimelineRow(
              'Schedule',
              '${goal.timeline.workSchedule.hoursPerDay}h/day',
              Icons.schedule_rounded,
              Colors.blue,
            ),
          ],
          if (goal.timeline.workSchedule.workDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTimelineRow(
              'Work Days',
              goal.timeline.workSchedule.workDays.join(', '),
              Icons.calendar_view_day_rounded,
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Strategic Insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.flag_rounded,
            'Status',
            'Goal is ${goal.indicators.status} with ${_completedWeeks} completed weeks',
            primaryColor,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.speed_rounded,
            'Consistency Score',
            'You\'ve maintained ${_consistencyScore.toStringAsFixed(1)}% consistency',
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.trending_up_rounded,
            'Task Stack',
            '${goal.taskStack} consecutive weeks of progress',
            Colors.blue,
          ),
          if (goal.analysis.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightItem(
              Icons.tips_and_updates_rounded,
              'Recommendation',
              goal.analysis.suggestions.first,
              Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        border: Border(top: BorderSide(color: primaryColor.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL POINTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${goal.analysis.pointsEarned}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'pts',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: goal.id));
                  AppSnackbar.success(
                    'ID Copied',
                    description: 'Goal ID copied to clipboard',
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.copy_rounded, size: 18, color: primaryColor),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

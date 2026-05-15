import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/widgets/circular_progress_indicator.dart';
import 'dart:ui';

import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../personal/task_model/week_task/models/week_task_model.dart';
import '../../../../reward_tags/reward_scratch_card.dart';

class WeekTaskMetadataPopup extends StatefulWidget {
  final WeekTaskModel task;

  const WeekTaskMetadataPopup({super.key, required this.task});

  @override
  State<WeekTaskMetadataPopup> createState() => _WeekTaskMetadataPopupState();
}

class _WeekTaskMetadataPopupState extends State<WeekTaskMetadataPopup>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  WeekTaskModel get task => widget.task;

  // Computed properties
  int get _completedDays => task.totalCompletedDays;
  int get _totalScheduled => task.timeline.totalScheduledDays;
  double get _progressValue => _totalScheduled == 0 ? 0.0 : (_completedDays / _totalScheduled);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
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
    final gradient = task.getCardGradient(isDarkMode: isDark);
    final primaryColor = gradient.first;
    final progressColor = CardColorHelper.getProgressColor(task.summary.progress);

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
                              _buildProgressVisualization(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildStatsGrid(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildRewardSection(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildDailyInsights(theme, primaryColor),
                              const SizedBox(height: 24),
                              _buildTimelineSection(theme, primaryColor),
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
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'WEEK ANALYTICS',
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
                          color: CardColorHelper.getPriorityColor(task.indicators.priority),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.indicators.priority.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
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
            task.aboutTask.taskName,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: ${task.id.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Created: ${DateFormat('MMM d, yyyy').format(task.createdAt)}',
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

  Widget _buildMainMetrics(ThemeData theme, Color primaryColor, Color progressColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                'Performance Overview',
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
                value: task.summary.progress,
                icon: Icons.pie_chart_rounded,
                color: progressColor,
                indicator: TaskMetricIndicator(
                  type: TaskMetricType.progress,
                  value: task.summary.progress.toDouble(),
                  size: 70,
                  showLabel: false,
                ),
              ),
              _buildMetricCircle(
                context,
                label: 'Efficiency',
                value: (_progressValue * 100).round(),
                icon: Icons.bolt_rounded,
                color: Colors.amber,
                indicator: TaskMetricIndicator(
                  type: TaskMetricType.efficiency,
                  value: _progressValue,
                  size: 50,
                  showLabel: false,
                ),
              ),
              _buildMetricCircle(
                context,
                label: 'Rating',
                value: task.summary.rating,
                icon: Icons.stars_rounded,
                color: Colors.purple,
                indicator: task.summary.rating > 0
                    ? TaskMetricIndicator(
                        type: TaskMetricType.rating,
                        value: task.summary.rating,
                        size: 24,
                        showLabel: false,
                      )
                    : const Icon(Icons.star_border_rounded, size: 30, color: Colors.grey),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontSize: 11,
          ),
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

  Widget _buildProgressVisualization(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Weekly Trajectory',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AdvancedProgressIndicator(
                  progress: task.summary.progress / 100.0,
                  size: 100,
                  strokeWidth: 12,
                  shape: ProgressShape.circular,
                  gradientColors: task.getCardGradient(isDarkMode: theme.brightness == Brightness.dark),
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
                      'Days Completed',
                      '$_completedDays/$_totalScheduled',
                      Colors.green,
                      _progressValue,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressStat(
                      'Points Earned',
                      '${task.summary.pointsEarned}',
                      Colors.orange,
                      task.summary.pointsEarned / 1000.0,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressStat(
                      'Task Stack',
                      '${task.taskStack} sets',
                      Colors.blue,
                      task.taskStack / 10.0,
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

  Widget _buildProgressStat(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
          'Total Scheduled',
          '$_totalScheduled Days',
          Icons.calendar_today_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          theme,
          'Completed',
          '$_completedDays Days',
          Icons.check_circle_rounded,
          Colors.green,
        ),
        _buildStatCard(
          theme,
          'Days Missed',
          '${task.summary.pendingGoalDays} Days',
          Icons.error_outline_rounded,
          Colors.red,
        ),
        _buildStatCard(
          theme,
          'Feedbacks',
          '${task.totalFeedbacks}',
          Icons.feedback_rounded,
          Colors.purple,
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
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
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
    if (task.summary.totalRewardsEarned == 0) {
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
                    const Icon(Icons.military_tech_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'REWARDS EARNED!',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.summary.bestTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${task.summary.totalRewardsEarned} Rewards this week',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // We can show a generic high-tier box if multiple rewards
          PremiumRewardBox(
            taskId: task.id,
            taskType: 'week_task',
            taskTitle: task.aboutTask.taskName,
            rewardPackage: task.rewardPackage,
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInsights(ThemeData theme, Color primaryColor) {
    if (task.dailyProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'Daily Insights',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...task.dailyProgress.reversed.take(5).map((day) => _buildDayTile(theme, day, primaryColor)),
      ],
    );
  }

  Widget _buildDayTile(ThemeData theme, DailyProgress day, Color primaryColor) {
    final isComplete = day.dailyMetrics.isComplete;
    final dayColor = isComplete ? Colors.green : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            dayColor.withOpacity(0.1),
            Colors.transparent,
          ],
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
                  dayColor.withOpacity(0.2),
                  dayColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dayColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                day.dayName.isNotEmpty ? day.dayName.substring(0, 1) : '?',
                style: TextStyle(
                  color: dayColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
                      day.dayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isComplete) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                    ],
                  ],
                ),
                Text(
                  day.taskDate,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              TaskMetricIndicator(
                type: TaskMetricType.progress,
                value: day.metrics.progress.toDouble(),
                size: 32,
                showLabel: false,
              ),
              Text(
                '${day.metrics.progress}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: dayColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, Color primaryColor) {
    final start = task.timeline.startingTime;
    final end = task.timeline.endingTime;

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
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineRow(
            'Start',
            DateFormat('MMM d, yyyy').format(start),
            Icons.play_arrow_rounded,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            'End',
            DateFormat('MMM d, yyyy').format(end),
            Icons.stop_rounded,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            'Remaining',
            '${task.timeline.remainingTime.inDays} Days left',
            Icons.timer_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, String value, IconData icon, Color color) {
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
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
        border: Border(
          top: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
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
                    '${task.summary.pointsEarned}',
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
                  Clipboard.setData(ClipboardData(text: task.id));
                  AppSnackbar.success(
                    'ID Copied',
                    description: 'Task ID copied to clipboard',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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


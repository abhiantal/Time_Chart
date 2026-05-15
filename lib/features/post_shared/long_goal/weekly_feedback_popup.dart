// ============================================================================
// FILE: lib/features/social/message_bubbles/long_goal_weekly_feedback_popup.dart
// WEEKLY FEEDBACK DETAIL POPUP FOR LONG GOAL — PREMIUM DESIGN
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../personal/task_model/long_goal/models/long_goal_model.dart';

/// Show the weekly feedback popup
void showWeeklyFeedbackPopup({
  required BuildContext context,
  required int weekNumber,
  required WeeklyGoalLog week,
  required LongGoalModel goal,
}) {
  HapticFeedback.mediumImpact();
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) =>
        WeeklyFeedbackPopup(weekNumber: weekNumber, week: week, goal: goal),
  );
}

class WeeklyFeedbackPopup extends StatefulWidget {
  final int weekNumber;
  final WeeklyGoalLog week;
  final LongGoalModel goal;

  const WeeklyFeedbackPopup({
    super.key,
    required this.weekNumber,
    required this.week,
    required this.goal,
  });

  @override
  State<WeeklyFeedbackPopup> createState() => _WeeklyFeedbackPopupState();
}

class _WeeklyFeedbackPopupState extends State<WeeklyFeedbackPopup>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  WeeklyGoalLog get week => widget.week;
  LongGoalModel get goal => widget.goal;
  int get weekNum => widget.weekNumber;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = goal.getCardGradient(isDarkMode: isDark);
    final primary = gradient.first;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212).withOpacity(0.95) : Colors.white.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(theme, isDark, gradient),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWeeklyGoal(theme, primary),
                              const SizedBox(height: 24),
                              _buildMetricsGrid(theme, primary),
                              const SizedBox(height: 24),
                              _buildDailyTimeline(theme, primary),
                            ],
                          ),
                        ),
                      ),
                      _buildFooter(theme, primary),
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

  Widget _buildHeader(ThemeData theme, bool isDark, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  'WEEK $weekNum PERFORMANCE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            goal.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoal(ThemeData theme, Color primary) {
    final weekPlan = goal.indicators.weeklyPlans.firstWhere(
      (p) => p.weekId == week.weekId,
      orElse: () => WeeklyPlan(
        weekId: week.weekId,
        weeklyGoal: '',
        mood: '',
        isCompleted: false,
      ),
    );

    if (weekPlan.weeklyGoal.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Focus',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primary.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekPlan.weeklyGoal,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme, Color primary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _MetricCard(
          label: 'Progress',
          value: '${goal.metrics.weeklyMetrics.firstWhere((m) => m.weekId == week.weekId, orElse: () => WeekMetrics(weekId: week.weekId, progress: 0, pointsEarned: 0, rating: 0, totalScheduledDays: 0, completedDays: 0, pendingGoalDays: 0, pendingDates: [])).progress}%',
          icon: Icons.speed_rounded,
          color: Colors.blue,
        ),
        _MetricCard(
          label: 'Success',
          value: goal.indicators.weeklyPlans.firstWhere((p) => p.weekId == week.weekId, orElse: () => WeeklyPlan(weekId: week.weekId, weeklyGoal: '', mood: '', isCompleted: false)).isCompleted ? 'YES' : 'PENDING',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        _MetricCard(
          label: 'Rating',
          value: '${goal.metrics.weeklyMetrics.firstWhere((m) => m.weekId == week.weekId, orElse: () => WeekMetrics(weekId: week.weekId, progress: 0, pointsEarned: 0, rating: 0, totalScheduledDays: 0, completedDays: 0, pendingGoalDays: 0, pendingDates: [])).rating}',
          icon: Icons.star_rounded,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildDailyTimeline(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Milestone Log',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (week.dailyFeedback.isEmpty)
          const Text('No daily logs found for this period.')
        else
          ...week.dailyFeedback.map((f) => _buildFeedbackTile(theme, f, primary)),
      ],
    );
  }

  Widget _buildFeedbackTile(ThemeData theme, DailyFeedback f, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'DAY ${f.feedbackDay}',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (f.dailyProgress?.isComplete == true)
                const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(f.feedbackText, style: theme.textTheme.bodyMedium),
          if (f.mediaUrl != null && f.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildThumbnail(f.mediaUrl!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, Color primary) {
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

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '${weekMetrics.pointsEarned} PTS EARNED',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Great Job!'),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String url) {
    return FutureBuilder<String?>(
      future: UniversalMediaService().getValidSignedUrl(url),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? url;
        final isLocal = !resolvedUrl.startsWith('http');

        if (isLocal) {
          final file = File(resolvedUrl);
          if (file.existsSync()) {
            return Image.file(file, fit: BoxFit.cover, height: 120, width: double.infinity);
          }
        }

        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          height: 120,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey.withOpacity(0.1),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 32),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

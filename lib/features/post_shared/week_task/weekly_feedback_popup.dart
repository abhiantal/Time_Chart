// ============================================================================
// FILE: lib/features/social/message_bubbles/week_task_weekly_feedback_popup.dart
// WEEKLY FEEDBACK DETAIL POPUP FOR WEEK TASK — PREMIUM DESIGN
// ============================================================================

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../personal/task_model/week_task/models/week_task_model.dart';

/// Show the weekly feedback popup for Week Task
void showWeekTaskFeedbackPopup({
  required BuildContext context,
  required WeekTaskModel task,
}) {
  HapticFeedback.mediumImpact();
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => WeeklyFeedbackPopup(task: task),
  );
}

class WeeklyFeedbackPopup extends StatefulWidget {
  final WeekTaskModel task;

  const WeeklyFeedbackPopup({super.key, required this.task});

  @override
  State<WeeklyFeedbackPopup> createState() => _WeeklyFeedbackPopupState();
}

class _WeeklyFeedbackPopupState extends State<WeeklyFeedbackPopup>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  WeekTaskModel get task => widget.task;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = task.getCardGradient(isDarkMode: isDark);
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF121212).withOpacity(0.95)
                      : Colors.white.withOpacity(0.98),
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
                              _buildMainSummary(theme, primary),
                              const SizedBox(height: 24),
                              _buildDailyLogs(theme, primary),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  'WEEKLY FEEDBACK',
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
            task.aboutTask.taskName,
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

  Widget _buildMainSummary(ThemeData theme, Color primary) {
    return Row(
      children: [
        _SummaryBox(
          label: 'Success Rate',
          value: '${task.summary.completionRate.toStringAsFixed(0)}%',
          color: Colors.blue,
        ),
        const SizedBox(width: 16),
        _SummaryBox(
          label: 'Total Entry',
          value: '${task.dailyProgress.length} Days',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildDailyLogs(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Timeline',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (task.dailyProgress.isEmpty)
          const Text('No feedback entries found.')
        else
          ...task.dailyProgress.map(
            (day) => _buildDaySection(theme, day, primary),
          ),
      ],
    );
  }

  Widget _buildDaySection(ThemeData theme, DailyProgress day, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            '${day.dayName} • ${day.taskDate}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...day.feedbacks.map((f) => _buildFeedbackCard(theme, f, primary)),
        if (day.feedbacks.any(
          (f) => f.finalText != null && f.finalText!.isNotEmpty,
        ))
          _buildFinalTextCard(theme, day.feedbacks.last.finalText!, primary),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeedbackCard(ThemeData theme, DailyFeedback f, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'Feedback Entry',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 10, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          if (f.mediaUrl != null && f.mediaUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildThumbnail(f.mediaUrl!),
            ),
            const SizedBox(height: 12),
          ],
          if (f.finalText != null && f.finalText!.isNotEmpty)
            Text(f.finalText!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildFinalTextCard(ThemeData theme, String text, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_rounded, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(
                'END OF DAY SUMMARY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${task.summary.pointsEarned} PTS TOTAL',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Dismiss'),
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
            return Image.file(
              file,
              fit: BoxFit.cover,
              height: 120,
              width: double.infinity,
            );
          }
        }

        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.cover,
          height: 120,
          width: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 32),
        );
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

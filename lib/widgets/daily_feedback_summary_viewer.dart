import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../reward_tags/reward_manager.dart';
import '../reward_tags/reward_scratch_card.dart';
import '../media_utility/media_display.dart';
import '../media_utility/media_asset_model.dart';
import '../features/personal/task_model/long_goal/models/long_goal_model.dart'
    as goal_model;
import '../features/personal/task_model/week_task/models/week_task_model.dart'
    as week_model;
import 'metric_indicators.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL (unchanged public API)
// ─────────────────────────────────────────────────────────────────────────────

class DailyFeedbackSummaryData {
  final String taskId;
  final String taskType;
  final String taskTitle;
  final DateTime date;

  final int progress;
  final int pointsEarned;
  final double rating;
  final bool isComplete;
  final bool isMissed;
  final bool isToday;

  final String statusLabel;
  final Map<String, dynamic> statusData;

  final List<String> feedbackTexts;
  final List<EnhancedMediaFile> mediaFiles;
  final int? feedbackCount;

  final int? penaltyPoints;
  final String? penaltyReason;

  final String? motivationalQuote;
  final RewardPackage? rewardPackage;

  final VoidCallback? onAddFeedback;
  final VoidCallback? onViewDetails;
  final VoidCallback? onShare;

  final List<Map<String, dynamic>>? hourlyBreakdown;
  final String? dayName;

  DailyFeedbackSummaryData({
    required this.taskId,
    required this.taskType,
    required this.taskTitle,
    required this.date,
    required this.progress,
    required this.pointsEarned,
    required this.rating,
    required this.isComplete,
    required this.isMissed,
    required this.isToday,
    required this.statusLabel,
    required this.statusData,
    required this.feedbackTexts,
    required this.mediaFiles,
    this.feedbackCount,
    this.penaltyPoints,
    this.penaltyReason,
    this.motivationalQuote,
    this.rewardPackage,
    this.onAddFeedback,
    this.onViewDetails,
    this.onShare,
    this.hourlyBreakdown,
    this.dayName,
  });

  factory DailyFeedbackSummaryData.fromLongGoal({
    required String taskId,
    required String taskTitle,
    required DateTime date,
    required List<goal_model.DailyFeedback> feedbacks,
    required goal_model.GoalTimeline timeline,
    required goal_model.DailyProgress? dailyProgress,
    required Map<String, dynamic> statusData,
    required VoidCallback? onAddFeedback,
  }) {
    final isComplete = dailyProgress?.isComplete ?? false;
    final isToday = _isSameDay(date, DateTime.now());
    final isMissed = !isComplete && date.isBefore(DateTime.now()) && !isToday;
    final feedbackTexts = feedbacks
        .map((f) => f.feedbackText)
        .where((t) => t.isNotEmpty)
        .toList();
    final mediaFiles = feedbacks
        .where((f) => f.hasMedia)
        .map(
          (f) => EnhancedMediaFile.fromUrl(
            id: 'lg_${f.feedbackDay}_${f.feedbackCount}',
            url: f.mediaUrl!,
          ),
        )
        .toList();
    return DailyFeedbackSummaryData(
      taskId: taskId,
      taskType: 'Long Term Goal',
      taskTitle: taskTitle,
      date: date,
      progress: dailyProgress?.progress ?? 0,
      pointsEarned: dailyProgress?.pointsEarned ?? 0,
      rating: dailyProgress?.rating ?? 0.0,
      isComplete: isComplete,
      isMissed: isMissed,
      isToday: isToday,
      statusLabel: isComplete
          ? 'Completed'
          : isMissed
          ? 'Missed'
          : isToday
          ? 'In Progress'
          : 'Pending',
      statusData: statusData,
      feedbackTexts: feedbackTexts,
      mediaFiles: mediaFiles,
      feedbackCount: feedbacks.length,
      penaltyPoints: dailyProgress?.penalty?.penaltyPoints,
      penaltyReason: dailyProgress?.penalty?.reason,
      motivationalQuote: dailyProgress?.motivationalQuote,
      rewardPackage: dailyProgress?.rewardPackage,
      onAddFeedback: onAddFeedback,
    );
  }

  factory DailyFeedbackSummaryData.fromWeekTask({
    required String taskId,
    required String taskTitle,
    required week_model.DailyProgress dailyProgress,
    required Map<String, dynamic> statusData,
    required VoidCallback? onAddFeedback,
  }) {
    final isToday = _isSameDay(dailyProgress.date, DateTime.now());
    final isMissed =
        !dailyProgress.isComplete &&
        dailyProgress.date.isBefore(DateTime.now()) &&
        !isToday;
    final feedbackTexts = dailyProgress.feedbacks
        .where((f) => f.finalText != null && f.finalText!.isNotEmpty)
        .map((f) => f.finalText!)
        .toList();
    final mediaFiles = dailyProgress.feedbacks
        .where((f) => f.mediaUrl != null && f.mediaUrl!.isNotEmpty)
        .map(
          (f) => EnhancedMediaFile.fromUrl(
            id: 'wt_${f.feedbackNumber}',
            url: f.mediaUrl!,
            thumbnailUrl: f.mediaUrl!,
          ),
        )
        .toList();
    final hourlyBreakdown = <Map<String, dynamic>>[];

    return DailyFeedbackSummaryData(
      taskId: taskId,
      taskType: 'Weekly Task',
      taskTitle: taskTitle,
      date: dailyProgress.date,
      progress: dailyProgress.metrics.progress,
      pointsEarned: dailyProgress.metrics.pointsEarned,
      rating: dailyProgress.metrics.rating,
      isComplete: dailyProgress.isComplete,
      isMissed: isMissed,
      isToday: isToday,
      statusLabel: dailyProgress.isComplete
          ? 'Completed'
          : isMissed
          ? 'Missed'
          : isToday
          ? 'In Progress'
          : 'Scheduled',
      statusData: statusData,
      feedbackTexts: feedbackTexts,
      mediaFiles: mediaFiles,
      feedbackCount: dailyProgress.feedbacks.length,
      penaltyPoints: dailyProgress.metrics.penalty?.penaltyPoints,
      penaltyReason: dailyProgress.metrics.penalty?.reason,
      motivationalQuote: dailyProgress.metrics.motivationalQuote,
      rewardPackage: dailyProgress.metrics.rewardPackage,
      onAddFeedback: onAddFeedback,
      hourlyBreakdown: hourlyBreakdown,
      dayName: dailyProgress.dayName,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR PALETTE  (each section has its own distinct accent)
// ─────────────────────────────────────────────────────────────────────────────

class _Palette {
  // Header / background top
  static const Color headerTop = Color(0xFF1A1A2E);
  static const Color headerBot = Color(0xFF16213E);

  // Sheet background
  static const Color sheetBg = Color(0xFF0F0F1A);
  static const Color cardBg = Color(0xFF1C1C2E);
  static const Color cardBorder = Color(0xFF2A2A40);

  // Status accents
  static const Color completed = Color(0xFF00C897); // mint green
  static const Color missed = Color(0xFFFF4E6A); // coral red
  static const Color inProgress = Color(0xFF4E9FFF); // sky blue
  static const Color pending = Color(0xFFFFB347); // warm orange

  // Section accents
  static const Color progressAcc = Color(0xFF7C4DFF); // deep violet
  static const Color pointsAcc = Color(0xFFFFD700); // gold
  static const Color ratingAcc = Color(0xFF00D4FF); // cyan
  static const Color metricsAcc = Color(0xFFFF6B9D); // pink
  static const Color notesAcc = Color(0xFF64FFDA); // teal
  static const Color timelineAcc = Color(0xFFFFAB40); // amber
  static const Color mediaAcc = Color(0xFFAA80FF); // lavender
  static const Color penaltyAcc = Color(0xFFFF5252); // red

  static Color statusColor(bool isComplete, bool isMissed, bool isToday) {
    if (isComplete) return completed;
    if (isMissed) return missed;
    if (isToday) return inProgress;
    return pending;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class DailyFeedbackSummaryDialog extends StatefulWidget {
  final DailyFeedbackSummaryData data;
  const DailyFeedbackSummaryDialog({super.key, required this.data});

  @override
  State<DailyFeedbackSummaryDialog> createState() =>
      _DailyFeedbackSummaryDialogState();
}

class _DailyFeedbackSummaryDialogState extends State<DailyFeedbackSummaryDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryScale;
  late Animation<double> _entryFade;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _rotateCtrl;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entryScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeOutCubic,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _entryCtrl.forward().then((_) => _progressCtrl.forward());
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  DailyFeedbackSummaryData get d => widget.data;
  Color get _statusColor =>
      _Palette.statusColor(d.isComplete, d.isMissed, d.isToday);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: _entryFade.value,
        child: Transform.scale(scale: _entryScale.value, child: child),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.sheetBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.28),
                  blurRadius: 30,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 14),
                          _buildStatusCard(),
                          const SizedBox(height: 12),
                          _buildStatsRow(),
                          const SizedBox(height: 12),
                          _buildProgressCard(),
                          const SizedBox(height: 12),
                          _buildMetricsCard(),
                          if (d.rewardPackage?.earned == true) ...[
                            const SizedBox(height: 12),
                            _buildRewardCard(),
                          ],
                          if (d.motivationalQuote?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _buildQuoteCard(),
                          ],
                          if (d.feedbackTexts.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildNotesCard(),
                          ],
                          if (d.hourlyBreakdown?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _buildTimelineCard(),
                          ],
                          if (d.mediaFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildMediaCard(),
                          ],
                          if (d.penaltyPoints != null &&
                              d.penaltyPoints! > 0) ...[
                            const SizedBox(height: 12),
                            _buildPenaltyCard(),
                          ],
                          const SizedBox(height: 12),
                          _buildDetailsToggle(),
                          if (_showDetails) ...[
                            const SizedBox(height: 10),
                            _buildDetailsCard(),
                          ],
                          const SizedBox(height: 16),
                          _buildActions(),
                        ],
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

  // ── HEADER (dark gradient with status glow strip at bottom) ──────────────

  Widget _buildHeader() {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _statusColor.withOpacity(0.35),
            _Palette.headerTop,
            _Palette.headerBot,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Glow orb top-left
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor.withOpacity(0.18),
              ),
            ),
          ),
          // Bottom separator line in status color
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _statusColor.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateBadge(),
                const SizedBox(width: 14),
                Expanded(child: _buildHeaderInfo()),
                _buildCloseBtn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: d.isToday ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: d.isToday
                ? _statusColor.withOpacity(0.9)
                : Colors.white.withOpacity(0.15),
            width: d.isToday ? 2 : 1,
          ),
          boxShadow: d.isToday
              ? [
                  BoxShadow(
                    color: _statusColor.withOpacity(0.4),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              DateFormat('MMM').format(d.date).toUpperCase(),
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${d.date.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: d.isToday
                    ? _statusColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d.isToday
                    ? 'TODAY'
                    : DateFormat('EEE').format(d.date).toUpperCase(),
                style: TextStyle(
                  color: d.isToday ? _statusColor : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task type chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                d.taskType == 'Long Term Goal'
                    ? Icons.flag_rounded
                    : Icons.calendar_view_week_rounded,
                color: _statusColor,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                d.taskType,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          d.taskTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (d.dayName != null) ...[
          const SizedBox(height: 4),
          Text(
            d.dayName!,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCloseBtn() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white60, size: 17),
      ),
    );
  }

  // ── STATUS CARD (colored accent based on status) ──────────────────────────

  Widget _buildStatusCard() {
    final icon = d.isComplete
        ? Icons.check_circle_rounded
        : d.isMissed
        ? Icons.cancel_rounded
        : d.isToday
        ? Icons.radio_button_checked_rounded
        : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(accentColor: _statusColor, glow: true),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _statusColor.withOpacity(0.45),
                  _statusColor.withOpacity(0.12),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _statusColor.withOpacity(0.55),
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(d.date),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (d.feedbackCount != null)
            _Pill(
              icon: Icons.chat_bubble_rounded,
              label: '${d.feedbackCount}',
              color: _Palette.notesAcc,
            ),
        ],
      ),
    );
  }

  // ── STATS ROW (points = gold, rating = cyan) ─────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.stars_rounded,
            value: '${d.pointsEarned}',
            label: 'POINTS',
            accentColor: _Palette.pointsAcc,
            animation: _progressAnim,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.insights_rounded,
            value: d.rating.toStringAsFixed(1),
            label: 'RATING',
            accentColor: _Palette.ratingAcc,
            animation: _progressAnim,
            suffix: _buildStarRow(d.rating),
          ),
        ),
      ],
    );
  }

  Widget _buildStarRow(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData ic;
        if (i < full) {
          ic = Icons.star_rounded;
        } else if (i == full && half) {
          ic = Icons.star_half_rounded;
        } else {
          ic = Icons.star_outline_rounded;
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 350 + i * 70),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Icon(
            ic,
            color: i < full || (i == full && half)
                ? _Palette.pointsAcc
                : Colors.white12,
            size: 13,
          ),
        );
      }),
    );
  }

  // ── PROGRESS CARD (violet accent) ─────────────────────────────────────────

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(accentColor: _Palette.progressAcc),
      child: Row(
        children: [
          // Ring
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) {
              final val = (d.progress / 100.0) * _progressAnim.value;
              final pct = (d.progress * _progressAnim.value).round();
              return SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _Palette.progressAcc.withOpacity(0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Track
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 9,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    // Fill
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: CircularProgressIndicator(
                        value: val,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _Palette.progressAcc,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'done',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(width: 18),

          // Bar + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROGRESS',
                  style: TextStyle(
                    color: _Palette.progressAcc,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) {
                    final val = (d.progress / 100.0) * _progressAnim.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: val,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.07),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _Palette.progressAcc,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(d.progress * _progressAnim.value).round()} of 100',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // small breakdown chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (d.isComplete)
                      _SmallChip(
                        label: '✓ Complete',
                        color: _Palette.completed,
                      ),
                    if (d.isMissed)
                      _SmallChip(label: '✗ Missed', color: _Palette.missed),
                    if (d.isToday && !d.isComplete)
                      _SmallChip(label: '⟳ Today', color: _Palette.inProgress),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── METRICS (pink accent) ─────────────────────────────────────────────────

  Widget _buildMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(accentColor: _Palette.metricsAcc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: 'METRICS', color: _Palette.metricsAcc),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TaskMetricIndicator(
                  type: TaskMetricType.status,
                  value: d.statusData['status'] ?? 'pending',
                  size: 38,
                  showLabel: true,
                  customLabel: d.statusLabel,
                  adaptToTheme: false,
                ),
                const SizedBox(width: 8),
                TaskMetricIndicator(
                  type: TaskMetricType.priority,
                  value: d.statusData['priority'] ?? 'medium',
                  size: 38,
                  showLabel: true,
                  adaptToTheme: false,
                ),
                const SizedBox(width: 8),
                TaskMetricIndicator(
                  type: TaskMetricType.rating,
                  value: d.rating,
                  size: 38,
                  showLabel: true,
                  adaptToTheme: false,
                ),
                const SizedBox(width: 8),
                TaskMetricIndicator(
                  type: TaskMetricType.pointsEarned,
                  value: d.pointsEarned,
                  size: 38,
                  showLabel: true,
                  adaptToTheme: false,
                ),
                if (d.mediaFiles.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TaskMetricIndicator(
                    type: TaskMetricType.mediaCount,
                    value: d.mediaFiles.length,
                    size: 38,
                    showLabel: true,
                    adaptToTheme: false,
                  ),
                ],
                if (d.feedbackCount != null) ...[
                  const SizedBox(width: 8),
                  TaskMetricIndicator(
                    type: TaskMetricType.feedbackCount,
                    value: d.feedbackCount,
                    size: 38,
                    showLabel: true,
                    adaptToTheme: false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── REWARD (gold gradient) ────────────────────────────────────────────────

  Widget _buildRewardCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1200), Color(0xFF3D2A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _Palette.pointsAcc.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.pointsAcc.withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _rotateCtrl,
                  builder: (_, child) => Transform.rotate(
                    angle: _rotateCtrl.value * 2 * math.pi,
                    child: child,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _Palette.pointsAcc,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '🎉  REWARD EARNED!',
                  style: TextStyle(
                    color: _Palette.pointsAcc,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: PremiumRewardBox(
                taskId: '${d.taskId}_${d.date.millisecondsSinceEpoch}',
                taskType: 'daily_${d.taskType}',
                taskTitle:
                    '${d.taskTitle} – ${DateFormat('MMM d').format(d.date)}',
                rewardPackage: d.rewardPackage!,
                width: 100,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUOTE (teal accent, dark bg) ──────────────────────────────────────────

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(accentColor: _Palette.notesAcc),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: _Palette.notesAcc.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              d.motivationalQuote!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTES (teal accent) ───────────────────────────────────────────────────

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(accentColor: _Palette.notesAcc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionHeader(label: 'NOTES', color: _Palette.notesAcc),
              const Spacer(),
              _Pill(
                icon: Icons.notes_rounded,
                label: '${d.feedbackTexts.length}',
                color: _Palette.notesAcc,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...d.feedbackTexts.asMap().entries.map((e) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + e.key * 80),
              curve: Curves.easeOut,
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: Container(
                margin: EdgeInsets.only(
                  bottom: e.key < d.feedbackTexts.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Palette.notesAcc.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _Palette.notesAcc.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(
                        color: _Palette.notesAcc.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            color: _Palette.notesAcc,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── TIMELINE (amber accent) ───────────────────────────────────────────────

  Widget _buildTimelineCard() {
    final items = d.hourlyBreakdown!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(accentColor: _Palette.timelineAcc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'ACTIVITY TIMELINE',
            color: _Palette.timelineAcc,
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == items.length - 1;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + i * 80),
              curve: Curves.easeOut,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(16 * (1 - v), 0),
                  child: child,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _Palette.timelineAcc.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _Palette.timelineAcc.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: _Palette.timelineAcc,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 1.5,
                          height: 26,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: _Palette.timelineAcc.withOpacity(0.2),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['time'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _SmallChip(
                                      label: '+${item['points']} pts',
                                      color: _Palette.pointsAcc,
                                    ),
                                    if (item['hasMedia'] == true) ...[
                                      const SizedBox(width: 6),
                                      _SmallChip(
                                        label: '📷 Media',
                                        color: _Palette.mediaAcc,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── MEDIA (lavender accent) ───────────────────────────────────────────────

  Widget _buildMediaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(accentColor: _Palette.mediaAcc),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionHeader(label: 'MEDIA', color: _Palette.mediaAcc),
              const Spacer(),
              _Pill(
                icon: Icons.photo_library_rounded,
                label: '${d.mediaFiles.length}',
                color: _Palette.mediaAcc,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: d.mediaFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + i * 70),
                curve: Curves.easeOutBack,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 106,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _Palette.mediaAcc.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: EnhancedMediaDisplay(
                      mediaFiles: [d.mediaFiles[i]],
                      config: const MediaDisplayConfig(
                        layoutMode: MediaLayoutMode.single,
                        allowDelete: false,
                        allowFullScreen: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PENALTY (red) ─────────────────────────────────────────────────────────

  Widget _buildPenaltyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.penaltyAcc.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _Palette.penaltyAcc.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.penaltyAcc.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _Palette.penaltyAcc.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _Palette.penaltyAcc,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '−${d.penaltyPoints} Points Deducted',
                  style: TextStyle(
                    color: _Palette.penaltyAcc,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (d.penaltyReason != null)
                  Text(
                    d.penaltyReason!,
                    style: TextStyle(
                      color: _Palette.penaltyAcc.withOpacity(0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DETAILS TOGGLE ────────────────────────────────────────────────────────

  Widget _buildDetailsToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = !_showDetails),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedRotation(
            turns: _showDetails ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              Icons.expand_more_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _showDetails ? 'HIDE DETAILS' : 'MORE DETAILS',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'DETAILS', color: Colors.white38),
            const SizedBox(height: 10),
            _DR(label: 'Task ID', value: d.taskId),
            _DR(label: 'Type', value: d.taskType),
            _DR(
              label: 'Date',
              value: DateFormat('EEE, MMM d yyyy').format(d.date),
            ),
            _DR(label: 'Progress', value: '${d.progress}%'),
            _DR(label: 'Points', value: '${d.pointsEarned}'),
            _DR(label: 'Rating', value: '${d.rating.toStringAsFixed(2)} / 5.0'),
            if (d.penaltyPoints != null && d.penaltyPoints! > 0)
              _DR(
                label: 'Penalty',
                value: '−${d.penaltyPoints} pts',
                valueColor: _Palette.penaltyAcc,
              ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final canAdd =
        d.onAddFeedback != null &&
        (d.isToday || d.date.isBefore(DateTime.now()));

    return Row(
      children: [
        if (d.onShare != null) ...[
          Expanded(
            child: _OutlineBtn(
              icon: Icons.share_rounded,
              label: 'SHARE',
              color: Colors.white30,
              onTap: d.onShare!,
            ),
          ),
          if (canAdd) const SizedBox(width: 10),
        ],
        if (canAdd)
          Expanded(
            flex: d.onShare != null ? 1 : 2,
            child: _FilledBtn(
              icon: Icons.add_rounded,
              label: 'ADD FEEDBACK',
              gradientColors: [_statusColor, _statusColor.withOpacity(0.6)],
              onTap: () {
                Navigator.pop(context);
                d.onAddFeedback!();
              },
            ),
          ),
        if (!canAdd && d.onShare == null)
          Expanded(
            child: _FilledBtn(
              icon: Icons.close_rounded,
              label: 'CLOSE',
              gradientColors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
              onTap: () => Navigator.pop(context),
            ),
          ),
      ],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  BoxDecoration _cardDecor({Color? accentColor, bool glow = false}) {
    return BoxDecoration(
      color: _Palette.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accentColor != null
            ? accentColor.withOpacity(0.22)
            : _Palette.cardBorder,
        width: 1,
      ),
      boxShadow: glow && accentColor != null
          ? [
              BoxShadow(
                color: accentColor.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;
  final Animation<double> animation;
  final Widget? suffix;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.animation,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(opacity: animation.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _Palette.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (suffix != null) ...[const SizedBox(width: 8), suffix!],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _DR extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DR({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white30, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FilledBtn({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

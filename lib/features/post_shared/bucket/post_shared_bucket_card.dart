// ============================================================================
// FILE: lib/features/bucket_sharing/message_bubbles/shared_bucket_card_view.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui';

import 'package:the_time_chart/features/post_shared/bucket/post_shared_bucket_checklist_preview.dart';
import 'package:the_time_chart/features/post_shared/bucket/post_shared_bucket_metadata_dialog.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../personal/bucket_model/models/bucket_model.dart';
import '../../../../widgets/metric_indicators.dart';
import '../../../../widgets/bar_progress_indicator.dart';

class SharedBucketCardView extends StatefulWidget {
  final BucketModel bucket;
  final bool isListView;
  final bool allowInteraction;
  final EdgeInsets? margin;

  const SharedBucketCardView({
    super.key,
    required this.bucket,
    this.isListView = false,
    this.allowInteraction = false,
    this.margin,
  });

  @override
  State<SharedBucketCardView> createState() => _SharedBucketCardViewState();
}

class _SharedBucketCardViewState extends State<SharedBucketCardView>
    with TickerProviderStateMixin {
  late AnimationController _revealCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _revealAnim;
  bool _isExpanded = false;

  // ── Computed properties ──────────────────────────────────────────
  int get _completedTasks =>
      widget.bucket.checklist.where((i) => i.done).length;

  int get _totalTasks => widget.bucket.checklist.length;

  double get _progressValue =>
      _totalTasks == 0 ? 0.0 : (_completedTasks / _totalTasks);

  bool get _isOverdue =>
      widget.bucket.timeline.dueDate != null &&
      DateTime.now().isAfter(widget.bucket.timeline.dueDate!) &&
      !widget.bucket.isCompleted;

  TaskStatus get _taskStatus {
    if (widget.bucket.isCompleted) return TaskStatus.completed;
    if (_isOverdue) return TaskStatus.missed;
    if (_progressValue > 0) return TaskStatus.inProgress;
    if (widget.bucket.timeline.startDate != null &&
        DateTime.now().isBefore(widget.bucket.timeline.startDate!)) {
      return TaskStatus.upcoming;
    }
    return TaskStatus.pending;
  }

  Duration? get _timeSpent {
    if (widget.bucket.timeline.completeDate != null &&
        widget.bucket.timeline.startDate != null) {
      return widget.bucket.timeline.completeDate!.difference(
        widget.bucket.timeline.startDate!,
      );
    }
    return null;
  }

  String get _timeLeftText {
    if (widget.bucket.timeline.dueDate == null) return '';
    final diff = widget.bucket.timeline.dueDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Due now';
  }

  int get _feedbackCount => widget.bucket.checklist
      .where((i) => i.feedbacks.isNotEmpty)
      .length;

  // ── Lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.easeOutExpo,
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _revealCtrl.forward();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────
  void _showMetadata() {
    HapticFeedback.mediumImpact();
    if (widget.allowInteraction) {
      showDialog(
        context: context,
        builder: (_) => SharedBucketMetadataDialog(bucket: widget.bucket),
      );
    }
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = !_isExpanded);
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = widget.bucket.getCardGradient(isDarkMode: isDark);
    final primary = gradient.first;

    return FadeTransition(
      opacity: _revealAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_revealAnim),
        child: Container(
          margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primary.withOpacity(isDark ? 0.3 : 0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(isDark ? 0.18 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeroSection(theme, isDark, gradient, primary),
                    _buildSecondaryMetricsBar(theme, isDark, primary),
                    _buildBodySection(theme, isDark, primary),
                  ],
                ),
                if (widget.bucket.isCompleted) _buildCompletionBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 1. HERO SECTION
  // ══════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(
    ThemeData theme,
    bool isDark,
    List<Color> gradient,
    Color primary,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Hex pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _HexPainter(color: Colors.white.withOpacity(0.05)),
            ),
          ),

          // Glow orb
          Positioned(
            top: -40,
            right: -40,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(
                          0.08 + (_pulseCtrl.value * 0.04),
                        ),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(theme),
                const SizedBox(height: 16),
                _buildCategoryPills(),
                const SizedBox(height: 20),
                _buildPrimaryMetricsRow(),
                const SizedBox(height: 22),
                _buildProgressBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Header: media + title + status indicators ───────────
  Widget _buildHeroHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMediaThumb(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      widget.bucket.title.isEmpty ||
                              widget.bucket.title == 'null'
                          ? 'Untitled Bucket'
                          : widget.bucket.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Primary Indicator Cluster ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TaskMetricIndicator(
                        type: TaskMetricType.status,
                        value: _taskStatus,
                        size: 26,
                        showLabel: false,
                      ),
                      const SizedBox(width: 5),
                      TaskMetricIndicator(
                        type: TaskMetricType.priority,
                        value: widget.bucket.metadata.priority,
                        size: 26,
                        showLabel: false,
                      ),
                      const SizedBox(width: 5),
                      TaskMetricIndicator(
                        type: TaskMetricType.category,
                        value: 'Bucket',
                        size: 26,
                        showLabel: false,
                      ),
                    ],
                  ),
                ],
              ),

              // Description snippet
              if (widget.bucket.details.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.bucket.details.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Media Thumbnail ──────────────────────────────────────────
  Widget _buildMediaThumb() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.bucket.details.mediaUrl.isEmpty
            ? _defaultMediaIcon()
            : _networkMediaImage(),
      ),
    );
  }

  Widget _defaultMediaIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _networkMediaImage() {
    return FutureBuilder<String?>(
      future: UniversalMediaService().getValidSignedUrl(
        widget.bucket.details.mediaUrl.first,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          );
        }

        final url = snap.data ?? widget.bucket.details.mediaUrl.first;
        const fallback = Center(
          child: Icon(Icons.image_rounded, color: Colors.white70, size: 28),
        );

        if (!url.startsWith('http')) {
          final clean = url.replaceFirst('file://', '');
          final file = File(clean);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );
          }
          return fallback;
        }
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      },
    );
  }

  // ── Category + Tag Pills ─────────────────────────────────────
  Widget _buildCategoryPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.bucket.categoryType != null &&
            widget.bucket.categoryType!.isNotEmpty)
          _GlassPill(
            label: widget.bucket.categoryType!,
            icon: Icons.category_rounded,
            color: CardColorHelper.getPriorityColor(
              widget.bucket.metadata.priority,
            ),
          ),
        if (widget.bucket.subTypes != null &&
            widget.bucket.subTypes!.isNotEmpty)
          _GlassPill(
            label: widget.bucket.subTypes!,
            icon: Icons.label_rounded,
            opacity: 0.85,
          ),
        if (widget.bucket.hasReward)
          _GlassPill(
            label: widget.bucket.rewardDisplayName,
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
          ),
      ],
    );
  }

  // ── Primary Metrics Row (inside hero) ────────────────────────
  Widget _buildPrimaryMetricsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          TaskMetricIndicator(
            type: TaskMetricType.progress,
            value: widget.bucket.metadata.averageProgress,
            size: 42,
            showLabel: true,
          ),

          const SizedBox(width: 10),
          if (_totalTasks > 0) ...[
            TaskMetricIndicator(
              type: TaskMetricType.efficiency,
              value: _progressValue,
              size: 34,
              showLabel: true,
            ),
            const SizedBox(width: 10),
          ],
          if (widget.bucket.metadata.averageRating > 0) ...[
            TaskMetricIndicator(
              type: TaskMetricType.rating,
              value: widget.bucket.metadata.averageRating,
              size: 18,
              showLabel: true,
            ),

            const SizedBox(width: 10),
          ],
          if (widget.bucket.metadata.totalPointsEarned > 0)
            TaskMetricIndicator(
              type: TaskMetricType.pointsEarned,
              value: widget.bucket.metadata.totalPointsEarned.toDouble(),
              size: 30,
              showLabel: false,
            ),
        ],
      ),
    );
  }

  // ── Progress Bar ─────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COMPLETION',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '$_completedTasks / $_totalTasks tasks',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomProgressIndicator(
          progress: _progressValue,
          progressBarName: '',
          width: double.infinity,
          baseHeight: 8,
          maxHeightIncrease: 2,
          borderRadius: 4,
          backgroundColor: Colors.white.withOpacity(0.12),
          progressColor: Colors.white,
          gradientColors: [Colors.white, Colors.white.withOpacity(0.8)],
          progressLabelDisplay: ProgressLabelDisplay.none,
          nameLabelPosition: LabelPosition.top,
          animated: true,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 2. SECONDARY METRICS BAR (Below hero)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSecondaryMetricsBar(
    ThemeData theme,
    bool isDark,
    Color primary,
  ) {
    final indicators = _collectSecondaryIndicators();
    if (indicators.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: primary.withOpacity(isDark ? 0.08 : 0.05),
        border: Border(bottom: BorderSide(color: primary.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: TaskMetricIndicatorRow(spacing: 14, indicators: indicators),
      ),
    );
  }

  List<TaskMetricIndicator> _collectSecondaryIndicators() {
    final list = <TaskMetricIndicator>[];

    if (_isOverdue) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.overdue,
          value: true,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.timeline.dueDate != null && !_isOverdue) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.timeLeft,
          value: _timeLeftText,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.timeline.dueDate != null) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.deadline,
          value: widget.bucket.timeline.dueDate,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (_timeSpent != null) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.timeOnComplete,
          value: _timeSpent,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.socialInfo != null) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.posted,
          value: {'live': widget.bucket.socialInfo?.posted?.live ?? false},
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.details.mediaUrl.isNotEmpty) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.mediaCount,
          value: widget.bucket.details.mediaUrl.length,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (_feedbackCount > 0) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.feedbackCount,
          value: _feedbackCount,
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.hasReward) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.reward,
          value: widget.bucket.metadata.totalPointsEarned.toDouble(),
          size: 28,
          showLabel: true,
        ),
      );
    }

    if (widget.bucket.timeline.startDate != null) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.startingTime,
          value: widget.bucket.timeline.startDate,
          size: 28,
          showLabel: true,
          customLabel: 'Started',
        ),
      );
    }

    if (widget.bucket.timeline.completeDate != null) {
      list.add(
        TaskMetricIndicator(
          type: TaskMetricType.completionTime,
          value: widget.bucket.timeline.completeDate,
          size: 28,
          showLabel: true,
          customLabel: 'Completed',
        ),
      );
    }

    return list;
  }

  // ══════════════════════════════════════════════════════════════════
  // 3. BODY SECTION
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBodySection(ThemeData theme, bool isDark, Color primary) {
    return Container(
      color: theme.colorScheme.surface,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checklist header
          _buildChecklistHeader(theme, primary),

          const SizedBox(height: 14),

          // Checklist
          SharedBucketChecklistPreview(
            bucket: widget.bucket,
            isListView: widget.isListView,
            allowInteraction: widget.allowInteraction,
          ),

          // Action button
          if (widget.allowInteraction) ...[
            const SizedBox(height: 20),
            _buildActionButton(theme, primary),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistHeader(ThemeData theme, Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.checklist_rounded, size: 18, color: primary),
        ),
        const SizedBox(width: 12),
        Text(
          'Checklist',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _progressValue >= 1.0
                ? Colors.green.withOpacity(0.1)
                : primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _progressValue >= 1.0
                ? '✓ Complete'
                : '${(_progressValue * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _progressValue >= 1.0 ? Colors.green : primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme, Color primary) {
    return GestureDetector(
      onTap: _showMetadata,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.12), primary.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isListView
                  ? Icons.open_in_full_rounded
                  : Icons.info_outline_rounded,
              color: primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.isListView ? 'View Full Bucket' : 'See All Details',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: primary, size: 18),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // 4. EXPANDABLE SECTION
  // ══════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════
  // 5. COMPLETION BADGE
  // ══════════════════════════════════════════════════════════════════
  Widget _buildCompletionBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              'COMPLETED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  String _fmtDateTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${_months[d.month - 1]} ${d.day}, $h:${d.minute.toString().padLeft(2, '0')} $p';
  }
}

// ══════════════════════════════════════════════════════════════════════
// SUPPORTING WIDGETS
// ══════════════════════════════════════════════════════════════════════

class _GlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final double opacity;

  const _GlassPill({
    required this.label,
    this.icon,
    this.color,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.withOpacity(0.18 * opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: c.withOpacity(0.35 * opacity),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: c.withOpacity(0.9 * opacity)),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: c.withOpacity(0.95 * opacity),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  final TaskMetricIndicator indicator;
  final String label;

  const _HeroMetricCard({required this.indicator, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.2), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── HEX PAINTER ──────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  final Color color;
  _HexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const r = 16.0;
    const dx = r * 1.5;
    final dy = r * math.sqrt(3);
    for (double y = -dy; y < size.height + dy; y += dy) {
      for (double x = -dx; x < size.width + dx; x += dx * 2) {
        _hex(canvas, x, y, r, paint);
        _hex(canvas, x + dx, y + dy / 2, r, paint);
      }
    }
  }

  void _hex(Canvas c, double cx, double cy, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

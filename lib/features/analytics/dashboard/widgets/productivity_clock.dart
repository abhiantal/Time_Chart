// ================================================================
// FILE: lib/features/personal/dashboard/widgets/productivity_clock.dart
// PREMIUM ANIMATED 24-HOUR PRODUCTIVITY CLOCK
// Fully integrated with CardColorHelper & AdvancedProgressIndicator
// ================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../helpers/card_color_helper.dart';
import '../../../../widgets/bar_progress_indicator.dart';

// ================================================================
// TASK SEGMENT MODEL (Enhanced)
// ================================================================

class TaskSegment {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String priority;
  final String status;
  final int progress; // 0–100
  final int points;
  final String? categoryType;
  final String? reward;
  final String taskType;

  const TaskSegment({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.priority = 'medium',
    this.status = 'pending',
    this.progress = 0,
    this.points = 0,
    this.categoryType,
    this.reward,
    this.taskType = 'Task',
  });

  /// Duration in hours (0–24)
  double get durationHours {
    final minutes = endTime.difference(startTime).inMinutes.clamp(0, 24 * 60);
    return minutes / 60.0;
  }

  /// Duration fraction of 24 hours
  double get durationFraction {
    final minutes = endTime.difference(startTime).inMinutes;
    return (minutes / (24 * 60)).clamp(0.0, 1.0);
  }

  /// Start angle in radians (0 = midnight = top, clockwise)
  /// Offset by -90° (π/2) so midnight is at top
  double get startAngle {
    final minutes = startTime.hour * 60 + startTime.minute;
    return (minutes / (24 * 60)) * 2 * math.pi;
  }

  /// Sweep angle in radians
  double get sweepAngle {
    final minutes = endTime.difference(startTime).inMinutes.clamp(0, 24 * 60);
    return (minutes / (24 * 60)) * 2 * math.pi;
  }

  bool get isActive =>
      status.toLowerCase() == 'inprogress' ||
      status.toLowerCase() == 'in_progress';

  bool get isCompleted =>
      status.toLowerCase() == 'completed' || progress >= 100;

  bool get isMissed =>
      status.toLowerCase() == 'missed' || status.toLowerCase() == 'failed';

  bool get isPending =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'upcoming';

  String get timeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start – $end';
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed ✓';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'missed':
      case 'failed':
        return 'Missed';
      case 'pending':
      case 'upcoming':
        return 'Pending';
      default:
        return status;
    }
  }

  String get priorityLabel {
    if (priority.isEmpty) return 'Medium';
    return '${priority[0].toUpperCase()}${priority.substring(1)}';
  }
}

// ================================================================
// MAIN WIDGET
// ================================================================

class Productivity24HourClock extends StatefulWidget {
  final List<TaskSegment> tasks;
  final double dailyProgress; // 0.0–1.0
  final bool isDarkMode;
  final double size;
  final VoidCallback? onTaskTap;
  final Function(TaskSegment)? onTaskSelected;
  final String tier;

  const Productivity24HourClock({
    super.key,
    required this.tasks,
    required this.dailyProgress,
    this.isDarkMode = true,
    this.size = 320,
    this.onTaskTap,
    this.onTaskSelected,
    this.tier = 'none',
  });

  @override
  State<Productivity24HourClock> createState() =>
      _Productivity24HourClockState();
}

class _Productivity24HourClockState extends State<Productivity24HourClock>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late AnimationController _glowController;

  late Animation<double> _ringAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _glowAnimation;

  TaskSegment? _selectedTask;
  Offset _cardPosition = Offset.zero;
  bool _cardVisible = false;

  Timer? _liveTimeTimer;

  @override
  void initState() {
    super.initState();

    // Ring entrance animation
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeInOutCubic,
    );

    // Pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    // Card pop animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );

    _ringController.forward();

    // Setup periodic timer to refresh the live current time pointer smoothly without continuous 60fps canvas ticks
    _liveTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _liveTimeTimer?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Offset center, double outerR) {
    final local = details.localPosition;
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Check if tap is within task ring
    final innerR = outerR * 0.65;
    if (dist < innerR || dist > outerR + 8) {
      if (_cardVisible) _dismissCard();
      return;
    }

    // Calculate angle (from top, clockwise)
    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    // Find hit task
    TaskSegment? hit;
    for (final task in widget.tasks) {
      double start = task.startAngle % (2 * math.pi);
      if (start < 0) start += 2 * math.pi;
      final sweep = task.sweepAngle;
      double end = (start + sweep) % (2 * math.pi);

      bool inArc;
      if (sweep >= 2 * math.pi) {
        inArc = true;
      } else if (end > start) {
        inArc = angle >= start && angle <= end;
      } else {
        inArc = angle >= start || angle <= end;
      }

      if (inArc) {
        hit = task;
        break;
      }
    }

    if (hit != null) {
      HapticFeedback.lightImpact();
      widget.onTaskSelected?.call(hit);
      setState(() {
        _selectedTask = hit;
        _cardPosition = details.localPosition;
        _cardVisible = true;
      });
      _cardController.reset();
      _cardController.forward();
    } else {
      _dismissCard();
    }
  }

  void _dismissCard() {
    _cardController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _cardVisible = false;
          _selectedTask = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final center = Offset(size / 2, size / 2);
    final outerR = size * 0.45;

    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size + 60,
        child: Stack(
          children: [
            // Clock face
            SizedBox(
              width: size,
              height: size,
              child: GestureDetector(
                onTapUp: (d) => _handleTap(d, center, outerR),
                child: AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (ctx, _) => CustomPaint(
                    size: Size(size, size),
                    painter: _ClockPainter(
                      tasks: widget.tasks,
                      dailyProgress: widget.dailyProgress,
                      isDarkMode: widget.isDarkMode,
                      ringAnimation: _ringAnimation.value,
                      pulseAnimation: 1.0,
                      glowAnimation: 1.0,
                      selectedTaskId: _selectedTask?.id,
                      tier: widget.tier,
                    ),
                  ),
                ),
              ),
            ),

            // Center display
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ringAnimation,
                builder: (ctx, _) => Center(
                  child: _CenterProgressDisplay(
                    progress: widget.dailyProgress * _ringAnimation.value,
                    tasks: widget.tasks,
                    isDarkMode: widget.isDarkMode,
                    pulseAnim: _pulseAnimation,
                  ),
                ),
              ),
            ),

            // Floating task card
            if (_cardVisible && _selectedTask != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissCard,
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          const cardW = ClockPopupConfig.kClockPopupWidth;
                          const cardH = ClockPopupConfig.kClockPopupHeight;

                          // Clamp position
                          double left = _cardPosition.dx - cardW / 2;
                          double top = _cardPosition.dy - cardH - 20;
                          left = left.clamp(8.0, size - cardW - 8);
                          top = top.clamp(8.0, size - cardH - 8);

                          return Positioned(
                            left: left,
                            top: top,
                            child: AnimatedBuilder(
                              animation: _cardAnimation,
                              builder: (ctx, _) => _TaskDetailCard(
                                task: _selectedTask!,
                                isDarkMode: widget.isDarkMode,
                                animValue: _cardAnimation.value,
                                onDismiss: _dismissCard,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CLOCK PAINTER
// ================================================================

class _ClockPainter extends CustomPainter {
  final List<TaskSegment> tasks;
  final double dailyProgress;
  final bool isDarkMode;
  final double ringAnimation;
  final double pulseAnimation;
  final double glowAnimation;
  final String? selectedTaskId;
  final String tier;

  _ClockPainter({
    required this.tasks,
    required this.dailyProgress,
    required this.isDarkMode,
    required this.ringAnimation,
    required this.pulseAnimation,
    required this.glowAnimation,
    required this.selectedTaskId,
    required this.tier,
  });

  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.45;

    _drawBackground(canvas, center, outerR);
    _drawProductivityRing(canvas, center, outerR);
    _drawTaskArcs(canvas, center, outerR);
    _drawCurrentTimeLine(canvas, center, outerR);
    _drawHourMarkers(canvas, center, outerR);
  }

  void _drawBackground(Canvas canvas, Offset center, double radius) {
    final bg = isDarkMode ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FF);

    // Outer glow
    final haloPaint = Paint()
      ..color = (isDarkMode ? const Color(0xFF2563EB) : const Color(0xFF3B82F6))
          .withValues(alpha: 0.15 + 0.1 * glowAnimation)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    canvas.drawCircle(center, radius + 20, haloPaint);

    // Background
    canvas.drawCircle(center, radius + 8, Paint()..color = bg);

    // Radial gradient
    final gradient = RadialGradient(
      colors: isDarkMode
          ? [const Color(0xFF0F172A), const Color(0xFF030712)]
          : [const Color(0xFFFAFCFF), const Color(0xFFF0F4FF)],
    );
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius + 8),
        ),
    );

    // Subtle border
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..color = (isDarkMode ? Colors.white : Colors.black).withValues(
          alpha: 0.05,
        )
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawProductivityRing(Canvas canvas, Offset center, double outerR) {
    final innerR = outerR * 0.88;
    final strokeW = (outerR - innerR) * 0.35;
    final r = (innerR + outerR) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    // Background track
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color =
            (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF))
                .withValues(alpha: 0.4)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Productive sweep
    if (ringAnimation > 0 && dailyProgress > 0) {
      final sweep = 2 * math.pi * dailyProgress * ringAnimation;

      // Gradient colors based on user tier (from total_points)
      final baseColor = CardColorHelper.getTierColor(tier);
      final colors = [
        baseColor,
        baseColor.withValues(alpha: 0.6),
      ];

      // Glow
      canvas.drawArc(
        rect,
        _startAngle,
        sweep,
        false,
        Paint()
          ..strokeWidth = strokeW + 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            8 + 4 * glowAnimation,
          )
          ..shader = SweepGradient(
            startAngle: _startAngle,
            endAngle: _startAngle + sweep,
            colors: colors.map((c) => c.withValues(alpha: 0.3)).toList(),
          ).createShader(rect),
      );

      // Main arc
      canvas.drawArc(
        rect,
        _startAngle,
        sweep,
        false,
        Paint()
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: _startAngle,
            endAngle: _startAngle + sweep,
            colors: colors,
          ).createShader(rect),
      );
    }
  }

  void _drawTaskArcs(Canvas canvas, Offset center, double outerR) {
    final innerR = outerR * 0.64;
    final strokeW = (outerR - innerR) * 0.22;
    final r = (innerR + outerR) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);

    // Background track (Non-scheduled hours) -> 0xFF8b8176
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF8B8176).withValues(alpha: 0.5)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke,
    );
    
    // Foreground track overlay (Scheduled hours) -> 0xFF1976d2
    // We could draw arcs for the scheduled blocks, but to keep it simple, 
    // the clock normally paints the whole track as non-scheduled,
    // and task segments will cover it. If a task is pending/upcoming, 
    // its segment color handles the "scheduled hour" look.

    for (final task in tasks) {
      final isSelected = selectedTaskId == task.id;
      final startA = _startAngle + task.startAngle;
      final sweepA = task.sweepAngle * ringAnimation;
      if (sweepA <= 0) continue;

      final colors = _getClockTaskColor(task);

      // Shadow
      canvas.drawArc(
        rect,
        startA,
        sweepA,
        false,
        Paint()
          ..color = colors[0].withValues(alpha: 0.2)
          ..strokeWidth = strokeW + 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Glow for active/selected
      if (task.isActive || isSelected) {
        final glowW = strokeW + 8 + 4 * glowAnimation;
        canvas.drawArc(
          rect,
          startA,
          sweepA,
          false,
          Paint()
            ..strokeWidth = glowW
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              10 + 4 * glowAnimation,
            )
            ..shader = SweepGradient(
              startAngle: startA,
              endAngle: startA + sweepA,
              colors: [
                colors[0].withValues(alpha: 0.4),
                colors[colors.length > 1 ? 1 : 0].withValues(alpha: 0.25),
              ],
            ).createShader(rect),
        );
      }

      // Main arc
      canvas.drawArc(
        rect,
        startA,
        sweepA,
        false,
        Paint()
          ..strokeWidth = isSelected ? strokeW + 3 : strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startA,
            endAngle: startA + sweepA,
            colors: colors,
          ).createShader(rect),
      );

      // Progress overlay
      if (task.progress > 0 && task.progress < 100) {
        final progressSweep = sweepA * (task.progress / 100.0);
        canvas.drawArc(
          rect,
          startA,
          progressSweep,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..strokeWidth = strokeW * 0.35
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }

      // End dot
      final endAngle = startA + sweepA;
      final dotX = center.dx + r * math.cos(endAngle);
      final dotY = center.dy + r * math.sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        isSelected ? 5 : 3.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        isSelected ? 3 : 2,
        Paint()..color = colors[0],
      );
    }
  }

  void _drawCurrentTimeLine(Canvas canvas, Offset center, double outerR) {
    final now = DateTime.now();
    final minutesFromMidnight = now.hour * 60 + now.minute;
    final fraction = minutesFromMidnight / (24 * 60);
    final angle = _startAngle + fraction * 2 * math.pi;

    final innerR = outerR * 0.6;

    // Glow
    canvas.drawLine(
      Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      ),
      Offset(
        center.dx + (outerR + 12) * math.cos(angle),
        center.dy + (outerR + 12) * math.sin(angle),
      ),
      Paint()
        ..color =
            (isDarkMode ? const Color(0xFFFF4D8A) : const Color(0xFFEC4899))
                .withValues(alpha: 0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawLine(
      Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      ),
      Offset(
        center.dx + (outerR + 12) * math.cos(angle),
        center.dy + (outerR + 12) * math.sin(angle),
      ),
      Paint()
        ..color = isDarkMode ? const Color(0xFFFF4D8A) : const Color(0xFFEC4899)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dot
    canvas.drawCircle(
      Offset(
        center.dx + (outerR + 12) * math.cos(angle),
        center.dy + (outerR + 12) * math.sin(angle),
      ),
      5.5,
      Paint()
        ..color = isDarkMode
            ? const Color(0xFFFF4D8A)
            : const Color(0xFFEC4899),
    );
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double outerR) {
    final labelR = outerR + 28;
    const majorLabels = {
      0: '0h',
      3: '3h',
      6: '6h',
      9: '9h',
      12: '12h',
      15: '15h',
      18: '18h',
      21: '21h',
    };

    for (int h = 0; h < 24; h++) {
      final angle = _startAngle + (h / 24) * 2 * math.pi;
      final isMajor = h % 3 == 0;
      final tickLen = isMajor ? 10.0 : 5.0;
      final tickW = isMajor ? 2.0 : 1.0;

      final x1 = center.dx + outerR * math.cos(angle);
      final y1 = center.dy + outerR * math.sin(angle);
      final x2 = center.dx + (outerR + tickLen) * math.cos(angle);
      final y2 = center.dy + (outerR + tickLen) * math.sin(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = (isDarkMode ? Colors.white : const Color(0xFF1E3A8A))
              .withValues(alpha: isMajor ? 0.7 : 0.3)
          ..strokeWidth = tickW
          ..strokeCap = StrokeCap.round,
      );

      if (isMajor && majorLabels.containsKey(h)) {
        final lx = center.dx + labelR * math.cos(angle);
        final ly = center.dy + labelR * math.sin(angle);
        _drawText(
          canvas,
          majorLabels[h]!,
          Offset(lx, ly),
          isDarkMode
              ? Colors.white.withValues(alpha: 0.6)
              : const Color(0xFF1E3A8A).withValues(alpha: 0.7),
          9,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double size,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  List<Color> _getClockTaskColor(TaskSegment task) {
    // Custom user requested colors
    const bucket = Color(0xFFFB8500);
    const diary = Color(0xFFFFB703);
    const inProcess = Color(0xFFA7C957);
    const completed = Color(0xFF386641);
    const notCompleted = Color(0xFF9A031E);
    // scheduled hour
    const scheduled = Color(0xFF1976D2);
    
    Color primary;
    if (task.taskType.toLowerCase() == 'bucket') {
      primary = bucket;
    } else if (task.taskType.toLowerCase() == 'diary') {
      primary = diary;
    } else if (task.isCompleted) {
      primary = completed;
    } else if (task.isActive) {
      primary = inProcess;
    } else if (task.isMissed) {
      primary = notCompleted;
    } else {
      primary = scheduled;
    }

    return [primary, primary.withValues(alpha: 0.7)];
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.ringAnimation != ringAnimation ||
      old.pulseAnimation != pulseAnimation ||
      old.glowAnimation != glowAnimation ||
      old.selectedTaskId != selectedTaskId;
}

// ================================================================
// CENTER DISPLAY
// ================================================================

class _CenterProgressDisplay extends StatelessWidget {
  final double progress;
  final List<TaskSegment> tasks;
  final bool isDarkMode;
  final Animation<double> pulseAnim;

  const _CenterProgressDisplay({
    required this.progress,
    required this.tasks,
    required this.isDarkMode,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();

    final total = tasks.length;
    final done = tasks.where((t) => t.isCompleted).length;
    final active = total - done;

    final bg = isDarkMode ? const Color(0xFF0D1120) : Colors.white;
    final fg = isDarkMode ? Colors.white : const Color(0xFF0D1120);
    final sub = fg.withValues(alpha: 0.5);

    // Productivity color
    late Color prodColor;
    if (progress >= 0.7) {
      prodColor = isDarkMode
          ? const Color(0xFF00FF88)
          : const Color(0xFF10B981);
    } else if (progress >= 0.4) {
      prodColor = isDarkMode
          ? const Color(0xFFFFD700)
          : const Color(0xFFF59E0B);
    } else {
      prodColor = isDarkMode
          ? const Color(0xFFFF6B6B)
          : const Color(0xFFEF4444);
    }

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (ctx, _) {
        final scale = 1.0 + 0.02 * pulseAnim.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: prodColor.withValues(
                    alpha: 0.15 + 0.1 * pulseAnim.value,
                  ),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Percentage with gradient
                ShaderMask(
                  shaderCallback: (r) => LinearGradient(
                    colors: [prodColor, prodColor.withValues(alpha: 0.7)],
                  ).createShader(r),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Productive',
                  style: TextStyle(
                    fontSize: 10,
                    color: sub,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatCol(
                      label: 'Done',
                      value: '$done',
                      color: isDarkMode
                          ? const Color(0xFF00FF88)
                          : const Color(0xFF10B981),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: sub.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    _StatCol(
                      label: 'Active',
                      value: '$active',
                      color: isDarkMode
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFF59E0B),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: sub.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    _StatCol(label: 'Total', value: '$total', color: fg),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// TASK DETAIL CARD
// ================================================================

class _TaskDetailCard extends StatelessWidget {
  final TaskSegment task;
  final bool isDarkMode;
  final double animValue;
  final VoidCallback onDismiss;

  const _TaskDetailCard({
    required this.task,
    required this.isDarkMode,
    required this.animValue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    const cardW = ClockPopupConfig.kClockPopupWidth;

    final colors = CardColorHelper.getTaskCardGradient(
      priority: task.priority,
      status: task.status,
      progress: task.progress,
      isDarkMode: isDarkMode,
    );
    final accentColor = colors[0];

    final bg = isDarkMode
        ? const Color(0xFF0F1628).withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.97);
    final fg = isDarkMode ? Colors.white : const Color(0xFF0D1120);
    final sub = fg.withValues(alpha: 0.5);

    return Transform.scale(
      scale: animValue.clamp(0.0, 1.0),
      child: Opacity(
        opacity: animValue.clamp(0.0, 1.0),
        child: Container(
          width: cardW,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.2),
                        accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTaskIcon(task.taskType),
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              task.taskType.toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.title,
                              style: TextStyle(
                                color: fg,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: sub,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Timing',
                        value: task.timeRange,
                        fg: fg,
                        sub: sub,
                        color: accentColor,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.auto_graph_rounded,
                        label: 'Status',
                        value: task.statusLabel,
                        fg: fg,
                        sub: sub,
                        color: accentColor,
                      ),
                      const SizedBox(height: 20),
                      // Progress Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PROGRESS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: sub,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '${task.progress}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accentColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            CustomProgressIndicator(
                              progress: (task.progress / 100.0).clamp(0, 1),
                              progressBarName: '',
                              baseHeight: 6,
                              maxHeightIncrease: 0,
                              backgroundColor: isDarkMode
                                  ? Colors.black26
                                  : Colors.grey[200]!,
                              progressColor: accentColor,
                              gradientColors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                              borderRadius: 3,
                              progressLabelDisplay: ProgressLabelDisplay.none,
                              animated: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'day task':
        return Icons.today_rounded;
      case 'weekly task':
        return Icons.event_repeat_rounded;
      case 'long goal':
        return Icons.emoji_events_rounded;
      case 'bucket':
        return Icons.shopping_basket_rounded;
      case 'diary entry':
        return Icons.edit_note_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color fg, sub, color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: sub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: fg,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
// ================================================================
// CONFIGURATION FOR CLOCK POPUP DIMENSIONS
// ================================================================

class ClockPopupConfig {
  static const double kClockPopupWidth = 240.0;
  static const double kClockPopupHeight = 240.0;
}

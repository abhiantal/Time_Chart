// ================================================================
// FILE: progress_history_shared_widgets.dart
// ================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Dashboard shared ─────────────────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/shared_widgets.dart';
// removed import

// ================================================================
// 1. SECTION LABEL  (identical style used in all detail screens)
// ================================================================

class PHSectionLabel extends StatelessWidget {
  final String label;
  const PHSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ],
    );
  }
}

// ================================================================
// 2. CARD SHELL
// ================================================================

class PHCardShell extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final List<Color>? gradient;
  final EdgeInsets? padding;

  const PHCardShell({
    super.key,
    required this.child,
    this.accentColor,
    this.gradient,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient!)
            : null,
        color: gradient == null
            ? (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface)
            : null,
        borderRadius: BorderRadius.circular(18),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.22))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// 3. HERO STAT + DIVIDER  (used in both hero headers)
// ================================================================

class PHHeroStat extends StatelessWidget {
  final String value, label, icon;
  const PHHeroStat(
      {super.key,
        required this.value,
        required this.label,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class PHHeroDiv extends StatelessWidget {
  const PHHeroDiv({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.22));
}

// ================================================================
// 4. TREND BANNER
// Used by both screens to show improving / declining / stable
// ================================================================

class PHTrendBanner extends StatelessWidget {
  final String trend;
  final IconData trendIcon;
  final String? subtitle;

  const PHTrendBanner({
    super.key,
    required this.trend,
    required this.trendIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isUp = trend.toLowerCase() == 'improving' ||
        trend.toLowerCase() == 'up';
    final isDown = trend.toLowerCase() == 'declining' ||
        trend.toLowerCase() == 'down';

    final color = isUp
        ? const Color(0xFF10B981)
        : isDown
        ? const Color(0xFFEF4444)
        : const Color(0xFF94A3B8);

    final emoji = isUp ? '📈' : isDown ? '📉' : '➡️';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trend: ${_capitalize(trend)}',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: color)),
            if (subtitle != null)
              Text(subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      height: 1.4)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(trendIcon, color: color, size: 20),
        ),
      ]),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ================================================================
// 5. HIGHLIGHT CARD  (best/worst day or week)
// Generic — works for both screen types
// ================================================================

class PHHighlightCard extends StatelessWidget {
  final String label;         // "Best Day" / "Worst Week"
  final String dateLabel;     // formatted date or "Week 12"
  final int points;
  final int? tasksCompleted;
  final IconData icon;
  final Color color;

  const PHHighlightCard({
    super.key,
    required this.label,
    required this.dateLabel,
    required this.points,
    this.tasksCompleted,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDark ? 0.22 : 0.14),
            color.withOpacity(isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
            Text(dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800)),
            if (tasksCompleted != null)
              Text('$tasksCompleted tasks completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                      fontSize: 10)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+$points',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900, color: color)),
          Text('pts',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withOpacity(0.7))),
        ]),
      ]),
    );
  }
}

// ================================================================
// 6. SPARKLINE CHART  (replaces fl_chart LineChartWidget)
// Draws a smooth line from List<num> values using CustomPainter.
// Used by both screens with their respective data series.
// ================================================================

class PHSparklineChart extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<num> values;           // y-axis data points
  final List<String> labels;        // x-axis labels (show every N-th)
  final Color lineColor;
  final double height;
  final bool showDots;

  const PHSparklineChart({
    super.key,
    required this.title,
    this.subtitle,
    required this.values,
    required this.labels,
    this.lineColor = const Color(0xFF3B82F6),
    this.height = 200,
    this.showDots = false,
  });

  @override
  State<PHSparklineChart> createState() => _PHSparklineChartState();
}

class _PHSparklineChartState extends State<PHSparklineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.values.isEmpty) {
      return PHCardShell(
        child: SizedBox(
          height: widget.height,
          child: EmptyStateWidget(
            icon: Icons.show_chart_rounded,
            title: 'No Data',
            subtitle: 'No data available yet',
          ),
        ),
      );
    }

    final maxVal = widget.values.isEmpty ? 100.0 : widget.values.reduce((a, b) => a > b ? a : b);

    return PHCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (widget.subtitle != null)
                Text(widget.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Max: ${maxVal.toStringAsFixed(0)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.lineColor)),
            ),
          ]),
          const SizedBox(height: 16),

          // Chart canvas
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => GestureDetector(
              onTapDown: (d) {
                final box =
                context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(d.globalPosition);
                final chartWidth = box.size.width;
                final n = widget.values.length;
                if (n < 2) return;
                final idx =
                ((localPos.dx / chartWidth) * (n - 1)).round().clamp(0, n - 1);
                setState(() => _hoveredIndex = idx);
              },
              child: SizedBox(
                height: widget.height,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SparklinePainter(
                    values: widget.values,
                    progress: _anim.value,
                    lineColor: widget.lineColor,
                    fillColor: widget.lineColor.withOpacity(0.12),
                    gridColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    dotColor: widget.lineColor,
                    showDots: widget.showDots,
                    hoveredIndex: _hoveredIndex,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          // X-axis labels
          _buildXLabels(theme),

          // Tooltip for hovered index
          if (_hoveredIndex != null &&
              _hoveredIndex! < widget.values.length) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: widget.lineColor.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: widget.lineColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  '${_hoveredIndex! < widget.labels.length ? widget.labels[_hoveredIndex!] : ''}  •  ${widget.values[_hoveredIndex!].toStringAsFixed(0)} pts',
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.lineColor),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXLabels(ThemeData theme) {
    if (widget.labels.isEmpty) return const SizedBox.shrink();
    final n = widget.labels.length;
    // Show ~5 labels
    final step = (n / 5).ceil().clamp(1, n);
    final shown = <int>[];
    for (int i = 0; i < n; i += step) {
      shown.add(i);
    }
    if (!shown.contains(n - 1)) shown.add(n - 1);

    return Row(
      children: List.generate(n, (i) {
        if (!shown.contains(i)) return const Expanded(child: SizedBox());
        return Expanded(
          child: Text(
            widget.labels[i],
            textAlign: i == 0
                ? TextAlign.left
                : i == n - 1
                ? TextAlign.right
                : TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        );
      }),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<num> values;
  final double progress;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color dotColor;
  final bool showDots;
  final int? hoveredIndex;
  final bool isDark;

  _SparklinePainter({
    required this.values,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.dotColor,
    required this.showDots,
    this.hoveredIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final n = values.length;
    final maxVal =
    values.fold<double>(0, (m, v) => v.toDouble() > m ? v.toDouble() : m);
    final minVal = values.fold<double>(
        maxVal, (m, v) => v.toDouble() < m ? v.toDouble() : m);
    final range = (maxVal - minVal).abs();
    final safeRange = range == 0 ? 1.0 : range;

    // 4 horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double _x(int idx) =>
        n == 1 ? size.width / 2 : idx / (n - 1) * size.width;
    double _y(int idx) {
      final v = values[idx].toDouble();
      return size.height * (1 - ((v - minVal) / safeRange));
    }

    // Build path up to progress
    final visibleCount = (n * progress).ceil().clamp(1, n);

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(_x(0), size.height);
    fillPath.lineTo(_x(0), _y(0));
    for (int i = 1; i < visibleCount; i++) {
      final prev = Offset(_x(i - 1), _y(i - 1));
      final curr = Offset(_x(i), _y(i));
      final cp1 = Offset(prev.dx + (curr.dx - prev.dx) / 3, prev.dy);
      final cp2 = Offset(curr.dx - (curr.dx - prev.dx) / 3, curr.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    final lastVisX = _x(visibleCount - 1);
    fillPath.lineTo(lastVisX, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor, fillColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(_x(0), _y(0));
    for (int i = 1; i < visibleCount; i++) {
      final prev = Offset(_x(i - 1), _y(i - 1));
      final curr = Offset(_x(i), _y(i));
      final cp1 = Offset(prev.dx + (curr.dx - prev.dx) / 3, prev.dy);
      final cp2 = Offset(curr.dx - (curr.dx - prev.dx) / 3, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    if (showDots || hoveredIndex != null) {
      for (int i = 0; i < visibleCount; i++) {
        final isHovered = hoveredIndex == i;
        if (!showDots && !isHovered) continue;

        final paint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
          ..style = PaintingStyle.fill;

        final radius = isHovered ? 7.0 : 3.5;
        canvas.drawCircle(Offset(_x(i), _y(i)), radius + 1.5, borderPaint);
        canvas.drawCircle(Offset(_x(i), _y(i)), radius, paint);

        // Vertical guide line for hovered
        if (isHovered) {
          final guidePaint = Paint()
            ..color = lineColor.withOpacity(0.3)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
              Offset(_x(i), 0), Offset(_x(i), size.height), guidePaint);
        }
      }
    }

    // End-of-line glow dot
    if (visibleCount > 0) {
      final endX = _x(visibleCount - 1);
      final endY = _y(visibleCount - 1);
      canvas.drawCircle(
          Offset(endX, endY),
          5,
          Paint()
            ..color = lineColor.withOpacity(0.2)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          Offset(endX, endY),
          3,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.progress != progress || old.hoveredIndex != hoveredIndex;
}

// ================================================================
// 7. WEEK COMPARE STRIP  (used by WeeklyHistoryDetailScreen)
// ================================================================

class PHWeekCompareStrip extends StatelessWidget {
  final int currentWeekPoints;
  final int lastWeekPoints;
  final double weekOverWeekChange;

  const PHWeekCompareStrip({
    super.key,
    required this.currentWeekPoints,
    required this.lastWeekPoints,
    required this.weekOverWeekChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPositive = weekOverWeekChange >= 0;
    final changeColor = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    final maxPts = math.max(currentWeekPoints, lastWeekPoints);
    final currentFrac =
    maxPts > 0 ? currentWeekPoints / maxPts : 0.0;
    final lastFrac =
    maxPts > 0 ? lastWeekPoints / maxPts : 0.0;

    return PHCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Week Comparison',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: changeColor.withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: changeColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${weekOverWeekChange.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: changeColor),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 18),

          // This week bar
          _WeekBar(
            label: 'This Week',
            emoji: '📅',
            points: currentWeekPoints,
            fraction: currentFrac,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 14),

          // Last week bar
          _WeekBar(
            label: 'Last Week',
            emoji: '📆',
            points: lastWeekPoints,
            fraction: lastFrac,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  final String label, emoji;
  final int points;
  final double fraction;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _WeekBar({
    required this.label,
    required this.emoji,
    required this.points,
    required this.fraction,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ]),
          Text('+$points pts',
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 6),
        CustomProgressIndicator(
          progress: fraction.clamp(0.0, 1.0),
          progressBarName: '',
          orientation: ProgressOrientation.horizontal,
          baseHeight: 11,
          maxHeightIncrease: 4,
          gradientColors: [color, color.withOpacity(0.55)],
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.shade200,
          borderRadius: 8,
          progressLabelDisplay: ProgressLabelDisplay.none,
          nameLabelPosition: LabelPosition.bottom,
          animateNameLabel: false,
          animationDuration: const Duration(milliseconds: 1300),
          animationCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

// ================================================================
// 8. AVERAGE METRIC ARC  (AdvancedProgressIndicator arc)
// Generic — used in both screens for avg daily / avg weekly
// ================================================================

class PHAverageArc extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final double progress;   // 0.0 – 1.0 relative to a max
  final Color color;
  final String emoji;

  const PHAverageArc({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PHCardShell(
      accentColor: color,
      gradient: [
        color.withOpacity(isDark ? 0.2 : 0.12),
        color.withOpacity(isDark ? 0.07 : 0.03),
      ],
      child: Row(children: [
        AdvancedProgressIndicator(
          progress: progress.clamp(0.0, 1.0),
          size: 100,
          strokeWidth: 9,
          shape: ProgressShape.arc,
          arcStartAngle: 180,
          arcSweepAngle: 180,
          gradientColors: [color, color.withOpacity(0.5)],
          backgroundColor: color.withOpacity(0.1),
          labelStyle: ProgressLabelStyle.custom,
          customLabel: value,
          labelTextStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900, color: color),
          animationDuration: const Duration(milliseconds: 1400),
          animationCurve: Curves.easeOutCubic,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6))),
            Text('$value $unit',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, color: color)),
          ]),
        ),
      ]),
    );
  }
}

// ================================================================
// 9. STAT SUMMARY GRID  (used by both screens)
// Generic 2×N grid of stat tiles
// ================================================================

class PHStatSummaryGrid extends StatelessWidget {
  final List<PHStatTileData> tiles;

  const PHStatSummaryGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) => _PHStatTile(data: tiles[i]),
    );
  }
}

class PHStatTileData {
  final String emoji, label, value;
  final Color color;
  const PHStatTileData(
      {required this.emoji,
        required this.label,
        required this.value,
        required this.color});
}

class _PHStatTile extends StatelessWidget {
  final PHStatTileData data;
  const _PHStatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.color.withOpacity(isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 18)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: data.color)),
            Text(data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 9)),
          ]),
        ],
      ),
    );
  }
}
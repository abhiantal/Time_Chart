// lib/message_bubbles/advanced_progress_indicator.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

// --- ENUMS ---
enum ProgressShape { circular, arc }

enum ProgressLabelPosition { top, bottom, left, right, center, none }

enum ProgressLabelStyle { none, percentage, custom, box, bubble }

// --- MAIN WIDGET ---
class AdvancedProgressIndicator extends StatefulWidget {
  // Core Properties
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final ProgressShape shape;

  // Colors & Styling
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Color>? gradientColors;
  final Gradient? customGradient;
  final Color? shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  // Progress Label
  final ProgressLabelStyle labelStyle;
  final String? customLabel;
  final TextStyle? labelTextStyle;
  final Color? labelBackgroundColor;
  final EdgeInsetsGeometry labelPadding;
  final double labelSpacing;

  // Name Label
  final String? name;
  final ProgressLabelPosition namePosition;
  final TextStyle? nameTextStyle;
  final EdgeInsetsGeometry namePadding;

  // Arc Specific (when shape = arc)
  final double arcStartAngle; // in degrees
  final double arcSweepAngle; // in degrees (e.g., 180 for semicircle)
  final bool arcFromCenter; // Draw from center like a pie chart

  // Circular Specific
  final double circularStartAngle; // in degrees (0 = top, 90 = right)
  final bool clockwise;
  final StrokeCap strokeCap;

  // Animation
  final bool animated;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool animateLabel;
  final Duration labelAnimationDuration;

  // Decorations
  final double borderWidth;
  final Color? borderColor;
  final bool showGlow;
  final double glowRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AdvancedProgressIndicator({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.shape = ProgressShape.circular,
    this.backgroundColor,
    this.foregroundColor,
    this.gradientColors,
    this.customGradient,
    this.shadowColor,
    this.shadowBlur = 8.0,
    this.shadowOffset = const Offset(0, 4),
    this.labelStyle = ProgressLabelStyle.percentage,
    this.customLabel,
    this.labelTextStyle,
    this.labelBackgroundColor,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.labelSpacing = 12.0,
    this.name,
    this.namePosition = ProgressLabelPosition.bottom,
    this.nameTextStyle,
    this.namePadding = const EdgeInsets.all(8),
    this.arcStartAngle = 0,
    this.arcSweepAngle = 180,
    this.arcFromCenter = false,
    this.circularStartAngle = -90,
    this.clockwise = true,
    this.strokeCap = StrokeCap.round,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationCurve = Curves.easeInOutCubic,
    this.animateLabel = true,
    this.labelAnimationDuration = const Duration(milliseconds: 600),
    this.borderWidth = 0,
    this.borderColor,
    this.showGlow = false,
    this.glowRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  State<AdvancedProgressIndicator> createState() =>
      _AdvancedProgressIndicatorState();
}

class _AdvancedProgressIndicatorState extends State<AdvancedProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _labelController;
  late Animation<double> _progressAnimation;
  late Animation<double> _labelAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: widget.animationCurve,
          ),
        );

    _labelController = AnimationController(
      duration: widget.labelAnimationDuration,
      vsync: this,
    );

    _labelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.elasticOut),
    );

    if (widget.animated) _progressController.forward();
    if (widget.animateLabel) _labelController.forward();
  }

  @override
  void didUpdateWidget(AdvancedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: widget.animationCurve,
            ),
          );

      if (widget.animated) {
        _progressController.reset();
        _progressController.forward();
      }
      if (widget.animateLabel) {
        _labelController.reset();
        _labelController.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: widget.margin,
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _labelAnimation]),
        builder: (context, _) {
          final progress = _progressAnimation.value.clamp(0.0, 1.0);
          return _buildLayout(context, theme, progress);
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, ThemeData theme, double progress) {
    final progressWidget = _buildProgressWidget(context, theme, progress);
    final nameWidget = _buildNameLabel(theme);

    if (widget.name == null ||
        widget.namePosition == ProgressLabelPosition.none) {
      return progressWidget;
    }

    switch (widget.namePosition) {
      case ProgressLabelPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: widget.namePadding, child: nameWidget),
            SizedBox(height: widget.labelSpacing),
            progressWidget,
          ],
        );
      case ProgressLabelPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            progressWidget,
            SizedBox(height: widget.labelSpacing),
            Padding(padding: widget.namePadding, child: nameWidget),
          ],
        );
      case ProgressLabelPosition.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(padding: widget.namePadding, child: nameWidget),
            SizedBox(width: widget.labelSpacing),
            progressWidget,
          ],
        );
      case ProgressLabelPosition.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            progressWidget,
            SizedBox(width: widget.labelSpacing),
            Padding(padding: widget.namePadding, child: nameWidget),
          ],
        );
      case ProgressLabelPosition.center:
        return Stack(
          alignment: Alignment.center,
          children: [progressWidget, nameWidget],
        );
      case ProgressLabelPosition.none:
        return progressWidget;
    }
  }

  Widget _buildProgressWidget(
    BuildContext context,
    ThemeData theme,
    double progress,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: AdvancedProgressPainter(
              progress: progress,
              strokeWidth: widget.strokeWidth,
              backgroundColor:
                  widget.backgroundColor ??
                  (isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey.shade200),
              foregroundColor:
                  widget.foregroundColor ?? theme.colorScheme.primary,
              gradientColors: widget.gradientColors,
              customGradient: widget.customGradient,
              shape: widget.shape,
              arcStartAngle: widget.arcStartAngle,
              arcSweepAngle: widget.arcSweepAngle,
              arcFromCenter: widget.arcFromCenter,
              circularStartAngle: widget.circularStartAngle,
              clockwise: widget.clockwise,
              strokeCap: widget.strokeCap,
              borderWidth: widget.borderWidth,
              borderColor: widget.borderColor,
              showGlow: widget.showGlow,
              glowRadius: widget.glowRadius,
              shadowColor: widget.shadowColor,
              shadowBlur: widget.shadowBlur,
              shadowOffset: widget.shadowOffset,
            ),
          ),
        ),
        if (widget.labelStyle != ProgressLabelStyle.none)
          _buildCenterLabel(context, theme, progress),
      ],
    );
  }

  Widget _buildCenterLabel(
    BuildContext context,
    ThemeData theme,
    double progress,
  ) {
    String labelText;
    switch (widget.labelStyle) {
      case ProgressLabelStyle.percentage:
        labelText = '${(progress * 100).toInt()}%';
        break;
      case ProgressLabelStyle.custom:
        labelText = widget.customLabel ?? '';
        break;
      case ProgressLabelStyle.box:
      case ProgressLabelStyle.bubble:
        labelText = widget.customLabel ?? '${(progress * 100).toInt()}%';
        break;
      case ProgressLabelStyle.none:
        return const SizedBox.shrink();
    }

    final isDark = theme.brightness == Brightness.dark;
    final defaultTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: isDark ? theme.colorScheme.onSurface : theme.colorScheme.primary,
    );

    Widget textWidget = Text(
      labelText,
      style: widget.labelTextStyle ?? defaultTextStyle,
      textAlign: TextAlign.center,
    );

    if (widget.labelStyle == ProgressLabelStyle.box) {
      textWidget = Container(
        padding: widget.labelPadding,
        decoration: BoxDecoration(
          color:
              widget.labelBackgroundColor ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (widget.labelBackgroundColor ?? theme.colorScheme.primary)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: textWidget,
      );
    } else if (widget.labelStyle == ProgressLabelStyle.bubble) {
      textWidget = Container(
        padding: widget.labelPadding,
        decoration: BoxDecoration(
          color:
              widget.labelBackgroundColor ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: textWidget,
      );
    }

    if (widget.animateLabel) {
      return AnimatedBuilder(
        animation: _labelAnimation,
        builder: (context, child) => Transform.scale(
          scale: 0.5 + (0.5 * _labelAnimation.value),
          child: Opacity(
            opacity: _labelAnimation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }

  Widget _buildNameLabel(ThemeData theme) {
    if (widget.name == null || widget.name!.isEmpty) {
      return const SizedBox.shrink();
    }

    final textStyle =
        widget.nameTextStyle ??
        theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);

    return Text(widget.name!, style: textStyle, textAlign: TextAlign.center);
  }
}

// --- CUSTOM PAINTER ---
class AdvancedProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<Color>? gradientColors;
  final Gradient? customGradient;
  final ProgressShape shape;
  final double arcStartAngle;
  final double arcSweepAngle;
  final bool arcFromCenter;
  final double circularStartAngle;
  final bool clockwise;
  final StrokeCap strokeCap;
  final double borderWidth;
  final Color? borderColor;
  final bool showGlow;
  final double glowRadius;
  final Color? shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  AdvancedProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
    this.gradientColors,
    this.customGradient,
    required this.shape,
    required this.arcStartAngle,
    required this.arcSweepAngle,
    required this.arcFromCenter,
    required this.circularStartAngle,
    required this.clockwise,
    required this.strokeCap,
    required this.borderWidth,
    this.borderColor,
    required this.showGlow,
    required this.glowRadius,
    this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shape == ProgressShape.circular) {
      _paintCircular(canvas, size);
    } else {
      _paintArc(canvas, size);
    }
  }

  void _paintCircular(Canvas canvas, Size size) {
    // Ensure size is valid
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Ensure radius is positive
    if (radius <= 0) return;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    canvas.drawCircle(center, radius, bgPaint);

    // Glow effect
    if (showGlow && progress > 0) {
      final glowPaint = Paint()
        ..color = foregroundColor.withOpacity(0.3)
        ..strokeWidth = strokeWidth + glowRadius
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      final sweepAngle = 2 * math.pi * progress * (clockwise ? 1 : -1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degreesToRadians(circularStartAngle),
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Shadow
    if (shadowColor != null && progress > 0) {
      final shadowPaint = Paint()
        ..color = shadowColor!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = strokeCap
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

      final sweepAngle = 2 * math.pi * progress * (clockwise ? 1 : -1);
      canvas.drawArc(
        Rect.fromCircle(center: center + shadowOffset, radius: radius),
        _degreesToRadians(circularStartAngle),
        sweepAngle,
        false,
        shadowPaint,
      );
    }

    // Progress arc
    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Ensure gradient parameters are valid before creating shader
    if (customGradient != null) {
      progressPaint.shader = customGradient!.createShader(rect);
    } else if (gradientColors != null && gradientColors!.length > 1) {
      final startAngle = _degreesToRadians(circularStartAngle);
      final endAngle = startAngle + (2 * math.pi * progress);

      // Ensure angles are valid and endAngle >= startAngle for SweepGradient
      if (startAngle.isFinite && endAngle.isFinite && endAngle >= startAngle) {
        try {
          progressPaint.shader = SweepGradient(
            colors: gradientColors!,
            startAngle: startAngle,
            endAngle: endAngle,
          ).createShader(rect);
        } catch (e) {
          // Fallback to solid color if gradient creation fails
          progressPaint.color = foregroundColor;
        }
      } else {
        // Fallback to solid color if angles are invalid
        progressPaint.color = foregroundColor;
      }
    } else {
      progressPaint.color = foregroundColor;
    }

    final sweepAngle = 2 * math.pi * progress * (clockwise ? 1 : -1);

    // Ensure sweepAngle is valid before drawing
    if (sweepAngle.isFinite) {
      canvas.drawArc(
        rect,
        _degreesToRadians(circularStartAngle),
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Border
    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;

      final borderRadius = radius + strokeWidth / 2 + borderWidth / 2;
      // Ensure border radius is valid
      if (borderRadius.isFinite && borderRadius > 0) {
        canvas.drawCircle(center, borderRadius, borderPaint);
      }
    }
  }

  void _paintArc(Canvas canvas, Size size) {
    // Ensure size is valid
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Ensure radius is positive
    if (radius <= 0) return;

    final startRad = _degreesToRadians(arcStartAngle);
    final totalSweepRad = _degreesToRadians(arcSweepAngle);
    final progressSweepRad = totalSweepRad * progress;

    // Ensure angles are valid
    if (!startRad.isFinite ||
        !totalSweepRad.isFinite ||
        !progressSweepRad.isFinite) {
      return;
    }

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = arcFromCenter ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = strokeCap;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startRad, totalSweepRad, arcFromCenter, bgPaint);

    // Glow effect
    if (showGlow && progress > 0) {
      final glowPaint = Paint()
        ..color = foregroundColor.withOpacity(0.3)
        ..strokeWidth = strokeWidth + glowRadius
        ..style = arcFromCenter ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeCap = strokeCap
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      canvas.drawArc(
        rect,
        startRad,
        progressSweepRad,
        arcFromCenter,
        glowPaint,
      );
    }

    // Progress arc
    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = arcFromCenter ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = strokeCap;

    if (customGradient != null) {
      progressPaint.shader = customGradient!.createShader(rect);
    } else if (gradientColors != null && gradientColors!.length > 1) {
      final endRad = startRad + progressSweepRad;

      // Ensure angles are valid and endRad >= startRad for SweepGradient
      if (startRad.isFinite && endRad.isFinite && endRad >= startRad) {
        try {
          progressPaint.shader = SweepGradient(
            colors: gradientColors!,
            startAngle: startRad,
            endAngle: endRad,
          ).createShader(rect);
        } catch (e) {
          // Fallback to solid color if gradient creation fails
          progressPaint.color = foregroundColor;
        }
      } else {
        // Fallback to solid color if angles are invalid
        progressPaint.color = foregroundColor;
      }
    } else {
      progressPaint.color = foregroundColor;
    }

    canvas.drawArc(
      rect,
      startRad,
      progressSweepRad,
      arcFromCenter,
      progressPaint,
    );

    // Border
    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;

      final borderRadius = radius + strokeWidth / 2 + borderWidth / 2;
      // Ensure border radius is valid
      if (borderRadius.isFinite && borderRadius > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: borderRadius),
          startRad,
          totalSweepRad,
          false,
          borderPaint,
        );
      }
    }
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant AdvancedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}

// ================================================================
// FILE: lib/features/competition/common/competition_animations.dart
// Animation controllers, mixins, and wrappers
// ================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ================================================================
// ANIMATION DURATIONS
// ================================================================
class AnimationDurations {
  static const Duration screenEntry = Duration(milliseconds: 1000);
  static const Duration cardEntry = Duration(milliseconds: 600);
  static const Duration barGrowth = Duration(milliseconds: 1500);
  static const Duration pulse = Duration(milliseconds: 1500);
  static const Duration float = Duration(milliseconds: 2500);
  static const Duration glow = Duration(milliseconds: 1500);
  static const Duration shimmer = Duration(milliseconds: 2000);
  static const Duration count = Duration(milliseconds: 1200);
}

// ================================================================
// ANIMATION CURVES
// ================================================================
class AnimationCurves {
  static const Curve entry = Curves.easeOutCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve smooth = Curves.easeInOut;
  static const Curve spring = Curves.easeOutBack;
}

// ================================================================
// ANIMATION INTERVALS
// ================================================================
class AnimationIntervals {
  static Interval getBarInterval(int index) {
    final start = 0.0 + (index * 0.1);
    final end = 0.5 + (index * 0.1);
    return Interval(
      start.clamp(0.0, 0.5),
      end.clamp(0.5, 1.0),
      curve: Curves.easeOutCubic,
    );
  }

  static Interval getCardInterval(int index) {
    final start = (index * 0.15).clamp(0, 0.5);
    final end = (start + 0.5).clamp(0.5, 1.0);
    return Interval(
      start.toDouble(),
      end.toDouble(),
      curve: Curves.easeOutCubic,
    );
  }

  static Interval getAvatarInterval(int index) {
    final start = index * 0.1;
    final end = 0.6 + (index * 0.1);
    return Interval(
      start.clamp(0.0, 0.4),
      end.clamp(0.5, 1.0),
      curve: Curves.elasticOut,
    );
  }
}

// ================================================================
// COMPETITION ANIMATION MIXIN
// ================================================================
mixin CompetitionAnimationMixin<T extends StatefulWidget>
on TickerProviderStateMixin<T> {
  late AnimationController entryController;
  late AnimationController pulseController;
  late AnimationController floatController;
  late AnimationController glowController;
  late AnimationController shimmerController;
  late Animation<double> fadeAnimation;
  late Animation<double> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> floatAnimation;
  late Animation<double> glowAnimation;
  late Animation<double> shimmerAnimation;

  double get fadeIn => fadeAnimation.value;
  double get slideUp => slideAnimation.value;
  double get scale => scaleAnimation.value;
  double get float => floatAnimation.value;
  double get pulse => pulseAnimation.value;
  double get glow => glowAnimation.value;
  double get shimmer => shimmerAnimation.value;

  Listenable get entryAnimationsListenable => entryController;
  Listenable get pulseAnimationsListenable => pulseController;
  Listenable get floatAnimationsListenable => floatController;
  Listenable get glowAnimationsListenable => glowController;

  void initCompetitionAnimations({
    bool enableFade = true,
    bool enableSlide = true,
    bool enableScale = false,
    bool enablePulse = false,
    bool enableFloat = false,
    bool enableGlow = false,
    bool enableShimmer = false,
  }) {
    entryController = AnimationController(
      duration: AnimationDurations.screenEntry,
      vsync: this,
    );

    pulseController = AnimationController(
      duration: AnimationDurations.pulse,
      vsync: this,
    );

    floatController = AnimationController(
      duration: AnimationDurations.float,
      vsync: this,
    );

    glowController = AnimationController(
      duration: AnimationDurations.glow,
      vsync: this,
    );

    shimmerController = AnimationController(
      duration: AnimationDurations.shimmer,
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeOut),
    );

    slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeOutCubic),
    );

    scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeOutBack),
    );

    pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );

    glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: glowController, curve: Curves.easeInOut),
    );

    shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: shimmerController, curve: Curves.linear),
    );

    if (enableFade || enableSlide || enableScale) entryController.forward();
    if (enablePulse) pulseController.repeat(reverse: true);
    if (enableFloat) floatController.repeat(reverse: true);
    if (enableGlow) glowController.repeat(reverse: true);
    if (enableShimmer) shimmerController.repeat();
  }

  void disposeCompetitionAnimations() {
    entryController.dispose();
    pulseController.dispose();
    floatController.dispose();
    glowController.dispose();
    shimmerController.dispose();
  }
}

// ================================================================
// ENTRY ANIMATION WRAPPER
// ================================================================
class EntryAnimationWrapper extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final bool fade;
  final bool slide;
  final bool scale;
  final Duration duration;

  const EntryAnimationWrapper({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.fade = true,
    this.slide = true,
    this.scale = false,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<EntryAnimationWrapper> createState() => _EntryAnimationWrapperState();
}

class _EntryAnimationWrapperState extends State<EntryAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    final delay = widget.delay + Duration(milliseconds: 100 * widget.index);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget transformed = widget.child;

        if (widget.fade) {
          transformed = Opacity(opacity: _fadeAnimation.value, child: transformed);
        }

        if (widget.slide) {
          transformed = Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: transformed,
          );
        }

        if (widget.scale) {
          transformed = Transform.scale(scale: _scaleAnimation.value, child: transformed);
        }

        return transformed;
      },
    );
  }
}

// ================================================================
// PULSE ANIMATION WRAPPER
// ================================================================
class PulseAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulseAnimationWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.minScale = 1.0,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseAnimationWrapper> createState() => _PulseAnimationWrapperState();
}

class _PulseAnimationWrapperState extends State<PulseAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}

// ================================================================
// FLOAT ANIMATION WRAPPER
// ================================================================
class FloatAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double offset;
  final Duration duration;

  const FloatAnimationWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.offset = 10,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<FloatAnimationWrapper> createState() => _FloatAnimationWrapperState();
}

class _FloatAnimationWrapperState extends State<FloatAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: -widget.offset, end: widget.offset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// ================================================================
// GLOW ANIMATION WRAPPER
// ================================================================
class GlowAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Color glowColor;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const GlowAnimationWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    required this.glowColor,
    this.minOpacity = 0.2,
    this.maxOpacity = 0.6,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<GlowAnimationWrapper> createState() => _GlowAnimationWrapperState();
}

class _GlowAnimationWrapperState extends State<GlowAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(_animation.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

// ================================================================
// STAGGERED ANIMATION BUILDER
// ================================================================
class StaggeredAnimationBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration itemDelay;
  final Duration totalDuration;
  final Curve curve;

  const StaggeredAnimationBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDelay = const Duration(milliseconds: 100),
    this.totalDuration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: totalDuration,
      curve: curve,
      builder: (context, progress, child) {
        return Column(
          children: List.generate(itemCount, (index) {
            final itemProgress = (progress - (index * 0.1)).clamp(0.0, 1.0);
            return Opacity(
              opacity: itemProgress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - itemProgress)),
                child: itemBuilder(context, index),
              ),
            );
          }),
        );
      },
    );
  }
}

// ================================================================
// COUNT ANIMATION
// ================================================================
class CountAnimation extends StatefulWidget {
  final int targetValue;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String Function(int value)? format;

  const CountAnimation({
    super.key,
    required this.targetValue,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.format,
  });

  @override
  State<CountAnimation> createState() => _CountAnimationState();
}

class _CountAnimationState extends State<CountAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addListener(_updateValue);
    _controller.forward();
  }

  void _updateValue() {
    setState(() {
      _currentValue = (widget.targetValue * _animation.value).round();
    });
  }

  @override
  void didUpdateWidget(CountAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValue);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.format?.call(_currentValue) ?? _currentValue.toString();
    return Text(text, style: widget.style);
  }
}

// ================================================================
// SHAKE ANIMATION
// ================================================================
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double offset;
  final int shakeCount;
  final Duration duration;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.enabled = true,
    this.offset = 10,
    this.shakeCount = 3,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
  }

  void shake() {
    if (widget.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: shake,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final sineValue = math.sin(
            widget.shakeCount * 2 * math.pi * _controller.value,
          );
          return Transform.translate(
            offset: Offset(sineValue * widget.offset, 0),
            child: widget.child,
          );
        },
      ),
    );
  }
}
// ================================================================
// FILE: lib/features/chat/widgets/common/typing_dots_animation.dart
// PURPOSE: Animated typing indicator with bouncing dots
// STYLE: WhatsApp-style 3 bouncing dots
// DEPENDENCIES: None - Pure widget
// ================================================================

import 'package:flutter/material.dart';

enum TypingDotsStyle {
  bounce, // WhatsApp style - dots bounce up and down
  pulse, // Fade in/out
  wave, // Sine wave animation
  scale, // Scale up/down
}

class TypingDotsAnimation extends StatefulWidget {
  final int dotCount;
  final TypingDotsStyle style;
  final Color? color;
  final double dotSize;
  final double spacing;
  final Duration duration;
  final Duration staggerDelay;
  final bool repeat;

  const TypingDotsAnimation({
    super.key,
    this.dotCount = 3,
    this.style = TypingDotsStyle.bounce,
    this.color,
    this.dotSize = 8,
    this.spacing = 4,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 150),
    this.repeat = true,
  });

  // WhatsApp style (default)
  const TypingDotsAnimation.whatsapp({
    super.key,
    this.color,
    this.dotSize = 8,
    this.spacing = 4,
  }) : dotCount = 3,
       style = TypingDotsStyle.bounce,
       duration = const Duration(milliseconds: 600),
       staggerDelay = const Duration(milliseconds: 150),
       repeat = true;

  // iMessage style
  const TypingDotsAnimation.imessage({
    super.key,
    this.color,
    this.dotSize = 6,
    this.spacing = 3,
  }) : dotCount = 3,
       style = TypingDotsStyle.pulse,
       duration = const Duration(milliseconds: 800),
       staggerDelay = const Duration(milliseconds: 200),
       repeat = true;

  @override
  State<TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<TypingDotsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.asMap().entries.map((entry) {
      final controller = entry.value;
      return _createAnimation(controller);
    }).toList();
  }

  Animation<double> _createAnimation(AnimationController controller) {
    switch (widget.style) {
      case TypingDotsStyle.bounce:
        return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutQuad),
        );
      case TypingDotsStyle.pulse:
        return Tween<double>(
          begin: 0.3,
          end: 1,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      case TypingDotsStyle.wave:
        return Tween<double>(begin: 0, end: 2 * 3.14159).animate(controller);
      case TypingDotsStyle.scale:
        return Tween<double>(
          begin: 0.6,
          end: 1.2,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }
  }

  void _startAnimations() async {
    if (!widget.repeat) {
      for (int i = 0; i < widget.dotCount; i++) {
        await Future.delayed(widget.staggerDelay * i);
        if (mounted) _controllers[i].forward();
      }
      return;
    }

    _animateLoop();
  }

  void _animateLoop() async {
    while (mounted && _isAnimating) {
      // Forward animation with stagger
      for (int i = 0; i < widget.dotCount; i++) {
        if (!mounted || !_isAnimating) return;
        _controllers[i].forward();
        await Future.delayed(widget.staggerDelay);
      }

      // Wait at peak
      await Future.delayed(const Duration(milliseconds: 100));

      // Reverse animation
      for (int i = 0; i < widget.dotCount; i++) {
        if (!mounted || !_isAnimating) return;
        _controllers[i].reverse();
        await Future.delayed(widget.staggerDelay);
      }

      // Pause before next cycle
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _isAnimating = false;
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        if (index > 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: widget.spacing),
              _buildDot(index, effectiveColor),
            ],
          );
        }
        return _buildDot(index, effectiveColor);
      }),
    );
  }

  Widget _buildDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: _getOffset(index),
          child: Transform.scale(
            scale: _getScale(index),
            child: Opacity(
              opacity: _getOpacity(index),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _getOffset(int index) {
    final value = _animations[index].value;
    switch (widget.style) {
      case TypingDotsStyle.bounce:
        return Offset(0, -widget.dotSize * value);
      case TypingDotsStyle.wave:
        return Offset(0, 4 * value.sign);
      default:
        return Offset.zero;
    }
  }

  double _getScale(int index) {
    final value = _animations[index].value;
    switch (widget.style) {
      case TypingDotsStyle.scale:
        return value;
      default:
        return 1.0;
    }
  }

  double _getOpacity(int index) {
    final value = _animations[index].value;
    switch (widget.style) {
      case TypingDotsStyle.pulse:
        return value;
      default:
        return 1.0;
    }
  }
}

// ================================================================
// TYPING BUBBLE - Message bubble with typing indicator
// ================================================================

class TypingBubble extends StatelessWidget {
  final String? senderName;
  final String? senderAvatar;
  final Color? bubbleColor;
  final Color? dotsColor;
  final TypingDotsStyle dotsStyle;
  final bool showAvatar;
  final double avatarSize;

  const TypingBubble({
    super.key,
    this.senderName,
    this.senderAvatar,
    this.bubbleColor,
    this.dotsColor,
    this.dotsStyle = TypingDotsStyle.bounce,
    this.showAvatar = true,
    this.avatarSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar) ...[
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: senderAvatar != null
                  ? Image.network(
                      senderAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: avatarSize * 0.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: avatarSize * 0.6,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    senderName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor ?? colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: TypingDotsAnimation(
                  style: dotsStyle,
                  color: dotsColor ?? colorScheme.onSurfaceVariant,
                  dotSize: 8,
                  spacing: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// TYPING INDICATOR BAR - For app bar subtitle
// ================================================================

class TypingIndicatorBar extends StatelessWidget {
  final List<String> typingUserNames;
  final TextStyle? style;
  final Color? dotsColor;
  final bool showDots;

  const TypingIndicatorBar({
    super.key,
    required this.typingUserNames,
    this.style,
    this.dotsColor,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (typingUserNames.isEmpty) return const SizedBox.shrink();

    final textStyle =
        style ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontStyle: FontStyle.italic,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDots) ...[
          const TypingDotsAnimation.whatsapp(dotSize: 6, spacing: 2),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            _getTypingText(),
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTypingText() {
    if (typingUserNames.isEmpty) return '';

    if (typingUserNames.length == 1) {
      return '${typingUserNames[0]} is typing';
    }

    if (typingUserNames.length == 2) {
      return '${typingUserNames[0]} and ${typingUserNames[1]} are typing';
    }

    return '${typingUserNames[0]} and ${typingUserNames.length - 1} others are typing';
  }
}

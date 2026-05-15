// ================================================================
// FILE: lib/features/chat/widgets/input/chat_emoji_button.dart
// PURPOSE: Emoji button that opens emoji picker
// STYLE: WhatsApp-style smiley face
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatEmojiButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const ChatEmojiButton({super.key, required this.onPressed, this.size = 44});

  @override
  State<ChatEmojiButton> createState() => _ChatEmojiButtonState();
}

class _ChatEmojiButtonState extends State<ChatEmojiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(
                Icons.emoji_emotions_outlined,
                color: colorScheme.onSurfaceVariant,
                size: widget.size * 0.6,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    HapticFeedback.lightImpact();
    widget.onPressed();
  }
}

/// Extended emoji button with animated face
class AnimatedEmojiButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const AnimatedEmojiButton({
    super.key,
    required this.onPressed,
    this.size = 44,
  });

  @override
  State<AnimatedEmojiButton> createState() => _AnimatedEmojiButtonState();
}

class _AnimatedEmojiButtonState extends State<AnimatedEmojiButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_emotions_rounded,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// FILE: lib/features/chat/widgets/input/chat_attachment_button.dart
// PURPOSE: Attachment button that opens media picker
// STYLE: WhatsApp-style plus button
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatAttachmentButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;

  const ChatAttachmentButton({
    super.key,
    required this.onPressed,
    this.size = 44,
  });

  @override
  State<ChatAttachmentButton> createState() => _ChatAttachmentButtonState();
}

class _ChatAttachmentButtonState extends State<ChatAttachmentButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: widget.size * 0.7,
                ),
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

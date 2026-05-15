// ================================================================
// FILE: lib/features/chat/widgets/input/chat_send_button.dart
// PURPOSE: Send button that toggles to voice recording on long press
// STYLE: WhatsApp + Snapchat hybrid
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatSendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isRecording;
  final bool canSend;
  final bool showMic;
  final VoidCallback? onLongPress;
  final Function(LongPressStartDetails)? onLongPressStart;
  final Function(LongPressMoveUpdateDetails)? onLongPressMoveUpdate;
  final Function(LongPressEndDetails)? onLongPressEnd;
  final double size;

  const ChatSendButton({
    super.key,
    required this.onPressed,
    required this.isRecording,
    required this.canSend,
    required this.showMic,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.size = 44,
  });

  @override
  State<ChatSendButton> createState() => _ChatSendButtonState();
}

class _ChatSendButtonState extends State<ChatSendButton>
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
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
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

    final icon = widget.isRecording
        ? Icons.stop_rounded
        : (widget.canSend
              ? Icons.send_rounded
              : (widget.showMic ? Icons.mic_rounded : Icons.send_rounded));

    final bgColor = widget.isRecording
        ? Colors.red
        : (widget.canSend
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest);

    final fgColor = widget.isRecording
        ? Colors.white
        : (widget.canSend
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTap: widget.canSend || widget.isRecording ? _onTap : null,
      onLongPress: widget.showMic && !widget.canSend && !widget.isRecording
          ? widget.onLongPress
          : null,
      onLongPressStart: widget.showMic && !widget.canSend && !widget.isRecording
          ? widget.onLongPressStart
          : null,
      onLongPressMoveUpdate:
          widget.showMic && !widget.canSend && !widget.isRecording
          ? widget.onLongPressMoveUpdate
          : null,
      onLongPressEnd: widget.showMic && !widget.canSend && !widget.isRecording
          ? widget.onLongPressEnd
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (widget.canSend || widget.isRecording)
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Icon(icon, color: fgColor, size: widget.size * 0.5),
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

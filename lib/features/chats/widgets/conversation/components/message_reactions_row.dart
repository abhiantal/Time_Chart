// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_reactions_row.dart
// PURPOSE: Display emoji reactions on messages
// STYLE: WhatsApp reaction bubbles style
// DEPENDENCIES: message_reactions.dart model
// ================================================================

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../model/chat_message_model.dart';
import '../../../providers/chat_message_provider.dart';

class MessageReactionsRow extends StatelessWidget {
  final MessageReactions reactions;
  final String messageId;
  final bool isMe;

  const MessageReactionsRow({
    super.key,
    required this.reactions,
    required this.messageId,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final reactionsList = reactions.raw.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...reactionsList.take(3).map((entry) {
            return _ReactionChip(
              emoji: entry.key,
              count: entry.value.length,
              messageId: messageId,
              isMe: isMe,
              reactions: reactions,
            );
          }),
          if (reactionsList.length > 3)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${reactionsList.length - 3}',
                style: TextStyle(
                  color: isMe
                      ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatefulWidget {
  final String emoji;
  final int count;
  final String messageId;
  final bool isMe;

  final MessageReactions reactions;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.messageId,
    required this.isMe,
    required this.reactions,
  });

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ChatMessageProvider>();
    final hasReacted =
        provider.currentUserId != null &&
        widget.reactions.hasUserReacted(widget.emoji, provider.currentUserId!);

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
        _controller.reverse();
        setState(() => _isPressed = false);
        provider.toggleReaction(widget.messageId, widget.emoji);
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(right: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasReacted
                    ? (widget.isMe
                          ? Colors.white.withValues(alpha: 0.2)
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 14)),
                  if (widget.count > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${widget.count}',
                      style: TextStyle(
                        color: widget.isMe
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.9)
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

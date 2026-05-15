// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/deleted_message_bubble.dart
// PURPOSE: Deleted message placeholder bubble
// STYLE: WhatsApp deleted message style
// DEPENDENCIES: message_bubble_base.dart
// ================================================================

import 'package:flutter/material.dart';

import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';

class DeletedMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String? senderName;
  final String? senderAvatar;

  const DeletedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      showReactions: false,
      showStatus: false,
      showName: !isMe && senderName != null,
      showAvatar: !isMe && senderName != null,
      senderName: senderName,
      senderAvatar: senderAvatar,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 16,
            color: isMe
                ? (theme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black45)
                : (theme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black45),
          ),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: TextStyle(
              color: isMe
                  ? (theme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black45)
                  : (theme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black45),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

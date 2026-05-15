// ================================================================
// FILE: lib/features/chat/widgets/input/chat_reply_bar.dart
// PURPOSE: Reply/Edit preview bar shown above chat input
// STYLE: WhatsApp-style reply bar with close button
// DEPENDENCIES: chat_message_model.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/chat_message_model.dart';
import '../../utils/chat_text_utils.dart';

class ChatReplyBar extends StatelessWidget {
  final ChatMessageModel actionMessage;
  final bool isEditing;
  final VoidCallback onCancel;

  const ChatReplyBar({
    super.key,
    required this.actionMessage,
    required this.isEditing,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          bottom: BorderSide(
            color: isEditing
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.1),
            width: isEditing ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEditing
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.reply_rounded,
              color: isEditing
                  ? colorScheme.primary
                  : colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Editing message' : _getReplySender(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isEditing
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPreviewText(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isEditing
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onCancel();
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  String _getReplySender() {
    if (actionMessage.senderId == 'current_user') {
      return 'Replying to yourself';
    }
    return 'Replying to ${_getSenderName()}';
  }

  String _getSenderName() {
    // TODO: Get sender name from provider
    return actionMessage.senderId.substring(0, 6);
  }

  String _getPreviewText() {
    if (actionMessage.isDeleted) {
      return 'This message was deleted';
    }

    if (actionMessage.isMediaMessage) {
      switch (actionMessage.type) {
        case ChatMessageType.image:
          return '📷 Photo';
        case ChatMessageType.video:
          return '🎥 Video';
        case ChatMessageType.audio:
          return '🎵 Audio';
        case ChatMessageType.voice:
          return '🎤 Voice message';
        case ChatMessageType.document:
          return '📄 Document';
        default:
          return 'Media';
      }
    }

    if (actionMessage.isSharedContent) {
      return '📋 Shared content';
    }

    if (actionMessage.textContent != null) {
      return ChatTextUtils.generatePreview(
        actionMessage.textContent!,
        maxLength: 80,
      );
    }

    return 'Message';
  }
}

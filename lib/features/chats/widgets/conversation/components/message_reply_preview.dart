// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_reply_preview.dart
// PURPOSE: Reply preview bar shown in message bubble when replying
// STYLE: WhatsApp reply preview style
// DEPENDENCIES: chat_message_model.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/chat_message_model.dart';
import '../../../providers/chat_message_provider.dart';
import '../../../utils/chat_text_utils.dart';

class MessageReplyPreview extends StatelessWidget {
  final String replyToId;
  final bool isMe;
  final bool revamped;

  const MessageReplyPreview({
    super.key,
    required this.replyToId,
    required this.isMe,
    this.revamped = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ChatMessageProvider>();

    final originalMessage = provider.messages.where((m) => m.id == replyToId).firstOrNull;

    if (originalMessage == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.onPrimary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: revamped
              ? Border.all(
                  color: isMe
                      ? colorScheme.onPrimary.withValues(alpha: 0.3)
                      : colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.reply_rounded,
              size: 14,
              color: isMe
                  ? colorScheme.onPrimary.withValues(alpha: 0.6)
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Original message deleted',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isMe
                      ? colorScheme.onPrimary.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isOriginalMe = originalMessage.senderId == provider.currentUserId;
    final senderName = isOriginalMe
        ? 'You'
        : _getSenderName(provider, originalMessage.senderId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.onPrimary.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? colorScheme.onPrimary : colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isMe ? colorScheme.onPrimary : colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getPreviewText(originalMessage),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMe
                  ? colorScheme.onPrimary.withValues(alpha: 0.8)
                  : colorScheme.onSurface,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSenderName(ChatMessageProvider provider, String senderId) {
    final member = provider.members.where((m) => m.userId == senderId).firstOrNull;
    if (member != null) {
      return member.settings.customTitle ?? member.fullName ?? member.username ?? 'User';
    }
    return 'User';
  }

  String _getPreviewText(ChatMessageModel message) {
    if (message.isDeleted) {
      return 'This message was deleted';
    }

    if (message.isMediaMessage) {
      switch (message.type) {
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

    if (message.isSharedContent) {
      return '📋 Shared content';
    }

    if (message.textContent != null) {
      return ChatTextUtils.generatePreview(message.textContent!, maxLength: 80);
    }

    return 'Message';
  }
}

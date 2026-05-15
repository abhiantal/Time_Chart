// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/text_message_bubble.dart
// PURPOSE: Text message bubble with links, mentions, and reactions
// STYLE: WhatsApp style with tail and reactions
// DEPENDENCIES: message_bubble_base.dart, chat_text_utils.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/chat_message_model.dart';
import '../../../utils/chat_text_utils.dart';
import '../components/message_forward_label.dart';
import 'message_bubble_base.dart';
import '../components/message_reply_preview.dart';

class TextMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;

  const TextMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onDoubleTap,
    this.senderName,
    this.senderAvatar,
    this.showName = false,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview (if replying to another message)
          if (message.replyToId != null)
            MessageReplyPreview(replyToId: message.replyToId!, isMe: isMe),

          // Forward label (if forwarded)
          if (message.isForwarded)
            MessageForwardLabel(isMe: isMe, forwardCount: message.forwardCount),

          // Message text with links and mentions
          ChatTextUtils.buildRichText(
            context,
            message.textContent ?? '',
            isMe: isMe,
            onMentionTap: (userId) {
              // TODO: Navigate to user profile
              HapticFeedback.lightImpact();
            },
            onLinkTap: (url) async {
              HapticFeedback.lightImpact();
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}

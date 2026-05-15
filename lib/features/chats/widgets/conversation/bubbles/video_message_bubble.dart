// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/video_message_bubble.dart
// PURPOSE: Video message bubble with thumbnail and player
// STYLE: WhatsApp style
// ================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../../../model/chat_attachment_model.dart';
import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';
import '../components/message_forward_label.dart';
import '../components/message_reply_preview.dart';
import '../../../../../media_utility/media_display.dart';

class VideoMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;
  final ChatMessageAttachmentModel attachment;

  const VideoMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.senderName,
    this.senderAvatar,
    this.showName = false,
    this.showAvatar = false,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCaption = message.textContent?.isNotEmpty ?? false;

    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      isMedia: !hasCaption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyToId != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MessageReplyPreview(
                replyToId: message.replyToId!,
                isMe: isMe,
              ),
            ),

          if (message.isForwarded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: MessageForwardLabel(
                isMe: isMe,
                forwardCount: message.forwardCount,
              ),
            ),

          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(!isMe ? 2 : 12),
              bottomRight: Radius.circular(isMe ? 2 : 12),
            ),
            child: EnhancedMediaDisplay(
              mediaFiles: [attachment.toEnhancedMediaFile()],
              config: const MediaDisplayConfig(
                layoutMode: MediaLayoutMode.single,
                mediaBucket: MediaBucket.chatMedia,
                borderRadius: 0,
                allowDelete: false,
                allowFullScreen: true,
                imageFit: BoxFit.cover,
                autoPlay: false,
              ),
            ),
          ),

          if (hasCaption)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                message.textContent!,
                style: TextStyle(
                  color: (theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

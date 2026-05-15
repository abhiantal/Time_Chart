// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/image_message_bubble.dart
// PURPOSE: Image message bubble with thumbnail, grid layout, full-screen viewer
// STYLE: WhatsApp style with image grid
// DEPENDENCIES: message_bubble_base.dart, media_display.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';

import '../../../../../media_utility/media_display.dart';
import '../../../model/chat_attachment_model.dart';
import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';
import '../components/message_forward_label.dart';
import '../components/message_reply_preview.dart';

class ImageMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;
  final List<ChatMessageAttachmentModel> attachments;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onDoubleTap,
    this.senderName,
    this.senderAvatar,
    this.showName = false,
    this.showAvatar = false,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCaption = message.textContent?.isNotEmpty ?? false;

    // Convert attachments to EnhancedMediaFile
    final mediaFiles = attachments
        .map((att) => att.toEnhancedMediaFile())
        .toList();

    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      isMedia: !hasCaption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (message.replyToId != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MessageReplyPreview(
                replyToId: message.replyToId!,
                isMe: isMe,
              ),
            ),

          // Forward label
          if (message.isForwarded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: MessageForwardLabel(
                isMe: isMe,
                forwardCount: message.forwardCount,
              ),
            ),

          // Media Display
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(!isMe ? 2 : 12),
              bottomRight: Radius.circular(isMe ? 2 : 12),
            ),
            child: EnhancedMediaDisplay(
              mediaFiles: mediaFiles,
              config: MediaDisplayConfig(
                layoutMode: mediaFiles.length == 1
                    ? MediaLayoutMode.single
                    : MediaLayoutMode.grid,
                gridColumns: mediaFiles.length >= 4
                    ? 2
                    : (mediaFiles.length > 1 ? 2 : 1),
                mediaBucket: MediaBucket.chatMedia,
                borderRadius: 0,
                allowDelete: false,
                allowFullScreen: true,
                imageFit: BoxFit.cover,
              ),
            ),
          ),

          // Caption
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

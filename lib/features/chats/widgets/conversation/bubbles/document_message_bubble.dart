// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/document_message_bubble.dart
// PURPOSE: Document message bubble with file icon, name, size
// STYLE: WhatsApp style
// ================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../../../model/chat_attachment_model.dart';
import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';
import '../../../../../media_utility/media_display.dart';

class DocumentMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;
  final ChatMessageAttachmentModel attachment;

  const DocumentMessageBubble({
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
    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: EnhancedMediaDisplay(
          mediaFiles: [attachment.toEnhancedMediaFile()],
          config: const MediaDisplayConfig(
            layoutMode: MediaLayoutMode.single,
            mediaBucket: MediaBucket.chatMedia,
            borderRadius: 12,
            allowDelete: false,
            allowFullScreen: false,
          ),
        ),
      ),
    );
  }
}

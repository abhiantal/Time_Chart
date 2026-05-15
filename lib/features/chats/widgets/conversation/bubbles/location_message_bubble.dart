// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/location_message_bubble.dart
// PURPOSE: Location message bubble with map preview
// STYLE: WhatsApp style
// ================================================================

import 'package:flutter/material.dart';
import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';

class LocationMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final String? senderName;
  final String? senderAvatar;

  const LocationMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      showName: !isMe && senderName != null,
      showAvatar: !isMe && senderName != null,
      senderName: senderName,
      senderAvatar: senderAvatar,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Icon(Icons.map_rounded, size: 48, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.locationName ?? 'Location',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (message.locationAddress != null)
                  Text(
                    message.locationAddress!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

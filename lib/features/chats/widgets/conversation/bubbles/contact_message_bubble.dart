// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/contact_message_bubble.dart
// PURPOSE: Contact message bubble with avatar, name, phone
// STYLE: WhatsApp style
// ================================================================

import 'package:flutter/material.dart';
import '../../../model/chat_message_model.dart';
import 'message_bubble_base.dart';

class ContactMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final String? senderName;
  final String? senderAvatar;

  const ContactMessageBubble({
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person_rounded, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.contactName ?? 'Contact',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (message.contactPhone != null)
                Text(
                  message.contactPhone!,
                  style: TextStyle(
                    fontSize: 12,
                    color: (isMe ? Colors.white70 : Colors.black54).withValues(alpha: 
                      0.7,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

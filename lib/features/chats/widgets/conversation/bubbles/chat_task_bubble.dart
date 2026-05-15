// ================================================================
// FILE: lib/features/chats/widgets/shared_content/bubbles/chat_task_bubble.dart
// PURPOSE: Message bubble for tasks created directly in chat
// STYLE: Premium task card with status and due date
// ================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'message_bubble_base.dart';
import '../../../utils/chat_text_utils.dart';

class ChatTaskBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final String? senderName;
  final String? senderAvatar;
  final bool showName;
  final bool showAvatar;

  const ChatTaskBubble({
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
    final snapshot = message.sharedContentSnapshot ?? {};
    final title = snapshot['title'] ?? 'Task';
    final description = snapshot['description'] ?? '';
    final dueDateStr = snapshot['due_date'] as String?;
    final status = snapshot['status'] ?? 'pending';

    DateTime? dueDate;
    if (dueDateStr != null) {
      dueDate = DateTime.tryParse(dueDateStr);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MessageBubbleBase(
      message: message,
      isMe: isMe,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      showName: showName,
      showAvatar: showAvatar,
      senderName: senderName,
      senderAvatar: senderAvatar,
      padding: EdgeInsets.zero,
      sentColor: Colors.transparent,
      receivedColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [
                    const Color(0xFF00A884).withValues(alpha: 0.9),
                    const Color(0xFF008E6E).withValues(alpha: 0.7),
                  ]
                : [
                    isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isMe ? Colors.white : colorScheme.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        color: isMe ? Colors.white : colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW TASK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: (isMe ? Colors.white : colorScheme.primary)
                                  .withValues(alpha: 0.9),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: (isMe ? Colors.white : colorScheme.primary)
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ChatTextUtils.cleanMentions(title),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isMe ? Colors.white : colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ChatTextUtils.cleanMentions(description),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (isMe ? Colors.white : colorScheme.onSurface)
                              .withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Opacity(
                  opacity: 0.1,
                  child: Divider(height: 1, color: Colors.white),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 14,
                      color: (isMe ? Colors.white : colorScheme.onSurface)
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dueDate != null
                          ? DateFormat('MMM dd, hh:mm a').format(dueDate)
                          : 'No due date',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: (isMe ? Colors.white : colorScheme.onSurface)
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        'View Task',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe ? Colors.white : colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

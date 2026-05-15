// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/message_bubble_base.dart
// PURPOSE: Base widget for all message bubbles with tail, reactions, status
// STYLE: Premium WhatsApp style with doodle background support
// ================================================================

import 'package:flutter/material.dart';
import '../../common/user_avatar_cached.dart';
import '../../../model/chat_message_model.dart';
import '../components/message_status_ticks.dart' as ticks;
import '../components/message_reactions_row.dart';

enum BubbleStyle {
  whatsapp, // Classic rounded with tail
  modern, // Smooth corners, no tail
  ios, // iOS style with smooth tail
}

class MessageBubbleBase extends StatelessWidget {
  final Widget child;
  final ChatMessageModel message;
  final bool isMe;
  final BubbleStyle style;
  final bool showTail;
  final bool showReactions;
  final bool showStatus;
  final bool showTime;
  final bool showName;
  final bool showAvatar;
  final String? senderName;
  final String? senderAvatar;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final EdgeInsetsGeometry? padding;
  final Color? sentColor;
  final Color? receivedColor;
  final double borderRadius;
  final double tailSize;
  final bool isMedia;

  const MessageBubbleBase({
    super.key,
    required this.child,
    required this.message,
    required this.isMe,
    this.style = BubbleStyle.whatsapp,
    this.showTail = true,
    this.showReactions = true,
    this.showStatus = true,
    this.showTime = true,
    this.showName = false,
    this.showAvatar = false,
    this.senderName,
    this.senderAvatar,
    this.onLongPress,
    this.onDoubleTap,
    this.padding,
    this.sentColor,
    this.receivedColor,
    this.borderRadius = 16,
    this.tailSize = 6,
    this.isMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Placeholder for UI preferences until merged into ChatProvider
    final currentStyle = style;
    final defaultSentColor = sentColor ?? (isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3));
    final defaultReceivedColor = receivedColor ?? (isDark ? const Color(0xFF202C33) : Colors.white);

    final onSentColor = isDark ? Colors.white : const Color(0xFF111B21);
    final onReceivedColor = isDark ? Colors.white : const Color(0xFF111B21);

    BorderRadius currentRadius = _getBorderRadius(currentStyle);
    if (padding == EdgeInsets.zero && isMedia) {
      currentRadius = BorderRadius.circular(
        18,
      ); // smooth edge zero-pad media render
    }

    // Bubble content wrapper
    Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth:
            MediaQuery.of(context).size.width *
            (isMedia
                ? 0.89
                : 0.78), // Give larger width for media and custom cards
      ),
      decoration: BoxDecoration(
        color: isMe ? defaultSentColor : defaultReceivedColor,
        borderRadius: currentRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 1.2,
            offset: const Offset(0, 1.2),
          ),
        ],
      ),
      child: Padding(
        padding:
            padding ??
            (isMedia
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                // Allow space for time at bottom so it doesn't overlap
                bottom: (showTime || (showStatus && isMe)) && !isMedia ? 4 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender Name (for Groups/Communities)
                  if (showName && senderName != null && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 12,
                        bottom: 3,
                        right: 30,
                      ),
                      child: Text(
                        senderName!,
                        style: TextStyle(
                          color: _getSenderColor(senderName!),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Main content
                  child,

                  // Extra space for timestamp if content is small
                  if ((showTime || (showStatus && isMe)) && !isMedia)
                    const SizedBox(
                      height: 16,
                      width: 70,
                    ), // Added width to prevent overlap on short messages
                ],
              ),
            ),

            // Time and Status aligned to bottom right of the bubble
            if (showTime || (showStatus && isMe))
              Positioned(
                bottom: isMedia ? 6 : 0,
                right: isMedia ? 6 : 0,
                child: Container(
                  padding: isMedia
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
                      : EdgeInsets.zero,
                  decoration: isMedia
                      ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (message.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isMedia
                                  ? Colors.white70
                                  : (isMe ? onSentColor : onReceivedColor)
                                        .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      if (showTime)
                        Text(
                          _formatTime(message.sentAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isMedia
                                ? Colors.white.withValues(alpha: 0.9)
                                : (isMe ? onSentColor : onReceivedColor)
                                      .withValues(alpha: 0.55),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      if (showStatus && isMe) ...[
                        const SizedBox(width: 3.5),
                        ticks.MessageStatusTicks(
                          status: _mapMessageStatus(message.status),
                          size: 14,
                          color: isMedia
                              ? Colors.white
                              : onSentColor.withValues(alpha: 0.55),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Add tail if style is whatsapp
    if (showName && currentStyle == BubbleStyle.whatsapp) {
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            top: 0,
            left: isMe ? null : -tailSize + 1,
            right: isMe ? -tailSize + 1 : null,
            child: _buildTail(isMe ? defaultSentColor : defaultReceivedColor),
          ),
        ],
      );
    }

    // Wrap with Reactions
    if (showReactions && message.hasReactions) {
      bubble = Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          bubble,
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: MessageReactionsRow(
              reactions: message.reactions,
              messageId: message.id,
              isMe: isMe,
            ),
          ),
        ],
      );
    }

    // Full Row Content (Avatar + Bubble)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for every message
        children: [
          if (!isMe) ...[
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(top: 2), // Small offset from top
                child: UserAvatarCached(
                  imageUrl: senderAvatar,
                  name: senderName ?? '?',
                  size: 30,
                  isGroup: false,
                ),
              )
            else if (senderName != null)
              const SizedBox(width: 36),
            
            if (showAvatar || senderName != null)
              const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              onDoubleTap: onDoubleTap,
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _getBorderRadius(BubbleStyle currentStyle) {
    if (currentStyle != BubbleStyle.whatsapp) {
      return BorderRadius.circular(borderRadius);
    }

    // Only apply the "tail corner" logic if it's the first message in a group (showName = true)
    // For 1-on-1 chats, we might need a different heuristic if showName is always false.
    final bool useTailRadius = showName;

    if (!useTailRadius) {
      return BorderRadius.circular(borderRadius);
    }

    return BorderRadius.only(
      topLeft: Radius.circular(isMe ? borderRadius : 5),
      topRight: Radius.circular(isMe ? 5 : borderRadius),
      bottomLeft: Radius.circular(borderRadius),
      bottomRight: Radius.circular(borderRadius),
    );
  }

  Widget _buildTail(Color color) {
    return CustomPaint(
      size: Size(tailSize, tailSize + 2),
      painter: _WhatsAppTailPainter(isMe: isMe, color: color),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $ampm';
  }

  Color _getSenderColor(String name) {
    final colors = [
      const Color(0xFF1F6FEB), // Blue
      const Color(0xFFD97706), // Amber/Orange
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF0D9488), // Teal
      const Color(0xFFDB2777), // Pink
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF0891B2), // Cyan
      const Color(0xFF16A34A), // Green
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  ticks.MessageStatus _mapMessageStatus(dynamic chatMessageStatus) {
    // If it's already the right type, return it
    if (chatMessageStatus is ticks.MessageStatus) return chatMessageStatus;
    
    // If it's the model's MessageStatus, map it by name string to avoid enum collision
    final statusStr = chatMessageStatus.toString().split('.').last;
    return ticks.MessageStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => ticks.MessageStatus.sent,
    );
  }
}

class _WhatsAppTailPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  _WhatsAppTailPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppTailPainter oldDelegate) {
    return oldDelegate.isMe != isMe || oldDelegate.color != color;
  }
}

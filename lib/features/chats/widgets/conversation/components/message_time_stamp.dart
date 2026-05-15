// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_time_stamp.dart
// PURPOSE: Time stamp for message bubbles
// STYLE: 12/24 hour format, edited indicator
// DEPENDENCIES: chat_date_utils.dart
// ================================================================

import 'package:flutter/material.dart';
import '../../../utils/chat_date_utils.dart';

class MessageTimeStamp extends StatelessWidget {
  final DateTime dateTime;
  final bool isEdited;
  final Color? color;
  final double fontSize;
  final bool use24HourFormat;

  const MessageTimeStamp({
    super.key,
    required this.dateTime,
    this.isEdited = false,
    this.color,
    this.fontSize = 11,
    this.use24HourFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEdited) ...[
          Text(
            'edited ',
            style: TextStyle(
              color: color ?? Colors.grey[600],
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        Text(
          use24HourFormat
              ? ChatDateUtils.formatMessageTime24(dateTime)
              : ChatDateUtils.formatMessageTime(dateTime),
          style: TextStyle(
            color: color ?? Colors.grey[600],
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

/// Compact time stamp for chat list
class ChatListTimeStamp extends StatelessWidget {
  final DateTime? dateTime;
  final TextStyle? style;
  final bool compact;

  const ChatListTimeStamp({
    super.key,
    required this.dateTime,
    this.style,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dateTime == null) return const SizedBox.shrink();

    return Text(
      compact
          ? ChatDateUtils.formatChatListTimeCompact(dateTime!)
          : ChatDateUtils.formatChatListTime(dateTime!),
      style: style ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Relative time stamp (e.g., "2 min ago")
class RelativeTimeStamp extends StatelessWidget {
  final DateTime? dateTime;
  final TextStyle? style;
  final bool short;

  const RelativeTimeStamp({
    super.key,
    required this.dateTime,
    this.style,
    this.short = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dateTime == null) return const SizedBox.shrink();

    return Text(
      short
          ? ChatDateUtils.formatRelativeShort(dateTime!)
          : ChatDateUtils.formatRelativeTime(dateTime!),
      style: style ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Last seen timestamp for online status
class LastSeenTimeStamp extends StatelessWidget {
  final DateTime? lastSeen;
  final bool isOnline;
  final TextStyle? style;

  const LastSeenTimeStamp({
    super.key,
    this.lastSeen,
    this.isOnline = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      ChatDateUtils.formatLastSeen(lastSeen, isOnline: isOnline),
      style: style ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}

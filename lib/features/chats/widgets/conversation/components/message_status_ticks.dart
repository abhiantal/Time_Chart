// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_status_ticks.dart
// PURPOSE: WhatsApp-style message status indicators (ticks)
// STYLE: Single tick, double tick, blue double tick
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';

enum MessageStatus {
  sending, // Clock icon
  sent, // Single tick
  delivered, // Double tick (gray)
  read, // Double tick (blue)
  failed, // Error icon
}

class MessageStatusTicks extends StatelessWidget {
  final MessageStatus status;
  final double size;
  final Color? color;
  final Color? readColor;
  final bool animate;

  const MessageStatusTicks({
    super.key,
    required this.status,
    this.size = 16,
    this.color,
    this.readColor,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return _PendingIcon(
          size: size,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          animate: animate,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.done_rounded,
          size: size + 2,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case MessageStatus.delivered:
        return _DoubleCheckIcon(
          size: size,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case MessageStatus.read:
        return _DoubleCheckIcon(
          size: size,
          color: readColor ?? const Color(0xFF34B7F1), // WhatsApp blue
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline_rounded,
          size: size,
          color: Theme.of(context).colorScheme.error,
        );
    }
  }
}

class _PendingIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool animate;

  const _PendingIcon({
    required this.size,
    required this.color,
    required this.animate,
  });

  @override
  State<_PendingIcon> createState() => _PendingIconState();
}

class _PendingIconState extends State<_PendingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Icon(
        Icons.access_time_rounded,
        size: widget.size,
        color: widget.color,
      );
    }

    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.access_time_rounded,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

class _DoubleCheckIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _DoubleCheckIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.done_all_rounded, size: size + 2, color: color);
  }
}

/// Status with timestamp (for message bubble)
class MessageStatusWithTime extends StatelessWidget {
  final MessageStatus status;
  final String time;
  final bool isEdited;
  final Color? textColor;
  final double fontSize;

  const MessageStatusWithTime({
    super.key,
    required this.status,
    required this.time,
    this.isEdited = false,
    this.textColor,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = textColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isEdited) ...[
          Text(
            'edited',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          time,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
        const SizedBox(width: 4),
        MessageStatusTicks(status: status, size: fontSize + 2, color: color),
      ],
    );
  }
}

/// Group read receipts summary
class GroupReadReceipts extends StatelessWidget {
  final int totalMembers;
  final int deliveredCount;
  final int readCount;
  final bool showDetails;
  final VoidCallback? onTap;

  const GroupReadReceipts({
    super.key,
    required this.totalMembers,
    required this.deliveredCount,
    required this.readCount,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine overall status
    MessageStatus status;
    if (readCount == totalMembers - 1) {
      status = MessageStatus.read;
    } else if (deliveredCount == totalMembers - 1) {
      status = MessageStatus.delivered;
    } else {
      status = MessageStatus.sent;
    }

    if (!showDetails) {
      return MessageStatusTicks(status: status);
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageStatusTicks(status: status, size: 14),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    final others = totalMembers - 1;
    if (readCount == others) {
      return 'Seen by all';
    } else if (readCount > 0) {
      return 'Seen by $readCount of $others';
    } else if (deliveredCount == others) {
      return 'Delivered to all';
    } else if (deliveredCount > 0) {
      return 'Delivered to $deliveredCount of $others';
    }
    return 'Sent';
  }
}

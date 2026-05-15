// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_date_header.dart
// PURPOSE: Date separator between messages from different days
// STYLE: WhatsApp-style centered date bubble
// DEPENDENCIES: chat_date_utils.dart
// ================================================================

import 'package:flutter/material.dart';
import '../../../utils/chat_date_utils.dart';

class MessageDateHeader extends StatelessWidget {
  final DateTime dateTime;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final bool animated;

  const MessageDateHeader({
    super.key,
    required this.dateTime,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final headerText = ChatDateUtils.formatDateHeader(dateTime);

    Widget header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        headerText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor ?? colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );

    if (animated) {
      header = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          );
        },
        child: header,
      );
    }

    return Padding(
      padding: padding,
      child: Center(child: header),
    );
  }
}

/// New messages indicator (for scroll-to-bottom)
class NewMessagesIndicator extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NewMessagesIndicator({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$count new message${count != 1 ? 's' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today/Yesterday header for chat list sections
class ChatListSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const ChatListSectionHeader({super.key, required this.title, this.count = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

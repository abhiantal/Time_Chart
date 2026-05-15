// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_forward_label.dart
// PURPOSE: "Forwarded" label shown in forwarded messages
// STYLE: WhatsApp forward label style
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';

class MessageForwardLabel extends StatelessWidget {
  final bool isMe;
  final int forwardCount;
  final bool revamped;

  const MessageForwardLabel({
    super.key,
    required this.isMe,
    this.forwardCount = 0,
    this.revamped = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forward_rounded,
            size: 12,
            color: isMe
                ? colorScheme.onPrimary.withValues(alpha: 0.7)
                : revamped
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            forwardCount > 4 ? 'Forwarded many times' : 'Forwarded',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isMe
                  ? colorScheme.onPrimary.withValues(alpha: 0.7)
                  : revamped
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

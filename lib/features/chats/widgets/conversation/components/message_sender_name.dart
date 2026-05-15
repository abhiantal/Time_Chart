// ================================================================
// FILE: lib/features/chat/widgets/conversation/components/message_sender_name.dart
// PURPOSE: Display sender name in group chat messages
// STYLE: Color-coded by user ID for visual distinction
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';

class MessageSenderName extends StatelessWidget {
  final String name;
  final String? userId;
  final bool isMe;
  final TextStyle? style;
  final VoidCallback? onTap;

  const MessageSenderName({
    super.key,
    required this.name,
    this.userId,
    this.isMe = false,
    this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate consistent color from user ID
    final nameColor = _getUserColor(userId ?? name, colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          isMe ? 'You' : name,
          style:
              style ??
              theme.textTheme.labelSmall?.copyWith(
                color: isMe ? colorScheme.primary : nameColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }

  Color _getUserColor(String id, ColorScheme colorScheme) {
    // Generate consistent pastel color from string
    final hash = id.codeUnits.fold(0, (prev, char) => prev + char);

    // Palette of colors that work well on both light and dark backgrounds
    const colors = [
      Color(0xFFE91E63), // Pink
      Color(0xFF9C27B0), // Purple
      Color(0xFF673AB7), // Deep Purple
      Color(0xFF3F51B5), // Indigo
      Color(0xFF2196F3), // Blue
      Color(0xFF009688), // Teal
      Color(0xFF4CAF50), // Green
      Color(0xFFFF9800), // Orange
      Color(0xFFFF5722), // Deep Orange
      Color(0xFF795548), // Brown
    ];

    return colors[hash % colors.length];
  }
}

/// Color-coded sender name chip (for member list)
class SenderNameChip extends StatelessWidget {
  final String name;
  final String? userId;
  final bool isAdmin;
  final bool isOwner;
  final double size;

  const SenderNameChip({
    super.key,
    required this.name,
    this.userId,
    this.isAdmin = false,
    this.isOwner = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nameColor = _getUserColor(userId ?? name, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: nameColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwner
              ? Colors.amber
              : isAdmin
              ? Colors.blue
              : nameColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: nameColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 4),
            Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          ] else if (isAdmin) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.admin_panel_settings_rounded,
              size: 12,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Color _getUserColor(String id, ColorScheme colorScheme) {
    final hash = id.codeUnits.fold(0, (prev, char) => prev + char);
    const colors = [
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF673AB7),
      Color(0xFF3F51B5),
      Color(0xFF2196F3),
      Color(0xFF009688),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFFF5722),
    ];
    return colors[hash % colors.length];
  }
}

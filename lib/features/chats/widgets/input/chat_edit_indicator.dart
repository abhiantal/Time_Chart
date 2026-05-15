// ================================================================
// FILE: lib/features/chat/widgets/input/chat_edit_indicator.dart
// PURPOSE: Edit mode indicator showing which message is being edited
// STYLE: Clean edit bar with message preview
// DEPENDENCIES: chat_message_model.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/chat_message_model.dart';
import '../../utils/chat_text_utils.dart';

class ChatEditIndicator extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback onCancel;

  const ChatEditIndicator({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          bottom: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          // Edit icon with pulse animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Message preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Editing message',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMessageType(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getPreviewText(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Cancel button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onCancel();
            },
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  String _getMessageType() {
    if (message.type == ChatMessageType.text) return 'Text';
    if (message.type == ChatMessageType.image) return 'Image';
    if (message.type == ChatMessageType.video) return 'Video';
    if (message.type == ChatMessageType.audio) return 'Audio';
    if (message.type == ChatMessageType.voice) return 'Voice';
    if (message.type == ChatMessageType.document) return 'Document';
    if (message.type == ChatMessageType.location) return 'Location';
    if (message.type == ChatMessageType.contact) return 'Contact';
    return 'Message';
  }

  String _getPreviewText() {
    if (message.textContent != null && message.textContent!.isNotEmpty) {
      return ChatTextUtils.generatePreview(message.textContent!, maxLength: 80);
    }
    return 'No text content';
  }
}

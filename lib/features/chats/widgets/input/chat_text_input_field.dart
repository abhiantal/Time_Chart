// ================================================================
// FILE: lib/features/chat/widgets/input/chat_text_input_field.dart
// PURPOSE: Expandable text input field for chat
// STYLE: WhatsApp-style with max lines
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatTextInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;
  final String hintText;

  const ChatTextInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 6,
    this.hintText = 'Type a message...',
  });

  @override
  State<ChatTextInputField> createState() => _ChatTextInputFieldState();
}

class _ChatTextInputFieldState extends State<ChatTextInputField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        minHeight: 40,
        maxHeight: 40 + (20 * (widget.maxLines - 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSend(),
              inputFormatters: [LengthLimitingTextInputFormatter(4096)],
            ),
          ),
        ],
      ),
    );
  }
}

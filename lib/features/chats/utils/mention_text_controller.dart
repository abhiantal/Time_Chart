import 'package:flutter/material.dart';

/// A specialized controller that hides the UUID part of mentions in the input field.
/// Format: @[DisplayName](UUID) -> Displays as: @DisplayName
class MentionTextController extends TextEditingController {
  MentionTextController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Regex matches: @[Some Name](some-uuid)
    // Group 1: Display Name
    // Group 2: UUID
    final mentionRegex = RegExp(r'@\[([^\]]+)\]\s?\(([^)]+)\)');
    
    final List<InlineSpan> spans = [];
    int currentPos = 0;

    final matches = mentionRegex.allMatches(text).toList();
    
    for (final match in matches) {
      // Add plain text before the mention
      if (match.start > currentPos) {
        spans.add(TextSpan(
          text: text.substring(currentPos, match.start),
          style: style,
        ));
      }

      // Add the display name (without the UUID part)
      final displayName = match.group(1) ?? "";
      spans.add(TextSpan(
        text: '@$displayName',
        style: style?.copyWith(
          color: const Color(0xFF00A884), // WhatsApp-style Teal
          fontWeight: FontWeight.bold,
        ),
      ));

      currentPos = match.end;
    }

    // Add the remaining text after the last match
    if (currentPos < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPos),
        style: style,
      ));
    }

    return TextSpan(children: spans, style: style);
  }
}

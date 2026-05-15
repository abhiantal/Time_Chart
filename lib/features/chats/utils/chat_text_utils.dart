import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTextUtils {
  ChatTextUtils._();

  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)',
    caseSensitive: false,
  );

  static final RegExp _mentionRegex = RegExp(r'@\[([^\]]+)\]\(([^)]+)\)');

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static final RegExp _phoneRegex = RegExp(
    r'^[\+]?[(]?[0-9]{1,3}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,4}[-\s\.]?[0-9]{1,9}$',
  );

  static Widget buildRichText(
    BuildContext context,
    String text, {
    bool isMe = false,
    Function(String userId)? onMentionTap,
    Function(String url)? onLinkTap,
    TextStyle? baseStyle,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultStyle =
        baseStyle ??
        TextStyle(
          color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
          fontSize: 14,
        );

    final mentionStyle = defaultStyle.copyWith(
      color: const Color(0xFF00A884), // WhatsApp Teal
      fontWeight: FontWeight.bold,
    );

    final linkStyle = defaultStyle.copyWith(
      color: isMe ? Colors.white : colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: isMe ? Colors.white70 : colorScheme.primary,
    );

    final List<InlineSpan> spans = [];
    int currentPos = 0;

    final allMatches = <({int start, int end, String type, String value, String? name})>[];

    for (final match in _mentionRegex.allMatches(text)) {
      allMatches.add((
        start: match.start,
        end: match.end,
        type: 'mention',
        value: match.group(2) ?? '',
        name: match.group(1) ?? '',
      ));
    }

    for (final match in _urlRegex.allMatches(text)) {
      allMatches.add((
        start: match.start,
        end: match.end,
        type: 'url',
        value: match.group(0)!,
        name: null,
      ));
    }

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    for (final match in allMatches) {
      if (currentPos < match.start) {
        spans.add(
          TextSpan(
            text: text.substring(currentPos, match.start),
            style: defaultStyle,
          ),
        );
      }

      if (match.type == 'mention') {
        spans.add(
          TextSpan(
            text: '@${match.name}',
            style: mentionStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                HapticFeedback.lightImpact();
                onMentionTap?.call(match.value);
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.value,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openLink(match.value, onLinkTap),
          ),
        );
      }

      currentPos = match.end;
    }

    if (currentPos < text.length) {
      spans.add(
        TextSpan(text: text.substring(currentPos), style: defaultStyle),
      );
    }

    return RichText(text: TextSpan(children: spans), softWrap: true);
  }

  static String cleanMentions(String text) {
    if (text.isEmpty) return text;
    // Converts @[User Name](uuid-1234) into just @User Name
    return text.replaceAllMapped(_mentionRegex, (match) {
      final name = match.group(1);
      return name != null ? '@$name' : match.group(0)!;
    });
  }

  static String generatePreview(String text, {int maxLength = 100}) {
    if (text.isEmpty) return '';
    final cleanText = cleanMentions(text);
    if (cleanText.length <= maxLength) return cleanText;
    return '${cleanText.substring(0, maxLength)}...';
  }

  static String? getMentionQuery(String text, int cursorPosition) {
    if (text.isEmpty || cursorPosition <= 0) return null;

    int startPos = cursorPosition - 1;
    while (startPos >= 0 && text[startPos] != '@') {
      startPos--;
    }

    if (startPos < 0 || text[startPos] != '@') return null;

    if (startPos > 0 && !_isWordBoundary(text[startPos - 1])) {
      return null;
    }

    final query = text.substring(startPos + 1, cursorPosition);
    if (query.contains(' ')) return null;

    return query;
  }

  static String insertMention({
    required String text,
    required int cursorPosition,
    required String userId,
    required String displayName,
  }) {
    if (text.isEmpty || cursorPosition <= 0) return text;

    int startPos = cursorPosition - 1;
    while (startPos >= 0 && text[startPos] != '@') {
      startPos--;
    }

    if (startPos < 0 || text[startPos] != '@') return text;

    final beforeMention = text.substring(0, startPos);
    final afterMention = text.substring(cursorPosition);
    final mention = '@[$displayName]($userId) ';

    return beforeMention + mention + afterMention;
  }

  static List<String> extractMentions(String text) {
    final mentions = <String>[];
    for (final match in _mentionRegex.allMatches(text)) {
      final userId = match.group(2);
      if (userId != null) mentions.add(userId);
    }
    return mentions;
  }

  static List<String> extractUrls(String text) {
    final urls = <String>[];
    for (final match in _urlRegex.allMatches(text)) {
      urls.add(match.group(0)!);
    }
    return urls;
  }

  static bool isEmail(String text) => _emailRegex.hasMatch(text);
  static bool isPhoneNumber(String text) => _phoneRegex.hasMatch(text);
  static bool hasUrl(String text) => _urlRegex.hasMatch(text);
  static bool hasMentions(String text) => _mentionRegex.hasMatch(text);

  static Future<void> _openLink(String url, Function(String)? onLinkTap) async {
    HapticFeedback.lightImpact();
    if (onLinkTap != null) {
      onLinkTap(url);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static bool _isWordBoundary(String char) {
    return RegExp(r'[\s\.,!?;:()\[\]{}<>]').hasMatch(char);
  }

  static String sanitizeMessage(String text) {
    return cleanMentions(text).replaceAll(RegExp(r'[<>]'), '');
  }

  static int countCharacters(String text) => text.length;
  static int countWords(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
}

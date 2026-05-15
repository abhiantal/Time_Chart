import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';

class PostContent extends StatefulWidget {
  final String text;
  final List<String>? hashtags;
  final List<String>? mentions;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final int? maxLines;

  const PostContent({
    super.key,
    required this.text,
    this.hashtags,
    this.mentions,
    required this.isExpanded,
    required this.onExpandToggle,
    this.maxLines = 3,
  });

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  bool _shouldShowMore = false;

  @override
  void initState() {
    super.initState();
    _checkIfNeedsMore();
  }

  void _checkIfNeedsMore() {
    // Simple check - if text length > 200 chars, show "more" button
    _shouldShowMore = widget.text.length > 200 && !widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content with clickable hashtags/mentions
          RichText(
            text: _buildTextSpans(context),
            textScaleFactor: MediaQuery.of(context).textScaleFactor,
          ),

          // "more" / "less" button
          if (_shouldShowMore ||
              (widget.isExpanded && widget.text.length > 200))
            GestureDetector(
              onTap: widget.onExpandToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.isExpanded ? 'See less' : 'See more',
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Hashtags row (if not already in text)
          if (widget.hashtags != null &&
              widget.hashtags!.isNotEmpty &&
              !_hasHashtagsInText())
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.hashtags!.map((tag) {
                  return GestureDetector(
                    onTap: () => _navigateToHashtag(context, tag),
                    child: Text(
                      tag.startsWith('#') ? tag : '#$tag',
                      style: theme.textScheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  TextSpan _buildTextSpans(BuildContext context) {
    final theme = Theme.of(context);
    final List<TextSpan> spans = [];
    final RegExp mentionRegex = RegExp(r'@(\w+)');
    final RegExp hashtagRegex = RegExp(r'#(\w+)');

    String text = widget.text;
    int currentIndex = 0;

    // Combine all matches
    final matches = <RegExpMatch>[
      ...mentionRegex.allMatches(text),
      ...hashtagRegex.allMatches(text),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      // Add text before match
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: theme.textScheme.bodyMedium,
          ),
        );
      }

      // Add clickable mention/hashtag
      final isMention = match.group(0)!.startsWith('@');
      spans.add(
        TextSpan(
          text: match.group(0),
          style: theme.textScheme.bodyMedium?.copyWith(
            color: isMention
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isMention) {
                _navigateToProfile(context, match.group(1)!);
              } else {
                _navigateToHashtag(context, match.group(1)!);
              }
            },
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: widget.isExpanded
              ? text.substring(currentIndex)
              : text.substring(currentIndex, _getDisplayLimit(text)),
          style: theme.textScheme.bodyMedium,
        ),
      );
    }

    return TextSpan(children: spans);
  }

  int _getDisplayLimit(String text) {
    if (widget.maxLines == null) return text.length;
    // Rough estimate: ~50 chars per line
    final limit = (widget.maxLines! * 50).clamp(0, text.length);
    return limit < text.length ? limit : text.length;
  }

  bool _hasHashtagsInText() {
    if (widget.hashtags == null) return false;
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(widget.text);
    return matches.isNotEmpty;
  }

  void _navigateToProfile(BuildContext context, String username) {
    // Navigate to profile by username
    // This would need a method to get user ID from username
  }

  void _navigateToHashtag(BuildContext context, String tag) {
    context.pushNamed('hashtagFeed', pathParameters: {'tag': tag});
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../base_post_card.dart';
import '../helper/post_content.dart';

class TextPostCard extends StatefulWidget {
  final FeedPost post;
  final String currentUserId;
  final bool isInDetailView;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;

  const TextPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isInDetailView = false,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
  });

  @override
  State<TextPostCard> createState() => _TextPostCardState();
}

class _TextPostCardState extends State<TextPostCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArticle = widget.post.post.articleData != null;
    final articleData = widget.post.post.articleData;

    Widget contentWidget;
    if (isArticle) {
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.post.caption ?? 'Untitled Article',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (articleData?.content != null)
              PostContent(
                text: articleData!.content,
                hashtags: widget.post.post.hashtags,
                mentions: widget.post.post.mentionedUsernames,
                isExpanded: _isExpanded,
                onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
                maxLines: widget.isInDetailView ? null : 6,
              ),
          ],
        ),
      );
    } else if (widget.post.post.caption?.isNotEmpty == true) {
      contentWidget = PostContent(
        text: widget.post.post.caption!,
        hashtags: widget.post.post.hashtags,
        mentions: widget.post.post.mentionedUsernames,
        isExpanded: _isExpanded,
        onExpandToggle: () => setState(() => _isExpanded = !_isExpanded),
        maxLines: widget.isInDetailView ? null : 6,
      );
    } else {
      contentWidget = const SizedBox.shrink();
    }

    return BasePostCard(
      post: widget.post,
      currentUserId: widget.currentUserId,
      onTap: widget.onTap,
      onCommentPressed: widget.onCommentPressed,
      onMenuPressed: widget.onMenuPressed,
      content: contentWidget,
    );
  }
}

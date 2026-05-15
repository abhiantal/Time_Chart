import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/comments/models/comments_model.dart';
import 'package:the_time_chart/features/social/comments/providers/comment_provider.dart';
import '../../../../../media_utility/universal_media_service.dart';

class CommentTile extends StatefulWidget {
  final CommentModel comment;
  final String currentUserId;
  final bool isPostAuthor;
  final bool isReply;
  final bool isPinned;
  final bool isLast;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isPostAuthor,
    this.isReply = false,
    this.isPinned = false,
    this.isLast = false,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isExpanded = false;
  String? _validAvatarUrl;
  String? _resolvedMediaUrl;
  final UniversalMediaService _mediaService = UniversalMediaService();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _resolveMedia();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resolveMedia() async {
    if (widget.comment.hasMedia) {
      final resolved = await _mediaService.getValidSignedUrl(
        widget.comment.media!.url,
      );
      if (mounted) {
        setState(() => _resolvedMediaUrl = resolved);
      }
    }
  }

  Future<void> _loadAvatar() async {
    if (widget.comment.profileUrl != null) {
      final validUrl = await _mediaService.getValidAvatarUrl(
        widget.comment.profileUrl,
      );
      if (mounted) {
        setState(() {
          _validAvatarUrl = validUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnComment = widget.comment.userId == widget.currentUserId;
    final canModerate = isOwnComment || widget.isPostAuthor;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 48 : 16,
        right: 16,
        top: 8,
        bottom: widget.isLast ? 8 : 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToProfile(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: widget.comment.isByAuthor
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: ClipOval(
                  child: _validAvatarUrl != null
                      ? (_validAvatarUrl!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: _validAvatarUrl!,
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
                                placeholder: (context, url) => Container(
                                  color: theme.colorScheme.primaryContainer,
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildAvatarInitial(theme),
                              )
                            : Image.file(
                                File(_validAvatarUrl!),
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
                              ))
                      : _buildAvatarInitial(theme),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name, badge, timestamp
                _buildHeader(context, theme, isOwnComment),

                const SizedBox(height: 4),

                // Comment text with deleted/hidden handling
                _buildContent(context, theme),

                // Media (image/gif/sticker)
                if (widget.comment.hasMedia) _buildMedia(context, theme),

                const SizedBox(height: 6),

                // Reply context (when replying to someone)
                if (widget.comment.replyContextText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      widget.comment.replyContextText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Action row
                _buildActionRow(context, theme, canModerate, isOwnComment),
              ],
            ),
          ),

          // 3-dot menu for moderation
          if (canModerate)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                if (isOwnComment)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (canModerate)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                if (widget.isPostAuthor && !isOwnComment) ...[
                  const PopupMenuDivider(),
                  if (!widget.comment.isPinned)
                    const PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, size: 18),
                          SizedBox(width: 8),
                          Text('Pin comment'),
                        ],
                      ),
                    ),
                  if (widget.comment.isPinned)
                    const PopupMenuItem(
                      value: 'unpin',
                      child: Row(
                        children: [
                          Icon(Icons.push_pin_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Unpin comment'),
                        ],
                      ),
                    ),
                  if (!widget.comment.isHidden)
                    const PopupMenuItem(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 18),
                          SizedBox(width: 8),
                          Text('Hide comment'),
                        ],
                      ),
                    ),
                  if (widget.comment.isHidden)
                    const PopupMenuItem(
                      value: 'unhide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Unhide comment'),
                        ],
                      ),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitial(ThemeData theme) {
    final nameToUse = widget.comment.displayName?.isNotEmpty == true ? widget.comment.displayName! : widget.comment.username;
    return Center(
      child: Text(
        nameToUse?.isNotEmpty == true
            ? nameToUse![0].toUpperCase()
            : '?',
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isOwnComment,
  ) {
    return Row(
      children: [
        // Username with author badge
        GestureDetector(
          onTap: _navigateToProfile,
          child: Text(
            widget.comment.displayName?.isNotEmpty == true ? widget.comment.displayName! : (widget.comment.username ?? 'Unknown user'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.comment.isByAuthor
                  ? theme.colorScheme.primary
                  : null,
            ),
          ),
        ),

        // Author badge
        if (widget.comment.isByAuthor) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              'Author',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],

        // Pinned badge
        if (widget.comment.isPinned) ...[
          const SizedBox(width: 6),
          Icon(Icons.push_pin, size: 12, color: theme.colorScheme.primary),
        ],

        const Spacer(),

        // Timestamp
        Text(
          widget.comment.timeAgo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Edited indicator
        if (widget.comment.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            '• Edited',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (!widget.comment.isVisible) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.comment.displayContent,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Parse mentions and hashtags
    final text = widget.comment.content;
    final hasMore = text.length > 300 && !_isExpanded;
    final displayText = hasMore ? '${text.substring(0, 300)}...' : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: _parseContent(displayText, theme)),
          style: theme.textTheme.bodyMedium,
        ),
        if (hasMore)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'See more',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<TextSpan> _parseContent(String text, ThemeData theme) {
    final List<TextSpan> spans = [];
    final mentionRegex = RegExp(r'@(\w+)');
    final hashtagRegex = RegExp(r'#(\w+)');

    int currentIndex = 0;

    // Simple parser - for production use a more robust solution
    final matches = [
      ...mentionRegex.allMatches(text),
      ...hashtagRegex.allMatches(text),
    ]..sort((a, b) => a.start.compareTo(b.start));

    for (final match in matches) {
      // Add text before match
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      // Add mention/hashtag as special span
      final isMention = match.group(0)!.startsWith('@');
      spans.add(
        TextSpan(
          text: match.group(0),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMention
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
          recognizer: null, // Add TapGestureRecognizer if needed
        ),
      );

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
  }

  Widget _buildMedia(BuildContext context, ThemeData theme) {
    if (widget.comment.media == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Open full-screen media viewer
        // Navigate to full-screen media
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _resolvedMediaUrl != null
              ? (_resolvedMediaUrl!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: _resolvedMediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildMediaShimmer(theme),
                        errorWidget: (context, url, error) =>
                            _buildErrorPlaceholder(theme),
                      )
                    : Image.file(File(_resolvedMediaUrl!), fit: BoxFit.cover))
              : _buildMediaShimmer(theme),
        ),
      ),
    );
  }

  Widget _buildMediaShimmer(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    ThemeData theme,
    bool canModerate,
    bool isOwnComment,
  ) {
    return Row(
      children: [
        // Like button - Outlined specifically to match image
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<CommentProvider>().updateCommentReaction(
              postId: widget.comment.postId,
              commentId: widget.comment.id,
              reactionType: widget.comment.hasReacted == true ? null : 'love',
              totalReactions: widget.comment.hasReacted == true
                  ? widget.comment.totalReactions - 1
                  : widget.comment.totalReactions + 1,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(
              widget.comment.hasReacted == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 20,
              color: widget.comment.hasReacted == true
                  ? Colors.red
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Reply button
        if (widget.comment.canReply)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<CommentProvider>().startReply(
                widget.comment.postId,
                widget.comment,
              );
            },
            child: Row(
              children: [
                Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Reply',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Replies count
        if (widget.comment.hasReplies && !widget.comment.isReply)
          GestureDetector(
            onTap: () {
              context.read<CommentProvider>().toggleReplies(
                postId: widget.comment.postId,
                commentId: widget.comment.id,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.comment.viewRepliesText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToProfile() {
    if (widget.comment.userId == widget.currentUserId) {
      // Navigate to own profile
    } else {
      context.pushNamed(
        'otherUserProfileScreen',
        pathParameters: {'userId': widget.comment.userId},
      );
    }
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    HapticFeedback.selectionClick();

    switch (action) {
      case 'edit':
        context.read<CommentProvider>().startEditing(
          widget.comment.postId,
          widget.comment,
        );
        break;

      case 'delete':
        final confirmed = await _showDeleteConfirmation(context);
        if (confirmed) {
          if (!mounted) return;
          await context.read<CommentProvider>().deleteComment(
            commentId: widget.comment.id,
            postId: widget.comment.postId,
          );
        }
        break;

      case 'pin':
        await context.read<CommentProvider>().togglePinComment(
          commentId: widget.comment.id,
          postId: widget.comment.postId,
        );
        break;

      case 'unpin':
        await context.read<CommentProvider>().togglePinComment(
          commentId: widget.comment.id,
          postId: widget.comment.postId,
        );
        break;

      case 'hide':
        await context.read<CommentProvider>().toggleHideComment(
          commentId: widget.comment.id,
          postId: widget.comment.postId,
          hide: true,
        );
        break;

      case 'unhide':
        await context.read<CommentProvider>().toggleHideComment(
          commentId: widget.comment.id,
          postId: widget.comment.postId,
          hide: false,
        );
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// Extension for text scheme
extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

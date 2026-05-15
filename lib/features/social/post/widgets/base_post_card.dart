import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';
import 'package:the_time_chart/features/social/reactions/providers/reaction_provider.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/features/social/reactions/widgets/reaction_picker.dart';
import 'package:the_time_chart/features/social/follow/providers/follow_provider.dart';

import '../models/post_model.dart';
import 'base_post_card/post_header.dart';
import 'helper/post_ad_badge.dart';
import 'base_post_card/post_actions.dart';
import 'helper/post_bottom_menu_sheet.dart';
import 'helper/post_bottom_share_sheet.dart';

class BasePostCard extends StatefulWidget {
  final FeedPost post;
  final String currentUserId;
  final Widget content;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;

  const BasePostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.content,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
  });

  @override
  State<BasePostCard> createState() => _BasePostCardState();
}

class _BasePostCardState extends State<BasePostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _doubleTapController;
  late Animation<double> _doubleTapAnimation;
  bool _showLikeAnimation = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _doubleTapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doubleTapController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.heavyImpact();
    setState(() => _showLikeAnimation = true);
    _doubleTapController.forward().then((_) {
      _doubleTapController.reverse().then((_) {
        if (mounted) setState(() => _showLikeAnimation = false);
      });
    });

    if (!widget.post.hasReacted) {
      context.read<ReactionProvider>().togglePostLike(widget.post.post.id);
    }
  }

  void _navigateToProfile() {
    if (widget.post.post.userId == widget.currentUserId) {
      context.goNamed('personalNav');
    } else {
      context.pushNamed(
        'otherUserProfileScreen',
        pathParameters: {'userId': widget.post.post.userId},
      );
    }
  }

  void _navigateToPostDetail() {
    // TODO: Implement post detail screen
    // context.pushNamed(
    //   'postDetail',
    //   pathParameters: {'postId': widget.post.post.id},
    //   extra: {
    //     'post': widget.post,
    //     'currentUserId': widget.currentUserId,
    //   },
    // );
  }

  void _navigateToComments() {
    context.pushNamed(
      'comments',
      extra: {
        'targetType': 'post',
        'targetId': widget.post.post.id,
        'currentUserId': widget.currentUserId,
      },
    );
  }

  void _showReactionPicker(
    BuildContext context,
    Offset offset,
    Size size,
    String postId,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: false,
      builder: (context) => ReactionPicker(
        anchorOffset: offset,
        anchorSize: size,
        currentReaction: ReactionType.tryFromString(widget.post.userReaction),
        onReactionSelected: (reaction) {
          context.read<ReactionProvider>().togglePostReaction(
            postId: postId,
            reactionType: reaction,
          );
        },
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    final post = widget.post.post;

    PostBottomSheet.show(
      context: context,
      postId: post.id,
      userId: post.userId,
      currentUserId: widget.currentUserId,
      username: widget.post.username ?? '',
      onEdit: () => PostBottomSheet.navigateToEditPost(context, widget.post),
      onDelete: () async {
        final success = await context.read<PostProvider>().deletePost(post.id);
        if (success && context.mounted) {
          AppSnackbar.success('Post deleted successfully');
        }
      },
      onShare: () {
        PostBottomShareSheet.show(context, widget.post);
      },
      onReport: () {
        PostBottomSheet.showReportDialog(
          context,
          onSubmitted: (reason) async {
            await context.read<PostProvider>().reportPost(
                  postId: post.id,
                  reason: reason,
                );
          },
        );
      },
      onBlock: () async {
        await context.read<FollowProvider>().blockUser(post.userId);
      },
      onCopyLink: () async {
        await Clipboard.setData(
          ClipboardData(text: 'https://app.com/post/${post.id}'),
        );
        if (context.mounted) {
          AppSnackbar.success('Link copied to clipboard');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post.post;
    final isOwnPost = post.userId == widget.currentUserId;

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onTap ?? _navigateToPostDetail,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.only(bottom: 16),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.02),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostHeader(
              userId: post.userId,
              username: widget.post.username ?? '',
              displayName: widget.post.displayName,
              profileUrl: widget.post.profileUrl,
              createdAt: post.publishedAt,
              isEdited: post.editHistory.isNotEmpty,
              isOwnPost: isOwnPost,
              visibility: post.visibility,
              isSponsored: post.adData != null,
              contentType: post.contentType.name,
              onAvatarTap: _navigateToProfile,
              onUsernameTap: _navigateToProfile,
              onMenuTap: widget.onMenuPressed ?? () => _showPostMenu(context),
            ),

            // Media Content
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  widget.content,
                  if (_showLikeAnimation)
                    AnimatedBuilder(
                      animation: _doubleTapAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_doubleTapAnimation.value * 0.5),
                          child: Opacity(
                            opacity: (1.0 - _doubleTapAnimation.value).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        theme.colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: theme.colorScheme.primary,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Integrated Ad Overlay
                  if (post.isSponsored && post.adData != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: PostAdBadge(
                        postId: post.id,
                        adData: post.adData,
                      ),
                    ),
                ],
              ),
            ),

            // Location Badge (without map functionality)
            if (post.location != null && post.location!.hasName)
              _buildLocationBadge(),

            // Post Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: PostActions(
                post: widget.post,
                hasReacted: widget.post.hasReacted,
                userReaction: widget.post.userReaction,
                reactionsCount: post.likesCount,
                commentsCount: post.commentsCount,
                savesCount: post.hasSaved ? 1 : 0,
                viewsCount: post.viewsCount,
                onCommentPressed:
                    widget.onCommentPressed ?? _navigateToComments,
                onReactionLongPress: (offset, size) {
                  _showReactionPicker(context, offset, size, post.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    final theme = Theme.of(context);
    final location = widget.post.post.location!;

    // Removed onTap functionality since we don't have url_launcher
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              location.name!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

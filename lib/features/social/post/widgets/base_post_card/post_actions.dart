import 'package:flutter/material.dart';
import 'package:the_time_chart/features/social/reactions/widgets/reaction_button.dart';
import 'package:the_time_chart/features/social/saves/widgets/save_button.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

import '../helper/post_bottom_share_sheet.dart';
import '../../models/post_model.dart';

class PostActions extends StatefulWidget {
  final FeedPost post;
  final bool hasReacted;
  final String? userReaction;
  final int reactionsCount;
  final int commentsCount;
  final int savesCount;
  final int viewsCount;
  final VoidCallback onCommentPressed;
  final Function(Offset, Size)? onReactionLongPress;

  const PostActions({
    super.key,
    required this.post,
    required this.hasReacted,
    this.userReaction,
    required this.reactionsCount,
    required this.commentsCount,
    required this.savesCount,
    this.viewsCount = 0,
    required this.onCommentPressed,
    this.onReactionLongPress,
  });

  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isShareExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count <= 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final formatted = (count / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(count / 1000).floor()}K'
          : '${formatted}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget _buildStat(IconData icon, int count, VoidCallback? onTap, {Color? activeColor, bool isActive = false}) {
      final hasCount = count > 0;
      final Color displayColor = (isActive && activeColor != null) ? activeColor : theme.colorScheme.onSurface;
      
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 24, 
              color: displayColor.withOpacity(hasCount || isActive ? 1.0 : 0.6)
            ),
            const SizedBox(width: 6),
            Text(
              _formatCount(count),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: hasCount ? FontWeight.bold : FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(hasCount ? 1.0 : 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Like/Reaction button & count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: () {
                  if (widget.onReactionLongPress != null) {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final offset = box.localToGlobal(Offset.zero);
                    final size = box.size;
                    widget.onReactionLongPress!(offset, size);
                  }
                },
                child: ReactionButton(
                  targetType: ReactionTargetType.post,
                  targetId: widget.post.post.id,
                  initialReaction: ReactionType.tryFromString(
                    widget.userReaction,
                  ),
                  initialCount: 0, // Count is shown in custom text below
                  size: 24,
                  style: ReactionButtonStyle.instagram,
                  showCount: false,
                  showLabel: false,
                  onReactionChanged: (reaction) {},
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatCount(widget.reactionsCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: widget.reactionsCount > 0 ? FontWeight.bold : FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(widget.reactionsCount > 0 ? 1.0 : 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Comment button
          _buildStat(
            Icons.chat_bubble_outline,
            widget.commentsCount,
            widget.onCommentPressed,
            activeColor: theme.colorScheme.primary,
            isActive: widget.commentsCount > 0,
          ),
          const SizedBox(width: 20),

          // Share button
          GestureDetector(
            onTap: () {
              setState(() => _isShareExpanded = !_isShareExpanded);
              _animationController.forward().then((_) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() => _isShareExpanded = false);
                    _animationController.reverse();
                  }
                });
              });
              PostBottomShareSheet.show(context, widget.post);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 24,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Views count (read-only for normal users)
          if (widget.viewsCount > 0)
            _buildStat(Icons.bar_chart, widget.viewsCount, null),

          const Spacer(),
          // Save button
          SaveButton(
            postId: widget.post.post.id,
            initialSaved: false, // This will be provided by provider
            size: 24,
            showLabel: false, // Hide label to make it cleaner
          ),
        ],
      ),
    );
  }
}

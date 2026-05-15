import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/comments/models/comments_model.dart';
import 'package:the_time_chart/features/social/comments/providers/comment_provider.dart';
import 'comment_tile.dart';

class CommentReplies extends StatefulWidget {
  final CommentModel parentComment;
  final String currentUserId;
  final bool isPostAuthor;
  final String postId;

  const CommentReplies({
    super.key,
    required this.parentComment,
    required this.currentUserId,
    required this.isPostAuthor,
    required this.postId,
  });

  @override
  State<CommentReplies> createState() => _CommentRepliesState();
}

class _CommentRepliesState extends State<CommentReplies>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Auto-expand if replies are already loaded
    if (widget.parentComment.isRepliesLoaded) {
      _isExpanded = true;
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleReplies() {
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded) {
      _expandController.forward();
      _loadReplies();
    } else {
      _expandController.reverse();
    }
  }

  Future<void> _loadReplies() async {
    if (widget.parentComment.isRepliesLoaded) return;

    await context.read<CommentProvider>().loadReplies(
      postId: widget.postId,
      commentId: widget.parentComment.id,
    );
  }

  Future<void> _loadMoreReplies() async {
    await context.read<CommentProvider>().loadMoreReplies(
      postId: widget.postId,
      commentId: widget.parentComment.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = context.watch<CommentProvider>();
    final replies = widget.parentComment.replies;
    final totalReplies = widget.parentComment.repliesCount;
    final remainingReplies = totalReplies - replies.length;
    final isLoading = commentProvider.isRepliesLoading(widget.parentComment.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reply toggle button
        if (widget.parentComment.hasReplies)
          GestureDetector(
            onTap: _toggleReplies,
            child: Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isExpanded
                        ? widget.parentComment.hideRepliesText
                        : widget.parentComment.viewRepliesText,
                    style: Theme.of(context).textScheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Replies list (animated)
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Column(
            children: [
              // Reply tiles
              ...replies.asMap().entries.map((entry) {
                final index = entry.key;
                final reply = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: CommentTile(
                    comment: reply,
                    currentUserId: widget.currentUserId,
                    isPostAuthor: widget.isPostAuthor,
                    isReply: true,
                    isLast: index == replies.length - 1,
                  ),
                );
              }),

              // Loading indicator
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),

              // Load more button
              if (remainingReplies > 0 && !isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 8),
                  child: GestureDetector(
                    onTap: _loadMoreReplies,
                    child: Text(
                      'View $remainingReplies more ${remainingReplies == 1 ? 'reply' : 'replies'}',
                      style: Theme.of(context).textScheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

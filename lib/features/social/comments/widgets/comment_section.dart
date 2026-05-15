import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/comments/models/comments_model.dart';
import 'package:the_time_chart/features/social/comments/providers/comment_provider.dart';

import 'comment_tile.dart';
import 'comment_input.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final bool isPostAuthor;
  final VoidCallback? onClose;

  const CommentSection({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.isPostAuthor,
    this.onClose,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showPinnedComment = true;
  CommentSortBy _currentSort = CommentSortBy.top;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    setState(() => _isLoading = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CommentProvider>().loadComments(
        postId: widget.postId,
        sortBy: _currentSort,
        refresh: refresh,
      );
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _changeSort(CommentSortBy sort) {
    if (_currentSort == sort) return;

    HapticFeedback.selectionClick();
    setState(() => _currentSort = sort);
    _loadComments(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentProvider = Provider.of<CommentProvider>(context);
    final commentsList = commentProvider.getCommentsList(widget.postId);
    final pinnedComment = commentsList.pinnedComment;
    final comments = commentsList.comments;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle for bottom sheet
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          _buildHeader(context, theme),

          // Tabs & Sort
          _buildTabsAndSort(context, theme),

          // Pinned Comment (if any)
          if (pinnedComment != null && _showPinnedComment)
            _buildPinnedComment(context, pinnedComment),

          // Comments List
          Expanded(
            child: _isLoading && comments.isEmpty
                ? _buildLoadingState(theme)
                : comments.isEmpty
                ? _buildEmptyState(context, theme)
                : _buildCommentsList(context, comments, pinnedComment),
          ),

          // Comment Input
          CommentInput(
            postId: widget.postId,
            currentUserId: widget.currentUserId,
            isPostAuthor: widget.isPostAuthor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Comments',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose ?? () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsAndSort(BuildContext context, ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Text(
                    'Top comments',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    'Newest',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    'Threaded',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    _changeSort(CommentSortBy.top);
                    break;
                  case 1:
                    _changeSort(CommentSortBy.newest);
                    break;
                  case 2:
                    _changeSort(CommentSortBy.threaded);
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedComment(BuildContext context, CommentModel comment) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Pinned comment',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isPostAuthor)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    context
                        .read<CommentProvider>()
                        .togglePinComment(
                          commentId: comment.id,
                          postId: widget.postId,
                        )
                        .then((_) {
                          setState(() => _showPinnedComment = false);
                        });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          CommentTile(
            comment: comment,
            currentUserId: widget.currentUserId,
            isPostAuthor: widget.isPostAuthor,
            isPinned: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    List<CommentModel> comments,
    CommentModel? pinnedComment,
  ) {
    final displayComments = pinnedComment != null && _showPinnedComment
        ? comments.where((c) => c.id != pinnedComment.id).toList()
        : comments;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: displayComments.length,
      itemBuilder: (context, index) {
        final comment = displayComments[index];

        if (_currentSort == CommentSortBy.threaded) {
          // Threaded view - only show root comments, replies are nested
          if (!comment.isRoot) return const SizedBox.shrink();

          return CommentThread(
            key: ValueKey(comment.id),
            comment: comment,
            currentUserId: widget.currentUserId,
            isPostAuthor: widget.isPostAuthor,
            postId: widget.postId,
          );
        }

        // Flat view - show all comments
        return CommentTile(
          comment: comment,
          currentUserId: widget.currentUserId,
          isPostAuthor: widget.isPostAuthor,
          isLast: index == displayComments.length - 1,
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading comments...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to start the conversation!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Thread widget for nested replies
class CommentThread extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final bool isPostAuthor;
  final String postId;

  const CommentThread({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isPostAuthor,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommentTile(
          comment: comment,
          currentUserId: currentUserId,
          isPostAuthor: isPostAuthor,
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: comment.replies
                  .map(
                    (reply) => CommentTile(
                      comment: reply,
                      currentUserId: currentUserId,
                      isPostAuthor: isPostAuthor,
                      isReply: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        const Divider(height: 24, indent: 48),
      ],
    );
  }
}

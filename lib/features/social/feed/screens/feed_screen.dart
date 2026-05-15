import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/features/social/post/providers/post_ui_provider.dart';
import 'package:the_time_chart/features/social/post/widgets/post_card.dart';
import 'package:the_time_chart/features/social/feed/widgets/feed_skeleton.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';

import '../controllers/feed_controller.dart';
import '../widgets/feed_header.dart';
import '../widgets/feed_filter_chips.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_error_state.dart';

import '../widgets/feed_bottom_loader.dart';
import '../widgets/feed_refresh_indicator.dart';

enum FeedType { home, following, trending, live, media }

class FeedScreen extends StatefulWidget {
  final String currentUserId;
  final FeedType initialFeedType;

  const FeedScreen({
    super.key,
    required this.currentUserId,
    this.initialFeedType = FeedType.home,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late FeedController _feedController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _postViewRecorded = {};
  bool _isRefreshing = false;
  bool _showScrollToTop = false;

  final List<_FeedTab> _tabs = const [
    _FeedTab(label: 'For You', type: FeedType.home, icon: Icons.explore),
    _FeedTab(label: 'Following', type: FeedType.following, icon: Icons.people),
    _FeedTab(
      label: 'Trending',
      type: FeedType.trending,
      icon: Icons.trending_up,
    ),
    _FeedTab(label: 'Live', type: FeedType.live, icon: Icons.sensors),
    _FeedTab(label: 'Media', type: FeedType.media, icon: Icons.video_library),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _tabs.indexWhere(
        (tab) => tab.type == widget.initialFeedType,
      ),
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _feedController = FeedController(
      postProvider: context.read<PostProvider>(),
      currentUserId: widget.currentUserId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialFeed();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _feedController.dispose();

    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    HapticFeedback.selectionClick();
    _feedController.changeFeedType(_tabs[_tabController.index].type);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Check if should show scroll to top button
      final showButton = _scrollController.position.pixels > 800;
      if (showButton != _showScrollToTop) {
        setState(() => _showScrollToTop = showButton);
      }

      // Load more when near bottom
      if (_scrollController.position.extentAfter < 500) {
        _feedController.loadMorePosts();
      }
    }
  }

  Future<void> _loadInitialFeed() async {
    await _feedController.loadInitialPosts();
  }

  Future<void> _refreshFeed() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    await _feedController.refreshFeed();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context);
    final uiProvider = Provider.of<PostUIProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FeedRefreshIndicator(
        onRefresh: _refreshFeed,
        isRefreshing: _isRefreshing,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar with stories
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: FeedHeader(
                currentUserId: widget.currentUserId,
                onSearchTap: () => _navigateToSearch(),
                onNotificationsTap: () => _navigateToNotifications(),
                onMessagesTap: () => _navigateToMessages(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Column(
                  children: [
                    // Filter chips
                    FeedFilterChips(
                      currentUserId: widget.currentUserId,
                      selectedType: _tabs[_tabController.index].type,
                      onTypeSelected: (type) {
                        final index = _tabs.indexWhere(
                          (tab) => tab.type == type,
                        );
                        if (index != -1) {
                          _tabController.animateTo(index);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Feed content — reels/vlogs are excluded here (they live on ReelsPage)
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: _buildFeedContent(postProvider, uiProvider),
            ),

            // Bottom loader
            if (postProvider.hasMoreFeed)
              SliverToBoxAdapter(
                child: FeedBottomLoader(isLoading: postProvider.isLoadingFeed),
              ),
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: theme.colorScheme.primary,
               heroTag: 'feed_scroll_to_top_fab',
               child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildFeedContent(
    PostProvider postProvider,
    PostUIProvider uiProvider,
  ) {
    final currentFeedType = _tabs[_tabController.index].type;

    final allowedContentTypes = {
      'text',
      'image',
      'carousel',
      'article',
      'link',
      'poll',
      'day_task',
      'long_goal',
      'week_task',
      'bucket',
      'video',
      'reel',
      'vlog',
      'advertisement',
    };
    final List<FeedPost> rawPosts;
    if (currentFeedType == FeedType.trending) {
      rawPosts = postProvider.explorePosts
          .map(
            (ep) => FeedPost(
              post: ep.post,
              username: ep.post.username,
              profileUrl: ep.post.profileUrl,
            ),
          )
          .toList();
    } else {
      rawPosts = postProvider.feedPosts;
    }

    final allPosts = rawPosts
        .where((f) => allowedContentTypes.contains(f.post.contentType.name))
        .toList();

    final posts = currentFeedType == FeedType.media
        ? allPosts.where((f) {
            final content = f.post.contentType ?? '';
            return content == 'image' ||
                content == 'carousel' ||
                f.post.hasMedia;
          }).toList()
        : allPosts;

    if (postProvider.isLoadingFeed && posts.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const FeedSkeleton(),
          childCount: 5,
        ),
      );
    }

    if (postProvider.error != null && posts.isEmpty) {
      return SliverToBoxAdapter(
        child: FeedErrorState(
          error: postProvider.error!,
          onRetry: _refreshFeed,
        ),
      );
    }

    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: FeedEmptyState(
          currentUserId: widget.currentUserId,
          feedType: _tabs[_tabController.index].type,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildPostCard(posts[index], index);
      }, childCount: posts.length),
    );
  }

  Widget _buildPostCard(FeedPost post, int index) {
    // Record view when post becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_postViewRecorded.containsKey(post.post.id)) {
        _postViewRecorded[post.post.id] = true;
        context.read<PostViewProvider>().recordViewWithDebounce(
          postId: post.post.id,
          source: ViewSource.feed,
        );
      }
    });

    return PostCard(
      post: post,
      currentUserId: widget.currentUserId,
      onCommentPressed: () => _navigateToComments(post.post.id),
    );
  }

  void _navigateToSearch() {
    context.pushNamed('profileSearchPage');
  }

  void _navigateToNotifications() {
    // Navigate to notifications screen
  }

  void _navigateToMessages() {
    context.pushNamed('chatHubScreen');
  }

  void _navigateToComments(String postId) {
    context.pushNamed(
      'comments',
      extra: {
        'targetType': 'post',
        'targetId': postId,
        'currentUserId': widget.currentUserId,
      },
    );
  }
}

class _FeedTab {
  final String label;
  final FeedType type;
  final IconData icon;

  const _FeedTab({required this.label, required this.type, required this.icon});
}

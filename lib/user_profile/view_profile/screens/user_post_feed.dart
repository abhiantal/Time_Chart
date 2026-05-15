import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/features/social/post/widgets/post_card.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/widgets/feature_info_widgets.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_provider.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_models.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/chats/widgets/common/user_avatar_cached.dart';

class UserPostFeedScreen extends StatefulWidget {
  final String userId;
  final int initialIndex;
  final String? initialPostId; // 👈 Added initialPostId
  final List<PostModel>? preloadedPosts;
  final String? title;
  final String? tabType; // 👈 Added tabType

  const UserPostFeedScreen({
    super.key,
    required this.userId,
    this.initialIndex = 0,
    this.initialPostId, // 👈 Added initialPostId
    this.preloadedPosts,
    this.title,
    this.tabType, // 👈 Added tabType
  });

  @override
  State<UserPostFeedScreen> createState() => _UserPostFeedScreenState();
}

class _UserPostFeedScreenState extends State<UserPostFeedScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, bool> _postViewRecorded = {};
  bool _hasScrolled = false;
  UserProfile? _userProfile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_isLoadingProfile) return;
    setState(() => _isLoadingProfile = true);

    try {
      final profile = await context.read<ProfileProvider>().getProfileById(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _jumpToIndex(int targetIndex) {
    if (_hasScrolled) return;
    if (targetIndex < 0) return;

    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: targetIndex);
      _hasScrolled = true;
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && itemScrollController.isAttached && !_hasScrolled) {
          itemScrollController.jumpTo(index: targetIndex);
          _hasScrolled = true;
        }
      });
    }
  }

  List<PostModel> _filterPosts(List<PostModel> allPosts, String tabType) {
    return allPosts.where((post) {
      final isFromSource = post.sourceType != null;
      final hasMedia = post.media.isNotEmpty;

      if (tabType == 'posts') return !isFromSource && hasMedia;
      if (tabType == 'live') return isFromSource && post.isLive;
      if (tabType == 'snapshot') return isFromSource && !post.isLive;
      if (tabType == 'custom') return !isFromSource && !hasMedia;
      return true;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    // Refresh posts for this user
    await context.read<PostProvider>().loadUserPosts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider>().currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isLoadingProfile
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatarCached(
                    imageUrl: _userProfile?.profileUrl,
                    name: _userProfile?.displayName ?? widget.title ?? 'Posts',
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userProfile?.displayName ?? widget.title ?? 'Posts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_userProfile?.username != null)
                          Text(
                            '@${_userProfile!.username}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            onPressed: () => FeatureInfoCard.showEliteDialog(
              context,
              EliteFeatures.postFeed,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          // 🛡️ DYNAMIC RESOLUTION: Sync with provider for the specific user
          final List<PostModel> providerPosts = postProvider.getUserPosts(widget.userId);
          
          List<PostModel> posts;
          
          if (widget.tabType != null) {
            // If provider has data for this user, re-filter it to stay synced
            if (providerPosts.isNotEmpty) {
              posts = _filterPosts(providerPosts, widget.tabType!);
            } else {
              // Initial load fallback: Use preloaded while provider is loading current state
              posts = widget.preloadedPosts ?? [];
            }
          } else {
            // No tab filtering: Use provider if available, otherwise fallback to preloaded
            posts = providerPosts.isNotEmpty ? providerPosts : (widget.preloadedPosts ?? []);
          }

          // Safety check: ensure the list is actually populated if we have preloaded data
          if (posts.isEmpty && providerPosts.isEmpty && (widget.preloadedPosts?.isNotEmpty ?? false)) {
            posts = widget.preloadedPosts!;
          }

          // 🎯 ROBUST JUMP: If we haven't scrolled, find the correct index by ID
          if (!_hasScrolled && posts.isNotEmpty) {
            int targetIndex = -1;
            if (widget.initialPostId != null) {
              targetIndex = posts.indexWhere((p) => p.id == widget.initialPostId);
            }
            
            // Fallback to initialIndex if ID not found or not provided
            if (targetIndex == -1) {
              targetIndex = widget.initialIndex.clamp(0, posts.length - 1);
            }

            if (targetIndex >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _jumpToIndex(targetIndex);
              });
            }
          }

          // Try to get profile info from first post if not loaded yet
          if (_userProfile == null && posts.isNotEmpty) {
            final firstPost = posts.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _userProfile == null) {
                setState(() {
                  _userProfile = UserProfile(
                    id: widget.userId,
                    userId: widget.userId,
                    email: '', // Not needed for UI display
                    username: firstPost.username ?? '',
                    displayName: firstPost.displayName ?? '',
                    profileUrl: firstPost.profileUrl,
                    createdAt: firstPost.publishedAt,
                    updatedAt: DateTime.now(),
                  );
                });
              }
            });
          }

          if (posts.isEmpty && !postProvider.isLoadingUser) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts available.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (posts.isEmpty && postProvider.isLoadingUser) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: ScrollablePositionedList.builder(
              itemCount: posts.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final postModel = posts[index];

                // Record view when post becomes visible
                if (!_postViewRecorded.containsKey(postModel.id)) {
                  _postViewRecorded[postModel.id] = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.read<PostViewProvider>().recordViewWithDebounce(
                        postId: postModel.id,
                        source: ViewSource.profile,
                      );
                    }
                  });
                }

                // Map to FeedPost to maintain compatibility with PostCard
                // 🛡️ Enhanced Fallback: Use screen-level profile if post metadata is missing
                final feedPost = FeedPost(
                  post: postModel,
                  username: postModel.username ?? _userProfile?.username,
                  displayName: postModel.displayName ?? _userProfile?.displayName,
                  profileUrl: postModel.profileUrl ?? _userProfile?.profileUrl,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: PostCard(
                    post: feedPost,
                    currentUserId: currentUserId,
                  ),
                );
              },
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
            ),
          );
        },
      ),
    );
  }
}

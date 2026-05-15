// ================================================================
// FILE: lib/user_profile/view_profile/widgets/profile_tab_content.dart
// PURPOSE: Tab content for user profile (Posts, Live, Snapshot)
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/user_profile/view_profile/widgets/profile_grid_post_item.dart';
import 'package:the_time_chart/user_profile/view_profile/widgets/expandable_post_card.dart';
import 'package:the_time_chart/user_profile/view_profile/widgets/expandable_custom_post_card.dart';

class ProfileTabContent extends StatefulWidget {
  final String userId;
  final String title;
  final String? tabType; // 'posts', 'live', 'snapshot'

  const ProfileTabContent({
    super.key,
    required this.userId,
    required this.title,
    this.tabType,
  });

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent>
    with AutomaticKeepAliveClientMixin {
  bool _isNavigating = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    final postProvider = context.read<PostProvider>();
    await postProvider.loadUserPosts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final posts = postProvider.getUserPosts(widget.userId);
        final isLoading = postProvider.isLoadingUserPosts(widget.userId);

        // Filter posts based on tab type
        final filteredPosts = posts.where((post) {
          final isFromSource = post.sourceType != null;
          final hasMedia = post.media.isNotEmpty;

          if (widget.tabType == 'posts') {
            // Posts with media created directly
            return !isFromSource && hasMedia;
          }

          if (widget.tabType == 'live') {
            // Tasks/Buckets that are LIVE
            return isFromSource && post.isLive;
          }

          if (widget.tabType == 'snapshot') {
            // Tasks/Buckets that are SNAPSHOTS (not live)
            return isFromSource && !post.isLive;
          }

          if (widget.tabType == 'custom') {
            // Polls and Text posts created directly (no media)
            return !isFromSource && !hasMedia;
          }

          return true;
        }).toList();

        if (isLoading && filteredPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.tabType == 'posts'
                      ? Icons.grid_on_rounded
                      : widget.tabType == 'live'
                      ? Icons.sensors_rounded
                      : widget.tabType == 'snapshot'
                      ? Icons.camera_alt_outlined
                      : Icons.auto_awesome_mosaic_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${widget.title.toLowerCase()} yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (widget.tabType == 'posts') {
          return RefreshIndicator(
            onRefresh: _loadPosts,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final postModel = filteredPosts[index];
                return ProfileGridPostItem(
                  post: postModel,
                  index: index,
                  userId: widget.userId,
                  posts: filteredPosts,
                  tabType: widget.tabType, // 👈 Added tabType
                );
              },
            ),
          );
        } else {
          return RefreshIndicator(
            onRefresh: _loadPosts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final postModel = filteredPosts[index];
                if (widget.tabType == 'snapshot' || widget.tabType == 'live') {
                  return ExpandablePostCard(
                    post: postModel,
                    onTap: () {
                      if (_isNavigating) return;
                      setState(() => _isNavigating = true);

                      context.pushNamed(
                        'userPostFeed',
                        extra: {
                          'userId': widget.userId,
                          'initialIndex': index,
                          'initialPostId': postModel.id,
                          'preloadedPosts': filteredPosts,
                          'title': widget.tabType?.toUpperCase() ?? 'POSTS',
                          'tabType': widget.tabType,
                        },
                      ).then((_) {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                  );
                } else {
                  // This is for 'custom' (poll/text)
                  return ExpandableCustomPostCard(
                    post: postModel,
                    onTap: () {
                      if (_isNavigating) return;
                      setState(() => _isNavigating = true);

                      context.pushNamed(
                        'userPostFeed',
                        extra: {
                          'userId': widget.userId,
                          'initialIndex': index,
                          'initialPostId': postModel.id,
                          'preloadedPosts': filteredPosts,
                          'title': widget.tabType?.toUpperCase() ?? 'CUSTOM',
                          'tabType': widget.tabType,
                        },
                      ).then((_) {
                        if (mounted) setState(() => _isNavigating = false);
                      });
                    },
                  );
                }
              },
            ),
          );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/features/social/reels/widgets/reels_feed.dart';
import 'package:the_time_chart/features/social/screens/create_post_screen.dart';

class ReelsPage extends StatefulWidget {
  final String? currentUserId;

  const ReelsPage({super.key, this.currentUserId});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReels();
    });
  }

  Future<void> _loadReels() async {
    final provider = context.read<PostProvider>();
    // Trigger feed load so we have posts to filter
    if (provider.feedPosts.isEmpty) {
      await provider.loadHomeFeed();
    }
  }

  /// Returns all posts whose post_type OR content_type signals a video/reel/vlog.
  List<PostModel> _filterReelPosts(List<FeedPost> feedPosts) {
    return feedPosts
        .map((f) => f.post)
        .where(
          (p) =>
              p.hasMedia ||
              p.postType == PostType.video ||
              p.postType == PostType.reel,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reels',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurface),
            onPressed: () => _openCreateReel(context),
            tooltip: 'Create Reel',
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, _) {
          if (postProvider.isLoadingFeed && postProvider.feedPosts.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          final reels = _filterReelPosts(postProvider.feedPosts);

          if (reels.isEmpty && !postProvider.isLoadingFeed) {
            return _buildEmptyState(context);
          }

          return ReelsFeed(
            currentUserId: widget.currentUserId ?? '',
            initialReels: reels,
          );
        },
      ),
    ),
  );
}

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          ),
          const SizedBox(height: 20),
          Text(
            'No Reels Yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first reel or\nfollow people to see their reels here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _openCreateReel(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Reel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateReel(BuildContext context) {
    // Navigate to CreatePostScreen with reel mode pre-selected
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreatePostScreen(currentUserId: widget.currentUserId ?? ''),
        settings: const RouteSettings(arguments: {'initialMode': 'reel'}),
      ),
    );
  }
}

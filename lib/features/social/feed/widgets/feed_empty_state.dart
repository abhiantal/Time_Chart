import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/feed_screen.dart';

class FeedEmptyState extends StatelessWidget {
  final String currentUserId;
  final FeedType feedType;

  const FeedEmptyState({
    super.key,
    required this.currentUserId,
    required this.feedType,
  });

  const FeedEmptyState.explore({
    super.key,
    required this.currentUserId,
    this.feedType = FeedType.trending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getMessage(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (feedType == FeedType.home) ...[
              FilledButton.icon(
                onPressed: () {
                  context.pushNamed(
                    'createPost',
                    extra: {'currentUserId': currentUserId},
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate to explore
                  context.pushNamed('explore');
                },
                child: const Text('Discover People'),
              ),
            ] else if (feedType == FeedType.following) ...[
              FilledButton.icon(
                onPressed: () {
                  context.pushNamed('explore');
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explore'),
              ),
            ] else if (feedType == FeedType.live) ...[
              FilledButton.icon(
                onPressed: () {
                  // Start live stream
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Go Live'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (feedType) {
      case FeedType.home:
        return Icons.home_outlined;
      case FeedType.following:
        return Icons.people_outline;
      case FeedType.trending:
        return Icons.trending_up;
      case FeedType.live:
        return Icons.sensors;
      case FeedType.media:
        return Icons.video_library_outlined;
    }
  }

  String _getTitle() {
    switch (feedType) {
      case FeedType.home:
        return 'Your feed is empty';
      case FeedType.following:
        return 'No posts from people you follow';
      case FeedType.trending:
        return 'No trending posts found';
      case FeedType.live:
        return 'No live streams right now';
      case FeedType.media:
        return 'No media posts found';
    }
  }

  String _getMessage() {
    switch (feedType) {
      case FeedType.home:
        return 'Follow people to see their posts here,\nor create your own!';
      case FeedType.following:
        return 'When people you follow post, they\'ll appear here';
      case FeedType.trending:
        return 'Check back later for trending content';
      case FeedType.live:
        return 'Start a live stream or check back later';
      case FeedType.media:
        return 'Try switching to another feed type';
    }
  }
}

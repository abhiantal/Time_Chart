import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';
import '../../../media_utility/universal_media_service.dart';

class ProfileGridPostItem extends StatefulWidget {
  final PostModel post;
  final int index;
  final String userId;
  final List<PostModel> posts;
  final String? tabType;

  const ProfileGridPostItem({
    super.key,
    required this.post,
    required this.index,
    required this.userId,
    required this.posts,
    this.tabType,
  });

  @override
  State<ProfileGridPostItem> createState() => _ProfileGridPostItemState();
}

class _ProfileGridPostItemState extends State<ProfileGridPostItem> {
  bool _isNavigating = false;

  void _navigateToFeed(BuildContext context) {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    context.pushNamed(
      'userPostFeed',
      extra: {
        'userId': widget.userId,
        'initialIndex': widget.index,
        'initialPostId': widget.post.id,
        'preloadedPosts': widget.posts,
        'tabType': widget.tabType,
      },
    ).then((_) {
      if (mounted) setState(() => _isNavigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToFeed(context),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          child: widget._buildGridContent(context),
        ),
      ),
    );
  }
}

extension on ProfileGridPostItem {
  Widget _buildGridContent(BuildContext context) {
    final theme = Theme.of(context);
    final contentType = post.contentType.toLowerCase();
    final sourceType = post.sourceType?.toLowerCase() ?? '';

    // Check if it's a media post (Image, Video, Reel)
    if (contentType == 'image' ||
        contentType == 'video' ||
        contentType == 'reel') {
      if (post.media.isNotEmpty) {
        return Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<String?>(
              future: UniversalMediaService().getValidSignedUrl(
                post.media.first.url,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(color: theme.colorScheme.surfaceContainer);
                }
                final url = snapshot.data ?? post.media.first.url;

                if (url.isEmpty) {
                  return const Icon(Icons.broken_image, size: 30);
                }

                if (!url.startsWith('http') && File(url).existsSync()) {
                  return Image.file(
                    File(url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 30),
                  );
                }

                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: theme.colorScheme.surfaceContainer),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 30),
                );
              },
            ),
            if (contentType == 'video' || contentType == 'reel')
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  contentType == 'reel'
                      ? Icons.movie_outlined
                      : Icons.play_circle_outline,
                  color: Colors.white,
                  size: 20,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
          ],
        );
      }
    }

    // Check if it's a custom task (Day Task, Week Task, Long Goal, Bucket)
    final bool isCustomTask =
        ['day_task', 'week_task', 'long_goal', 'bucket'].contains(sourceType) ||
        ['day_task', 'week_task', 'long_goal', 'bucket'].contains(contentType);

    if (isCustomTask) {
      return _buildCustomTaskPreview(
        context,
        sourceType.isNotEmpty ? sourceType : contentType,
      );
    }

    // Fallback: Show a text snippet for text posts, polls, links, etc.
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          post.caption ?? '',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTaskPreview(BuildContext context, String type) {
    // Pick a thematic gradient / color logic based on the type
    // We'll just grab a nice vibrant one for the profile grid to look premium.
    List<Color> gradientColors;
    IconData icon;
    String displayType;

    switch (type) {
      case 'day_task':
        gradientColors = CardColorHelper.progress61to80Light[0]; // Greenish
        icon = Icons.check_circle_outline;
        displayType = 'Daily';
        break;
      case 'week_task':
        gradientColors = CardColorHelper.postponedLight[0]; // Purplish
        icon = Icons.calendar_view_week;
        displayType = 'Weekly';
        break;
      case 'long_goal':
        gradientColors = CardColorHelper.highPriorityLight[2]; // Orange/Pink
        icon = Icons.flag_outlined;
        displayType = 'Goal';
        break;
      case 'bucket':
        gradientColors = CardColorHelper.inProgressLight[0]; // Blueish
        icon = Icons.inbox_outlined;
        displayType = 'Bucket';
        break;
      default:
        gradientColors = CardColorHelper.mediumPriorityLight[0];
        icon = Icons.task_alt;
        displayType = 'Task';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            displayType,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          // Try to show a tiny bit of the sourceData (like the goal title) if available
          if (post.sourceData != null && post.sourceData!['title'] != null)
            Text(
              post.sourceData!['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

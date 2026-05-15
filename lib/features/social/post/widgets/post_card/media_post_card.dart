import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';

// Import your existing models, providers, and utilities
import '../../../../../media_utility/media_asset_model.dart';
import '../../../../../media_utility/media_display.dart';
import '../../models/post_model.dart';
import '../base_post_card.dart';
import '../helper/post_content.dart';

class MediaPostCard extends StatefulWidget {
  final FeedPost post;
  final String currentUserId;
  final bool isInDetailView;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;

  const MediaPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isInDetailView = false,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
  });

  @override
  State<MediaPostCard> createState() => _MediaPostCardState();
}

class _MediaPostCardState extends State<MediaPostCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  // Animation controllers
  late AnimationController _likeAnimationController;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.heavyImpact();
    setState(() => _showLikeAnimation = true);
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse().then((_) {
        if (mounted) setState(() => _showLikeAnimation = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaList = widget.post.post.media;

    final mediaFiles = mediaList
        .map(
          (m) => EnhancedMediaFile.fromUrl(
            id: m.id.isNotEmpty ? m.id : m.url,
            url: m.url,
            fileName: m.url.split('/').last,
            thumbnailUrl: m.thumbnail,
          ),
        )
        .toList();

    return BasePostCard(
      post: widget.post,
      currentUserId: widget.currentUserId,
      onTap: widget.onTap,
      onCommentPressed: widget.onCommentPressed,
      onMenuPressed: widget.onMenuPressed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post text content
          if (widget.post.post.caption?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: PostContent(
                text: widget.post.post.caption!,
                hashtags: widget.post.post.hashtags,
                mentions: widget.post.post.mentionedUsernames,
                isExpanded: _isExpanded,
                onExpandToggle: () =>
                    setState(() => _isExpanded = !_isExpanded),
                maxLines: widget.isInDetailView ? null : 3,
              ),
            ),

          // Media Section
          if (mediaList.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    EnhancedMediaDisplay(
                      mediaFiles: mediaFiles,
                      config: MediaDisplayConfig(
                        layoutMode: mediaFiles.length == 1
                            ? MediaLayoutMode.single
                            : MediaLayoutMode.carousel,
                        mediaBucket: MediaBucket.socialMedia,
                        allowFullScreen: true,
                        allowDelete: false,
                        maxHeight: 380, // Reduced height as requested
                      ),
                    ),

                    // Like animation on double tap
                    if (_showLikeAnimation)
                      Center(
                        child: AnimatedBuilder(
                          animation: _likeAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + _likeAnimationController.value * 0.5,
                              child: Opacity(
                                opacity: 1.0 - _likeAnimationController.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: colorScheme.primary,
                                    size: 60,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

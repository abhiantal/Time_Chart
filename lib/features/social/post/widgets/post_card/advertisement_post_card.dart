import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';
import '../base_post_card.dart';
import '../../../../../media_utility/media_display.dart';
import '../../../../../media_utility/media_asset_model.dart';

class AdvertisementPostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUserId;
  final bool isInDetailView;
  final VoidCallback? onTap;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onMenuPressed;

  const AdvertisementPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isInDetailView = false,
    this.onTap,
    this.onCommentPressed,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adData = post.post.adData;

    final mediaFiles = post.post.media.items
        .map(
          (m) => EnhancedMediaFile.fromUrl(
            id: m.id.isNotEmpty ? m.id : m.url,
            url: m.url,
            thumbnailUrl: m.thumbnail,
          ),
        )
        .toList();

    return BasePostCard(
      post: post,
      currentUserId: currentUserId,
      onTap: onTap,
      onCommentPressed: onCommentPressed,
      onMenuPressed: onMenuPressed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Header / Brand Info (Overriding default header style if needed,
          // but BasePostCard handles the standard header)

          // Caption
          if (post.post.caption?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post.post.caption!,
                style: theme.textTheme.bodyMedium,
              ),
            ),

          // Media Display
          if (mediaFiles.isNotEmpty)
            Stack(
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
                    maxHeight: 400,
                  ),
                ),

                // Premium "Sponsored" Tag on media
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sponsored',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Action Bar (CTA)
          if (adData != null) _buildAdActionBar(context, theme, adData),
        ],
      ),
    );
  }

  Widget _buildAdActionBar(
    BuildContext context,
    ThemeData theme,
    AdData adData,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  adData.advertiserName ?? 'Sponsored Content',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (adData.title.isNotEmpty)
                  Text(
                    adData.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Ad CTA logic is usually handled in PostAdBadge or similar
              // We reuse the badge logic or trigger it here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              adData.ctaText ?? 'Learn More',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

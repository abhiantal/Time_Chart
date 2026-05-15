// ================================================================
// FILE: lib/media_utility/media_display.dart
// COMPLETELY FIXED — Proper URL resolution, video support, offline display
// ================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:the_time_chart/media_utility/media_asset_model.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart' as vc;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'animated_audio_player.dart';
import 'universal_media_service.dart';
export 'media_asset_model.dart';
export 'animated_audio_player.dart' show AudioPlayerStyle;

// ================================================================
// COMPATIBILITY HELPERS
// ================================================================

List<EnhancedMediaFile> convertUrlsToEnhancedMedia(List<String> urls) {
  return urls.asMap().entries.map((entry) {
    return EnhancedMediaFile.fromUrl(
      id: '${entry.value}_${entry.key}',
      url: entry.value,
    );
  }).toList();
}

class FullScreenViewer extends FullScreenMediaViewer {
  const FullScreenViewer({
    super.key,
    required super.mediaFiles,
    required super.initialIndex,
    required super.config,
  });
}

// ================================================================
// DISPLAY CONFIGURATION
// ================================================================

class MediaDisplayConfig {
  final MediaLayoutMode layoutMode;
  final double borderRadius;
  final double spacing;
  final bool showFileName;
  final bool showFileSize;
  final bool showDate;
  final bool allowDelete;
  final bool allowFullScreen;
  final bool autoPlay;
  final BoxFit imageFit;
  final int gridColumns;
  final double? maxHeight;
  final bool enableImageRotation;
  final bool enableAnimations;
  final AudioPlayerStyle audioStyle;
  final bool isMe;
  final bool showDetails;
  final bool transparentBackground;
  // NEW: provide bucket context so URL resolver works correctly for private buckets
  final MediaBucket? mediaBucket;

  const MediaDisplayConfig({
    this.layoutMode = MediaLayoutMode.grid,
    this.borderRadius = 16,
    this.spacing = 12,
    this.showFileName = true,
    this.showFileSize = true,
    this.showDate = true,
    this.allowDelete = true,
    this.allowFullScreen = true,
    this.autoPlay = false,
    this.imageFit = BoxFit.cover,
    this.gridColumns = 3,
    this.maxHeight,
    this.enableImageRotation = false,
    this.enableAnimations = true,
    this.audioStyle = AudioPlayerStyle.card,
    this.isMe = false,
    this.showDetails = true,
    this.transparentBackground = false,
    this.mediaBucket,
  });
}

enum MediaLayoutMode { grid, list, carousel, single, masonry }

// ================================================================
// ENHANCED MEDIA DISPLAY WIDGET
// ================================================================

class EnhancedMediaDisplay extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final MediaDisplayConfig config;
  final Function(String mediaId)? onDelete;
  final VoidCallback? onAddMedia;
  final bool isLoading;
  final String? emptyMessage;

  const EnhancedMediaDisplay({
    super.key,
    required this.mediaFiles,
    this.config = const MediaDisplayConfig(),
    this.onDelete,
    this.onAddMedia,
    this.isLoading = false,
    this.emptyMessage,
  });

  @override
  State<EnhancedMediaDisplay> createState() => _EnhancedMediaDisplayState();
}

class _EnhancedMediaDisplayState extends State<EnhancedMediaDisplay>
    with TickerProviderStateMixin {
  late AnimationController _entryAnimController;
  late AnimationController _layoutTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  MediaLayoutMode? _previousLayoutMode;

  @override
  void initState() {
    super.initState();
    _entryAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _layoutTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimController, curve: Curves.easeOutBack),
    );
    if (widget.config.enableAnimations) _entryAnimController.forward();
  }

  @override
  void didUpdateWidget(EnhancedMediaDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.layoutMode != widget.config.layoutMode) {
      _previousLayoutMode = oldWidget.config.layoutMode;
      _layoutTransitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entryAnimController.dispose();
    _layoutTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoadingState();
    if (widget.mediaFiles.isEmpty) return _buildEmptyState();

    return widget.config.enableAnimations
        ? FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildMediaLayout(),
            ),
          )
        : _buildMediaLayout();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading media...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              widget.emptyMessage ?? 'No media files',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.onAddMedia != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAddMedia!();
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Media'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaLayout() {
    if (_previousLayoutMode != null && widget.config.enableAnimations) {
      return AnimatedBuilder(
        animation: _layoutTransitionController,
        builder: (context, _) {
          return Stack(
            children: [
              if (_layoutTransitionController.value < 0.5)
                Opacity(
                  opacity: 1.0 - (_layoutTransitionController.value * 2),
                  child: _buildLayoutForMode(_previousLayoutMode!),
                ),
              if (_layoutTransitionController.value >= 0.5)
                Opacity(
                  opacity: (_layoutTransitionController.value - 0.5) * 2,
                  child: _buildLayoutForMode(widget.config.layoutMode),
                ),
            ],
          );
        },
      );
    }
    return _buildLayoutForMode(widget.config.layoutMode);
  }

  Widget _buildLayoutForMode(MediaLayoutMode mode) {
    switch (mode) {
      case MediaLayoutMode.grid:
        return _buildGrid();
      case MediaLayoutMode.list:
        return _buildList();
      case MediaLayoutMode.carousel:
        return _buildCarousel();
      case MediaLayoutMode.single:
        return _buildSingle();
      case MediaLayoutMode.masonry:
        return _buildMasonry();
    }
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUnbounded = constraints.maxWidth == double.infinity;
        final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.config.gridColumns,
            crossAxisSpacing: widget.config.spacing,
            mainAxisSpacing: widget.config.spacing,
          ),
          itemCount: widget.mediaFiles.length,
          itemBuilder: (context, index) => _MediaTile(
            media: widget.mediaFiles[index],
            config: widget.config,
            index: index,
            onTap: () => _openFullScreen(index),
            onDelete: widget.config.allowDelete
                ? () => _confirmDelete(widget.mediaFiles[index].id)
                : null,
          ),
        );

        if (isUnbounded) {
          return SizedBox(width: 300, child: grid);
        }
        return grid;
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.mediaFiles.length,
      separatorBuilder: (_, __) => SizedBox(height: widget.config.spacing),
      itemBuilder: (context, index) {
        final media = widget.mediaFiles[index];
        if (media.type == MediaFileType.audio) {
          return Dismissible(
            key: Key(media.id),
            direction: widget.config.allowDelete
                ? DismissDirection.endToStart
                : DismissDirection.none,
            onDismissed: (_) {
              HapticFeedback.mediumImpact();
              widget.onDelete?.call(media.id);
            },
            background: _buildDismissBackground(),
            child: AnimatedAudioPlayer(
              url: media.url,
              isLocal: media.isLocal,
              title: media.fileName,
              subtitle: 'Tap to play',
              height: 180,
              showWaveform: true,
              style: widget.config.audioStyle,
              isMe: widget.config.isMe,
              showDetails: widget.config.showDetails,
              transparentBackground: widget.config.transparentBackground,
            ),
          );
        }
        return _MediaListTile(
          media: media,
          config: widget.config,
          index: index,
          onTap: () => _openFullScreen(index),
          onDelete: widget.config.allowDelete
              ? () => _confirmDelete(media.id)
              : null,
        );
      },
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: widget.config.spacing / 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildCarousel() {
    return _MediaCarousel(
      mediaFiles: widget.mediaFiles,
      config: widget.config,
      onTap: _openFullScreen,
      onDelete: widget.config.allowDelete ? _confirmDelete : null,
    );
  }

  Widget _buildSingle() {
    if (widget.mediaFiles.isEmpty) return const SizedBox();
    final media = widget.mediaFiles[0];
    if (media.type == MediaFileType.audio) {
      return AnimatedAudioPlayer(
        url: media.url,
        isLocal: media.isLocal,
        title: media.fileName,
        subtitle: 'Audio message',
        height: widget.config.audioStyle == AudioPlayerStyle.bubble
            ? null
            : 180,
        style: widget.config.audioStyle,
        isMe: widget.config.isMe,
        borderRadius: widget.config.borderRadius,
        showDetails: widget.config.showDetails,
        transparentBackground: widget.config.transparentBackground,
        timestamp: media.uploadedAt,
      );
    }
    return SizedBox(
      height: widget.config.maxHeight ?? 220,
      child: _MediaTile(
        media: media,
        config: widget.config,
        index: 0,
        onTap: () => _openFullScreen(0),
        onDelete: widget.config.allowDelete
            ? () => _confirmDelete(media.id)
            : null,
      ),
    );
  }

  Widget _buildMasonry() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUnbounded = constraints.maxWidth == double.infinity;
        final masonry = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: widget.mediaFiles.length,
          itemBuilder: (context, index) => _MediaTile(
            media: widget.mediaFiles[index],
            config: widget.config,
            index: index,
            onTap: () => _openFullScreen(index),
            onDelete: widget.config.allowDelete
                ? () => _confirmDelete(widget.mediaFiles[index].id)
                : null,
          ),
        );

        if (isUnbounded) {
          return SizedBox(width: 300, child: masonry);
        }
        return masonry;
      },
    );
  }

  Future<void> _confirmDelete(String mediaId) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call(mediaId);
  }

  void _openFullScreen(int index) {
    if (!widget.config.allowFullScreen) return;
    if (!widget.mediaFiles[index].supportsFullScreen) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => FullScreenMediaViewer(
          mediaFiles: widget.mediaFiles,
          initialIndex: index,
          config: widget.config,
        ),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MEDIA TILE — with smart URL resolution
// ================================================================

class _MediaTile extends StatefulWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const _MediaTile({
    required this.media,
    required this.config,
    required this.onTap,
    required this.index,
    this.onDelete,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final child = GestureDetector(
      onTapDown: (_) {
        if (widget.config.enableAnimations) {
          _pressController.forward();
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        if (widget.config.enableAnimations) {
          _pressController.reverse();
          setState(() => _isPressed = false);
        }
      },
      onTapCancel: () {
        if (widget.config.enableAnimations) {
          _pressController.reverse();
          setState(() => _isPressed = false);
        }
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.08),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(context),
                if (widget.onDelete != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DeleteButton(onDelete: widget.onDelete!),
                  ),
                _buildOverlay(),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.config.enableAnimations) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(
          milliseconds: 300 + (widget.index * 40).clamp(0, 400),
        ),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        ),
        child: child,
      );
    }
    return child;
  }

  Widget _buildMediaContent(BuildContext context) {
    switch (widget.media.type) {
      case MediaFileType.image:
        return _SmartImageWidget(
          media: widget.media,
          config: widget.config,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.video:
        return _SmartVideoThumbnail(
          media: widget.media,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.audio:
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.media.fileName ?? 'Audio',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case MediaFileType.document:
        return Container(
          color: Colors.blue.shade50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_rounded,
                size: 40,
                color: Colors.blue.shade700,
              ),
              if (widget.media.fileName != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.media.fileName!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildOverlay() {
    if (!widget.config.showDate) return const SizedBox();
    if (widget.media.type == MediaFileType.audio) return const SizedBox();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Row(
          children: [
            _getMediaIcon(),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatDate(widget.media.uploadedAt),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0)
        return diff.inMinutes == 0 ? 'Just now' : '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _getMediaIcon() {
    switch (widget.media.type) {
      case MediaFileType.video:
        return const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 16,
        );
      case MediaFileType.document:
        return const Icon(
          Icons.description_rounded,
          color: Colors.white,
          size: 16,
        );
      default:
        return const SizedBox();
    }
  }
}

// ================================================================
// SMART IMAGE WIDGET — handles local + network + storage paths
// ================================================================

class _SmartImageWidget extends StatelessWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final MediaBucket? bucket;

  const _SmartImageWidget({
    required this.media,
    required this.config,
    this.bucket,
  });

  @override
  Widget build(BuildContext context) {
    // If already local, display immediately with no network call
    if (media.isLocal || _isLocalPath(media.url)) {
      return _buildLocalImage(media.url);
    }

    // For storage paths or HTTP URLs, use the resolver
    return _ResolvedMediaWidget(
      pathOrUrl: media.url,
      bucket: bucket,
      builder: (resolvedUrl, isLocal) {
        if (isLocal) return _buildLocalImage(resolvedUrl);
        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: config.imageFit,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (_, __, ___) => _buildError(),
          placeholder: (_, __) => _buildPlaceholder(context),
        );
      },
      loadingBuilder: () => _buildPlaceholder(context),
      errorBuilder: () => _buildError(),
    );
  }

  Widget _buildLocalImage(String path) {
    final filePath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    return Image.file(
      File(filePath),
      fit: config.imageFit,
      errorBuilder: (_, __, ___) => _buildError(),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary.withOpacity(0.5),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Container(
    color: Colors.grey.shade200,
    alignment: Alignment.center,
    child: const FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    ),
  );

  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');
}

// ================================================================
// LOCAL VIDEO THUMBNAIL GENERATOR
// ================================================================

class _LocalVideoThumbnail extends StatefulWidget {
  final String videoPath;
  const _LocalVideoThumbnail({required this.videoPath});

  @override
  State<_LocalVideoThumbnail> createState() => _LocalVideoThumbnailState();
}

class _LocalVideoThumbnailState extends State<_LocalVideoThumbnail> {
  File? _thumbnailFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnail = await vc.VideoCompress.getFileThumbnail(
        widget.videoPath,
        quality: 50,
        position: -1, // default to first frame
      );
      if (mounted) {
        setState(() {
          _thumbnailFile = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }

    if (_thumbnailFile != null && _thumbnailFile!.existsSync()) {
      return Image.file(
        _thumbnailFile!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black87,
      child: const Icon(
        Icons.movie_creation_outlined,
        color: Colors.white24,
        size: 48,
      ),
    );
  }
}

// ================================================================
// SMART VIDEO THUMBNAIL
// ================================================================

class _SmartVideoThumbnail extends StatelessWidget {
  final EnhancedMediaFile media;
  final MediaBucket? bucket;

  const _SmartVideoThumbnail({required this.media, this.bucket});

  @override
  Widget build(BuildContext context) {
    if (media.isLocal || _isLocalPath(media.url)) {
      final path = media.url.startsWith('file://')
          ? Uri.parse(media.url).toFilePath()
          : media.url;
      return Stack(
        fit: StackFit.expand,
        children: [
          _LocalVideoThumbnail(videoPath: path),
          _buildPlayIcon(),
        ],
      );
    }

    return _ResolvedMediaWidget(
      pathOrUrl: media.url,
      bucket: bucket,
      builder: (resolvedUrl, isLocal) {
        if (media.thumbnailUrl != null && media.thumbnailUrl!.isNotEmpty) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _ResolvedMediaWidget(
                pathOrUrl: media.thumbnailUrl!,
                bucket: bucket,
                builder: (thumbUrl, thumbIsLocal) {
                  if (thumbIsLocal)
                    return Image.file(File(thumbUrl), fit: BoxFit.cover);
                  return CachedNetworkImage(
                    imageUrl: thumbUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.black12),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.black26),
                  );
                },
                loadingBuilder: () => Container(
                  color: Colors.black12,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: () => Container(color: Colors.black26),
              ),
              _buildPlayIcon(),
            ],
          );
        }

        // If no thumbnail but we have a resolved local path (cached video), generate thumbnail
        if (isLocal) {
          final cleanPath = resolvedUrl.startsWith('file://')
              ? Uri.parse(resolvedUrl).toFilePath()
              : resolvedUrl;
          return Stack(
            fit: StackFit.expand,
            children: [
              _LocalVideoThumbnail(videoPath: cleanPath),
              _buildPlayIcon(),
            ],
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black87,
              child: const Icon(
                Icons.movie_creation_outlined,
                color: Colors.white24,
                size: 48,
              ),
            ),
            _buildPlayIcon(),
          ],
        );
      },
      loadingBuilder: () => Container(
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      ),
      errorBuilder: () => Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black87),
          _buildPlayIcon(),
        ],
      ),
    );
  }

  Widget _buildPlayIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');
}

// ================================================================
// RESOLVED MEDIA WIDGET — async URL resolution with proper states
// FIXED: doesn't flash or re-resolve unnecessarily
// ================================================================

class _ResolvedMediaWidget extends StatefulWidget {
  final String pathOrUrl;
  final MediaBucket? bucket;
  final Widget Function(String resolvedUrl, bool isLocal) builder;
  final Widget Function() loadingBuilder;
  final Widget Function() errorBuilder;

  const _ResolvedMediaWidget({
    required this.pathOrUrl,
    required this.builder,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.bucket,
  });

  @override
  State<_ResolvedMediaWidget> createState() => _ResolvedMediaWidgetState();
}

class _ResolvedMediaWidgetState extends State<_ResolvedMediaWidget> {
  String? _resolvedUrl;
  bool _isLocal = false;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(_ResolvedMediaWidget old) {
    super.didUpdateWidget(old);
    if (old.pathOrUrl != widget.pathOrUrl) {
      setState(() {
        _resolvedUrl = null;
        _isLocal = false;
        _hasError = false;
        _isLoading = true;
      });
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = widget.pathOrUrl;

    // Fast path: already local or http
    if (url.startsWith('/') || url.startsWith('file://')) {
      final filePath = url.startsWith('file://')
          ? Uri.parse(url).toFilePath()
          : url;
      if (File(filePath).existsSync()) {
        if (mounted)
          setState(() {
            _resolvedUrl = url;
            _isLocal = true;
            _isLoading = false;
          });
        return;
      }
    }

    if (url.startsWith('http')) {
      if (mounted)
        setState(() {
          _resolvedUrl = url;
          _isLocal = false;
          _isLoading = false;
        });
      return;
    }

    // Storage path — needs resolution
    try {
      String? resolved;
      if (widget.bucket != null) {
        resolved = await mediaService.resolveUrl(url, widget.bucket!);
      } else {
        resolved = await mediaService.getValidSignedUrl(url);
      }

      if (resolved == null) {
        if (mounted)
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        return;
      }

      final isLocal =
          resolved.startsWith('/') || resolved.startsWith('file://');
      if (mounted)
        setState(() {
          _resolvedUrl = resolved;
          _isLocal = isLocal;
          _isLoading = false;
        });

      // Listen for URL updates (e.g., after background upload completes)
      mediaService.urlUpdates.listen((event) {
        if (event.storagePath == url && mounted) {
          final newUrl = event.newUrl;
          final newIsLocal =
              newUrl.startsWith('/') || newUrl.startsWith('file://');
          setState(() {
            _resolvedUrl = newUrl;
            _isLocal = newIsLocal;
          });
        }
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return widget.loadingBuilder();
    if (_hasError || _resolvedUrl == null) return widget.errorBuilder();
    return widget.builder(_resolvedUrl!, _isLocal);
  }
}

// ================================================================
// LIST TILE
// ================================================================

class _MediaListTile extends StatelessWidget {
  final EnhancedMediaFile media;
  final MediaDisplayConfig config;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const _MediaListTile({
    required this.media,
    required this.config,
    required this.onTap,
    required this.index,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _MediaTile(
                      media: media,
                      config: config,
                      index: index,
                      onTap: onTap,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.fileName ?? 'Unknown File',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (config.showFileSize && media.size != null)
                            _formatFileSize(media.size!),
                          if (config.showDate && media.uploadedAt != null)
                            _formatDate(media.uploadedAt!),
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (config.enableAnimations) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 400)),
        curve: Curves.easeOut,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        ),
        child: tile,
      );
    }
    return tile;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ================================================================
// DELETE BUTTON
// ================================================================

class _MediaCarousel extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final MediaDisplayConfig config;
  final Function(int) onTap;
  final Function(String)? onDelete;

  const _MediaCarousel({
    required this.mediaFiles,
    required this.config,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaFiles.isEmpty) return const SizedBox();
    
    final theme = Theme.of(context);
    final height = widget.config.maxHeight ?? 300.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaFiles.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.mediaFiles.length > 1 ? 4.0 : 0.0,
                    ),
                    child: _MediaTile(
                      media: widget.mediaFiles[index],
                      config: widget.config,
                      index: index,
                      onTap: () => widget.onTap(index),
                      onDelete: widget.onDelete != null
                          ? () => widget.onDelete!(widget.mediaFiles[index].id)
                          : null,
                    ),
                  );
                },
              ),
            ),
            
            // Index Indicator (e.g., 1/5)
            if (widget.mediaFiles.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.mediaFiles.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Dot Indicators
        if (widget.mediaFiles.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.mediaFiles.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 8 : 6,
                  height: _currentIndex == index ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onDelete();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
      ),
    );
  }
}

// ================================================================
// FULL SCREEN VIEWER
// ================================================================

class FullScreenMediaViewer extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;
  final int initialIndex;
  final MediaDisplayConfig config;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaFiles,
    required this.initialIndex,
    required this.config,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.mediaFiles.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (context, index) {
          final media = widget.mediaFiles[index];
          return PhotoViewGalleryPageOptions.customChild(
            child: _buildFullScreenItem(media),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            heroAttributes: PhotoViewHeroAttributes(tag: media.id),
            disableGestures: media.type == MediaFileType.video,
          );
        },
        itemCount: widget.mediaFiles.length,
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          HapticFeedback.selectionClick();
        },
      ),
    );
  }

  Widget _buildFullScreenItem(EnhancedMediaFile media) {
    switch (media.type) {
      case MediaFileType.video:
        return _FullScreenVideoPlayer(
          pathOrUrl: media.url,
          isLocal: media.isLocal,
          bucket: widget.config.mediaBucket,
        );

      case MediaFileType.audio:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedAudioPlayer(
              url: media.url,
              isLocal: media.isLocal,
              title: media.fileName,
              subtitle: 'Now Playing',
              autoPlay: true,
              showWaveform: true,
              height: 220,
            ),
          ),
        );

      case MediaFileType.image:
        if (media.isLocal ||
            media.url.startsWith('/') ||
            media.url.startsWith('file://')) {
          final filePath = media.url.startsWith('file://')
              ? Uri.parse(media.url).toFilePath()
              : media.url;
          return Center(child: Image.file(File(filePath), fit: BoxFit.contain));
        }
        if (media.url.startsWith('http')) {
          return Center(
            child: CachedNetworkImage(
              imageUrl: media.url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        }
        // Storage path — resolve first
        return _ResolvedMediaWidget(
          pathOrUrl: media.url,
          bucket: widget.config.mediaBucket,
          builder: (resolvedUrl, isLocal) {
            if (isLocal) {
              final filePath = resolvedUrl.startsWith('file://')
                  ? Uri.parse(resolvedUrl).toFilePath()
                  : resolvedUrl;
              return Center(
                child: Image.file(File(filePath), fit: BoxFit.contain),
              );
            }
            return Center(
              child: CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: () => const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 64,
            ),
          ),
        );

      default:
        return const Center(
          child: Icon(
            Icons.description_rounded,
            color: Colors.white54,
            size: 64,
          ),
        );
    }
  }
}

// ================================================================
// FULL SCREEN VIDEO PLAYER — Fixed with proper URL resolution
// ================================================================

class _FullScreenVideoPlayer extends StatefulWidget {
  final String pathOrUrl;
  final bool isLocal;
  final MediaBucket? bucket;

  const _FullScreenVideoPlayer({
    required this.pathOrUrl,
    this.isLocal = false,
    this.bucket,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isEnded = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveAndInit();
  }

  Future<void> _resolveAndInit() async {
    try {
      String effectiveUrl = widget.pathOrUrl;

      // Resolve storage path to playable URL
      if (!effectiveUrl.startsWith('http') &&
          !effectiveUrl.startsWith('/') &&
          !effectiveUrl.startsWith('file://')) {
        String? resolved;
        if (widget.bucket != null) {
          resolved = await mediaService.resolveUrl(
            effectiveUrl,
            widget.bucket!,
          );
        } else {
          resolved = await mediaService.getValidSignedUrl(effectiveUrl);
        }
        if (resolved != null) effectiveUrl = resolved;
      }

      // Strip file:// prefix for VideoPlayerController.file
      if (effectiveUrl.startsWith('file://')) {
        effectiveUrl = Uri.parse(effectiveUrl).toFilePath();
      }

      VideoPlayerController controller;
      if (widget.isLocal || effectiveUrl.startsWith('/')) {
        final file = File(effectiveUrl);
        if (!file.existsSync()) {
          if (mounted)
            setState(() {
              _hasError = true;
              _errorMessage = 'Video file not found';
            });
          return;
        }
        controller = VideoPlayerController.file(file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(effectiveUrl));
      }

      controller.addListener(_onControllerUpdate);
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
          // _isPlaying will be updated by VisibilityDetector
        });
      } else {
        controller.dispose();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
    }
  }

  void _onControllerUpdate() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur) {
      if (mounted && !_isEnded)
        setState(() {
          _isPlaying = false;
          _isEnded = true;
          _showControls = true;
        });
    }
    if (_controller!.value.hasError && mounted && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _controller!.value.errorDescription;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load video',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_initialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return VisibilityDetector(
      key: Key('fullscreen_video_${widget.pathOrUrl}'),
      onVisibilityChanged: (info) {
        if (mounted && _controller != null) {
          final isVisible = info.visibleFraction > 0.5;
          if (isVisible && !_isEnded && _isPlaying) {
            _controller?.play();
          } else if (isVisible && !_isEnded && !_isPlaying) {
            // Let it be paused if user specifically paused it
            // But if it's the first time it becomes visible, play it
            if (_controller!.value.position == Duration.zero) {
              _controller?.play();
              setState(() => _isPlaying = true);
            }
          } else {
            _controller?.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _showControls = !_showControls);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton(
                          iconSize: 72,
                          color: Colors.white,
                          icon: Icon(
                            _isEnded
                                ? Icons.replay_circle_filled_rounded
                                : (_isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_isEnded) {
                                _controller!.seekTo(Duration.zero);
                                _controller!.play();
                                _isPlaying = true;
                                _isEnded = false;
                              } else if (_controller!.value.isPlaying) {
                                _controller!.pause();
                                _isPlaying = false;
                              } else {
                                _controller!.play();
                                _isPlaying = true;
                              }
                            });
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

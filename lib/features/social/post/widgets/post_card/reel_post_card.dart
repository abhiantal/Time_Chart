import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/post/widgets/helper/post_bottom_share_sheet.dart';
import 'package:the_time_chart/features/social/post/widgets/helper/post_bottom_menu_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../../media_utility/universal_media_service.dart';
import '../../../../../../widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../../../saves/providers/save_provider.dart';
import '../../../reactions/providers/reaction_provider.dart';
import '../../../follow/providers/follow_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/post_model.dart';

class ReelPostCard extends StatefulWidget {
  final FeedPost post;
  final String currentUserId;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNextReel;
  final VoidCallback? onPreviousReel;

  const ReelPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onCommentPressed,
    this.onSharePressed,
    this.onMenuPressed,
    this.onNextReel,
    this.onPreviousReel,
  });

  @override
  State<ReelPostCard> createState() => _ReelPostCardState();
}

class _ReelPostCardState extends State<ReelPostCard>
    with TickerProviderStateMixin {
  late AnimationController _doubleTapController;
  late Animation<double> _doubleTapAnimation;
  bool _showLikeAnimation = false;
  String? _validAvatarUrl;
  final UniversalMediaService _mediaService = UniversalMediaService();

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMuted = false;
  bool _isPaused = false;

  // Animation controllers
  late AnimationController _musicNoteController;

  // State
  bool _isFollowing = false;
  bool _isSaved = false;
  bool _showPlayPauseHint = false;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _doubleTapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doubleTapController, curve: Curves.elasticOut),
    );

    _musicNoteController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    if (widget.post.profileUrl != null) {
      _loadReelAvatar();
    }

    _initializeVideo();
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    _musicNoteController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadReelAvatar() async {
    final validUrl = await _mediaService.getValidAvatarUrl(
      widget.post.profileUrl,
    );
    if (mounted) {
      setState(() => _validAvatarUrl = validUrl);
    }
  }

  Future<void> _initializeVideo() async {
    final media = widget.post.post.media;
    if (media.isEmpty) return;

    try {
      final videoMedia = media.firstWhere(
        (m) => m.type == 'video' || m.type == 'reel',
        orElse: () => media.first,
      );

      String effectiveUrl = videoMedia.url;

      // Use UniversalMediaService to resolve Supabase storage paths
      if (!effectiveUrl.startsWith('http') &&
          !effectiveUrl.startsWith('/') &&
          !effectiveUrl.startsWith('file://')) {
        final resolved = await _mediaService.resolveUrl(
          effectiveUrl,
          MediaBucket.socialMedia,
        );
        if (resolved != null) {
          effectiveUrl = resolved;
        }
      }

      // Handle local files vs network files
      if (effectiveUrl.startsWith('file://')) {
        effectiveUrl = Uri.parse(effectiveUrl).toFilePath();
      }

      VideoPlayerController controller;
      if (effectiveUrl.startsWith('/')) {
        final file = File(effectiveUrl);
        if (!file.existsSync()) {
          logW('Local video file not found: $effectiveUrl');
          return;
        }
        controller = VideoPlayerController.file(file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(effectiveUrl));
      }

      await controller.initialize();
      controller.setLooping(true);

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitialized = true;
        });
        // Let VisibilityDetector handle play()
      } else {
        controller.dispose();
      }
    } catch (e) {
      logE('Error initializing reel video', error: e);
    }
  }

  void _handleDoubleTap() {
    HapticFeedback.heavyImpact();
    setState(() => _showLikeAnimation = true);
    _doubleTapController.forward().then((_) {
      _doubleTapController.reverse().then((_) {
        if (mounted) setState(() => _showLikeAnimation = false);
      });
    });

    if (!widget.post.hasReacted) {
      context.read<ReactionProvider>().togglePostLike(widget.post.post.id);
    }
  }

  void _handleTap() {
    if (_videoController != null) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPaused = true;
          _showPlayPauseHint = true;
        } else {
          _videoController!.play();
          _isPaused = false;
          _showPlayPauseHint = true;
        }
      });

      // Hide hint after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _showPlayPauseHint = false);
        }
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    HapticFeedback.lightImpact();
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
    HapticFeedback.lightImpact();
    context.read<SaveProvider>().toggleSave(widget.post.post.id);
  }

  void _showPostMenu() {
    PostBottomSheet.show(
      context: context,
      postId: widget.post.post.id,
      userId: widget.post.post.userId,
      currentUserId: widget.currentUserId,
      username: widget.post.username ?? '',
      onEdit: () => PostBottomSheet.navigateToEditPost(context, widget.post),
      onDelete: () async {
        final success = await context.read<PostProvider>().deletePost(
          widget.post.post.id,
        );
        if (success && mounted) {
          AppSnackbar.success('Reel deleted successfully');
        }
      },
      onShare: () {
        PostBottomShareSheet.show(context, widget.post);
      },
      onReport: () {
        PostBottomSheet.showReportDialog(
          context,
          onSubmitted: (reason) async {
            await context.read<PostProvider>().reportPost(
              postId: widget.post.post.id,
              reason: reason,
            );
          },
        );
      },
      onBlock: () async {
        await context.read<FollowProvider>().blockUser(widget.post.post.userId);
      },
      onCopyLink: () async {
        await Clipboard.setData(
          ClipboardData(text: 'https://app.com/post/${widget.post.post.id}'),
        );
        if (mounted) {
          AppSnackbar.success('Link copied to clipboard');
        }
      },
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final formatted = (count / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(count / 1000).floor()}K'
          : '${formatted}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  void _navigateToComments() {
    context.pushNamed(
      'comments',
      extra: {
        'targetType': 'post',
        'targetId': widget.post.post.id,
        'currentUserId': widget.currentUserId,
      },
    );
  }

  Widget _buildReelActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post.post;
    final isOwnPost = post.userId == widget.currentUserId;
    final hasVideo = _isVideoInitialized && _videoController != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      color: Colors.black,
      margin: const EdgeInsets.only(bottom: 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen reel player
          VisibilityDetector(
            key: Key('reel_${widget.post.post.id}'),
            onVisibilityChanged: (info) {
              if (mounted) {
                final isVisible = info.visibleFraction > 0.5;
                if (isVisible && !_isPaused) {
                  _videoController?.play();
                } else {
                  _videoController?.pause();
                }
              }
            },
            child: GestureDetector(
              onDoubleTap: _handleDoubleTap,
              onTap: _handleTap,
              child: Container(
                color: Colors.black,
                child: hasVideo
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : _buildPlaceholderMedia(),
              ),
            ),
          ),

          // Gradient overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Video progress indicator
          if (hasVideo)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value:
                    _videoController!.value.position.inMilliseconds /
                    _videoController!.value.duration.inMilliseconds,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),

          // Like Animation
          if (_showLikeAnimation)
            Center(
              child: AnimatedBuilder(
                animation: _doubleTapAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_doubleTapAnimation.value * 0.5),
                    child: Opacity(
                      opacity: 1.0 - _doubleTapAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: theme.colorScheme.primary,
                          size: 100,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Play/Pause hint overlay
          if (_showPlayPauseHint)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayPauseHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),

                // Camera/Upload button (optional feature)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.photo_camera_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      // Navigate to camera/reel upload
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Menu button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _showPostMenu,
                  ),
                ),
              ],
            ),
          ),

          // Bottom info section
          Positioned(
            bottom: 100,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    // Avatar with ring
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: _buildAvatar(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Username and follow button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.post.displayName?.isNotEmpty == true) ? widget.post.displayName! : (widget.post.username ?? 'user'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (widget.post.displayName?.isNotEmpty == true && widget.post.displayName != widget.post.username)
                             Text(
                                '@${widget.post.username}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                             ),
                          if (post.location != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    post.location!.name ?? '',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    if (!isOwnPost)
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isFollowing
                                ? Colors.transparent
                                : Colors.blue,
                            border: _isFollowing
                                ? Border.all(color: Colors.white, width: 1.5)
                                : null,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: _isFollowing ? Colors.white : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Caption
                if (post.caption?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(height: 8),

                // Music
                if (post.hasReelAudio)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _musicNoteController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                -_musicNoteController.value * 5,
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            post.reelAudio?.title ?? 'Original Audio',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildReelActionButton(
                  icon: widget.post.hasReacted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _formatCount(post.reactionsCount.total),
                  color: widget.post.hasReacted ? Colors.red : Colors.white,
                  onTap: _handleDoubleTap,
                ),
                const SizedBox(height: 20),
                _buildReelActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _formatCount(post.commentsCount),
                  onTap: widget.onCommentPressed ?? _navigateToComments,
                ),
                const SizedBox(height: 20),
                _buildReelActionButton(
                  icon: Icons.send_rounded,
                  label: _formatCount(post.sharesCount),
                  onTap: () {
                    PostBottomShareSheet.show(context, widget.post);
                  },
                ),
                const SizedBox(height: 20),
                _buildReelActionButton(
                  icon: _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: '',
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 20),

                // Mute/Unmute button
                GestureDetector(
                  onTap: _toggleMute,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildReelActionButton(
                  icon: Icons.more_horiz_rounded,
                  label: '',
                  onTap: _showPostMenu,
                ),
              ],
            ),
          ),

          // Navigation hints with animations
          if (widget.onPreviousReel != null)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (widget.onNextReel != null)
            Positioned(
              bottom: 250,
              left: 0,
              right: 0,
              child: Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final theme = Theme.of(context);

    if (_validAvatarUrl != null && _validAvatarUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: _validAvatarUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildAvatarPlaceholder(theme),
        errorWidget: (_, __, ___) => _buildAvatarPlaceholder(theme),
      );
    } else if (_validAvatarUrl != null && File(_validAvatarUrl!).existsSync()) {
      return Image.file(File(_validAvatarUrl!), fit: BoxFit.cover);
    } else {
      return _buildAvatarPlaceholder(theme);
    }
  }

  Widget _buildAvatarPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          (widget.post.username ?? '').isNotEmpty
              ? widget.post.username![0].toUpperCase()
              : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderMedia() {
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_rounded, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Unable to load reel',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

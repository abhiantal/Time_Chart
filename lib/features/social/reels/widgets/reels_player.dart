import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:the_time_chart/features/social/post/widgets/helper/post_bottom_share_sheet.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/reactions/providers/reaction_provider.dart';
import 'package:the_time_chart/features/social/saves/providers/save_provider.dart';
import 'package:the_time_chart/features/social/follow/providers/follow_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/widgets/logger.dart';

class ReelsPlayer extends StatefulWidget {
  final PostModel reel;
  final bool isActive;
  final bool autoPlay;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Function(bool)? onLikeChanged;
  final Function()? onCommentPressed;
  final Function()? onSaveChanged;

  const ReelsPlayer({
    super.key,
    required this.reel,
    this.isActive = true,
    this.autoPlay = true,
    this.onNext,
    this.onPrevious,
    this.onLikeChanged,
    this.onCommentPressed,
    this.onSaveChanged,
  });

  @override
  State<ReelsPlayer> createState() => _ReelsPlayerState();
}

class _ReelsPlayerState extends State<ReelsPlayer>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _likeAnimationController;
  late AnimationController _musicNoteController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isMuted = false;
  bool _showControls = true;
  bool _showLikeAnimation = false;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reel.hasReacted;
    _isSaved = widget.reel.hasSaved;
    _likeCount = widget.reel.likesCount;
    _commentCount = widget.reel.commentsCount;
    _commentCount = widget.reel.commentsCount;

    _initializeVideo();
    _checkFollowStatus();

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _musicNoteController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  Future<void> _checkFollowStatus() async {
    final followProvider = context.read<FollowProvider>();
    final isFollowing = await followProvider.isFollowing(widget.reel.userId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReelsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.reel.id != oldWidget.reel.id) {
      _isLiked = widget.reel.hasReacted;
      _isSaved = widget.reel.hasSaved;
      _likeCount = widget.reel.likesCount;
      _commentCount = widget.reel.commentsCount;
      _commentCount = widget.reel.commentsCount;
      _checkFollowStatus();
      
      _disposeController();
      _initializeVideo();
    }

    if (widget.isActive && !oldWidget.isActive) {
      _initializeVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      // CRITICAL: Must dispose controller to prevent BLASTBufferQueue surface exhaustion
      _disposeController();
    }
  }

  void _disposeController() {
    if (widget.reel.hasVideo && _isInitialized) {
      try {
        _controller.dispose();
      } catch (e) {
        logE('Error disposing reel video controller', error: e);
      }
      _isInitialized = false;
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _disposeController();
    _likeAnimationController.dispose();
    _musicNoteController.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.reel.media.isEmpty || !widget.reel.hasVideo) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    try {
      final url = widget.reel.media.first.url;
      VideoPlayerController controller;
      if (url.startsWith('http') || url.startsWith('https')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        controller = VideoPlayerController.file(File(url));
      }

      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      // If widget became inactive while we were initializing, dispose and return
      if (!widget.isActive) {
        controller.dispose();
        return;
      }

      _controller = controller;

      if (widget.autoPlay && widget.isActive) {
        _controller.play();
        _isPlaying = true;
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      logE('Error initializing reel video', error: e);
    }
  }

  void _play() {
    if (widget.reel.hasVideo && _isInitialized && !_isPlaying) {
      _controller.play();
      setState(() => _isPlaying = true);
    }
  }

  void _pause() {
    if (widget.reel.hasVideo && _isInitialized && _isPlaying) {
      _controller.pause();
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
    _showControlsTemporarily();
  }

  void _toggleMute() {
    if (!widget.reel.hasVideo || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
        _showLikeAnimation = true;
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse().then((_) {
            if (mounted) setState(() => _showLikeAnimation = false);
          });
        });
      } else {
        _likeCount--;
      }
    });

    widget.onLikeChanged?.call(_isLiked);
    context.read<ReactionProvider>().togglePostLike(widget.reel.id);
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    widget.onSaveChanged?.call();
    context.read<SaveProvider>().toggleSave(widget.reel.id);
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() => _isFollowLoading = true);
    final result = await context.read<FollowProvider>().toggleFollow(
      widget.reel.userId,
    );

    if (mounted) {
      setState(() {
        if (result != null) {
          _isFollowing = result.isFollowed;
        }
        _isFollowLoading = false;
      });
    }
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized && widget.reel.hasVideo) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _toggleLike,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          widget.onPrevious?.call();
        } else if (details.primaryVelocity! < 0) {
          widget.onNext?.call();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Content (Video, Image, or Text)
          if (widget.reel.hasVideo && _isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else if (widget.reel.hasMedia)
            Image.network(
              widget.reel.media.first.url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.file(
                File(widget.reel.media.first.url),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  widget.reel.caption ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                stops: const [0.7, 1.0],
              ),
            ),
          ),

          // ❤️ Like animation
          if (_showLikeAnimation)
            Center(
              child: AnimatedBuilder(
                animation: _likeAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + _likeAnimationController.value * 0.5,
                    child: Opacity(
                      opacity: 1.0 - _likeAnimationController.value,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            ),

          // ⏸️ Pause indicator
          if (!_isPlaying && _showControls)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

          // 🎵 Music note animation
          Positioned(
            bottom: 100,
            right: 16,
            child: AnimatedBuilder(
              animation: _musicNoteController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_musicNoteController.value * 20),
                  child: Opacity(
                    opacity: 1.0 - _musicNoteController.value,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),

          // 📊 Progress bar
          if (_showControls && widget.reel.hasVideo && _isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.black38,
                ),
              ),
            ),

          // User info
          Positioned(
            bottom: 100,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: widget.reel.profileUrl != null
                          ? (widget.reel.profileUrl!.startsWith('http') ||
                                        widget.reel.profileUrl!.startsWith(
                                          'https',
                                        )
                                    ? NetworkImage(widget.reel.profileUrl!)
                                    : FileImage(File(widget.reel.profileUrl!)))
                                as ImageProvider
                          : null,
                      child: widget.reel.profileUrl == null
                          ? Text(
                              widget.reel.username
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.reel.username ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (widget.reel.userId !=
                        Supabase.instance.client.auth.currentUser?.id)
                      GestureDetector(
                        onTap: _toggleFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isFollowing ? Colors.white24 : Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isFollowing ? Colors.white38 : Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: _isFollowLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.reel.caption?.isNotEmpty == true)
                  Text(
                    widget.reel.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (widget.reel.hasReelAudio)
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.reel.reelAudio?.title ?? 'Original Audio',
                          style: const TextStyle(
                            color: Colors.white,
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

          // Right side action buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(_likeCount),
                  color: _isLiked ? Colors.red : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: _formatCount(_commentCount),
                  onTap: widget.onCommentPressed ?? () {},
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.send,
                  label: '',
                  onTap: () {
                    PostBottomShareSheet.show(
                      context,
                      FeedPost(
                        post: widget.reel,
                        username: widget.reel.username,
                        profileUrl: widget.reel.profileUrl,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: '',
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  label: '',
                  onTap: _toggleMute,
                ),
              ],
            ),
          ),

          // Navigation hints
          if (widget.onPrevious != null && _showControls)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Previous', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          if (widget.onNext != null && _showControls)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Next', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
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
}

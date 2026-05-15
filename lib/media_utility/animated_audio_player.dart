// ================================================================
// FILE: lib/media_utility/animated_audio_player.dart
// Complete Animated Audio Player - Fixed AnimatedBuilder Conflict
// ================================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/logger.dart';
import 'universal_media_service.dart';

/// 🎵 ANIMATED AUDIO PLAYER
/// Complete audio player with beautiful animated UI and real audio playback
enum AudioPlayerStyle { card, bubble }

/// 🎵 ANIMATED AUDIO PLAYER
/// Complete audio player with beautiful animated UI and real audio playback
class AnimatedAudioPlayer extends StatefulWidget {
  final String url;
  final bool isLocal;
  final String? title;
  final String? subtitle;
  final bool autoPlay;
  final double? height;
  final bool showWaveform;
  final Color? primaryColor;
  final Color? accentColor;
  final double borderRadius;
  final AudioPlayerStyle style;
  final String? userAvatarUrl;
  final bool isMe;
  final DateTime? timestamp;
  final bool isRead;
  final bool isSent;
  final bool isDelivered;
  final bool showDetails;
  final bool transparentBackground;
  final Function(Duration position)? onPositionChanged;
  final Function(Duration duration)? onDurationChanged;
  final Function(PlayerState state)? onStateChanged;

  const AnimatedAudioPlayer({
    super.key,
    required this.url,
    this.isLocal = false,
    this.title,
    this.subtitle,
    this.autoPlay = false,
    this.height,
    this.showWaveform = true,
    this.primaryColor,
    this.accentColor,
    this.borderRadius = 24,
    this.style = AudioPlayerStyle.card,
    this.userAvatarUrl,
    this.isMe = false,
    this.timestamp,
    this.isRead = false,
    this.isSent = true,
    this.isDelivered = true,
    this.showDetails = true,
    this.transparentBackground = false,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onStateChanged,
  });

  @override
  State<AnimatedAudioPlayer> createState() => _AnimatedAudioPlayerState();
}

class _AnimatedAudioPlayerState extends State<AnimatedAudioPlayer>
    with TickerProviderStateMixin {
  // Audio Player
  late AudioPlayer _audioPlayer;

  // State
  bool _isPlaying = false;
  bool _isLoaded = false;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Subscriptions
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completeSubscription;

  // Animations
  late AnimationController _entryController;
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  late AnimationController _playButtonController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Waveform data
  late List<double> _waveformData;

  @override
  void initState() {
    super.initState();
    _generateWaveform();
    _initAnimations();
    _initAudio();
  }

  void _generateWaveform() {
    final seed = widget.url.hashCode;
    final random = math.Random(seed);
    _waveformData = List.generate(60, (index) {
      final base = 0.3 + (math.sin(index * 0.3) * 0.3).abs();
      final variation = random.nextDouble() * 0.3;
      return (base + variation).clamp(0.15, 0.95);
    });
  }

  void _initAnimations() {
    // Entry animation
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Waveform animation
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse animation for play button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Play button rotation/scale
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Shimmer effect for loading
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _entryController.forward();
  }

  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Listen to state changes
      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() => _isPlaying = state == PlayerState.playing);

          if (_isPlaying) {
            _playButtonController.forward();
          } else {
            _playButtonController.reverse();
          }

          widget.onStateChanged?.call(state);
        }
      });

      // Listen to duration changes
      _durationSubscription = _audioPlayer.onDurationChanged.listen((
        newDuration,
      ) {
        if (mounted) {
          setState(() => _duration = newDuration);
          widget.onDurationChanged?.call(newDuration);
        }
      });

      // Listen to position changes
      _positionSubscription = _audioPlayer.onPositionChanged.listen((
        newPosition,
      ) {
        if (mounted) {
          setState(() => _position = newPosition);
          widget.onPositionChanged?.call(newPosition);
        }
      });

      // Listen to completion
      _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      // Set source
      if (widget.isLocal) {
        String filePath = widget.url;
        if (filePath.startsWith('file://')) {
          filePath = Uri.parse(filePath).toFilePath();
        }
        final file = File(filePath);
        if (await file.exists()) {
          await _audioPlayer.setSourceDeviceFile(filePath);
        } else {
          throw Exception("File not found");
        }
      } else {
        final resolvedUrl = await UniversalMediaService().getValidSignedUrl(
          widget.url,
        );
        if (resolvedUrl != null) {
          await _audioPlayer.setSourceUrl(resolvedUrl);
        } else {
          await _audioPlayer.setSourceUrl(widget.url);
        }
      }

      if (mounted) {
        setState(() => _isLoaded = true);
      }

      if (widget.autoPlay && mounted) {
        await _audioPlayer.resume();
      }
    } catch (e) {
      logE('Audio Player Error', error: e);
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();

    _entryController.dispose();
    _waveformController.dispose();
    _pulseController.dispose();
    _playButtonController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_isLoaded || _hasError) return;

    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _seek(Duration position) async {
    if (!_isLoaded || _hasError) return;
    await _audioPlayer.seek(position);
  }

  void _onSeekStart(DragStartDetails details) {
    // Optional: pause while seeking
    HapticFeedback.selectionClick();
  }

  void _onSeekUpdate(DragUpdateDetails details, double maxWidth) {
    final progress = (details.localPosition.dx / maxWidth).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * progress).toInt(),
    );
    _seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;

    if (_hasError) {
      return _buildErrorState(isDark);
    }

    return MediaAnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: widget.style == AudioPlayerStyle.bubble
                  ? _buildBubblePlayer(isDark, primaryColor, accentColor, theme)
                  : _buildPlayerCard(isDark, primaryColor, accentColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubblePlayer(
    bool isDark,
    Color primaryColor,
    Color accentColor,
    ThemeData theme,
  ) {
    final bubbleColor = widget.transparentBackground
        ? Colors.transparent
        : (widget.isMe
              ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFE7FFDB))
              : (isDark ? const Color(0xFF303030) : Colors.white));

    final onBubbleColor = widget.isMe
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white : Colors.black87);

    final waveformColor = widget.isMe
        ? (isDark
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.15))
        : (isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1));

    final activeWaveformColor = widget.isMe
        ? (isDark ? Colors.white : (widget.primaryColor ?? primaryColor))
        : (widget.primaryColor ?? primaryColor);

    return Container(
      padding: widget.transparentBackground
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: widget.transparentBackground
          ? null
          : BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                bottomRight: Radius.circular(widget.isMe ? 4 : 16),
              ),
              boxShadow: widget.transparentBackground
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              // Play / Pause Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: onBubbleColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                    color: onBubbleColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Waveform and Progress
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onHorizontalDragUpdate: (details) =>
                              _onSeekUpdate(details, constraints.maxWidth),
                          onTapDown: (details) {
                            final progressValue =
                                (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0.0, 1.0);
                            _seek(
                              Duration(
                                milliseconds:
                                    (_duration.inMilliseconds * progressValue)
                                        .toInt(),
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              SizedBox(
                                height: 32,
                                width: double.infinity,
                                child: MediaAnimatedBuilder(
                                  animation: _waveformController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _BubbleWaveformPainter(
                                        waveformData: _waveformData,
                                        progress: _duration.inMilliseconds > 0
                                            ? _position.inMilliseconds /
                                                  _duration.inMilliseconds
                                            : 0.0,
                                        baseColor: waveformColor,
                                        activeColor: activeWaveformColor,
                                        isMe: widget.isMe,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Seek Indicator (Small Circle)
                              if (_duration.inMilliseconds > 0 &&
                                  (_isPlaying || _position != Duration.zero))
                                Positioned(
                                  left:
                                      (constraints.maxWidth *
                                              (_position.inMilliseconds /
                                                  _duration.inMilliseconds))
                                          .clamp(0.0, constraints.maxWidth - 8),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: activeWaveformColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: activeWaveformColor
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isPlaying || _position != Duration.zero
                              ? _formatDuration(_position)
                              : (widget.subtitle ?? _formatDuration(_duration)),
                          style: TextStyle(
                            fontSize: 11,
                            color: onBubbleColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.showDetails) ...[
            const SizedBox(height: 4),
            // Timestamp and Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(widget.timestamp ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: onBubbleColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.isMe) _buildStatusIcons(onBubbleColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcons(Color color) {
    if (widget.isRead) {
      return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    } else if (widget.isDelivered) {
      return Icon(Icons.done_all, size: 14, color: color.withOpacity(0.5));
    } else if (widget.isSent) {
      return Icon(Icons.done, size: 14, color: color.withOpacity(0.5));
    }
    return Icon(
      Icons.access_time_rounded,
      size: 12,
      color: color.withOpacity(0.5),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildErrorState(bool isDark) {
    final height = widget.height ?? 140;
    return Container(
      height: height > 140 ? 140 : height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_off_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load audio',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check file or connection',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(bool isDark, Color primaryColor, Color accentColor) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.height ?? 180),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF141422)]
              : [Colors.white, const Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? primaryColor.withOpacity(0.2)
              : primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.2 : 0.12),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(-10, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // Waveform background
            if (widget.showWaveform)
              Positioned.fill(
                child: _buildWaveformBackground(
                  isDark,
                  primaryColor,
                  accentColor,
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withOpacity(0.1),
                      (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with music icon
                  _buildTitleRow(isDark, primaryColor),
                  const Spacer(),

                  // Progress section
                  _buildProgressSection(isDark, primaryColor, accentColor),
                  const SizedBox(height: 8),

                  // Time labels
                  _buildTimeLabels(isDark),
                  const SizedBox(height: 16),

                  // Controls
                  _buildControls(isDark, primaryColor, accentColor),
                ],
              ),
            ),

            // Loading overlay
            if (!_isLoaded)
              Positioned.fill(
                child: _buildLoadingOverlay(isDark, primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            MediaAnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1.5 + 3 * _shimmerController.value, 0),
                      end: Alignment(-0.5 + 3 * _shimmerController.value, 0),
                      colors: [
                        Colors.transparent,
                        isDark ? Colors.white24 : Colors.black12,
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  child: Text(
                    'Loading audio...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformBackground(
    bool isDark,
    Color primaryColor,
    Color accentColor,
  ) {
    return MediaAnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return CustomPaint(
          painter: _WaveformPainter(
            waveformData: _waveformData,
            animationValue: _waveformController.value,
            isPlaying: _isPlaying,
            primaryColor: primaryColor,
            accentColor: accentColor,
            progress: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _buildTitleRow(bool isDark, Color primaryColor) {
    return Row(
      children: [
        // Animated music icon
        MediaAnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPlaying ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.music_note_rounded
                      : Icons.audio_file_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 14),

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'Audio Track',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Status indicator
        _buildStatusIndicator(isDark, primaryColor),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _isPlaying
            ? Colors.green.withOpacity(0.15)
            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPlaying
              ? Colors.green.withOpacity(0.3)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isPlaying ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: _isPlaying
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isPlaying ? 'Playing' : 'Paused',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _isPlaying
                  ? Colors.green
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    bool isDark,
    Color primaryColor,
    Color accentColor,
  ) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: _onSeekStart,
          onHorizontalDragUpdate: (details) =>
              _onSeekUpdate(details, constraints.maxWidth),
          onTapDown: (details) {
            final progress = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            final newPosition = Duration(
              milliseconds: (_duration.inMilliseconds * progress).toInt(),
            );
            _seek(newPosition);
            HapticFeedback.selectionClick();
          },
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // Thumb indicator
                if (progress > 0.02)
                  Positioned(
                    left: (constraints.maxWidth * progress) - 14,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeLabels(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_position),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(bool isDark, Color primaryColor, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s button
        _buildControlButton(
          icon: Icons.replay_10_rounded,
          onPressed: () {
            final newPos = _position - const Duration(seconds: 10);
            _seek(newPos < Duration.zero ? Duration.zero : newPos);
          },
          size: 48,
          iconSize: 24,
          isDark: isDark,
          primaryColor: primaryColor,
        ),
        const SizedBox(width: 16),

        // Main Play/Pause button
        _buildMainPlayButton(isDark, primaryColor, accentColor),
        const SizedBox(width: 16),

        // Forward 10s button
        _buildControlButton(
          icon: Icons.forward_10_rounded,
          onPressed: () {
            final newPos = _position + const Duration(seconds: 10);
            _seek(newPos > _duration ? _duration : newPos);
          },
          size: 48,
          iconSize: 24,
          isDark: isDark,
          primaryColor: primaryColor,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required double iconSize,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark
              ? primaryColor.withOpacity(0.15)
              : primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(icon, size: iconSize, color: primaryColor),
      ),
    );
  }

  Widget _buildMainPlayButton(
    bool isDark,
    Color primaryColor,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: MediaAnimatedBuilder(
        animation: _playButtonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_playButtonController.value * 0.05),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, accentColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(_isPlaying),
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

// ================================================================
// WAVEFORM PAINTER
// ================================================================

class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double animationValue;
  final bool isPlaying;
  final Color primaryColor;
  final Color accentColor;
  final double progress;
  final bool isDark;

  _WaveformPainter({
    required this.waveformData,
    required this.animationValue,
    required this.isPlaying,
    required this.primaryColor,
    required this.accentColor,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / waveformData.length;
    final centerY = size.height * 0.5;
    final maxHeight = size.height * 0.5;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedPosition = i / waveformData.length;

      // Calculate bar height with animation
      var height = waveformData[i] * maxHeight;

      if (isPlaying) {
        final phase = (animationValue * 2 * math.pi) + (i * 0.15);
        final wave = (math.sin(phase) * 0.4 + 1.0);
        height *= wave;
      }

      // Color based on progress
      final isPlayed = normalizedPosition <= progress;
      final color = isPlayed
          ? Color.lerp(primaryColor, accentColor, normalizedPosition)!
          : (isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.08));

      final paint = Paint()
        ..color = color
        ..strokeWidth = barWidth * 0.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Add glow for played bars
      if (isPlayed && isPlaying) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = barWidth * 0.8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(x, centerY - height / 2),
          Offset(x, centerY + height / 2),
          glowPaint,
        );
      }

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.progress != progress;
  }
}

class _BubbleWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final Color baseColor;
  final Color activeColor;
  final bool isMe;

  _BubbleWaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.baseColor,
    required this.activeColor,
    required this.isMe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 45; // Fixed number of bars for bubble
    final spacing = 2.0;
    final totalSpacing = (barCount - 1) * spacing;
    final barWidth = (size.width - totalSpacing) / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing) + barWidth / 2;
      final normalizedPos = i / barCount;

      // Use a subset of waveform data or interpolate
      final dataIndex = (normalizedPos * (waveformData.length - 1)).toInt();
      final height = (waveformData[dataIndex] * size.height * 0.8).clamp(
        4.0,
        size.height,
      );

      final isPlayed = normalizedPos <= progress;
      final paint = Paint()
        ..color = isPlayed ? activeColor : baseColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ================================================================
// MEDIA ANIMATED BUILDER (Renamed to avoid conflict with Flutter's AnimatedBuilder)
// ================================================================

class MediaAnimatedBuilder extends StatefulWidget {
  final Listenable animation;
  final TransitionBuilder builder;
  final Widget? child;

  const MediaAnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  State<MediaAnimatedBuilder> createState() => _MediaAnimatedBuilderState();
}

class _MediaAnimatedBuilderState extends State<MediaAnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(MediaAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeListener(_handleChange);
      widget.animation.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The animation has changed.
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}

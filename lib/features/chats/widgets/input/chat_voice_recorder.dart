// ================================================================
// FILE: lib/features/chat/widgets/input/chat_voice_recorder.dart
// PURPOSE: Voice recording interface with waveform and lock
// STYLE: Snapchat-style hold-to-record with slide to lock
// DEPENDENCIES: record, path_provider, permission_handler
// ================================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_attachment_provider.dart';
import '../../../../media_utility/animated_audio_player.dart';

import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class ChatVoiceRecorder extends StatefulWidget {
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final bool startLocked;

  const ChatVoiceRecorder({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.startLocked = false,
  });

  @override
  State<ChatVoiceRecorder> createState() => ChatVoiceRecorderState();
}

class ChatVoiceRecorderState extends State<ChatVoiceRecorder>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isLocked = false;
  bool _showCancelTooltip = false;
  bool _showPreview = false;

  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  Timer? _cancelTooltipTimer;

  String? _recordedFilePath;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  late AnimationController _lockController;

  final List<double> _waveformValues = List.generate(30, (_) => 0.0);
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    _isLocked = widget.startLocked;
    _initAnimations();
    _checkPermissionsAndStart();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_waveController);

    _lockController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _checkPermissionsAndStart() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _startRecording();
    } else {
      if (mounted) {
        AppSnackbar.warning('Microphone permission is required to record voice');
        widget.onCancel();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      HapticFeedback.mediumImpact();

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
        _recordDuration = Duration.zero;
      });

      // Update Attachment Provider
      final attachmentProvider = context.read<ChatAttachmentProvider>();
      attachmentProvider.startRecording();

      _startTimer();
      _startAmplitudeListener();

      // Show cancel tooltip after 1 second
      _cancelTooltipTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && !_isLocked) {
          setState(() => _showCancelTooltip = true);
        }
      });
    } catch (e) {
      logE('Error starting recording: $e');
      widget.onCancel();
    }
  }

  void _startTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() {
          _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
        });

        // Update Attachment Provider
        context.read<ChatAttachmentProvider>().updateRecordingDuration(
          _recordDuration,
        );
      }
    });
  }

  void _startAmplitudeListener() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) async {
      if (mounted && _isRecording && !_isPaused) {
        final amp = await _recorder.getAmplitude();
        setState(() {
          // Move existing values left
          for (int i = 0; i < _waveformValues.length - 1; i++) {
            _waveformValues[i] = _waveformValues[i + 1];
          }
          // Add new value (scale -60..0 dB to 0..1 range)
          double volume = (amp.current + 60) / 60;
          _waveformValues[_waveformValues.length - 1] = volume.clamp(0.05, 1.0);

          // Update Attachment Provider
          context.read<ChatAttachmentProvider>().updateWaveform(_waveformValues);
        });
      }
    });
  }

  Future<void> stopRecording() async {
    try {
      HapticFeedback.mediumImpact();
      await _recorder.stop();
      _recordTimer?.cancel();
      _waveformTimer?.cancel();
      _cancelTooltipTimer?.cancel();

      setState(() {
        _isRecording = false;
        _showCancelTooltip = false;
        if (_isLocked && _recordedFilePath != null) {
          _showPreview = true;
        }
      });

      // Update Attachment Provider
      context.read<ChatAttachmentProvider>().stopRecording(_recordedFilePath);
    } catch (e) {
      logE('Error stopping recording: $e');
    }
  }

  void _cancelRecording() {
    HapticFeedback.lightImpact();
    stopRecording();

    // Delete recorded file
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    context.read<ChatAttachmentProvider>().cancelRecording();
    setState(() {
      _showPreview = false;
      _isLocked = false;
    });
    widget.onCancel();
  }

  void updateDragPosition(double dx, double dy) {
    if (_isLocked || _showPreview) return;

    // dy is negative when sliding up
    if (dy < -60 && !_isLocked) {
      _lockRecording();
    }

    // dx is negative when sliding left
    if (dx < -100) {
      _cancelRecording();
    }
  }

  void endDrag(double dx, double dy) {
    if (_isLocked || _showPreview) return;

    if (dx < -100) {
      _cancelRecording();
    } else if (dy < -60) {
      _lockRecording();
    } else {
      // If not locked and not cancelled, send on release
      _sendRecording();
    }
  }

  void _lockRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLocked = true;
      _showCancelTooltip = false;
    });
    _lockController.forward();
  }

  void _sendRecording() async {
    HapticFeedback.heavyImpact();
    await stopRecording();
    widget.onSend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cancelRecording();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveformTimer?.cancel();
    _cancelTooltipTimer?.cancel();
    _recorder.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _lockController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_showPreview && _recordedFilePath != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
            Expanded(
              child: AnimatedAudioPlayer(
                url: _recordedFilePath!,
                isLocal: true,
                style: AudioPlayerStyle.bubble,
                isMe: true,
                borderRadius: 22,
                autoPlay: false,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendRecording,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // Pulse animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: _pulseAnimation.value * 4,
                          spreadRadius: _pulseAnimation.value * 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Timer
              SizedBox(
                width: 48,
                child: Text(
                  _formatDuration(_recordDuration),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Waveform or "Slide to cancel"
              Expanded(
                child: !_isLocked
                    ? _buildSlideToCancel(theme)
                    : _buildWaveform(colorScheme),
              ),

              // Stop button (when locked)
              if (_isLocked && !_showPreview)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: stopRecording,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                )
              else if (!_isLocked)
                const SizedBox(
                  width: 44,
                ), // Space for the mic button that's actually above it
            ],
          ),

          // Lock hint (sliding up)
          if (!_isLocked && !_showPreview)
            Positioned(bottom: 48, right: 0, child: _buildLockHint(theme)),
        ],
      ),
    );
  }

  Widget _buildWaveform(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 24,
          child: CustomPaint(
            painter: _VoiceWavePainter(
              waveform: _waveformValues,
              color: colorScheme.primary,
              progress: _waveAnimation.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlideToCancel(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.keyboard_arrow_left_rounded,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          'Slide to cancel',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLockHint(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey),
        const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _VoiceWavePainter extends CustomPainter {
  final List<double> waveform;
  final Color color;
  final double progress;

  _VoiceWavePainter({
    required this.waveform,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final spacing = 1.0;
    final barWidth = math.max(
      1.0,
      (size.width - (waveform.length - 1) * spacing) / waveform.length,
    );

    for (int i = 0; i < waveform.length; i++) {
      // Scale height to painter size, with a minimum height of 2px
      final height = (waveform[i] * size.height).clamp(2.0, size.height);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.4 + (waveform[i] * 0.6))
        ..style = PaintingStyle.fill
        ..strokeCap = StrokeCap.round;

      final left = i * (barWidth + spacing);
      final top = (size.height - height) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.waveform != waveform || oldDelegate.progress != progress;
  }
}

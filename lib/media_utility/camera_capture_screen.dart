// ================================================================
// FILE: lib/media_utility/camera_capture_screen.dart
// ✅ FIXED: Filter circles show LIVE camera feed (not grey box)
// ✅ FIXED: Buttons with spring animations + haptic + glow effects
// ✅ All original features preserved
// ================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'gallery_picker_screen.dart';
import '../widgets/logger.dart';
import '../widgets/app_snackbar.dart';
import 'color_filters.dart';

class CameraCaptureResult {
  final List<XFile> files;
  final ColorFilter? filter;
  final String? filterName;

  CameraCaptureResult({required this.files, this.filter, this.filterName});
}

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isRecordingPending = false;
  bool _isRearCamera = true;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  final List<XFile> _recordedClips = [];
  Duration _totalRecordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // ── Animation controllers ──
  late AnimationController _shutterAnimController;
  late AnimationController _recordPulseController;
  late AnimationController _captureButtonController;
  late AnimationController _switchButtonController;
  late AnimationController _galleryButtonController;
  late AnimationController _flashButtonController;
  late AnimationController _closeButtonController;
  late AnimationController _filterSwitchController;

  late Animation<double> _recordPulseAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _switchScaleAnimation;
  late Animation<double> _galleryScaleAnimation;
  late Animation<double> _flashScaleAnimation;
  late Animation<double> _closeScaleAnimation;
  late Animation<double> _filterSlideAnimation;

  late List<Map<String, dynamic>> _filters;
  int _selectedFilterIndex = 0;

  // ✅ Scroll controller to snap filter to center
  final ScrollController _filterScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filters = ColorFilters.getAllFilters();
    _initAnimations();
    _initializeCamera();
  }

  void _initAnimations() {
    _shutterAnimController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _recordPulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _recordPulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _recordPulseController, curve: Curves.easeInOut),
    );

    // ── Shutter button spring ──
    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _captureButtonController, curve: Curves.easeOut),
    );

    // ── Switch camera spring ──
    _switchButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _switchButtonController,
        curve: Curves.easeInBack,
      ),
    );

    // ── Gallery button spring ──
    _galleryButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _galleryScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _galleryButtonController, curve: Curves.easeOut),
    );

    // ── Flash button spring ──
    _flashButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _flashScaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _flashButtonController, curve: Curves.easeOut),
    );

    // ── Close button spring ──
    _closeButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _closeScaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _closeButtonController, curve: Curves.easeOut),
    );

    // ── Filter strip slide in ──
    _filterSwitchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _filterSlideAnimation = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(
        parent: _filterSwitchController,
        curve: Curves.easeOutCubic,
      ),
    );
    _filterSwitchController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recordingTimer?.cancel();
    _shutterAnimController.dispose();
    _recordPulseController.dispose();
    _captureButtonController.dispose();
    _switchButtonController.dispose();
    _galleryButtonController.dispose();
    _flashButtonController.dispose();
    _closeButtonController.dispose();
    _filterSwitchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        snackbarService.showWarning('No cameras available');
        return;
      }

      _cameras = cameras;
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _controller?.dispose();

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      logE('Camera initialization error: $e');
      if (mounted) snackbarService.showError('Failed to initialize camera');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    HapticFeedback.lightImpact();

    // ✅ Spin animation on switch
    _switchButtonController.forward().then((_) {
      _isRearCamera = !_isRearCamera;
      _switchButtonController.reverse();
    });

    try {
      setState(() => _isCameraInitialized = false);

      final newCamera = _cameras!.firstWhere(
        (cam) =>
            cam.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );

      await _controller?.dispose();

      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = 1.0;

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      logE('Camera switch error: $e');
      snackbarService.showError('Failed to switch camera');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    HapticFeedback.selectionClick();

    // Button tap animation
    _flashButtonController.forward().then(
      (_) => _flashButtonController.reverse(),
    );

    try {
      final nextMode = {
        FlashMode.off: FlashMode.always,
        FlashMode.always: FlashMode.torch,
        FlashMode.torch: FlashMode.auto,
        FlashMode.auto: FlashMode.off,
      }[_flashMode]!;

      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (e) {
      logE('Flash toggle error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing)
      return;

    try {
      setState(() => _isCapturing = true);
      HapticFeedback.mediumImpact();
      _shutterAnimController.forward().then(
        (_) => _shutterAnimController.reverse(),
      );

      final XFile photo = await _controller!.takePicture();
      final processedFile = await _processPhoto(photo);

      if (mounted) {
        Navigator.pop(context, [XFile(processedFile.path)]);
      }
    } catch (e) {
      logE('Photo capture error: $e');
      snackbarService.showError('Failed to capture photo');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<File> _processPhoto(XFile photo) async {
    try {
      final bytes = await File(photo.path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return File(photo.path);

      image = img.bakeOrientation(image);
      if (!_isRearCamera) image = img.flipHorizontal(image);

      final matrix = _filters[_selectedFilterIndex]['matrix'] as List<double>?;
      if (matrix != null) {
        image = _applyColorFilterMatrix(image, matrix);
      }

      final outputBytes = img.encodeJpg(image, quality: 95);
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);
      return outputFile;
    } catch (e) {
      logE('Error processing photo: $e');
      return File(photo.path);
    }
  }

  img.Image _applyColorFilterMatrix(img.Image image, List<double> matrix) {
    assert(matrix.length == 20);
    final filtered = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final a = pixel.a.toDouble();

        final nr =
            (r * matrix[0] +
                    g * matrix[1] +
                    b * matrix[2] +
                    a * matrix[3] +
                    matrix[4])
                .clamp(0, 255)
                .toInt();
        final ng =
            (r * matrix[5] +
                    g * matrix[6] +
                    b * matrix[7] +
                    a * matrix[8] +
                    matrix[9])
                .clamp(0, 255)
                .toInt();
        final nb =
            (r * matrix[10] +
                    g * matrix[11] +
                    b * matrix[12] +
                    a * matrix[13] +
                    matrix[14])
                .clamp(0, 255)
                .toInt();
        final na =
            (r * matrix[15] +
                    g * matrix[16] +
                    b * matrix[17] +
                    a * matrix[18] +
                    matrix[19])
                .clamp(0, 255)
                .toInt();

        filtered.setPixelRgba(x, y, nr, ng, nb, na);
      }
    }

    return filtered;
  }

  Future<void> _startRecording() async {
    if (_controller == null || _isRecording || _isRecordingPending) return;

    try {
      setState(() => _isRecordingPending = true);
      HapticFeedback.heavyImpact();

      await _controller!.startVideoRecording();

      if (!_isRecordingPending) {
        await _controller!.stopVideoRecording();
        return;
      }

      setState(() {
        _isRecording = true;
        _isRecordingPending = false;
      });

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (mounted) {
          setState(
            () => _totalRecordingDuration += const Duration(milliseconds: 100),
          );
          if (_totalRecordingDuration.inSeconds >= 60) _stopRecording();
        }
      });
    } catch (e) {
      logE('Recording start error: $e');
      snackbarService.showError('Failed to start recording');
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null) return;
    if (_isRecordingPending && !_isRecording) {
      setState(() => _isRecordingPending = false);
      return;
    }
    if (!_isRecording) return;

    try {
      HapticFeedback.mediumImpact();
      _recordingTimer?.cancel();
      final XFile video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
        _recordedClips.add(video);
      });
      if (mounted) Navigator.pop(context, _recordedClips);
    } catch (e) {
      logE('Recording stop error: $e');
      snackbarService.showError('Failed to stop recording');
      setState(() {
        _isRecording = false;
        _isRecordingPending = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onScaleUpdate: (details) {
            if (_controller == null) return;
            final newZoom = (_currentZoom * details.scale).clamp(
              _minZoom,
              _maxZoom,
            );
            _controller!.setZoomLevel(newZoom);
            setState(() => _currentZoom = newZoom);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(),
              // Shutter flash overlay
              AnimatedBuilder(
                animation: _shutterAnimController,
                builder: (_, __) => IgnorePointer(
                  child: Opacity(
                    opacity: _shutterAnimController.value * 0.5,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              _buildTopControls(),
              _buildBottomControls(),
              if (_currentZoom > 1.01) _buildZoomIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // CAMERA PREVIEW — full screen with active filter
  // ══════════════════════════════════════════════════════
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Wrap entire camera preview with selected color filter
    final currentFilter =
        _filters[_selectedFilterIndex]['filter'] as ColorFilter?;

    Widget preview = CameraPreview(_controller!);

    if (currentFilter != null) {
      preview = ColorFiltered(colorFilter: currentFilter, child: preview);
    }

    return GestureDetector(onDoubleTap: _switchCamera, child: preview);
  }

  // ══════════════════════════════════════════════════════
  // TOP CONTROLS — close + flash + switch
  // ══════════════════════════════════════════════════════
  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Close ──
          _AnimatedControlButton(
            icon: Icons.close_rounded,
            controller: _closeButtonController,
            scaleAnimation: _closeScaleAnimation,
            onTap: () {
              _closeButtonController.forward().then(
                (_) => _closeButtonController.reverse(),
              );
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          Row(
            children: [
              // ── Flash ──
              _AnimatedControlButton(
                icon: _getFlashIcon(),
                controller: _flashButtonController,
                scaleAnimation: _flashScaleAnimation,
                onTap: _toggleFlash,
                glowColor: _flashMode != FlashMode.off ? Colors.amber : null,
                badgeColor: _flashMode != FlashMode.off ? Colors.amber : null,
              ),
              const SizedBox(width: 12),
              // ── Switch camera (spin animation) ──
              AnimatedBuilder(
                animation: _switchScaleAnimation,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 - _switchScaleAnimation.value,
                  child: child,
                ),
                child: _AnimatedControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  controller: _switchButtonController,
                  scaleAnimation: const AlwaysStoppedAnimation(1.0),
                  onTap: _switchCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() => switch (_flashMode) {
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always => Icons.flash_on_rounded,
    FlashMode.off => Icons.flash_off_rounded,
    FlashMode.torch => Icons.flashlight_on_rounded,
  };

  // ══════════════════════════════════════════════════════
  // BOTTOM CONTROLS
  // ══════════════════════════════════════════════════════
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) _buildRecordingIndicator(),
            if (!_isRecording) ...[
              _buildFilterSelector(),
              const SizedBox(height: 24),
            ],
            _buildMainControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _recordPulseAnimation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(
                0.5 * (_recordPulseAnimation.value - 1.0) / 0.25 + 0.3,
              ),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(_totalRecordingDuration),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ✅ FILTER SELECTOR — live camera feed in each circle
  // ══════════════════════════════════════════════════════
  Widget _buildFilterSelector() {
    return AnimatedBuilder(
      animation: _filterSlideAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _filterSlideAnimation.value),
        child: Opacity(
          opacity: 1.0 - (_filterSlideAnimation.value / 80).clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: SizedBox(
        height: 115,
        child: ListView.builder(
          controller: _filterScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedFilterIndex;
            final filterName = _filters[index]['name'] as String;
            final colorFilter = _filters[index]['filter'] as ColorFilter?;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilterIndex = index);
                // ✅ Scroll selected filter to center
                final itemWidth = 78.0;
                final screenWidth = MediaQuery.of(context).size.width;
                final offset =
                    (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
                _filterScrollController.animateTo(
                  offset.clamp(
                    0,
                    _filterScrollController.position.maxScrollExtent,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 10),
                width: 78,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ FIXED: Live camera preview inside filter circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 68 : 58,
                      height: isSelected ? 68 : 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.amber
                              : Colors.white.withOpacity(0.4),
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipOval(
                        child: _isCameraInitialized && _controller != null
                            // ✅ Real camera feed with filter applied
                            ? colorFilter != null
                                  ? ColorFiltered(
                                      colorFilter: colorFilter,
                                      child: CameraPreview(_controller!),
                                    )
                                  : CameraPreview(_controller!)
                            // Fallback while camera loads
                            : Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: isSelected ? 12 : 11,
                      ),
                      child: Text(
                        filterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // MAIN CONTROLS — gallery | shutter | switch
  // ══════════════════════════════════════════════════════
  Widget _buildMainControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Gallery button ──
          _buildGalleryButton(),

          // ── Shutter button ──
          _buildShutterButton(),

          // ── Switch camera button ──
          _buildSwitchButton(),
        ],
      ),
    );
  }

  // ── Gallery button with spring tap ──
  Widget _buildGalleryButton() {
    return GestureDetector(
      onTapDown: (_) => _galleryButtonController.forward(),
      onTapUp: (_) {
        _galleryButtonController.reverse();
        _openGallery();
      },
      onTapCancel: () => _galleryButtonController.reverse(),
      child: AnimatedBuilder(
        animation: _galleryScaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _galleryScaleAnimation.value, child: child),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.photo_library_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ── Switch button with rotation ──
  Widget _buildSwitchButton() {
    return GestureDetector(
      onTap: _switchCamera,
      child: AnimatedBuilder(
        animation: _switchButtonController,
        builder: (_, child) => Transform.rotate(
          angle: _switchButtonController.value * 3.14159,
          child: child,
        ),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.cameraswitch_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ── Shutter button with spring + glow ──
  Widget _buildShutterButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isRecording && !_isCapturing) {
          _captureButtonController.forward();
        }
      },
      onTapUp: (_) {
        _captureButtonController.reverse();
        if (!_isRecording && !_isCapturing) _capturePhoto();
      },
      onTapCancel: () => _captureButtonController.reverse(),
      onLongPressStart: (_) {
        if (!_isRecording && !_isCapturing) _startRecording();
      },
      onLongPressEnd: (_) {
        if (_isRecording) _stopRecording();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _buttonScaleAnimation,
          _recordPulseAnimation,
        ]),
        builder: (_, __) {
          final scale = _isRecording
              ? _recordPulseAnimation.value
              : _buttonScaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ✅ Outer glow ring when recording
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 96 : 88,
                  height: _isRecording ? 96 : 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? Colors.red : Colors.white,
                      width: _isRecording ? 3 : 4,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                ),
                // Inner button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  width: _isRecording ? 46 : 70,
                  height: _isRecording ? 46 : 70,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.white,
                    // ✅ Morphs from circle to rounded square when recording
                    borderRadius: _isRecording
                        ? BorderRadius.circular(12)
                        : BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : Colors.white)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isCapturing
                      ? const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black45,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      top: MediaQuery.of(context).size.height / 2 - 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            '${_currentZoom.toStringAsFixed(1)}×',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGallery() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const GalleryPickerScreen(allowMultiple: true, maxSelection: 10),
      ),
    );

    if (result == 'camera_requested' || result == null || !mounted) return;

    List<XFile> xFiles = [];
    if (result is List<File>) {
      xFiles = result.map((f) => XFile(f.path)).toList();
    } else if (result is List<XFile>) {
      xFiles = result;
    }

    if (xFiles.isNotEmpty) {
      Navigator.pop(
        context,
        CameraCaptureResult(
          files: xFiles,
          filter: _filters[_selectedFilterIndex]['filter'] as ColorFilter?,
          filterName: _filters[_selectedFilterIndex]['name'] as String?,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }
}

// ══════════════════════════════════════════════════════
// REUSABLE ANIMATED CONTROL BUTTON (top bar)
// ══════════════════════════════════════════════════════
class _AnimatedControlButton extends StatelessWidget {
  const _AnimatedControlButton({
    required this.icon,
    required this.controller,
    required this.scaleAnimation,
    required this.onTap,
    this.glowColor,
    this.badgeColor,
  });

  final IconData icon;
  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final Color? glowColor;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () => controller.reverse(),
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: scaleAnimation.value, child: child),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: glowColor != null
                  ? glowColor!.withOpacity(0.6)
                  : Colors.white24,
              width: 1.5,
            ),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (badgeColor != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

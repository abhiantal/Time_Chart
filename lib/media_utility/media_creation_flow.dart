// ================================================================
// COMPLETE INTEGRATION: How to use the system
// File: screen/media_creation_flow.dart
// ================================================================

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/logger.dart';
import 'camera_capture_screen.dart';
import 'media_asset_model.dart' hide convertUrlsToEnhancedMedia;
import 'media_display.dart';
import 'universal_media_service.dart';
import 'media_picker.dart';
import 'media_editor_suite_screen.dart';
import 'gallery_picker_screen.dart';

/// Main entry point for creating media content
/// This demonstrates the full Instagram + Snapchat workflow
class MediaCreationFlow extends StatefulWidget {
  const MediaCreationFlow({super.key});

  @override
  State<MediaCreationFlow> createState() => _MediaCreationFlowState();
}

class _MediaCreationFlowState extends State<MediaCreationFlow> {
  final UniversalMediaService mediaService = UniversalMediaService();

  Future<void> _openCamera() async {
    final result = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );

    if (result != null && result.isNotEmpty) {
      // Direct pick - skip editor per user request
      // await _navigateToEditor(files);
      await _processDirectly(result.map((xFile) => File(xFile.path)).toList());
    }
  }

  Future<void> _openGallery({bool allowMultiple = true}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GalleryPickerScreen(allowMultiple: allowMultiple, maxSelection: 10),
      ),
    );

    if (result == 'camera_requested') {
      await _openCamera();
      return;
    }

    if (result != null && result is List<File> && result.isNotEmpty) {
      // Direct pick - skip editor per user request
      // await _navigateToEditor(result);
      await _processDirectly(result);
    }
  }

  Future<void> _processDirectly(List<File> files) async {
    // Convert files to MediaAssetModel
    final assets = files.map((file) {
      final extension = file.path.toLowerCase();
      final isVideo =
          extension.endsWith('.mp4') ||
          extension.endsWith('.mov') ||
          extension.endsWith('.avi');

      return MediaAssetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        file: file,
        type: isVideo ? MediaType.video : MediaType.image,
      );
    }).toList();

    await _uploadToBackend(assets);
  }

  Future<void> _uploadToBackend(List<MediaAssetModel> assets) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final uploadedUrls = <String>[];

      for (final asset in assets) {
        // Use the edited file if available, otherwise original
        final fileToUpload = asset.editedFile ?? asset.file;

        // Upload using UniversalMediaService
        final url = await mediaService.uploadSingle(
          file: fileToUpload,
          bucket: MediaBucket.socialMedia,
          autoCompress: true,
        );

        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success
      if (uploadedUrls.isNotEmpty && mounted) {
        AppSnackbar.success(
          'Uploaded ${uploadedUrls.length} files successfully!',
        );

        // Display uploaded media
        await _displayUploadedMedia(uploadedUrls);
      }
    } catch (e, s) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        logE('Upload failed', error: e, stackTrace: s);
        AppSnackbar.error('Upload failed: $e');
      }
    }
  }

  Future<void> _displayUploadedMedia(List<String> urls) async {
    // Convert URLs to EnhancedMediaFile for display
    final mediaFiles = await mediaService.retrieve(
      bucket: MediaBucket.socialMedia,
      specificUrls: urls,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDisplayScreen(mediaFiles: mediaFiles),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Content'), elevation: 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera,
                size: 100,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 32),
              Text(
                'Create Amazing Content',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Take photos, record videos, or choose from gallery',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Camera Button (Primary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gallery Button (Secondary)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openGallery(allowMultiple: true),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Features list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FeatureItem(
                      icon: Icons.filter,
                      title: 'Instagram-style Filters',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.brush,
                      title: 'Draw & Add Text',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.tune,
                      title: 'Professional Adjustments',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.crop,
                      title: 'Crop & Trim Videos',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black87),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// MEDIA DISPLAY SCREEN
// Shows uploaded/retrieved media using EnhancedMediaDisplay
// ================================================================

class MediaDisplayScreen extends StatefulWidget {
  final List<EnhancedMediaFile> mediaFiles;

  const MediaDisplayScreen({super.key, required this.mediaFiles});

  @override
  State<MediaDisplayScreen> createState() => _MediaDisplayScreenState();
}

class _MediaDisplayScreenState extends State<MediaDisplayScreen> {
  late List<EnhancedMediaFile> _mediaFiles;
  MediaLayoutMode _layoutMode = MediaLayoutMode.grid;

  @override
  void initState() {
    super.initState();
    _mediaFiles = widget.mediaFiles;
  }

  Future<void> _deleteMedia(String mediaId) async {
    final file = _mediaFiles.firstWhere((f) => f.id == mediaId);

    // Delete from backend
    final success = await mediaService.deleteSingle(
      mediaUrl: file.url,
      bucket: MediaBucket.socialMedia,
    );

    if (success) {
      setState(() {
        _mediaFiles.removeWhere((f) => f.id == mediaId);
      });

      if (mounted) {
        AppSnackbar.success('Media deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Media'),
        actions: [
          PopupMenuButton<MediaLayoutMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (mode) {
              setState(() => _layoutMode = mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MediaLayoutMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view),
                    SizedBox(width: 8),
                    Text('Grid'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MediaLayoutMode.list,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('List'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MediaLayoutMode.carousel,
                child: Row(
                  children: [
                    Icon(Icons.view_carousel),
                    SizedBox(width: 8),
                    Text('Carousel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MediaLayoutMode.masonry,
                child: Row(
                  children: [
                    Icon(Icons.dashboard),
                    SizedBox(width: 8),
                    Text('Masonry'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: EnhancedMediaDisplay(
          mediaFiles: _mediaFiles,
          config: MediaDisplayConfig(
            layoutMode: _layoutMode,
            borderRadius: 12,
            spacing: 8,
            showFileName: true,
            showFileSize: true,
            showDate: true,
            allowDelete: true,
            allowFullScreen: true,
            gridColumns: 3,
          ),
          onDelete: _deleteMedia,
          emptyMessage: 'No media uploaded yet',
        ),
      ),
    );
  }
}

// ================================================================
// USAGE EXAMPLES
// ================================================================

/// Example 1: Upload bucket media
Future<void> uploadBucketMediaExample(BuildContext context) async {
  // Pick media using EnhancedMediaPicker
  final files = await EnhancedMediaPicker.pickMultipleMedia(
    context,
    config: const MediaPickerConfig(
      allowImage: true,
      allowVideo: true,
      autoCompress: true,
      maxFileSizeMB: 50,
    ),
    maxFiles: 10,
  );

  if (files.isNotEmpty) {
    final fileList = files.map((xFile) => File(xFile.path)).toList();

    // Upload to bucket-media
    final urls = await mediaService.uploadBucketMedia(fileList);

    logI('Uploaded ${urls.length} files to bucket-media');
  }
}

/// Example 2: Upload task media with task ID
Future<void> uploadTaskMediaExample(BuildContext context, String taskId) async {
  final file = await EnhancedMediaPicker.pickMedia(
    context,
    config: const MediaPickerConfig(
      allowImage: true,
      allowVideo: false,
      autoCompress: true,
    ),
  );

  if (file != null) {
    final urls = await mediaService.uploadTaskMedia(
      files: [File(file.path)],
      taskType: 'daily', // or 'weekly', 'long'
      taskId: taskId,
    );

    logI('Uploaded to task: ${urls.first}');
  }
}

/// Example 3: Retrieve and display user's media
Future<void> retrieveAndDisplayExample(
  BuildContext context,
  MediaBucket bucket,
) async {
  // Retrieve media from backend
  final mediaFiles = await mediaService.retrieve(bucket: bucket, limit: 50);

  if (mediaFiles.isNotEmpty && context.mounted) {
    // Display in different layouts
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Your Media',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: EnhancedMediaDisplay(
                  mediaFiles: mediaFiles,
                  config: const MediaDisplayConfig(
                    layoutMode: MediaLayoutMode.grid,
                    gridColumns: 3,
                    allowFullScreen: true,
                    allowDelete: true,
                  ),
                  onDelete: (mediaId) async {
                    final file = mediaFiles.firstWhere((f) => f.id == mediaId);
                    await mediaService.deleteSingle(
                      mediaUrl: file.url,
                      bucket: bucket,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Example 4: Avatar upload and display
Future<void> avatarUploadExample(BuildContext context) async {
  final file = await EnhancedMediaPicker.pickMedia(
    context,
    config: const MediaPickerConfig(
      allowCamera: true,
      allowGallery: true,
      allowImage: true,
      allowVideo: false,
      autoCompress: true,
      imageQuality: 80,
    ),
  );

  if (file != null) {
    final avatarUrl = await mediaService.uploadAvatar(File(file.path));

    if (avatarUrl != null) {
      // Use the avatar URL
      logI('Avatar uploaded: $avatarUrl');

      // Later, when displaying, ensure it's valid
      final validUrl = await mediaService.getValidAvatarUrl(avatarUrl);

      // Display in UI
      if (context.mounted && validUrl != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Avatar Updated'),
            content: Image.network(validUrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// Example 5: Full content creation flow with editing
Future<void> fullCreationFlowExample(BuildContext context) async {
  // Step 1: Choose source (camera or gallery)
  final source = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose Source'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ],
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  List<File>? files;

  if (source == 'camera') {
    final result = await Navigator.push<List<XFile>>(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );
    if (result != null) {
      files = result.map((xFile) => File(xFile.path)).toList();
    }
  } else {
    final result = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const GalleryPickerScreen(allowMultiple: true, maxSelection: 10),
      ),
    );
    files = result;
  }

  if (files == null || files.isEmpty || !context.mounted) return;

  // Step 2: Convert to MediaAssetModel
  final assets = files.map((file) {
    return MediaAssetModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      file: file,
      type: file.path.toLowerCase().contains('.mp4')
          ? MediaType.video
          : MediaType.image,
    );
  }).toList();

  // Step 3: Edit
  final editedAssets = await Navigator.push<List<MediaAssetModel>>(
    context,
    MaterialPageRoute(
      builder: (context) => MediaEditorScreen(mediaAssets: assets),
    ),
  );

  if (editedAssets == null || editedAssets.isEmpty || !context.mounted) return;

  // Step 4: Upload
  final uploadedUrls = <String>[];
  for (final asset in editedAssets) {
    final fileToUpload = asset.editedFile ?? asset.file;
    final url = await mediaService.uploadSingle(
      file: fileToUpload,
      bucket: MediaBucket.socialMedia,
      autoCompress: true,
    );
    if (url != null) uploadedUrls.add(url);
  }

  // Step 5: Display
  if (uploadedUrls.isNotEmpty && context.mounted) {
    final mediaFiles = convertUrlsToEnhancedMedia(uploadedUrls);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDisplayScreen(mediaFiles: mediaFiles),
      ),
    );
  }
}

// ================================================================
// THEME CONFIGURATION
// Add these colors to your theme
// ================================================================

class MediaTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF6366F1), // Indigo
        secondary: const Color(0xFFEC4899), // Pink
        surface: Colors.white,
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF818CF8), // Lighter indigo for dark
        secondary: const Color(0xFFF472B6), // Lighter pink for dark
        surface: const Color(0xFF1F2937),
        error: const Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

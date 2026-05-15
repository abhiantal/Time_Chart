import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:provider/provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../../../media_utility/media_editor_suite_screen.dart'
    hide AnimatedBuilder;
import '../../../../media_utility/gallery_picker_screen.dart';
import '../../../../media_utility/camera_capture_screen.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../media_utility/enhanced_audio_recorder.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import '../../../../user_profile/create_edit_profile/profile_provider.dart';
import '../../chats/widgets/common/user_avatar_cached.dart';
import '../post/models/post_model.dart';

enum CreatePostType { media, article, poll, advertisement }

class CreatePostScreen extends StatefulWidget {
  final String currentUserId;
  final PostModel? editPost;
  final VoidCallback? onPostSuccess;

  const CreatePostScreen({
    super.key,
    required this.currentUserId,
    this.editPost,
    this.onPostSuccess,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _captionController;
  final FocusNode _captionFocusNode = FocusNode();
  List<EnhancedMediaFile> _selectedMedia = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _userAvatar;
  String? _userName;
  PostVisibility _visibility = PostVisibility.public;
  late AnimationController _progressController;
  ProfileProvider? _profileProvider;

  bool _isPoll = false;
  final TextEditingController _pollQuestionController = TextEditingController();
  CreatePostType _selectedType = CreatePostType.media;
  final TextEditingController _articleTitleController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final TextEditingController _adAdvertiserController = TextEditingController();
  final TextEditingController _adCtaTextController = TextEditingController();
  final TextEditingController _adCtaUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchUserProfile();
    _initEditMode();
  }

  @override
  void dispose() {
    // Remove profile listener safely without using context
    _profileProvider?.removeListener(_onProfileUpdate);

    _captionController.dispose();
    _captionFocusNode.dispose();
    _progressController.dispose();
    _pollQuestionController.dispose();
    _articleTitleController.dispose();
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
    _adAdvertiserController.dispose();
    _adCtaTextController.dispose();
    _adCtaUrlController.dispose();
    super.dispose();
  }

  void _initEditMode() {
    if (widget.editPost != null) {
      _captionController.text = widget.editPost!.caption ?? '';
      _visibility = widget.editPost!.visibility;

      if (widget.editPost!.hasMedia) {
        _selectedMedia = widget.editPost!.media.map((media) {
          return EnhancedMediaFile.fromUrl(
            id: media.id,
            url: media.url,
            thumbnailUrl: media.thumbnail,
          );
        }).toList();
      }

      if (widget.editPost!.postType == PostType.advertisement &&
          widget.editPost!.adData != null) {
        _selectedType = CreatePostType.advertisement;
        _adAdvertiserController.text =
            widget.editPost!.adData!.advertiserName ?? '';
        _adCtaTextController.text = widget.editPost!.adData!.ctaText ?? '';
        _adCtaUrlController.text = widget.editPost!.adData!.ctaUrl ?? '';
      }
    }
  }

  void _onProfileUpdate() {
    if (!mounted) return;
    final userProvider = _profileProvider;
    if (userProvider == null) return;

    final myProfile = userProvider.myProfile;
    if (myProfile != null && myProfile.id == widget.currentUserId) {
      setState(() {
        _userName = myProfile.username;
        _userAvatar = myProfile.profileUrl;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      if (widget.currentUserId.isEmpty) return;
      _profileProvider = context.read<ProfileProvider>();

      _onProfileUpdate();
      // Listen for profile changes
      _profileProvider?.addListener(_onProfileUpdate);
    } catch (e, stack) {
      logE('Error fetching user profile', error: e, stackTrace: stack);
    }
  }

  Future<void> _handleCamera() async {
    if (_selectedMedia.length >= 10) {
      AppSnackbar.warning('Maximum 10 media items allowed');
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (result != null && result is List<XFile>) {
      final assets = result
          .map(
            (x) => MediaAssetModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              file: File(x.path),
              type: _getMediaType(x.path),
            ),
          )
          .toList();
      _processAssets(assets);
    }
  }

  Future<void> _handleGallery() async {
    if (_selectedMedia.length >= 10) {
      AppSnackbar.warning('Maximum 10 media items allowed');
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPickerScreen(
          allowMultiple: true,
          maxSelection: 10 - _selectedMedia.length,
          allowedTypes: const [pm.AssetType.image, pm.AssetType.video],
        ),
      ),
    );
    if (result != null && result is List<File>) {
      final assets = result
          .map(
            (f) => MediaAssetModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              file: f,
              type: _detectAssetType(f.path),
            ),
          )
          .toList();
      _processAssets(assets);
    }
  }

  MediaType _detectAssetType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  Future<void> _processAssets(List<MediaAssetModel> assets) async {
    if (assets.isEmpty) return;
    final editedAssets = await Navigator.push<List<MediaAssetModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => MediaEditorScreen(mediaAssets: assets),
      ),
    );
    if (editedAssets != null && editedAssets.isNotEmpty) {
      for (final asset in editedAssets) {
        final file = asset.editedFile ?? asset.file;
        setState(() {
          _selectedMedia.add(
            EnhancedMediaFile.fromFile(
              file: file,
              type: asset.type == MediaType.video
                  ? MediaFileType.video
                  : MediaFileType.image,
            ),
          );
        });
      }
    } else if (assets.isNotEmpty) {
      for (final asset in assets) {
        setState(() {
          _selectedMedia.add(
            EnhancedMediaFile.fromFile(
              file: asset.file,
              type: asset.type == MediaType.video
                  ? MediaFileType.video
                  : MediaFileType.image,
            ),
          );
        });
      }
    }
  }

  Future<void> _handleAudio() async {
    final XFile? recordedFile = await showModalBottomSheet<XFile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedAudioRecorder(
        onCompleted: (file) => Navigator.pop(context, file),
        onCanceled: () => Navigator.pop(context),
      ),
    );
    if (recordedFile != null && mounted) {
      setState(() {
        _selectedMedia.add(
          EnhancedMediaFile.fromFile(
            file: File(recordedFile.path),
            type: MediaFileType.audio,
          ),
        );
      });
    }
  }

  MediaType _getMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  void _removeMedia(String mediaId) {
    setState(() {
      _selectedMedia.removeWhere((m) => m.id == mediaId);
    });
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...PostVisibility.values.map((visibility) {
                final isSelected = _visibility == visibility;
                return ListTile(
                  leading: Icon(_getVisibilityIcon(visibility)),
                  title: Text(_getVisibilityLabel(visibility)),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() => _visibility = visibility);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createPost() async {
    final caption = _captionController.text.trim();
    final hasMainContent = caption.isNotEmpty || _selectedMedia.isNotEmpty;
    final hasPollContent =
        _isPoll && _pollQuestionController.text.trim().isNotEmpty;

    if (!hasMainContent && !hasPollContent) {
      AppSnackbar.error('Please add some content to your post');
      return;
    }
    setState(() => _isUploading = true);
    try {
      final List<String> mediaUrls = [];
      if (_selectedMedia.isNotEmpty) {
        final filesToUpload = _selectedMedia
            .where((m) => m.isLocal)
            .map((m) => File(m.url))
            .toList();
        if (filesToUpload.isNotEmpty) {
          final uploadedUrls = await UniversalMediaService().uploadMultiple(
            files: filesToUpload,
            bucket: MediaBucket.socialMedia,
            onProgress: (progress) =>
                setState(() => _uploadProgress = progress),
          );
          mediaUrls.addAll(uploadedUrls);
        }
        mediaUrls.addAll(
          _selectedMedia.where((m) => !m.isLocal).map((m) => m.url),
        );
      }
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.id;

      final postProvider = context.read<PostProvider>();
      final mediaItems = mediaUrls
          .map((url) => PostMedia(url: url, type: _getMediaTypeFromUrl(url)))
          .toList();

      PostType finalPostType = _selectedType == CreatePostType.poll
          ? PostType.poll
          : (_selectedType == CreatePostType.advertisement
                ? PostType.advertisement
                : (mediaItems.any((m) => m.isVideo)
                      ? PostType.video
                      : PostType.post));

      final post = await postProvider.createPost(
        userId: currentUserId ?? '',
        postType: finalPostType,
        caption: _captionController.text.trim(),
        media: mediaItems,
        visibility: _visibility,
        pollData: _selectedType == CreatePostType.poll
            ? PollData(
                question: _pollQuestionController.text.trim(),
                options: _pollOptionControllers
                    .where((c) => c.text.trim().isNotEmpty)
                    .map(
                      (c) => PollOption(
                        id: const Uuid().v4(),
                        text: c.text.trim(),
                        votes: 0,
                      ),
                    )
                    .toList(),
              )
            : null,
        articleData: _selectedType == CreatePostType.article
            ? ArticleData(
                title: _captionController.text.trim(),
                content: _articleTitleController.text.trim(),
              )
            : null,
        adData: _selectedType == CreatePostType.advertisement
            ? AdData(
                id: const Uuid().v4(),
                title: _captionController.text.trim(),
                advertiserName: _adAdvertiserController.text.trim(),
                ctaText: _adCtaTextController.text.trim(),
                ctaUrl: _adCtaUrlController.text.trim(),
              )
            : null,
      );

      if (post != null && mounted) {
        AppSnackbar.success('Post created successfully!');
        if (widget.onPostSuccess != null) {
          widget.onPostSuccess!();
        } else {
          // Small delay to ensure snackbar has started its animation and navigator is ready
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop(post);
            }
          });
        }
      }
    } catch (e) {
      AppSnackbar.error('Failed to create post: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _getMediaTypeFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.mp4') ||
        lowerUrl.contains('.mov') ||
        lowerUrl.contains('.avi'))
      return 'video';
    if (lowerUrl.contains('.mp3') ||
        lowerUrl.contains('.wav') ||
        lowerUrl.contains('.m4a'))
      return 'audio';
    return 'image';
  }

  IconData _getVisibilityIcon(PostVisibility v) {
    switch (v) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.followers:
        return Icons.people_outline;
      case PostVisibility.following:
        return Icons.person_add_alt_1_outlined;
      case PostVisibility.private:
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getVisibilityLabel(PostVisibility v) => v.name.toUpperCase();

  // _toggleContentType was replaced by the top-level picker

  // _buildContentTypeSelector was replaced by the top-level picker

  // _contentTypeChip was replaced by the top-level picker

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            color: Colors.blue,
            onTap: _handleCamera,
          ),
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.purple,
            onTap: _handleGallery,
          ),
          _buildActionButton(
            icon: Icons.mic,
            label: 'Audio',
            color: Colors.orange,
            onTap: _handleAudio,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.onPostSuccess == null,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          systemOverlayStyle: theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          leading: widget.onPostSuccess != null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
          title: const Text(
            'Create Post',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: TextButton(
                  onPressed: _isUploading ? null : _createPost,
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: _isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isUploading)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        UserAvatarCached(
                          imageUrl: _userAvatar,
                          name: _userName ?? 'User',
                          size: 48,
                          showBorder: true,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? 'Loading...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                _buildVisibilityChip(theme),
                                SizedBox(width: 16),
                                _buildPostTypeChip(theme),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Primary Content Field
                    TextField(
                      controller: _captionController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        hintText: "Write a caption...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isPoll) _buildPollInput(theme),
                    if (_selectedType == CreatePostType.advertisement)
                      _buildAdInput(theme),

                    const SizedBox(height: 20),
                    if (_selectedType == CreatePostType.media ||
                        _selectedType == CreatePostType.advertisement)
                      EnhancedMediaDisplay(
                        mediaFiles: _selectedMedia,
                        onDelete: _removeMedia,
                        config: MediaDisplayConfig(
                          layoutMode: _selectedMedia.length == 1
                              ? MediaLayoutMode.single
                              : MediaLayoutMode.grid,
                          mediaBucket: MediaBucket.socialMedia,
                          allowDelete: true,
                          gridColumns: 2,
                          borderRadius: 12,
                          spacing: 8,
                          maxHeight: 300,
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (_selectedType == CreatePostType.media ||
                _selectedType == CreatePostType.advertisement)
              _buildBottomActionBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(ThemeData theme) {
    return GestureDetector(
      onTap: _showVisibilityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getVisibilityIcon(_visibility),
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              _visibility.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeChip(ThemeData theme) {
    return GestureDetector(
      onTap: _showPostTypePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPostTypeIcon(_selectedType),
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              _getPostTypeLabel(_selectedType).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...CreatePostType.values.map((type) {
                final isSelected = _selectedType == type;
                return ListTile(
                  leading: Icon(_getPostTypeIcon(type)),
                  title: Text(_getPostTypeLabel(type)),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      _isPoll = type == CreatePostType.poll;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  IconData _getPostTypeIcon(CreatePostType type) {
    switch (type) {
      case CreatePostType.media:
        return Icons.image_outlined;
      case CreatePostType.article:
        return Icons.article_outlined;
      case CreatePostType.poll:
        return Icons.poll_outlined;
      case CreatePostType.advertisement:
        return Icons.campaign_outlined;
    }
  }

  String _getPostTypeLabel(CreatePostType type) {
    switch (type) {
      case CreatePostType.media:
        return 'Media Post';
      case CreatePostType.article:
        return 'Article';
      case CreatePostType.poll:
        return 'Poll';
      case CreatePostType.advertisement:
        return 'Advertisement';
    }
  }

  Widget _buildPollInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Poll Question',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _pollQuestionController,
            decoration: const InputDecoration(hintText: 'Enter question...'),
          ),
          const SizedBox(height: 16),
          const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._pollOptionControllers.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        hintText: 'Option ${entry.key + 1}',
                      ),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => setState(
                        () => _pollOptionControllers.removeAt(entry.key),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (_pollOptionControllers.length < 5)
            TextButton.icon(
              onPressed: () => setState(
                () => _pollOptionControllers.add(TextEditingController()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
        ],
      ),
    );
  }

  Widget _buildAdInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Campaign Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            controller: _adAdvertiserController,
            label: 'Brand / Advertiser Name',
            hint: 'e.g. Nike, Apple, Your Business...',
            icon: Icons.business_rounded,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _adCtaTextController,
            label: 'Call to Action Button',
            hint: 'e.g. Shop Now, Join Today...',
            icon: Icons.touch_app_rounded,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _adCtaUrlController,
            label: 'Destination Web Address',
            hint: 'https://example.com/promo',
            icon: Icons.link_rounded,
            theme: theme,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Higher-quality media drives 2x more engagement.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

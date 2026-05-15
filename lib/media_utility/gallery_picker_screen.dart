// ================================================================
// FILE: lib/media_utility/gallery_picker_screen.dart
// Gallery Picker with Rotation Fix - UPDATED
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../widgets/app_snackbar.dart';
import '../widgets/logger.dart';

class GalleryPickerScreen extends StatefulWidget {
  final bool allowMultiple;
  final int maxSelection;
  final List<AssetType> allowedTypes;

  const GalleryPickerScreen({
    super.key,
    this.allowMultiple = false,
    this.maxSelection = 10,
    this.allowedTypes = const [AssetType.image, AssetType.video],
  });

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  final List<AssetEntity> _mediaList = [];
  final List<AssetEntity> _selectedMedia = [];

  bool _isLoading = true;
  bool _isProcessing = false;
  int _currentPage = 0;
  final int _pageSize = 50;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _requestPermission();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadMedia(loadMore: true);
    }
  }

  Future<void> _requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _loadAlbums();
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Please grant storage permission to access photos and videos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  PhotoManager.openSetting();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          videoOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );

      if (albums.isNotEmpty) {
        setState(() {
          _albums = albums;
          _currentAlbum = albums.first;
        });
        await _loadMedia();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      logE('Error loading albums: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMedia({bool loadMore = false}) async {
    if (_currentAlbum == null) return;

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 0;
      _mediaList.clear();
    }

    try {
      final List<AssetEntity> media = await _currentAlbum!.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          _mediaList.addAll(media);
          _isLoading = false;
        });
      }
    } catch (e) {
      logE('Error loading media: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(AssetEntity asset) {
    HapticFeedback.selectionClick();

    if (!widget.allowMultiple) {
      _selectedMedia.clear();
      _selectedMedia.add(asset);
      _handleDone();
      return;
    }

    setState(() {
      if (_selectedMedia.contains(asset)) {
        _selectedMedia.remove(asset);
      } else {
        if (_selectedMedia.length < widget.maxSelection) {
          _selectedMedia.add(asset);
        } else {
          AppSnackbar.warning('Maximum ${widget.maxSelection} items allowed');
        }
      }
    });
  }

  Future<void> _handleDone() async {
    if (_selectedMedia.isEmpty) {
      AppSnackbar.warning('Please select at least one item');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final files = <File>[];
      for (final asset in _selectedMedia) {
        final file = await asset.file;
        if (file != null) {
          if (asset.type == AssetType.image) {
            final fixedFile = await _fixImageRotation(file);
            files.add(fixedFile);
          } else {
            files.add(file);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, files);
      }
    } catch (e) {
      logE('Error processing files: $e');
      if (mounted) {
        AppSnackbar.error('Failed to process files');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File> _fixImageRotation(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return file;

      final fixedImage = img.bakeOrientation(image);
      final extension = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpg';
      final outputBytes = extension == 'png'
          ? img.encodePng(fixedImage)
          : img.encodeJpg(fixedImage, quality: 92);

      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/fixed_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile;
    } catch (e) {
      logE('Error fixing rotation: $e');
      return file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAlbumSelector(isDark),
        actions: [
          if (_selectedMedia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isProcessing ? null : _handleDone,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Next (${_selectedMedia.length})',
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _buildGrid(isDark),
    );
  }

  Widget _buildAlbumSelector(bool isDark) {
    return GestureDetector(
      onTap: _showAlbumPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentAlbum?.name ?? 'Recents',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  void _showAlbumPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Albums',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  final isSelected = _currentAlbum?.id == album.id;

                  return ListTile(
                    leading: Icon(
                      Icons.folder_rounded,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                    title: Text(
                      album.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data ?? 0}',
                          style: TextStyle(color: Colors.grey[500]),
                        );
                      },
                    ),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primary.withOpacity(
                      0.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() => _currentAlbum = album);
                      _loadMedia();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildGrid(bool isDark) {
    if (_mediaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No media found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _mediaList.length,
      itemBuilder: (context, index) {
        final asset = _mediaList[index];
        final isSelected = _selectedMedia.contains(asset);
        final selectionIndex = _selectedMedia.indexOf(asset) + 1;

        return _MediaGridItem(
          asset: asset,
          isSelected: isSelected,
          selectionIndex: widget.allowMultiple && isSelected
              ? selectionIndex
              : 0,
          onTap: () => _toggleSelection(asset),
        );
      },
    );
  }
}

class _MediaGridItem extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectionIndex;
  final VoidCallback onTap;

  const _MediaGridItem({
    required this.asset,
    required this.isSelected,
    required this.selectionIndex,
    required this.onTap,
  });

  @override
  State<_MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends State<_MediaGridItem> {
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(_MediaGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    try {
      final data = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
        quality: 80,
      );
      if (mounted) {
        setState(() => _thumbnail = data);
      }
    } catch (e) {
      logE('Error loading thumbnail', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbnail != null)
            Image.memory(_thumbnail!, fit: BoxFit.cover, gaplessPlayback: true)
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            ),
          if (widget.asset.type == AssetType.video)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(widget.asset.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              border: widget.isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                  : null,
              color: widget.isSelected ? Colors.black.withOpacity(0.2) : null,
            ),
          ),
          if (widget.isSelected && widget.selectionIndex > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.selectionIndex}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (!widget.isSelected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

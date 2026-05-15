import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_ui_provider.dart';
import '../../../../widgets/error_handler.dart';

class ChatWallpaperScreen extends StatefulWidget {
  final String chatId;
  const ChatWallpaperScreen({super.key, required this.chatId});

  @override
  State<ChatWallpaperScreen> createState() => _ChatWallpaperScreenState();
}

class _ChatWallpaperScreenState extends State<ChatWallpaperScreen> {
  String? _selectedWallpaper;
  final List<WallpaperOption> _wallpapers = [];

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uiProvider = context.read<ChatUIProvider>();
      uiProvider.setActiveChatId(widget.chatId);
      setState(() {
        _selectedWallpaper = uiProvider.wallpaperId;
      });
    });
  }

  Future<void> _loadWallpapers() async {
    setState(() {
      _wallpapers.addAll([
        WallpaperOption(
          id: 'default',
          name: 'None',
          imagePath: null,
          isDefault: true,
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/night_sky.png',
          name: 'Night Sky',
          imagePath: 'assets/chat_wallpaper/night_sky.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/scenery.png',
          name: 'Scenery',
          imagePath: 'assets/chat_wallpaper/scenery.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/abstract.png',
          name: 'Abstract',
          imagePath: 'assets/chat_wallpaper/abstract.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/nature.png',
          name: 'Nature',
          imagePath: 'assets/chat_wallpaper/nature.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/boy_thinking_night.jpg',
          name: 'Boy Thinking Night',
          imagePath: 'assets/chat_wallpaper/boy_thinking_night.jpg',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/cute_cat.jpg',
          name: 'Cute Cat',
          imagePath: 'assets/chat_wallpaper/cute_cat.jpg',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/couple_night.jpg',
          name: 'Couple Night',
          imagePath: 'assets/chat_wallpaper/couple_night.jpg',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/working_alone.jpg',
          name: 'Working Alone',
          imagePath: 'assets/chat_wallpaper/working_alone.jpg',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/boy_relaxing.png',
          name: 'Boy Relaxing',
          imagePath: 'assets/chat_wallpaper/boy_relaxing.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/landscape_1.png',
          name: 'Landscape 1',
          imagePath: 'assets/chat_wallpaper/landscape_1.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/landscape_2.png',
          name: 'Landscape 2',
          imagePath: 'assets/chat_wallpaper/landscape_2.png',
        ),
        WallpaperOption(
          id: 'assets/chat_wallpaper/landscape_3.png',
          name: 'Landscape 3',
          imagePath: 'assets/chat_wallpaper/landscape_3.png',
        ),
      ]);
    });
  }

  Future<void> _pickCustomWallpaper() async {
    try {
      HapticFeedback.lightImpact();
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedWallpaper = image.path;
        });
        ErrorHandler.showSuccessSnackbar('Custom wallpaper selected');
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'ChatWallpaperScreen.pickCustomWallpaper',
      );
    }
  }

  void _selectWallpaper(String id) {
    HapticFeedback.selectionClick();
    setState(() => _selectedWallpaper = id);
  }

  void _saveWallpaper() {
    HapticFeedback.mediumImpact();
    final uiProvider = context.read<ChatUIProvider>();
    uiProvider.setWallpaper(_selectedWallpaper);
    ErrorHandler.showSuccessSnackbar('Wallpaper updated');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'Chat Wallpaper',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(onPressed: _saveWallpaper, child: const Text('Save')),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              image: _getWallpaperImage(),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Preview',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Default section
                _buildSectionHeader(
                  'Default',
                  Icons.wallpaper_rounded,
                  colorScheme,
                ),
                const SizedBox(height: 8),
                _buildWallpaperTile(_wallpapers.first),

                const SizedBox(height: 16),

                // Wallpapers
                _buildSectionHeader(
                  'Wallpapers',
                  Icons.photo_library_rounded,
                  colorScheme,
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _wallpapers.where((w) => !w.isDefault).length,
                  itemBuilder: (context, index) {
                    final wallpapers = _wallpapers
                        .where((w) => !w.isDefault)
                        .toList();
                    final wallpaper = wallpapers[index];
                    return _buildImageTile(wallpaper);
                  },
                ),

                const SizedBox(height: 16),

                // Custom option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select your own image'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickCustomWallpaper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperTile(WallpaperOption wallpaper) {
    final isSelected = _selectedWallpaper == wallpaper.id;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _selectWallpaper(wallpaper.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  image: wallpaper.imagePath != null ? DecorationImage(
                    image: AssetImage(wallpaper.imagePath!),
                    fit: BoxFit.cover,
                  ) : null,
                  border: wallpaper.imagePath == null ? Border.all(color: Theme.of(context).dividerColor) : null,
                ),
                child: wallpaper.imagePath == null ? const Icon(Icons.block_rounded, size: 20, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallpaper.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(WallpaperOption wallpaper) {
    final isSelected = _selectedWallpaper == wallpaper.id;

    return InkWell(
      onTap: () => _selectWallpaper(wallpaper.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
          image: DecorationImage(
            image: AssetImage(wallpaper.imagePath!),
            fit: BoxFit.cover,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  DecorationImage? _getWallpaperImage() {
    String? path = _selectedWallpaper;
    if (path == null || path == 'default' || path.isEmpty) {
      return null;
    }

    if (path.startsWith('assets/')) {
      return DecorationImage(
        image: AssetImage(path),
        fit: BoxFit.cover,
      );
    } else {
      return DecorationImage(
        image: FileImage(File(path)),
        fit: BoxFit.cover,
      );
    }
  }
}

class WallpaperOption {
  final String id;
  final String name;
  final String? imagePath;
  final bool isDefault;

  WallpaperOption({
    required this.id,
    required this.name,
    this.imagePath,
    this.isDefault = false,
  });
}

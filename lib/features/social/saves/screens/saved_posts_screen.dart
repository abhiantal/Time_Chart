import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/saves/models/saves_model.dart';
import '../providers/save_provider.dart';
import '../widgets/saved_post_grid.dart';

class SavedPostsScreen extends StatefulWidget {
  final String userId;
  final String? initialCollection;
  final bool isOwnProfile;

  const SavedPostsScreen({
    super.key,
    required this.userId,
    this.initialCollection,
    this.isOwnProfile = true,
  });

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _selectedCollection;

  @override
  void initState() {
    super.initState();
    _selectedCollection = widget.initialCollection;
    _tabController = TabController(length: 2, vsync: this);
    _initializeProvider();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProvider() async {
    final provider = context.read<SaveProvider>();
    await provider.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SaveProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCollection ?? 'Saved',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: _selectedCollection == null && widget.isOwnProfile
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All Posts'),
                  Tab(text: 'Collections'),
                ],
              )
            : null,
        actions: [
          if (_selectedCollection != null && widget.isOwnProfile)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleCollectionAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Rename Collection'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Delete Collection',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (_selectedCollection != null && widget.isOwnProfile)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _selectedCollection = null);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedCollection == null && widget.isOwnProfile
          ? TabBarView(
              controller: _tabController,
              children: [
                SavedPostGrid(
                  userId: widget.userId,
                  isOwnProfile: widget.isOwnProfile,
                ),
                _buildCollectionsTab(theme, provider),
              ],
            )
          : SavedPostGrid(
              userId: widget.userId,
              initialCollection: _selectedCollection,
              isOwnProfile: widget.isOwnProfile,
            ),
    );
  }

  Widget _buildCollectionsTab(ThemeData theme, SaveProvider provider) {
    final collections = provider.collections.collections;

    if (collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No collections yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create collections to organize your saved posts',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _buildCollectionCard(theme, collection);
      },
    );
  }

  Widget _buildCollectionCard(ThemeData theme, SaveCollection collection) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCollection = collection.name;
        });
      },
      child: Card(
        elevation: 0,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: collection.hasThumbnail
                      ? DecorationImage(
                          image: NetworkImage(collection.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !collection.hasThumbnail
                    ? Center(
                        child: Icon(
                          collection.isDefault
                              ? Icons.collections_bookmark
                              : Icons.folder,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.3,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (collection.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: theme.textScheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collection.postCountText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (collection.lastUpdatedAgo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      collection.lastUpdatedAgo!,
                      style: theme.textScheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCollectionAction(String action) async {
    HapticFeedback.selectionClick();

    switch (action) {
      case 'rename':
        final newName = await _showRenameDialog();
        if (newName != null && newName.isNotEmpty) {
          await context.read<SaveProvider>().renameCollection(
            oldName: _selectedCollection!,
            newName: newName,
          );
        }
        break;

      case 'delete':
        final confirmed = await _showDeleteConfirmation();
        if (confirmed) {
          await context.read<SaveProvider>().deleteCollection(
            collectionName: _selectedCollection!,
            deleteSaves: false,
          );
          setState(() => _selectedCollection = null);
        }
        break;
    }
  }

  Future<String?> _showRenameDialog() async {
    final controller = TextEditingController(text: _selectedCollection);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Collection?'),
            content: Text(
              'Are you sure you want to delete "$_selectedCollection"? '
              'Posts will be moved to "All Saved".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

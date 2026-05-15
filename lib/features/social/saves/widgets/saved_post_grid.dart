import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../providers/save_provider.dart';
import '../models/saves_model.dart';
import 'note_editor.dart';
import 'collection_picker.dart';

class SavedPostGrid extends StatefulWidget {
  final String userId;
  final String? initialCollection;
  final bool isOwnProfile;

  const SavedPostGrid({
    super.key,
    required this.userId,
    this.initialCollection,
    this.isOwnProfile = true,
  });

  @override
  State<SavedPostGrid> createState() => _SavedPostGridState();
}

class _SavedPostGridState extends State<SavedPostGrid>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;
  String? _currentCollection;
  String? _searchQuery;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.initialCollection;
    _loadSavedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadMorePosts();
    }
  }

  Future<void> _loadSavedPosts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    await context.read<SaveProvider>().loadSavedPosts(
      collectionName: _currentCollection,
      refresh: refresh,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMorePosts() async {
    final provider = context.read<SaveProvider>();
    if (provider.savedPosts.hasMore && !_isLoading) {
      await provider.loadMoreSavedPosts();
    }
  }

  Future<void> _loadAvatar(String userId, String? url) async {
    if (url == null || _avatarCache.containsKey(userId)) return;

    final validUrl = await mediaService.getValidSignedUrl(url);
    if (mounted) {
      setState(() {
        _avatarCache[userId] = validUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final provider = context.watch<SaveProvider>();
    final savedPosts = provider.savedPosts;

    return Column(
      children: [
        // Collection header
        if (_currentCollection != null && provider.isInitialized)
          _buildCollectionHeader(context, theme, provider),

        // Search bar
        if (provider.isInitialized) _buildSearchBar(context, theme),

        // Posts grid
        Expanded(
          child: _isLoading && savedPosts.posts.isEmpty
              ? _buildLoadingState(theme)
              : savedPosts.posts.isEmpty
              ? _buildEmptyState(context, theme, provider)
              : _buildGrid(context, savedPosts.posts, theme),
        ),
      ],
    );
  }

  Widget _buildCollectionHeader(
    BuildContext context,
    ThemeData theme,
    SaveProvider provider,
  ) {
    final collection = provider.collections.findByName(_currentCollection!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              collection?.isDefault ?? false
                  ? Icons.collections_bookmark
                  : Icons.folder_special,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentCollection!,
                  style: theme.textScheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  collection?.postCountText ?? '0 posts',
                  style: theme.textScheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (collection?.lastUpdatedAgo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    collection!.lastUpdatedAgo!,
                    style: theme.textScheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (provider.isInitialized && collection?.isEditable == true)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) =>
                  _handleCollectionAction(context, value, _currentCollection!),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search saved posts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = null);
                    context.read<SaveProvider>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onChanged: (query) {
          setState(() => _searchQuery = query);
          context.read<SaveProvider>().searchSavedPosts(query);
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<SavedPost> posts,
    ThemeData theme,
  ) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        _loadAvatar(post.postUserId, post.postProfileUrl);

        return GestureDetector(
          onTap: () {
            // Navigate to post detail
          },
          onLongPress: () {
            if (widget.isOwnProfile) {
              _showPostOptions(context, post);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (post.thumbnailUrl != null)
                (post.thumbnailUrl!.startsWith('http') ||
                        post.thumbnailUrl!.startsWith('https'))
                    ? CachedNetworkImage(
                        imageUrl: post.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _buildErrorPlaceholder(theme),
                      )
                    : Image.file(
                        File(post.thumbnailUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildErrorPlaceholder(theme),
                      )
              else
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.text_snippet,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                ),

              // Video indicator
              if (post.postType == 'video' || post.postType == 'reel')
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

              // Multiple images indicator
              if (post.media != null && post.media!.length > 1)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${post.media!.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Note indicator
              if (post.hasNote)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // Collection badge (when viewing all)
              if (_currentCollection == null &&
                  !post.isInDefaultCollection &&
                  widget.isOwnProfile)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.collectionName,
                      style: theme.textScheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading saved posts...',
            style: theme.textScheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    SaveProvider provider,
  ) {
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
                _currentCollection == null
                    ? Icons.bookmark_border
                    : Icons.folder_open,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentCollection == null
                  ? 'No saved posts yet'
                  : 'No posts in this collection',
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentCollection == null
                  ? 'Posts you save will appear here'
                  : 'Add posts to this collection to see them here',
              style: theme.textScheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_currentCollection != null && widget.isOwnProfile)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to explore feed
                },
                icon: const Icon(Icons.explore),
                label: const Text('Discover Posts'),
              ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, SavedPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move to collection'),
              onTap: () {
                Navigator.pop(context);
                _movePostToCollection(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add/Edit note'),
              onTap: () {
                Navigator.pop(context);
                _editNote(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Remove from saved',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmRemove(post);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _movePostToCollection(SavedPost post) async {
    final newCollection = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => CollectionPicker(
        postId: post.postId,
        initialCollection: post.collectionName,
      ),
    );

    if (newCollection != null && newCollection != post.collectionName) {
      await context.read<SaveProvider>().moveToCollection(
        saveId: post.saveId,
        newCollectionName: newCollection,
      );
    }
  }

  Future<void> _editNote(SavedPost post) async {
    final newNote = await showDialog<String>(
      context: context,
      builder: (context) =>
          NoteEditor(initialNote: post.note, postTitle: post.contentPreview),
    );

    if (newNote != null) {
      await context.read<SaveProvider>().updateNote(
        saveId: post.saveId,
        note: newNote.isEmpty ? null : newNote,
      );
    }
  }

  Future<void> _confirmRemove(SavedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from saved'),
        content: const Text('Are you sure you want to remove this post?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<SaveProvider>().unsavePost(post.postId);
    }
  }

  Future<void> _handleCollectionAction(
    BuildContext context,
    String action,
    String collectionName,
  ) async {
    HapticFeedback.selectionClick();

    switch (action) {
      case 'rename':
        final newName = await _showRenameDialog(context, collectionName);
        if (newName != null) {
          await context.read<SaveProvider>().renameCollection(
            oldName: collectionName,
            newName: newName,
          );
          setState(() => _currentCollection = newName);
        }
        break;

      case 'delete':
        final confirmed = await _showDeleteCollectionDialog(context);
        if (confirmed) {
          await context.read<SaveProvider>().deleteCollection(
            collectionName: collectionName,
            deleteSaves: false,
          );
          setState(() => _currentCollection = null);
          Navigator.pop(context);
        }
        break;
    }
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new name'),
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

  Future<bool> _showDeleteCollectionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete collection'),
            content: const Text(
              'Posts in this collection will be moved to "All Saved". Continue?',
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

final mediaService = UniversalMediaService();

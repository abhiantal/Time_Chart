import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import '../../../../../media_utility/universal_media_service.dart';

class RecentViewersScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String currentUserId;

  const RecentViewersScreen({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.currentUserId,
  });

  @override
  State<RecentViewersScreen> createState() => _RecentViewersScreenState();
}

class _RecentViewersScreenState extends State<RecentViewersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;
  bool _isOwner = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.postOwnerId == widget.currentUserId;
    _tabController = TabController(length: _isOwner ? 3 : 1, vsync: this);
    _loadViewers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadMoreViewers();
    }
  }

  Future<void> _loadViewers({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // This would need a method in PostViewProvider to get recent viewers
      // For now, we'll use story viewers method as placeholder
      await context.read<PostViewProvider>().loadStoryViewers(
        storyId: widget.postId,
      );
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load viewers');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreViewers() async {
    if (_isLoading) return;
    await context.read<PostViewProvider>().loadMoreStoryViewers(widget.postId);
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
    final provider = context.watch<PostViewProvider>();
    final viewersList = provider.getStoryViewers(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwner ? 'Recent Views' : 'Viewers'),
        centerTitle: true,
        bottom: _isOwner
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                ],
              )
            : null,
      ),
      body: _isLoading && (viewersList?.viewers.isEmpty ?? true)
          ? _buildLoadingState(theme)
          : viewersList == null || viewersList.viewers.isEmpty
          ? _buildEmptyState(theme)
          : _buildViewersList(theme, viewersList),
    );
  }

  Widget _buildViewersList(ThemeData theme, StoryViewersListModel viewersList) {
    // Filter based on selected tab
    Iterable<StoryViewer> filteredViewers = viewersList.viewers;

    if (_isOwner) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));

      if (_tabController.index == 1) {
        filteredViewers = viewersList.viewers.where(
          (v) => v.viewedAt.isAfter(today),
        );
      } else if (_tabController.index == 2) {
        filteredViewers = viewersList.viewers.where(
          (v) => v.viewedAt.isAfter(weekAgo),
        );
      }
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredViewers.length + (viewersList.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredViewers.length) {
          return _buildLoadingMore();
        }

        final viewer = filteredViewers.elementAt(index);
        _loadAvatar(viewer.viewerUserId, viewer.viewerProfileUrl);

        return _buildViewerTile(theme, viewer);
      },
    );
  }

  Widget _buildViewerTile(ThemeData theme, StoryViewer viewer) {
    final isOwnView = viewer.viewerUserId == widget.currentUserId;
    final isOwnerView = viewer.viewerUserId == widget.postOwnerId;

    return ListTile(
      leading: GestureDetector(
        onTap: isOwnView ? null : () => _navigateToProfile(viewer.viewerUserId),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOwnerView
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: isOwnerView ? 2 : 1,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: _avatarCache[viewer.viewerUserId] != null
                ? NetworkImage(_avatarCache[viewer.viewerUserId]!)
                : null,
            child: _avatarCache[viewer.viewerUserId] == null
                ? Text(
                    (viewer.viewerDisplayName?.isNotEmpty == true ? viewer.viewerDisplayName! : viewer.viewerUsername).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isOwnView
                  ? 'You'
                  : isOwnerView
                  ? '${viewer.viewerDisplayName?.isNotEmpty == true ? viewer.viewerDisplayName! : viewer.viewerUsername} (Author)'
                  : (viewer.viewerDisplayName?.isNotEmpty == true ? viewer.viewerDisplayName! : viewer.viewerUsername),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isOwnView) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You',
                style: theme.textScheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDetailedTime(viewer.viewedAt),
            style: theme.textScheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_isOwner && !isOwnView) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Viewed for ${_getViewDuration()}',
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: _isOwner && !isOwnView
          ? IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showViewerOptions(viewer),
            )
          : null,
      onTap: isOwnView
          ? null
          : () {
              _navigateToProfile(viewer.viewerUserId);
            },
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
            'Loading viewers...',
            style: theme.textScheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
                Icons.visibility_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isOwner ? 'No views yet' : 'No one has viewed this post',
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isOwner
                  ? 'When people view your post, they will appear here'
                  : 'This post hasn\'t been viewed by anyone yet',
              style: theme.textScheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showViewerOptions(StoryViewer viewer) {
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
              leading: const Icon(Icons.person),
              title: const Text('View profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile(viewer.viewerUserId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Hide from this user'),
              onTap: () {
                Navigator.pop(context);
                // Implement hide functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text(
                'Block user',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(viewer.viewerUserId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showBlockConfirmation(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user?'),
        content: const Text(
          'They won\'t be able to see your posts or interact with you.',
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
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement block functionality
      AppSnackbar.info(title: 'User blocked');
    }
  }

  String _getDetailedTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getViewDuration() {
    // This would come from actual view duration data
    return '2.3s';
  }

  void _navigateToProfile(String userId) {
    if (userId == widget.currentUserId) {
      context.goNamed('personalNav');
    } else {
      context.pushNamed(
        'otherUserProfileScreen',
        pathParameters: {'userId': userId},
      );
    }
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

final mediaService = UniversalMediaService();

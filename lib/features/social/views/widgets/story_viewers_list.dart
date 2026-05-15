import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import '../../../../../media_utility/universal_media_service.dart';

class StoryViewersList extends StatefulWidget {
  final String storyId;
  final String storyOwnerId;
  final String currentUserId;

  const StoryViewersList({
    super.key,
    required this.storyId,
    required this.storyOwnerId,
    required this.currentUserId,
  });

  @override
  State<StoryViewersList> createState() => _StoryViewersListState();
}

class _StoryViewersListState extends State<StoryViewersList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.storyOwnerId == widget.currentUserId;
    _tabController = TabController(length: _isOwner ? 2 : 1, vsync: this);
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
      await context.read<PostViewProvider>().loadStoryViewers(
        storyId: widget.storyId,
      );
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Failed to load viewers');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreViewers() async {
    if (_isLoading) return;
    await context.read<PostViewProvider>().loadMoreStoryViewers(widget.storyId);
  }

  Future<void> _loadAvatar(String userId, String? url) async {
    if (url == null || _avatarCache.containsKey(userId)) return;

    final validUrl = await UniversalMediaService().getValidSignedUrl(url);
    if (mounted) {
      setState(() {
        _avatarCache[userId] = validUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PostViewProvider>();
    final viewersList = provider.getStoryViewers(widget.storyId);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Story Views',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viewersList?.viewerCountText ?? 'No views yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tabs (if owner)
              if (_isOwner)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'All Viewers'),
                      Tab(text: 'Insights'),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _isLoading && (viewersList?.viewers.isEmpty ?? true)
                    ? _buildLoadingState(theme)
                    : viewersList == null || viewersList.viewers.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildContent(theme, scrollController, viewersList),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ScrollController scrollController,
    StoryViewersListModel viewersList,
  ) {
    if (_isOwner && _tabController.index == 1) {
      return _buildInsightsTab(theme, viewersList);
    }

    return _buildViewersList(theme, scrollController, viewersList);
  }

  Widget _buildViewersList(
    ThemeData theme,
    ScrollController scrollController,
    StoryViewersListModel viewersList,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: viewersList.viewers.length + (viewersList.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == viewersList.viewers.length) {
          return _buildLoadingMore();
        }

        final viewer = viewersList.viewers[index];
        _loadAvatar(viewer.viewerUserId, viewer.viewerProfileUrl);

        return _buildViewerTile(theme, viewer);
      },
    );
  }

  Widget _buildViewerTile(ThemeData theme, StoryViewer viewer) {
    final isOwnView = viewer.viewerUserId == widget.currentUserId;

    return ListTile(
      leading: GestureDetector(
        onTap: isOwnView ? null : () => _navigateToProfile(viewer.viewerUserId),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
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
              isOwnView ? 'You' : (viewer.viewerDisplayName?.isNotEmpty == true ? viewer.viewerDisplayName! : viewer.viewerUsername),
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
      subtitle: Text(
        viewer.timeAgo,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: !isOwnView && widget.storyOwnerId == widget.currentUserId
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
              Navigator.pop(context);
              _navigateToProfile(viewer.viewerUserId);
            },
    );
  }

  Widget _buildInsightsTab(ThemeData theme, StoryViewersListModel viewersList) {
    final totalViews = viewersList.totalCount;
    final uniqueViewers = viewersList.viewers.length;
    final completionRate = totalViews > 0
        ? (viewersList.viewers
                  .where(
                    (v) => v.viewedAt.isAfter(
                      DateTime.now().subtract(const Duration(hours: 24)),
                    ),
                  )
                  .length /
              totalViews *
              100)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Stats cards
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: Icons.visibility,
                value: viewersList.formattedCount,
                label: 'Total Views',
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: Icons.people,
                value: uniqueViewers.toString(),
                label: 'Unique Viewers',
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: Icons.timer,
                value: '${completionRate.toStringAsFixed(0)}%',
                label: '24h Completion',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                theme,
                icon: Icons.schedule,
                value: _getAverageWatchTime(viewersList),
                label: 'Avg. Watch Time',
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Viewers over time
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Viewers over time',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: _buildViewersTimeline(theme, viewersList),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Top viewers
        if (viewersList.viewers.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Top viewers',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...viewersList.viewers.take(3).map((viewer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
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
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (viewer.viewerDisplayName?.isNotEmpty == true ? viewer.viewerDisplayName! : viewer.viewerUsername),
                          style: theme.textScheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Viewed ${_getTimeAgoDetailed(viewer.viewedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildInsightCard(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewersTimeline(
    ThemeData theme,
    StoryViewersListModel viewersList,
  ) {
    // Group viewers by hour
    final now = DateTime.now();
    final hours = List.generate(24, (i) {
      final hour = now.subtract(Duration(hours: 23 - i));
      return hour;
    });

    final viewersByHour = <DateTime, int>{};
    for (final hour in hours) {
      viewersByHour[hour] = 0;
    }

    for (final viewer in viewersList.viewers) {
      final viewerHour = DateTime(
        viewer.viewedAt.year,
        viewer.viewedAt.month,
        viewer.viewedAt.day,
        viewer.viewedAt.hour,
      );
      if (viewersByHour.containsKey(viewerHour)) {
        viewersByHour[viewerHour] = (viewersByHour[viewerHour] ?? 0) + 1;
      }
    }

    final maxViews = viewersByHour.values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: hours.map((hour) {
        final views = viewersByHour[hour] ?? 0;
        final height = maxViews > 0 ? (views / maxViews) * 80 : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hour.hour}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
              'No views yet',
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'When someone views your story,\nthey will appear here',
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
                Navigator.pop(context); // Close viewers list
                _navigateToProfile(viewer.viewerUserId);
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
          'They won\'t be able to see your stories or interact with you.',
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
      // Navigate to block flow
      // This would be handled by follow provider
    }
  }

  String _getAverageWatchTime(StoryViewersListModel viewersList) {
    // This would come from actual view duration data
    // For now return placeholder
    return '2.3s';
  }

  String _getTimeAgoDetailed(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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

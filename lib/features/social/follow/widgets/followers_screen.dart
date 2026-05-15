import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:the_time_chart/widgets/error_handler.dart';
import '../../../../../media_utility/universal_media_service.dart';
import '../providers/follow_provider.dart';
import '../models/follows_model.dart';
import 'follow_button.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String? initialSearch;

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.initialSearch,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;
  String? _searchQuery;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.text = widget.initialSearch ?? '';
    _searchQuery = widget.initialSearch;
    _loadFollowers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  Future<void> _loadFollowers({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    await context.read<FollowProvider>().loadFollowers(
      userId: widget.userId,
      refresh: refresh,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    await context.read<FollowProvider>().loadMoreFollowers(widget.userId);
  }

  Future<void> _search(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    // For search, we need to reload with search parameter
    // This would require repository method with search - for now just filter locally
    await context.read<FollowProvider>().loadFollowers(
      userId: widget.userId,
      refresh: true,
    );

    if (mounted) setState(() => _isLoading = false);
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
    final isOwnProfile = widget.userId == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Followers' : 'Followers'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search followers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                          _loadFollowers(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onSubmitted: _search,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowersList(theme, isOwnProfile),
                if (isOwnProfile)
                  _buildRequestsList(theme)
                else
                  _buildEmptyRequests(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersList(ThemeData theme, bool isOwnProfile) {
    final provider = context.watch<FollowProvider>();
    final followers = provider.currentFollowers;

    if (_isLoading && (followers?.users.isEmpty ?? true)) {
      return _buildLoadingState(theme);
    }

    if (followers == null || followers.users.isEmpty) {
      return _buildEmptyState(
        theme,
        isOwnProfile ? 'No followers yet' : 'No followers',
        isOwnProfile
            ? 'When someone follows you, they\'ll appear here'
            : 'This user has no followers yet',
      );
    }

    // Filter by search query
    final filteredUsers = _searchQuery != null && _searchQuery!.isNotEmpty
        ? followers.users
              .where(
                (u) =>
                    u.username.toLowerCase().contains(
                      _searchQuery!.toLowerCase(),
                    ) ||
                    (u.displayName.toLowerCase().contains(
                      _searchQuery!.toLowerCase(),
                    )),
              )
              .toList()
        : followers.users;

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(
        theme,
        'No results found',
        'No followers match your search',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredUsers.length + (followers.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredUsers.length) {
          return _buildLoadingMore();
        }

        final user = filteredUsers[index];
        _loadAvatar(user.userId, user.profileUrl);

        return _buildFollowerTile(theme, user, isOwnProfile);
      },
    );
  }

  Widget _buildFollowerTile(
    ThemeData theme,
    FollowerUser user,
    bool isOwnProfile,
  ) {
    final isCurrentUser = user.userId == widget.currentUserId;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(user.userId),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: user.isMutual
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: user.isMutual ? 2 : 1,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: _avatarCache[user.userId] != null
                ? (_avatarCache[user.userId]!.startsWith('http') ||
                              _avatarCache[user.userId]!.startsWith('https')
                          ? NetworkImage(_avatarCache[user.userId]!)
                          : FileImage(File(_avatarCache[user.userId]!)))
                      as ImageProvider
                : null,
            child: _avatarCache[user.userId] == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : '?',
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
              user.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (user.isVerified)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, size: 16, color: Colors.blue),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${user.username}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.bio!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person_add,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Followed ${user.followedTimeAgo}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (user.isMutual) ...[
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.people, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Mutual',
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: isOwnProfile && !isCurrentUser
          ? FollowButton(
              targetUserId: user.userId,
              size: FollowButtonSize.small,
              showIcon: true,
              username: user.username,
            )
          : null,
      onTap: () => _navigateToProfile(user.userId),
    );
  }

  Widget _buildRequestsList(ThemeData theme) {
    final provider = context.watch<FollowProvider>();
    final requests = provider.pendingRequests;

    if (provider.isLoading && requests.isEmpty) {
      return _buildLoadingState(theme);
    }

    if (requests.isEmpty) {
      return _buildEmptyState(
        theme,
        'No follow requests',
        'When someone requests to follow you, they\'ll appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        _loadAvatar(request.userId, request.profileUrl);

        return _buildRequestTile(theme, request);
      },
    );
  }

  Widget _buildRequestTile(ThemeData theme, FollowRequest request) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(request.userId),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: _avatarCache[request.userId] != null
              ? (_avatarCache[request.userId]!.startsWith('http') ||
                            _avatarCache[request.userId]!.startsWith('https')
                        ? NetworkImage(_avatarCache[request.userId]!)
                        : FileImage(File(_avatarCache[request.userId]!)))
                    as ImageProvider
              : null,
          child: _avatarCache[request.userId] == null
              ? Text(
                  request.displayName.isNotEmpty ? request.displayName.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        request.displayName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${request.username}',
            style: theme.textScheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested ${request.timeAgo}',
            style: theme.textScheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
            onPressed: () => _handleRequest(request.userId, accept: true),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: theme.colorScheme.error),
            onPressed: () => _handleRequest(request.userId, accept: false),
          ),
        ],
      ),
      onTap: () => _navigateToProfile(request.userId),
    );
  }

  Widget _buildEmptyRequests(ThemeData theme) {
    return _buildEmptyState(
      theme,
      'No access',
      'You can only view your own follow requests',
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
            'Loading...',
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

  Widget _buildEmptyState(ThemeData theme, String title, String message) {
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
                Icons.people_outline,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textScheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
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

  Future<void> _handleRequest(String followerId, {required bool accept}) async {
    try {
      final provider = context.read<FollowProvider>();
      if (accept) {
        await provider.acceptFollowRequest(followerId);
      } else {
        await provider.rejectFollowRequest(followerId);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar(
        'Failed to ${accept ? 'accept' : 'reject'} request',
      );
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

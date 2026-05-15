import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../../media_utility/universal_media_service.dart';
import '../providers/follow_provider.dart';
import '../models/follows_model.dart';
import 'follow_button.dart';
import 'follow_suggestions.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final String? initialSearch;

  const FollowingScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
    this.initialSearch,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String?> _avatarCache = {};
  bool _isLoading = false;
  String? _searchQuery;
  FollowRelationship? _selectedFilter;

  final List<_FilterChipOption> _filterOptions = const [
    _FilterChipOption(label: 'All', value: null),
    _FilterChipOption(
      label: 'Close Friends',
      value: FollowRelationship.closeFriend,
    ),
    _FilterChipOption(label: 'Favorites', value: FollowRelationship.favorite),
    _FilterChipOption(label: 'Muted', value: FollowRelationship.muted),
    _FilterChipOption(
      label: 'Restricted',
      value: FollowRelationship.restricted,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.text = widget.initialSearch ?? '';
    _searchQuery = widget.initialSearch;
    _loadFollowing();
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

  Future<void> _loadFollowing({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    await context.read<FollowProvider>().loadFollowing(
      userId: widget.userId,
      relationship: _selectedFilter,
      refresh: refresh,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    await context.read<FollowProvider>().loadMoreFollowing(
      widget.userId,
      relationship: _selectedFilter,
    );
  }

  Future<void> _search(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    await context.read<FollowProvider>().loadFollowing(
      userId: widget.userId,
      relationship: _selectedFilter,
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
        title: Text(isOwnProfile ? 'Following' : 'Following'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Suggestions'),
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
                hintText: 'Search following...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                          _loadFollowing(refresh: true);
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

          // Filter chips
          if (isOwnProfile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filterOptions.map((option) {
                  final isSelected = option.value == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(option.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? option.value : null;
                        });
                        _loadFollowing(refresh: true);
                      },
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      selectedColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowingList(theme, isOwnProfile),
                FollowSuggestions(
                  currentUserId: widget.currentUserId,
                  scrollDirection: Axis.vertical,
                  itemCount: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingList(ThemeData theme, bool isOwnProfile) {
    final provider = context.watch<FollowProvider>();
    final following = provider.currentFollowing;

    if (_isLoading && (following?.users.isEmpty ?? true)) {
      return _buildLoadingState(theme);
    }

    if (following == null || following.users.isEmpty) {
      return _buildEmptyState(
        theme,
        isOwnProfile ? 'Not following anyone' : 'No following',
        isOwnProfile
            ? 'Start following people to see their posts here'
            : 'This user is not following anyone yet',
      );
    }

    // Filter by search query
    final filteredUsers = _searchQuery != null && _searchQuery!.isNotEmpty
        ? following.users
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
        : following.users;

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(
        theme,
        'No results found',
        'No users match your search',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredUsers.length + (following.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredUsers.length) {
          return _buildLoadingMore();
        }

        final user = filteredUsers[index];
        _loadAvatar(user.userId, user.profileUrl);

        return _buildFollowingTile(theme, user, isOwnProfile);
      },
    );
  }

  Widget _buildFollowingTile(
    ThemeData theme,
    FollowingUser user,
    bool isOwnProfile,
  ) {
    // Determine the user ID to check against
    final isCurrentUser = user.userId == widget.currentUserId;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(user.userId),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor, width: 1),
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
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Since ${user.followedTimeAgo}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (user.isCloseFriend) ...[
                const SizedBox(width: 8),
                Icon(Icons.star, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Close Friend',
                  style: theme.textScheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: isOwnProfile
          ? PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: user.isCloseFriend
                      ? 'remove_close_friend'
                      : 'add_close_friend',
                  child: Row(
                    children: [
                      Icon(
                        user.isCloseFriend ? Icons.star_border : Icons.star,
                        color: user.isCloseFriend ? null : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isCloseFriend
                            ? 'Remove from Close Friends'
                            : 'Add to Close Friends',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: user.isMuted ? 'unmute' : 'mute',
                  child: Row(
                    children: [
                      Icon(user.isMuted ? Icons.volume_up : Icons.volume_off),
                      const SizedBox(width: 8),
                      Text(user.isMuted ? 'Unmute' : 'Mute'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unfollow',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Unfollow', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : (!isCurrentUser
                ? FollowButton(
                    targetUserId: user.userId,
                    size: FollowButtonSize.small,
                    showIcon: true,
                    username: user.username,
                  )
                : null),
      onTap: () => _navigateToProfile(user.userId),
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

  Future<void> _handleMenuAction(String action, FollowingUser user) async {
    final provider = context.read<FollowProvider>();

    switch (action) {
      case 'add_close_friend':
        await provider.addToCloseFriends(user.userId);
        break;
      case 'remove_close_friend':
        await provider.removeFromCloseFriends(user.userId);
        break;
      case 'mute':
        await provider.muteUser(user.userId);
        break;
      case 'unmute':
        await provider.unmuteUser(user.userId);
        break;
      case 'unfollow':
        await _confirmUnfollow(user);
        break;
    }
  }

  Future<void> _confirmUnfollow(FollowingUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfollow ${user.displayName}?'),
        content: const Text(
          'Are you sure you want to stop following this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FollowProvider>().toggleFollow(user.userId);
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

class _FilterChipOption {
  final String label;
  final FollowRelationship? value;

  const _FilterChipOption({required this.label, required this.value});
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

final mediaService = UniversalMediaService();

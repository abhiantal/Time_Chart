import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../../media_utility/universal_media_service.dart';
import 'package:the_time_chart/features/social/reactions/providers/reaction_provider.dart';

import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

class ReactionUsersSheet extends StatefulWidget {
  final ReactionTargetType targetType;
  final String targetId;
  final Map<String, dynamic>? reactionsCount;

  const ReactionUsersSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.reactionsCount,
  });

  @override
  State<ReactionUsersSheet> createState() => _ReactionUsersSheetState();
}

class _ReactionUsersSheetState extends State<ReactionUsersSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReactionType? _selectedFilter;
  List<ReactionTab> _tabs = [];
  bool _isLoading = false;
  final Map<String, String?> _avatarCache = {};

  @override
  void initState() {
    super.initState();
    _loadTabs();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabs() async {
    final tabs = await context.read<ReactionProvider>().loadReactionTabs(
      targetType: widget.targetType,
      targetId: widget.targetId,
    );

    if (mounted) {
      setState(() {
        _tabs = tabs;
        _tabController = TabController(length: tabs.length, vsync: this);
        _tabController.addListener(_onTabChanged);
      });
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final selectedTab = _tabs[_tabController.index];
      setState(() {
        _selectedFilter = selectedTab.type;
      });
      _loadUsers(refresh: true);
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    setState(() => _isLoading = true);

    await context.read<ReactionProvider>().loadReactionUsers(
      targetType: widget.targetType,
      targetId: widget.targetId,
      filterType: _selectedFilter,
      forceRefresh: refresh,
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
    final theme = Theme.of(context);
    final reactionProvider = context.watch<ReactionProvider>();
    final usersList = reactionProvider.getReactionUsers(
      targetType: widget.targetType,
      targetId: widget.targetId,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Reactions',
                      style: theme.textScheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tabs
              if (_tabs.isNotEmpty)
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
                    tabs: _tabs.map((tab) {
                      return Tab(
                        child: Row(
                          children: [
                            if (tab.emoji != null) ...[
                              Text(tab.emoji!),
                              const SizedBox(width: 4),
                            ],
                            Text(tab.displayLabel),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const Divider(height: 1),

              // Users list
              Expanded(
                child: _isLoading && (usersList?.users.isEmpty ?? true)
                    ? _buildLoadingState(theme)
                    : usersList == null || usersList.users.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildUsersList(
                        context,
                        scrollController,
                        usersList.users,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    ScrollController scrollController,
    List<ReactionUser> users,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        _loadAvatar(user.userId, user.profileUrl);

        return ListTile(
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: _avatarCache[user.userId] != null
                  ? (_avatarCache[user.userId]!.startsWith('http') ||
                                _avatarCache[user.userId]!.startsWith('https')
                            ? NetworkImage(_avatarCache[user.userId]!)
                            : FileImage(File(_avatarCache[user.userId]!)))
                        as ImageProvider
                  : null,
              child: _avatarCache[user.userId] == null
                  ? Text(
                      (user.displayName?.isNotEmpty == true ? user.displayName! : user.username).substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          title: Row(
            children: [
              Text(
                user.displayName?.isNotEmpty == true ? user.displayName! : user.username,
                style: Theme.of(
                  context,
                ).textScheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                user.reactionType.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          subtitle: Text(
            user.timeAgo,
            style: Theme.of(context).textScheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (user.userId != context.read<ReactionProvider>().currentUserId) {
              context.pushNamed(
                'otherUserProfileScreen',
                pathParameters: {'userId': user.userId},
              );
            }
          },
        );
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
            'Loading reactions...',
            style: theme.textScheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_emotions_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No reactions yet',
              style: theme.textScheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to react!',
              style: theme.textScheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

// Global media service instance
final mediaService = UniversalMediaService();

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_bar_animated.dart';
import '../../widgets/search/search_empty_state.dart';
import '../../widgets/search/search_result_tile.dart';
import '../../widgets/search/search_history_list.dart';
import '../../model/chat_model.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const GlobalSearchScreen({super.key, this.initialQuery});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ChatProvider _searchProvider;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _focusNode.requestFocus();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _isSearching = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchProvider.searchNow(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _searchProvider.searchNow('');
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _isSearching = query.isNotEmpty);
    _searchProvider.searchNow(query);
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() => _isSearching = false);
    _searchProvider.searchNow('');
  }

  void _navigateToResult(ChatSearchResult result) {
    switch (result.type) {
      case SearchResultType.chat:
        context.pushNamed(
          'chatRoomScreen',
          pathParameters: {'chatId': result.chatId},
        );
        break;
      case SearchResultType.message:
        context.pushNamed(
          'chatRoomScreen',
          pathParameters: {'chatId': result.chatId},
          extra: {'initialMessageId': result.id},
        );
        break;
      case SearchResultType.contact:
        context.pushNamed(
          'chatProfileScreen',
          pathParameters: {'userId': result.senderId!},
        );
        break;
      default:
        break;
    }
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
        title: SearchBarAnimated(
          controller: _searchController,
          focusNode: _focusNode,
          hintText: 'Search messages, chats, people...',
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
          autofocus: true,
        ),
        bottom: _isSearching
            ? TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Chats'),
                  Tab(text: 'Messages'),
                ],
              )
            : null,
      ),
      body: _isSearching ? _buildSearchResults() : _buildEmptyState(),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingShimmerList(itemCount: 5);
        }

        if (!provider.hasResults) {
          return SearchEmptyState(
            type: EmptyStateType.noSearchResults,
            searchQuery: _searchController.text,
            onAction: _clearSearch,
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildAllResults(provider),
            _buildChatsResults(provider),
            _buildMessagesResults(provider),
          ],
        );
      },
    );
  }

  Widget _buildAllResults(ChatProvider provider) {
    final grouped = provider.groupedUniversalResults;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (grouped.containsKey(SearchResultType.chat))
          _ResultSection(
            title: 'Chats',
            icon: Icons.chat_rounded,
            results: provider.chatResults,
            onSeeAll: () => _tabController.animateTo(1),
            onResultTap: _navigateToResult,
          ),
        if (grouped.containsKey(SearchResultType.message))
          _ResultSection(
            title: 'Messages',
            icon: Icons.message_rounded,
            results: provider.messageSearchResults,
            onSeeAll: () => _tabController.animateTo(2),
            onResultTap: _navigateToResult,
          ),
        if (grouped.containsKey(SearchResultType.contact))
          _ResultSection(
            title: 'People',
            icon: Icons.person_rounded,
            results: provider.contactResults,
            onSeeAll: null,
            onResultTap: _navigateToResult,
          ),
      ],
    );
  }

  Widget _buildChatsResults(ChatProvider provider) {
    final chats = provider.chatResults;

    if (chats.isEmpty) {
      return const Center(child: Text('No chats found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final result = chats[index];
        return SearchResultTile.chat(
          result: result,
          onTap: () => _navigateToResult(result),
        );
      },
    );
  }

  Widget _buildMessagesResults(ChatProvider provider) {
    final messages = provider.messageSearchResults;

    if (messages.isEmpty) {
      return const Center(child: Text('No messages found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final result = messages[index];
        return SearchResultTile.message(
          result: result as MessageSearchResult,
          onTap: () => _navigateToResult(result),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSearchTips(),
                const Divider(height: 32),
                const SearchHistoryList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search tips',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _SearchTip(
            icon: Icons.chat_rounded,
            title: 'Chats',
            description: 'Search by chat name',
            color: colorScheme.primary,
          ),
          _SearchTip(
            icon: Icons.message_rounded,
            title: 'Messages',
            description: 'Search by message content',
            color: colorScheme.secondary,
          ),
          _SearchTip(
            icon: Icons.person_rounded,
            title: 'People',
            description: 'Search by name or username',
            color: colorScheme.tertiary,
          ),
          _SearchTip(
            icon: Icons.photo_library_rounded,
            title: 'Media',
            description: 'Search photos, videos, documents',
            color: colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _SearchTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _SearchTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(description, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ChatSearchResult> results;
  final VoidCallback? onSeeAll;
  final Function(ChatSearchResult) onResultTap;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.results,
    required this.onSeeAll,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        ...results
            .take(3)
            .map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchResultTile.chat(
                  result: result,
                  onTap: () => onResultTap(result),
                ),
              ),
            ),
        const Divider(height: 24),
      ],
    );
  }
}

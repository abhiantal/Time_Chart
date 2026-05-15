import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';

import '../../providers/chat_provider.dart';
import '../../widgets/common/empty_state_illustration.dart' show EmptyStateType;
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_empty_state.dart';
import '../../widgets/search/search_result_tile.dart';
import '../../model/chat_model.dart';

class ChatSearchResultsScreen extends StatefulWidget {
  final String query;
  final Map<String, dynamic>? filters;

  const ChatSearchResultsScreen({super.key, required this.query, this.filters});

  @override
  State<ChatSearchResultsScreen> createState() =>
      _ChatSearchResultsScreenState();
}

class _ChatSearchResultsScreenState extends State<ChatSearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<ChatProvider>();
      await provider.searchNow(widget.query);

      setState(() => _isLoading = false);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatSearchResultsScreen.performSearch');
      setState(() => _isLoading = false);
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '"${widget.query}"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Chats'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 8)
          : Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (!provider.hasResults) {
                  return SearchEmptyState(
                    type: EmptyStateType.noSearchResults,
                    searchQuery: widget.query,
                    onAction: () => Navigator.pop(context),
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
            ),
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
            title: 'Contacts',
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
              (res) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchResultTile.chat(
                  result: res,
                  onTap: () => onResultTap(res),
                ),
              ),
            ),
        const Divider(height: 24),
      ],
    );
  }
}

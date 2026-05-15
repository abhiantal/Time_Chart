import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';

import '../../providers/chat_provider.dart';
import '../../model/chat_model.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_empty_state.dart';
import '../../widgets/search/search_result_tile.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isSearching = query.isNotEmpty);
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    try {
      final provider = context.read<ChatProvider>();
      provider.searchNow(query);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatSearchScreen.performSearch');
    }
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<ChatProvider>().searchNow('');
  }

  void _openFilters() {
    HapticFeedback.lightImpact();
    context.pushNamed('chatSearchFiltersScreen').then((_) {
      // Refresh search with new filters
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
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
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search chats, messages, media...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: Icon(Icons.tune_rounded, color: colorScheme.primary),
          ),
        ],
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
                  Tab(text: 'Media'),
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
            _buildMediaResults(provider),
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
          ),
        if (grouped.containsKey(SearchResultType.message))
          _ResultSection(
            title: 'Messages',
            icon: Icons.message_rounded,
            results: provider.messageSearchResults,
            onSeeAll: () => _tabController.animateTo(2),
          ),
        if (grouped.containsKey(SearchResultType.contact))
          _ResultSection(
            title: 'Contacts',
            icon: Icons.person_rounded,
            results: provider.contactResults,
            onSeeAll: () => _tabController.animateTo(1),
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
          onTap: () {
            context.pushNamed(
              'chatRoomScreen',
              pathParameters: {'chatId': result.chatId},
            );
          },
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
          onTap: () {
            if (result.message?.chatId != null) {
              context.pushNamed(
                'chatRoomScreen',
                pathParameters: {'chatId': result.message!.chatId},
                extra: {'initialMessageId': result.message!.id},
              );
            }
          },
        );
      },
    );
  }

  Widget _buildMediaResults(ChatProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = provider.mediaResults;

    if (media.isEmpty) {
      return const Center(child: Text('No media found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return GestureDetector(
          onTap: () {
            context.pushNamed(
              'chatMediaScreen',
              pathParameters: {'chatId': item.chatId},
              extra: {
                'initialMediaId': item.id,
                'mediaType': item.type.toJson(),
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              image: item.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.isVideo
                ? const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 32,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Everything',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Find chats, messages, media, and people',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
  final VoidCallback onSeeAll;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.results,
    required this.onSeeAll,
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
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        ...results
            .take(3)
            .map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchResultTile.chat(result: result),
              ),
            ),
        const Divider(height: 24),
      ],
    );
  }
}

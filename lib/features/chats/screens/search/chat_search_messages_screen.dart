import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../model/chat_model.dart';
import '../../widgets/common/empty_state_illustration.dart' show EmptyStateType;
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_empty_state.dart';
import '../../widgets/search/search_result_tile.dart';

class ChatSearchMessagesScreen extends StatefulWidget {
  final String chatId;

  const ChatSearchMessagesScreen({super.key, required this.chatId});

  @override
  State<ChatSearchMessagesScreen> createState() =>
      _ChatSearchMessagesScreenState();
}

class _ChatSearchMessagesScreenState extends State<ChatSearchMessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _initializeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeSearch() {
    try {
      final provider = context.read<ChatProvider>();
      provider.setActiveChatId(widget.chatId);
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'ChatSearchMessagesScreen.initializeSearch',
      );
    }
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
      provider.searchInChat(query);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatSearchMessagesScreen.performSearch');
    }
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<ChatProvider>().clearAll();
  }

  void _navigateToResult(String messageId) {
    Navigator.pop(context, messageId);
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
              hintText: 'Search messages...',
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
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _isSearching) {
            return const LoadingShimmerList(itemCount: 5);
          }

          if (_isSearching && !provider.hasResults) {
            return SearchEmptyState(
              type: EmptyStateType.noSearchResults,
              searchQuery: _searchController.text,
              onAction: _clearSearch,
              compact: true,
            );
          }

          if (!_isSearching) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              if (provider.hasResults)
                _buildNavigationBar(provider, theme, colorScheme),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messageResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final result = provider.messageResults[index];
                    final isHighlighted = index == provider.currentResultIndex;

                    return SearchResultTile.message(
                      result: MessageSearchResult(
                        message: result.message,
                        subtitle: result.subtitle,
                        senderName: result.title,
                      ),
                      isHighlighted: isHighlighted,
                      onTap: () => _navigateToResult(result.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationBar(
    ChatProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${provider.totalSearchResults} results',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: provider.currentResultIndex > 0
                ? provider.previousResult
                : null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: provider.currentResultIndex > 0
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            iconSize: 20,
          ),
          IconButton(
            onPressed:
                provider.currentResultIndex < provider.totalSearchResults - 1
                ? provider.nextResult
                : null,
            icon: Icon(
              Icons.arrow_downward_rounded,
              color:
                  provider.currentResultIndex < provider.totalSearchResults - 1
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Messages',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Find specific messages in this chat',
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

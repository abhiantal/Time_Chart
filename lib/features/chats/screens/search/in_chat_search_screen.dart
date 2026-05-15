import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/search/search_empty_state.dart';
import '../../model/chat_model.dart';
import '../../widgets/search/search_result_tile.dart';

class InChatSearchScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;

  const InChatSearchScreen({super.key, required this.chatId, this.chatName});

  @override
  State<InChatSearchScreen> createState() => _InChatSearchScreenState();
}

class _InChatSearchScreenState extends State<InChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ChatProvider _searchProvider;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSearch();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _searchProvider.clearAll();
    super.dispose();
  }

  void _initializeSearch() {
    try {
      _searchProvider.setActiveChatId(widget.chatId);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'InChatSearchScreen.initializeSearch');
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    try {
      _searchProvider.searchInChat(query);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'InChatSearchScreen.performSearch');
    }
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    _searchProvider.clearAll();
  }

  void _navigateToResult(String messageId) {
    Navigator.pop(context, messageId);
  }

  void _previousResult() {
    _searchProvider.previousResult();
  }

  void _nextResult() {
    _searchProvider.nextResult();
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
              hintText: 'Search "${widget.chatName ?? 'chat'}"',
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
          if (provider.isLoading && _searchController.text.isNotEmpty) {
            return const LoadingShimmerList(itemCount: 5);
          }

          if (_searchController.text.isEmpty) {
            return _buildEmptyState();
          }

          if (!provider.hasResults) {
            return SearchEmptyState(
              type: EmptyStateType.noSearchResults,
              searchQuery: _searchController.text,
              onAction: _clearSearch,
              compact: true,
            );
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
                      onTap: () {
                        final msgId = result.message?.id;
                        if (msgId != null && msgId.isNotEmpty) {
                          _navigateToResult(msgId);
                        }
                      },
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
            onPressed: provider.currentResultIndex > 0 ? _previousResult : null,
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
                ? _nextResult
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search in chat',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Find messages, media, or links shared in this chat',
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

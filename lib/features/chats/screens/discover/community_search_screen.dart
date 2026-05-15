import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../../personal/category_model/providers/category_provider.dart' as cat_prov;
import '../../../personal/category_model/models/category_model.dart' as cat_model;
import '../../model/chat_model.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';
import '../../widgets/search/search_empty_state.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;
  bool _isLoading = false;
  final List<ChatModel> _searchResults = [];

  // Categories for suggestions from CategoryProvider
  List<cat_model.Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoryProvider = context.read<cat_prov.CategoryProvider>();
    // Try to load categories if not already loaded
    await categoryProvider.loadCategoriesByType('community');
    final categories = categoryProvider.getCategoriesByType('community');
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isSearching = query.isNotEmpty);
        if (query.isNotEmpty) {
          _performSearch(query);
        } else {
          setState(() => _searchResults.clear());
        }
      }
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      setState(() => _isLoading = true);

      final chatProvider = context.read<ChatProvider>();
      final results = await chatProvider.getPublicCommunities(query: query);

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'CommunitySearchScreen.performSearch');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _selectCategory(cat_model.Category category) {
    context.pushNamed(
      'communityCategoriesScreen',
      pathParameters: {
        'categoryId': category.id,
        'categoryName': category.categoryType,
      },
    );
  }

  void _previewCommunity(ChatModel community) {
    context.pushNamed(
      'communityPreviewScreen',
      pathParameters: {'communityId': community.id},
      extra: community,
    );
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
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search communities...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? _isLoading
                ? const LoadingShimmerList(itemCount: 8)
                : _searchResults.isEmpty
                ? SearchEmptyState(
                    type: EmptyStateType.noSearchResults,
                    searchQuery: _searchController.text,
                    onAction: _clearSearch,
                    compact: true,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final community = _searchResults[index];
                      return _SearchResultCard(
                        community: community,
                        onTap: () => _previewCommunity(community),
                      );
                    },
                  )
          : _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_categories.isNotEmpty) ...[
          Text(
            'Explore Categories',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.take(12).map((category) {
              return InkWell(
                onTap: () => _selectCategory(category),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.categoryType,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
        
        Text(
          'Popular Searches',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSearchHistoryItem('Flutter Development'),
        _buildSearchHistoryItem('AI & Machine Learning'),
        _buildSearchHistoryItem('Gaming Community'),
      ],
    );
  }

  Widget _buildSearchHistoryItem(String term) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(Icons.history_rounded, color: colorScheme.onSurfaceVariant),
      title: Text(term, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.north_west_rounded, size: 16, color: colorScheme.outline),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        _searchController.text = term;
        _onSearchChanged(term);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ChatModel community;
  final VoidCallback onTap;

  const _SearchResultCard({required this.community, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'community_avatar_${community.id}',
                  child: UserAvatarCached(
                    imageUrl: community.avatar,
                    name: community.name ?? '',
                    size: 56,
                    isGroup: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              community.name ?? 'Unnamed Community',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (community.metadata['is_verified'] == true)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${community.totalMembers} members',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (community.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          community.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

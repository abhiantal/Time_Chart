import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../../personal/category_model/providers/category_provider.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';

class CommunityCategoriesScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const CommunityCategoriesScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<CommunityCategoriesScreen> createState() =>
      _CommunityCategoriesScreenState();
}

class _CommunityCategoriesScreenState extends State<CommunityCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<CategoryWithCommunities> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final categoryProvider = context.read<CategoryProvider>();
      final chatProvider = context.read<ChatProvider>();
      
      // Get real community categories
      final realCategories = categoryProvider.getCategoriesByType('community');
      
      if (realCategories.isEmpty) {
        await categoryProvider.loadCategoriesByType('community');
      }
      
      final updatedCategories = categoryProvider.getCategoriesByType('community');
      
      // Fetch communities for each category (simplified for now - load first few or current)
      _categories.clear();
      
      for (final cat in updatedCategories) {
        final communities = await chatProvider.getPublicCommunities(
          categoryId: cat.id,
          limit: 10,
        );
        
        _categories.add(
          CategoryWithCommunities(
            id: cat.id,
            name: cat.categoryType,
            icon: Icons.category_rounded, // Should map from cat.icon string
            color: _parseColor(cat.color),
            communities: communities,
          ),
        );
      }

      if (mounted) {
        _tabController = TabController(length: _categories.length, vsync: this);

        if (widget.initialCategoryId != null) {
          final index = _categories.indexWhere(
            (c) => c.id == widget.initialCategoryId,
          );
          if (index >= 0) {
            _tabController.index = index;
          }
        } else if (widget.initialCategoryName != null) {
             final index = _categories.indexWhere(
              (c) => c.name == widget.initialCategoryName,
            );
            if (index >= 0) {
              _tabController.index = index;
            }
        }

        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'CommunityCategoriesScreen.loadCategories',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
    }
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
        title: Text(
          'Categories',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: _isLoading || _categories.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                isScrollable: true,
                tabs: _categories
                    .map((category) => Tab(text: category.name))
                    .toList(),
              ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : _categories.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.category_outlined,
              title: 'No Categories',
              description: 'Categories will appear here',
              compact: true,
            )
          : TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _CategoryCommunitiesList(
                  category: category,
                  onCommunityTap: _previewCommunity,
                );
              }).toList(),
            ),
    );
  }
}

class CategoryWithCommunities {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<ChatModel> communities;

  CategoryWithCommunities({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.communities,
  });
}

class _CategoryCommunitiesList extends StatelessWidget {
  final CategoryWithCommunities category;
  final Function(ChatModel) onCommunityTap;

  const _CategoryCommunitiesList({
    required this.category,
    required this.onCommunityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category.communities.length,
      itemBuilder: (context, index) {
        final community = category.communities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            onTap: () => onCommunityTap(community),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                community.name ?? 'Community',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (community.metadata['is_verified'] == true)
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${community.totalMembers} members',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.description ?? '',
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

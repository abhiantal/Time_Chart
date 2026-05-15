import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../../../widgets/feature_info_widgets.dart';

import '../../../personal/category_model/providers/category_provider.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';
import 'community_categories_screen.dart';

class DiscoverCommunitiesScreen extends StatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  State<DiscoverCommunitiesScreen> createState() =>
      _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState extends State<DiscoverCommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<ChatModel> _featuredCommunities = [];
  final List<ChatModel> _popularCommunities = [];
  final List<ChatModel> _newCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<ChatProvider>();
      
      // Fetch data in parallel
      final results = await Future.wait([
        provider.getFeaturedCommunities(),
        provider.getTrendingCommunities(),
        provider.getNewCommunities(),
      ]);

      if (mounted) {
        setState(() {
          _featuredCommunities.clear();
          _featuredCommunities.addAll(results[0]);
          
          _popularCommunities.clear();
          _popularCommunities.addAll(results[1]);
          
          _newCommunities.clear();
          _newCommunities.addAll(results[2]);
          
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'DiscoverCommunitiesScreen.loadCommunities',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinCommunity(ChatModel community) async {
    HapticFeedback.mediumImpact();
    final result = await context.read<ChatProvider>().joinCommunity(community.id);
    
    if (result.success) {
      ErrorHandler.showSuccessSnackbar('Joined ${community.name ?? 'Community'}');
    } else {
      ErrorHandler.showErrorSnackbar(result.error ?? 'Failed to join community');
    }
  }

  void _previewCommunity(ChatModel community) {
    context.pushNamed(
      'communityPreviewScreen',
      pathParameters: {'communityId': community.id},
      extra: community,
    );
  }

  void _searchCommunities() {
    context.pushNamed('communitySearchScreen');
  }

  void _viewCategory(String categoryId, String categoryName) {
    context.pushNamed(
      'communityCategoriesScreen',
      extra: {'initialCategoryId': categoryId, 'initialCategoryName': categoryName},
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
          'Discover Communities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => FeatureInfoCard.showEliteDialog(
              context,
              EliteFeatures.community,
            ),
            icon: Icon(Icons.help_outline_rounded, color: colorScheme.primary),
          ),
          IconButton(
            onPressed: _searchCommunities,
            icon: Icon(Icons.search_rounded, color: colorScheme.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Popular'),
            Tab(text: 'New'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFeaturedTab(),
                _buildCommunitiesList(_popularCommunities),
                _buildCommunitiesList(_newCommunities),
                const CommunityCategoriesScreen(),
              ],
            ),
    );
  }

  Widget _buildFeaturedTab() {
    return ListView(
      children: [
        const SizedBox(height: 16),
        if (_featuredCommunities.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredCommunities.length,
              itemBuilder: (context, index) {
                final community = _featuredCommunities[index];
                return _FeaturedCard(
                  community: community,
                  onTap: () => _previewCommunity(community),
                  onJoin: () => _joinCommunity(community),
                );
              },
            ),
          )
        else if (!_isLoading)
           _buildFeaturedEmptyState(),
        
        const SizedBox(height: 24),
        _buildSectionHeader(
          'Popular Communities',
          () => _tabController.animateTo(1),
        ),
        _buildCommunitiesList(
          _popularCommunities.take(3).toList(),
          isCompact: true,
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(
          'New & Trending',
          () => _tabController.animateTo(2),
        ),
        _buildCommunitiesList(
          _newCommunities.take(3).toList(),
          isCompact: true,
        ),
        const SizedBox(height: 24),
        _buildExploreCategories(),
      ],
    );
  }

  Widget _buildFeaturedEmptyState() {
     return Container(
       height: 160,
       margin: const EdgeInsets.symmetric(horizontal: 16),
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
       ),
       child: Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), size: 32),
             const SizedBox(height: 8),
             Text('No featured communities yet', style: Theme.of(context).textTheme.bodyMedium),
           ],
         ),
       ),
     );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }

  Widget _buildCommunitiesList(
    List<ChatModel> communities, {
    bool isCompact = false,
  }) {
    if (communities.isEmpty && !_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('No communities found', style: Theme.of(context).textTheme.bodySmall)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return _CommunityCard(
          community: community,
          isCompact: isCompact,
          onTap: () => _previewCommunity(community),
          onJoin: () => _joinCommunity(community),
        );
      },
    );
  }

  Widget _buildExploreCategories() {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = categoryProvider.getCategoriesByType('community').take(6).toList();

    if (categories.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                name: category.categoryType,
                icon: _getCategoryIcon(category.icon),
                color: _getCategoryColor(category.color),
                onTap: () => _viewCategory(category.id, category.categoryType),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    if (icon == null) return Icons.category_rounded;
    return Icons.category_rounded;
  }

  Color _getCategoryColor(String? colorStr) {
     if (colorStr == null) return Colors.blue;
     try {
       final value = int.parse(colorStr.replaceFirst('#', '0xFF'));
       return Color(value);
     } catch (_) {
       return Colors.blue;
     }
  }
}

class _FeaturedCard extends StatelessWidget {
  final ChatModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _FeaturedCard({
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: community.banner != null
            ? DecorationImage(
                image: NetworkImage(community.banner!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.4),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: community.banner == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.secondary],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatarCached(
                      imageUrl: community.avatar,
                      name: community.name ?? 'Community',
                      size: 48,
                      isGroup: true,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (community.metadata['is_verified'] == true)
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${community.totalMembers} members',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  community.description ?? '',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: community.rulesList
                            .take(2)
                            .map(
                              (rule) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  rule,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                      ),
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final ChatModel community;
  final bool isCompact;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _CommunityCard({
    required this.community,
    required this.isCompact,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatarCached(
                imageUrl: community.avatar,
                name: community.name ?? 'Community',
                size: isCompact ? 40 : 48,
                isGroup: true,
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
                            size: 16,
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
                    if (!isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.description ?? '',
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

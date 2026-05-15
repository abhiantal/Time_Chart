import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_handler.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

class TrendingCommunitiesScreen extends StatefulWidget {
  const TrendingCommunitiesScreen({super.key});

  @override
  State<TrendingCommunitiesScreen> createState() => _TrendingCommunitiesScreenState();
}

class _TrendingCommunitiesScreenState extends State<TrendingCommunitiesScreen> {
  bool _isLoading = true;
  final List<ChatModel> _trendingCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      setState(() => _isLoading = true);

      final chatProvider = context.read<ChatProvider>();
      final results = await chatProvider.getTrendingCommunities();

      if (mounted) {
        setState(() {
          _trendingCommunities.clear();
          _trendingCommunities.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'TrendingCommunitiesScreen.loadTrending');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Trending Communities',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 8)
          : _trendingCommunities.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.trending_up_rounded,
              title: 'No Trending Communities',
              description: 'Check back later for trending communities',
              compact: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _trendingCommunities.length,
              itemBuilder: (context, index) {
                final community = _trendingCommunities[index];
                return _TrendingCard(
                  community: community,
                  rank: index + 1,
                  onTap: () => _previewCommunity(community),
                );
              },
            ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final ChatModel community;
  final int rank;
  final VoidCallback onTap;

  const _TrendingCard({
    required this.community,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: rank <= 3
              ? Colors.amber.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: _getRankColor(rank),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Avatar
              UserAvatarCached(
                imageUrl: community.avatar,
                name: community.name ?? '',
                size: 48,
                isGroup: true,
              ),
              const SizedBox(width: 16),

              // Content
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
                      community.metadata['category_name']?.toString() ?? 'General',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.totalMembers} members',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.trending_up_rounded,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trending',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}

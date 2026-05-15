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

class RecommendedCommunitiesScreen extends StatefulWidget {
  const RecommendedCommunitiesScreen({super.key});

  @override
  State<RecommendedCommunitiesScreen> createState() =>
      _RecommendedCommunitiesScreenState();
}

class _RecommendedCommunitiesScreenState
    extends State<RecommendedCommunitiesScreen> {
  bool _isLoading = true;
  final List<ChatModel> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() => _isLoading = true);

      final chatProvider = context.read<ChatProvider>();
      // Using public communities as 'recommendations' for now
      final results = await chatProvider.getPublicCommunities(limit: 15);

      if (mounted) {
        setState(() {
          _recommendations.clear();
          _recommendations.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'RecommendedCommunitiesScreen.loadRecommendations',
      );
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

  void _refreshRecommendations() {
    HapticFeedback.mediumImpact();
    _loadRecommendations();
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
          'Recommended for You',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshRecommendations,
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 8)
          : _recommendations.isEmpty
          ? EmptyStateIllustration(
              type: EmptyStateType.custom,
              icon: Icons.recommend_rounded,
              title: 'No Recommendations',
              description:
                  'We\'ll recommend communities based on your interests',
              compact: true,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final community = _recommendations[index];
                return _RecommendationCard(
                  community: community,
                  // Pseudo-score based on index for visual flair
                  matchScore: 99 - (index * 2),
                  onTap: () => _previewCommunity(community),
                );
              },
            ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ChatModel community;
  final int matchScore;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.community,
    required this.matchScore,
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
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Match score badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$matchScore%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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
              const SizedBox(width: 12),

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
                              fontWeight: FontWeight.bold,
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
                    if (community.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_rounded, size: 12, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${community.totalMembers} members',
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
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
}

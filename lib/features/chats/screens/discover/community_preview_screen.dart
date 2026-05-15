import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/user_avatar_cached.dart';
import '../../widgets/community/community_rules_list.dart';
import '../../widgets/community/community_stats_widget.dart';
import '../../model/chat_model.dart';
import '../../../../widgets/app_snackbar.dart';

class CommunityPreviewScreen extends StatefulWidget {
  final ChatModel? community;
  final String? communityId;

  const CommunityPreviewScreen({super.key, this.community, this.communityId});

  @override
  State<CommunityPreviewScreen> createState() => _CommunityPreviewScreenState();
}

class _CommunityPreviewScreenState extends State<CommunityPreviewScreen> {
  bool _isJoining = false;
  bool _isMember = false;
  ChatModel? _community;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.community != null) {
      _community = widget.community;
      _isLoading = false;
      _checkMembership();
    } else if (widget.communityId != null) {
      _loadCommunity(widget.communityId!);
    } else {
      _isLoading = false;
    }
  }

  void _checkMembership() {
    if (_community != null) {
      // In a real app, we'd check if the current user is in community.members
      // For now, if myRole is not null, we are a member
      setState(() {
        _isMember = _community!.myRole != null;
      });
    }
  }

  Future<void> _loadCommunity(String id) async {
    try {
      setState(() => _isLoading = true);
      
      final chatProvider = context.read<ChatProvider>();
      final community = await chatProvider.getChatById(id);
      
      if (mounted) {
        setState(() {
          _community = community;
          _isLoading = false;
          _checkMembership();
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'CommunityPreviewScreen.loadCommunity');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_community == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: const Center(child: Text('Community not found')),
      );
    }

    final community = _community!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  if (community.banner != null)
                    Image.network(
                      community.banner!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colorScheme.primary, colorScheme.tertiary],
                        ),
                      ),
                    ),
                  // Dark Overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.black54,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  // Community Info in FlexSpace
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: UserAvatarCached(
                                imageUrl: community.avatar,
                                name: community.name ?? 'Community',
                                size: 80,
                                isGroup: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            community.name ?? 'Community',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (community.metadata['is_verified'] == true)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: Icon(
                                              Icons.verified_rounded,
                                              color: Colors.blueAccent,
                                              size: 22,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${community.totalMembers} members',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
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
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: CommunityStatsWidget(
                    memberCount: community.totalMembers,
                    onlineCount: (community.totalMembers * 0.12).toInt(),
                    postCount: (community.metadata['post_count'] as int?) ?? 0,
                    createdAt: community.createdAt,
                  ),
                ),

                // Description section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        community.description ?? 'No description provided for this community.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 32),
                ),

                // Rules section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Rules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (community.rulesList.isEmpty)
                        Text(
                          'No specific rules listed. Follow standard app guidelines.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        CommunityRulesList(
                          rules: community.rulesList,
                          isEditable: false,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _isMember
                  ? FilledButton.tonalIcon(
                      onPressed: () {
                        context.goNamed(
                          'chatConversationScreen',
                          pathParameters: {'chatId': community.id},
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Open Community'),
                    )
                  : FilledButton.icon(
                      onPressed: _isJoining ? null : _joinCommunity,
                      icon: _isJoining
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.group_add_rounded),
                      label: Text(_isJoining ? 'Joining...' : 'Join Community'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinCommunity() async {
    try {
      setState(() => _isJoining = true);

      final chatProvider = context.read<ChatProvider>();
      final result = await chatProvider.joinCommunity(_community!.id);

      if (result.success) {
        if (mounted) {
          setState(() {
            _isJoining = false;
            _isMember = true;
          });

          AppSnackbar.success('Welcome to ${_community!.name}!');

          // Give a small delay before navigating to chat
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              context.goNamed(
                'chatConversationScreen',
                pathParameters: {'chatId': _community!.id},
              );
            }
          });
        }
      } else {
        throw result.error ?? 'Failed to join community';
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'CommunityPreviewScreen.joinCommunity');
      if (mounted) {
        setState(() => _isJoining = false);
        AppSnackbar.error('Failed to join', description: '$e');
      }
    }
  }
}

// ================================================================
// FILE: lib/screens_widgets/profile/user_profile_screen.dart
// Complete Profile Page with Views/Edit capabilities
// ================================================================

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/analytics/competition/screens/competitions_list_screen.dart';
import '../../../media_utility/universal_media_service.dart';
import '../../../widgets/logger.dart';
import 'package:the_time_chart/features/analytics/competition/providers/competition_provider.dart';
import 'package:the_time_chart/features/social/follow/widgets/followers_screen.dart';
import 'package:the_time_chart/features/social/follow/widgets/following_screen.dart';
import 'package:the_time_chart/user_profile/view_profile/widgets/profile_menu.dart';
import 'package:the_time_chart/user_profile/view_profile/widgets/profile_tab_content.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import '../../../core/Mode/Mode_bottom_sheet.dart';
import '../../../features/social/post/providers/post_provider.dart'; // Add this import
import '../../../../widgets/app_snackbar.dart';
import '../../../features/chats/screens/discover/community_preview_screen.dart';

// Feature Providers
import '../../../features/social/follow/providers/follow_provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import '../../create_edit_profile/profile_models.dart';
import '../../create_edit_profile/profile_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _ProfileSocialPageState();
}

class _ProfileSocialPageState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  UserProfile? _profile;
  String? _validAvatarUrl;

  // Stats
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _competitionsCount = 0;

  // Relationships
  bool _isFollowing = false;
  bool _isCompeting = false;

  // Services
  final UniversalMediaService mediaService = UniversalMediaService();
  Future<String?>? _avatarFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Called when an inherited widget (like a Provider) that this widget depends on changes.
  /// This is the safe place to read context.watch results and mutate state.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isOwnProfile) {
      final providerProfile = context.read<ProfileProvider>().myProfile;
      if (providerProfile != null && providerProfile != _profile) {
        // Capture old URL before reassigning _profile
        final oldUrl = _profile?.profileUrl;
        _profile = providerProfile;
        if (_isLoading) _isLoading = false;
        // Reset avatar future only if the avatar URL actually changed
        final newUrl = providerProfile.profileUrl;
        if (newUrl != oldUrl) {
          _avatarFuture = newUrl != null
              ? mediaService.getValidAvatarUrl(newUrl)
              : Future.value(null);
        }
      }
    }
  }

  Future<void> _loadProfile() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final userProvider = context.read<ProfileProvider>();
      final followProvider = context.read<FollowProvider>();
      final competitionProvider = context.read<BattleChallengeProvider>();

      // 1. Load Profile Data First
      UserProfile? profile;
      if (widget.userId == null) {
        // Only load if not already loaded to speed up
        if (userProvider.myProfile == null) {
          // Show loading only if we really need to fetch the profile itself
          setState(() => _isLoading = true);
          await userProvider.loadMyProfile();
        }
        profile = userProvider.myProfile;
      } else {
        setState(() => _isLoading = true);
        profile = await userProvider.getProfileById(widget.userId!);
      }

      if (profile == null) {
        if (mounted) {
          setState(() {
            _profile = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Show profile immediately if we have it
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          // Pre-initialize stats from socialStats 
          // Use explicit type to avoid any analyzer confusion
          final UserProfile p = profile!;
          final stats = p.socialStats;
          _followersCount = stats.followersCount;
          _followingCount = stats.followingCount;
          _postsCount = stats.postsCount;
          _competitionsCount = stats.competitionsCount;
        });
      }

      if (!mounted) return;
      final postProvider = context.read<PostProvider>();

      // 2. Load Stats in Background
      int followers = 0;
      int following = 0;
      int competitions = 0;
      int postCount = 0;
      bool isFollowing = false;
      bool isCompeting = false;
      String? validUrl;

      final currentUserId = userProvider.myProfile?.id;

      try {
        // Load leaderboard independently to avoid type issues with Future.wait
        final followersFuture = followProvider.getFollowersCount(profile.id);
        final followingFuture = followProvider.getFollowingCount(profile.id);
        // final competitionFuture = CompetitionService().getCompetitionList(
        //   profile.id,
        // );
        final avatarFuture = profile.profileUrl != null
            ? mediaService.getValidAvatarUrl(profile.profileUrl)
            : Future.value(null);
        final postCountFuture = postProvider.getPostCount(profile.id);

        final results = await Future.wait<Object?>([
          followersFuture,
          followingFuture,
          //  competitionFuture,
          avatarFuture,
          postCountFuture,
        ]);

        logI(
          'Stats loaded - Followers: ${results[0]}, Following: ${results[1]}, Posts: ${results[3]}',
        );
        if (profile.organizationName == null ||
            profile.organizationName!.isEmpty) {
          logD('Profile has no organization name (this is optional)');
        } else {
          logD('Organization: ${profile.organizationName}');
        }

        followers = results[0] as int;
        following = results[1] as int;
        // final comps = results[2] as List<CompetitionData>;
        validUrl = results[2] as String?;
        postCount = results[3] as int;

        // competitions = comps.length;

        // Relationship checks
        if (currentUserId != null && profile.id != currentUserId) {
          // Check following status
          isFollowing = await followProvider.isFollowing(profile.id);

          // Ensure competitions are loaded
          if (!competitionProvider.isInitialized) {
            await competitionProvider.initialize(currentUserId);
          }

          isCompeting = competitionProvider.isCompetingWith(profile.id);
        } else if (currentUserId != null && profile.id == currentUserId) {
          if (!competitionProvider.isInitialized) {
            await competitionProvider.initialize(currentUserId);
          }
          competitions = competitionProvider.battlingMeCount;
        }
      } catch (e, stackTrace) {
        logE(
          'Error loading profile leaderboard',
          error: e,
          stackTrace: stackTrace,
        );
        // Do not rethrow, just let the profile render with default leaderboard
      }

      if (mounted) {
        setState(() {
          // Update leaderboard without showing loading indicator again
          _validAvatarUrl = validUrl;
          // Refresh avatar future with resolved URL to avoid re-fetching
          if (validUrl != null) _avatarFuture = Future.value(validUrl);
          _followersCount = followers;
          _followingCount = following;
          _competitionsCount = competitions;
          _postsCount = postCount;
          _isFollowing = isFollowing;
          _isCompeting = isCompeting;
        });
      }
    });
  }

  bool get _isOwnProfile =>
      widget.userId == null ||
      (context.read<ProfileProvider>().myProfile?.id == widget.userId);

  Future<void> _handleFollowToggle() async {
    if (_profile == null) return;
    final userProvider = context.read<ProfileProvider>();
    final followProvider = context.read<FollowProvider>();
    final currentUserId = userProvider.myProfile?.id;

    if (currentUserId == null) return;

    final result = await followProvider.toggleFollow(_profile!.id);

    if (result?.success == true && mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });
    }
  }

  Future<void> _handleCompetitionToggle() async {
    if (_profile == null) return;
    final userProvider = context.read<ProfileProvider>();
    final competitionProvider = context.read<BattleChallengeProvider>();
    final currentUserId = userProvider.myProfile?.id;

    if (currentUserId == null) return;

    bool success = false;
    final targetName = _profile!.displayName;

    if (_isCompeting) {
      // "Delete competition" / "Remove competitor" logic
      success = await competitionProvider.removeCompetitor(_profile!.id);
      if (mounted) {
        if (success) {
          AppSnackbar.success(
            'Competitor Removed',
            description: '$targetName is no longer in your battle.',
          );
        } else {
          AppSnackbar.error(
            'Failed to Remove',
            description:
                competitionProvider.error ?? 'Please check your connection.',
          );
        }
      }
    } else {
      // "Create competition" / "Add competitor" logic
      success = await competitionProvider.addCompetitor(_profile!.id);
      if (mounted) {
        if (success) {
          AppSnackbar.success(
            'Battle Started!',
            description: 'You are now competing with $targetName.',
          );
        } else {
          AppSnackbar.error(
            'Failed to Add',
            description:
                competitionProvider.error ?? 'Please check your connection.',
          );
        }
      }
    }

    if (success && mounted) {
      setState(() {
        _isCompeting = !_isCompeting;
        if (_isCompeting) {
          _competitionsCount++;
        } else {
          _competitionsCount--;
        }
      });
    }
  }

  /// Starts a one-on-one chat with the user
  Future<void> _startChat() async {
    if (_profile == null) return;

    if (!_profile!.openToChat) {
      AppSnackbar.info(title: 'User not allowing public chats');
      return;
    }

    try {
      final chatRepo = ChatRepository();
      final result = await chatRepo.getOrCreateDirectChat(_profile!.id);
      if (result.success && result.data != null && mounted) {
        context.pushNamed(
          'chatRoomScreen',
          pathParameters: {'chatId': result.data!},
        );
      } else {
        throw Exception(result.error ?? 'Unknown error');
      }
    } catch (e, s) {
      logE('Error starting chat', error: e, stackTrace: s);
      if (mounted) {
        AppSnackbar.error(
          'Failed to start chat',
          description: 'Please try again later.',
        );
      }
    }
  }

  /// Opens the user's community preview/info
  void _openCommunity() {
    final communityId = _profile?.promotedCommunityId ?? _profile?.createdCommunityId;
    if (communityId != null && communityId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityPreviewScreen(communityId: communityId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safely read the provider — no state mutation inside build()
    // (Watching is fine; _profile is updated via didChangeDependencies below)
    if (_isOwnProfile) {
      context.watch<ProfileProvider>(); // subscribe for rebuilds only
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? _buildErrorState(theme)
          : _buildProfileContent(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDebugInfo(theme),
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Profile not found', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Unable to load profile information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildProfileAppBar(theme),
            _buildProfileInfoSliver(theme),
            _buildTabBarSliver(theme),
          ];
        },
        body: _buildTabContent(theme),
      ),
    );
  }

  /// Pinned App Bar
  Widget _buildProfileAppBar(ThemeData theme) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      titleSpacing: 0,
      // Custom leading for non-own profile to match "Other" style
      leading: !_isOwnProfile
          ? IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            )
          : null, // Default back button

      title: Row(
        children: [
          // Add spacing if using default leading or no leading
          if (_isOwnProfile) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _profile!.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${_profile!.username}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Community Button (Created or Promoted)
        if ((_profile!.createdCommunityId != null &&
                _profile!.createdCommunityId!.isNotEmpty) ||
            (_profile!.promotedCommunityId != null &&
                _profile!.promotedCommunityId!.isNotEmpty))
          IconButton(
            onPressed: _openCommunity,
            tooltip: 'View Community',
            icon: Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
          ),
        if (_isOwnProfile)
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Customize App',
            onPressed: () {
              // This is the static method we created in ModeBottomSheet
              ModeBottomSheet.show(context);
            },
          ),

        // Reuse the already-resolved avatar future — never create a new one in build()
        FutureBuilder<String?>(
          future: _avatarFuture,
          builder: (context, snapshot) {
            return ProfileMenu(
              profile: _profile!,
              isOwnProfile: _isOwnProfile,
              validAvatarUrl: snapshot.data ?? _validAvatarUrl,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Profile Info as a scrollable box
  Widget _buildProfileInfoSliver(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture & Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                _buildProfilePicture(theme),
                const SizedBox(width: 16),

                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location & Organization
                      if (_profile?.address != null ||
                          _profile?.organizationName != null)
                        _buildLocationRow(theme),

                      // Influencer Badge
                      if (_profile?.isInfluencer == true &&
                          _profile?.influencerCategory != null)
                        _buildInfluencerRow(theme),

                      // Message for Followers
                      if (_profile?.messageForFollower != null)
                        _buildMessageRow(theme),

                      // Message for Strength
                      // Message for Strength
                      if (_profile?.isInfluencer == false &&
                          _profile?.primaryGoal != null)
                        _buildGoalRow(theme),

                      // Message for Strength
                      if (_profile?.isInfluencer == false &&
                          _profile?.strengths != null &&
                          _profile!.strengths.isNotEmpty)
                        _buildStrengthsRow(theme),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats Row
            _buildStatsRow(theme),

            // Action Buttons
            if (!_isOwnProfile) ...[
              const SizedBox(height: 16),
              _buildActionButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _handleFollowToggle,
                style: FilledButton.styleFrom(
                  backgroundColor: _isFollowing
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary,
                  foregroundColor: _isFollowing
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimary,
                ),
                child: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
            if (!_isOwnProfile) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _startChat,
                  child: const Text('Message'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleCompetitionToggle,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isCompeting
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              backgroundColor: _isCompeting
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : null,
            ),
            child: Text(
              _isCompeting ? 'Remove Competitor' : 'Battle / Compete',
            ),
          ),
        ),
      ],
    );
  }

  /// Location and Organization Row
  Widget _buildLocationRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (_profile?.address != null) ...[
            Icon(
              Icons.location_on_outlined,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _profile!.address!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          if (_profile?.address != null && _profile?.organizationName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '•',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_profile?.organizationName != null) ...[
            Icon(
              Icons.business_outlined,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _profile!.organizationName!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Influencer Badge Row
  Widget _buildInfluencerRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.verified, color: Colors.blue, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _profile!.influencerCategory!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Message for Followers Row
  Widget _buildMessageRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_outlined,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _profile!.messageForFollower!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.ac_unit, color: theme.colorScheme.primary, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _profile?.primaryGoal ??
                  '', // Use null-aware operator instead of !
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.stacked_line_chart,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _profile?.strengths.join(', ') ?? '', // Use null-aware operators
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Stats Row - Horizontal layout
  Widget _buildStatsRow(ThemeData theme) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            theme,
            _followersCount.toString(),
            'Followers',
            onTap: () {
              if (_profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(
                      userId: _profile!.id,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              }
            },
          ),
          _buildDivider(theme),
          _buildStatItem(
            theme,
            _followingCount.toString(),
            'Following',
            onTap: () {
              if (_profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowingScreen(
                      userId: _profile!.id,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              }
            },
          ),
          _buildDivider(theme),
          _buildStatItem(
            theme,
            _competitionsCount.toString(),
            'Competitions',
            onTap: () {
              if (_profile != null) {
                if (_profile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompetitionsListScreen(
                        userId: _profile!.id,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          _buildDivider(theme),
          _buildStatItemWithStream(
            theme,
            context.read<PostProvider>().watchPostCount(_profile!.id),
            _postsCount.toString(),
            'Posts',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 40,
      width: 1,
      color: theme.colorScheme.outlineVariant,
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWithStream(
    ThemeData theme,
    Stream<int> stream,
    String fallbackValue,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                final val = snapshot.hasData
                    ? (snapshot.data as int).toString()
                    : fallbackValue;
                return Text(
                  val,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(ThemeData theme) {
    // Lazily create the avatar future only once (not on each rebuild)
    _avatarFuture ??= _profile?.profileUrl != null
        ? mediaService.getValidAvatarUrl(_profile!.profileUrl)
        : Future.value(null);

    return Hero(
      tag: 'profile_${_profile!.id}',
      child: Container(
        width: 106,
        height: 106,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FutureBuilder<String?>(
          future: _avatarFuture,
          builder: (context, snapshot) {
            final effectiveUrl = snapshot.data ?? _validAvatarUrl;

            // Local file (cached offline)
            if (effectiveUrl != null &&
                !effectiveUrl.startsWith('http') &&
                File(effectiveUrl).existsSync()) {
              return ClipOval(
                child: Image.file(
                  File(effectiveUrl),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            }

            // Remote URL via CachedNetworkImage
            if (effectiveUrl != null && effectiveUrl.startsWith('http')) {
              return ClipOval(
                child: CachedNetworkImage(
                  imageUrl: effectiveUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            }

            // Fallback icon
            return CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 50,
                color: theme.colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebugInfo(ThemeData theme) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🐛 DEBUG INFO',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Text(
            'Profile URL: ${_profile?.profileUrl ?? "NULL"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Username: ${_profile?.username ?? "NULL"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Email: ${_profile?.email ?? "NULL"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Org Name: ${_profile?.organizationName ?? "NULL"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Primary Goal: ${_profile?.primaryGoal ?? "NULL"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Strengths: ${_profile?.strengths.join(", ") ?? "[]"}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Weaknesses: ${_profile?.weaknesses.join(", ") ?? "[]"}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// TabBar as Sliver
  Widget _buildTabBarSliver(ThemeData theme) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelMedium,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on_rounded, size: 22), text: 'Posts'),
            Tab(icon: Icon(Icons.feed_outlined, size: 22), text: 'Live'),
            Tab(icon: Icon(Icons.camera_outlined, size: 22), text: 'Snapshot'),
            Tab(icon: Icon(Icons.auto_awesome_mosaic_outlined, size: 22), text: 'Custom'),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    return TabBarView(
      controller: _tabController,
      children: [
        ProfileTabContent(
          userId: _profile!.id,
          title: 'Posts',
          tabType: 'posts',
        ),
        ProfileTabContent(userId: _profile!.id, title: 'Live', tabType: 'live'),
        ProfileTabContent(
          userId: _profile!.id,
          title: 'Snapshot',
          tabType: 'snapshot',
        ),
        ProfileTabContent(
          userId: _profile!.id,
          title: 'Custom',
          tabType: 'custom',
        ),
      ],
    );
  }
}

/// Custom delegate for pinned TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

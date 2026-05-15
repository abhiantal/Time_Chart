// ================================================================
// FILE: lib/features/analytics/leaderboard/screens/stats_screen.dart
//
// Premium leaderboard screen using LeaderboardProvider + LeaderboardEntry.
// Features:
//   • Animated podium (top 3) with rank-colour glow rings
//   • Tap profile image → navigate to UserProfileScreen
//   • Premium rank badge with medal / crown / fire icons
//   • Expandable / collapsible row cards (rank 4+) with scratch cards
//   • Rank-tier badge per entry (rankSentinel → rankElite → none)
//   • Live sub-stat bars using your CustomProgressIndicator
//   • Pull-to-refresh & auto-refresh via provider
//   • Current-user highlight + sticky "Your Rank" chip
// ================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../media_utility/universal_media_service.dart';

import '../../../../reward_tags/reward_enums.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../../../../reward_tags/reward_scratch_card.dart';
import '../../../../widgets/logger.dart';
import '../../../../user_profile/create_edit_profile/profile_models.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';
import '../../dashboard_sidebar.dart';
import '../models/user_stats_model.dart';
import '../providers/user_stats_provider.dart';
import '../../../personal/task_model/day_tasks/screens/task_form_bottom_sheet.dart';
import '../../../../user_profile/view_profile/screens/user_profile_screen.dart';
import '../../../../widgets/feature_info_widgets.dart';

// ── Rank-tier display data ────────────────────────────────────────
class _RankTierInfo {
  final String emoji;
  final String label;
  final Color color;
  final Color glowColor;

  const _RankTierInfo({
    required this.emoji,
    required this.label,
    required this.color,
    required this.glowColor,
  });
}

_RankTierInfo _tierInfoFor(RewardTier tier) {
  switch (tier) {
    case RewardTier.rankSentinel:
      return const _RankTierInfo(
        emoji: '🦄',
        label: 'Mystic Sentinel',
        color: Color(0xFFD946EF),
        glowColor: Color(0x55D946EF),
      );
    case RewardTier.rankVanguard:
      return const _RankTierInfo(
        emoji: '🔱',
        label: 'Vanguard Supreme',
        color: Color(0xFF6366F1),
        glowColor: Color(0x556366F1),
      );
    case RewardTier.rankGodsend:
      return const _RankTierInfo(
        emoji: '💫',
        label: 'Godsend Alpha',
        color: Color(0xFFEAB308),
        glowColor: Color(0x55EAB308),
      );
    case RewardTier.rankIcon:
      return const _RankTierInfo(
        emoji: '💠',
        label: 'Ice Icon',
        color: Color(0xFF06B6D4),
        glowColor: Color(0x5506B6D4),
      );
    case RewardTier.rankLegend:
      return const _RankTierInfo(
        emoji: '🐉',
        label: 'Legend Unbound',
        color: Color(0xFF15803D),
        glowColor: Color(0x5515803D),
      );
    case RewardTier.rankMaster:
      return const _RankTierInfo(
        emoji: '🏹',
        label: 'Master Tactician',
        color: Color(0xFFF59E0B),
        glowColor: Color(0x55F59E0B),
      );
    case RewardTier.rankElite:
      return const _RankTierInfo(
        emoji: '🐲',
        label: 'Dragon Vanguard',
        color: Color(0xFF16A34A),
        glowColor: Color(0x5516A34A),
      );
    default:
      return const _RankTierInfo(
        emoji: '⭐',
        label: 'Contender',
        color: Color(0xFF64748B),
        glowColor: Color(0x3364748B),
      );
  }
}

// ── Podium rank colours ───────────────────────────────────────────
Color _podiumColor(int rank) {
  if (rank == 1) return const Color(0xFFFFD700);
  if (rank == 2) return const Color(0xFFC0C0C0);
  return const Color(0xFFCD7F32);
}

// ── Rank number aesthetics ────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isCurrentUser;
  const _RankBadge({required this.rank, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Special cosmetics for top 10
    final Color badgeColor;
    final String rankLabel;
    final Widget? iconWidget;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700);
      rankLabel = '';
      iconWidget = const Text('👑', style: TextStyle(fontSize: 18));
    } else if (rank == 2) {
      badgeColor = const Color(0xFFC0C0C0);
      rankLabel = '';
      iconWidget = const Text('🥈', style: TextStyle(fontSize: 16));
    } else if (rank == 3) {
      badgeColor = const Color(0xFFCD7F32);
      rankLabel = '';
      iconWidget = const Text('🥉', style: TextStyle(fontSize: 16));
    } else if (rank <= 10) {
      badgeColor = isCurrentUser ? cs.primary : const Color(0xFF6366F1);
      rankLabel = '#$rank';
      iconWidget = null;
    } else {
      badgeColor = isCurrentUser ? cs.primary : cs.surfaceContainerHighest;
      rankLabel = '#$rank';
      iconWidget = null;
    }

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: rank <= 3
            ? RadialGradient(
                colors: [
                  badgeColor.withValues(alpha: 0.95),
                  badgeColor.withValues(alpha: 0.6),
                ],
              )
            : null,
        color: rank > 3 ? badgeColor.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badgeColor.withValues(alpha: rank <= 3 ? 0.8 : 0.35),
          width: rank <= 3 ? 2 : 1.5,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child:
          iconWidget ??
          Text(
            rankLabel,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isCurrentUser || rank <= 10
                  ? badgeColor
                  : cs.onSurfaceVariant,
              fontSize: rank > 99 ? 11 : 14,
            ),
          ),
    );
  }
}

// ================================================================
// SCREEN
// ================================================================

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final AnimationController _listAnim;
  final Set<String> _expandedIds = {}; // userId → expanded

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  void _toggle(String userId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedIds.contains(userId)) {
        _expandedIds.remove(userId);
      } else {
        _expandedIds.add(userId);
      }
    });
  }

  void _navigateToProfile(BuildContext context, String userId) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Consumer<LeaderboardProvider>(
        builder: (_, provider, __) {
          return NestedScrollView(
            headerSliverBuilder: (_, innerScrolled) => [
              _buildAppBar(theme, cs, isDark, provider, innerScrolled),
            ],
            body: _buildBody(theme, cs, isDark, provider),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    LeaderboardProvider provider,
    bool innerScrolled,
  ) {
    final myRank = provider.currentUserRank;
    final myEntry = provider.currentUserEntry;
    final total = provider.totalParticipants;

    return SliverAppBar(
      expandedHeight: 230,
      floating: false,
      pinned: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => DashboardSidebarController.to.toggleSidebar(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.help_outline_rounded,
            color: isDark ? Colors.white70 : cs.onSurface.withOpacity(0.6),
            size: 22,
          ),
          onPressed: () => FeatureInfoCard.showEliteDialog(
            context,
            EliteFeatures.leaderboard,
          ),
        ),
        IconButton(
          icon: provider.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurface,
                  ),
                )
              : const Icon(Icons.refresh_rounded),
          onPressed: provider.isLoading ? null : provider.refresh,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeader(
          theme,
          cs,
          isDark,
          myRank,
          myEntry,
          total,
          provider,
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    int myRank,
    LeaderboardEntry? myEntry,
    int total,
    LeaderboardProvider provider,
  ) {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (_, __) {
        final fade = Curves.easeOut.transform(_headerAnim.value);
        final slide = 24 * (1 - _headerAnim.value);

        final rewards = myEntry?.rewards.where((r) => r.earned).toList() ?? [];

        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1E2E),
                          const Color(0xFF11111B),
                          const Color(0xFF1E1E2E),
                        ]
                      : [cs.primary, cs.secondary, cs.primary],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // decorative blobs
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 52, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _glowContainer(
                                  child: const Text(
                                    '🏆',
                                    style: TextStyle(fontSize: 26),
                                  ),
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Champions League',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1,
                                            fontSize: 24,
                                          ),
                                    ),
                                    Text(
                                      '$total builders on the board',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                if (myRank > 0 && myEntry != null)
                                  _MyRankChip(
                                    rank: myRank,
                                    entry: myEntry,
                                    total: total,
                                  ),
                                const Spacer(),
                                if (rewards.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${rewards.length} Rewards',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            if (rewards.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 80,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.zero,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: rewards.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (ctx, idx) {
                                    final r = rewards[idx];
                                    return SizedBox(
                                      width: 160,
                                      child: PremiumRewardBox(
                                        rewardPackage: r,
                                        taskId: 'rank_${r.tier.name}_reward',
                                        taskType: r.source.name,
                                        taskTitle: r.tagName,
                                        width: 70,
                                        height: 70,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildBody(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    LeaderboardProvider provider,
  ) {
    if (provider.isLoading && !provider.hasData) {
      return _buildLoading(cs);
    }
    if (provider.error != null && !provider.hasData) {
      return _buildError(provider, cs, theme);
    }
    if (!provider.hasData) {
      return _buildEmpty(theme, cs, provider);
    }

    final podium = provider.podium;
    final hasPodium = podium.length >= 3;
    final rest = hasPodium ? provider.restOfLeaderboard : provider.leaderboard;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: cs.primary,
      child: CustomScrollView(
        slivers: [
          if (hasPodium)
            SliverToBoxAdapter(
              child: _PodiumSection(
                entries: podium,
                currentUserId: provider.currentUserId,
                onProfileTap: (userId) => _navigateToProfile(context, userId),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Rankings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.leaderboard.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final entry = rest[i];
                final isExpanded = _expandedIds.contains(entry.userId);
                final isMe = entry.userId == provider.currentUserId;

                return AnimatedBuilder(
                  animation: _listAnim,
                  builder: (_, child) {
                    final delay = (i * 0.06).clamp(0.0, 0.5);
                    final t = Curves.easeOut.transform(
                      (((_listAnim.value - delay) / (1.0 - delay)).clamp(
                        0.0,
                        1.0,
                      )),
                    );
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LeaderboardRowCard(
                      entry: entry,
                      rank: entry.globalRank,
                      isExpanded: isExpanded,
                      isCurrentUser: isMe,
                      onTap: () => _toggle(entry.userId),
                      onProfileTap: () =>
                          _navigateToProfile(context, entry.userId),
                    ),
                  ),
                );
              }, childCount: rest.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AdvancedProgressIndicator(
          progress: 0.7,
          size: 72,
          strokeWidth: 5,
          foregroundColor: cs.primary,
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          labelStyle: ProgressLabelStyle.none,
          showGlow: true,
        ),
        const SizedBox(height: 16),
        Text(
          'Loading champions…',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    ),
  );

  Widget _buildError(
    LeaderboardProvider provider,
    ColorScheme cs,
    ThemeData theme,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: cs.error),
          const SizedBox(height: 16),
          Text(
            'Could not load rankings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty(
    ThemeData theme,
    ColorScheme cs,
    LeaderboardProvider provider,
  ) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FeatureInfoCard(feature: EliteFeatures.leaderboard),
          const SizedBox(height: 48),
          StreamBuilder<UserProfile?>(
            stream: ProfileRepository().watchMyProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final isPublic = profile?.isProfilePublic ?? false;

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isPublic
                      ? cs.primary.withOpacity(0.08)
                      : cs.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isPublic
                        ? cs.primary.withOpacity(0.4)
                        : cs.outlineVariant.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPublic
                            ? cs.primary.withOpacity(0.15)
                            : cs.onSurface.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPublic
                            ? Icons.public_rounded
                            : Icons.public_off_rounded,
                        color: isPublic
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public Profile',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPublic
                                ? 'You are active on the board'
                                : 'Enable to join the global board',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isPublic,
                      activeColor: cs.primary,
                      onChanged: (val) async {
                        HapticFeedback.mediumImpact();
                        try {
                          await ProfileRepository().updateMyProfile(
                            ProfileUpdateDto(isProfilePublic: val),
                          );
                          provider.refresh();
                        } catch (e) {
                          logE('Failed to update profile visibility', error: e);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              TaskFormBottomSheet.showCreateTask(context);
            },
            icon: const Icon(Icons.add_task_rounded, size: 22),
            label: const Text(
              'Start Your First Task',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              elevation: 8,
              shadowColor: cs.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _glowContainer({required Widget child, required Color color}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14),
          ],
        ),
        child: child,
      );
}

class _MyRankChip extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final int total;

  const _MyRankChip({
    required this.rank,
    required this.entry,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final tierInfo = _tierInfoFor(entry.rankReward.tier);
    final percentile = total > 0
        ? ((1 - (rank - 1) / total) * 100).toStringAsFixed(0)
        : '–';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: tierInfo.glowColor, blurRadius: 14, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tierInfo.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your rank: #$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'Top $percentile% · ${entry.pointsLabel}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (entry.rankReward.tier != RewardTier.none) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 28,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: tierInfo.color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tierInfo.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumSection extends StatefulWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;
  final void Function(String userId) onProfileTap;

  const _PodiumSection({
    required this.entries,
    required this.currentUserId,
    required this.onProfileTap,
  });

  @override
  State<_PodiumSection> createState() => _PodiumSectionState();
}

class _PodiumSectionState extends State<_PodiumSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final order = [widget.entries[1], widget.entries[0], widget.entries[2]];
    final ranks = [2, 1, 3];
    final heights = [110.0, 150.0, 80.0];

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final fade = Curves.easeOut.transform(_anim.value);
        return Opacity(
          opacity: fade,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF12121C)]
                    : [
                        cs.primaryContainer.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(3, (i) {
                final entry = order[i];
                final rank = ranks[i];
                final isMe = entry.userId == widget.currentUserId;
                final tierInfo = _tierInfoFor(entry.rankReward.tier);

                return Expanded(
                  child: _PodiumItem(
                    entry: entry,
                    rank: rank,
                    podiumHeight: heights[i],
                    isCurrentUser: isMe,
                    tierInfo: tierInfo,
                    animValue: _anim.value,
                    onProfileTap: () => widget.onProfileTap(entry.userId),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double podiumHeight;
  final bool isCurrentUser;
  final _RankTierInfo tierInfo;
  final double animValue;
  final VoidCallback onProfileTap;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.podiumHeight,
    required this.isCurrentUser,
    required this.tierInfo,
    required this.animValue,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _podiumColor(rank);
    final avatarSize = rank == 1 ? 72.0 : 58.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rank == 1
              ? '👑'
              : rank == 2
              ? '🥈'
              : '🥉',
          style: TextStyle(fontSize: rank == 1 ? 30 : 22),
        ),
        const SizedBox(height: 6),
        if (entry.rankReward.tier != RewardTier.none)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tierInfo.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tierInfo.color.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${tierInfo.emoji} ${tierInfo.label}',
              style: TextStyle(
                fontSize: 7,
                color: tierInfo.color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // Tappable avatar
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize + 20,
                height: avatarSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              AdvancedProgressIndicator(
                progress: (entry.totalPoints / 20000).clamp(0.01, 1.0),
                size: avatarSize + 14,
                strokeWidth: rank == 1 ? 5 : 4,
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
                labelStyle: ProgressLabelStyle.none,
                showGlow: rank == 1,
                padding: EdgeInsets.zero,
              ),
              _Avatar(entry: entry, size: avatarSize),
              // "View Profile" ring hint
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('👤', style: TextStyle(fontSize: 8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 88,
          child: Text(
            entry.name,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: isCurrentUser ? cs.primary : cs.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry.pointsLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: podiumHeight),
          duration: Duration(milliseconds: 800 + rank * 80),
          curve: Curves.easeOutBack,
          builder: (_, h, __) => Container(
            height: h,
            width: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.55)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final double size;

  const _Avatar({required this.entry, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: isDark ? cs.surface : Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
          ? FutureBuilder<String?>(
              future: UniversalMediaService().getValidAvatarUrl(entry.avatarUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.isNotEmpty) {
                  final resolvedPath = snapshot.data!;
                  if (!resolvedPath.startsWith('http') &&
                      (resolvedPath.startsWith('/') ||
                          resolvedPath.startsWith('C:\\') ||
                          resolvedPath.startsWith('file://'))) {
                    return Image.file(
                      File(resolvedPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(cs, theme),
                    );
                  } else {
                    return Image.network(
                      resolvedPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(cs, theme),
                    );
                  }
                }
                return _initials(cs, theme);
              },
            )
          : _initials(cs, theme),
    );
  }

  Widget _initials(ColorScheme cs, ThemeData theme) => Container(
    color: cs.primaryContainer.withValues(alpha: 0.5),
    child: Center(
      child: Text(
        entry.initials,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
        ),
      ),
    ),
  );
}

// ================================================================
// LEADERBOARD ROW CARD — premium glass design
// ================================================================

class _LeaderboardRowCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isExpanded;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const _LeaderboardRowCard({
    required this.entry,
    required this.rank,
    required this.isExpanded,
    required this.isCurrentUser,
    required this.onTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tierInfo = _tierInfoFor(entry.rankReward.tier);
    final hasTier = entry.rankReward.tier != RewardTier.none;

    // Rank-accent colour for top 10
    final rankAccent = rank <= 3
        ? _podiumColor(rank)
        : rank <= 10
        ? const Color(0xFF6366F1)
        : (isCurrentUser ? cs.primary : null);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isCurrentUser
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        cs.primary.withValues(alpha: 0.15),
                        cs.primaryContainer.withValues(alpha: 0.08),
                      ]
                    : [
                        cs.primary.withValues(alpha: 0.08),
                        cs.primaryContainer.withValues(alpha: 0.15),
                      ],
              )
            : null,
        color: isCurrentUser
            ? null
            : (isDark ? const Color(0xFF161625) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentUser
              ? cs.primary.withValues(alpha: 0.45)
              : rankAccent != null
              ? rankAccent.withValues(alpha: 0.2)
              : cs.outline.withValues(alpha: isDark ? 0.1 : 0.06),
          width: isCurrentUser ? 2 : 1.5,
        ),
        boxShadow: [
          if (isCurrentUser)
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            )
          else if (rank <= 3)
            BoxShadow(
              color: _podiumColor(rank).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Premium rank badge
                    _RankBadge(rank: rank, isCurrentUser: isCurrentUser),
                    const SizedBox(width: 12),
                    // Tappable avatar → profile
                    GestureDetector(
                      onTap: onProfileTap,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _Avatar(entry: entry, size: 48),
                          // Small "tap" indicator
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [cs.primary, cs.secondary],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'YOU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              if (hasTier && !isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Text(
                                  tierInfo.emoji,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              // Streak
                              Text(
                                entry.streakEmoji,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${entry.currentStreak}d streak',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                              if (hasTier) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tierInfo.color.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: tierInfo.color.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    tierInfo.label,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: tierInfo.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          entry.totalPoints.toString(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: rankAccent ?? cs.onSurface,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'points',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _ExpandedStats(entry: entry, tierInfo: tierInfo),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EXPANDED STATS with scratch cards
// ================================================================

class _ExpandedStats extends StatelessWidget {
  final LeaderboardEntry entry;
  final _RankTierInfo tierInfo;

  const _ExpandedStats({required this.entry, required this.tierInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasTier = entry.rankReward.tier != RewardTier.none;
    final earnedRewards = entry.rewards.where((r) => r.earned).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Divider(color: cs.outline.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 16),

          // ── Score breakdown ─────────────────────────────────────
          Text(
            'SCORE BREAKDOWN',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: cs.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          _StatBar(
            label: 'Daily Tasks',
            emoji: '📅',
            value: entry.dailyTasksPoints,
            max: 8000,
            color: const Color(0xFF4FACFE),
          ),
          const SizedBox(height: 8),
          _StatBar(
            label: 'Weekly Tasks',
            emoji: '📆',
            value: entry.weeklyTasksPoints,
            max: 5000,
            color: const Color(0xFF43E97B),
          ),
          const SizedBox(height: 8),
          _StatBar(
            label: 'Long Goals',
            emoji: '🎯',
            value: entry.longGoalsPoints,
            max: 4000,
            color: const Color(0xFF9333EA),
          ),
          const SizedBox(height: 8),
          _StatBar(
            label: 'Bucket List',
            emoji: '🪣',
            value: entry.bucketListPoints,
            max: 3000,
            color: const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 16),

          // ── Performance ─────────────────────────────────────────
          Text(
            'PERFORMANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: cs.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricCard(
                label: 'Today',
                value: '${entry.pointsToday}',
                sub: 'pts',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'This Week',
                value: '${entry.pointsThisWeek}',
                sub: 'pts',
                icon: Icons.date_range_rounded,
                color: const Color(0xFF4FACFE),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Longest Streak',
                value: '${entry.longestStreak}',
                sub: 'days',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricCard(
                label: 'Avg Rating',
                value: entry.ratingLabel,
                sub: '/ 5.0',
                icon: Icons.star_rounded,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Completion',
                value: entry.completionLabel,
                sub: 'all time',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF43E97B),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Rewards',
                value: '${entry.totalRewards}',
                sub: 'earned',
                icon: Icons.emoji_events_rounded,
                color: entry.bestTierColor,
              ),
            ],
          ),

          // ── Tier reward banner ───────────────────────────────────
          if (hasTier) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tierInfo.color.withValues(alpha: 0.18),
                    tierInfo.color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tierInfo.color.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tierInfo.color.withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(tierInfo.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tierInfo.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tierInfo.color,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          entry.rankReward.tagReason.isNotEmpty
                              ? entry.rankReward.tagReason
                              : 'Global rank achievement',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tierInfo.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${entry.rankReward.points} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Scratch cards ────────────────────────────────────────
          if (earnedRewards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'SCRATCH REWARDS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${earnedRewards.length}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: earnedRewards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, idx) {
                  final r = earnedRewards[idx];
                  return PremiumRewardBox(
                    key: ValueKey('${entry.userId}_reward_$idx'),
                    rewardPackage: r,
                    taskId: '${entry.userId}_reward_${r.tier.name}',
                    taskType: r.source.name,
                    taskTitle: r.tagName,
                    width: 80,
                    height: 80,
                    borderRadius: BorderRadius.circular(18),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final String emoji;
  final int value;
  final int max;
  final Color color;

  const _StatBar({
    required this.label,
    required this.emoji,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (value / max).clamp(0.001, 1.0);

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: CustomProgressIndicator(
            progress: progress,
            progressBarName: '',
            progressColor: color,
            backgroundColor: color.withValues(alpha: 0.1),
            borderRadius: 4,
            baseHeight: 6,
            maxHeightIncrease: 0,
            progressLabelDisplay: ProgressLabelDisplay.none,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$value',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.12 : 0.08),
              color.withValues(alpha: isDark ? 0.06 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(
              sub,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

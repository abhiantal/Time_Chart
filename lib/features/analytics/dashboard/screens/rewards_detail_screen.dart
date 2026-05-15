// ================================================================
// FILE: rewards_detail_screen.dart
// REWARDS DETAIL SCREEN — All tier achievements & reward data
// • NO reward_widgets.dart dependency — all widgets inline
// • Imports: shared_widgets.dart, list_widgets.dart
// • Uses: CustomProgressIndicator + AdvancedProgressIndicator
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Progress widgets ────────────────────────────────────────────

// ── Reward system ───────────────────────────────────────────────
import '../../../../reward_tags/reward_enums.dart';
import '../../../../reward_tags/reward_manager.dart';
import '../../../../helpers/card_color_helper.dart';

// ── Shared reusable components ──────────────────────────────────
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/circular_progress_indicator.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/list_widgets.dart';

// ── Data + provider ─────────────────────────────────────────────
import '../providers/user_dashboard_provider.dart';
// removed import
import '../utils/skeleton_widgets.dart';

// ================================================================
// SCREEN
// ================================================================

class RewardsDetailScreen extends StatefulWidget {
  const RewardsDetailScreen({super.key});

  @override
  State<RewardsDetailScreen> createState() => _RewardsDetailScreenState();
}

class _RewardsDetailScreenState extends State<RewardsDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _bodyCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _bodyFade;

  // Tab index for tier category switcher
  int _selectedTabIdx = 0;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _bodyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));
    _bodyFade = CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _heroCtrl.forward();
      Future.delayed(const Duration(milliseconds: 260),
              () { if (mounted) _bodyCtrl.forward(); });
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<UserDashboardProvider>(
        builder: (context, provider, _) {
          if (!provider.hasData) return const RewardsCardSkeleton();
          final rewards = provider.rewards;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO APP BAR ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: _RewardsHeroHeader(
                    rewards: rewards,
                    heroFade: _heroFade,
                    heroSlide: _heroSlide,
                    isDark: isDark,
                    theme: theme,
                  ),
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text('Rewards & Tiers',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),

              // ── BODY ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _bodyFade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 1. Best Tier Spotlight ────────────
                          _SectionLabel(label: 'Your Best Achievement'),
                          const SizedBox(height: 12),
                          _BestTierSpotlight(
                              rewards: rewards,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 2. Stats Grid ─────────────────────
                          _SectionLabel(label: 'Reward Statistics'),
                          const SizedBox(height: 12),
                          _RewardStatsGrid(
                              rewards: rewards,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 3. Next Target Progress ───────────
                          _SectionLabel(label: 'Next Target'),
                          const SizedBox(height: 12),
                          _NextTargetCard(
                              rewards: rewards,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 4. Tier Category Tabs ─────────────
                          _SectionLabel(label: 'Tier Collections'),
                          const SizedBox(height: 12),
                          _TierTabSwitcher(
                            selectedIdx: _selectedTabIdx,
                            onChanged: (i) =>
                                setState(() => _selectedTabIdx = i),
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          _TierCollectionPanel(
                            selectedIdx: _selectedTabIdx,
                            rewards: rewards,
                            theme: theme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // ── 5. Tier Comparison Bars ───────────
                          _SectionLabel(label: 'Tier Count Comparison'),
                          const SizedBox(height: 12),
                          _TierComparisonBars(
                              rewards: rewards,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 6. Dashboard Reward ───────────────
                          _SectionLabel(label: 'Dashboard Achievement'),
                          const SizedBox(height: 12),
                          _DashboardRewardCard(
                              rewards: rewards,
                              theme: theme,
                              isDark: isDark),
                          const SizedBox(height: 24),

                          // ── 7. Recent Rewards ─────────────────
                          if (rewards.recentRewards.isNotEmpty) ...[
                            _SectionLabel(label: 'Recent Rewards'),
                            const SizedBox(height: 12),
                            _RecentRewardsList(
                                rewards: rewards,
                                theme: theme,
                                isDark: isDark),
                          ],
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================================================
// TIER METADATA HELPER
// ================================================================

class _TierMeta {
  final String name;
  final String tagName;
  final String emoji;
  final Color color;
  const _TierMeta(
      {required this.name,
        required this.tagName,
        required this.emoji,
        required this.color});
}

_TierMeta _metaFor(String tier) {
  final color = CardColorHelper.getTierColor(tier);
  final emoji = CardColorHelper.getTierEmoji(tier);
  final names = {
    'spark': 'Spark Guardian',
    'flame': 'Flame Bearer',
    'ember': 'Ember Keeper',
    'blaze': 'Blaze Warrior',
    'crystal': 'Crystal Knight',
    'prism': 'Prism Sage',
    'radiant': 'Radiant Crown',
    'nova': 'Nova Eternal',
    'dashboardbronze': 'Luck Guardian',
    'dashboardsilver': 'Comet Sentinel',
    'dashboardgold': 'Golden Phoenix',
    'dashboardplatinum': 'Platinum Oracle',
    'dashboarddiamond': 'Diamond Sovereign',
    'dashboardomega': 'Omega Ascendant',
    'dashboardapex': 'Apex Eternal',
    'rankelite': 'Elite Dragon',
    'rankmaster': 'Master Archer',
    'ranklegend': 'Emerald Legend',
    'rankicon': 'Ice Icon',
    'rankgodsend': 'Godsend',
    'rankvanguard': 'Vanguard',
    'ranksentinel': 'Sentinel Unicorn',
  };
  return _TierMeta(
    name: tier,
    tagName: names[tier.toLowerCase()] ?? tier,
    emoji: emoji,
    color: color,
  );
}

// Core tiers in order
const _coreTiers = [
  'spark', 'flame', 'ember', 'blaze', 'crystal', 'prism', 'radiant', 'nova'
];
const _dashboardTiers = [
  'dashboardBronze', 'dashboardSilver', 'dashboardGold',
  'dashboardPlatinum', 'dashboardDiamond', 'dashboardOmega', 'dashboardApex'
];
const _rankTiers = [
  'rankElite', 'rankMaster', 'rankLegend', 'rankIcon',
  'rankGodsend', 'rankVanguard', 'rankSentinel'
];

// ================================================================
// HERO HEADER
// ================================================================

class _RewardsHeroHeader extends StatelessWidget {
  final dynamic rewards; // RewardsStats
  final Animation<double> heroFade;
  final Animation<Offset> heroSlide;
  final bool isDark;
  final ThemeData theme;

  const _RewardsHeroHeader({
    required this.rewards,
    required this.heroFade,
    required this.heroSlide,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bestColor = CardColorHelper.getTierColor(rewards.bestTierAchieved);
    final bestEmoji = CardColorHelper.getTierEmoji(rewards.bestTierAchieved);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            Color.lerp(bestColor, const Color(0xFF0F0F1A), 0.75)!,
            const Color(0xFF0A0A14),
          ]
              : [
            Color.lerp(bestColor, Colors.white, 0.2)!,
            Color.lerp(bestColor, Colors.white, 0.55)!,
          ],
        ),
      ),
      child: SlideTransition(
        position: heroSlide,
        child: FadeTransition(
          opacity: heroFade,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rewards & Tiers',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color: isDark ? Colors.white : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8)
                                    ])),
                            const SizedBox(height: 3),
                            Text('Your achievement journey',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                    Colors.white.withOpacity(0.75))),
                          ],
                        ),
                      ),
                      // Best tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(bestEmoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(
                              rewards.bestTierAchieved.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Quick stats strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                            value: rewards.totalRewardsEarned.toString(),
                            label: 'Total Earned',
                            icon: '🏆'),
                        _HeroDiv(),
                        _HeroStat(
                            value: rewards.totalPoints.toString(),
                            label: 'Reward Pts',
                            icon: '⭐'),
                        _HeroDiv(),
                        _HeroStat(
                            value: rewards.earnedRewardsNo.length.toString(),
                            label: 'Tiers Hit',
                            icon: '🎯'),
                        _HeroDiv(),
                        _HeroStat(
                            value: rewards.summary.nextRewards.isEmpty
                                ? '✅'
                                : rewards.summary.nextRewards,
                            label: 'Next Target',
                            icon: '🚀'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label, icon;
  const _HeroStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HeroDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.25));
}

// ================================================================
// SECTION LABEL
// ================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ],
    );
  }
}

// ================================================================
// CARD SHELL
// ================================================================

class _CardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final ThemeData theme;
  final Color? accentColor;
  final EdgeInsets? padding;
  final List<Color>? gradient;

  const _CardShell({
    required this.child,
    required this.isDark,
    required this.theme,
    this.accentColor,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient!)
            : null,
        color: gradient == null
            ? (isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface)
            : null,
        borderRadius: BorderRadius.circular(18),
        border: accentColor != null
            ? Border.all(color: accentColor!.withOpacity(0.22))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

// ================================================================
// 1. BEST TIER SPOTLIGHT
// ================================================================

class _BestTierSpotlight extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _BestTierSpotlight(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final best = rewards.bestTierAchieved as String;
    final meta = _metaFor(best);
    final color = meta.color;
    final nextInfo = RewardManager.getNextTierInfo(
        RewardManager.parseTier(best));

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      gradient: [
        color.withOpacity(isDark ? 0.28 : 0.18),
        color.withOpacity(isDark ? 0.1 : 0.04),
      ],
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress arc showing tier level
              AdvancedProgressIndicator(
                progress: (_tierLevel(best) / 22).clamp(0.0, 1.0),
                size: 110,
                strokeWidth: 10,
                shape: ProgressShape.circular,
                gradientColors: [color, color.withOpacity(0.5)],
                backgroundColor: color.withOpacity(0.1),
                labelStyle: ProgressLabelStyle.custom,
                customLabel: meta.emoji,
                labelTextStyle: const TextStyle(fontSize: 32),
                showGlow: true,
                glowRadius: 10,
                animationDuration: const Duration(milliseconds: 1500),
                animationCurve: Curves.easeOutCubic,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                        Border.all(color: color.withOpacity(0.35)),
                      ),
                      child: Text('BEST TIER ACHIEVED',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(height: 6),
                    Text(best.toUpperCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -0.5)),
                    Text(meta.tagName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.55))),
                    const SizedBox(height: 10),
                    Row(children: [
                      _TierStatPill(
                          label: 'Level',
                          value: '#${_tierLevel(best)}',
                          color: color),
                      const SizedBox(width: 8),
                      _TierStatPill(
                          label: 'Earned',
                          value:
                          'x${rewards.earnedRewardsNo[best] ?? 0}',
                          color: color),
                    ]),
                  ],
                ),
              ),
            ],
          ),

          // Next tier progress bar
          if (nextInfo != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(nextInfo['emoji'] as String? ?? '🏆',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('Next: ${nextInfo['tagName']}',
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700)),
                ]),
                Text('Tier ${nextInfo['level']}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Color((nextInfo['color'] as Color)
                            .value),
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            CustomProgressIndicator(
              progress: (_tierLevel(best) / 22).clamp(0.0, 1.0),
              progressBarName: '',
              orientation: ProgressOrientation.horizontal,
              baseHeight: 10,
              maxHeightIncrease: 3,
              gradientColors: [color, color.withOpacity(0.55)],
              backgroundColor: color.withOpacity(0.1),
              borderRadius: 8,
              progressLabelDisplay: ProgressLabelDisplay.bubble,
              progressLabelBackgroundColor: color,
              nameLabelPosition: LabelPosition.bottom,
              animateNameLabel: false,
              animationDuration: const Duration(milliseconds: 1400),
              animationCurve: Curves.easeOutCubic,
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⚜️', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Maximum Tier Achieved!',
                      style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _tierLevel(String tier) {
    final t = RewardManager.parseTier(tier);
    return t.level;
  }
}

class _TierStatPill extends StatelessWidget {
  final String label, value;
  final Color color;

  const _TierStatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color.withOpacity(0.65), fontSize: 9)),
          TextSpan(
              text: value,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

// ================================================================
// 2. REWARD STATS GRID
// ================================================================

class _RewardStatsGrid extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _RewardStatsGrid(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTileData(
          icon: Icons.emoji_events_rounded,
          label: 'Total Earned',
          value: rewards.totalRewardsEarned.toString(),
          color: const Color(0xFFF59E0B)),
      _StatTileData(
          icon: Icons.star_rounded,
          label: 'Reward Points',
          value: rewards.totalPoints.toString(),
          color: const Color(0xFFFFD700)),
      _StatTileData(
          icon: Icons.workspace_premium_rounded,
          label: 'Best Tier',
          value: rewards.bestTierAchieved.toUpperCase(),
          color: CardColorHelper.getTierColor(rewards.bestTierAchieved)),
      _StatTileData(
          icon: Icons.trending_up_rounded,
          label: 'Tiers Unlocked',
          value: rewards.earnedRewardsNo.length.toString(),
          color: const Color(0xFF10B981)),
      _StatTileData(
          icon: Icons.local_fire_department_rounded,
          label: 'Core Rewards',
          value: _coreTiers
              .fold<int>(
              0, (s, t) => s + (rewards.earnedRewardsNo[t] ?? 0) as int)
              .toString(),
          color: const Color(0xFFEF4444)),
      _StatTileData(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard Rewards',
          value: _dashboardTiers
              .fold<int>(
              0, (s, t) => s + (rewards.earnedRewardsNo[t] ?? 0) as int)
              .toString(),
          color: const Color(0xFF8B5CF6)),
      _StatTileData(
          icon: Icons.leaderboard_rounded,
          label: 'Rank Rewards',
          value: _rankTiers
              .fold<int>(
              0, (s, t) => s + (rewards.earnedRewardsNo[t] ?? 0) as int)
              .toString(),
          color: const Color(0xFF06B6D4)),
      _StatTileData(
          icon: Icons.rocket_launch_rounded,
          label: 'Next Target',
          value: rewards.summary.nextRewards.isEmpty
              ? 'All Done!'
              : rewards.summary.nextRewards,
          color: const Color(0xFF667EEA)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, i) {
        final t = tiles[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.color.withOpacity(isDark ? 0.1 : 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(t.icon, color: t.color, size: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: t.color)),
                  Text(t.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 9)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTileData {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatTileData(
      {required this.icon,
        required this.label,
        required this.value,
        required this.color});
}

// ================================================================
// 3. NEXT TARGET CARD
// ================================================================

class _NextTargetCard extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _NextTargetCard(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final next = rewards.summary.nextRewards as String;
    final nextColor = next.isEmpty
        ? const Color(0xFF10B981)
        : CardColorHelper.getTierColor(next);
    final progress =
    (rewards.totalRewardsEarned / (rewards.totalRewardsEarned + 3))
        .clamp(0.0, 1.0);
    final suggestion = rewards.summary.suggestion as String? ?? '';

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: nextColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Arc showing progress to next
              AdvancedProgressIndicator(
                progress: progress,
                size: 80,
                strokeWidth: 8,
                shape: ProgressShape.arc,
                arcStartAngle: 180,
                arcSweepAngle: 180,
                gradientColors: [nextColor, nextColor.withOpacity(0.5)],
                backgroundColor: nextColor.withOpacity(0.1),
                labelStyle: ProgressLabelStyle.custom,
                customLabel:
                '${(progress * 100).toStringAsFixed(0)}%',
                labelTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: nextColor),
                animationDuration: const Duration(milliseconds: 1300),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.isEmpty ? 'All Achieved!' : 'Next: $next',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800, color: nextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rewards.totalRewardsEarned} rewards earned',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: nextColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: nextColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          CustomProgressIndicator(
            progress: progress,
            progressBarName: 'Progress to Next Reward',
            orientation: ProgressOrientation.horizontal,
            baseHeight: 10,
            maxHeightIncrease: 3,
            gradientColors: [nextColor, nextColor.withOpacity(0.55)],
            backgroundColor: nextColor.withOpacity(0.1),
            borderRadius: 8,
            progressLabelDisplay: ProgressLabelDisplay.box,
            progressLabelBackgroundColor: nextColor,
            nameLabelPosition: LabelPosition.top,
            nameLabelStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55)),
            animateNameLabel: true,
            animationDuration: const Duration(milliseconds: 1300),
            animationCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 4. TIER TAB SWITCHER
// ================================================================

class _TierTabSwitcher extends StatelessWidget {
  final int selectedIdx;
  final ValueChanged<int> onChanged;
  final ThemeData theme;
  final bool isDark;

  const _TierTabSwitcher({
    required this.selectedIdx,
    required this.onChanged,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Core', '✨'),
      ('Dashboard', '📊'),
      ('Global Rank', '🌐'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = entry.key == selectedIdx;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.value.$2,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(entry.value.$1,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface
                                .withOpacity(0.6))),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// 4b. TIER COLLECTION PANEL
// ================================================================

class _TierCollectionPanel extends StatelessWidget {
  final int selectedIdx;
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _TierCollectionPanel({
    required this.selectedIdx,
    required this.rewards,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = selectedIdx == 0
        ? _coreTiers
        : selectedIdx == 1
        ? _dashboardTiers
        : _rankTiers;

    final bestTier = rewards.bestTierAchieved as String;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: tiers.length,
      itemBuilder: (context, i) {
        final tier = tiers[i];
        final meta = _metaFor(tier);
        final count =
        (rewards.earnedRewardsNo[tier] ?? 0) as int;
        final isEarned = count > 0;
        final isBest =
            tier.toLowerCase() == bestTier.toLowerCase();
        final color = meta.color;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEarned
                  ? [
                color.withOpacity(isDark ? 0.28 : 0.18),
                color.withOpacity(isDark ? 0.1 : 0.05),
              ]
                  : [
                theme.colorScheme.onSurface.withOpacity(0.04),
                theme.colorScheme.onSurface.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: isBest
                ? Border.all(color: color, width: 2)
                : Border.all(
                color: isEarned
                    ? color.withOpacity(0.3)
                    : theme.colorScheme.outline.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // BEST badge
              if (isBest)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('BEST',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                )
              else
                const SizedBox(height: 14),
              // Emoji with opacity if not earned
              Text(meta.emoji,
                  style: TextStyle(
                      fontSize: 22,
                      color: isEarned ? null : Colors.grey.withOpacity(0.4))),
              // Name + count
              Column(
                children: [
                  Text(tier.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: isEarned
                              ? color
                              : theme.colorScheme.onSurface.withOpacity(0.25),
                          letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isEarned
                          ? color.withOpacity(0.15)
                          : theme.colorScheme.outline.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEarned ? 'x$count' : '🔒',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isEarned
                              ? color
                              : theme.colorScheme.onSurface.withOpacity(0.3)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// 5. TIER COMPARISON BARS  (CustomProgressIndicator)
// ================================================================

class _TierComparisonBars extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _TierComparisonBars(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final allTiers = [..._coreTiers, ..._dashboardTiers, ..._rankTiers];
    final counts = allTiers
        .map((t) =>
        MapEntry(t, (rewards.earnedRewardsNo[t] ?? 0) as int))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (counts.isEmpty) {
      return _CardShell(
        isDark: isDark,
        theme: theme,
        child: EmptyStateWidget(
          icon: Icons.bar_chart_rounded,
          title: 'No Rewards Yet',
          subtitle: 'Complete tasks to earn rewards',
        ),
      );
    }

    final maxCount = counts.fold<int>(1, (m, e) => e.value > m ? e.value : m);

    return _CardShell(
      isDark: isDark,
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text('Earned Count by Tier',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          ...counts.map((entry) {
            final meta = _metaFor(entry.key);
            final color = meta.color;
            final fraction = entry.value / maxCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Text(meta.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(entry.key.toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('x${entry.value}',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CustomProgressIndicator(
                    progress: fraction.clamp(0.0, 1.0),
                    progressBarName: '',
                    orientation: ProgressOrientation.horizontal,
                    baseHeight: 10,
                    maxHeightIncrease: 3,
                    gradientColors: [color, color.withOpacity(0.5)],
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade200,
                    borderRadius: 8,
                    progressLabelDisplay: ProgressLabelDisplay.none,
                    nameLabelPosition: LabelPosition.bottom,
                    animateNameLabel: false,
                    animationDuration:
                    const Duration(milliseconds: 1200),
                    animationCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ================================================================
// 6. DASHBOARD REWARD CARD
// ================================================================

class _DashboardRewardCard extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _DashboardRewardCard(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Find highest dashboard tier earned
    final earned = _dashboardTiers
        .where(
            (t) => (rewards.earnedRewardsNo[t] ?? 0) > 0)
        .toList();

    if (earned.isEmpty) {
      return _CardShell(
        isDark: isDark,
        theme: theme,
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text('No Dashboard Reward Yet',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Earn rewards across multiple task types to unlock your first dashboard tier!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color:
                  theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
          ],
        ),
      );
    }

    final topDash = earned.last;
    final meta = _metaFor(topDash);
    final color = meta.color;
    final countAll = earned.fold<int>(
        0, (s, t) => s + (rewards.earnedRewardsNo[t] ?? 0) as int);

    return _CardShell(
      isDark: isDark,
      theme: theme,
      accentColor: color,
      gradient: [
        color.withOpacity(isDark ? 0.22 : 0.14),
        color.withOpacity(isDark ? 0.08 : 0.03),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AdvancedProgressIndicator(
              progress: (_dashboardTiers.indexOf(topDash) + 1) /
                  _dashboardTiers.length,
              size: 72,
              strokeWidth: 7,
              shape: ProgressShape.circular,
              gradientColors: [color, color.withOpacity(0.5)],
              backgroundColor: color.withOpacity(0.1),
              labelStyle: ProgressLabelStyle.custom,
              customLabel: meta.emoji,
              labelTextStyle: const TextStyle(fontSize: 22),
              showGlow: true,
              glowRadius: 6,
              animationDuration: const Duration(milliseconds: 1300),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard Achievement',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: color.withOpacity(0.75),
                          fontWeight: FontWeight.w600)),
                  Text(topDash.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900, color: color)),
                  Text(meta.tagName,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5))),
                  const SizedBox(height: 6),
                  Row(children: [
                    _TierStatPill(
                        label: 'Tiers',
                        value: '${earned.length}/${_dashboardTiers.length}',
                        color: color),
                    const SizedBox(width: 8),
                    _TierStatPill(
                        label: 'Total',
                        value: 'x$countAll',
                        color: color),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Tier progression row
          Row(
            children: _dashboardTiers.asMap().entries.map((e) {
              final isEarned =
                  (rewards.earnedRewardsNo[e.value] ?? 0) > 0;
              final isTop = e.value == topDash;
              final m = _metaFor(e.value);
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? m.color.withOpacity(0.2)
                            : theme.colorScheme.outline.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: isTop
                            ? Border.all(color: m.color, width: 1.5)
                            : null,
                      ),
                      child: Text(m.emoji,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: isEarned ? null : Colors.grey.withOpacity(0.3))),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      e.value
                          .replaceAll('dashboard', '')
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: isEarned
                              ? m.color
                              : theme.colorScheme.onSurface.withOpacity(0.2)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 7. RECENT REWARDS LIST  (uses RewardListItem from list_widgets)
// ================================================================

class _RecentRewardsList extends StatelessWidget {
  final dynamic rewards;
  final ThemeData theme;
  final bool isDark;

  const _RecentRewardsList(
      {required this.rewards, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final recent = rewards.recentRewards as List;

    return _CardShell(
      isDark: isDark,
      theme: theme,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: RewardListItem(
                  tier: r.tier as String,
                  emoji: r.tierEmoji as String?,
                  tagName: r.tagName as String?,
                  taskName: r.taskName as String?,
                  points: (r.points as num?)?.toInt() ?? 0,
                  earnedFrom: r.earnedFrom as String,
                  timeAgo: r.timeAgo as String,
                  tierColor: r.tierColor as Color?,
                  showBackground: false,
                ),
              ),
              if (i < recent.length - 1)
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color:
                  theme.colorScheme.outline.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
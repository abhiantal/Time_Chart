import 'reward_enums.dart';

class TierMeta {
  final RewardTier tier;
  final RewardColor color;
  final String tagName;
  final String powerWord;
  final String emoji;
  final int points;
  final String description;

  const TierMeta({
    required this.tier,
    required this.color,
    required this.tagName,
    required this.powerWord,
    required this.emoji,
    required this.points,
    required this.description,
  });
}

const Map<RewardTier, TierMeta> kTierRegistry = {
  // ── CORE REWARDS ──
  RewardTier.spark: TierMeta(
    tier: RewardTier.spark,
    color: RewardColor.sparkBlue,
    tagName: 'First Spark',
    powerWord: 'Ignited',
    emoji: '✨',
    points: 10,
    description: 'You took the first step — momentum begins here.',
  ),
  RewardTier.flame: TierMeta(
    tier: RewardTier.flame,
    color: RewardColor.flameSilver,
    tagName: 'Rising Flame',
    powerWord: 'Consistent',
    emoji: '🔥',
    points: 20,
    description: 'You\'re showing up every day. Keep the fire alive.',
  ),
  RewardTier.ember: TierMeta(
    tier: RewardTier.ember,
    color: RewardColor.emberGreen,
    tagName: 'Deep Ember',
    powerWord: 'Disciplined',
    emoji: '🌿',
    points: 35,
    description: 'Discipline is becoming second nature to you.',
  ),
  RewardTier.blaze: TierMeta(
    tier: RewardTier.blaze,
    color: RewardColor.blazeOrange,
    tagName: 'Full Blaze',
    powerWord: 'Unstoppable',
    emoji: '⚡',
    points: 50,
    description: 'Peak performance. You\'re blazing hot.',
  ),
  RewardTier.crystal: TierMeta(
    tier: RewardTier.crystal,
    color: RewardColor.crystalDeepBlue,
    tagName: 'Crystal Mind',
    powerWord: 'Expert',
    emoji: '💎',
    points: 75,
    description: 'Expert focus. Crystal-clear execution.',
  ),
  RewardTier.prism: TierMeta(
    tier: RewardTier.prism,
    color: RewardColor.prismWhite,
    tagName: 'Prism Master',
    powerWord: 'Masterful',
    emoji: '🏆',
    points: 100,
    description: 'Multi-faceted mastery across every dimension.',
  ),
  RewardTier.radiant: TierMeta(
    tier: RewardTier.radiant,
    color: RewardColor.radiantForest,
    tagName: 'Radiant Force',
    powerWord: 'Champion',
    emoji: '👑',
    points: 150,
    description: 'Championship-level brilliance. You radiate excellence.',
  ),
  RewardTier.nova: TierMeta(
    tier: RewardTier.nova,
    color: RewardColor.novaCrimson,
    tagName: 'Nova Legend',
    powerWord: 'Legendary',
    emoji: '🌟',
    points: 250,
    description: 'You have reached the pinnacle. A true legend.',
  ),

  // ── DASHBOARD REWARDS ──
  RewardTier.dashboardBronze: TierMeta(
    tier: RewardTier.dashboardBronze,
    color: RewardColor.dbBronze,
    tagName: 'Luck Guardian',
    powerWord: 'Fortuitous',
    emoji: '🍀',
    points: 100,
    description: 'Fortune favors the disciplined. Momentum begins.',
  ),
  RewardTier.dashboardSilver: TierMeta(
    tier: RewardTier.dashboardSilver,
    color: RewardColor.dbSilver,
    tagName: 'Comet Sentinel',
    powerWord: 'Vigilant',
    emoji: '☄️',
    points: 150,
    description: 'Blazing through tasks with celestial speed.',
  ),
  RewardTier.dashboardGold: TierMeta(
    tier: RewardTier.dashboardGold,
    color: RewardColor.dbGold,
    tagName: 'Golden Phoenix',
    powerWord: 'Ascended',
    emoji: '🔱',
    points: 200,
    description: 'Rising from challenges with golden grace.',
  ),
  RewardTier.dashboardPlatinum: TierMeta(
    tier: RewardTier.dashboardPlatinum,
    color: RewardColor.dbPlatinum,
    tagName: 'Platinum Oracle',
    powerWord: 'Enlightened',
    emoji: '🔮',
    points: 300,
    description: 'Your insights transcend ordinary boundaries.',
  ),
  RewardTier.dashboardDiamond: TierMeta(
    tier: RewardTier.dashboardDiamond,
    color: RewardColor.dbDiamond,
    tagName: 'Diamond Sovereign',
    powerWord: 'Regal',
    emoji: '💎',
    points: 400,
    description: 'Unbreakable resolve. Timeless brilliance.',
  ),
  RewardTier.dashboardOmega: TierMeta(
    tier: RewardTier.dashboardOmega,
    color: RewardColor.dbOmega,
    tagName: 'Omega Ascendant',
    powerWord: 'Transcendent',
    emoji: 'Ω',
    points: 500,
    description: 'Beyond excellence. The final form of mastery.',
  ),
  RewardTier.dashboardApex: TierMeta(
    tier: RewardTier.dashboardApex,
    color: RewardColor.dbApex,
    tagName: 'Apex Eternal',
    powerWord: 'Immortal',
    emoji: '⚜️',
    points: 750,
    description: 'The pinnacle. Forever etched in legend.',
  ),

  // ── GLOBAL RANK REWARDS ──
  RewardTier.rankElite: TierMeta(
    tier: RewardTier.rankElite,
    color: RewardColor.rankElite,
    tagName: 'Dragon Vanguard',
    powerWord: 'Exceptional',
    emoji: '🐲',
    points: 200,
    description: 'Top 100 globally. The strength of a dragon.',
  ),
  RewardTier.rankMaster: TierMeta(
    tier: RewardTier.rankMaster,
    color: RewardColor.rankMaster,
    tagName: 'Master Tactician',
    powerWord: 'Strategic',
    emoji: '🏹',
    points: 300,
    description: 'Top 50 globally. Masterful strategy.',
  ),
  RewardTier.rankLegend: TierMeta(
    tier: RewardTier.rankLegend,
    color: RewardColor.rankLegend,
    tagName: 'Legend Unbound',
    powerWord: 'Mythic',
    emoji: '🐉',
    points: 400,
    description: 'Top 20 globally. The stuff of legends.',
  ),
  RewardTier.rankIcon: TierMeta(
    tier: RewardTier.rankIcon,
    color: RewardColor.rankIcon,
    tagName: 'Ice Icon',
    powerWord: 'Dominant',
    emoji: '💠',
    points: 500,
    description: 'Top 10 globally. Crystalline perfection.',
  ),
  RewardTier.rankGodsend: TierMeta(
    tier: RewardTier.rankGodsend,
    color: RewardColor.rankGodsend,
    tagName: 'Godsend Alpha',
    powerWord: 'Celestial',
    emoji: '💫',
    points: 750,
    description: 'Top 5 globally. Celestial brilliance.',
  ),
  RewardTier.rankVanguard: TierMeta(
    tier: RewardTier.rankVanguard,
    color: RewardColor.rankVanguard,
    tagName: 'Vanguard Supreme',
    powerWord: 'Omnipotent',
    emoji: '🔱',
    points: 1000,
    description: 'Top 3 globally. The vanguard of excellence.',
  ),
  RewardTier.rankSentinel: TierMeta(
    tier: RewardTier.rankSentinel,
    color: RewardColor.rankSentinel,
    tagName: 'Mystic Sentinel',
    powerWord: 'Unmatched',
    emoji: '🦄',
    points: 1500,
    description: 'Rank #1 globally. Truly legendary.',
  ),
};

class RewardTextEngine {
  static String tagReason({
    required RewardTier tier,
    required RewardSource source,
    required double progress,
    required double rating,
    required int completedDays,
    required int hoursPerDay,
    required int taskStack,
    int? globalRank,
    int? unlockedCount,
  }) {
    if (tier == RewardTier.none) {
      return _noRewardReason(progress, rating, source);
    }

    final meta = kTierRegistry[tier]!;
    final prog = progress.toStringAsFixed(0);
    final stars = rating.toStringAsFixed(1);
    final src = source.label;
    final emoji = meta.emoji;
    final name = meta.tagName.toUpperCase();

    // Dashboard rewards
    if (tier.isDashboard) {
      switch (tier) {
        case RewardTier.dashboardApex:
          return '$emoji $name — The ultimate achievement! You\'ve unlocked $unlockedCount rewards. Forever legendary!';
        case RewardTier.dashboardOmega:
          return '$emoji $name — Transcendent mastery! $unlockedCount rewards unlocked. Beyond excellence!';
        case RewardTier.dashboardDiamond:
          return '$emoji $name — Unbreakable brilliance! $unlockedCount+ rewards earned. Timeless mastery!';
        case RewardTier.dashboardPlatinum:
          return '$emoji $name — Enlightened excellence! $unlockedCount rewards unlocked. You\'ve transcended!';
        case RewardTier.dashboardGold:
          return '$emoji $name — Golden ascendance! $unlockedCount rewards earned. Rising to glory!';
        case RewardTier.dashboardSilver:
          return '$emoji $name — Silver dedication! $unlockedCount rewards unlocked. Vigilance recognized!';
        case RewardTier.dashboardBronze:
          return '$emoji $name — Bronze achievement! Your first $unlockedCount rewards. Journey begins!';
        default:
          break;
      }
    }

    // Global rank rewards
    if (tier.isRank) {
      switch (tier) {
        case RewardTier.rankSentinel:
          return '$emoji $name — RANK #1 GLOBALLY! Unmatched mastery. You are the Sentinel!';
        case RewardTier.rankVanguard:
          return '$emoji $name — TOP 3 GLOBALLY! Omnipotent excellence. Vanguard supreme!';
        case RewardTier.rankGodsend:
          return '$emoji $name — TOP 5 GLOBALLY! Celestial brilliance. Godsend achieved!';
        case RewardTier.rankIcon:
          return '$emoji $name — TOP 10 GLOBALLY! Dominant presence. Icon supreme!';
        case RewardTier.rankLegend:
          return '$emoji $name — TOP 20 GLOBALLY! Mythic status. Legend unbound!';
        case RewardTier.rankMaster:
          return '$emoji $name — TOP 50 GLOBALLY! Strategic excellence. Master tactician!';
        case RewardTier.rankElite:
          return '$emoji $name — TOP 100 GLOBALLY! Exceptional ranking. Elite vanguard!';
        default:
          break;
      }
    }

    // Core rewards (existing)
    switch (tier) {
      case RewardTier.nova:
        return '$emoji $name on $src — Pinnacle reached! $completedDays days, $hoursPerDay h/day, $stars★. Truly unstoppable — keep inspiring others!';
      case RewardTier.radiant:
        return '$emoji $name on $src — Outstanding excellence! $completedDays days completed with $prog% progress and $stars★ rating. Pure brilliance!';
      case RewardTier.prism:
        return '$emoji $name on $src — Masterful consistency! $completedDays days, $hoursPerDay h/day commitment with $stars★ quality. Multi-faceted mastery!';
      case RewardTier.crystal:
        return '$emoji $name on $src — Expert focus! $completedDays days of outstanding consistency with $prog% completion and $stars★ rating.';
      case RewardTier.blaze:
        return '$emoji $name on $src — Blazing performance! ${taskStack >= 3 ? '$taskStack-week stack' : '$completedDays days'} at $prog% progress and $stars★ rating.';
      case RewardTier.ember:
        return '$emoji $name on $src — Deep discipline! $prog% progress and $stars★ rating with strong consistency across $completedDays days.';
      case RewardTier.flame:
        return '$emoji $name on $src — Building momentum! $completedDays days completed with $prog% progress and $stars★ rating. Momentum is building!';
      case RewardTier.spark:
        return '$emoji $name on $src — First spark lit! Your journey begins with $prog% progress and $stars★ rating. Keep igniting!';
      default:
        return '$emoji $name — Achievement unlocked!';
    }
  }

  static String _noRewardReason(
      double progress,
      double rating,
      RewardSource source,
      ) {
    final prog = progress.toStringAsFixed(0);
    final stars = rating.toStringAsFixed(1);
    final src = source.label;

    if (progress < 60.0) {
      return "You're at $prog% on $src with $stars★ — reach 60% and 2.0★ to ignite your first Spark!";
    } else if (rating < 2.0) {
      return "You've reached $prog% on $src, but need 2.0★ rating to unlock your first Spark reward. Focus on quality!";
    }
    return "You're at $prog% with $stars★ on $src — almost there!";
  }

  static String suggestion({
    required RewardTier tier,
    required RewardSource source,
    required int progress,
    required double rating,
    required int completed,
    required int missed,
  }) {
    switch (tier) {
      case RewardTier.rankSentinel:
        return "🌟 RANK #1 SENTINEL! You are the global champion. Maintain excellence!";
      case RewardTier.rankVanguard:
        return "👑 Vanguard Supreme! Push for Top 3 to become the Sentinel!";
      case RewardTier.rankGodsend:
        return "✨ Godsend Prime! Reach Top 5 for Vanguard Supreme status!";
      case RewardTier.rankIcon:
        return "🔥 Icon Supreme! Break into Top 10 for Godsend Prime!";
      case RewardTier.rankLegend:
        return "⚔️ Legend Unbound! Push for Top 20 to become Icon Supreme!";
      case RewardTier.rankMaster:
        return "🎯 Master Tactician! Climb to Top 50 for Legend Unbound!";
      case RewardTier.rankElite:
        return "⭐ Elite Vanguard! Reach Top 100 for Master Tactician!";
      case RewardTier.dashboardApex:
        return "👾 APEX ETERNAL! The ultimate achievement unlocked!";
      case RewardTier.dashboardOmega:
        return "Ω Omega Ascendant! Push for Apex Eternal!";
      case RewardTier.dashboardDiamond:
        return "💠 Diamond Sovereign! Aim for Omega Ascendant!";
      case RewardTier.dashboardPlatinum:
        return "🔮 Platinum Oracle! Reach Diamond Sovereign!";
      case RewardTier.dashboardGold:
        return "🔱 Golden Phoenix! Target Platinum Oracle!";
      case RewardTier.dashboardSilver:
        return "☄️ Silver Sentinel! Push for Golden Phoenix!";
      case RewardTier.dashboardBronze:
        return "🍀 Bronze Guardian! Reach Silver Sentinel next!";
      case RewardTier.nova:
        return "🎉 NOVA LEGEND! You have reached the pinnacle. Truly unstoppable!";
      case RewardTier.radiant:
        return "👑 Champion level! Push for 99%+, 4.9★, 60+ days for Nova Legend!";
      case RewardTier.prism:
        return "🏆 Prism Master! Aim for 97%+, 4.7★, 45+ days for Radiant Force!";
      case RewardTier.crystal:
        return "💎 Crystal clear! Target 95%+, 4.5★, 30+ days for Prism Master!";
      case RewardTier.blaze:
        return "⚡ Blazing! Push for 92%+, 4.2★, 21+ days to crystallize into Crystal Mind!";
      case RewardTier.ember:
        return "🌿 Glowing! Hit 88%+, 4.0★, (task_stack ≥ 3 or 14+ days) to reach Full Blaze!";
      case RewardTier.flame:
        return "🔥 Flame rising! Target 80%+, 3.5★, 70% consistency to deepen into Ember!";
      case RewardTier.spark:
        return "✨ First spark lit! Push for 70%+, 3.0★, 3+ days for Rising Flame!";
      case RewardTier.none:
        if (progress < 60) {
          return "Complete more checklist items to cross 60% and unlock your first ✨ Spark reward!";
        } else if (rating < 2.0) {
          return "Improve your task quality (rating) to at least 2.0★ to ignite your Spark!";
        }
        return "Keep pushing! You're very close to your first ✨ Spark reward.";
    }
  }

  static String rewardDisplayName(RewardTier tier) {
    if (tier == RewardTier.none) return 'None';
    final meta = kTierRegistry[tier]!;
    final colorName =
        meta.color.name[0].toUpperCase() + meta.color.name.substring(1);
    return '$colorName ${meta.tagName}';
  }
}
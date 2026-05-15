/// The tier of a reward, ordered from lowest to highest.
enum RewardTier {
  /// No reward earned yet.
  none,

  // ── CORE REWARDS (existing - for Day/Week/Goal/Bucket/Diary) ──
  spark,
  flame,
  ember,
  blaze,
  crystal,
  prism,
  radiant,
  nova,

  // ── DASHBOARD REWARDS (new - 7 tiers) ──
  dashboardBronze, // Dashboard Tier 1
  dashboardSilver, // Dashboard Tier 2
  dashboardGold, // Dashboard Tier 3
  dashboardPlatinum, // Dashboard Tier 4
  dashboardDiamond, // Dashboard Tier 5
  dashboardOmega, // Dashboard Tier 6
  dashboardApex, // Dashboard Tier 7


  // ── GLOBAL RANK REWARDS (new - 7 tiers) ──
  rankElite, // Global Rank Tier 1 (Top 100)
  rankMaster, // Global Rank Tier 2 (Top 50)
  rankLegend, // Global Rank Tier 3 (Top 20)
  rankIcon, // Global Rank Tier 4 (Top 10)
  rankGodsend, // Global Rank Tier 5 (Top 5)
  rankVanguard, // Global Rank Tier 6 (Top 3)
  rankSentinel, // Global Rank Tier 7 (Rank 1)
}

/// The colour variant of a reward.
enum RewardColor {
  // Core
  sparkBlue,
  flameSilver,
  emberGreen,
  blazeOrange,
  crystalDeepBlue,
  prismWhite,
  radiantForest,
  novaCrimson,
  // Dashboard
  dbBronze,
  dbSilver,
  dbGold,
  dbPlatinum,
  dbDiamond,
  dbOmega,
  dbApex,
  // Rank
  rankElite,
  rankMaster,
  rankLegend,
  rankIcon,
  rankGodsend,
  rankVanguard,
  rankSentinel,
}

/// Where the reward was generated from.
enum RewardSource {
  dayTask,
  weekTask,
  longGoal,
  bucket,
  diary,
  dashboard,
  globalRank,
}

// ─────────────────────────────────────────────────────────────────────────────
// EXTENSIONS
// ─────────────────────────────────────────────────────────────────────────────

extension RewardTierX on RewardTier {
  int get level {
    switch (this) {
      case RewardTier.none:
        return 0;
    // CORE
      case RewardTier.spark:
        return 1;
      case RewardTier.flame:
        return 2;
      case RewardTier.ember:
        return 3;
      case RewardTier.blaze:
        return 4;
      case RewardTier.crystal:
        return 5;
      case RewardTier.prism:
        return 6;
      case RewardTier.radiant:
        return 7;
      case RewardTier.nova:
        return 8;
    // DASHBOARD
      case RewardTier.dashboardBronze:
        return 9;
      case RewardTier.dashboardSilver:
        return 10;
      case RewardTier.dashboardGold:
        return 11;
      case RewardTier.dashboardPlatinum:
        return 12;
      case RewardTier.dashboardDiamond:
        return 13;
      case RewardTier.dashboardOmega:
        return 14;
      case RewardTier.dashboardApex:
        return 15;
    // GLOBAL RANK
      case RewardTier.rankElite:
        return 16;
      case RewardTier.rankMaster:
        return 17;
      case RewardTier.rankLegend:
        return 18;
      case RewardTier.rankIcon:
        return 19;
      case RewardTier.rankGodsend:
        return 20;
      case RewardTier.rankVanguard:
        return 21;
      case RewardTier.rankSentinel:
        return 22;
    }
  }

  bool get isDiamond => level >= 5 && level <= 8;
  bool get isDashboard => level >= 9 && level <= 15;
  bool get isRank => level >= 16 && level <= 22;
  bool get isGem => level >= 1 && level <= 4;
  bool get earned => this != RewardTier.none;

  RewardSource get defaultSource {
    if (isDashboard) return RewardSource.dashboard;
    if (isRank) return RewardSource.globalRank;
    return RewardSource.dayTask;
  }
}

extension RewardColorX on RewardColor {
  String get hexCode {
    switch (this) {
    // Core
      case RewardColor.sparkBlue:
        return '#3B82F6'; // Bright Blue
      case RewardColor.flameSilver:
        return '#94A3B8'; // Slate Silver
      case RewardColor.emberGreen:
        return '#10B981'; // Emerald
      case RewardColor.blazeOrange:
        return '#F97316'; // Vivid Orange
      case RewardColor.crystalDeepBlue:
        return '#1D4ED8'; // Royal Blue
      case RewardColor.prismWhite:
        return '#F8FAFC'; // Platinum
      case RewardColor.radiantForest:
        return '#F59E0B'; // Amber Gold (matches Crown 👑)
      case RewardColor.novaCrimson:
        return '#BE123C'; // Rose/Crimson
    // Dashboard
      case RewardColor.dbBronze:
        return '#10B981'; // Emerald (matches Luck 🍀)
      case RewardColor.dbSilver:
        return '#38BDF8'; // Comet Blue (matches ☄️)
      case RewardColor.dbGold:
        return '#EAB308'; // Pure Gold
      case RewardColor.dbPlatinum:
        return '#94A3B8'; // Light Platinum
      case RewardColor.dbDiamond:
        return '#2563EB'; // Diamond Blue
      case RewardColor.dbOmega:
        return '#7C3AED'; // Deep Purple
      case RewardColor.dbApex:
        return '#F59E0B'; // Amber Gold
    // Rank
      case RewardColor.rankElite:
        return '#16A34A'; // Dragon Green (matches 🐲)
      case RewardColor.rankMaster:
        return '#F59E0B'; // Amber/Orange
      case RewardColor.rankLegend:
        return '#15803D'; // Emerald Green
      case RewardColor.rankIcon:
        return '#06B6D4'; // Ice Cyan (matches 💠)
      case RewardColor.rankGodsend:
        return '#EAB308'; // Pure Gold (matches 💫)
      case RewardColor.rankVanguard:
        return '#6366F1'; // Indigo
      case RewardColor.rankSentinel:
        return '#D946EF'; // Mystical Pink (matches 🦄)
    }
  }

  int get argb {
    final hex = hexCode.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}

extension RewardSourceX on RewardSource {
  String get label {
    switch (this) {
      case RewardSource.dayTask:
        return 'Daily Task';
      case RewardSource.weekTask:
        return 'Weekly Task';
      case RewardSource.longGoal:
        return 'Long-term Goal';
      case RewardSource.bucket:
        return 'Bucket List';
      case RewardSource.diary:
        return 'Diary Entry';
      case RewardSource.dashboard:
        return 'Dashboard';
      case RewardSource.globalRank:
        return 'Global Rank';
    }
  }
}
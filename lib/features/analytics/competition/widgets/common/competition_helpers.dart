// ================================================================
// FILE: lib/features/competition/common/competition_helpers.dart
// Utility functions and helpers for competition screens
// ================================================================

import 'package:flutter/material.dart';
import '../../../../../reward_tags/reward_enums.dart';
import 'competition_models.dart';

// ================================================================
// SCORE FORMATTER
// ================================================================
class ScoreHelper {
  static String format(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }

  static String formatWithSuffix(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M pts';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K pts';
    }
    return '$score pts';
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatCompact(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}

// ================================================================
// DATE HELPER
// ================================================================
class DateHelper {
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static String formatShort(DateTime date) {
    return '${date.day}/${date.month}';
  }

  static String formatDay(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  static List<String> getLast7Days() {
    final dates = <String>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dates.add(formatDay(date));
    }
    return dates;
  }

  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days;
  }
}

// ================================================================
// COLOR HELPER
// ================================================================
class ColorHelper {
  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static Color getProgressColor(double progress) {
    if (progress >= 90) return const Color(0xFF10B981);
    if (progress >= 70) return const Color(0xFF3B82F6);
    if (progress >= 50) return const Color(0xFFF97316);
    if (progress >= 30) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  static Color getStreakColor(int streak) {
    if (streak >= 30) return const Color(0xFFEF4444);
    if (streak >= 14) return const Color(0xFFF97316);
    if (streak >= 7) return const Color(0xFFFBBF24);
    if (streak >= 3) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  static Color getMoodColor(double mood) {
    if (mood >= 8.5) return const Color(0xFF10B981);
    if (mood >= 7.0) return const Color(0xFF3B82F6);
    if (mood >= 5.0) return const Color(0xFFFBBF24);
    if (mood >= 3.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  static LinearGradient getGradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'tasks':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        );
      case 'goals':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
        );
      case 'buckets':
        return const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
        );
      case 'diary':
        return const LinearGradient(colors: [Colors.teal, Color(0xFF34D399)]);
      case 'streak':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        );
    }
  }
}

// ================================================================
// RANK CALCULATOR
// ================================================================
class RankHelper {
  static int calculateRank(List<int> scores, int targetScore) {
    final sorted = List<int>.from(scores)..sort((a, b) => b.compareTo(a));
    return sorted.indexOf(targetScore) + 1;
  }

  static List<CompetitorData> sortByScore(List<CompetitorData> competitors) {
    return List.from(competitors)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
  }

  static Map<String, int> assignRanks(List<CompetitorData> competitors) {
    final sorted = sortByScore(competitors);
    final Map<String, int> ranks = {};

    for (int i = 0; i < sorted.length; i++) {
      ranks[sorted[i].id] = i + 1;
    }

    return ranks;
  }

  static String getRankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }
}

// ================================================================
// PROGRESS CALCULATOR
// ================================================================
class ProgressHelper {
  static double calculatePercentage(int completed, int total) {
    if (total == 0) return 0;
    return (completed / total * 100).clamp(0, 100);
  }

  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static Map<String, double> calculateCategoryAverages(
    List<CompetitorData> competitors,
  ) {
    if (competitors.isEmpty) {
      return {'tasks': 0, 'goals': 0, 'buckets': 0, 'diary': 0, 'streak': 0};
    }

    double tasksSum = 0;
    double goalsSum = 0;
    double bucketsSum = 0;
    double diarySum = 0;
    double streakSum = 0;

    for (final c in competitors) {
      tasksSum += c.tasksCompletionRate;
      goalsSum += c.goalsProgress;
      bucketsSum += c.bucketCompletionRate;
      diarySum += (c.diaryEntries / 30) * 100;
      streakSum += (c.currentStreak / 30) * 100;
    }

    final count = competitors.length;
    return {
      'tasks': tasksSum / count,
      'goals': goalsSum / count,
      'buckets': bucketsSum / count,
      'diary': diarySum / count,
      'streak': streakSum / count,
    };
  }
}

// ================================================================
// DATA AGGREGATOR
// ================================================================
class DataAggregator {
  static int sumScores(List<CompetitorData> competitors) {
    return competitors.fold(0, (sum, c) => sum + c.totalScore);
  }

  static double averageCompletionRate(List<CompetitorData> competitors) {
    if (competitors.isEmpty) return 0;
    final sum = competitors.fold<double>(0, (sum, c) => sum + c.completionRate);
    return sum / competitors.length;
  }

  static int totalRewards(List<CompetitorData> competitors) {
    return competitors.fold(0, (sum, c) => sum + c.totalRewards);
  }

  static Map<String, int> aggregateByCategory(
    List<CompetitorData> competitors,
  ) {
    int tasks = 0;
    int goals = 0;
    int buckets = 0;
    int diary = 0;
    int streak = 0;

    for (final c in competitors) {
      tasks += c.taskPoints;
      goals += c.goalPoints;
      buckets += c.bucketPoints;
      diary += c.diaryPoints;
      streak += c.streakPoints;
    }

    return {
      'tasks': tasks,
      'goals': goals,
      'buckets': buckets,
      'diary': diary,
      'streak': streak,
    };
  }

  static List<ChartDataPoint> getDistributionData(
    List<CompetitorData> competitors,
  ) {
    final aggregated = aggregateByCategory(competitors);

    return [
      ChartDataPoint(
        label: 'Tasks',
        value: aggregated['tasks']!.toDouble(),
        color: const Color(0xFF8B5CF6),
      ),
      ChartDataPoint(
        label: 'Goals',
        value: aggregated['goals']!.toDouble(),
        color: const Color(0xFF3B82F6),
      ),
      ChartDataPoint(
        label: 'Buckets',
        value: aggregated['buckets']!.toDouble(),
        color: const Color(0xFFF97316),
      ),
      ChartDataPoint(
        label: 'Diary',
        value: aggregated['diary']!.toDouble(),
        color: Colors.teal,
      ),
      ChartDataPoint(
        label: 'Streak',
        value: aggregated['streak']!.toDouble(),
        color: Colors.deepOrange,
      ),
    ];
  }
}

// ================================================================
// CHART DATA TRANSFORMER
// ================================================================
class ChartDataTransformer {
  static List<Map<String, dynamic>> toBarGroups(List<ChartDataPoint> points) {
    return points.asMap().entries.map((entry) {
      return {
        'x': entry.key,
        'y': entry.value.value,
        'label': entry.value.label,
        'color': entry.value.color,
      };
    }).toList();
  }

  static Map<String, dynamic> toRadarData(List<RadarDataSet> datasets) {
    return {
      'datasets': datasets
          .map((d) => {'name': d.name, 'values': d.values, 'color': d.color})
          .toList(),
    };
  }

  static List<Map<String, dynamic>> toLineSpots(List<double> values) {
    return values.asMap().entries.map((entry) {
      return {'x': entry.key.toDouble(), 'y': entry.value};
    }).toList();
  }

  static List<Map<String, dynamic>> toPieSections(List<ChartDataPoint> points) {
    return points.map((p) {
      return {
        'value': p.value,
        'color': p.color,
        'label': p.label,
        'tooltip': p.tooltip ?? '${ScoreHelper.format(p.value.toInt())} pts',
      };
    }).toList();
  }
}

// ================================================================
// VALIDATION HELPER
// ================================================================
class ValidationHelper {
  static bool isValidScore(int score) {
    return score >= 0;
  }

  static bool isValidPercentage(double value) {
    return value >= 0 && value <= 100;
  }

  static bool isValidRank(int rank) {
    return rank > 0;
  }

  static bool isValidId(String id) {
    return id.isNotEmpty && id.length >= 3;
  }

  static String validateName(String name) {
    if (name.isEmpty) return 'Unknown';
    if (name.length > 20) return '${name.substring(0, 17)}...';
    return name;
  }
}

// ================================================================
// COMPARISON HELPER
// ================================================================
class ComparisonHelper {
  static String getComparisonText(int userScore, int competitorScore) {
    if (userScore > competitorScore) {
      final diff = userScore - competitorScore;
      return 'You are ahead by ${ScoreHelper.format(diff)} pts';
    } else if (competitorScore > userScore) {
      final diff = competitorScore - userScore;
      return 'You need ${ScoreHelper.format(diff)} pts to catch up';
    } else {
      return "It's a tie!";
    }
  }

  static Color getComparisonColor(int userScore, int competitorScore) {
    if (userScore > competitorScore) return Colors.green;
    if (competitorScore > userScore) return Colors.red;
    return Colors.orange;
  }

  static IconData getComparisonIcon(int userScore, int competitorScore) {
    if (userScore > competitorScore) return Icons.arrow_upward_rounded;
    if (competitorScore > userScore) return Icons.arrow_downward_rounded;
    return Icons.horizontal_rule_rounded;
  }

  static String getWinPercentage(int userScore, int competitorScore) {
    final total = userScore + competitorScore;
    if (total == 0) return '50%';
    final percentage = (userScore / total * 100).toStringAsFixed(1);
    return '$percentage%';
  }
}

// ================================================================
// STREAK HELPER
// ================================================================
class StreakHelper {
  static String getStreakEmoji(int streak) {
    if (streak >= 30) return '🔥🔥🔥';
    if (streak >= 14) return '🔥🔥';
    if (streak >= 7) return '🔥';
    if (streak >= 3) return '⚡';
    if (streak >= 1) return '✨';
    return '💤';
  }

  static String getStreakMessage(int streak) {
    if (streak >= 30) return 'Legendary!';
    if (streak >= 14) return 'Incredible!';
    if (streak >= 7) return 'Great streak!';
    if (streak >= 3) return 'Getting started!';
    if (streak >= 1) return 'Keep going!';
    return 'Start your streak!';
  }

  static int calculateStreak(List<bool> daysActive) {
    int streak = 0;
    for (int i = daysActive.length - 1; i >= 0; i--) {
      if (daysActive[i]) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static List<bool> generateMockStreakDays(int streak) {
    final days = List.filled(30, false);
    for (int i = 0; i < streak.clamp(0, 30); i++) {
      days[29 - i] = true;
    }
    return days;
  }
}

// ================================================================
// REWARD HELPER
// ================================================================
class RewardHelper {
  static String getRewardEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }

  static Color getRewardColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static String getRewardTierName(RewardTier tier) {
    if (tier == RewardTier.none) return 'No Reward';

    switch (tier) {
      case RewardTier.spark:
        return 'Spark';
      case RewardTier.flame:
        return 'Flame';
      case RewardTier.ember:
        return 'Ember';
      case RewardTier.blaze:
        return 'Blaze';
      case RewardTier.crystal:
        return 'Crystal';
      case RewardTier.prism:
        return 'Prism';
      case RewardTier.radiant:
        return 'Radiant';
      case RewardTier.nova:
        return 'Nova';
      case RewardTier.dashboardBronze:
        return 'Bronze Guardian';
      case RewardTier.dashboardSilver:
        return 'Silver Sentinel';
      case RewardTier.dashboardGold:
        return 'Gold Phoenix';
      case RewardTier.dashboardPlatinum:
        return 'Platinum Oracle';
      case RewardTier.dashboardDiamond:
        return 'Diamond Sovereign';
      case RewardTier.dashboardOmega:
        return 'Omega Ascendant';
      case RewardTier.dashboardApex:
        return 'Apex Eternal';
      case RewardTier.rankElite:
        return 'Elite Vanguard';
      case RewardTier.rankMaster:
        return 'Master Tactician';
      case RewardTier.rankLegend:
        return 'Legend Unbound';
      case RewardTier.rankIcon:
        return 'Icon Supreme';
      case RewardTier.rankGodsend:
        return 'Godsend Alpha';
      case RewardTier.rankVanguard:
        return 'Vanguard Supreme';
      case RewardTier.rankSentinel:
        return 'Sentinel Prime';
      default:
        return '';
    }
  }
}

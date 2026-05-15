// ================================================================
// FILE: lib/features/competition/common/competition_models.dart
// Data models for competition screens
// ================================================================

import 'package:flutter/material.dart';
import '../../../../../reward_tags/reward_enums.dart';
import '../../../../../reward_tags/reward_manager.dart';

// ================================================================
// COMPETITOR DATA MODEL
// ================================================================
class CompetitorData {
  final String id;
  final String name;
  final String? avatarUrl;
  final int totalScore;
  final int globalRank;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final int totalRewards;
  final double averageRating;
  final bool isOwner;

  // Task stats
  final int dailyTasksCompleted;
  final int dailyTasksTotal;
  final int weeklyTasksCompleted;
  final int weeklyTasksTotal;
  final double dailyCompletionRate;
  final double weeklyCompletionRate;

  // Goal stats
  final int activeGoals;
  final int completedGoals;
  final double goalsProgress;

  // Bucket stats
  final int bucketsCompleted;
  final int bucketsTotal;
  final double bucketCompletionRate;

  // Diary stats
  final int diaryEntries;
  final double moodAverage;
  final String lastMoodEmoji;

  // Points breakdown
  final int taskPoints;
  final int goalPoints;
  final int bucketPoints;
  final int diaryPoints;
  final int streakPoints;

  const CompetitorData({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.totalScore,
    required this.globalRank,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.totalRewards,
    required this.averageRating,
    required this.isOwner,
    required this.dailyTasksCompleted,
    required this.dailyTasksTotal,
    required this.weeklyTasksCompleted,
    required this.weeklyTasksTotal,
    required this.dailyCompletionRate,
    required this.weeklyCompletionRate,
    required this.activeGoals,
    required this.completedGoals,
    required this.goalsProgress,
    required this.bucketsCompleted,
    required this.bucketsTotal,
    required this.bucketCompletionRate,
    required this.diaryEntries,
    required this.moodAverage,
    required this.lastMoodEmoji,
    required this.taskPoints,
    required this.goalPoints,
    required this.bucketPoints,
    required this.diaryPoints,
    required this.streakPoints,
  });

  factory CompetitorData.empty({String id = '', String name = 'Unknown'}) {
    return CompetitorData(
      id: id,
      name: name,
      avatarUrl: null,
      totalScore: 0,
      globalRank: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0,
      totalRewards: 0,
      averageRating: 0,
      isOwner: false,
      dailyTasksCompleted: 0,
      dailyTasksTotal: 0,
      weeklyTasksCompleted: 0,
      weeklyTasksTotal: 0,
      dailyCompletionRate: 0,
      weeklyCompletionRate: 0,
      activeGoals: 0,
      completedGoals: 0,
      goalsProgress: 0,
      bucketsCompleted: 0,
      bucketsTotal: 0,
      bucketCompletionRate: 0,
      diaryEntries: 0,
      moodAverage: 0,
      lastMoodEmoji: '😐',
      taskPoints: 0,
      goalPoints: 0,
      bucketPoints: 0,
      diaryPoints: 0,
      streakPoints: 0,
    );
  }

  // Helper getters
  int get totalTasks => dailyTasksTotal + weeklyTasksTotal;
  int get completedTasks => dailyTasksCompleted + weeklyTasksCompleted;
  double get tasksCompletionRate => totalTasks > 0
      ? (completedTasks / totalTasks * 100)
      : 0;

  String get rankEmoji {
    if (globalRank == 1) return '🥇';
    if (globalRank == 2) return '🥈';
    if (globalRank == 3) return '🥉';
    return '#$globalRank';
  }

  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    if (currentStreak >= 3) return '⚡';
    return '🌱';
  }
}

// ================================================================
// OVERVIEW SCREEN DATA
// ================================================================
class CompetitionOverviewData {
  final CompetitorData currentUser;
  final List<CompetitorData> competitors;
  final DateTime lastUpdated;

  const CompetitionOverviewData({
    required this.currentUser,
    required this.competitors,
    required this.lastUpdated,
  });

  factory CompetitionOverviewData.empty() {
    return CompetitionOverviewData(
      currentUser: CompetitorData.empty(id: 'user', name: 'You'),
      competitors: [],
      lastUpdated: DateTime.now(),
    );
  }

  // Derived data
  List<CompetitorData> get topCompetitors {
    final list = List<CompetitorData>.from(competitors);
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list.take(5).toList();
  }

  List<ChartDataPoint> get scoreComparisonData {
    final points = [
      ChartDataPoint(
        label: 'You',
        value: currentUser.totalScore.toDouble(),
        color: const Color(0xFF8B5CF6),
        avatarUrl: currentUser.avatarUrl,
        isUser: true,
      ),
      ...topCompetitors.map((c) => ChartDataPoint(
        label: c.name.length > 6 ? '${c.name.substring(0, 5)}...' : c.name,
        value: c.totalScore.toDouble(),
        color: const Color(0xFF3B82F6),
        avatarUrl: c.avatarUrl,
        isUser: false,
      )),
    ];

    // Fill empty slots
    while (points.length < 6) {
      points.add(ChartDataPoint(
        label: 'Empty',
        value: 0,
        color: Colors.grey.withOpacity(0.3),
      ));
    }

    return points;
  }

  List<ActivityEvent> get recentActivities {
    final events = <ActivityEvent>[];

    // Add user activities
    events.add(ActivityEvent(
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatarUrl,
      type: ActivityType.streak,
      title: 'Streak Milestone',
      description: '${currentUser.currentStreak} day streak!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      points: currentUser.currentStreak * 5,
    ));

    // Add competitor activities
    for (final comp in competitors.take(3)) {
      events.add(ActivityEvent(
        userId: comp.id,
        userName: comp.name,
        userAvatar: comp.avatarUrl,
        type: ActivityType.task,
        title: 'Completed Daily Tasks',
        description: 'All daily tasks completed',
        timestamp: DateTime.now().subtract(Duration(hours: 3 + competitors.indexOf(comp))),
        points: 50,
      ));
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  Map<String, dynamic> toJson() => {
    'currentUser': currentUser,
    'competitors': competitors.map((c) => c.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

class StackedBarData {
  final String label;
  final List<double> values;
  final List<Color> colors;

  StackedBarData({
    required this.label,
    required this.values,
    required this.colors,
  });
}

// ================================================================
// DETAIL SCREEN DATA
// ================================================================
class CompetitionDetailData {
  final CompetitorData user;
  final CompetitorData competitor;
  final DateTime lastUpdated;

  const CompetitionDetailData({
    required this.user,
    required this.competitor,
    required this.lastUpdated,
  });

  factory CompetitionDetailData.empty() {
    return CompetitionDetailData(
      user: CompetitorData.empty(id: 'user', name: 'You'),
      competitor: CompetitorData.empty(id: 'comp', name: 'Competitor'),
      lastUpdated: DateTime.now(),
    );
  }

  // Comparison metrics
  bool get isUserWinning => user.totalScore > competitor.totalScore;
  bool get isTied => user.totalScore == competitor.totalScore;
  int get pointDifference => (user.totalScore - competitor.totalScore).abs();

  double get userWinPercentage {
    final total = user.totalScore + competitor.totalScore;
    return total > 0 ? user.totalScore / total : 0.5;
  }

  // Radar chart data for metrics comparison
  List<RadarDataSet> get radarData {
    return [
      RadarDataSet(
        name: user.name,
        values: [
          user.dailyCompletionRate,
          user.weeklyCompletionRate,
          user.goalsProgress,
          user.bucketCompletionRate,
          (user.moodAverage / 10) * 100,
          (user.currentStreak / 30) * 100,
        ],
        color: const Color(0xFF8B5CF6),
      ),
      RadarDataSet(
        name: competitor.name,
        values: [
          competitor.dailyCompletionRate,
          competitor.weeklyCompletionRate,
          competitor.goalsProgress,
          competitor.bucketCompletionRate,
          (competitor.moodAverage / 10) * 100,
          (competitor.currentStreak / 30) * 100,
        ],
        color: const Color(0xFF3B82F6),
      ),
    ];
  }

  List<String> get radarLabels => const [
    'Daily Tasks',
    'Weekly Tasks',
    'Goals',
    'Buckets',
    'Mood',
    'Streak',
  ];

  // Category comparison
  List<MetricComparison> get metricComparisons => [
    MetricComparison(
      category: 'Daily Tasks',
      userValue: '${user.dailyTasksCompleted}/${user.dailyTasksTotal}',
      competitorValue: '${competitor.dailyTasksCompleted}/${competitor.dailyTasksTotal}',
      userProgress: user.dailyCompletionRate,
      competitorProgress: competitor.dailyCompletionRate,
      userColor: const Color(0xFF8B5CF6),
      competitorColor: const Color(0xFF3B82F6),
    ),
    MetricComparison(
      category: 'Weekly Tasks',
      userValue: '${user.weeklyTasksCompleted}/${user.weeklyTasksTotal}',
      competitorValue: '${competitor.weeklyTasksCompleted}/${competitor.weeklyTasksTotal}',
      userProgress: user.weeklyCompletionRate,
      competitorProgress: competitor.weeklyCompletionRate,
      userColor: const Color(0xFF8B5CF6),
      competitorColor: const Color(0xFF3B82F6),
    ),
    MetricComparison(
      category: 'Goals',
      userValue: '${user.completedGoals}/${user.activeGoals}',
      competitorValue: '${competitor.completedGoals}/${competitor.activeGoals}',
      userProgress: user.goalsProgress,
      competitorProgress: competitor.goalsProgress,
      userColor: const Color(0xFF10B981),
      competitorColor: const Color(0xFF34D399),
    ),
    MetricComparison(
      category: 'Bucket List',
      userValue: '${user.bucketsCompleted}/${user.bucketsTotal}',
      competitorValue: '${competitor.bucketsCompleted}/${competitor.bucketsTotal}',
      userProgress: user.bucketCompletionRate,
      competitorProgress: competitor.bucketCompletionRate,
      userColor: const Color(0xFFF97316),
      competitorColor: const Color(0xFFFBBF24),
    ),
    MetricComparison(
      category: 'Diary',
      userValue: '${user.diaryEntries} entries',
      competitorValue: '${competitor.diaryEntries} entries',
      userProgress: (user.diaryEntries / 30) * 100,
      competitorProgress: (competitor.diaryEntries / 30) * 100,
      userColor: Colors.teal,
      competitorColor: Colors.tealAccent,
    ),
    MetricComparison(
      category: 'Streak',
      userValue: '${user.currentStreak} days',
      competitorValue: '${competitor.currentStreak} days',
      userProgress: (user.currentStreak / 30) * 100,
      competitorProgress: (competitor.currentStreak / 30) * 100,
      userColor: Colors.deepOrange,
      competitorColor: Colors.orange,
    ),
  ];
}

// ================================================================
// MY DATA SCREEN (MULTI-COMPARISON) DATA
// ================================================================
class MyCompetitionData {
  final CompetitorData currentUser;
  final List<CompetitorData> competitors;
  final DateTime lastUpdated;

  const MyCompetitionData({
    required this.currentUser,
    required this.competitors,
    required this.lastUpdated,
  });

  factory MyCompetitionData.empty() {
    return MyCompetitionData(
      currentUser: CompetitorData.empty(id: 'user', name: 'You'),
      competitors: [],
      lastUpdated: DateTime.now(),
    );
  }

  // All participants including user
  List<CompetitorData> get allParticipants {
    return [currentUser, ...competitors];
  }

  // Sorted by score
  List<CompetitorData> get rankedParticipants {
    final list = List<CompetitorData>.from(allParticipants);
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list;
  }

  // Get rank for a participant
  int getRank(String id) {
    final ranked = rankedParticipants;
    final index = ranked.indexWhere((p) => p.id == id);
    return index >= 0 ? index + 1 : 0;
  }

  // Max score across all participants
  int get maxScore {
    return allParticipants.map((p) => p.totalScore).reduce((a, b) => a > b ? a : b);
  }

  // Chart data for category comparison
  List<BarChartData> getBarChartData(ComparisonCategory category) {
    return allParticipants.map((p) {
      double value;
      switch (category) {
        case ComparisonCategory.overall:
          value = p.totalScore.toDouble();
          break;
        case ComparisonCategory.tasks:
          value = p.taskPoints.toDouble();
          break;
        case ComparisonCategory.goals:
          value = p.goalPoints.toDouble();
          break;
        case ComparisonCategory.buckets:
          value = p.bucketPoints.toDouble();
          break;
        case ComparisonCategory.diary:
          value = p.diaryPoints.toDouble();
          break;
        case ComparisonCategory.streaks:
          value = p.streakPoints.toDouble();
          break;
      }
      return BarChartData(
        label: p.id == currentUser.id ? 'You' : p.name,
        value: value,
        color: p.id == currentUser.id
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF3B82F6),
        isUser: p.id == currentUser.id,
      );
    }).toList();
  }

  // Leaderboard entries
  List<LeaderboardEntry> get leaderboard {
    return rankedParticipants.asMap().entries.map((entry) {
      final index = entry.key;
      final p = entry.value;
      return LeaderboardEntry(
        rank: index + 1,
        id: p.id,
        name: p.name,
        avatarUrl: p.avatarUrl,
        score: p.totalScore,
        isUser: p.id == currentUser.id,
        streak: p.currentStreak,
        completionRate: p.completionRate,
      );
    }).toList();
  }

  // Streak comparison data
  List<StreakData> get streakComparison {
    return allParticipants.map((p) {
      return StreakData(
        name: p.id == currentUser.id ? 'You' : p.name,
        current: p.currentStreak,
        longest: p.longestStreak,
        isUser: p.id == currentUser.id,
        emoji: p.streakEmoji,
      );
    }).toList()
      ..sort((a, b) => b.current.compareTo(a.current));
  }

  // Rewards comparison
  List<RewardsData> get rewardsComparison {
    return allParticipants.map((p) {
      final reward = RewardManager.forDashboardSummary(
        globalRank: p.globalRank,
        pointsToday: p.taskPoints,
        totalPoints: p.totalScore,
        totalRewards: p.totalRewards,
        averageRating: p.averageRating,
        currentStreak: p.currentStreak,
        longestStreak: p.longestStreak,
        averageProgress: p.completionRate.toInt(),
        pointsThisWeek: p.taskPoints + p.goalPoints,
        bestTierAchieved: '',
        completionRateAll: p.completionRate,
        completionRateWeek: p.weeklyCompletionRate,
        completionRateToday: p.dailyCompletionRate,
        dailyTasksPoints: p.taskPoints,
        weeklyTasksPoints: p.taskPoints,
        longGoalsPoints: p.goalPoints,
        bucketListPoints: p.bucketPoints,
      );

      return RewardsData(
        name: p.id == currentUser.id ? 'You' : p.name,
        gold: reward.tier == RewardTier.dashboardGold ? 1 : 0,
        silver: reward.tier == RewardTier.dashboardSilver ? 1 : 0,
        bronze: reward.tier == RewardTier.dashboardBronze ? 1 : 0,
        isUser: p.id == currentUser.id,
        tier: reward.tier,
      );
    }).toList()
      ..sort((a, b) => b.weightedTotal.compareTo(a.weightedTotal));
  }
}

// ================================================================
// SUPPORTING MODELS
// ================================================================

enum ComparisonCategory {
  overall,
  tasks,
  goals,
  buckets,
  diary,
  streaks,
}

// Chart data point
class ChartDataPoint {
  final String label;
  final double value;
  final Color color;
  final String? tooltip;
  final String? avatarUrl;
  final bool isUser;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    this.tooltip,
    this.avatarUrl,
    this.isUser = false,
  });
}

// Bar chart data
class BarChartData {
  final String label;
  final double value;
  final Color color;
  final bool isUser;

  BarChartData({
    required this.label,
    required this.value,
    required this.color,
    required this.isUser,
  });
}

// Radar data set
class RadarDataSet {
  final String name;
  final List<double> values;
  final Color color;

  RadarDataSet({
    required this.name,
    required this.values,
    required this.color,
  });
}

// Metric comparison
class MetricComparison {
  final String category;
  final String userValue;
  final String competitorValue;
  final double userProgress;
  final double competitorProgress;
  final Color userColor;
  final Color competitorColor;

  MetricComparison({
    required this.category,
    required this.userValue,
    required this.competitorValue,
    required this.userProgress,
    required this.competitorProgress,
    required this.userColor,
    required this.competitorColor,
  });

  bool get isUserWinning {
    if (userProgress > competitorProgress) return true;
    if (userProgress < competitorProgress) return false;

    // If progress equal, compare actual values
    final userNum = double.tryParse(userValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final compNum = double.tryParse(competitorValue.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    return userNum > compNum;
  }
}

// Leaderboard entry
class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String? avatarUrl;
  final int score;
  final bool isUser;
  final int streak;
  final double completionRate;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.score,
    required this.isUser,
    required this.streak,
    required this.completionRate,
  });

  String get rankEmoji {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  Color get rankColor {
    if (rank == 1) return const Color(0xFFFBBF24);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey;
  }
}

// Streak data
class StreakData {
  final String name;
  final int current;
  final int longest;
  final bool isUser;
  final String emoji;

  StreakData({
    required this.name,
    required this.current,
    required this.longest,
    required this.isUser,
    required this.emoji,
  });
}

// Rewards data
class RewardsData {
  final String name;
  final int gold;
  final int silver;
  final int bronze;
  final bool isUser;
  final RewardTier tier;

  RewardsData({
    required this.name,
    required this.gold,
    required this.silver,
    required this.bronze,
    required this.isUser,
    required this.tier,
  });

  int get weightedTotal => gold * 3 + silver * 2 + bronze;
  int get total => gold + silver + bronze;
}

// Activity event
enum ActivityType {
  task,
  goal,
  bucket,
  diary,
  streak,
}

class ActivityEvent {
  final String userId;
  final String userName;
  final String? userAvatar;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final int points;

  ActivityEvent({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.points,
  });

  Color get typeColor {
    switch (type) {
      case ActivityType.task:
        return const Color(0xFF8B5CF6);
      case ActivityType.goal:
        return const Color(0xFF3B82F6);
      case ActivityType.bucket:
        return const Color(0xFFF97316);
      case ActivityType.diary:
        return Colors.teal;
      case ActivityType.streak:
        return Colors.deepOrange;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ActivityType.task:
        return Icons.task_alt_rounded;
      case ActivityType.goal:
        return Icons.flag_rounded;
      case ActivityType.bucket:
        return Icons.inventory_2_rounded;
      case ActivityType.diary:
        return Icons.book_rounded;
      case ActivityType.streak:
        return Icons.local_fire_department_rounded;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Extensions for CompetitorData serialization
extension CompetitorDataX on CompetitorData {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'totalScore': totalScore,
    'globalRank': globalRank,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'completionRate': completionRate,
    'totalRewards': totalRewards,
    'averageRating': averageRating,
    'isOwner': isOwner,
    'dailyTasksCompleted': dailyTasksCompleted,
    'dailyTasksTotal': dailyTasksTotal,
    'weeklyTasksCompleted': weeklyTasksCompleted,
    'weeklyTasksTotal': weeklyTasksTotal,
    'dailyCompletionRate': dailyCompletionRate,
    'weeklyCompletionRate': weeklyCompletionRate,
    'activeGoals': activeGoals,
    'completedGoals': completedGoals,
    'goalsProgress': goalsProgress,
    'bucketsCompleted': bucketsCompleted,
    'bucketsTotal': bucketsTotal,
    'bucketCompletionRate': bucketCompletionRate,
    'diaryEntries': diaryEntries,
    'moodAverage': moodAverage,
    'lastMoodEmoji': lastMoodEmoji,
    'taskPoints': taskPoints,
    'goalPoints': goalPoints,
    'bucketPoints': bucketPoints,
    'diaryPoints': diaryPoints,
    'streakPoints': streakPoints,
  };
}
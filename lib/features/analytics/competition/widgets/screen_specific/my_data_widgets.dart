// ================================================================
// FILE: lib/features/competition/widgets/screen_specific/my_data_widgets.dart
// Widgets for My Competition Data Screen (Multi-Comparison)
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/competition_helpers.dart';
import '../common/competition_models.dart';
import '../common/competition_shared_widgets.dart';

// ================================================================
// LIVE LEADERBOARD ROW
// ================================================================
class LiveLeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int index;

  const LiveLeaderboardRow({
    super.key,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTop3 = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: entry.isUser || isTop3
            ? LinearGradient(
          colors: [
            entry.rankColor.withOpacity(0.15),
            entry.rankColor.withOpacity(0.05),
          ],
        )
            : null,
        color: entry.isUser || isTop3
            ? null
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(12),
        border: entry.isUser
            ? Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 2)
            : (isTop3 ? Border.all(color: entry.rankColor.withOpacity(0.3)) : null),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isTop3 ? LinearGradient(colors: [
                entry.rankColor,
                entry.rankColor.withOpacity(0.7),
              ]) : null,
              color: isTop3 ? null : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: isTop3
                  ? Text(
                entry.rankEmoji,
                style: const TextStyle(fontSize: 18),
              )
                  : Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          PulseAvatar(
            imageUrl: entry.avatarUrl,
            name: entry.name,
            size: 40,
            borderGradient: entry.isUser
                ? const [Color(0xFF8B5CF6), Color(0xFFEC4899)]
                : (entry.rank == 1
                ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                : const [Color(0xFF3B82F6), Color(0xFF06B6D4)]),
            showPulse: entry.isUser,
          ),

          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: entry.isUser ? FontWeight.w900 : FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (entry.isUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.rank == 1)
                  Text(
                    '👑 Leading the pack!',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFFBBF24),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: entry.isUser
                      ? const [Color(0xFF8B5CF6), Color(0xFFEC4899)]
                      : [entry.rankColor, entry.rankColor.withOpacity(0.7)],
                ).createShader(bounds),
                child: Text(
                  ScoreHelper.format(entry.score),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CATEGORY CHIP
// ================================================================
class CategoryChip extends StatelessWidget {
  final ComparisonCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  String get _emoji {
    switch (category) {
      case ComparisonCategory.overall:
        return '🏆';
      case ComparisonCategory.tasks:
        return '✅';
      case ComparisonCategory.goals:
        return '🎯';
      case ComparisonCategory.buckets:
        return '🪣';
      case ComparisonCategory.diary:
        return '📔';
      case ComparisonCategory.streaks:
        return '🔥';
    }
  }

  String get _label {
    switch (category) {
      case ComparisonCategory.overall:
        return 'Overall';
      case ComparisonCategory.tasks:
        return 'Tasks';
      case ComparisonCategory.goals:
        return 'Goals';
      case ComparisonCategory.buckets:
        return 'Buckets';
      case ComparisonCategory.diary:
        return 'Diary';
      case ComparisonCategory.streaks:
        return 'Streaks';
    }
  }

  List<Color> get _colors {
    switch (category) {
      case ComparisonCategory.overall:
        return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
      case ComparisonCategory.tasks:
        return const [Color(0xFF8B5CF6), Color(0xFFEC4899)];
      case ComparisonCategory.goals:
        return const [Color(0xFF3B82F6), Color(0xFF06B6D4)];
      case ComparisonCategory.buckets:
        return const [Color(0xFFF97316), Color(0xFFFBBF24)];
      case ComparisonCategory.diary:
        return [Colors.teal, Colors.tealAccent];
      case ComparisonCategory.streaks:
        return const [Color(0xFFEF4444), Color(0xFFF97316)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: _colors) : null,
          color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// METRICS TABLE
// ================================================================
class MetricsTable extends StatelessWidget {
  final List<CompetitorData> participants;
  final ComparisonCategory category;

  const MetricsTable({
    super.key,
    required this.participants,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 140), // Space for label
                ...participants.map((p) => _buildHeaderCell(p, isDark)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Metrics rows
          ..._buildMetricRows(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(CompetitorData participant, bool isDark) {
    return Container(
      width: 70,
      alignment: Alignment.center,
      child: Text(
        participant.id == 'user' ? 'You' : participant.name.split(' ').first,
        style: TextStyle(
          fontSize: 11,
          fontWeight: participant.id == 'user' ? FontWeight.bold : FontWeight.w600,
          color: participant.id == 'user'
              ? const Color(0xFF8B5CF6)
              : (isDark ? Colors.white70 : Colors.black54),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<Widget> _buildMetricRows(bool isDark) {
    final metrics = _getMetricsForCategory();

    return metrics.map((metric) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Label
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Icon(
                      metric.icon,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      metric.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Values
              ...metric.values.map((value) => _buildMetricValue(
                isDark,
                value,
                value.isUser,
                value.isHighest,
              )),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMetricValue(bool isDark, _MetricValue value, bool isUser, bool isHighest) {
    return Container(
      width: 70,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: isHighest ? BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ) : null,
        child: Text(
          value.text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isUser || isHighest ? FontWeight.bold : FontWeight.w500,
            color: isHighest
                ? const Color(0xFF10B981)
                : (isUser
                ? const Color(0xFF8B5CF6)
                : (isDark ? Colors.white70 : Colors.black87)),
          ),
        ),
      ),
    );
  }

  List<_MetricRow> _getMetricsForCategory() {
    switch (category) {
      case ComparisonCategory.overall:
        return [
          _MetricRow(
            icon: Icons.star_rounded,
            label: 'Total Score',
            values: participants.map((p) => _MetricValue(
              text: ScoreHelper.format(p.totalScore),
              isUser: p.id == 'user',
              isHighest: p.totalScore == participants.map((e) => e.totalScore).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.emoji_events_rounded,
            label: 'Rewards',
            values: participants.map((p) => _MetricValue(
              text: p.totalRewards.toString(),
              isUser: p.id == 'user',
              isHighest: p.totalRewards == participants.map((e) => e.totalRewards).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.percent_rounded,
            label: 'Completion',
            values: participants.map((p) => _MetricValue(
              text: '${p.completionRate.toStringAsFixed(0)}%',
              isUser: p.id == 'user',
              isHighest: p.completionRate == participants.map((e) => e.completionRate).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];

      case ComparisonCategory.tasks:
        return [
          _MetricRow(
            icon: Icons.today_rounded,
            label: 'Daily Tasks',
            values: participants.map((p) => _MetricValue(
              text: '${p.dailyTasksCompleted}/${p.dailyTasksTotal}',
              isUser: p.id == 'user',
              isHighest: p.dailyCompletionRate == participants.map((e) => e.dailyCompletionRate).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.date_range_rounded,
            label: 'Weekly Tasks',
            values: participants.map((p) => _MetricValue(
              text: '${p.weeklyTasksCompleted}/${p.weeklyTasksTotal}',
              isUser: p.id == 'user',
              isHighest: p.weeklyCompletionRate == participants.map((e) => e.weeklyCompletionRate).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];

      case ComparisonCategory.goals:
        return [
          _MetricRow(
            icon: Icons.flag_rounded,
            label: 'Active Goals',
            values: participants.map((p) => _MetricValue(
              text: p.activeGoals.toString(),
              isUser: p.id == 'user',
              isHighest: p.activeGoals == participants.map((e) => e.activeGoals).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            values: participants.map((p) => _MetricValue(
              text: p.completedGoals.toString(),
              isUser: p.id == 'user',
              isHighest: p.completedGoals == participants.map((e) => e.completedGoals).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.trending_up_rounded,
            label: 'Progress',
            values: participants.map((p) => _MetricValue(
              text: '${p.goalsProgress.toStringAsFixed(0)}%',
              isUser: p.id == 'user',
              isHighest: p.goalsProgress == participants.map((e) => e.goalsProgress).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];

      case ComparisonCategory.buckets:
        return [
          _MetricRow(
            icon: Icons.inventory_2_rounded,
            label: 'Completed',
            values: participants.map((p) => _MetricValue(
              text: p.bucketsCompleted.toString(),
              isUser: p.id == 'user',
              isHighest: p.bucketsCompleted == participants.map((e) => e.bucketsCompleted).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.percent_rounded,
            label: 'Completion',
            values: participants.map((p) => _MetricValue(
              text: '${p.bucketCompletionRate.toStringAsFixed(0)}%',
              isUser: p.id == 'user',
              isHighest: p.bucketCompletionRate == participants.map((e) => e.bucketCompletionRate).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];

      case ComparisonCategory.diary:
        return [
          _MetricRow(
            icon: Icons.book_rounded,
            label: 'Entries',
            values: participants.map((p) => _MetricValue(
              text: p.diaryEntries.toString(),
              isUser: p.id == 'user',
              isHighest: p.diaryEntries == participants.map((e) => e.diaryEntries).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.mood_rounded,
            label: 'Mood',
            values: participants.map((p) => _MetricValue(
              text: p.moodAverage.toStringAsFixed(1),
              isUser: p.id == 'user',
              isHighest: p.moodAverage == participants.map((e) => e.moodAverage).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];

      case ComparisonCategory.streaks:
        return [
          _MetricRow(
            icon: Icons.local_fire_department_rounded,
            label: 'Current',
            values: participants.map((p) => _MetricValue(
              text: '${p.currentStreak}d',
              isUser: p.id == 'user',
              isHighest: p.currentStreak == participants.map((e) => e.currentStreak).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
          _MetricRow(
            icon: Icons.emoji_events_rounded,
            label: 'Longest',
            values: participants.map((p) => _MetricValue(
              text: '${p.longestStreak}d',
              isUser: p.id == 'user',
              isHighest: p.longestStreak == participants.map((e) => e.longestStreak).reduce((a, b) => a > b ? a : b),
            )).toList(),
          ),
        ];
    }
  }
}

class _MetricRow {
  final IconData icon;
  final String label;
  final List<_MetricValue> values;

  _MetricRow({
    required this.icon,
    required this.label,
    required this.values,
  });
}

class _MetricValue {
  final String text;
  final bool isUser;
  final bool isHighest;

  _MetricValue({
    required this.text,
    required this.isUser,
    required this.isHighest,
  });
}

// ================================================================
// HEAD TO HEAD CARD
// ================================================================
class HeadToHeadCard extends StatelessWidget {
  final CompetitorData user;
  final CompetitorData competitor;
  final VoidCallback onTap;

  const HeadToHeadCard({
    super.key,
    required this.user,
    required this.competitor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diff = user.totalScore - competitor.totalScore;
    final isAhead = diff >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1F1F2C), const Color(0xFF16161E)]
                : [Colors.white, const Color(0xFFF0F4FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VS ${competitor.name.split(' ').first}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAhead
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAhead ? 'WINNING' : 'TRAILING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAhead ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniScore(user.totalScore, true, isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMiniScore(competitor.totalScore, false, isDark),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAhead
                    ? 'You are ahead by ${ScoreHelper.format(diff)} pts'
                    : 'You need ${ScoreHelper.format(diff.abs())} pts to catch up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isAhead ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScore(int score, bool isUser, bool isDark) {
    return Column(
      children: [
        Text(
          isUser ? 'YOU' : 'THEM',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isUser
                ? const Color(0xFF8B5CF6)
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ScoreHelper.format(score),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isUser
                ? const Color(0xFF8B5CF6)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// STREAK WAR CARD
// ================================================================
class StreakWarCard extends StatelessWidget {
  final String name;
  final int current;
  final int longest;
  final bool isUser;

  const StreakWarCard({
    super.key,
    required this.name,
    required this.current,
    required this.longest,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFF8B5CF6).withOpacity(0.1)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(16),
        border: isUser ? Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.3),
        ) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            StreakHelper.getStreakEmoji(current),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            '$current Days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Best: $longest',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// REWARDS COMPARE ROW
// ================================================================
class RewardsCompareRow extends StatelessWidget {
  final RewardsData data;

  const RewardsCompareRow({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: data.isUser
            ? const Color(0xFFFBBF24).withOpacity(0.1)
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(12),
        border: data.isUser ? Border.all(
          color: const Color(0xFFFBBF24).withOpacity(0.3),
        ) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              data.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          _buildMedalCount('🥇', data.gold),
          const SizedBox(width: 12),
          _buildMedalCount('🥈', data.silver),
          const SizedBox(width: 12),
          _buildMedalCount('🥉', data.bronze),
        ],
      ),
    );
  }

  Widget _buildMedalCount(String emoji, int count) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
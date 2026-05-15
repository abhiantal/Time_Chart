// ================================================================
// FILE: lib/features/competition/widgets/screen_specific/overview_widgets.dart
// Widgets for Competition Overview Screen
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../widgets/bar_progress_indicator.dart';
import '../common/competition_helpers.dart';
import '../common/competition_models.dart';
import '../common/competition_shared_widgets.dart';

// ================================================================
// STATS SUMMARY CARD

// ================================================================
// STATS SUMMARY CARD
// ================================================================
class StatsSummaryCard extends StatelessWidget {
  final int totalPoints;
  final int totalRewards;
  final double completionRate;
  final int currentStreak;

  const StatsSummaryCard({
    super.key,
    required this.totalPoints,
    required this.totalRewards,
    required this.completionRate,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.star_rounded,
            value: ScoreHelper.format(totalPoints),
            label: 'Total Points',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.emoji_events_rounded,
            value: totalRewards.toString(),
            label: 'Rewards',
            color: const Color(0xFFFBBF24),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.percent_rounded,
            value: '${completionRate.toStringAsFixed(0)}%',
            label: 'Completed',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildStatItem(
            icon: Icons.local_fire_department_rounded,
            value: currentStreak.toString(),
            label: 'Streak',
            color: const Color(0xFFF97316),
            isDark: isDark,
            suffix: 'd',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    String suffix = '',
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (suffix.isNotEmpty)
              Text(
                suffix,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// COMPETITOR AVATAR STRIP
// ================================================================
class CompetitorAvatarStrip extends StatelessWidget {
  final List<CompetitorData> competitors;
  final String? selectedId;
  final Function(CompetitorData) onTap;
  final VoidCallback onAddTap;
  final int maxDisplay;

  const CompetitorAvatarStrip({
    super.key,
    required this.competitors,
    this.selectedId,
    required this.onTap,
    required this.onAddTap,
    this.maxDisplay = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = competitors.take(maxDisplay).toList();

    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayList.length + 1,
        itemBuilder: (context, index) {
          if (index == displayList.length) {
            return _AddCompetitorCard(onTap: onAddTap, isDark: isDark);
          }

          final competitor = displayList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CompetitorAvatarItem(
              competitor: competitor,
              isSelected: selectedId == competitor.id,
              onTap: () => onTap(competitor),
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _AddCompetitorCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddCompetitorCard({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitorAvatarItem extends StatelessWidget {
  final CompetitorData competitor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CompetitorAvatarItem({
    required this.competitor,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.1)
              : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                PulseAvatar(
                  imageUrl: competitor.avatarUrl,
                  name: competitor.name,
                  size: 40,
                  borderGradient: competitor.globalRank == 1
                      ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
                      : const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  showPulse: false,
                ),
                if (competitor.globalRank <= 3)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: RankBadge(rank: competitor.globalRank, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              competitor.name.length > 6
                  ? '${competitor.name.substring(0, 5)}...'
                  : competitor.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              ScoreHelper.format(competitor.totalScore),
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PROGRESS GRID CARD
// ================================================================
class ProgressGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double progress;
  final String value;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const ProgressGridCard({
    super.key,
    required this.title,
    required this.icon,
    required this.progress,
    required this.value,
    required this.subtitle,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradientColors.first.withOpacity(0.2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gradientColors.first.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: gradientColors.first, size: 16),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: gradientColors.first,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              CustomProgressIndicator(
                progress: progress / 100,
                width: double.infinity,
                baseHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.2),
                progressColor: gradientColors.first,
                borderRadius: 3,
                progressBarName: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ACTIVITY TIMELINE TILE
// ================================================================
class ActivityTimelineTile extends StatelessWidget {
  final ActivityEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityTimelineTile({
    super.key,
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? event.typeColor.withOpacity(0.1)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? event.typeColor
                : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: event.typeColor, width: 2),
              ),
              child: ClipOval(
                child: event.userAvatar != null
                    ? Image.network(event.userAvatar!, fit: BoxFit.cover)
                    : Container(
                        color: event.typeColor.withOpacity(0.2),
                        child: Center(
                          child: Text(
                            event.userName[0].toUpperCase(),
                            style: TextStyle(
                              color: event.typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
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
                          event.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (event.points > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+${event.points}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.userName} • ${event.timeAgo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Type icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: event.typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(event.typeIcon, color: event.typeColor, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

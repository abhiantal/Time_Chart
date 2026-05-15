// ================================================================
// COMMUNITY STATS WIDGET - Production Ready
// Displays community statistics (members, posts, activity)
// ================================================================

import 'package:flutter/material.dart';

class CommunityStatsWidget extends StatelessWidget {
  final int memberCount;
  final int postCount;
  final int onlineCount;
  final DateTime? createdAt;
  final double? averagePostsPerDay;

  const CommunityStatsWidget({
    super.key,
    required this.memberCount,
    required this.postCount,
    required this.onlineCount,
    this.createdAt,
    this.averagePostsPerDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Stats',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatItem(
                context,
                icon: Icons.people_rounded,
                value: '$memberCount',
                label: 'Members',
                color: colorScheme.primary,
              ),
              _buildStatItem(
                context,
                icon: Icons.post_add_rounded,
                value: '$postCount',
                label: 'Posts',
                color: colorScheme.secondary,
              ),
              _buildStatItem(
                context,
                icon: Icons.circle_rounded,
                value: '$onlineCount',
                label: 'Online',
                color: const Color(0xFF22C55E),
              ),
              if (createdAt != null)
                _buildStatItem(
                  context,
                  icon: Icons.calendar_today_rounded,
                  value: _formatDate(createdAt!),
                  label: 'Created',
                  color: colorScheme.tertiary,
                ),
              if (averagePostsPerDay != null)
                _buildStatItem(
                  context,
                  icon: Icons.trending_up_rounded,
                  value: averagePostsPerDay!.toStringAsFixed(1),
                  label: 'Posts/Day',
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else {
      return '${(diff.inDays / 365).floor()}y ago';
    }
  }
}

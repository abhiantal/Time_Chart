import 'package:flutter/material.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

class ReactionSummary extends StatelessWidget {
  final int totalCount;
  final Map<ReactionType, int>? breakdown;
  final ReactionType? userReaction;
  final List<String>? topReactorNames;
  final VoidCallback? onTap;
  final double size;

  const ReactionSummary({
    super.key,
    required this.totalCount,
    this.breakdown,
    this.userReaction,
    this.topReactorNames,
    this.onTap,
    this.size = 16,
  });

  factory ReactionSummary.fromReactionState(
    ReactionState state, {
    VoidCallback? onTap,
    List<String>? reactorNames,
  }) {
    final breakdown = <ReactionType, int>{};
    state.counts.forEach((typeName, count) {
      final type = ReactionType.tryFromString(typeName);
      if (type != null) {
        breakdown[type] = count;
      }
    });

    return ReactionSummary(
      totalCount: state.totalCount,
      breakdown: breakdown,
      userReaction: state.currentReaction,
      topReactorNames: reactorNames,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final topReactions = _getTopReactions(3);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked emojis
          if (topReactions.isNotEmpty)
            SizedBox(
              height: size * 1.2,
              width: size * 1.2 * topReactions.length * 0.7,
              child: Stack(
                clipBehavior: Clip.none,
                children: topReactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reaction = entry.value;
                  return Positioned(
                    left: index * size * 0.7,
                    child: Container(
                      padding: EdgeInsets.all(size * 0.2),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor, width: 1),
                      ),
                      child: Text(
                        reaction.emoji,
                        style: TextStyle(fontSize: size),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(width: 8),

          // Count
          Text(
            _formatCount(totalCount),
            style: theme.textScheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // User reaction indicator
          if (userReaction != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                userReaction!.emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],

          // Reactor names
          if (topReactorNames != null && topReactorNames!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatReactorNames(topReactorNames!, totalCount),
                style: theme.textScheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<ReactionType> _getTopReactions(int limit) {
    if (breakdown == null || breakdown!.isEmpty) return [];

    final sorted = breakdown!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final formatted = (count / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(count / 1000).floor()}K'
          : '${formatted}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String _formatReactorNames(List<String> names, int total) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0];
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    return '${names[0]}, ${names[1]} and ${total - 2} others';
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

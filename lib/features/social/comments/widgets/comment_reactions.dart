import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/reactions/providers/reaction_provider.dart';

class CommentReactions extends StatelessWidget {
  final String commentId;
  final int reactionCount;
  final bool hasReacted;
  final String? userReaction;
  final VoidCallback? onPress;

  const CommentReactions({
    super.key,
    required this.commentId,
    required this.reactionCount,
    required this.hasReacted,
    this.userReaction,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (onPress != null) {
          onPress!();
        } else {
          _toggleLike(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasReacted
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: hasReacted
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              userReaction != null
                  ? _getReactionIcon(userReaction!)
                  : Icons.favorite_border,
              size: 14,
              color: hasReacted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            if (reactionCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(reactionCount),
                style: theme.textScheme.labelSmall?.copyWith(
                  color: hasReacted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasReacted ? FontWeight.w600 : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleLike(BuildContext context) {
    context.read<ReactionProvider>().toggleCommentLike(commentId);
  }

  IconData _getReactionIcon(String reaction) {
    switch (reaction) {
      case 'like':
        return Icons.thumb_up;
      case 'love':
        return Icons.favorite;
      case 'celebrate':
        return Icons.celebration;
      case 'support':
        return Icons.handshake;
      case 'insightful':
        return Icons.lightbulb;
      case 'curious':
        return Icons.help;
      case 'haha':
        return Icons.emoji_emotions;
      case 'wow':
        return Icons.mood;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.favorite_border;
    }
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
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

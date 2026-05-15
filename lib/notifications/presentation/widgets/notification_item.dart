import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/notifications/presentation/models/notification_model.dart';
import 'package:the_time_chart/features/chats/widgets/common/user_avatar_cached.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final categoryColor = _getCategoryColor(notification.type);

    return Dismissible(
      key: Key('notif_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.error.withValues(alpha: 0.15),
              colorScheme.error.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dismiss',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Ultra Premium Glassmorphic / Sleek Dark Card styling
                color: isDark 
                    ? theme.cardColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: notification.isRead 
                    ? theme.dividerColor.withValues(alpha: 0.05)
                    : categoryColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: notification.isRead ? 0.01 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Left Accent Color Bar for Premium visual distinction
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Leading: Avatar or Premium Category Icon
                    _buildLeading(context),
                    const SizedBox(width: 16),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(notification.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.4,
                              fontSize: 13.5,
                            ),
                          ),
                          
                          // Recency Tag / Status indicators for interactive feel
                          if (DateTime.now().difference(notification.createdAt).inHours < 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: categoryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'NEW ACTIVITY',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: categoryColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final theme = Theme.of(context);
    
    if (notification.isInteraction || notification.isChat) {
      final avatarUrl = notification.senderAvatar;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        return Stack(
          children: [
            UserAvatarCached(
              imageUrl: avatarUrl,
              name: notification.senderName,
              size: 48,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _getCategoryColor(notification.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 1.5),
                ),
                child: Icon(
                  _getCategoryIcon(notification.type),
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      }
    }

    // Default Fallback Category Icon with soft glow effect
    final color = _getCategoryColor(notification.type);
    final icon = _getCategoryIcon(notification.type);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('chat') || t.contains('message') || t.contains('msg')) {
      return Icons.chat_bubble_outline_rounded;
    }
    if (t.contains('goal') || t.contains('milestone')) {
      return Icons.star_border_purple500_rounded;
    }
    if (t.contains('bucket')) {
      return Icons.shopping_bag_outlined;
    }
    if (t.contains('task') || t.contains('remind') || t.contains('overdue')) {
      return Icons.checklist_rtl_rounded;
    }
    if (t.contains('ai') || t.contains('gpt') || t.contains('token')) {
      return Icons.auto_awesome_outlined;
    }
    if (t.contains('like') || t.contains('love') || t.contains('react') || t.contains('social')) {
      return Icons.favorite_outline_rounded;
    }
    if (t.contains('comment') || t.contains('reply')) {
      return Icons.add_comment_outlined;
    }
    if (t.contains('follow')) {
      return Icons.person_add_alt_1_outlined;
    }
    if (t.contains('competition') || t.contains('rank') || t.contains('battle') || t.contains('leaderboard')) {
      return Icons.emoji_events_outlined;
    }
    if (t.contains('mentor') || t.contains('learn')) {
      return Icons.school_outlined;
    }
    if (t.contains('analytic') || t.contains('insight') || t.contains('weekly_progress') || t.contains('dashboard')) {
      return Icons.analytics_outlined;
    }
    if (t.contains('system') || t.contains('announcement') || t.contains('maintenance')) {
      return Icons.shield_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  Color _getCategoryColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('chat') || t.contains('message') || t.contains('msg')) {
      return const Color(0xFF00C6FF); // Sky Blue
    }
    if (t.contains('goal') || t.contains('milestone')) {
      return const Color(0xFFFF9900); // Amber Orange
    }
    if (t.contains('bucket')) {
      return const Color(0xFFFF5E36); // Coral Accent
    }
    if (t.contains('task') || t.contains('remind') || t.contains('overdue')) {
      return const Color(0xFF00E676); // Emerald Green
    }
    if (t.contains('ai') || t.contains('gpt') || t.contains('token')) {
      return const Color(0xFFD500F9); // Neon Purple
    }
    if (t.contains('like') || t.contains('love') || t.contains('react') || t.contains('social')) {
      return const Color(0xFFFF2D55); // Warm Pink
    }
    if (t.contains('comment') || t.contains('reply')) {
      return const Color(0xFF00BFA5); // Teal
    }
    if (t.contains('follow')) {
      return const Color(0xFFFF4081); // Bright Magenta
    }
    if (t.contains('competition') || t.contains('rank') || t.contains('battle') || t.contains('leaderboard')) {
      return const Color(0xFFFFD700); // Gold Yellow
    }
    if (t.contains('mentor') || t.contains('learn')) {
      return const Color(0xFF3F51B5); // Deep Indigo
    }
    if (t.contains('analytic') || t.contains('insight') || t.contains('weekly_progress') || t.contains('dashboard')) {
      return const Color(0xFF00E5FF); // Bright Cyan
    }
    if (t.contains('system') || t.contains('announcement') || t.contains('maintenance')) {
      return const Color(0xFF78909C); // Cool Grey
    }
    return const Color(0xFF607D8B); // Slate Blue
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(date);
  }
}

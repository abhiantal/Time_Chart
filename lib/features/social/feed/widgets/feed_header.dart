import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeedHeader extends StatelessWidget {
  final String currentUserId;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onMessagesTap;

  const FeedHeader({
    super.key,
    required this.currentUserId,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.onMessagesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Brand Logo & Title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                height: 24,
                width: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Time Chart',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Search button
        IconButton(
          icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
          onPressed: onSearchTap,
        ),

        // Notifications button
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: onNotificationsTap,
            ),
            // Notification badge (simplified - would come from provider)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Messages button
        IconButton(
          icon: Icon(Icons.send, color: theme.colorScheme.onSurface),
          onPressed: onMessagesTap,
        ),
      ],
    );
  }
}

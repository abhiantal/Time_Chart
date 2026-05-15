// ================================================================
// FILE: lib/features/chat/widgets/dialogs/mute_options_sheet.dart
// PURPOSE: Bottom sheet with mute duration options
// STYLE: WhatsApp-style mute options
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MuteDuration { oneHour, eightHours, oneDay, oneWeek, always, custom }

class MuteOptionsSheet extends StatelessWidget {
  final Function(MuteDuration, DateTime?) onMuteSelected;
  final bool isCurrentlyMuted;
  final VoidCallback? onUnmute;

  const MuteOptionsSheet({
    super.key,
    required this.onMuteSelected,
    this.isCurrentlyMuted = false,
    this.onUnmute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_off_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentlyMuted
                            ? 'Mute Notifications'
                            : 'Mute Notifications',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCurrentlyMuted
                            ? 'Choose mute duration or unmute'
                            : 'Choose how long to mute notifications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Mute options
          _MuteOptionTile(
            icon: Icons.hourglass_bottom_rounded,
            title: '1 hour',
            subtitle: 'Mute for 1 hour',
            duration: MuteDuration.oneHour,
            onTap: () {
              HapticFeedback.lightImpact();
              final muteUntil = DateTime.now().add(const Duration(hours: 1));
              Navigator.pop(context, MuteDuration.oneHour);
              onMuteSelected(MuteDuration.oneHour, muteUntil);
            },
          ),
          _MuteOptionTile(
            icon: Icons.hourglass_bottom_rounded,
            title: '8 hours',
            subtitle: 'Mute for 8 hours',
            duration: MuteDuration.eightHours,
            onTap: () {
              HapticFeedback.lightImpact();
              final muteUntil = DateTime.now().add(const Duration(hours: 8));
              Navigator.pop(context, MuteDuration.eightHours);
              onMuteSelected(MuteDuration.eightHours, muteUntil);
            },
          ),
          _MuteOptionTile(
            icon: Icons.today_rounded,
            title: '1 day',
            subtitle: 'Mute for 24 hours',
            duration: MuteDuration.oneDay,
            onTap: () {
              HapticFeedback.lightImpact();
              final muteUntil = DateTime.now().add(const Duration(days: 1));
              Navigator.pop(context, MuteDuration.oneDay);
              onMuteSelected(MuteDuration.oneDay, muteUntil);
            },
          ),
          _MuteOptionTile(
            icon: Icons.weekend_rounded,
            title: '1 week',
            subtitle: 'Mute for 7 days',
            duration: MuteDuration.oneWeek,
            onTap: () {
              HapticFeedback.lightImpact();
              final muteUntil = DateTime.now().add(const Duration(days: 7));
              Navigator.pop(context, MuteDuration.oneWeek);
              onMuteSelected(MuteDuration.oneWeek, muteUntil);
            },
          ),
          _MuteOptionTile(
            icon: Icons.all_inclusive,
            title: 'Always',
            subtitle: 'Mute until you unmute',
            duration: MuteDuration.always,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, MuteDuration.always);
              onMuteSelected(MuteDuration.always, null);
            },
          ),

          if (isCurrentlyMuted) ...[
            const Divider(height: 1),
            _MuteOptionTile(
              icon: Icons.notifications_active_rounded,
              title: 'Unmute',
              subtitle: 'Turn notifications back on',
              duration: null,
              isDestructive: false,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onUnmute?.call();
              },
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MuteOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MuteDuration? duration;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MuteOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.duration,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? colorScheme.error
                      : colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? colorScheme.error : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show mute options as bottom sheet
Future<MuteDuration?> showMuteOptionsSheet(
  BuildContext context, {
  bool isCurrentlyMuted = false,
  VoidCallback? onUnmute,
}) {
  return showModalBottomSheet<MuteDuration>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MuteOptionsSheet(
      onMuteSelected: (duration, muteUntil) {
        // Returned via RadioListTile or tapped - the widget already pops in its Internalタップ handlers
        // Wait, the _MuteOptionTile onTap calls Navigator.pop(context) which pops with null if not specified.
        // It needs to pop with the duration.
      },
      isCurrentlyMuted: isCurrentlyMuted,
      onUnmute: onUnmute,
    ),
  );
}

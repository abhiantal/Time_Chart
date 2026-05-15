import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/providers/chat_message_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class ReusableChatSettingsSection extends StatelessWidget {
  final bool showMute;
  final bool showPin;
  final bool showArchive;
  final bool showBlock;
  final bool isGroupOwner;

  const ReusableChatSettingsSection({
    super.key,
    this.showMute = true,
    this.showPin = true,
    this.showArchive = true,
    this.showBlock = false,
    this.isGroupOwner = false,
  });

  void _showErrorSnackBar(BuildContext context, String message) {
    AppSnackbar.error(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatMessageProvider>(
      builder: (context, provider, _) {
        final membership = provider.myMembership;
        if (membership == null) {
          return const SizedBox.shrink();
        }

        final isMuted = membership.isMuted;
        final isPinned = membership.isPinned;
        final isArchived = membership.isArchived;
        final isBlocked = membership.isBlocked;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMute || showPin || showArchive || showBlock) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],

            // Mute Switch
            if (showMute)
              _buildSwitchTile(
                context: context,
                title: 'Mute Notifications',
                icon: isMuted
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_active_rounded,
                iconColor: isMuted ? Colors.orange : Colors.blue,
                value: isMuted,
                isLoading: provider.isLoading, // Use provider's isLoading
                onChanged: (val) async {
                  try {
                    await provider.toggleMute(val);
                  } catch (e) {
                    if (context.mounted)
                      _showErrorSnackBar(context, e.toString());
                  }
                },
              ),

            // Pin Switch
            if (showPin)
              _buildSwitchTile(
                context: context,
                title: 'Pin Conversation',
                icon: Icons.push_pin_rounded,
                iconColor: isPinned ? Colors.red : Colors.grey,
                value: isPinned,
                isLoading: provider.isLoading,
                onChanged: (val) async {
                  try {
                    await provider.togglePin(val);
                  } catch (e) {
                    if (context.mounted)
                      _showErrorSnackBar(context, e.toString());
                  }
                },
              ),

            // Archive Switch
            if (showArchive && !isGroupOwner)
              _buildSwitchTile(
                context: context,
                title: 'Archive Chat',
                icon: Icons.archive_rounded,
                iconColor: isArchived ? Colors.brown : Colors.grey,
                value: isArchived,
                isLoading: provider.isLoading,
                onChanged: (val) async {
                  try {
                    await provider.toggleArchive(val);
                  } catch (e) {
                    if (context.mounted)
                      _showErrorSnackBar(context, e.toString());
                  }
                },
              ),

            // Block Switch (Personal Chat only)
            if (showBlock)
              _buildSwitchTile(
                context: context,
                title: 'Block User',
                subtitle: 'They won\'t be able to message you',
                icon: Icons.block_rounded,
                iconColor: isBlocked ? Colors.red : Colors.grey,
                value: isBlocked,
                isLoading: provider.isLoading,
                onChanged: (val) async {
                  try {
                    await provider.toggleBlock(val);
                  } catch (e) {
                    if (context.mounted)
                      _showErrorSnackBar(context, e.toString());
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required bool isLoading,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: isLoading ? null : () => onChanged(!value),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
    );
  }
}

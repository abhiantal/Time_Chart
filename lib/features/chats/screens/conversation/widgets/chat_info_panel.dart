import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_provider.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_models.dart';
import '../../../providers/chat_message_provider.dart';
import '../../../model/chat_model.dart';
import '../../../model/chat_member_model.dart';
import '../../../widgets/common/user_avatar_cached.dart';

class ChatInfoPanel extends StatelessWidget {
  final String chatId;

  const ChatInfoPanel({
    super.key,
    required this.chatId,
  });

  static Future<void> show(BuildContext context, String chatId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatInfoPanel(chatId: chatId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Consumer<ChatMessageProvider>(
          builder: (context, provider, _) {
            final chat = provider.activeChat;
            if (chat == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final members = provider.members;
            final myMembership = provider.myMembership;
            final isAdmin = myMembership?.role.isAdmin ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, chat, provider, members),
                Flexible(
                  child: _buildContent(context, chat, provider, isAdmin),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChatModel chat,
    ChatMessageProvider provider,
    List<ChatMemberModel> members,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          _headerIconBox(context, chat),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getSubLabel(chat, members, provider),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _getSubLabel(ChatModel chat, List<ChatMemberModel> members, ChatMessageProvider provider) {
    if (chat.isOneOnOne) {
       final otherUserId = chat.otherUserId ?? '';
       return otherUserId.isNotEmpty && provider.isUserOnline(otherUserId) ? 'Online' : 'Last seen recently';
    }
    final onlineCount = members.where((m) => provider.isUserOnline(m.userId)).length;
    return '${members.length} members • $onlineCount online';
  }

  Widget _headerIconBox(BuildContext context, ChatModel chat) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: UserAvatarCached(
          imageUrl: chat.isOneOnOne ? chat.otherUserAvatar : chat.avatar,
          name: chat.displayName,
          size: 38,
          isGroup: !chat.isOneOnOne,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ChatModel chat,
    ChatMessageProvider provider,
    bool isAdmin,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // --- Shared Content ---
        _menuItem(
          context,
          icon: Icons.perm_media_rounded,
          label: 'Shared Media',
          iconColor: Colors.blue,
          onTap: () => _navigateTo(context, 'chatMediaScreen'),
        ),
        _menuItem(
          context,
          icon: Icons.link_rounded,
          label: 'Shared Links',
          iconColor: Colors.teal,
          onTap: () => _navigateTo(context, 'chatLinksScreen'),
        ),
        _menuItem(
          context,
          icon: Icons.description_rounded,
          label: 'Documents',
          iconColor: Colors.orange,
          onTap: () => _navigateTo(context, 'chatDocumentsScreen'),
        ),
        _menuItem(
          context,
          icon: Icons.task_alt_rounded,
          label: 'Shared Tasks',
          iconColor: Colors.purple,
          onTap: () => _navigateTo(context, 'chatSharedDayTasksScreen'),
        ),

        const _MenuDivider(),

        // --- Members ---
        if (!chat.isOneOnOne) ...[
          _menuItem(
            context,
            icon: Icons.people_alt_rounded,
            label: 'Members',
            iconColor: Colors.indigo,
            onTap: () => _navigateTo(context, 'chatMembersScreen'),
          ),
          if (isAdmin)
             _menuItem(
              context,
              icon: Icons.person_add_rounded,
              label: 'Add Members',
              iconColor: Colors.green,
              onTap: () => _navigateTo(context, 'addMembersScreen'),
            ),
          _menuItem(
            context,
            icon: Icons.qr_code_2_rounded,
            label: 'QR Code',
            iconColor: Colors.purple,
            onTap: () => _navigateTo(context, 'qrCodeScreen'),
          ),
          const _MenuDivider(),
        ],

        // --- Search ---
        _menuItem(
          context,
          icon: Icons.search_rounded,
          label: 'Search in Chat',
          iconColor: colorScheme.primary,
          onTap: () => _navigateTo(context, 'inChatSearchScreen'),
        ),

        const _MenuDivider(),

        // --- Community Promotion ---
        if (chat.type == ChatType.community) ...[
          _promoteToggle(context),
          const _MenuDivider(),
        ],

        // --- Settings ---
        _menuItem(
          context,
          icon: Icons.notifications_active_rounded,
          label: 'Notifications',
          iconColor: Colors.deepOrange,
          onTap: () => _navigateTo(context, 'notificationSettingsScreen'),
        ),
        _menuItem(
          context,
          icon: Icons.palette_rounded,
          label: 'Chat Theme',
          iconColor: Colors.blue,
          onTap: () => _navigateTo(context, 'chatThemeScreen'),
        ),
        _menuItem(
          context,
          icon: Icons.wallpaper_rounded,
          label: 'Wallpaper',
          iconColor: Colors.cyan,
          onTap: () => _navigateTo(context, 'chatWallpaperScreen'),
        ),

        const _MenuDivider(),

        // --- Actions ---
        _menuItem(
          context,
          icon: Icons.delete_sweep_rounded,
          label: 'Clear History',
          iconColor: Colors.orange,
          onTap: () => _confirmAction(
            context,
            'Clear History?',
            'This will delete all messages for you.',
            'Clear',
            () => provider.clearChatHistory(),
          ),
        ),

        if (chat.isOneOnOne)
          _menuItem(
            context,
            icon: Icons.delete_forever_rounded,
            label: 'Delete Chat',
            iconColor: colorScheme.error,
            onTap: () => _confirmAction(
              context,
              'Delete Chat?',
              'This will permanently delete this conversation.',
              'Delete',
              () async {
                await provider.deleteChat();
                if (context.mounted) {
                   Navigator.pop(context);
                   context.goNamed('chatHubScreen');
                }
              },
            ),
          )
        else
          _menuItem(
            context,
            icon: Icons.exit_to_app_rounded,
            label: 'Leave Group',
            iconColor: colorScheme.error,
            onTap: () => _confirmAction(
              context,
              'Leave Group?',
              'You will no longer receive messages.',
              'Leave',
              () async {
                await provider.leaveGroup();
                if (context.mounted) {
                   Navigator.pop(context);
                   context.goNamed('chatHubScreen');
                }
              },
            ),
          ),
        
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  Widget _promoteToggle(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final myProfile = profileProvider.myProfile;
        final isPromoted = myProfile?.promotedCommunityId == chatId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.pink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promote Community',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Show this community on your profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isPromoted,
                activeColor: Colors.pink,
                onChanged: (value) async {
                  final success = await profileProvider.updateProfile(
                    ProfileUpdateDto(
                      promotedCommunityId: value ? chatId : '',
                    ),
                  );
                  if (success) {
                    snackbarService.showSuccess(
                      value ? 'Community promoted!' : 'Promotion removed',
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? () {
        Navigator.pop(context);
        onTap();
      } : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: enabled
                    ? iconColor.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled ? iconColor : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? theme.colorScheme.onSurface : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    context.pushNamed(routeName, pathParameters: {'chatId': chatId});
  }

  Future<void> _confirmAction(
    BuildContext context,
    String title,
    String message,
    String confirmLabel,
    Future<void> Function() onConfirm,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await onConfirm();
        if (context.mounted) {
           snackbarService.showSuccess('Action completed');
        }
      } catch (e) {
        if (context.mounted) snackbarService.showError('Failed: $e');
      }
    }
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 16,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

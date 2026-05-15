// ================================================================
// FILE: lib/features/chat/widgets/members/member_tile.dart
// PURPOSE: Single member row with avatar, name, role, actions
// STYLE: WhatsApp-style member tile
// DEPENDENCIES: user_avatar_cached.dart, member_role_badge.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';

import 'package:provider/provider.dart';
import '../../providers/chat_message_provider.dart';
import '../common/user_avatar_cached.dart';
import 'member_role_badge.dart';

class MemberTile extends StatelessWidget {
  final ChatMemberModel member;
  final bool isGroup;
  final bool isCommunity;
  final bool showRole;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MemberTile({
    super.key,
    required this.member,
    this.isGroup = true,
    this.isCommunity = false,
    this.showRole = true,
    this.showActions = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ChatMessageProvider>(
      builder: (context, provider, _) {
        final isMe = member.userId == provider.currentUserId;
        final isOnline = provider.isUserOnline(member.userId);
        final isAdmin = member.role.isAdmin;
        final isOwner = member.role.isOwner;

        return ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          leading: Stack(
            children: [
              UserAvatarCached(
                imageUrl: member.avatarUrl,
                name: _getDisplayName(),
                size: 48,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _getDisplayName(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                    color: isMe ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (isMe)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'You',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              if (showRole && (isAdmin || isOwner))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: MemberRoleBadge(role: member.role, compact: true),
                ),
              if (member.settings.customTitle != null) ...[
                if (showRole && (isAdmin || isOwner)) const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      member.settings.customTitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: showActions && !isMe
              ? PopupMenuButton<MemberAction>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (action) {
                    HapticFeedback.lightImpact();
                    _handleAction(context, action, provider);
                  },
                  itemBuilder: (context) => _buildActions(member, provider),
                )
              : null,
        );
      },
    );
  }

  String _getDisplayName() {
    if (member.settings.customTitle != null &&
        member.settings.customTitle!.isNotEmpty) {
      return member.settings.customTitle!;
    }
    if (member.fullName != null && member.fullName!.isNotEmpty) {
      return member.fullName!;
    }
    if (member.username != null && member.username!.isNotEmpty) {
      return member.username!;
    }
    return 'User ${member.userId.substring(0, 6)}';
  }

  List<PopupMenuEntry<MemberAction>> _buildActions(
    ChatMemberModel member,
    ChatMessageProvider provider,
  ) {
    final actions = <PopupMenuEntry<MemberAction>>[];

    if (provider.canPromote && !member.role.isAdmin) {
      actions.add(
        const PopupMenuItem(
          value: MemberAction.promote,
          child: Row(
            children: [
              Icon(Icons.star_rounded),
              SizedBox(width: 12),
              Text('Promote to Admin'),
            ],
          ),
        ),
      );
    }

    if (provider.canDemote && member.role.isAdmin && !member.role.isOwner) {
      actions.add(
        const PopupMenuItem(
          value: MemberAction.demote,
          child: Row(
            children: [
              Icon(Icons.star_border_rounded),
              SizedBox(width: 12),
              Text('Demote to Member'),
            ],
          ),
        ),
      );
    }

    if (provider.canRemove && !member.role.isOwner) {
      actions.add(
        const PopupMenuItem(
          value: MemberAction.remove,
          child: Row(
            children: [
              Icon(Icons.person_remove_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Remove', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (isCommunity) {
      actions.add(
        const PopupMenuItem(
          value: MemberAction.block,
          child: Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Block', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return actions;
  }

  void _handleAction(
    BuildContext context,
    MemberAction action,
    ChatMessageProvider provider,
  ) {
    switch (action) {
      case MemberAction.promote:
        _showConfirmDialog(
          context,
          'Promote to Admin',
          'Are you sure you want to promote this member to admin?',
          () => provider.promoteMember(member.userId),
        );
        break;
      case MemberAction.demote:
        _showConfirmDialog(
          context,
          'Demote to Member',
          'Are you sure you want to demote this admin to member?',
          () => provider.demoteMember(member.userId),
        );
        break;
      case MemberAction.remove:
        _showConfirmDialog(
          context,
          'Remove Member',
          'Are you sure you want to remove this member from the group?',
          () => provider.removeMember(member.userId),
        );
        break;
      case MemberAction.block:
        _showConfirmDialog(
          context,
          'Block User',
          'Are you sure you want to block this user?',
          () => provider.blockUser(member.userId),
        );
        break;
    }
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
              onConfirm();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

enum MemberAction { promote, demote, remove, block }

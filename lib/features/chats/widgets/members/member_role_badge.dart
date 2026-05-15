// ================================================================
// FILE: lib/features/chat/widgets/members/member_role_badge.dart
// PURPOSE: Badge showing member role (owner, admin, moderator)
// STYLE: Color-coded badge with icon
// DEPENDENCIES: chat_member_model.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/features/chats/model/chat_member_model.dart';

class MemberRoleBadge extends StatelessWidget {
  final ChatMemberRole role;
  final bool compact;
  final double size;

  const MemberRoleBadge({
    super.key,
    required this.role,
    this.compact = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (role == ChatMemberRole.member) return const SizedBox.shrink();

    final config = _getRoleConfig();

    if (compact) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(config.icon, size: size * 0.6, color: config.color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _RoleConfig _getRoleConfig() {
    switch (role) {
      case ChatMemberRole.owner:
        return _RoleConfig(
          label: 'Owner',
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B),
        );
      case ChatMemberRole.admin:
        return _RoleConfig(
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF3B82F6),
        );
      case ChatMemberRole.member:
        return _RoleConfig(
          label: 'Member',
          icon: Icons.person_rounded,
          color: const Color(0xFF6B7280),
        );
    }
  }
}

class _RoleConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Role badge with dropdown for role selection
class RoleSelectorBadge extends StatelessWidget {
  final ChatMemberRole currentRole;
  final bool canEdit;
  final Function(ChatMemberRole)? onRoleSelected;

  const RoleSelectorBadge({
    super.key,
    required this.currentRole,
    this.canEdit = false,
    this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!canEdit) {
      return MemberRoleBadge(role: currentRole, compact: true);
    }

    return PopupMenuButton<ChatMemberRole>(
      onSelected: onRoleSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MemberRoleBadge(role: currentRole, compact: true),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: ChatMemberRole.admin, child: Text('Admin')),
        const PopupMenuItem(
          value: ChatMemberRole.member,
          child: Text('Member'),
        ),
      ],
    );
  }
}

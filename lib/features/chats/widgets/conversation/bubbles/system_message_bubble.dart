// ================================================================
// FILE: lib/features/chat/widgets/conversation/bubbles/system_message_bubble.dart
// PURPOSE: System event message bubble (join, leave, create, etc.)
// STYLE: WhatsApp system message style
// DEPENDENCIES: message_bubble_base.dart
// ================================================================

import 'package:flutter/material.dart';

import 'package:the_time_chart/features/chats/model/chat_model.dart';
import '../../../model/chat_message_model.dart';

class SystemMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const SystemMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(colorScheme),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getSystemMessageText(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color color;

    switch (message.systemEventType) {
      case SystemEventType.chatCreated:
        iconData = Icons.chat_rounded;
        color = Colors.green;
        break;
      case SystemEventType.memberJoined:
      case SystemEventType.memberAdded:
        iconData = Icons.person_add_rounded;
        color = Colors.blue;
        break;
      case SystemEventType.memberLeft:
      case SystemEventType.memberRemoved:
        iconData = Icons.person_remove_rounded;
        color = Colors.orange;
        break;
      case SystemEventType.memberPromoted:
        iconData = Icons.star_rounded;
        color = Colors.amber;
        break;
      case SystemEventType.memberDemoted:
        iconData = Icons.star_border_rounded;
        color = Colors.grey;
        break;
      case SystemEventType.nameChanged:
        iconData = Icons.edit_rounded;
        color = Colors.purple;
        break;
      case SystemEventType.avatarChanged:
        iconData = Icons.photo_camera_rounded;
        color = Colors.teal;
        break;
      case SystemEventType.disappearingEnabled:
      case SystemEventType.disappearingDisabled:
        iconData = Icons.timer_rounded;
        color = Colors.indigo;
        break;
      default:
        iconData = Icons.info_outline_rounded;
        color = colorScheme.onSurfaceVariant;
    }

    return Icon(iconData, size: 16, color: color);
  }

  String _getSystemMessageText() {
    final data = message.systemEventData ?? {};

    switch (message.systemEventType) {
      case SystemEventType.chatCreated:
        return 'Chat created';

      case SystemEventType.memberJoined:
        return 'joined the chat';

      case SystemEventType.memberLeft:
        return 'left the chat';

      case SystemEventType.memberAdded:
        final addedBy = data['added_by'] != null
            ? ' by ${_formatUserId(data['added_by'])}'
            : '';
        return '${_formatUserId(data['user_id'])} was added$addedBy';

      case SystemEventType.memberRemoved:
        final removedBy = data['removed_by'] != null
            ? ' by ${_formatUserId(data['removed_by'])}'
            : '';
        return '${_formatUserId(data['user_id'])} was removed$removedBy';

      case SystemEventType.memberPromoted:
        final promotedBy = data['promoted_by'] != null
            ? ' by ${_formatUserId(data['promoted_by'])}'
            : '';
        final role = data['new_role'] == 'owner' ? 'owner' : 'admin';
        return '${_formatUserId(data['user_id'])} was promoted to $role$promotedBy';

      case SystemEventType.memberDemoted:
        final demotedBy = data['demoted_by'] != null
            ? ' by ${_formatUserId(data['demoted_by'])}'
            : '';
        return '${_formatUserId(data['user_id'])} was demoted to member$demotedBy';

      case SystemEventType.nameChanged:
        final oldName = data['old_name'] ?? 'Unnamed';
        final newName = data['new_name'] ?? 'Unnamed';
        return 'Group name changed from "$oldName" to "$newName"';

      case SystemEventType.avatarChanged:
        return 'Group avatar changed';

      case SystemEventType.disappearingEnabled:
        final duration = data['duration'] != null
            ? _formatDuration(data['duration'])
            : '24 hours';
        return 'Disappearing messages enabled ($duration)';

      case SystemEventType.disappearingDisabled:
        return 'Disappearing messages disabled';

      default:
        return 'System message';
    }
  }

  String _formatUserId(dynamic userId) {
    if (userId == null) return 'Someone';
    // TODO: Get user name from provider
    return 'User';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${seconds ~/ 60} minutes';
    if (seconds < 86400) return '${seconds ~/ 3600} hours';
    return '${seconds ~/ 86400} days';
  }
}

// ================================================================
// FILE: lib/features/chats/widgets/conversation/components/message_actions_sheet.dart
// PURPOSE: Premium bottom sheet for chat message actions (Forward, Delete, Edit, etc.)
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../model/chat_message_model.dart';
import '../../../providers/chat_message_provider.dart';
import '../../shared_content/chat_picker_sheet.dart';
import '../../../../../widgets/app_snackbar.dart';

class MessageActionsSheet extends StatelessWidget {
  final ChatMessageModel message;

  const MessageActionsSheet({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.read<ChatMessageProvider>();
    final isMe = message.isMine;

    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Message Preview (Optional, keep it small)
          if (message.textContent != null && message.textContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message.textContent!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Actions List
          if (!message.isDeleted) ...[
            _buildActionItem(
              context,
              icon: Icons.reply_rounded,
              title: 'Reply',
              onTap: () {
                provider.setReply(message);
                Navigator.pop(context);
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.copy_rounded,
              title: 'Copy',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.textContent ?? ''));
                Navigator.pop(context);
                // TODO: Show toast
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.forward_rounded,
              title: 'Forward',
              onTap: () async {
                final chatIds = await showChatPicker(context, title: 'Forward to...', multiSelect: true);
                if (chatIds != null && chatIds.isNotEmpty) {
                  for (var chatId in chatIds) {
                    await provider.forwardMessage(
                      messageId: message.id,
                      toChatId: chatId,
                    );
                  }
                  if (context.mounted) {
                    AppSnackbar.success('Forwarded successfully', description: 'Forwarded to ${chatIds.length} chats');
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            if (isMe)
              _buildActionItem(
                context,
                icon: Icons.edit_rounded,
                title: 'Edit',
                onTap: () {
                  provider.setEdit(message);
                  Navigator.pop(context);
                },
              ),
            _buildActionItem(
              context,
              icon: message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              title: message.isPinned ? 'Unpin' : 'Pin',
              onTap: () {
                provider.togglePinMessage(message.id, !message.isPinned);
                Navigator.pop(context);
              },
            ),
          ],

          const Divider(indent: 24, endIndent: 24, height: 24),

          _buildActionItem(
            context,
            icon: Icons.delete_sweep_rounded,
            title: 'Delete for Me',
            color: colorScheme.error,
            onTap: () async {
              final confirmed = await _showDeleteConfirm(context, 'Delete for Me', 'This message will be hidden from your chat history.');
              if (confirmed == true) {
                provider.deleteMessageForMe(message.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),

          if (isMe && !message.isDeleted)
            _buildActionItem(
              context,
              icon: Icons.delete_forever_rounded,
              title: 'Delete for Everyone',
              color: colorScheme.error,
              onTap: () async {
                final confirmed = await _showDeleteConfirm(context, 'Delete for Everyone', 'This message will be deleted for ALL participants.');
                if (confirmed == true) {
                  provider.deleteMessageForEveryone(message.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: color ?? theme.colorScheme.onSurface),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color ?? theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
    );
  }

  static void show(BuildContext context, ChatMessageModel message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MessageActionsSheet(message: message),
    );
  }
}

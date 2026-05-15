import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_provider.dart';
import 'chat_list_tile.dart';

class GroupChatsList extends StatelessWidget {
  final VoidCallback? onChatTap;
  final bool isMultiSelectMode;
  final Set<String> selectedChatIds;
  final Function(String) onSelectionToggle;

  const GroupChatsList({
    super.key,
    this.onChatTap,
    this.isMultiSelectMode = false,
    required this.selectedChatIds,
    required this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final groupChats = chatProvider.chats
            .where((c) => c.isGroup && !c.isCommunity && !c.isArchived)
            .toList();

        if (groupChats.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: groupChats.length,
          itemBuilder: (context, index) {
            final chat = groupChats[index];
            final isTyping = chatProvider.isTypingInChat(chat.id);
            final typingUsers = isTyping ? ['Someone'] : <String>[];

            return ChatListTile(
              item: chat,
              isTyping: isTyping,
              typingUsers: typingUsers,
              onTap: () {
                onChatTap?.call();
                context.pushNamed(
                  'groupChatScreen',
                  pathParameters: {'chatId': chat.id},
                );
              },
              onArchive: () => chatProvider.toggleArchive(chat.id, true),
              onDelete: () => chatProvider.deleteChat(chat.id),
              onPin: () => chatProvider.togglePin(chat.id, !chat.isPinned),
              onMute: () => chatProvider.toggleMute(chat.id, !chat.isMuted),
              onMarkRead: () => chatProvider.markChatAsRead(chat.id),
              isSelected: selectedChatIds.contains(chat.id),
              isMultiSelectMode: isMultiSelectMode,
              onSelectionToggle: () => onSelectionToggle(chat.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [colorScheme.secondaryContainer, colorScheme.secondaryContainer.withValues(alpha: 0.3)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.group_outlined, size: 48, color: colorScheme.secondary)),
          ),
          const SizedBox(height: 24),
          Text('No groups yet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text('Create a group to chat with multiple people at once', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.pushNamed('createGroupScreen'),
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Create Group'),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary),
          ),
        ],
      ),
    );
  }
}

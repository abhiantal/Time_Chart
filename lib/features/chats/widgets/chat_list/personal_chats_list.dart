import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import '../../providers/chat_provider.dart';
import 'chat_list_tile.dart' as ui;

class PersonalChatsList extends StatelessWidget {
  final VoidCallback? onChatTap;
  final bool isMultiSelectMode;
  final Set<String> selectedChatIds;
  final Function(String) onSelectionToggle;

  const PersonalChatsList({
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
        final personalChats = chatProvider.chats
            .where((c) => c.isOneOnOne && !c.isArchived)
            .toList();

        final pinnedChats = personalChats.where((c) => c.isPinned).toList();
        final unpinnedChats = personalChats.where((c) => !c.isPinned).toList();

        if (personalChats.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _getItemCount(personalChats, pinnedChats, unpinnedChats),
          itemBuilder: (context, index) {
            if (index == 0 && pinnedChats.isNotEmpty) {
              return const PinnedChatSeparator();
            }

            if (index > 0 && index <= pinnedChats.length) {
              final chat = pinnedChats[index - 1];
              return _buildChatTile(context, chat, chatProvider);
            }

            if (index == pinnedChats.length + 1 && pinnedChats.isNotEmpty) {
              return const ChatListDivider();
            }

            int unpinnedIndex = pinnedChats.isNotEmpty ? index - pinnedChats.length - 2 : index;

            if (unpinnedIndex >= 0 && unpinnedIndex < unpinnedChats.length) {
              final chat = unpinnedChats[unpinnedIndex];
              return _buildChatTile(context, chat, chatProvider);
            }

            return const SizedBox();
          },
        );
      },
    );
  }

  int _getItemCount(
    List<ChatModel> allChats,
    List<ChatModel> pinnedChats,
    List<ChatModel> unpinnedChats,
  ) {
    int count = allChats.length;
    if (pinnedChats.isNotEmpty) count += 2;
    return count;
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatModel chat,
    ChatProvider chatProvider,
  ) {
    final isOnline = chat.otherUserId != null && chatProvider.isUserOnline(chat.otherUserId!);
    final isTyping = chatProvider.isTypingInChat(chat.id);
    final typingUsers = isTyping ? [chat.displayName] : <String>[];

    return ui.ChatListTile(
      item: chat,
      isOnline: isOnline,
      isTyping: isTyping,
      typingUsers: typingUsers,
      onTap: () {
        onChatTap?.call();
        context.pushNamed(
          'personalChatScreen',
          pathParameters: {'chatId': chat.id},
        );
      },
      onArchive: () => chatProvider.archiveChat(chat.id, true),
      onDelete: () => chatProvider.deleteChat(chat.id),
      onPin: () => chatProvider.pinChat(chat.id, !chat.isPinned),
      onMute: () => _showMuteOptions(context, chat, chatProvider),
      onMarkRead: () => chatProvider.markChatAsRead(chat.id),
      isSelected: selectedChatIds.contains(chat.id),
      isMultiSelectMode: isMultiSelectMode,
      onSelectionToggle: () => onSelectionToggle(chat.id),
    );
  }

  void _showMuteOptions(BuildContext context, ChatModel chat, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.hourglass_bottom_rounded),
              title: const Text('1 hour'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, true, muteDuration: const Duration(hours: 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom_rounded),
              title: const Text('8 hours'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, true, muteDuration: const Duration(hours: 8));
              },
            ),
            ListTile(
              leading: const Icon(Icons.today_rounded),
              title: const Text('1 day'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, true, muteDuration: const Duration(days: 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend_rounded),
              title: const Text('1 week'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, true, muteDuration: const Duration(days: 7));
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text('Always'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_active_rounded, color: Colors.red),
              title: const Text('Unmute'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleMute(chat.id, false);
              },
            ),
          ],
        ),
      ),
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
              gradient: RadialGradient(colors: [colorScheme.primaryContainer, colorScheme.primaryContainer.withValues(alpha: 0.3)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: colorScheme.primary)),
          ),
          const SizedBox(height: 24),
          Text('No conversations yet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text('Start a chat with friends or join a group to begin messaging', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.pushNamed('searchUsersScreen'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }
}

class PinnedChatSeparator extends StatelessWidget {
  const PinnedChatSeparator({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(Icons.push_pin_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text('Pinned', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class ChatListDivider extends StatelessWidget {
  const ChatListDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Recent chats', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(child: Container(margin: const EdgeInsets.only(left: 12), height: 1, color: colorScheme.outline.withValues(alpha: 0.1))),
        ],
      ),
    );
  }
}

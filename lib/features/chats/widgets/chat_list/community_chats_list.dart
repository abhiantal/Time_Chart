import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_provider.dart';
import 'chat_list_tile.dart';

class CommunityChatsList extends StatelessWidget {
  final VoidCallback? onChatTap;
  final bool isMultiSelectMode;
  final Set<String> selectedChatIds;
  final Function(String) onSelectionToggle;

  const CommunityChatsList({
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
        final communities = chatProvider.chats
            .where((c) => c.isCommunity && !c.isArchived)
            .toList();

        if (communities.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            final isTyping = chatProvider.isTypingInChat(community.id);

            return ChatListTile(
              item: community,
              isTyping: isTyping,
              onTap: () {
                onChatTap?.call();
                context.pushNamed(
                  'communityChatScreen',
                  pathParameters: {'chatId': community.id},
                );
              },
              onArchive: () => chatProvider.toggleArchive(community.id, true),
              onDelete: () => chatProvider.deleteChat(community.id),
              onPin: () => chatProvider.togglePin(community.id, !community.isPinned),
              onMute: () => chatProvider.toggleMute(community.id, !community.isMuted),
              onMarkRead: () => chatProvider.markChatAsRead(community.id),
              isSelected: selectedChatIds.contains(community.id),
              isMultiSelectMode: isMultiSelectMode,
              onSelectionToggle: () => onSelectionToggle(community.id),
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
              gradient: RadialGradient(colors: [colorScheme.tertiaryContainer, colorScheme.tertiaryContainer.withValues(alpha: 0.3)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.tertiary)),
          ),
          const SizedBox(height: 24),
          Text('No communities yet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text('Join public communities or create your own', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pushNamed('discoverCommunitiesScreen'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Discover'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => context.pushNamed('createCommunityScreen'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create'),
                style: FilledButton.styleFrom(backgroundColor: colorScheme.tertiary, foregroundColor: colorScheme.onTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:the_time_chart/features/chats/model/chat_model.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/logger.dart';
import '../../providers/chat_provider.dart';
// ChatRealtimeProvider removed
import '../../widgets/chat_list/chat_list_tile.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';

enum ChatListFilterType { personal, groups, communities }

class ChatListFilterScreen extends StatefulWidget {
  final ChatListFilterType filterType;

  const ChatListFilterScreen({
    super.key,
    required this.filterType,
  });

  @override
  State<ChatListFilterScreen> createState() => _ChatListFilterScreenState();
}

class _ChatListFilterScreenState extends State<ChatListFilterScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // --- Helpers ---
  String _safeName(ChatModel chat) {
    if (chat.displayName.trim().isNotEmpty) return chat.displayName;
    return switch (widget.filterType) {
      ChatListFilterType.personal => 'Chat',
      ChatListFilterType.groups => 'Group',
      ChatListFilterType.communities => 'Community',
    };
  }

  Color _getThemeColor(ColorScheme colorScheme) {
    return switch (widget.filterType) {
      ChatListFilterType.personal => colorScheme.primary,
      ChatListFilterType.groups => colorScheme.secondary,
      ChatListFilterType.communities => colorScheme.tertiary,
    };
  }

  // --- Actions ---
  Future<void> _handleRefresh(ChatProvider provider) async {
    HapticFeedback.mediumImpact();
    try {
      await provider.refresh();
    } catch (e) {
      logE('ChatListFilterScreen refresh error: $e');
      snackbarService.showError('Failed to refresh');
    }
  }

  Future<void> _archiveChat(ChatModel chat, ChatProvider provider) async {
    HapticFeedback.mediumImpact();
    try {
      await provider.toggleArchive(chat.id, true);
      if (mounted) {
        AppSnackbar.success('${_safeName(chat)} archived');
      }
    } catch (e) {
      logE('Archive error: $e');
      snackbarService.showError('Failed to archive');
    }
  }

  Future<void> _deleteOrLeave(ChatModel chat, ChatProvider provider) async {
    final actionLabel = widget.filterType == ChatListFilterType.personal ? 'Delete' : 'Leave';
    final confirmed = await _showConfirmDialog(
      title: '$actionLabel "${_safeName(chat)}"?',
      content: widget.filterType == ChatListFilterType.personal
          ? 'This chat will be permanently deleted.'
          : 'You will no longer receive updates from this ${widget.filterType == ChatListFilterType.groups ? 'group' : 'community'}.',
      confirmLabel: actionLabel,
    );

    if (!confirmed || !mounted) return;

    HapticFeedback.heavyImpact();
    try {
      await provider.deleteChat(chat.id);
      snackbarService.showInfo('$actionLabel success: ${_safeName(chat)}');
    } catch (e) {
      logE('Delete/Leave error: $e');
      snackbarService.showError('Action failed');
    }
  }

  void _showMuteOptions(ChatModel chat, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MuteSheet(
        chatName: _safeName(chat),
        onMute: (duration) async {
          try {
            await provider.toggleMute(
              chat.id,
              true,
              muteDuration: duration,
            );
            snackbarService.showInfo('Muted ${_safeName(chat)}');
          } catch (e) {
            logE('Mute error: $e');
            snackbarService.showError('Failed to mute');
          }
        },
        onUnmute: () async {
          try {
            await provider.toggleMute(chat.id, false);
            snackbarService.showInfo('Unmuted ${_safeName(chat)}');
          } catch (e) {
            logE('Unmute error: $e');
          }
        },
      ),
    );
  }

  void _showOptions(ChatModel chat, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatOptionsSheet(
        chat: chat,
        deleteLabel: widget.filterType == ChatListFilterType.personal ? 'Delete' : 'Leave',
        onPin: () => provider.togglePin(chat.id, !chat.isPinned),
        onMute: () => _showMuteOptions(chat, provider),
        onArchive: () => _archiveChat(chat, provider),
        onDelete: () => _deleteOrLeave(chat, provider),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: Text(confirmLabel),
              ),
            ],
          ),
        )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getThemeColor(colorScheme);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        List<ChatModel> filteredItems = [];
        try {
          filteredItems = chatProvider.chats.where((c) {
            return switch (widget.filterType) {
              ChatListFilterType.personal => c.isOneOnOne,
              ChatListFilterType.groups => c.isGroup && !c.isCommunity,
              ChatListFilterType.communities => c.isCommunity,
            };
          }).toList();
        } catch (e) {
          logE('Data filter error: $e');
          return _buildErrorState(chatProvider);
        }

        if (chatProvider.isLoading && filteredItems.isEmpty) {
          return const LoadingShimmerList();
        }

        if (filteredItems.isEmpty) return _buildEmptyState(context);

        // Sorting / Grouping logic (Pinned vs Recent)
        final pinned = filteredItems.where((c) => c.isPinned).toList();
        final recent = filteredItems.where((c) => !c.isPinned).toList();
        final listItems = <dynamic>[];
        
        if (pinned.isNotEmpty) {
          listItems.add({'type': 'header', 'icon': Icons.push_pin_rounded, 'label': 'Pinned'});
          listItems.addAll(pinned);
          if (recent.isNotEmpty) {
            listItems.add({'type': 'header', 'icon': Icons.history_rounded, 'label': 'Recent'});
            listItems.addAll(recent);
          }
        } else {
          listItems.addAll(recent);
        }

        return RefreshIndicator(
          onRefresh: () => _handleRefresh(chatProvider),
          color: color,
          backgroundColor: colorScheme.surface,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              final item = listItems[index];
              if (item is Map) {
                return _SectionHeader(icon: item['icon'], label: item['label'], color: color);
              }
              final chat = item as ChatModel;
              return _buildTile(context, chat, chatProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return switch (widget.filterType) {
      ChatListFilterType.personal => EmptyStateIllustration(
          type: EmptyStateType.noChats,
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No conversations yet',
          description: 'Start a new chat to connect with friends',
          actionLabel: 'Start New Chat',
          onAction: () => context.pushNamed('newChatScreen'),
        ),
      ChatListFilterType.groups => EmptyStateIllustration(
          type: EmptyStateType.custom,
          icon: Icons.group_outlined,
          title: 'No Groups Yet',
          description: 'Create a group to chat with multiple people at once',
          actionLabel: 'Create Group',
          onAction: () => context.pushNamed('createGroupScreen'),
        ),
      ChatListFilterType.communities => EmptyStateIllustration(
          type: EmptyStateType.custom,
          icon: Icons.people_outline_rounded,
          title: 'No Communities Yet',
          description: 'Discover or create communities to connect with like-minded people',
          actionLabel: 'Discover',
          onAction: () => context.pushNamed('discoverCommunitiesScreen'),
          secondaryActionLabel: 'Create',
          onSecondaryAction: () => context.pushNamed('createCommunityScreen'),
        ),
    };
  }

  Widget _buildErrorState(ChatProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange.shade400),
          const SizedBox(height: 16),
          const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () => _handleRefresh(provider), icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, ChatModel chat, ChatProvider chatProvider) {
    final isTyping = chatProvider.isTypingInChat(chat.id);
    final isDraft = chatProvider.hasDraft(chat.id);
    return ChatListTile(
      item: isDraft 
        ? chat.copyWith(previewOverride: chatProvider.getDraft(chat.id))
        : chat,
      isOnline: chat.otherUserId != null && chatProvider.isUserOnline(chat.otherUserId!),
      isTyping: isTyping,
      isDraft: isDraft,
      typingUsers: chatProvider.getTypingUsers(chat.id),
      onTap: () => context.pushNamed(
        widget.filterType == ChatListFilterType.communities ? 'communityChatScreen' : (widget.filterType == ChatListFilterType.groups ? 'groupChatScreen' : 'chatRoomScreen'),
        pathParameters: {'chatId': chat.id},
      ),
      onLongPress: () => _showOptions(chat, chatProvider),
      onArchive: () => _archiveChat(chat, chatProvider),
      onDelete: () => _deleteOrLeave(chat, chatProvider),
      onPin: () => chatProvider.togglePin(chat.id, !chat.isPinned),
      onMute: () => _showMuteOptions(chat, chatProvider),
      onMarkRead: () => chatProvider.markChatAsRead(chat.id),
    );
  }
}

// --- Internal Widgets ---

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _MuteSheet extends StatelessWidget {
  final String chatName;
  final void Function(Duration? duration) onMute;
  final VoidCallback onUnmute;
  const _MuteSheet({required this.chatName, required this.onMute, required this.onUnmute});

  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.hourglass_top_rounded, '1 hour', const Duration(hours: 1)),
      (Icons.hourglass_bottom_rounded, '8 hours', const Duration(hours: 8)),
      (Icons.today_rounded, '1 day', const Duration(days: 1)),
      (Icons.date_range_rounded, '1 week', const Duration(days: 7)),
      (Icons.all_inclusive_rounded, 'Always', null),
    ];

    return _BottomSheet(
      title: 'Mute Notifications',
      children: [
        ...options.map((o) => _SheetTile(icon: o.$1, label: o.$2, onTap: () { Navigator.pop(context); onMute(o.$3); })),
        const Divider(height: 1),
        _SheetTile(icon: Icons.notifications_active_rounded, label: 'Unmute', iconColor: Colors.green, onTap: () { Navigator.pop(context); onUnmute(); }),
      ],
    );
  }
}

class _ChatOptionsSheet extends StatelessWidget {
  final ChatModel chat;
  final String deleteLabel;
  final VoidCallback onPin;
  final VoidCallback onMute;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  const _ChatOptionsSheet({required this.chat, required this.deleteLabel, required this.onPin, required this.onMute, required this.onArchive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _BottomSheet(
      title: chat.displayName,
      children: [
        _SheetTile(icon: chat.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, label: chat.isPinned ? 'Unpin' : 'Pin', iconColor: chat.isPinned ? Colors.amber : null, onTap: () { Navigator.pop(context); onPin(); }),
        _SheetTile(icon: Icons.notifications_off_rounded, label: 'Mute Notifications', onTap: () { Navigator.pop(context); onMute(); }),
        _SheetTile(icon: Icons.archive_rounded, label: 'Archive', onTap: () { Navigator.pop(context); onArchive(); }),
        _SheetTile(icon: Icons.delete_outline_rounded, label: deleteLabel, iconColor: colorScheme.error, labelColor: colorScheme.error, onTap: () { Navigator.pop(context); onDelete(); }),
      ],
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _BottomSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          ...children,
          SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  const _SheetTile({required this.icon, required this.label, required this.onTap, this.iconColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}

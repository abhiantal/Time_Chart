import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_list/chat_list_tile.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});
  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedChatIds = {};

  void _toggleMultiSelectMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedChatIds.clear();
    });
  }

  void _toggleChatSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
        if (_selectedChatIds.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(_isMultiSelectMode ? '${_selectedChatIds.length} selected' : 'Archived Chats'),
      ),
      body: Consumer<ChatProvider>(builder: (context, provider, _) {
        if (provider.isLoading && provider.archivedChats.isEmpty) return const LoadingShimmerList();
        if (provider.archivedChats.isEmpty) return EmptyStateIllustration(type: EmptyStateType.custom, icon: Icons.archive_outlined, title: 'No archived chats', description: 'Chats you archive will appear here');
        return ListView.builder(itemCount: provider.archivedChats.length, itemBuilder: (context, index) {
          final chat = provider.archivedChats[index];
          return ChatListTile(
            item: chat,
            isSelected: _selectedChatIds.contains(chat.id),
            isMultiSelectMode: _isMultiSelectMode,
            onTap: () {
              if (_isMultiSelectMode) {
                _toggleChatSelection(chat.id);
              } else {
                context.pushNamed(chat.isGroup ? 'groupChatScreen' : 'personalChatScreen', pathParameters: {'chatId': chat.id});
              }
            },
            onLongPress: _toggleMultiSelectMode,
            onArchive: () => provider.toggleArchive(chat.id, false),
            onDelete: () => provider.deleteChat(chat.id),
          );
        });
      }),
    );
  }
}

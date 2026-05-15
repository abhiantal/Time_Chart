import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';

class ChatPickerSheet extends StatefulWidget {
  final String title;
  final bool multiSelect;
  final String? messageToForward;

  const ChatPickerSheet({
    super.key,
    this.title = 'Send to...',
    this.multiSelect = false,
    this.messageToForward,
  });

  @override
  State<ChatPickerSheet> createState() => _ChatPickerSheetState();
}

class _ChatPickerSheetState extends State<ChatPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedChatIds = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ChatProvider>();
    final chats = provider.chats.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.multiSelect && _selectedChatIds.isNotEmpty)
                  Text(
                    '${_selectedChatIds.length} selected',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // List
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No chats found'
                              : 'No results for "$_searchQuery"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final isSelected = _selectedChatIds.contains(chat.id);

                      return ListTile(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (widget.multiSelect) {
                            setState(() {
                              if (isSelected) {
                                _selectedChatIds.remove(chat.id);
                              } else {
                                _selectedChatIds.add(chat.id);
                              }
                            });
                          } else {
                            Navigator.pop(context, [chat.id]);
                          }
                        },
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: chat.avatar != null
                              ? NetworkImage(chat.avatar!)
                              : null,
                          child: chat.avatar == null
                              ? Text(
                                  chat.displayName.isNotEmpty
                                      ? chat.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          chat.displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          chat.type == ChatType.oneOnOne ? 'Personal' : 'Group',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: widget.multiSelect
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (val == true) {
                                      _selectedChatIds.add(chat.id);
                                    } else {
                                      _selectedChatIds.remove(chat.id);
                                    }
                                  });
                                },
                                shape: const CircleBorder(),
                              )
                            : null,
                      );
                    },
                  ),
          ),

          // Action Button (Multi-select)
          if (widget.multiSelect)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: _selectedChatIds.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selectedChatIds.toList()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Send to ${_selectedChatIds.length} chats'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper to show the chat picker
Future<List<String>?> showChatPicker(
  BuildContext context, {
  String title = 'Send to...',
  bool multiSelect = false,
  String? messageToForward,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ChatPickerSheet(
      title: title,
      multiSelect: multiSelect,
      messageToForward: messageToForward,
    ),
  );
}

// ================================================================
// FILE: lib/features/chat/widgets/input/chat_mention_popup.dart
// PURPOSE: @ mention autocomplete popup for chat input
// STYLE: WhatsApp-style mention suggestions
// DEPENDENCIES: chat_search_repository.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_message_provider.dart';
import '../../model/chat_member_model.dart';
import '../common/user_avatar_cached.dart';

class ChatMentionPopup extends StatefulWidget {
  final String chatId;
  final String query;
  final Function(String userId, String displayName) onMentionSelected;

  const ChatMentionPopup({
    super.key,
    required this.chatId,
    required this.query,
    required this.onMentionSelected,
  });

  @override
  State<ChatMentionPopup> createState() => _ChatMentionPopupState();
}

class _ChatMentionPopupState extends State<ChatMentionPopup> {
  List<ChatMemberModel> _suggestions = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  @override
  void didUpdateWidget(ChatMentionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _fetchSuggestions();
      setState(() => _selectedIndex = 0);
    }
  }

  void _fetchSuggestions() {
    final provider = context.read<ChatMessageProvider>();
    final members = provider.members;

    if (widget.query.isEmpty) {
      setState(() {
        _suggestions = members;
      });
      return;
    }

    final queryLower = widget.query.toLowerCase();
    setState(() {
      _suggestions = members.where((m) {
        final name = (m.fullName ?? '').toLowerCase();
        final username = (m.username ?? '').toLowerCase();
        return name.contains(queryLower) || username.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;


    if (_suggestions.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No users found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Mentions',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final isSelected = index == _selectedIndex;

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 
                    0.3,
                  ),
                  leading: UserAvatarCached(
                    imageUrl: suggestion.avatarUrl,
                    name: suggestion.fullName ?? 'User',
                    size: 36,
                  ),
                  title: Text(
                    suggestion.fullName ?? 'Unknown',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '@${suggestion.username ?? suggestion.userId.substring(0, 8)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '@',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onMentionSelected(
                      suggestion.userId,
                      suggestion.fullName ?? 'User',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_message_provider.dart';
import '../../model/chat_member_model.dart';
import '../../widgets/common/user_avatar_cached.dart';

class ChatSearchMembersScreen extends StatefulWidget {
  final String chatId;

  const ChatSearchMembersScreen({super.key, required this.chatId});

  @override
  State<ChatSearchMembersScreen> createState() =>
      _ChatSearchMembersScreenState();
}

class _ChatSearchMembersScreenState extends State<ChatSearchMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _isSearching = query.isNotEmpty;
        });
      }
    });
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _showMemberOptions(ChatMemberModel member, bool isAdmin) {
    if (!isAdmin) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!member.role.isAdmin)
              ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber),
                title: const Text('Promote to Admin'),
                onTap: () {
                  Navigator.pop(context);
                  _showPromoteDialog(member);
                },
              ),
            if (member.role.isAdmin && !member.role.isOwner)
              ListTile(
                leading: const Icon(
                  Icons.star_border_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Demote to Member'),
                onTap: () {
                  Navigator.pop(context);
                  _showDemoteDialog(member);
                },
              ),
            if (!member.role.isOwner)
              ListTile(
                leading: const Icon(
                  Icons.person_remove_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Remove from Chat',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveDialog(member);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPromoteDialog(ChatMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Promote to Admin?'),
        content: Text(
          '${member.settings.customTitle ?? 'This member'} will be able to manage group settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatMessageProvider>().promoteMember(
                member.userId,
              );
              Navigator.pop(context);
              ErrorHandler.showSuccessSnackbar('Member promoted to admin');
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  void _showDemoteDialog(ChatMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Demote to Member?'),
        content: Text(
          '${member.settings.customTitle ?? 'This admin'} will lose admin privileges.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatMessageProvider>().demoteMember(
                member.userId,
              );
              Navigator.pop(context);
              ErrorHandler.showSuccessSnackbar('Admin demoted to member');
            },
            child: const Text('Demote'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(ChatMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Member?'),
        content: Text(
          '${member.settings.customTitle ?? 'This member'} will be removed from the chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatMessageProvider>().removeMember(
                member.userId,
              );
              Navigator.pop(context);
              ErrorHandler.showSuccessSnackbar('Member removed');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Consumer<ChatMessageProvider>(
        builder: (context, chatProvider, _) {
          final members = chatProvider.members;
          final myMembership = chatProvider.myMembership;
          final isAdmin = myMembership?.role.isAdmin ?? false;
          final currentUserId = chatProvider.currentUserId;

          if (members.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredMembers = _filterMembers(members);

          if (filteredMembers.isEmpty && _isSearching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members found',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              final member = filteredMembers[index];
              final isCurrentUser = member.userId == currentUserId;
              final isOnline = chatProvider.isUserOnline(member.userId);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  leading: Stack(
                    children: [
                      UserAvatarCached(
                        imageUrl: null,
                        name: member.userId,
                        size: 48,
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.settings.customTitle ??
                              member.userId.substring(0, 8),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (member.role.isAdmin && !isCurrentUser)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    isOnline
                        ? 'Online'
                        : chatProvider.getPresenceText(member.userId),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOnline
                          ? Colors.green
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isAdmin && !isCurrentUser
                      ? IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _showMemberOptions(member, isAdmin),
                        )
                      : null,
                  onTap: () {
                    if (!isCurrentUser) {
                      context.pushNamed(
                        'chatProfileScreen',
                        pathParameters: {'userId': member.userId},
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<ChatMemberModel> _filterMembers(List<ChatMemberModel> members) {
    if (_searchQuery.isEmpty) return members;

    final query = _searchQuery.toLowerCase();
    return members.where((member) {
      final displayName =
          member.settings.customTitle?.toLowerCase() ??
          member.userId.toLowerCase();
      return displayName.contains(query);
    }).toList();
  }
}

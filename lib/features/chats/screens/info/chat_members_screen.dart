import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_message_provider.dart';
import '../../model/chat_member_model.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/members/member_tile.dart';

class ChatMembersScreen extends StatefulWidget {
  final String chatId;

  const ChatMembersScreen({super.key, required this.chatId});

  @override
  State<ChatMembersScreen> createState() => _ChatMembersScreenState();
}

class _ChatMembersScreenState extends State<ChatMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyAdmins = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<ChatMessageProvider>();
      // Ensure chat is loaded
      if (provider.activeChatId != widget.chatId) {
        await provider.openChat(widget.chatId);
      }

      setState(() => _isLoading = false);
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatMembersScreen.loadMembers');
      setState(() => _isLoading = false);
    }
  }

  void _toggleAdminFilter() {
    HapticFeedback.selectionClick();
    setState(() => _showOnlyAdmins = !_showOnlyAdmins);
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _inviteMembers() {
    context.pushNamed(
      'addMembersScreen',
      pathParameters: {'chatId': widget.chatId},
    );
  }

  List<ChatMemberModel> _filterMembers(List<ChatMemberModel> members) {
    var filtered = members;

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((member) {
        final customTitle = member.settings.customTitle?.toLowerCase() ?? '';
        final fullName = member.fullName?.toLowerCase() ?? '';
        final username = member.username?.toLowerCase() ?? '';
        final userId = member.userId.toLowerCase();

        return customTitle.contains(query) ||
            fullName.contains(query) ||
            username.contains(query) ||
            userId.contains(query);
      }).toList();
    }

    // Filter by admins only
    if (_showOnlyAdmins) {
      filtered = filtered.where((member) => member.role.isAdmin).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ChatMessageProvider>(
      builder: (context, chatProvider, _) {
        final allMembers = chatProvider.members;
        final myMembership = chatProvider.myMembership;
        final isAdmin = myMembership?.role.isAdmin ?? false;
        final currentUserId = chatProvider.currentUserId;

        final filteredMembers = _filterMembers(allMembers);
        final onlineCount = allMembers
            .where((m) => chatProvider.isUserOnline(m.userId))
            .length;

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
            title: Text(
              'Members',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed: _inviteMembers,
                  icon: Icon(
                    Icons.person_add_rounded,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
          body: _isLoading
              ? const LoadingShimmerList(itemCount: 8)
              : Column(
                  children: [
                    // Search and filter bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                decoration: InputDecoration(
                                  hintText: 'Search members...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          onPressed: _clearSearch,
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Admins'),
                            selected: _showOnlyAdmins,
                            onSelected: (_) => _toggleAdminFilter(),
                            selectedColor: colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                    ),

                    // Stats bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredMembers.length} members',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$onlineCount online',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Members list
                    Expanded(
                      child: filteredMembers.isEmpty
                          ? EmptyStateIllustration(
                              type: EmptyStateType.custom,
                              icon: Icons.people_outline_rounded,
                              title: 'No members found',
                              description: _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'No members in this chat',
                              compact: true,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                final member = filteredMembers[index];
                                final isCurrentUser =
                                    member.userId == currentUserId;

                                return MemberTile(
                                  member: member,
                                  isGroup: true,
                                  showRole: true,
                                  showActions: isAdmin && !isCurrentUser,
                                  onTap: () {
                                    if (!isCurrentUser) {
                                      context.pushNamed(
                                        'chatMemberProfileScreen',
                                        pathParameters: {
                                          'userId': member.userId,
                                        },
                                        extra: {'chatId': widget.chatId},
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

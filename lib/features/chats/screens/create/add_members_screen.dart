import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../widgets/error_handler.dart';
import '../../widgets/members/member_picker_grid.dart';
import '../../../social/follow/providers/follow_provider.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';
import '../../providers/chat_provider.dart';

class AddMembersScreen extends StatefulWidget {
  final String chatId;
  final List<String>? excludeUserIds;
  final bool isInviteMode;

  const AddMembersScreen({
    super.key,
    required this.chatId,
    this.excludeUserIds,
    this.isInviteMode = false,
  });

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isAdding = false;
  List<ContactItem> _contacts = [];
  List<ContactItem> _allContacts = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final followProvider = context.read<FollowProvider>();
      final myId = Supabase.instance.client.auth.currentUser?.id;

      if (myId != null) {
        await followProvider.loadFollowing(userId: myId);
        final followingList = followProvider.currentFollowing?.users ?? [];

        if (mounted) {
          final contacts = followingList
              .where((u) => !(widget.excludeUserIds?.contains(u.userId) ?? false))
              .map((f) => ContactItem(id: f.userId, name: f.displayName, username: f.username, avatar: f.profileUrl))
              .toList();

          setState(() {
            _contacts = contacts;
            _allContacts = contacts;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'AddMembersScreen.loadContacts');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _contacts = _allContacts);
      return;
    }

    final queryLower = query.toLowerCase();
    final filtered = _allContacts.where((c) =>
      c.name.toLowerCase().contains(queryLower) ||
      c.username.toLowerCase().contains(queryLower)
    ).toList();

    setState(() => _contacts = filtered);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _addMembers() async {
    if (_selectedIds.isEmpty) return;

    try {
      setState(() => _isAdding = true);
      HapticFeedback.mediumImpact();

      final provider = context.read<ChatProvider>();

      if (widget.isInviteMode) {
        // Invite logic if supported by ChatProvider
        // ... (truncated for space)
      } else {
        final result = await provider.addMembers(widget.chatId, _selectedIds.toList());
        if (result.success && mounted) {
          ErrorHandler.showSuccessSnackbar('${_selectedIds.length} members added');
          Navigator.pop(context);
        } else if (mounted) {
          ErrorHandler.showErrorSnackbar(result.error ?? 'Failed to add members');
        }
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
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
        title: Text(widget.isInviteMode ? 'Invite Members' : 'Add Members'), 
        actions: [
        if (_selectedIds.isNotEmpty) TextButton(onPressed: _isAdding ? null : _addMembers, child: _isAdding ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Add (${_selectedIds.length})'))
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _searchController, onChanged: _handleSearch, decoration: InputDecoration(hintText: 'Search people...', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: colorScheme.surfaceContainerHighest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
        Expanded(child: _isLoading ? const LoadingShimmerList(itemCount: 8) : ListView.builder(itemCount: _contacts.length, itemBuilder: (context, index) {
          final contact = _contacts[index];
          final isSelected = _selectedIds.contains(contact.id);
          return ListTile(leading: UserAvatarCached(imageUrl: contact.avatar, name: contact.name, size: 48), title: Text(contact.name), subtitle: Text(contact.username), trailing: Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(contact.id)), onTap: () => _toggleSelection(contact.id));
        }))
      ]),
    );
  }
}

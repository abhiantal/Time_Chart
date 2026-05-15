import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../social/follow/providers/follow_provider.dart';
import '../../widgets/members/member_picker_grid.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../../providers/chat_provider.dart';

class MemberPickerScreen extends StatefulWidget {
  final List<String> initialSelectedIds;
  final int maxSelection;

  const MemberPickerScreen({
    super.key,
    this.initialSelectedIds = const [],
    this.maxSelection = 100,
  });

  @override
  State<MemberPickerScreen> createState() => _MemberPickerScreenState();
}

class _MemberPickerScreenState extends State<MemberPickerScreen> {
  List<ContactItem> _contacts = [];
  List<ContactItem> _allContacts = []; // Cache for "Following" list
  bool _isLoading = true;
  List<String> _currentSelection = [];

  // Cache for all loaded/searched contacts to prevent losing selection details
  final Map<String, ContactItem> _contactCache = {};

  @override
  void initState() {
    super.initState();
    _currentSelection = List.from(widget.initialSelectedIds);
    // Defer loading to avoid "setState during build" error if provider notifies immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final followProvider = context.read<FollowProvider>();
      final myId = Supabase.instance.client.auth.currentUser?.id;

      if (myId != null) {
        // Force refresh to start from offset 0
        await followProvider.loadFollowing(userId: myId, refresh: true);

        final followingList = followProvider.currentFollowing?.users ?? [];
        logI('Loaded ${followingList.length} contacts for picker');

        if (mounted) {
          final contacts = followingList
              .map(
                (f) => ContactItem(
                  id: f.userId,
                  name: f.displayName,
                  username: f.username,
                  avatar: f.profileUrl,
                ),
              )
              .toList();

          setState(() {
            _contacts = contacts;
            _allContacts = contacts;
            for (final c in contacts) {
              _contactCache[c.id] = c;
            }
          });
        }
      } else {
        logW('No current user ID found');
      }
    } catch (e) {
      logE('Failed to load contacts for picker', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _contacts = _allContacts);
      return;
    }

    try {
      final results = await context.read<ChatProvider>().searchContacts(
        query,
      );

      if (!mounted) return;

      setState(() {
        _contacts = results
            .map(
              (r) => ContactItem(
                id: r.id,
                name: r.chatName,
                username: r.subtitle ?? '',
                avatar: r.avatarUrl,
              ),
            )
            .toList();

        for (final c in _contacts) {
          _contactCache[c.id] = c;
        }
      });
    } catch (e) {
      logW('Error searching contacts in picker: $e');
      if (mounted) {
        setState(() => _contacts = []);
        AppSnackbar.error('Search failed', description: 'Check your connection.');
      }
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
        title: const Text('Select Members'),
        actions: [
          TextButton(
            onPressed: _currentSelection.isNotEmpty
                ? () {
                    final selectedContacts = _currentSelection
                        .map((id) => _contactCache[id])
                        .whereType<ContactItem>()
                        .toList();

                    Navigator.pop(context, selectedContacts);
                  }
                : null,
            child: const Text('Done'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MemberPickerGrid(
              contacts: _contacts,
              initialSelectedIds: widget.initialSelectedIds,
              maxSelection: widget.maxSelection,
              onSelectionChanged: (ids) {
                _currentSelection = ids;
                // Force rebuild to update 'Done' button state
                setState(() {});
              },
              onSearch: _onSearch,
              onDone: () {
                final selectedContacts = _currentSelection
                    .map((id) => _contactCache[id])
                    .whereType<ContactItem>()
                    .toList();
                Navigator.pop(context, selectedContacts);
              },
            ),
    );
  }
}

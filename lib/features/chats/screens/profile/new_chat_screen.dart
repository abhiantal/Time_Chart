// ================================================================
// FILE: lib/features/chats/screen/new_chat_screen.dart
// PURPOSE: Search and select contacts to start a new 1:1 chat
// STYLE: WhatsApp + iOS Contacts
// DEPENDENCIES: chat_avatar_with_status.dart, chat_search_bar.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../social/follow/providers/follow_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_list/chat_avatar_with_status.dart';
import '../../widgets/search/search_bar_animated.dart';
import '../../../../widgets/error_handler.dart';
import '../../../../widgets/logger.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<ContactItem> _contacts = [];
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    try {
      final followProvider = context.read<FollowProvider>();
      final myId = Supabase.instance.client.auth.currentUser?.id;

      if (myId != null) {
        // Load following users
        await followProvider.loadFollowing(userId: myId);

        // Check if user started searching while we were loading
        if (_searchController.text.isNotEmpty) return;

        final followingList = followProvider.currentFollowing?.users ?? [];

        if (mounted) {
          setState(() {
            _contacts = followingList
                .map(
                  (f) => ContactItem(
                    id: f.userId,
                    name: f.displayName,
                    username: f.username,
                    avatar: f.profileUrl,
                    isOnline: false, // TODO: Check online status
                    status: f.bio ?? '',
                  ),
                )
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      logE('Failed to load contacts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    // Determine if we should clear or search based on query content
    if (query.isEmpty) {
      // Reload initial contacts (following)
      _loadContacts();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await context.read<ChatProvider>().searchContacts(
        query,
      );

      if (!mounted) return;

      // DISCARD results if query has changed since we started
      if (_searchController.text != query) return;

      setState(() {
        _contacts = results
            .map(
              (r) => ContactItem(
                id: r.id,
                name: r.chatName,
                username: r.subtitle ?? '',
                avatar: r.avatarUrl,
                isOnline: false,
                status: '', // r.description ?? '',
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      logE('Error searching contacts: $e');
      if (!mounted) return;

      // Only update if query matches
      if (_searchController.text != query) return;

      if (mounted) {
        setState(() {
          _contacts = [];
          _isLoading = false;
        });

        // Show error to user (likely network issue)
        // Show error to user (likely network issue)
        ErrorHandler.showErrorSnackbar(
          'Search failed. Check your connection.',
          context: context,
        );
      }
    }
  }

  Future<void> _startChat(ContactItem contact) async {
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<ChatProvider>();
      final result = await provider.getOrCreateDirectChat(contact.id);

      if (result.success && mounted) {
        // Give the watchQuery stream time to emit the new/existing chat
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        context.pushReplacementNamed(
          'personalChatScreen',
          pathParameters: {'chatId': result.data!},
        );
      } else {
        if (mounted) {
          ErrorHandler.showErrorSnackbar(
            result.error ?? 'Failed to start chat',
            context: context,
          );
        }
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'NewChatScreen.startChat');
      if (mounted) {
        ErrorHandler.showErrorSnackbar(
          'Failed to start chat',
          context: context,
        );
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          'New Chat',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBarAnimated(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search people...',
                onChanged: _handleSearch,
                onClear: () {
                  _searchController.clear();
                  _handleSearch('');
                },
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(theme, colorScheme)
                  : _contacts.isEmpty
                  ? _buildEmptyState(theme, colorScheme)
                  : _buildContactsList(theme, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    // If not searching (and list empty), user follows no one
    final isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching
                  ? Icons.person_search_rounded
                  : Icons.people_outline_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'No user found' : 'Find People',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isSearching
                  ? 'We couldn\'t find anyone matching "${_searchController.text}"'
                  : 'Search for a username to start a new chat',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ThemeData theme, ColorScheme colorScheme) {
    // Group contacts by first letter
    final groupedContacts = <String, List<ContactItem>>{};
    for (final contact in _contacts) {
      if (contact.name.isEmpty) continue;
      final firstLetter = contact.name[0].toUpperCase();
      if (!groupedContacts.containsKey(firstLetter)) {
        groupedContacts[firstLetter] = [];
      }
      groupedContacts[firstLetter]!.add(contact);
    }

    final sortedLetters = groupedContacts.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedLetters.length,
      itemBuilder: (context, index) {
        final letter = sortedLetters[index];
        final contactsItems = groupedContacts[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                letter,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),

            // Contacts in this section
            ...contactsItems.map(
              (contact) => _buildContactTile(contact, theme, colorScheme),
            ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildContactTile(
    ContactItem contact,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startChat(contact),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Avatar with online status
              ChatAvatarWithStatus(
                imageUrl: contact.avatar,
                name: contact.name,
                size: 52,
                isOnline: contact.isOnline,
                showPulseAnimation: true,
              ),

              const SizedBox(width: 12),

              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (contact.isOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Online',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF22C55E),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.username,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Start chat button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactItem {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isOnline;
  final String status;

  const ContactItem({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    required this.isOnline,
    required this.status,
  });
}

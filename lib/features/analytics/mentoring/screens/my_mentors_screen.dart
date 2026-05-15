// ================================================================
// FILE: lib/features/mentoring/screen/my_mentors_screen.dart
// Screen showing people who can view my progress (I am the owner)
// Allows managing, pausing, and revoking mentor access
// Single source of truth: uses streams for real-time updates
// ================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import '../repositories/mentorship_repository.dart';
import '../widgets/mentoring_cards.dart';
import '../widgets/mentoring_common_widgets.dart';
import '../widgets/mentoring_dialogs.dart';
import '../widgets/mentoring_menus.dart';
import '../../../../widgets/app_snackbar.dart';
import 'access_settings_screen.dart';

class MyMentorsScreen extends StatefulWidget {
  const MyMentorsScreen({super.key});

  @override
  State<MyMentorsScreen> createState() => _MyMentorsScreenState();
}

class _MyMentorsScreenState extends State<MyMentorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _isSearching = false;

  // Stream-based single source of truth
  final MentorshipRepository _repository = MentorshipRepository();
  StreamSubscription<List<MentorshipConnection>>? _mentorsStreamSubscription;
  List<MentorshipConnection> _liveMentors = [];
  bool _isStreamLoading = true;

  // Filter tabs
  static const List<_FilterTab> _tabs = [
    _FilterTab('Active', AccessStatus.active),
    _FilterTab('Paused', AccessStatus.paused),
    _FilterTab('All', null),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _startWatchingMentors();
  }

  @override
  void dispose() {
    _mentorsStreamSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Subscribe to the mentors stream for real-time updates.
  /// This is the single source of truth — any change by any user
  /// (e.g. another user revoking) will be reflected automatically.
  void _startWatchingMentors() {
    final userId = _repository.currentUserId;
    if (userId.isEmpty) return;

    _mentorsStreamSubscription = _repository
        .watchMyMentors(userId)
        .listen(
          (mentors) {
            if (mounted) {
              setState(() {
                _liveMentors = mentors;
                _isStreamLoading = false;
              });
              // Load profiles for all mentor IDs so names/avatars are available
              final provider = context.read<MentorshipProvider>();
              provider.loadProfilesForUsers(mentors.map((m) => m.mentorId));
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _isStreamLoading = false);
            }
          },
        );
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(theme, colorScheme),
      body: Consumer<MentorshipProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Bar
              if (_isSearching) _buildSearchBar(theme, colorScheme),

              // Tab Bar
              _buildTabBar(theme, colorScheme),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildMentorList(
                      provider,
                      theme,
                      colorScheme,
                      isDarkMode,
                      tab.status,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(colorScheme, isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('My Mentors'),
      centerTitle: false,
      actions: [
        // Search Toggle
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          tooltip: _isSearching ? 'Close Search' : 'Search',
        ),
        // Filter/Sort Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter & Sort',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: _handleFilterAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sort_recent',
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 20),
                  SizedBox(width: 12),
                  Text('Most Recent'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_name',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha, size: 20),
                  SizedBox(width: 12),
                  Text('By Name'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_views',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 12),
                  Text('Most Views'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'expiring_soon',
              child: Row(
                children: [
                  Icon(Icons.timer, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Expiring Soon'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search mentors...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: _tabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tab.label),
                if (_getCountForTab(tab.status) > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _tabController.index == _tabs.indexOf(tab)
                          ? Colors.white.withAlpha((255 * 0.3).toInt())
                          : colorScheme.primary.withAlpha((255 * 0.2).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getCountForTab(tab.status)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == _tabs.indexOf(tab)
                            ? Colors.white
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMentorList(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
    AccessStatus? filterStatus,
  ) {
    // Use live stream data as single source of truth
    List<MentorshipConnection> mentors = List.from(_liveMentors);

    // Filter out revoked/expired — only show active and paused
    mentors = mentors
        .where(
          (m) =>
              m.accessStatus == AccessStatus.active ||
              m.accessStatus == AccessStatus.paused,
        )
        .toList();

    // Apply status filter
    if (filterStatus != null) {
      mentors = mentors.where((m) => m.accessStatus == filterStatus).toList();
    }

    // Apply search filter — search by name, label, and relationship type
    if (_searchQuery.isNotEmpty) {
      mentors = mentors.where((m) {
        final label = m.relationshipLabel?.toLowerCase() ?? '';
        final type = m.relationshipType.label.toLowerCase();
        // Also search by actual username from profile cache
        final profile = provider.getUserProfile(m.mentorId);
        final username = profile?.username.toLowerCase() ?? '';
        final displayName = profile?.displayName.toLowerCase() ?? '';
        return label.contains(_searchQuery) ||
            type.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            displayName.contains(_searchQuery);
      }).toList();
    }

    // Loading state
    if (_isStreamLoading && mentors.isEmpty) {
      return MentoringLoadingState.cards(count: 3);
    }

    // Empty state
    if (mentors.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return MentoringEmptyState.noResults(searchQuery: _searchQuery);
      }

      if (filterStatus == AccessStatus.active) {
        return MentoringEmptyState(
          type: MentoringEmptyType.noActive,
          title: 'No Active Mentors',
          subtitle: 'You don\'t have any active mentors viewing your progress.',
          actionLabel: 'Share Access',
          onAction: () => _showShareAccessMenu(context),
        );
      }

      if (filterStatus == AccessStatus.paused) {
        return const MentoringEmptyState(
          type: MentoringEmptyType.noActive,
          title: 'No Paused Mentors',
          subtitle: 'You haven\'t paused any mentor access.',
        );
      }

      return MentoringEmptyState.noMentors(
        onAddMentor: () => _showShareAccessMenu(context),
      );
    }

    // Mentor list
    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: mentors.length + 1, // +1 for summary header
        itemBuilder: (context, index) {
          // Summary header
          if (index == 0) {
            return _buildListHeader(
              theme,
              colorScheme,
              mentors.length,
              filterStatus,
            );
          }

          final mentor = mentors[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MentorCard(
              connection: mentor,
              mentorName: _getMentorDisplayName(mentor, provider),
              mentorAvatar: _getMentorAvatar(mentor, provider),
              showActions: true,
              compact: false,
              onTap: () => _navigateToSettings(mentor),
              onSettings: () => _navigateToSettings(mentor),
              onPause: () => _handlePauseResume(mentor, provider),
              onRevoke: () => _handleRevoke(mentor, provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    int count,
    AccessStatus? filterStatus,
  ) {
    String statusText = 'mentor${count == 1 ? '' : 's'}';
    if (filterStatus == AccessStatus.active) {
      statusText = 'active $statusText';
    } else if (filterStatus == AccessStatus.paused) {
      statusText = 'paused $statusText';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(
                (255 * 0.5).toInt(),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '$count $statusText',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAB(ColorScheme colorScheme, bool isDarkMode) {
    return FloatingActionButton.extended(
      heroTag: 'my_mentors_request_fab',
      onPressed: () => _showShareAccessMenu(context),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.person_add),
      label: const Text('Share Access'),
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  int _getCountForTab(AccessStatus? status) {
    // Use live stream data for counts
    final activeMentors = _liveMentors
        .where(
          (m) =>
              m.accessStatus == AccessStatus.active ||
              m.accessStatus == AccessStatus.paused,
        )
        .toList();

    if (status == null) {
      return activeMentors.length;
    }
    return activeMentors.where((m) => m.accessStatus == status).length;
  }

  /// Get the display name for a mentor.
  /// Priority: profile username > relationship label > relationship type + ID
  String _getMentorDisplayName(
    MentorshipConnection mentor,
    MentorshipProvider provider,
  ) {
    // First try to get the actual username from profile cache
    final profile = provider.getUserProfile(mentor.mentorId);
    if (profile != null && (profile.displayName.isNotEmpty || profile.username.isNotEmpty)) {
      return profile.displayName.isNotEmpty ? profile.displayName : profile.username;
    }
    // Then try relationship label
    if (mentor.relationshipLabel?.isNotEmpty ?? false) {
      return mentor.relationshipLabel!;
    }
    // Fallback to relationship type + ID
    return '${mentor.relationshipType.mentorLabel} (${mentor.mentorId.substring(0, 6)})';
  }

  /// Get the avatar URL for a mentor from the profile cache
  String? _getMentorAvatar(
    MentorshipConnection mentor,
    MentorshipProvider provider,
  ) {
    return provider.getUserProfile(mentor.mentorId)?.profileUrl;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    HapticFeedback.selectionClick();
  }

  void _handleFilterAction(String action) {
    HapticFeedback.selectionClick();
    switch (action) {
      case 'sort_recent':
        setState(() {
          _liveMentors.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
        break;
      case 'sort_name':
        final provider = context.read<MentorshipProvider>();
        setState(() {
          _liveMentors.sort((a, b) {
            final nameA = _getMentorDisplayName(a, provider).toLowerCase();
            final nameB = _getMentorDisplayName(b, provider).toLowerCase();
            return nameA.compareTo(nameB);
          });
        });
        break;
      case 'sort_views':
        setState(() {
          _liveMentors.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        });
        break;
      case 'expiring_soon':
        setState(() {
          _liveMentors.sort((a, b) {
            if (a.expiresAt == null && b.expiresAt == null) return 0;
            if (a.expiresAt == null) return 1;
            if (b.expiresAt == null) return -1;
            return a.expiresAt!.compareTo(b.expiresAt!);
          });
        });
        break;
    }
  }

  // ================================================================
  // NAVIGATION & ACTIONS
  // ================================================================

  void _navigateToSettings(MentorshipConnection mentor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccessSettingsScreen(connection: mentor),
      ),
    );
  }

  Future<void> _handlePauseResume(
    MentorshipConnection mentor,
    MentorshipProvider provider,
  ) async {
    final isPaused = mentor.isPaused;
    final displayName = _getMentorDisplayName(mentor, provider);

    // Show confirmation dialog
    final confirmed = await PauseAccessDialog.show(
      context,
      isPaused: isPaused,
      userName: displayName,
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();

      bool success;
      if (isPaused) {
        success = await provider.resumeAccess(mentor.id);
      } else {
        success = await provider.pauseAccess(mentor.id);
      }

      if (success && mounted) {
        // Refresh to get latest data from stream
        await provider.refreshAll();
        AppSnackbar.success(
          isPaused
              ? 'Access resumed for $displayName'
              : 'Access paused for $displayName',
        );
      } else if (!success && mounted) {
        AppSnackbar.error(
          isPaused ? 'Failed to resume access' : 'Failed to pause access',
        );
      }
    }
  }

  Future<void> _handleRevoke(
    MentorshipConnection mentor,
    MentorshipProvider provider,
  ) async {
    final displayName = _getMentorDisplayName(mentor, provider);

    // Show revoke confirmation dialog
    final confirmed = await RevokeAccessDialog.show(
      context,
      connection: mentor,
      userName: displayName,
      isMentor: true,
      onRevoke: () async {
        final success = await provider.revokeAccess(mentor.id);
        if (success) {
          // Refresh to get the latest list from the stream
          // The stream will automatically filter out revoked items
          await provider.refreshAll();
        }
        return success;
      },
    );

    if (confirmed == true && mounted) {
      HapticFeedback.heavyImpact();
      AppSnackbar.success('Access revoked for $displayName');
    }
  }

  Future<void> _showShareAccessMenu(BuildContext context) async {
    final provider = context.read<MentorshipProvider>();

    await ShareAccessMenu.show(
      context,
      onSearchUsers: (query) async {
        // TODO: Implement user search from your user provider
        return [];
      },
      onSubmit:
          ({
            required String viewerId,
            required RelationshipType relationshipType,
            String? relationshipLabel,
            required List<AccessibleScreen> screens,
            required MentorshipPermissions permissions,
            required AccessDuration duration,
            required bool isLiveEnabled,
          }) async {
            final result = await provider.shareAccessWith(
              viewerId: viewerId,
              relationshipType: relationshipType,
              relationshipLabel: relationshipLabel,
              screens: screens,
              permissions: permissions,
              duration: duration,
              isLiveEnabled: isLiveEnabled,
            );
            return result != null;
          },
    );
  }
}

// ================================================================
// HELPER CLASSES
// ================================================================

class _FilterTab {
  final String label;
  final AccessStatus? status;

  const _FilterTab(this.label, this.status);
}

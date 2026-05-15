// ================================================================
// FILE: lib/features/mentoring/screen/my_mentees_screen.dart
// Screen showing people whose progress I can view (I am the mentor/viewer)
// Allows viewing their data and sending encouragement
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
import '../widgets/mentoring_utils.dart';
import 'view_mentee_screen.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';
import '../../../../widgets/app_snackbar.dart';

class MyMenteesScreen extends StatefulWidget {
  const MyMenteesScreen({super.key});

  @override
  State<MyMenteesScreen> createState() => _MyMenteesScreenState();
}

class _MyMenteesScreenState extends State<MyMenteesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _isSearching = false;
  _SortOption _currentSort = _SortOption.recent;

  // Stream-based single source of truth
  final MentorshipRepository _repository = MentorshipRepository();
  StreamSubscription<List<MentorshipConnection>>? _menteesStreamSubscription;
  List<MentorshipConnection> _liveMentees = [];
  bool _isStreamLoading = true;

  // Filter tabs
  static const List<_FilterTab> _tabs = [
    _FilterTab('Active', _FilterType.active, Icons.check_circle),
    _FilterTab(
      'Needs Attention',
      _FilterType.needsAttention,
      Icons.warning_amber,
    ),
    _FilterTab('All', _FilterType.all, Icons.list),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _startWatchingMentees();
  }

  @override
  void dispose() {
    _menteesStreamSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Subscribe to the mentees stream for real-time updates.
  /// This is the single source of truth — any change by any user
  /// (e.g. a mentee revoking access) will be reflected automatically.
  void _startWatchingMentees() {
    final userId = _repository.currentUserId;
    if (userId.isEmpty) return;

    _menteesStreamSubscription = _repository
        .watchMyMentees(userId)
        .listen(
          (mentees) {
            if (mounted) {
              setState(() {
                _liveMentees = mentees;
                _isStreamLoading = false;
              });
              // Load profiles for all mentee owner IDs so names/avatars are available
              final provider = context.read<MentorshipProvider>();
              provider.loadProfilesForUsers(mentees.map((m) => m.ownerId));
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
              _buildTabBar(theme, colorScheme, provider),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildMenteeList(
                      provider,
                      theme,
                      colorScheme,
                      isDarkMode,
                      tab.filterType,
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
      title: const Text('My Mentees'),
      centerTitle: false,
      actions: [
        // Search Toggle
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          tooltip: _isSearching ? 'Close Search' : 'Search',
        ),
        // Sort & Filter Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: _handleSortAction,
          itemBuilder: (context) => [
            _buildSortMenuItem('sort_recent', 'Most Recent', Icons.access_time),
            _buildSortMenuItem('sort_activity', 'By Activity', Icons.timeline),
            _buildSortMenuItem(
              'sort_streak',
              'By Streak',
              Icons.local_fire_department,
            ),
            _buildSortMenuItem('sort_points', 'By Points', Icons.stars),
            const PopupMenuDivider(),
            _buildSortMenuItem('sort_name', 'By Name', Icons.sort_by_alpha),
            _buildSortMenuItem(
              'sort_relationship',
              'By Relationship',
              Icons.handshake,
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _currentSort.value == value;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? colorScheme.primary : null),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18, color: colorScheme.primary),
          ],
        ],
      ),
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
          hintText: 'Search mentees...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
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

  Widget _buildTabBar(
    ThemeData theme,
    ColorScheme colorScheme,
    MentorshipProvider provider,
  ) {
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
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: _tabs.map((tab) {
          final count = _getCountForTab(tab.filterType);
          final isSelected = _tabController.index == _tabs.indexOf(tab);
          final isAttention = tab.filterType == _FilterType.needsAttention;

          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAttention && count > 0) ...[
                  Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(tab.label, overflow: TextOverflow.ellipsis),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha((255 * 0.3).toInt())
                          : (isAttention
                                ? Colors.orange.withAlpha((255 * 0.2).toInt())
                                : colorScheme.primary.withAlpha(
                                    (255 * 0.2).toInt(),
                                  )),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isAttention
                                  ? Colors.orange
                                  : colorScheme.primary),
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

  Widget _buildMenteeList(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
    _FilterType filterType,
  ) {
    // Use live stream data as single source of truth
    List<MentorshipConnection> mentees = _getFilteredMentees(
      provider,
      filterType,
    );

    // Apply search filter — search by name, label, relationship type, and username
    if (_searchQuery.isNotEmpty) {
      mentees = mentees.where((m) {
        final label = m.relationshipLabel?.toLowerCase() ?? '';
        final type = m.relationshipType.label.toLowerCase();
        // Also search by actual username from profile cache
        final profile = provider.getUserProfile(m.ownerId);
        final username = profile?.username.toLowerCase() ?? '';
        final displayName = profile?.displayName.toLowerCase() ?? '';
        return label.contains(_searchQuery) ||
            type.contains(_searchQuery) ||
            username.contains(_searchQuery) ||
            displayName.contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    mentees = _applySorting(mentees);

    // Loading state
    if (_isStreamLoading && mentees.isEmpty) {
      return MentoringLoadingState.cards(count: 3);
    }

    // Empty state
    if (mentees.isEmpty) {
      return _buildEmptyState(filterType);
    }

    // Mentee list
    return RefreshIndicator(
      onRefresh: () async {
        final provider = context.read<MentorshipProvider>();
        await provider.refreshAll();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: mentees.length + 1, // +1 for header
        itemBuilder: (context, index) {
          // Summary header
          if (index == 0) {
            return _buildListHeader(
              theme,
              colorScheme,
              mentees.length,
              filterType,
            );
          }

          final mentee = mentees[index - 1];
          final menteeData = _getMenteeDisplayData(mentee, provider);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MenteeCard(
              connection: mentee,
              menteeName: menteeData.name,
              menteeAvatar: menteeData.avatar,
              currentStreak: menteeData.streak,
              totalPoints: menteeData.points,
              isActive: menteeData.isActive,
              showQuickStats: true,
              showActions: true,
              compact: false,
              onTap: () => _navigateToViewMentee(mentee),
              onViewProgress: () => _navigateToViewMentee(mentee),
              onEncourage: () => _showEncouragementDialog(mentee),
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
    _FilterType filterType,
  ) {
    String statusText;
    Color? badgeColor;

    switch (filterType) {
      case _FilterType.active:
        statusText = 'active mentee${count == 1 ? '' : 's'}';
        break;
      case _FilterType.needsAttention:
        statusText = 'need${count == 1 ? 's' : ''} attention';
        badgeColor = Colors.orange;
        break;
      case _FilterType.all:
        statusText = 'mentee${count == 1 ? '' : 's'}';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (badgeColor ?? colorScheme.primary).withAlpha(
                (255 * 0.1).toInt(),
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (badgeColor ?? colorScheme.primary).withAlpha(
                  (255 * 0.2).toInt(),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterType == _FilterType.needsAttention
                      ? Icons.warning_amber
                      : Icons.school,
                  size: 16,
                  color: badgeColor ?? colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count $statusText',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: badgeColor ?? colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sort indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _currentSort.icon,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentSort.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(_FilterType filterType) {
    if (_searchQuery.isNotEmpty) {
      return MentoringEmptyState.noResults(searchQuery: _searchQuery);
    }

    switch (filterType) {
      case _FilterType.active:
        return MentoringEmptyState(
          type: MentoringEmptyType.noActive,
          title: 'No Active Mentees',
          subtitle: 'You don\'t have any active mentees to monitor.',
          actionLabel: 'Request Access',
          onAction: () => _showRequestAccessMenu(context),
        );
      case _FilterType.needsAttention:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noActive,
          customEmoji: '🎉',
          title: 'All Caught Up!',
          subtitle: 'None of your mentees need attention right now.',
        );
      case _FilterType.all:
        return MentoringEmptyState.noMentees(
          onRequestAccess: () => _showRequestAccessMenu(context),
        );
    }
  }

  Widget _buildFAB(ColorScheme colorScheme, bool isDarkMode) {
    return FloatingActionButton.extended(
      heroTag: 'my_mentees_request_fab',
      onPressed: () => _showRequestAccessMenu(context),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.person_add),
      label: const Text('Request Access'),
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  List<MentorshipConnection> _getFilteredMentees(
    MentorshipProvider provider,
    _FilterType filterType,
  ) {
    // Use live stream data as single source of truth
    // Filter out revoked/expired — only show active and paused
    final validMentees = _liveMentees
        .where(
          (m) =>
              m.accessStatus == AccessStatus.active ||
              m.accessStatus == AccessStatus.paused,
        )
        .toList();

    switch (filterType) {
      case _FilterType.active:
        return validMentees
            .where((m) => m.accessStatus == AccessStatus.active)
            .toList();
      case _FilterType.needsAttention:
        return validMentees.where((m) {
          if (!m.canAccess) return false;
          if (m.lastViewedAt == null) return true;
          final daysSinceView = DateTime.now()
              .difference(m.lastViewedAt!)
              .inDays;
          return daysSinceView >= m.inactiveThresholdDays;
        }).toList();
      case _FilterType.all:
        return validMentees;
    }
  }

  List<MentorshipConnection> _applySorting(List<MentorshipConnection> mentees) {
    final sorted = List<MentorshipConnection>.from(mentees);

    switch (_currentSort) {
      case _SortOption.recent:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _SortOption.activity:
        sorted.sort((a, b) {
          final aViewed = a.lastViewedAt ?? DateTime(1970);
          final bViewed = b.lastViewedAt ?? DateTime(1970);
          return bViewed.compareTo(aViewed);
        });
        break;
      case _SortOption.streak:
        // TODO: Sort by actual streak when user data is available
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case _SortOption.points:
        // TODO: Sort by actual points when user data is available
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case _SortOption.name:
        final provider = context.read<MentorshipProvider>();
        sorted.sort((a, b) {
          final aName = _getMenteeDisplayName(a, provider).toLowerCase();
          final bName = _getMenteeDisplayName(b, provider).toLowerCase();
          return aName.compareTo(bName);
        });
        break;
      case _SortOption.relationship:
        sorted.sort(
          (a, b) =>
              a.relationshipType.index.compareTo(b.relationshipType.index),
        );
        break;
    }

    return sorted;
  }

  int _getCountForTab(_FilterType filterType) {
    final provider = context.read<MentorshipProvider>();
    return _getFilteredMentees(provider, filterType).length;
  }

  /// Get display name for a mentee.
  /// Priority: profile username > relationship label > relationship type + ID
  String _getMenteeDisplayName(
    MentorshipConnection mentee,
    MentorshipProvider provider,
  ) {
    // First try to get actual username from profile cache
    final profile = provider.getUserProfile(mentee.ownerId);
    if (profile != null && (profile.displayName.isNotEmpty || profile.username.isNotEmpty)) {
      final nameToUse = profile.displayName.isNotEmpty ? profile.displayName : profile.username;
      return '$nameToUse (${mentee.relationshipType.ownerLabel})';
    }
    // Then try relationship label
    if (mentee.relationshipLabel?.isNotEmpty ?? false) {
      return mentee.relationshipLabel!;
    }
    // Fallback to relationship type + ID
    return '${mentee.relationshipType.ownerLabel} (${mentee.ownerId.substring(0, 6)})';
  }

  /// Get the avatar URL for a mentee from the profile cache
  String? _getMenteeAvatar(
    MentorshipConnection mentee,
    MentorshipProvider provider,
  ) {
    return provider.getUserProfile(mentee.ownerId)?.profileUrl;
  }

  _MenteeDisplayData _getMenteeDisplayData(
    MentorshipConnection mentee,
    MentorshipProvider provider,
  ) {
    final name = _getMenteeDisplayName(mentee, provider);
    final avatar = _getMenteeAvatar(mentee, provider);

    return _MenteeDisplayData(
      name: name,
      avatar: avatar,
      streak: mentee.cachedSnapshot['streak'] as int? ?? 0,
      points: mentee.cachedSnapshot['points'] as int? ?? 0,
      isActive: !MentoringHelpers.isMenteeInactive(mentee),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _clearSearch();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _handleSortAction(String action) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentSort = _SortOption.values.firstWhere(
        (s) => s.value == action,
        orElse: () => _SortOption.recent,
      );
    });
  }

  // ================================================================
  // NAVIGATION & ACTIONS
  // ================================================================

  void _navigateToViewMentee(MentorshipConnection mentee) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewMenteeScreen(connection: mentee)),
    );
  }

  Future<void> _showEncouragementDialog(MentorshipConnection mentee) async {
    final provider = context.read<MentorshipProvider>();
    final menteeData = _getMenteeDisplayData(mentee, provider);

    final result = await SendEncouragementDialog.show(
      context,
      connection: mentee,
      menteeName: menteeData.name,
      menteeAvatar: menteeData.avatar,
      onSend: (type, message) async {
        final success = await provider.sendEncouragement(
          mentee.id,
          type: type,
          message: message,
        );
        return success;
      },
    );

    if (result == true && mounted) {
      HapticFeedback.mediumImpact();
      AppSnackbar.success('Encouragement sent to ${menteeData.name}!');
    }
  }

  Future<void> _showRequestAccessMenu(BuildContext context) async {
    final provider = context.read<MentorshipProvider>();
    final userRepo = ProfileRepository();

    await RequestAccessMenu.show(
      context,
      onSearchUsers: (query) async {
        final users = await userRepo.searchProfiles(query);
        return users
            .map(
              (u) => {'id': u.id, 'name': u.displayName.isNotEmpty ? u.displayName : u.username, 'avatar': u.profileUrl},
            )
            .toList();
      },
      onSubmit:
          ({
            required String targetUserId,
            required RelationshipType relationshipType,
            String? relationshipLabel,
            required List<AccessibleScreen> screens,
            required AccessDuration duration,
            String? message,
          }) async {
            final result = await provider.sendAccessRequest(
              targetUserId: targetUserId,
              relationshipType: relationshipType,
              relationshipLabel: relationshipLabel,
              screens: screens,
              duration: duration,
              message: message,
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
  final _FilterType filterType;
  final IconData icon;

  const _FilterTab(this.label, this.filterType, this.icon);
}

enum _FilterType { active, needsAttention, all }

enum _SortOption {
  recent('sort_recent', 'Recent', Icons.access_time),
  activity('sort_activity', 'Activity', Icons.timeline),
  streak('sort_streak', 'Streak', Icons.local_fire_department),
  points('sort_points', 'Points', Icons.stars),
  name('sort_name', 'Name', Icons.sort_by_alpha),
  relationship('sort_relationship', 'Type', Icons.handshake);

  final String value;
  final String label;
  final IconData icon;

  const _SortOption(this.value, this.label, this.icon);
}

class _MenteeDisplayData {
  final String name;
  final String? avatar;
  final int streak;
  final int points;
  final bool isActive;

  const _MenteeDisplayData({
    required this.name,
    this.avatar,
    required this.streak,
    required this.points,
    required this.isActive,
  });
}

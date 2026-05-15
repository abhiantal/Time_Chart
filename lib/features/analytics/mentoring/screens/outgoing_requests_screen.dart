// ================================================================
// FILE: lib/features/mentoring/screen/outgoing_requests_screen.dart
// Screen showing my requests to view others' progress
// Allows viewing status and canceling pending requests
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import '../widgets/mentoring_common_widgets.dart';
import '../widgets/mentoring_dialogs.dart';
import '../widgets/mentoring_menus.dart';
import '../widgets/mentoring_utils.dart';
import '../../../../widgets/app_snackbar.dart';
import 'view_mentee_screen.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';

class OutgoingRequestsScreen extends StatefulWidget {
  const OutgoingRequestsScreen({super.key});

  @override
  State<OutgoingRequestsScreen> createState() => _OutgoingRequestsScreenState();
}

class _OutgoingRequestsScreenState extends State<OutgoingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User profile cache
  final Map<String, Map<String, String?>> _userProfiles = {};
  final ProfileRepository _profileRepository = ProfileRepository();

  // Filter tabs
  static const List<_OutgoingTab> _tabs = [
    _OutgoingTab(
      'Pending',
      _OutgoingFilter.pending,
      Icons.hourglass_empty,
      Colors.orange,
    ),
    _OutgoingTab(
      'Approved',
      _OutgoingFilter.approved,
      Icons.check_circle,
      Colors.green,
    ),
    _OutgoingTab(
      'Rejected',
      _OutgoingFilter.rejected,
      Icons.cancel,
      Colors.red,
    ),
    _OutgoingTab('All', _OutgoingFilter.all, Icons.list, Colors.grey),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (mounted) setState(() {});
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
              // Summary Stats Row
              _buildSummaryStats(provider, theme, colorScheme),

              // Tab Bar
              _buildTabBar(theme, colorScheme, provider),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildRequestList(
                      provider,
                      theme,
                      colorScheme,
                      isDarkMode,
                      tab.filter,
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
      title: const Text('Outgoing Requests'),
      centerTitle: false,
      actions: [
        // Refresh Button
        Consumer<MentorshipProvider>(
          builder: (context, provider, _) {
            return IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      provider.refreshAll();
                    },
              icon: provider.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
            );
          },
        ),
        // Info Button
        IconButton(
          onPressed: () => _showInfoDialog(context),
          icon: const Icon(Icons.info_outline),
          tooltip: 'Info',
        ),
      ],
    );
  }

  Widget _buildSummaryStats(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final pending = provider.outgoingRequests.length;
    final approved = provider.myMentees
        .where((m) => m.requestType == RequestType.requestAccess)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withAlpha((255 * 0.5).toInt()),
            colorScheme.secondaryContainer.withAlpha((255 * 0.3).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha((255 * 0.1).toInt()),
        ),
      ),
      child: Row(
        children: [
          // Pending
          Expanded(
            child: _StatItem(
              icon: Icons.hourglass_empty,
              iconColor: Colors.orange,
              value: pending,
              label: 'Pending',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
          // Approved
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              value: approved,
              label: 'Approved',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
          // Success Rate
          Expanded(
            child: _StatItem(
              icon: Icons.trending_up,
              iconColor: colorScheme.primary,
              value: _calculateSuccessRate(provider),
              label: 'Success',
              isPercentage: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    ThemeData theme,
    ColorScheme colorScheme,
    MentorshipProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final count = _getCountForTab(tab.filter, provider);
          final isSelected = _tabController.index == index;

          return GestureDetector(
            onTap: () {
              _tabController.animateTo(index);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? tab.color
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? tab.color
                      : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 16,
                    color: isSelected ? Colors.white : tab.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withAlpha((255 * 0.3).toInt())
                            : tab.color.withAlpha((255 * 0.15).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : tab.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestList(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
    _OutgoingFilter filter,
  ) {
    // Get filtered requests
    List<MentorshipConnection> requests = _getFilteredRequests(
      provider,
      filter,
    );

    // Loading state
    if (provider.isLoading && requests.isEmpty) {
      return MentoringLoadingState.cards(count: 3);
    }

    // Empty state
    if (requests.isEmpty) {
      return _buildEmptyState(filter);
    }

    // Request list
    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOutgoingRequestCard(
              request,
              theme,
              colorScheme,
              isDarkMode,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutgoingRequestCard(
    MentorshipConnection request,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final targetData = _getTargetDisplayData(request);
    final isPending = request.requestStatus == RequestStatus.pending;
    final isApproved = request.requestStatus == RequestStatus.approved;
    final isRejected = request.requestStatus == RequestStatus.rejected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPending
                  ? Colors.orange.withAlpha((255 * 0.3).toInt())
                  : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
              width: isPending ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  (255 * (isDarkMode ? 0.2 : 0.05)).toInt(),
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar with status indicator
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: MentoringHelpers.getAvatarColor(
                          targetData.name,
                        ),
                        backgroundImage: targetData.avatar != null
                            ? NetworkImage(targetData.avatar!)
                            : null,
                        child: targetData.avatar == null
                            ? Text(
                                MentoringHelpers.getInitials(targetData.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            request.requestStatus.icon,
                            size: 14,
                            color: request.requestStatus.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Name and relationship
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetData.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              request.relationshipType.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request.displayLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _StatusBadge(status: request.requestStatus),
                ],
              ),

              const SizedBox(height: 12),

              // Request Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(
                    (255 * 0.5).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Screens
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.phone_android,
                        label: request.hasAllScreens
                            ? 'All Screens'
                            : '${request.allowedScreens.length} screen${request.allowedScreens.length > 1 ? 's' : ''}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Duration
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.timer,
                        label: request.duration.label,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.access_time,
                        label: MentoringHelpers.formatTimeAgo(
                          request.requestedAt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Message Preview
              if (request.requestMessage?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.requestMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Response Message (if rejected)
              if (isRejected &&
                  (request.responseMessage?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((255 * 0.05).toInt()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withAlpha((255 * 0.2).toInt()),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.reply, size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.responseMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons
              if (isPending)
                _buildPendingActions(request, colorScheme)
              else if (isApproved)
                _buildApprovedActions(request, colorScheme)
              else if (isRejected)
                _buildRejectedActions(request, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActions(
    MentorshipConnection request,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Waiting Indicator
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Waiting for response...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Cancel Button
        OutlinedButton(
          onPressed: () => _handleCancel(request),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildApprovedActions(
    MentorshipConnection request,
    ColorScheme colorScheme,
  ) {
    return FilledButton.icon(
      onPressed: () => _navigateToViewMentee(request),
      icon: const Icon(Icons.visibility, size: 18),
      label: const Text('View Their Progress'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size(double.infinity, 44),
      ),
    );
  }

  Widget _buildRejectedActions(
    MentorshipConnection request,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Rejected Status
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 16, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text(
                  'Request Declined',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Request Again Button
        OutlinedButton.icon(
          onPressed: () => _handleRequestAgain(request),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Try Again'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(_OutgoingFilter filter) {
    switch (filter) {
      case _OutgoingFilter.pending:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noRequests,
          customEmoji: '📤',
          title: 'No Pending Requests',
          subtitle:
              'You don\'t have any outgoing requests waiting for response.',
        );
      case _OutgoingFilter.approved:
        return MentoringEmptyState(
          type: MentoringEmptyType.noActive,
          customEmoji: '✅',
          title: 'No Approved Requests',
          subtitle: 'None of your requests have been approved yet.',
          actionLabel: 'Send Request',
          onAction: () => _showRequestAccessMenu(context),
        );
      case _OutgoingFilter.rejected:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noRequests,
          customEmoji: '📋',
          title: 'No Rejected Requests',
          subtitle: 'None of your requests have been declined.',
        );
      case _OutgoingFilter.all:
        return MentoringEmptyState.noMentees(
          onRequestAccess: () => _showRequestAccessMenu(context),
        );
    }
  }

  Widget _buildFAB(ColorScheme colorScheme, bool isDarkMode) {
    return FloatingActionButton.extended(
      heroTag: 'outgoing_mentoring_request_fab',
      onPressed: () => _showRequestAccessMenu(context),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.person_add),
      label: const Text('New Request'),
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  List<MentorshipConnection> _getFilteredRequests(
    MentorshipProvider provider,
    _OutgoingFilter filter,
  ) {
    switch (filter) {
      case _OutgoingFilter.pending:
        return provider.allOutgoingRequests
            .where((r) => r.requestStatus == RequestStatus.pending)
            .toList();
      case _OutgoingFilter.approved:
        return provider.allOutgoingRequests
            .where((r) => r.requestStatus == RequestStatus.approved)
            .toList();
      case _OutgoingFilter.rejected:
        return provider.allOutgoingRequests
            .where((r) => r.requestStatus == RequestStatus.rejected)
            .toList();
      case _OutgoingFilter.all:
        return provider.allOutgoingRequests;
    }
  }

  int _getCountForTab(_OutgoingFilter filter, MentorshipProvider provider) {
    return _getFilteredRequests(provider, filter).length;
  }

  int _calculateSuccessRate(MentorshipProvider provider) {
    final approved = provider.myMentees
        .where((m) => m.requestType == RequestType.requestAccess)
        .length;
    final total = approved + provider.outgoingRequests.length;
    if (total == 0) return 0;
    return ((approved / total) * 100).round();
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await _profileRepository.getProfileById(userId);
      if (profile != null && mounted) {
        setState(() {
          _userProfiles[userId] = {
            'name': profile.username,
            'avatar': profile.profileUrl,
          };
        });
      }
    } catch (_) {}
  }

  _TargetDisplayData _getTargetDisplayData(MentorshipConnection request) {
    if (!_userProfiles.containsKey(request.ownerId)) {
      _userProfiles[request.ownerId] =
          {}; // Placeholder to prevent infinite loading
      _loadUserProfile(request.ownerId);
    }

    final profileData = _userProfiles[request.ownerId];
    final bool isLoaded = profileData != null && profileData.isNotEmpty;

    final relLabel =
        request.relationshipLabel == 'null' ||
            request.relationshipLabel?.isEmpty == true
        ? null
        : request.relationshipLabel;

    String fallbackName =
        relLabel ??
        '${request.relationshipType.ownerLabel} (${request.ownerId.substring(0, 6)})';

    return _TargetDisplayData(
      name:
          (isLoaded &&
              profileData['name'] != null &&
              profileData['name']!.isNotEmpty)
          ? profileData['name']!
          : fallbackName,
      avatar: isLoaded ? profileData['avatar'] : null,
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  void _showRequestDetails(MentorshipConnection request) {
    final targetData = _getTargetDisplayData(request);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OutgoingRequestDetailsSheet(
        request: request,
        targetName: targetData.name,
        targetAvatar: targetData.avatar,
        onCancel: request.isPending ? () => _handleCancel(request) : null,
        onViewProgress: request.isApproved
            ? () => _navigateToViewMentee(request)
            : null,
        onRequestAgain: request.isRejected
            ? () => _handleRequestAgain(request)
            : null,
      ),
    );
  }

  Future<void> _handleCancel(MentorshipConnection request) async {
    final provider = context.read<MentorshipProvider>();
    final targetData = _getTargetDisplayData(request);

    // Confirmation dialog
    final confirmed = await MentoringConfirmDialog.show(
      context,
      title: 'Cancel Request?',
      message:
          'Are you sure you want to cancel your access request to ${targetData.name}?',
      confirmLabel: 'Cancel Request',
      cancelLabel: 'Keep',
      confirmColor: Colors.red,
      icon: Icons.cancel,
      isDangerous: true,
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();

      final success = await provider.cancelRequest(request.id);

      if (success && mounted) {
        AppSnackbar.info(
          title: 'Request Cancelled',
          message: 'Request to ${targetData.name} cancelled',
        );
      }
    }
  }

  void _navigateToViewMentee(MentorshipConnection request) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewMenteeScreen(connection: request)),
    );
  }

  Future<void> _handleRequestAgain(MentorshipConnection request) async {
    // Pre-fill the request menu with previous values
    await RequestAccessMenu.show(
      context,
      targetUserId: request.ownerId,
      targetUserName: _getTargetDisplayData(request).name,
      onSubmit:
          ({
            required String targetUserId,
            required RelationshipType relationshipType,
            String? relationshipLabel,
            required List<AccessibleScreen> screens,
            required AccessDuration duration,
            String? message,
          }) async {
            final provider = context.read<MentorshipProvider>();
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

  Future<void> _showRequestAccessMenu(BuildContext context) async {
    final provider = context.read<MentorshipProvider>();
    final userRepo = ProfileRepository();

    await RequestAccessMenu.show(
      context,
      onSearchUsers: (query) async {
        final users = await userRepo.searchProfiles(query);
        return users
            .map(
              (u) => {'id': u.id, 'name': u.username, 'avatar': u.profileUrl},
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About Outgoing'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.send,
              color: Colors.blue,
              title: 'Outgoing Requests',
              description: 'Requests you sent to view others\' progress',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              title: 'Pending',
              description: 'Waiting for the other person to respond',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Approved',
              description: 'You can now view their progress',
            ),
            SizedBox(height: 12),
            _InfoRow(
              icon: Icons.cancel,
              color: Colors.red,
              title: 'Rejected',
              description: 'Request was declined',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// HELPER WIDGETS
// ================================================================

class _OutgoingTab {
  final String label;
  final _OutgoingFilter filter;
  final IconData icon;
  final Color color;

  const _OutgoingTab(this.label, this.filter, this.icon, this.color);
}

enum _OutgoingFilter { pending, approved, rejected, all }

class _TargetDisplayData {
  final String name;
  final String? avatar;

  const _TargetDisplayData({required this.name, this.avatar});
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final bool isPercentage;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 600),
          builder: (context, animValue, _) {
            return Text(
              isPercentage ? '$animValue%' : '$animValue',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            );
          },
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withAlpha((255 * 0.3).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Outgoing request details bottom sheet
class _OutgoingRequestDetailsSheet extends StatelessWidget {
  final MentorshipConnection request;
  final String targetName;
  final String? targetAvatar;
  final VoidCallback? onCancel;
  final VoidCallback? onViewProgress;
  final VoidCallback? onRequestAgain;

  const _OutgoingRequestDetailsSheet({
    required this.request,
    required this.targetName,
    this.targetAvatar,
    this.onCancel,
    this.onViewProgress,
    this.onRequestAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withAlpha((255 * 0.3).toInt()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: MentoringHelpers.getAvatarColor(targetName),
                  backgroundImage: targetAvatar != null
                      ? NetworkImage(targetAvatar!)
                      : null,
                  child: targetAvatar == null
                      ? Text(
                          MentoringHelpers.getInitials(targetName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusBadge(status: request.requestStatus),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    icon: Icons.handshake,
                    title: 'Relationship',
                    child: RelationshipBadge(
                      type: request.relationshipType,
                      customLabel: request.relationshipLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.phone_android,
                    title: 'Screens Requested',
                    child: PermissionChips(
                      screens: request.allowedScreens.screens,
                      size: PermissionChipSize.small,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.timer,
                    title: 'Duration',
                    value: request.duration.label,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    title: 'Requested On',
                    value: MentoringHelpers.formatDate(request.requestedAt),
                  ),
                  if (request.requestMessage?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.message,
                      title: 'Your Message',
                      value: request.requestMessage!,
                    ),
                  ],
                  if (request.respondedAt != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.done_all,
                      title: 'Responded On',
                      value: MentoringHelpers.formatDate(request.respondedAt),
                    ),
                  ],
                  if (request.responseMessage?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.reply,
                      title: 'Their Response',
                      value: request.responseMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: _buildActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (onViewProgress != null) {
      return FilledButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onViewProgress!();
        },
        icon: const Icon(Icons.visibility),
        label: const Text('View Their Progress'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    if (onCancel != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel!();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Request'),
            ),
          ),
        ],
      );
    }

    if (onRequestAgain != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRequestAgain!();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Request Again'),
            ),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('Close'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? child;

  const _DetailRow({
    required this.icon,
    required this.title,
    this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha((255 * 0.5).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (child != null)
                child!
              else
                Text(
                  value ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Extension for RequestStatus icon removed since it's now in the model.

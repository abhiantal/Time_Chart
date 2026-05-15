// ================================================================
// FILE: lib/features/mentoring/screen/incoming_requests_screen.dart
// Screen showing requests from others to view my progress
// Allows approving, customizing, or declining requests
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import '../widgets/mentoring_common_widgets.dart';
import '../widgets/mentoring_dialogs.dart';
import '../widgets/mentoring_utils.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../user_profile/create_edit_profile/profile_repository.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // User profile cache (same pattern as OutgoingRequestsScreen)
  final Map<String, Map<String, String?>> _userProfiles = {};
  final ProfileRepository _profileRepository = ProfileRepository();

  // Filter tabs
  static const List<_IncomingTab> _tabs = [
    _IncomingTab(
      'Pending',
      RequestStatus.pending,
      Icons.hourglass_empty,
      Colors.orange,
    ),
    _IncomingTab(
      'Approved',
      RequestStatus.approved,
      Icons.check_circle,
      Colors.green,
    ),
    _IncomingTab('Declined', RequestStatus.rejected, Icons.cancel, Colors.red),
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
                      tab.status,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Incoming Requests'),
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
        // Help Button
        IconButton(
          onPressed: () => _showHelpDialog(context),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildSummaryStats(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final pending = provider.allIncomingRequests
        .where((r) => r.requestStatus == RequestStatus.pending)
        .length;
    final approved = provider.allIncomingRequests
        .where((r) => r.requestStatus == RequestStatus.approved)
        .length;
    final declined = provider.allIncomingRequests
        .where((r) => r.requestStatus == RequestStatus.rejected)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
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
            color: colorScheme.outline.withValues(alpha: 0.2),
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
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          // Declined
          Expanded(
            child: _StatItem(
              icon: Icons.cancel,
              iconColor: Colors.red,
              value: declined,
              label: 'Declined',
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
          final count = _getCountForTab(tab.status, provider);
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
                      : colorScheme.outline.withValues(alpha: 0.2),
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
                            ? Colors.white.withValues(alpha: 0.3)
                            : tab.color.withValues(alpha: 0.15),
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
    RequestStatus status,
  ) {
    final requests = _getFilteredRequests(provider, status);

    // Loading state
    if (provider.isLoading && requests.isEmpty) {
      return MentoringLoadingState.cards(count: 3);
    }

    // Empty state
    if (requests.isEmpty) {
      return _buildEmptyState(status);
    }

    // Request list
    return RefreshIndicator(
      onRefresh: () => provider.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: requests.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildListHeader(
              theme,
              colorScheme,
              requests.length,
              status,
            );
          }
          final request = requests[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIncomingRequestCard(
              request,
              theme,
              colorScheme,
              isDarkMode,
              status,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncomingRequestCard(
    MentorshipConnection request,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
    RequestStatus status,
  ) {
    final requesterData = _getRequesterDisplayData(request);
    final isPending = status == RequestStatus.pending;

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
                  ? Colors.orange.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isPending ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
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
                          requesterData.name,
                        ),
                        backgroundImage: requesterData.avatar != null
                            ? NetworkImage(requesterData.avatar!)
                            : null,
                        child: requesterData.avatar == null
                            ? Text(
                                MentoringHelpers.getInitials(
                                  requesterData.name,
                                ),
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
                          requesterData.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'wants to view your progress',
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
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
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

              // Response message (if already responded)
              if (!isPending &&
                  (request.responseMessage?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        (status == RequestStatus.approved
                                ? Colors.green
                                : Colors.red)
                            .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          (status == RequestStatus.approved
                                  ? Colors.green
                                  : Colors.red)
                              .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.reply,
                        size: 14,
                        color: status == RequestStatus.approved
                            ? Colors.green.shade400
                            : Colors.red.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.responseMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: status == RequestStatus.approved
                                ? Colors.green.shade400
                                : Colors.red.shade400,
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
              else if (status == RequestStatus.approved)
                _buildApprovedStatus(colorScheme)
              else
                _buildDeclinedStatus(colorScheme),
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
        // Accept
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleAccept(request),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Accept'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Customize
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleCustomize(request),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Customize'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Decline
        IconButton(
          onPressed: () => _handleDecline(request),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedStatus(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
          const SizedBox(width: 8),
          Text(
            'Access Granted',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedStatus(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildListHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    int count,
    RequestStatus status,
  ) {
    final tab = _tabs.firstWhere((t) => t.status == status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tab.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tab.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 16, color: tab.color),
                const SizedBox(width: 6),
                Text(
                  '$count ${tab.label.toLowerCase()} request${count == 1 ? '' : 's'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tab.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (status == RequestStatus.pending && count > 1)
            TextButton.icon(
              onPressed: () => _showBulkActionsMenu(context),
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Bulk Actions'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noRequests,
          title: 'No Pending Requests',
          subtitle:
              'You don\'t have any access requests waiting for your approval.',
          customEmoji: '📭',
        );
      case RequestStatus.approved:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noRequests,
          title: 'No Approved Requests',
          subtitle: 'You haven\'t approved any access requests yet.',
          customEmoji: '📋',
        );
      case RequestStatus.rejected:
        return const MentoringEmptyState(
          type: MentoringEmptyType.noRequests,
          title: 'No Declined Requests',
          subtitle: 'You haven\'t declined any access requests.',
          customEmoji: '📋',
        );
      default:
        return MentoringEmptyState.noRequests();
    }
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  List<MentorshipConnection> _getFilteredRequests(
    MentorshipProvider provider,
    RequestStatus status,
  ) {
    return provider.allIncomingRequests
        .where((r) => r.requestStatus == status)
        .toList();
  }

  int _getCountForTab(RequestStatus status, MentorshipProvider provider) {
    return _getFilteredRequests(provider, status).length;
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

  _RequesterDisplayData _getRequesterDisplayData(MentorshipConnection request) {
    // Use mentorId — the person who sent the incoming request
    final requesterId = request.mentorId;

    if (!_userProfiles.containsKey(requesterId)) {
      _userProfiles[requesterId] =
          {}; // Placeholder to prevent infinite loading
      _loadUserProfile(requesterId);
    }

    final profileData = _userProfiles[requesterId];
    final bool isLoaded = profileData != null && profileData.isNotEmpty;

    final relLabel =
        request.relationshipLabel == 'null' ||
            request.relationshipLabel?.isEmpty == true
        ? null
        : request.relationshipLabel;

    final fallbackName =
        relLabel ??
        '${request.relationshipType.mentorLabel} (${requesterId.substring(0, 6)})';

    return _RequesterDisplayData(
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
    final requesterData = _getRequesterDisplayData(request);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IncomingRequestDetailsSheet(
        request: request,
        requesterName: requesterData.name,
        requesterAvatar: requesterData.avatar,
        onAccept: request.isPending ? () => _handleAccept(request) : null,
        onCustomize: request.isPending ? () => _handleCustomize(request) : null,
        onDecline: request.isPending ? () => _handleDecline(request) : null,
      ),
    );
  }

  Future<void> _handleAccept(MentorshipConnection request) async {
    final provider = context.read<MentorshipProvider>();
    final requesterData = _getRequesterDisplayData(request);

    HapticFeedback.mediumImpact();

    final success = await provider.approveRequest(request.id);

    if (success && mounted) {
      AppSnackbar.success('Access granted to ${requesterData.name}');
    }
  }

  Future<void> _handleCustomize(MentorshipConnection request) async {
    final provider = context.read<MentorshipProvider>();
    final requesterData = _getRequesterDisplayData(request);

    final result = await AcceptRequestDialog.show(
      context,
      request: request,
      requesterName: requesterData.name,
      requesterAvatar: requesterData.avatar,
      onAccept:
          ({
            MentorshipPermissions? customPermissions,
            List<AccessibleScreen>? customScreens,
            String? responseMessage,
          }) async {
            return await provider.approveRequest(
              request.id,
              customPermissions: customPermissions,
              customScreens: customScreens,
              responseMessage: responseMessage,
            );
          },
    );

    if (result == true && mounted) {
      HapticFeedback.mediumImpact();
      AppSnackbar.success('Customized access granted to ${requesterData.name}');
    }
  }

  Future<void> _handleDecline(MentorshipConnection request) async {
    final provider = context.read<MentorshipProvider>();
    final requesterData = _getRequesterDisplayData(request);

    final result = await DeclineRequestDialog.show(
      context,
      request: request,
      requesterName: requesterData.name,
      onDecline: (reason) async {
        return await provider.rejectRequest(request.id, reason: reason);
      },
    );

    if (result == true && mounted) {
      HapticFeedback.mediumImpact();
      AppSnackbar.info(
        title: 'Request Declined',
        message: 'Request from ${requesterData.name} declined',
      );
    }
  }

  void _showBulkActionsMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bulk Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            // Options
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green),
              ),
              title: const Text('Accept All'),
              subtitle: const Text('Approve all pending requests'),
              onTap: () {
                Navigator.pop(context);
                _handleBulkAccept();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cancel, color: Colors.red),
              ),
              title: const Text('Decline All'),
              subtitle: const Text('Reject all pending requests'),
              onTap: () {
                Navigator.pop(context);
                _handleBulkDecline();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBulkAccept() async {
    final provider = context.read<MentorshipProvider>();
    final requests = provider.incomingRequests;

    if (requests.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Accept All?'),
          ],
        ),
        content: Text(
          'This will approve ${requests.length} pending request${requests.length > 1 ? 's' : ''} with default permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      int successCount = 0;
      for (final request in requests) {
        final success = await provider.approveRequest(request.id);
        if (success) successCount++;
      }
      if (mounted) {
        AppSnackbar.success(
          'Approved $successCount request${successCount > 1 ? 's' : ''}',
        );
      }
    }
  }

  Future<void> _handleBulkDecline() async {
    final provider = context.read<MentorshipProvider>();
    final requests = provider.incomingRequests;

    if (requests.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text('Decline All?'),
          ],
        ),
        content: Text(
          'This will reject ${requests.length} pending request${requests.length > 1 ? 's' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      int successCount = 0;
      for (final request in requests) {
        final success = await provider.rejectRequest(request.id);
        if (success) successCount++;
      }
      if (mounted) {
        AppSnackbar.info(
          title: 'Requests Declined',
          message:
              'Declined $successCount request${successCount > 1 ? 's' : ''}',
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
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
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About Requests'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpRow(
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              title: 'Pending',
              description: 'Requests waiting for your decision',
            ),
            SizedBox(height: 12),
            _HelpRow(
              icon: Icons.check_circle,
              color: Colors.green,
              title: 'Accept',
              description: 'Grant access to view your progress',
            ),
            SizedBox(height: 12),
            _HelpRow(
              icon: Icons.tune,
              color: Colors.blue,
              title: 'Customize',
              description: 'Modify permissions before accepting',
            ),
            SizedBox(height: 12),
            _HelpRow(
              icon: Icons.cancel,
              color: Colors.red,
              title: 'Decline',
              description: 'Reject the access request',
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

class _IncomingTab {
  final String label;
  final RequestStatus status;
  final IconData icon;
  final Color color;

  const _IncomingTab(this.label, this.status, this.icon, this.color);
}

class _RequesterDisplayData {
  final String name;
  final String? avatar;

  const _RequesterDisplayData({required this.name, this.avatar});
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
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
              '$animValue',
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
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
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

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _HelpRow({
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
            color: color.withValues(alpha: 0.1),
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

/// Incoming request details bottom sheet
class _IncomingRequestDetailsSheet extends StatelessWidget {
  final MentorshipConnection request;
  final String requesterName;
  final String? requesterAvatar;
  final VoidCallback? onAccept;
  final VoidCallback? onCustomize;
  final VoidCallback? onDecline;

  const _IncomingRequestDetailsSheet({
    required this.request,
    required this.requesterName,
    this.requesterAvatar,
    this.onAccept,
    this.onCustomize,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              color: colorScheme.outline.withValues(alpha: 0.3),
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
                  backgroundColor: MentoringHelpers.getAvatarColor(
                    requesterName,
                  ),
                  backgroundImage: requesterAvatar != null
                      ? NetworkImage(requesterAvatar!)
                      : null,
                  child: requesterAvatar == null
                      ? Text(
                          MentoringHelpers.getInitials(requesterName),
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
                        requesterName,
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
                      size: PermissionChipSize.medium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.timer,
                    title: 'Duration',
                    value: request.duration.label,
                    subtitle: request.duration.description,
                  ),
                  if (request.requestMessage?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.message,
                      title: 'Message',
                      value: request.requestMessage!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time,
                    title: 'Requested',
                    value: MentoringHelpers.formatTimeAgo(request.requestedAt),
                  ),
                  if (request.respondedAt != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.done_all,
                      title: 'Responded',
                      value: MentoringHelpers.formatTimeAgo(
                        request.respondedAt,
                      ),
                    ),
                  ],
                  if (request.responseMessage?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.reply,
                      title: 'Your Response',
                      value: request.responseMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          if (onAccept != null || onCustomize != null || onDecline != null) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  if (onDecline != null)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDecline!();
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (onCustomize != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onCustomize!();
                        },
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Customize'),
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (onAccept != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onAccept!();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Widget? child;

  const _DetailRow({
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
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
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
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
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

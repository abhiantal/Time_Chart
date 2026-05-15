// ================================================================
// FILE: lib/features/mentoring/screen/mentoring_hub_screen.dart
// Main entry point for the mentoring feature
// Shows overview of mentors, mentees, and pending requests
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../user_profile/create_edit_profile/profile_repository.dart';
import 'package:the_time_chart/features/analytics/dashboard_sidebar.dart';

import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import '../../../../widgets/feature_info_widgets.dart';
import '../widgets/mentoring_cards.dart';
import '../widgets/mentoring_common_widgets.dart';
import '../widgets/mentoring_menus.dart';
import '../widgets/mentoring_utils.dart';

// Import your screen (will be created next)
import 'my_mentors_screen.dart';
import 'my_mentees_screen.dart';
import 'incoming_requests_screen.dart';
import 'outgoing_requests_screen.dart';
import 'view_mentee_screen.dart';
import 'access_settings_screen.dart';

class MentoringHubScreen extends StatefulWidget {
  const MentoringHubScreen({super.key});

  @override
  State<MentoringHubScreen> createState() => _MentoringHubScreenState();
}

class _MentoringHubScreenState extends State<MentoringHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Removed local profile cache as MentorshipProvider handles it now

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Initialize provider if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final provider = context.read<MentorshipProvider>();
    // Provider should already be initialized from app startup
    // But refresh to ensure latest data
    await provider.refreshAll();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          if (provider.isLoading && !provider.hasAnyMentorship) {
            return MentoringLoadingState.hub();
          }

          if (provider.error != null && !provider.hasAnyMentorship) {
            return MentoringEmptyState.error(
              message: provider.error,
              onRetry: () => provider.refreshAll(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!provider.hasAnyMentorship) ...[
                        const SizedBox(height: 20),
                        FeatureInfoCard(feature: EliteFeatures.mentoring),
                        const SizedBox(height: 32),
                      ],

                      // Stats Overview Cards
                      _buildStatsSection(
                        provider,
                        theme,
                        colorScheme,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // Pending Requests Alert
                      if (provider.hasPendingRequests)
                        _buildPendingRequestsSection(
                          provider,
                          theme,
                          colorScheme,
                        ),

                      if (provider.hasPendingRequests)
                        const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActionsSection(theme, colorScheme, isDarkMode),

                      const SizedBox(height: 24),

                      // Recent Activity / Mentees Needing Attention
                      if (provider.activeMentees.isNotEmpty)
                        _buildMenteesAttentionSection(
                          provider,
                          theme,
                          colorScheme,
                        ),

                      if (provider.activeMentees.isNotEmpty)
                        const SizedBox(height: 24),

                      // Active Mentors Preview
                      if (provider.activeMentors.isNotEmpty)
                        _buildMentorsPreviewSection(
                          provider,
                          theme,
                          colorScheme,
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => DashboardSidebarController.to.toggleSidebar(),
          ),
          const SizedBox(width: 10),
          const Text('Mentoring'),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => FeatureInfoCard.showEliteDialog(
            context,
            EliteFeatures.mentoring,
          ),
          icon: Icon(
            Icons.help_outline_rounded,
            color: colorScheme.onSurface.withOpacity(0.6),
            size: 22,
          ),
          tooltip: 'How It Works',
        ),
        // Notification Badge
        Consumer<MentorshipProvider>(
          builder: (context, provider, _) {
            final pendingCount = provider.pendingIncomingCount;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => _navigateToIncomingRequests(context),
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Requests',
                ),
                if (pendingCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // More Options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'outgoing',
              child: Row(
                children: [
                  Icon(Icons.outbox, size: 20),
                  SizedBox(width: 12),
                  Text('Outgoing Requests'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'incoming',
              child: Row(
                children: [
                  Icon(Icons.move_to_inbox, size: 20),
                  SizedBox(width: 12),
                  Text('Incoming Requests'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'request',
              child: Row(
                children: [
                  Icon(Icons.person_add_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Request Access'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.ios_share, size: 20),
                  SizedBox(width: 12),
                  Text('Share My Access'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 12),
                  Text('How It Works'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (provider.isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats Cards Row — use actual list counts for accurate data
        Row(
          children: [
            // My Mentors Card
            Expanded(
              child: _StatsCard(
                icon: Icons.supervisor_account,
                iconColor: Colors.blue,
                gradient: MentoringColors.getGradient('mentor', isDarkMode),
                title: 'My Mentors',
                count: provider.myMentors.length,
                subtitle: '${provider.activeMentors.length} active',
                onTap: () => _navigateToMyMentors(context),
              ),
            ),
            const SizedBox(width: 12),
            // My Mentees Card
            Expanded(
              child: _StatsCard(
                icon: Icons.school,
                iconColor: Colors.green,
                gradient: MentoringColors.getGradient('mentee', isDarkMode),
                title: 'My Mentees',
                count: provider.myMentees.length,
                subtitle: '${provider.activeMentees.length} active',
                onTap: () => _navigateToMyMentees(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingRequestsSection(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Requests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Incoming Requests
        if (provider.pendingIncomingCount > 0)
          _PendingAlertCard(
            icon: Icons.arrow_downward,
            iconColor: Colors.orange,
            title:
                '${provider.pendingIncomingCount} incoming request${provider.pendingIncomingCount > 1 ? 's' : ''}',
            subtitle: 'People waiting for your approval',
            onTap: () => _navigateToIncomingRequests(context),
          ),

        if (provider.pendingIncomingCount > 0 &&
            provider.pendingOutgoingCount > 0)
          const SizedBox(height: 8),

        // Outgoing Requests
        if (provider.pendingOutgoingCount > 0)
          _PendingAlertCard(
            icon: Icons.arrow_upward,
            iconColor: Colors.blue,
            title:
                '${provider.pendingOutgoingCount} outgoing request${provider.pendingOutgoingCount > 1 ? 's' : ''}',
            subtitle: 'Waiting for response',
            onTap: () => _navigateToOutgoingRequests(context),
          ),

        // Pending Offers
        if (provider.pendingOffersCount > 0) ...[
          const SizedBox(height: 8),
          _PendingAlertCard(
            icon: Icons.card_giftcard,
            iconColor: Colors.purple,
            title:
                '${provider.pendingOffersCount} access offer${provider.pendingOffersCount > 1 ? 's' : ''}',
            subtitle: 'Someone wants to share with you',
            onTap: () => _navigateToIncomingRequests(context),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Request Access Button
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person_add_alt_1,
                label: 'Request Access',
                description: 'Monitor someone',
                gradient: MentoringColors.getGradient('request', isDarkMode),
                onTap: () => _showRequestAccessMenu(context),
              ),
            ),
            const SizedBox(width: 12),
            // Share Access Button
            Expanded(
              child: _QuickActionButton(
                icon: Icons.share,
                label: 'Share Access',
                description: 'Let someone monitor you',
                gradient: MentoringColors.getGradient('mentee', isDarkMode),
                onTap: () => _showShareAccessMenu(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenteesAttentionSection(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final menteesNeedingAttention = provider.getMenteesNeedingAttention();
    final displayMentees = menteesNeedingAttention.take(3).toList();

    if (displayMentees.isEmpty && provider.activeMentees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (menteesNeedingAttention.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              menteesNeedingAttention.isNotEmpty
                  ? 'Needs Attention'
                  : 'Active Mentees',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _navigateToMyMentees(context),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Display mentees needing attention or active mentees
        if (displayMentees.isNotEmpty)
          ...displayMentees.map((connection) {
            final profile = provider.getUserProfile(connection.ownerId);
            final name =
                (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ??
                connection.relationshipLabel ??
                'Mentee ${connection.ownerId.substring(0, 6)}';
            final avatar = profile?.profileUrl;
            final streak = connection.cachedSnapshot['streak'] as int?;
            final points = connection.cachedSnapshot['points'] as int?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MenteeCard(
                connection: connection,
                menteeName: name,
                menteeAvatar: avatar,
                currentStreak: streak,
                totalPoints: points,
                compact: true,
                showQuickStats: false,
                showActions: false,
                onTap: () => _navigateToViewMentee(context, connection),
              ),
            );
          })
        else
          ...provider.activeMentees.take(2).map((connection) {
            final profile = provider.getUserProfile(connection.ownerId);
            final name =
                (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ??
                connection.relationshipLabel ??
                'Mentee ${connection.ownerId.substring(0, 6)}';
            final avatar = profile?.profileUrl;
            final streak = connection.cachedSnapshot['streak'] as int?;
            final points = connection.cachedSnapshot['points'] as int?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MenteeCard(
                connection: connection,
                menteeName: name,
                menteeAvatar: avatar,
                currentStreak: streak,
                totalPoints: points,
                compact: true,
                showQuickStats: false,
                showActions: false,
                onTap: () => _navigateToViewMentee(context, connection),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMentorsPreviewSection(
    MentorshipProvider provider,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final displayMentors = provider.activeMentors.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active Mentors',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _navigateToMyMentors(context),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...displayMentors.map((connection) {
          final profile = provider.getUserProfile(connection.mentorId);
          final name =
              (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ??
              connection.relationshipLabel ??
              'Mentor ${connection.mentorId.substring(0, 6)}';
          final avatar = profile?.profileUrl;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MentorCard(
              connection: connection,
              mentorName: name,
              mentorAvatar: avatar,
              compact: true,
              showActions: false,
              onTap: () => _navigateToAccessSettings(context, connection),
            ),
          );
        }),
      ],
    );
  }

  // ================================================================
  // NAVIGATION METHODS
  // ================================================================

  void _navigateToMyMentors(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyMentorsScreen()),
    ).then((_) {
      // Refresh when returning to keep data in sync
      if (mounted) {
        context.read<MentorshipProvider>().refreshAll();
      }
    });
  }

  void _navigateToMyMentees(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyMenteesScreen()),
    ).then((_) {
      // Refresh when returning to keep data in sync
      if (mounted) {
        context.read<MentorshipProvider>().refreshAll();
      }
    });
  }

  void _navigateToIncomingRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IncomingRequestsScreen()),
    );
  }

  void _navigateToOutgoingRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OutgoingRequestsScreen()),
    );
  }

  void _navigateToViewMentee(
    BuildContext context,
    MentorshipConnection connection,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewMenteeScreen(connection: connection),
      ),
    );
  }

  void _navigateToAccessSettings(
    BuildContext context,
    MentorshipConnection connection,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccessSettingsScreen(connection: connection),
      ),
    );
  }

  // ================================================================
  // ACTION METHODS
  // ================================================================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'refresh':
        context.read<MentorshipProvider>().refreshAll();
        HapticFeedback.mediumImpact();
        break;
      case 'outgoing':
        _navigateToOutgoingRequests(context);
        break;
      case 'incoming':
        _navigateToIncomingRequests(context);
        break;
      case 'request':
        _showRequestAccessMenu(context);
        break;
      case 'share':
        _showShareAccessMenu(context);
        break;
      case 'help':
        FeatureInfoCard.showEliteDialog(context, EliteFeatures.mentoring);
        break;
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

  Future<void> _showShareAccessMenu(BuildContext context) async {
    final provider = context.read<MentorshipProvider>();
    final userRepo = ProfileRepository();

    await ShareAccessMenu.show(
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
// HELPER WIDGETS
// ================================================================

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final String title;
  final int count;
  final String subtitle;
  final VoidCallback onTap;

  const _StatsCard({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient.first.withAlpha((255 * 0.15).toInt()),
                gradient.last.withAlpha((255 * 0.05).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient.first.withAlpha((255 * 0.2).toInt()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: count),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    '$value',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingAlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PendingAlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: iconColor.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withAlpha((255 * 0.2).toInt())),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((255 * 0.15).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha((255 * 0.3).toInt()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha((255 * 0.8).toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

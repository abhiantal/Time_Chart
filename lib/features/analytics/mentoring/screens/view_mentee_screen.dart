// ================================================================
// FILE: lib/features/mentoring/screen/view_mentee_screen.dart
// Screen to view a mentee's progress with their allowed screen
// Shows their data filtered by permissions granted
// ================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/logger.dart';

import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import '../../dashboard/repositories/user_dashboard_repository.dart';
import '../../dashboard/providers/user_dashboard_provider.dart';
import '../../competition/providers/competition_provider.dart';
import '../../dashboard/screens/dashboard_home_screen.dart';
import '../../dashboard/screens/mood_detail_screen.dart';
import '../../dashboard/screens/overview_detail_screen.dart';
import '../../dashboard/screens/rewards_detail_screen.dart';
import '../widgets/mentoring_dialogs.dart';
import '../widgets/mentoring_utils.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../chats/widgets/common/user_avatar_cached.dart';

class ViewMenteeScreen extends StatefulWidget {
  final MentorshipConnection connection;

  const ViewMenteeScreen({super.key, required this.connection});

  @override
  State<ViewMenteeScreen> createState() => _ViewMenteeScreenState();
}

class _ViewMenteeScreenState extends State<ViewMenteeScreen> {
  late MentorshipConnection _connection;
  List<AccessibleScreen> _navScreens = [];

  // Mentee data (would come from their profile/leaderboard)
  Map<String, dynamic> _menteeData = {};

  // Auto-refresh timer for live mode
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;

    // Hub screens (ensure dashboard is first if not present)
    final baseScreens = List<AccessibleScreen>.from(_connection.allowedScreens.screens);
    if (!baseScreens.contains(AccessibleScreen.dashboard)) {
      baseScreens.insert(0, AccessibleScreen.dashboard);
    }
    _navScreens = baseScreens;

    _logView();

    // Load mentee profile and data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MentorshipProvider>().loadProfilesForUsers([
          _connection.ownerId,
        ]);
      }
    });

    _loadMenteeData();

    // Start auto-refresh if live mode
    if (_connection.isLiveEnabled && _connection.isActive) {
      _startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _navigateToScreen(
    AccessibleScreen screen,
    UserDashboardProvider provider,
  ) {
    HapticFeedback.selectionClick();
    _logView(screen: screen.value);

    Widget destination;
    switch (screen) {
      case AccessibleScreen.dashboard:
        destination = const DashboardHomeScreen();
        break;
      case AccessibleScreen.mood:
        destination = const MoodDetailScreen();
        break;
      case AccessibleScreen.rewards:
        destination = const RewardsDetailScreen();
        break;
      case AccessibleScreen.stats:
        destination = const OverviewDetailScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadMenteeData(silent: true),
    );
  }

  Future<void> _logView({String? screen}) async {
    final provider = context.read<MentorshipProvider>();
    final firstScreen = _connection.allowedScreens.isNotEmpty
        ? _connection.allowedScreens.first.value
        : 'dashboard';

    await provider.logScreenView(_connection.id, screen: screen ?? firstScreen);
  }

  Future<void> _loadMenteeData({bool silent = false}) async {
    try {
      final dashboard = await UserDashboardRepository()
          .getUserDashboardByUserId(_connection.ownerId);

      if (dashboard == null) {
        return;
      }

      // Map dashboard data to the format expected by the UI components
      final data = <String, dynamic>{};

      if (_connection.permissions.showPoints) {
        data['points'] = dashboard.overview.summary.totalPoints;
      }
      if (_connection.permissions.showStreak) {
        data['streak'] = dashboard.overview.summary.currentStreak;
      }
      if (_connection.permissions.showRank) {
        data['rank'] = dashboard.overview.summary.globalRank;
      }

      // Tasks and Goals stats
      data['tasksCompleted'] = dashboard.today.summary.completed;
      data['tasksTotal'] = dashboard.today.summary.totalScheduledTask;
      data['goalsActive'] = dashboard.activeItems.activeLongGoals.length;
      data['goalsCompleted'] = dashboard.overview.summary.totalPoints > 0
          ? (dashboard.overview.summary.totalPoints / 100).floor()
          : 0;

      if (_connection.permissions.showTasks &&
          _connection.permissions.showTaskDetails) {
        data['recentTasks'] = dashboard.recentActivity
            .where((a) => a.type == 'task')
            .take(5)
            .map((a) => {'name': a.message, 'status': 'completed'})
            .toList();
      }

      if (_connection.permissions.showGoals &&
          _connection.permissions.showGoalDetails) {
        data['goals'] = [];
      }

      if (_connection.permissions.showMood) {
        data['currentMood'] = dashboard.mood.mostCommonMood;
        data['moodTrend'] = 'stable'; // Default mapping if no better logic
      }

      if (_connection.permissions.showRewards) {
        data['badges'] = dashboard.rewards.summary.totalRewardsEarned;
        data['achievements'] = dashboard.rewards.unlockedRewards.length;
      }

      if (_connection.permissions.showProgress) {
        data['overallProgress'] = dashboard.overview.summary.completionRateAll
            .round();
        data['weeklyProgress'] = dashboard.overview.summary.completionRateWeek
            .round();
      }

      // Add last active timestamp
      data['lastActive'] = dashboard.updatedAt?.toIso8601String();

      if (mounted) {
        setState(() {
          _menteeData = data;
        });

        // Update cached snapshot
        final provider = context.read<MentorshipProvider>();
        await provider.updateSnapshot(_connection.id, data);
      }
    } catch (e, stack) {
      logE('Error loading mentee data', error: e, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              UserDashboardProvider(repository: UserDashboardRepository())
                ..initialize(_connection.ownerId),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BattleChallengeProvider()..initialize(_connection.ownerId),
        ),
      ],
      child: Consumer2<UserDashboardProvider, MentorshipProvider>(
        builder: (context, dashboardProvider, mentorshipProvider, child) {
          final profile = mentorshipProvider.getUserProfile(
            _connection.ownerId,
          );
          final menteeName =
              (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ?? _connection.relationshipLabel ?? 'Mentee';
          final menteeAvatar = profile?.profileUrl;

          // Check if access is still valid
          if (!_connection.canAccess) {
            return _buildAccessExpiredScreen(theme, colorScheme);
          }

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: _buildAppBar(
              theme,
              colorScheme,
              isDarkMode,
              menteeName,
              menteeAvatar,
            ),
            body: Column(
              children: [
                // Live Status Banner
                if (_connection.isLiveEnabled)
                  _buildLiveBanner(theme, colorScheme),

                // Navigation Hub (Premium Grid)
                Expanded(
                  child: _navScreens.isEmpty
                      ? Center(
                          child: Text(
                            'No screens accessible',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : _buildNavigationHub(
                          theme,
                          colorScheme,
                          dashboardProvider,
                        ),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(theme, colorScheme),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
    String menteeName,
    String? menteeAvatar,
  ) {
    return AppBar(
      title: Row(
        children: [
          UserAvatarCached(name: menteeName, imageUrl: menteeAvatar, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menteeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _connection.relationshipType.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connection.displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Refresh Button
        IconButton(
          onPressed: () {
            context.read<UserDashboardProvider>().refreshDashboard(
              _connection.ownerId,
            );
            context.read<BattleChallengeProvider>().initialize(
              _connection.ownerId,
            );
            _loadMenteeData(silent: true);
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh All',
        ),
        // More Options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'encourage',
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 20, color: Colors.pink.shade400),
                  const SizedBox(width: 12),
                  const Text('Send Encouragement'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'permissions',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 12),
                  Text('View Permissions'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Connection Info'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.orange.shade400],
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * value).toInt()),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha((127 * value).toInt()),
                      blurRadius: 4 * value,
                      spreadRadius: 1 * value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Live • Updated: ${_getLastUpdateLabel()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withAlpha(230),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Connection status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_cellular_4_bar,
                  size: 12,
                  color: Colors.white.withAlpha(230),
                ),
                const SizedBox(width: 4),
                Text(
                  'Connected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha(230),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHub(
    ThemeData theme,
    ColorScheme colorScheme,
    UserDashboardProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Data',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a category to view detailed analytics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _navScreens.length,
              itemBuilder: (context, index) {
                final screen = _navScreens[index];
                final bgColor = _getScreenColor(screen, colorScheme);

                return InkWell(
                  onTap: () => _navigateToScreen(screen, provider),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: bgColor.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            screen.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          screen.label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getScreenColor(AccessibleScreen screen, ColorScheme colorScheme) {
    switch (screen) {
      case AccessibleScreen.dashboard:
        return Colors.blue;
      case AccessibleScreen.mood:
        return Colors.orange;
      case AccessibleScreen.rewards:
        return Colors.purple;
      case AccessibleScreen.stats:
        return Colors.green;
    }
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Encourage Button
          Expanded(
            child: FilledButton.icon(
              onPressed: _showEncouragementDialog,
              icon: const Icon(Icons.favorite, size: 18),
              label: const Text('Encourage'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Last Active Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Active ${_getLastActiveLabel()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessExpiredScreen(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Access Expired')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha((255 * 0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_off,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Expired',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your access to view this person\'s progress has expired or been revoked.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  String _getMenteeName() {
    final provider = context.read<MentorshipProvider>();
    final profile = provider.getUserProfile(_connection.ownerId);

    // If profile has a name, use that and maybe add relationship label
    if (profile != null && (profile.displayName.isNotEmpty || profile.username.isNotEmpty)) {
      final nameToUse = profile.displayName.isNotEmpty ? profile.displayName : profile.username;
      if (_connection.relationshipLabel?.isNotEmpty ?? false) {
        return '$nameToUse (${_connection.relationshipLabel})';
      }
      return nameToUse;
    }

    // Fallback to relationship label if profile not available
    if (_connection.relationshipLabel?.isNotEmpty ?? false) {
      return _connection.relationshipLabel!;
    }

    return '${_connection.relationshipType.ownerLabel} (${_connection.ownerId.substring(0, 6)})';
  }

  String _getLastUpdateLabel() {
    if (_menteeData.isEmpty) return 'Never';
    return 'Just now';
  }

  String _getLastActiveLabel() {
    final lastActiveVal = _menteeData['lastActive'];
    if (lastActiveVal == null) return 'Unknown';

    DateTime? lastActive;
    if (lastActiveVal is String) {
      lastActive = DateTime.tryParse(lastActiveVal);
    } else if (lastActiveVal is DateTime) {
      lastActive = lastActiveVal;
    }

    if (lastActive == null) return 'Unknown';
    return MentoringHelpers.formatTimeAgo(lastActive);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'encourage':
        _showEncouragementDialog();
        break;
      case 'permissions':
        _showPermissionsDialog();
        break;
      case 'info':
        _showConnectionInfoDialog();
        break;
    }
  }

  Future<void> _showEncouragementDialog() async {
    final mentorshipProvider = context.read<MentorshipProvider>();
    final profile = mentorshipProvider.getUserProfile(_connection.ownerId);
    final menteeName = (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ?? _getMenteeName();
    final menteeAvatar = profile?.profileUrl;

    final result = await SendEncouragementDialog.show(
      context,
      connection: _connection,
      menteeName: menteeName,
      menteeAvatar: menteeAvatar,
      onSend: (type, message) async {
        return await mentorshipProvider.sendEncouragement(
          _connection.id,
          type: type,
          message: message,
        );
      },
    );

    if (result == true && mounted) {
      HapticFeedback.mediumImpact();
      AppSnackbar.success('Encouragement sent to ${_getMenteeName()}!');
    }
  }

  void _showPermissionsDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Your Permissions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'What you can see in this mentee\'s data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Screens
              Text(
                'Screens',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _connection.allowedScreens.map((screen) {
                  return Chip(
                    avatar: Icon(screen.icon, size: 16),
                    label: Text(screen.label),
                    backgroundColor: colorScheme.primaryContainer.withAlpha(
                      (255 * 0.5).toInt(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Details
              Text(
                'Visible Details',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _connection.permissions.summaryLabel,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got It'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _showConnectionInfoDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Connection Info',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(label: 'Relationship', value: _connection.displayLabel),
              const Divider(height: 24),
              _InfoRow(
                label: 'Status',
                value: _connection.accessStatus.label,
                valueColor: _connection.accessStatus.color,
              ),
              const Divider(height: 24),
              _InfoRow(label: 'Duration', value: _connection.duration.label),
              const Divider(height: 24),
              _InfoRow(
                label: 'Expires',
                value: _connection.hasExpiration
                    ? MentoringHelpers.formatDate(_connection.expiresAt)
                    : 'Never',
              ),
              const Divider(height: 24),
              _InfoRow(label: 'Your Views', value: '${_connection.viewCount}'),
              const Divider(height: 24),
              _InfoRow(
                label: 'Encouragements Sent',
                value: '${_connection.encouragementCount}',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        );
      },
    );
  }
}

// ================================================================
// HELPER WIDGETS
// ================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

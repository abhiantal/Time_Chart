// ================================================================
// FILE: lib/features/mentoring/screen/access_settings_screen.dart
// Screen for managing mentorship settings (permissions, screen, duration)
// Only accessible by the owner (person being monitored)
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
import '../../../../user_profile/create_edit_profile/profile_widgets.dart';

class AccessSettingsScreen extends StatefulWidget {
  final MentorshipConnection connection;

  const AccessSettingsScreen({super.key, required this.connection});

  @override
  State<AccessSettingsScreen> createState() => _AccessSettingsScreenState();
}

class _AccessSettingsScreenState extends State<AccessSettingsScreen> {
  late MentorshipConnection _connection;
  bool _isLoading = false;
  bool _isLiveEnabled = true;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
    _isLiveEnabled = widget.connection.isLiveEnabled;

    // Ensure profile is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorshipProvider>().loadProfilesForUsers([
        _connection.mentorId,
      ]);
    });
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
        builder: (context, provider, _) {
          // Update connection from provider if it exists
          final updatedConnection = provider.myMentors.firstWhere(
            (m) => m.id == widget.connection.id,
            orElse: () => _connection,
          );
          _connection = updatedConnection;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(theme, colorScheme, isDarkMode),

                const SizedBox(height: 24),

                // Allowed Screens
                _buildSectionTitle(
                  theme,
                  'ALLOWED SCREENS',
                  Icons.phone_android,
                ),
                const SizedBox(height: 12),
                _buildScreensSection(theme, colorScheme),

                const SizedBox(height: 24),

                // Visible Details
                _buildSectionTitle(theme, 'VISIBLE DETAILS', Icons.visibility),
                const SizedBox(height: 12),
                _buildPermissionsSection(theme, colorScheme),

                const SizedBox(height: 24),

                // Live Access
                _buildSectionTitle(theme, 'LIVE ACCESS', Icons.sensors),
                const SizedBox(height: 12),
                _buildLiveAccessSection(theme, colorScheme),

                const SizedBox(height: 24),

                // Duration
                _buildSectionTitle(theme, 'DURATION', Icons.timer),
                const SizedBox(height: 12),
                _buildDurationSection(theme, colorScheme),

                const SizedBox(height: 32),

                // Danger Zone
                _buildDangerZone(theme, colorScheme),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: const Text('Access Settings'),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _saveChanges,
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : const Icon(Icons.check),
          tooltip: 'Save Changes',
        ),
      ],
    );
  }

  String _getMentorName() {
    final provider = context.read<MentorshipProvider>();
    final profile = provider.getUserProfile(_connection.mentorId);

    // If profile has a name, use that and maybe add relationship label
    if (profile?.username.isNotEmpty ?? false) {
      if (_connection.relationshipLabel?.isNotEmpty ?? false) {
        return '${profile!.username} (${_connection.relationshipLabel})';
      }
      return profile!.username;
    }

    // Fallback to relationship label if profile not available
    if (_connection.relationshipLabel?.isNotEmpty ?? false) {
      return _connection.relationshipLabel!;
    }

    return '${_connection.relationshipType.mentorLabel} (${_connection.mentorId.substring(0, 6)})';
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final mentorName = _getMentorName();
    final profile = context.read<MentorshipProvider>().getUserProfile(
      _connection.mentorId,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MentoringHelpers.getCardDecoration(
        context: context,
        type: 'mentor',
        elevation: 4,
      ),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: profile?.profileUrl,
            fallbackText: mentorName,
            size: 56,
            borderColor: Colors.white.withAlpha((255 * 0.3).toInt()),
            borderWidth: 2,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Managing Access For',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha((255 * 0.8).toInt()),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  mentorName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.2).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _connection.relationshipLabel ??
                        _connection.relationshipType.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  MentoringHelpers.getStatusIcon(_connection.accessStatus),
                  size: 14,
                  color: MentoringColors.getStatusColor(
                    _connection.accessStatus,
                    false, // Always use light mode color on white bg
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _connection.accessStatus.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: MentoringColors.getStatusColor(
                      _connection.accessStatus,
                      false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Expanded(child: Divider(indent: 12)),
      ],
    );
  }

  Widget _buildScreensSection(ThemeData theme, ColorScheme colorScheme) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PermissionChips.detailed(
            screens: _connection.allowedScreens.screens,
            permissions: _connection.permissions,
            onScreenTap: (screen) => _openScreenSelector(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openScreenSelector,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Modify Screens'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(ThemeData theme, ColorScheme colorScheme) {
    final permissions = _connection.permissions;
    return _SettingsCard(
      child: Column(
        children: [
          _PermissionRow(
            label: 'Points & Scores',
            isEnabled: permissions.showPoints,
          ),
          _PermissionRow(label: 'Streak', isEnabled: permissions.showStreak),
          _PermissionRow(label: 'Rank', isEnabled: permissions.showRank),
          _PermissionRow(label: 'Tasks', isEnabled: permissions.showTasks),
          _PermissionRow(label: 'Goals', isEnabled: permissions.showGoals),
          _PermissionRow(label: 'Mood', isEnabled: permissions.showMood),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openPermissionSelector,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Customize Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAccessSection(ThemeData theme, ColorScheme colorScheme) {
    return _SettingsCard(
      child: SwitchListTile(
        title: const Text('Real-time Updates'),
        subtitle: Text(
          _isLiveEnabled
              ? 'Mentor sees changes immediately'
              : 'Mentor sees periodic snapshots only',
          style: theme.textTheme.bodySmall,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isLiveEnabled
                ? Colors.red.withAlpha((255 * 0.1).toInt())
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sensors,
            color: _isLiveEnabled ? Colors.red : colorScheme.onSurfaceVariant,
          ),
        ),
        value: _isLiveEnabled,
        onChanged: (value) async {
          setState(() => _isLiveEnabled = value);
          // Auto-save this setting
          await context.read<MentorshipProvider>().updatePermissions(
            _connection.id,
            isLiveEnabled: value,
          );
        },
        activeThumbColor: Colors.red,
      ),
    );
  }

  Widget _buildDurationSection(ThemeData theme, ColorScheme colorScheme) {
    return _SettingsCard(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(
                  (255 * 0.5).toInt(),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: colorScheme.primary),
            ),
            title: const Text('Current Duration'),
            subtitle: Text(_connection.duration.label),
            trailing: ExpiryCountdown(
              expiresAt: _connection.expiresAt,
              compact: true,
            ),
          ),
          if (_connection.expiresAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Expires on ${MentoringHelpers.formatDate(_connection.expiresAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _openDurationSelector,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Extend Duration'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDangerZone(ThemeData theme, ColorScheme colorScheme) {
    final isPaused = _connection.isPaused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'DANGER ZONE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.red,
              ),
            ),
            const Expanded(child: Divider(indent: 12, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          borderColor: Colors.red.withAlpha((255 * 0.3).toInt()),
          backgroundColor: Colors.red.withAlpha((255 * 0.05).toInt()),
          child: Column(
            children: [
              ListTile(
                title: Text(isPaused ? 'Resume Access' : 'Pause Access'),
                subtitle: Text(
                  isPaused
                      ? 'Mentor will be able to view data again'
                      : 'Temporarily stop mentor from viewing data',
                ),
                trailing: Switch(
                  value: !isPaused,
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.orange,
                  onChanged: (_) => _handlePauseResume(),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text(
                  'Revoke Access',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Permanently remove mentor access',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: IconButton(
                  onPressed: _handleRevoke,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                ),
                onTap: _handleRevoke,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  Future<void> _openScreenSelector() async {
    final result = await ScreenSelectorMenu.show(
      context,
      selectedScreens: _connection.allowedScreens.screens,
    );

    if (result != null) {
      setState(() => _isLoading = true);
      final success = await context
          .read<MentorshipProvider>()
          .updatePermissions(_connection.id, screens: result);
      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccessSnackbar('Screens updated');
      }
    }
  }

  Future<void> _openPermissionSelector() async {
    final result = await PermissionSelectorMenu.show(
      context,
      currentPermissions: _connection.permissions,
      relationshipType: _connection.relationshipType,
    );

    if (result != null) {
      setState(() => _isLoading = true);
      final success = await context
          .read<MentorshipProvider>()
          .updatePermissions(_connection.id, permissions: result);
      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccessSnackbar('Permissions updated');
      }
    }
  }

  Future<void> _openDurationSelector() async {
    final result = await ExtendDurationDialog.show(
      context,
      connection: _connection,
      onExtend: (duration) async {
        return await context.read<MentorshipProvider>().extendAccess(
          _connection.id,
          duration,
        );
      },
    );

    if (result == true && mounted) {
      _showSuccessSnackbar('Duration extended');
    }
  }

  Future<void> _handlePauseResume() async {
    final provider = context.read<MentorshipProvider>();
    final isPaused = _connection.isPaused;

    final confirmed = await PauseAccessDialog.show(
      context,
      isPaused: isPaused,
      userName: _getMentorName(),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      bool success;
      if (isPaused) {
        success = await provider.resumeAccess(_connection.id);
      } else {
        success = await provider.pauseAccess(_connection.id);
      }
      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSuccessSnackbar(isPaused ? 'Access resumed' : 'Access paused');
      }
    }
  }

  Future<void> _handleRevoke() async {
    final confirmed = await RevokeAccessDialog.show(
      context,
      connection: _connection,
      isMentor: true,
      onRevoke: () async {
        return await context.read<MentorshipProvider>().revokeAccess(
          _connection.id,
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context); // Close settings screen
      AppSnackbar.success('Access revoked successfully');
    }
  }

  void _saveChanges() {
    Navigator.pop(context);
  }

  void _showSuccessSnackbar(String message) {
    AppSnackbar.success(message);
  }
}

// ================================================================
// HELPER WIDGETS
// ================================================================

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  const _SettingsCard({
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ?? colorScheme.outline.withAlpha((255 * 0.2).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool isEnabled;

  const _PermissionRow({required this.label, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isEnabled ? Colors.green : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isEnabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              decoration: isEnabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FILE: lib/features/mentoring/widgets/dialogs/mentoring_dialogs.dart
// All Dialogs for Mentoring Feature
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/mentorship_model.dart';
import '../providers/mentorship_provider.dart';
import 'mentoring_common_widgets.dart';
import 'mentoring_utils.dart';
import '../../../chats/widgets/common/user_avatar_cached.dart';

// ================================================================
// PART 1: ACCEPT REQUEST DIALOG
// ================================================================

/// Dialog for accepting a mentorship request with customization options
class AcceptRequestDialog extends StatefulWidget {
  final MentorshipConnection request;
  final String? requesterName;
  final String? requesterAvatar;
  final Future<bool> Function({
    MentorshipPermissions? customPermissions,
    List<AccessibleScreen>? customScreens,
    String? responseMessage,
  })
  onAccept;

  const AcceptRequestDialog({
    super.key,
    required this.request,
    this.requesterName,
    this.requesterAvatar,
    required this.onAccept,
  });

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipConnection request,
    String? requesterName,
    String? requesterAvatar,
    required Future<bool> Function({
      MentorshipPermissions? customPermissions,
      List<AccessibleScreen>? customScreens,
      String? responseMessage,
    })
    onAccept,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AcceptRequestDialog(
        request: request,
        requesterName: requesterName,
        requesterAvatar: requesterAvatar,
        onAccept: onAccept,
      ),
    );
  }

  @override
  State<AcceptRequestDialog> createState() => _AcceptRequestDialogState();
}

class _AcceptRequestDialogState extends State<AcceptRequestDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<AccessibleScreen> _selectedScreens;
  late MentorshipPermissions _permissions;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _showCustomize = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedScreens = List.from(widget.request.allowedScreens.screens);
    _permissions = widget.request.permissions;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandle(colorScheme),

          // Header
          _buildHeader(theme, colorScheme, isDarkMode),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Summary
                  _buildRequestSummary(theme, colorScheme, isDarkMode),

                  if (_showCustomize) ...[
                    const Divider(height: 32),

                    // Customize Section
                    _buildCustomizeSection(theme, colorScheme, isDarkMode),
                  ],

                  const SizedBox(height: 16),

                  // Response Message
                  _buildResponseMessage(theme, colorScheme),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(theme, colorScheme),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.outline.withAlpha((255 * 0.3).toInt()),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: MentoringColors.getGradient('mentor', isDarkMode),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accept Request',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Allow ${widget.requesterName ?? 'this user'} to view your progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(
            (255 * 0.5).toInt(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requester Info
            Row(
              children: [
                _buildAvatar(colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.requesterName ?? 'Unknown User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RelationshipBadge(
                        type: widget.request.relationshipType,
                        customLabel: widget.request.relationshipLabel,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Request Details
            _buildDetailRow(
              theme,
              colorScheme,
              icon: Icons.phone_android,
              label: 'Screens Requested',
              child: PermissionChips(
                screens: widget.request.allowedScreens.screens,
                size: PermissionChipSize.small,
              ),
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              theme,
              colorScheme,
              icon: Icons.timer,
              label: 'Duration',
              value: widget.request.duration.label,
            ),

            if (widget.request.requestMessage?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                theme,
                colorScheme,
                icon: Icons.message,
                label: 'Message',
                value: widget.request.requestMessage!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return UserAvatarCached(
      name: widget.requesterName ?? 'Unknown User',
      imageUrl: widget.requesterAvatar,
      size: 48,
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    String? value,
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (value != null)
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (child != null)
                child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizeSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Access',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
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
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Screens'),
                Tab(text: 'Details'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScreensTab(theme, colorScheme),
                _buildDetailsTab(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreensTab(ThemeData theme, ColorScheme colorScheme) {
    final allScreens = AccessibleScreen.values;
    final hasAll =
        _selectedScreens.length == allScreens.length &&
        allScreens.every((s) => _selectedScreens.contains(s));

    return SingleChildScrollView(
      child: Column(
        children: [
          // All Screens Toggle
          _buildCheckboxTile(
            theme,
            colorScheme,
            title: 'All Screens',
            subtitle: 'Full access to everything',
            icon: Icons.apps,
            isChecked: hasAll,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedScreens = List.from(AccessibleScreen.values);
                } else {
                  _selectedScreens = [];
                }
              });
            },
          ),

          if (!hasAll) ...[
            const Divider(height: 16),
            ...allScreens.map(
              (screen) => _buildCheckboxTile(
                theme,
                colorScheme,
                title: screen.label,
                subtitle: screen.description,
                icon: screen.icon,
                isChecked: _selectedScreens.contains(screen),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedScreens.add(screen);
                    } else {
                      _selectedScreens.remove(screen);
                    }
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Points & Scores',
            icon: Icons.stars,
            value: _permissions.showPoints,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showPoints: v);
            }),
          ),
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Streaks',
            icon: Icons.local_fire_department,
            value: _permissions.showStreak,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showStreak: v);
            }),
          ),
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Rank',
            icon: Icons.leaderboard,
            value: _permissions.showRank,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showRank: v);
            }),
          ),
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Task Names',
            icon: Icons.task_alt,
            value: _permissions.showTasks,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showTasks: v);
            }),
          ),
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Goal Details',
            icon: Icons.flag,
            value: _permissions.showGoals,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showGoals: v);
            }),
          ),
          _buildSwitchTile(
            theme,
            colorScheme,
            title: 'Mood Data',
            icon: Icons.mood,
            value: _permissions.showMood,
            onChanged: (v) => setState(() {
              _permissions = _permissions.copyWith(showMood: v);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Icon(
              icon,
              size: 20,
              color: isChecked
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildResponseMessage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response Message (Optional)',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText:
                  'Add a message for ${widget.requesterName ?? 'them'}...',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(
                (255 * 0.5).toInt(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Customize Toggle
          if (!_showCustomize)
            OutlinedButton.icon(
              onPressed: () => setState(() => _showCustomize = true),
              icon: const Icon(Icons.tune),
              label: const Text('Customize Before Accepting'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          const SizedBox(height: 12),

          // Accept Button
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleAccept,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isLoading ? 'Accepting...' : 'Accept Request'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: Colors.green,
            ),
          ),

          const SizedBox(height: 8),

          // Cancel Button
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.onAccept(
        customPermissions: _showCustomize ? _permissions : null,
        customScreens: _showCustomize ? _selectedScreens : null,
        responseMessage: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ================================================================
// PART 2: DECLINE REQUEST DIALOG
// ================================================================

/// Dialog for declining a mentorship request
class DeclineRequestDialog extends StatefulWidget {
  final MentorshipConnection request;
  final String? requesterName;
  final Future<bool> Function(String? reason) onDecline;

  const DeclineRequestDialog({
    super.key,
    required this.request,
    this.requesterName,
    required this.onDecline,
  });

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipConnection request,
    String? requesterName,
    required Future<bool> Function(String? reason) onDecline,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeclineRequestDialog(
        request: request,
        requesterName: requesterName,
        onDecline: onDecline,
      ),
    );
  }

  @override
  State<DeclineRequestDialog> createState() => _DeclineRequestDialogState();
}

class _DeclineRequestDialogState extends State<DeclineRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _isLoading = false;

  static const List<String> _quickReasons = [
    'Not interested at this time',
    'I don\'t know this person',
    'Privacy concerns',
    'Already have enough mentors',
    'Other reason',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Decline Request'),
                Text(
                  'From ${widget.requesterName ?? 'Unknown User'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to decline this request? '
              'They won\'t be able to view your progress.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Reason (Optional)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Quick Reason Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return FilterChip(
                  label: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedReason = selected ? reason : null;
                      if (selected && reason != 'Other reason') {
                        _reasonController.clear();
                      }
                    });
                  },
                  selectedColor: colorScheme.secondaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),

            // Custom Reason Field
            if (_selectedReason == 'Other reason') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter your reason...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleDecline,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Decline'),
        ),
      ],
    );
  }

  Future<void> _handleDecline() async {
    setState(() => _isLoading = true);

    try {
      String? reason;
      if (_selectedReason == 'Other reason') {
        reason = _reasonController.text.isNotEmpty
            ? _reasonController.text
            : null;
      } else {
        reason = _selectedReason;
      }

      final success = await widget.onDecline(reason);

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ================================================================
// PART 3: REVOKE ACCESS DIALOG
// ================================================================

/// Dialog for revoking/ending a mentorship
class RevokeAccessDialog extends StatefulWidget {
  final MentorshipConnection connection;
  final String? userName;
  final bool
  isMentor; // true if revoking mentor's access, false if ending mentee
  final Future<bool> Function() onRevoke;

  const RevokeAccessDialog({
    super.key,
    required this.connection,
    this.userName,
    required this.isMentor,
    required this.onRevoke,
  });

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipConnection connection,
    String? userName,
    required bool isMentor,
    required Future<bool> Function() onRevoke,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RevokeAccessDialog(
        connection: connection,
        userName: userName,
        isMentor: isMentor,
        onRevoke: onRevoke,
      ),
    );
  }

  @override
  State<RevokeAccessDialog> createState() => _RevokeAccessDialogState();
}

class _RevokeAccessDialogState extends State<RevokeAccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  bool _isLoading = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final title = widget.isMentor ? 'Revoke Access' : 'End Monitoring';
    final description = widget.isMentor
        ? '${widget.userName ?? 'This user'} will no longer be able to view your progress.'
        : 'You will no longer be able to view ${widget.userName ?? 'this user'}\'s progress.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final shake = _shakeController.value;
          return Transform.translate(
            offset: Offset(
              10 *
                  (0.5 - (shake * 2 - 1).abs()) *
                  (shake < 0.5 ? 1 : -1) *
                  (_shakeController.isAnimating ? 1 : 0),
              0,
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.remove_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(
                (255 * (isDarkMode ? 0.2 : 0.1)).toInt(),
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withAlpha((255 * 0.3).toInt()),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This action cannot be undone!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Stats Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(
                (255 * 0.5).toInt(),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  theme,
                  colorScheme,
                  icon: Icons.access_time,
                  label: 'Active Since',
                  value: MentoringHelpers.formatDate(
                    widget.connection.startsAt,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  theme,
                  colorScheme,
                  icon: Icons.visibility,
                  label: 'Total Views',
                  value: '${widget.connection.viewCount}',
                ),
                if (widget.connection.encouragementCount > 0) ...[
                  const SizedBox(height: 8),
                  _buildStatRow(
                    theme,
                    colorScheme,
                    icon: Icons.favorite,
                    label: 'Encouragements Sent',
                    value: '${widget.connection.encouragementCount}',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Confirmation Checkbox
          InkWell(
            onTap: () => setState(() => _confirmed = !_confirmed),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _confirmed,
                    onChanged: (v) => setState(() => _confirmed = v ?? false),
                    activeColor: Colors.red,
                  ),
                  Expanded(
                    child: Text(
                      'I understand this will permanently end this connection',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_isLoading || !_confirmed) ? null : _handleRevoke,
          style: FilledButton.styleFrom(
            backgroundColor: _confirmed ? Colors.red : Colors.grey,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.isMentor ? 'Revoke Access' : 'End Monitoring'),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRevoke() async {
    if (!_confirmed) {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();
      final success = await widget.onRevoke();

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ================================================================
// PART 4: SEND ENCOURAGEMENT DIALOG
// ================================================================

/// Dialog for sending encouragement to a mentee
class SendEncouragementDialog extends StatefulWidget {
  final MentorshipConnection connection;
  final String? menteeName;
  final String? menteeAvatar;
  final Future<bool> Function(String type, String? message) onSend;

  const SendEncouragementDialog({
    super.key,
    required this.connection,
    this.menteeName,
    this.menteeAvatar,
    required this.onSend,
  });

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipConnection connection,
    String? menteeName,
    String? menteeAvatar,
    required Future<bool> Function(String type, String? message) onSend,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendEncouragementDialog(
        connection: connection,
        menteeName: menteeName,
        menteeAvatar: menteeAvatar,
        onSend: onSend,
      ),
    );
  }

  @override
  State<SendEncouragementDialog> createState() =>
      _SendEncouragementDialogState();
}

class _SendEncouragementDialogState extends State<SendEncouragementDialog>
    with TickerProviderStateMixin {
  late AnimationController _emojiController;
  late AnimationController _sendController;
  final TextEditingController _messageController = TextEditingController();

  String? _selectedEmoji;
  String? _selectedQuickMessage;
  bool _showCustomMessage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _sendController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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
          _buildHeader(theme, colorScheme, isDarkMode),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mentee Info
                  _buildMenteeInfo(theme, colorScheme),

                  const SizedBox(height: 24),

                  // Emoji Grid
                  _buildEmojiSection(theme, colorScheme),

                  const SizedBox(height: 24),

                  // Quick Messages
                  _buildQuickMessages(theme, colorScheme),

                  // Custom Message
                  if (_showCustomMessage) ...[
                    const SizedBox(height: 16),
                    _buildCustomMessage(theme, colorScheme),
                  ],

                  const SizedBox(height: 24),

                  // Send Button
                  _buildSendButton(theme, colorScheme, isDarkMode),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Consumer<MentorshipProvider>(
      builder: (context, provider, _) {
        final profile = provider.getUserProfile(widget.connection.ownerId);
        final menteeName =
            (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ?? widget.menteeName ?? 'your mentee';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Encouragement',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Motivate $menteeName to keep going! 🎉',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenteeInfo(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<MentorshipProvider>(
      builder: (context, provider, _) {
        final profile = provider.getUserProfile(widget.connection.ownerId);
        final menteeName =
            (profile?.displayName.isNotEmpty == true ? profile!.displayName : profile?.username) ?? widget.menteeName ?? 'Your Mentee';
        final menteeAvatar = profile?.profileUrl ?? widget.menteeAvatar;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  UserAvatarCached(
                    imageUrl: menteeAvatar,
                    name: menteeName,
                    size: 56,
                  ),
                  if (widget.connection.isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menteeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RelationshipBadge(
                          type: widget.connection.relationshipType,
                          compact: true,
                        ),
                        if (widget.connection.encouragementCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${widget.connection.encouragementCount} sent',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildEmojiSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick an Emoji',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              MentoringConstants.encouragementEmojis.length,
              (index) {
                final emoji = MentoringConstants.encouragementEmojis[index];
                final isSelected = _selectedEmoji == emoji;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                    HapticFeedback.lightImpact();
                    _emojiController.forward(from: 0);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withAlpha(
                                  (255 * 0.3).toInt(),
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
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

  Widget _buildQuickMessages(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Messages',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showCustomMessage = !_showCustomMessage;
                    _selectedQuickMessage = null;
                  });
                },
                icon: Icon(
                  _showCustomMessage ? Icons.list : Icons.edit,
                  size: 18,
                ),
                label: Text(
                  _showCustomMessage ? 'Quick Messages' : 'Custom',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MentoringConstants.quickEncouragementMessages.map((
              message,
            ) {
              final isSelected = _selectedQuickMessage == message;
              return FilterChip(
                label: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedQuickMessage = selected ? message : null;
                    if (selected) {
                      _showCustomMessage = false;
                      _messageController.clear();
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                selectedColor: colorScheme.secondaryContainer,
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: 'Write a personal message...',
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(
            (255 * 0.5).toInt(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (_) {
          setState(() {
            _selectedQuickMessage = null;
          });
        },
      ),
    );
  }

  Widget _buildSendButton(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final hasContent =
        _selectedEmoji != null ||
        _selectedQuickMessage != null ||
        _messageController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilledButton.icon(
          onPressed: (hasContent && !_isLoading) ? _handleSend : null,
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    hasContent ? Icons.send : Icons.favorite_border,
                    key: ValueKey(hasContent),
                  ),
                ),
          label: Text(
            _isLoading
                ? 'Sending...'
                : hasContent
                ? 'Send Encouragement'
                : 'Select something to send',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: hasContent
                ? Colors.pink
                : colorScheme.surfaceContainerHighest,
            foregroundColor: hasContent
                ? Colors.white
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_selectedEmoji == null &&
        _selectedQuickMessage == null &&
        _messageController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();

      String type = 'emoji';
      String? message;

      if (_selectedQuickMessage != null) {
        type = 'quick_message';
        message = _selectedQuickMessage;
      } else if (_messageController.text.isNotEmpty) {
        type = 'custom_message';
        message = _messageController.text;
      }

      if (_selectedEmoji != null) {
        message = '${_selectedEmoji!} ${message ?? ''}'.trim();
      }

      final success = await widget.onSend(type, message);

      if (success && mounted) {
        // Show success animation
        await _sendController.forward();
        HapticFeedback.heavyImpact();
      }

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ================================================================
// PART 5: ADDITIONAL DIALOGS
// ================================================================

/// Simple confirmation dialog
class MentoringConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDangerous;

  const MentoringConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.icon,
    this.isDangerous = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MentoringConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonColor =
        confirmColor ?? (isDangerous ? Colors.red : colorScheme.primary);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: buttonColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: buttonColor, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: buttonColor),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Pause/Resume confirmation dialog
class PauseAccessDialog extends StatelessWidget {
  final bool isPaused;
  final String? userName;

  const PauseAccessDialog({super.key, required this.isPaused, this.userName});

  static Future<bool?> show(
    BuildContext context, {
    required bool isPaused,
    String? userName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          PauseAccessDialog(isPaused: isPaused, userName: userName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = isPaused ? 'Resume Access' : 'Pause Access';
    final message = isPaused
        ? '${userName ?? 'This user'} will be able to view your progress again.'
        : '${userName ?? 'This user'} won\'t be able to view your progress until you resume.';
    final icon = isPaused ? Icons.play_arrow : Icons.pause;
    final color = isPaused ? Colors.green : Colors.orange;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: color),
          child: Text(isPaused ? 'Resume' : 'Pause'),
        ),
      ],
    );
  }
}

/// Extend duration dialog
class ExtendDurationDialog extends StatefulWidget {
  final MentorshipConnection connection;
  final Future<bool> Function(AccessDuration) onExtend;

  const ExtendDurationDialog({
    super.key,
    required this.connection,
    required this.onExtend,
  });

  static Future<bool?> show(
    BuildContext context, {
    required MentorshipConnection connection,
    required Future<bool> Function(AccessDuration) onExtend,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ExtendDurationDialog(connection: connection, onExtend: onExtend),
    );
  }

  @override
  State<ExtendDurationDialog> createState() => _ExtendDurationDialogState();
}

class _ExtendDurationDialogState extends State<ExtendDurationDialog> {
  AccessDuration _selectedDuration = AccessDuration.oneMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.connection.duration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withAlpha((255 * 0.3).toInt()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timer, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extend Duration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Current: ${widget.connection.duration.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Duration Options
          ...AccessDuration.values.map((duration) {
            final isSelected = _selectedDuration == duration;
            final expiresAt = duration.calculateExpiresAt();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedDuration = duration),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer.withAlpha(
                            (255 * 0.5).toInt(),
                          )
                        : colorScheme.surfaceContainerHighest.withAlpha(
                            (255 * 0.5).toInt(),
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<AccessDuration>(
                        value: duration,
                        groupValue: _selectedDuration,
                        onChanged: (v) =>
                            setState(() => _selectedDuration = v!),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        duration.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              duration.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              expiresAt != null
                                  ? 'Expires: ${MentoringHelpers.formatDate(expiresAt)}'
                                  : 'Never expires',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleExtend,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Extending...' : 'Extend'),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  Future<void> _handleExtend() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.onExtend(_selectedDuration);

      if (mounted) {
        Navigator.pop(context, success);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ================================================================
// FILE: lib/features/mentoring/widgets/menus/mentoring_menus.dart
// Complete Bottom Sheet Menus for Mentoring Feature
// Includes: Request Access, Share Access, Screen Selector,
//           Duration Selector, Permission Selector, Relationship Selector
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mentorship_model.dart';
import 'mentoring_utils.dart';
import '../../../chats/widgets/common/user_avatar_cached.dart';

// ================================================================
// PART 1: REQUEST ACCESS MENU
// ================================================================

/// Bottom sheet menu to request monitoring someone's progress
/// Triggered from: Profile page, Mentoring Hub
class RequestAccessMenu extends StatefulWidget {
  final String? targetUserId;
  final String? targetUserName;
  final String? targetUserAvatar;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onSearchUsers;
  final Future<bool> Function({
    required String targetUserId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    required List<AccessibleScreen> screens,
    required AccessDuration duration,
    String? message,
  })
  onSubmit;

  const RequestAccessMenu({
    super.key,
    this.targetUserId,
    this.targetUserName,
    this.targetUserAvatar,
    this.onSearchUsers,
    required this.onSubmit,
  });

  /// Show the menu as a modal bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    String? targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
    Future<List<Map<String, dynamic>>> Function(String query)? onSearchUsers,
    required Future<bool> Function({
      required String targetUserId,
      required RelationshipType relationshipType,
      String? relationshipLabel,
      required List<AccessibleScreen> screens,
      required AccessDuration duration,
      String? message,
    })
    onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestAccessMenu(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
        onSearchUsers: onSearchUsers,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RequestAccessMenu> createState() => _RequestAccessMenuState();
}

class _RequestAccessMenuState extends State<RequestAccessMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Form State
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserAvatar;
  RelationshipType _selectedRelationship = RelationshipType.custom;
  String? _customRelationshipLabel;
  List<AccessibleScreen> _selectedScreens = [AccessibleScreen.dashboard];
  AccessDuration _selectedDuration = AccessDuration.oneMonth;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    if (widget.targetUserId != null) {
      _selectedUserId = widget.targetUserId;
      _selectedUserName = widget.targetUserName;
      _selectedUserAvatar = widget.targetUserAvatar;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedUserId != null &&
      _selectedScreens.isNotEmpty &&
      (_selectedRelationship != RelationshipType.custom ||
          (_customRelationshipLabel?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Opacity(opacity: _slideAnimation.value, child: child),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).toInt()),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            _MenuHandle(),

            // Header
            _MenuHeader(
              icon: Icons.person_add_alt_1,
              iconGradient: MentoringColors.getGradient('request', isDarkMode),
              title: 'Request Access',
              subtitle: 'Request to monitor someone\'s progress',
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPadding + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target User Info
                    _buildUserSelectionSection(theme, colorScheme),

                    if (_selectedUserId != null) ...[
                      const SizedBox(height: 24),

                      // Relationship Type
                      _buildSectionHeader(
                        theme,
                        icon: Icons.handshake,
                        title: 'Relationship Type',
                      ),
                      const SizedBox(height: 12),
                      _RelationshipSelector(
                        selectedType: _selectedRelationship,
                        customLabel: _customRelationshipLabel,
                        onChanged: (type, label) {
                          setState(() {
                            _selectedRelationship = type;
                            _customRelationshipLabel = label;
                            // Update default screens/permissions based on relationship
                            _selectedScreens =
                                MentoringHelpers.getDefaultScreens(type);
                          });
                          HapticFeedback.selectionClick();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Screens to Access
                      _buildSectionHeader(
                        theme,
                        icon: Icons.phone_android,
                        title: 'Screens to Access',
                        action: TextButton(
                          onPressed: () => _openScreenSelector(context),
                          child: Text(
                            (_selectedScreens.length ==
                                    AccessibleScreen.values.length)
                                ? 'All Screens'
                                : '${_selectedScreens.length} selected',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ScreenPreviewChips(
                        screens: _selectedScreens,
                        onTap: () => _openScreenSelector(context),
                      ),

                      const SizedBox(height: 24),

                      // Duration
                      _buildSectionHeader(
                        theme,
                        icon: Icons.timer,
                        title: 'Access Duration',
                      ),
                      const SizedBox(height: 12),
                      _DurationSelector(
                        selectedDuration: _selectedDuration,
                        onChanged: (duration) {
                          setState(() => _selectedDuration = duration);
                          HapticFeedback.selectionClick();
                        },
                        compact: true,
                      ),

                      const SizedBox(height: 24),

                      // Message
                      _buildSectionHeader(
                        theme,
                        icon: Icons.message,
                        title: 'Message (Optional)',
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText:
                                'Add a personal message explaining why you\'re requesting access...',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withAlpha((255 * 0.5).toInt()),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SubmitButton(
                          label: 'Send Request',
                          icon: Icons.send,
                          isLoading: _isLoading,
                          isEnabled: _isValid,
                          onPressed: _handleSubmit,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelectionSection(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedUserId != null) {
      // Show selected user
      return _buildSelectedUserCard(theme, colorScheme);
    }

    // Show search field
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request From',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search user by name...',
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          // Search Results
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: UserAvatarCached(
                      imageUrl: user['avatar'],
                      name: user['name'] ?? 'Unknown',
                      size: 40,
                    ),
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: user['email'] != null
                        ? Text(user['email'])
                        : null,
                    onTap: () => _selectUser(user),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha((255 * 0.3).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withAlpha((255 * 0.2).toInt()),
          ),
        ),
        child: Row(
          children: [
            UserAvatarCached(
              imageUrl: _selectedUserAvatar,
              name: _selectedUserName ?? '?',
              size: 56,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requesting From',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedUserName ?? 'Unknown User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Change Button
            if (widget.targetUserId == null)
              IconButton(
                onPressed: _clearSelectedUser,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                ),
              ),
            if (widget.targetUserId != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null) ...[const Spacer(), action],
        ],
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    if (widget.onSearchUsers == null) return;

    setState(() => _isSearching = true);

    try {
      final results = await widget.onSearchUsers!(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['id'];
      _selectedUserName = user['name'];
      _selectedUserAvatar = user['avatar'];
      _searchResults = [];
      _searchController.clear();
    });
    HapticFeedback.selectionClick();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUserId = null;
      _selectedUserName = null;
      _selectedUserAvatar = null;
    });
  }

  Future<void> _openScreenSelector(BuildContext context) async {
    final result = await ScreenSelectorMenu.show(
      context,
      selectedScreens: _selectedScreens,
    );

    if (result != null) {
      setState(() => _selectedScreens = result);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isValid || _selectedUserId == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await widget.onSubmit(
        targetUserId: _selectedUserId!,
        relationshipType: _selectedRelationship,
        relationshipLabel: _customRelationshipLabel,
        screens: _selectedScreens,
        duration: _selectedDuration,
        message: _messageController.text.isNotEmpty
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
// PART 2: SHARE ACCESS MENU
// ================================================================

/// Bottom sheet menu to share your access with someone
/// Triggered from: Profile page, Mentoring Hub
class ShareAccessMenu extends StatefulWidget {
  final String? preselectedUserId;
  final String? preselectedUserName;
  final String? preselectedUserAvatar;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onSearchUsers;
  final Future<bool> Function({
    required String viewerId,
    required RelationshipType relationshipType,
    String? relationshipLabel,
    required List<AccessibleScreen> screens,
    required MentorshipPermissions permissions,
    required AccessDuration duration,
    required bool isLiveEnabled,
  })
  onSubmit;

  const ShareAccessMenu({
    super.key,
    this.preselectedUserId,
    this.preselectedUserName,
    this.preselectedUserAvatar,
    this.onSearchUsers,
    required this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? preselectedUserId,
    String? preselectedUserName,
    String? preselectedUserAvatar,
    Future<List<Map<String, dynamic>>> Function(String query)? onSearchUsers,
    required Future<bool> Function({
      required String viewerId,
      required RelationshipType relationshipType,
      String? relationshipLabel,
      required List<AccessibleScreen> screens,
      required MentorshipPermissions permissions,
      required AccessDuration duration,
      required bool isLiveEnabled,
    })
    onSubmit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareAccessMenu(
        preselectedUserId: preselectedUserId,
        preselectedUserName: preselectedUserName,
        preselectedUserAvatar: preselectedUserAvatar,
        onSearchUsers: onSearchUsers,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ShareAccessMenu> createState() => _ShareAccessMenuState();
}

class _ShareAccessMenuState extends State<ShareAccessMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Form State
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserAvatar;
  RelationshipType _selectedRelationship = RelationshipType.custom;
  String? _customRelationshipLabel;
  List<AccessibleScreen> _selectedScreens = List.from(AccessibleScreen.values);
  MentorshipPermissions _permissions = const MentorshipPermissions();
  AccessDuration _selectedDuration = AccessDuration.always;
  bool _isLiveEnabled = true;
  bool _isLoading = false;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Pre-select user if provided
    if (widget.preselectedUserId != null) {
      _selectedUserId = widget.preselectedUserId;
      _selectedUserName = widget.preselectedUserName;
      _selectedUserAvatar = widget.preselectedUserAvatar;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedUserId != null &&
      _selectedScreens.isNotEmpty &&
      (_selectedRelationship != RelationshipType.custom ||
          (_customRelationshipLabel?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Opacity(opacity: _slideAnimation.value, child: child),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).toInt()),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            _MenuHandle(),

            // Header
            _MenuHeader(
              icon: Icons.share,
              iconGradient: MentoringColors.getGradient('mentee', isDarkMode),
              title: 'Share Your Access',
              subtitle: 'Let someone monitor your progress',
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPadding + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Selection
                    _buildUserSelectionSection(theme, colorScheme),

                    if (_selectedUserId != null) ...[
                      const SizedBox(height: 24),

                      // Relationship Type
                      _buildSectionHeader(
                        theme,
                        icon: Icons.handshake,
                        title: 'Relationship Type',
                      ),
                      const SizedBox(height: 12),
                      _RelationshipSelector(
                        selectedType: _selectedRelationship,
                        customLabel: _customRelationshipLabel,
                        onChanged: (type, label) {
                          setState(() {
                            _selectedRelationship = type;
                            _customRelationshipLabel = label;
                            _selectedScreens =
                                MentoringHelpers.getDefaultScreens(type);
                            _permissions =
                                MentoringHelpers.getDefaultPermissions(type);
                          });
                          HapticFeedback.selectionClick();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Screens to Share
                      _buildSectionHeader(
                        theme,
                        icon: Icons.phone_android,
                        title: 'Screens to Share',
                        action: TextButton(
                          onPressed: () => _openScreenSelector(context),
                          child: Text(
                            (_selectedScreens.length ==
                                    AccessibleScreen.values.length)
                                ? 'All Screens'
                                : '${_selectedScreens.length} selected',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ScreenPreviewChips(
                        screens: _selectedScreens,
                        onTap: () => _openScreenSelector(context),
                      ),

                      const SizedBox(height: 24),

                      // Permissions
                      _buildSectionHeader(
                        theme,
                        icon: Icons.visibility,
                        title: 'Details to Show',
                        action: TextButton(
                          onPressed: () => _openPermissionSelector(context),
                          child: Text(_permissions.summaryLabel),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PermissionPreviewChips(
                        permissions: _permissions,
                        onTap: () => _openPermissionSelector(context),
                      ),

                      const SizedBox(height: 24),

                      // Duration
                      _buildSectionHeader(
                        theme,
                        icon: Icons.timer,
                        title: 'Access Duration',
                      ),
                      const SizedBox(height: 12),
                      _DurationSelector(
                        selectedDuration: _selectedDuration,
                        onChanged: (duration) {
                          setState(() => _selectedDuration = duration);
                          HapticFeedback.selectionClick();
                        },
                        compact: true,
                      ),

                      const SizedBox(height: 24),

                      // Live Access Toggle
                      _buildLiveAccessToggle(theme, colorScheme),

                      const SizedBox(height: 32),

                      // Submit Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SubmitButton(
                          label: 'Share Access',
                          icon: Icons.share,
                          isLoading: _isLoading,
                          isEnabled: _isValid,
                          onPressed: _handleSubmit,
                          gradient: MentoringColors.getGradient(
                            'mentee',
                            isDarkMode,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSelectionSection(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedUserId != null) {
      // Show selected user
      return _buildSelectedUserCard(theme, colorScheme);
    }

    // Show search field
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share With',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search user by name...',
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          // Search Results
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: UserAvatarCached(
                      imageUrl: user['avatar'],
                      name: user['name'] ?? 'Unknown',
                      size: 40,
                    ),
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: user['email'] != null
                        ? Text(user['email'])
                        : null,
                    onTap: () => _selectUser(user),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedUserCard(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer.withAlpha((255 * 0.5).toInt()),
              colorScheme.tertiaryContainer.withAlpha((255 * 0.3).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.secondary.withAlpha((255 * 0.2).toInt()),
          ),
        ),
        child: Row(
          children: [
            UserAvatarCached(
              imageUrl: _selectedUserAvatar,
              name: _selectedUserName ?? '?',
              size: 56,
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sharing With',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedUserName ?? 'Unknown User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Change Button
            if (widget.preselectedUserId == null)
              IconButton(
                onPressed: _clearSelectedUser,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAccessToggle(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isLiveEnabled
              ? Colors.red.withAlpha((255 * 0.1).toInt())
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLiveEnabled
                ? Colors.red.withAlpha((255 * 0.3).toInt())
                : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
        ),
        child: Row(
          children: [
            // Icon with pulse animation
            Stack(
              alignment: Alignment.center,
              children: [
                if (_isLiveEnabled)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        width: 40 * value,
                        height: 40 * value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withAlpha(
                            (255 * 0.2 / value).toInt(),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isLiveEnabled
                        ? Colors.red
                        : colorScheme.onSurfaceVariant.withAlpha(
                            (255 * 0.2).toInt(),
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLiveEnabled ? Icons.sensors : Icons.sensors_off,
                    color: _isLiveEnabled
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Access',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isLiveEnabled ? Colors.red : null,
                    ),
                  ),
                  Text(
                    _isLiveEnabled
                        ? 'They can see real-time updates'
                        : 'Only periodic snapshots',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Toggle
            Switch(
              value: _isLiveEnabled,
              onChanged: (value) {
                setState(() => _isLiveEnabled = value);
                HapticFeedback.selectionClick();
              },
              activeThumbColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null) ...[const Spacer(), action],
        ],
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    if (widget.onSearchUsers == null) return;

    setState(() => _isSearching = true);

    try {
      final results = await widget.onSearchUsers!(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['id'];
      _selectedUserName = user['name'];
      _selectedUserAvatar = user['avatar'];
      _searchResults = [];
      _searchController.clear();
    });
    HapticFeedback.selectionClick();
  }

  void _clearSelectedUser() {
    setState(() {
      _selectedUserId = null;
      _selectedUserName = null;
      _selectedUserAvatar = null;
    });
  }

  Future<void> _openScreenSelector(BuildContext context) async {
    final result = await ScreenSelectorMenu.show(
      context,
      selectedScreens: _selectedScreens,
    );

    if (result != null) {
      setState(() => _selectedScreens = result);
    }
  }

  Future<void> _openPermissionSelector(BuildContext context) async {
    final result = await PermissionSelectorMenu.show(
      context,
      currentPermissions: _permissions,
      relationshipType: _selectedRelationship,
    );

    if (result != null) {
      setState(() => _permissions = result);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_isValid || _selectedUserId == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await widget.onSubmit(
        viewerId: _selectedUserId!,
        relationshipType: _selectedRelationship,
        relationshipLabel: _customRelationshipLabel,
        screens: _selectedScreens,
        permissions: _permissions,
        duration: _selectedDuration,
        isLiveEnabled: _isLiveEnabled,
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
// PART 3: SCREEN SELECTOR MENU
// ================================================================

/// Bottom sheet menu for selecting which screen to share/request
class ScreenSelectorMenu extends StatefulWidget {
  final List<AccessibleScreen> selectedScreens;
  final bool allowMultiple;

  const ScreenSelectorMenu({
    super.key,
    required this.selectedScreens,
    this.allowMultiple = true,
  });

  static Future<List<AccessibleScreen>?> show(
    BuildContext context, {
    required List<AccessibleScreen> selectedScreens,
    bool allowMultiple = true,
  }) {
    return showModalBottomSheet<List<AccessibleScreen>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScreenSelectorMenu(
        selectedScreens: selectedScreens,
        allowMultiple: allowMultiple,
      ),
    );
  }

  @override
  State<ScreenSelectorMenu> createState() => _ScreenSelectorMenuState();
}

class _ScreenSelectorMenuState extends State<ScreenSelectorMenu> {
  late List<AccessibleScreen> _selectedScreens;

  bool get _isAllSelected =>
      _selectedScreens.length == AccessibleScreen.values.length;

  @override
  void initState() {
    super.initState();
    _selectedScreens = List.from(widget.selectedScreens);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenOptions = AccessibleScreen.values;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          const _MenuHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Screens',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // All Screens Toggle
          _buildAllScreensToggle(theme, colorScheme),

          const Divider(height: 1),

          // Screen List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: screenOptions.length,
              itemBuilder: (context, index) {
                final screen = screenOptions[index];
                final isSelected = _selectedScreens.contains(screen);

                return _ScreenOptionTile(
                  screen: screen,
                  isSelected: isSelected,
                  isDisabled: false, // Always allow manual selection
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedScreens.contains(screen)) {
                          _selectedScreens.add(screen);
                        }
                      } else {
                        _selectedScreens.remove(screen);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _selectedScreens.isNotEmpty
                        ? () => Navigator.pop(context, _selectedScreens)
                        : null,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  Widget _buildAllScreensToggle(ThemeData theme, ColorScheme colorScheme) {
    final isAll = _isAllSelected;

    return InkWell(
      onTap: () {
        setState(() {
          if (isAll) {
            _selectedScreens = [];
          } else {
            _selectedScreens = List.from(AccessibleScreen.values);
          }
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isAll
            ? colorScheme.primaryContainer.withAlpha((255 * 0.3).toInt())
            : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAll
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.apps,
                color: isAll
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Screens',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Full access to everything',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isAll,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedScreens = List.from(AccessibleScreen.values);
                  } else {
                    _selectedScreens = [];
                  }
                });
                HapticFeedback.selectionClick();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenOptionTile extends StatelessWidget {
  final AccessibleScreen screen;
  final bool isSelected;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const _ScreenOptionTile({
    required this.screen,
    required this.isSelected,
    required this.isDisabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: isDisabled ? null : () => onChanged(!isSelected),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withAlpha((255 * 0.1).toInt())
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  screen.icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      screen.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      screen.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: isDisabled ? null : (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// PART 4: DURATION SELECTOR MENU
// ================================================================

/// Bottom sheet menu for selecting access duration
class DurationSelectorMenu extends StatefulWidget {
  final AccessDuration selectedDuration;

  const DurationSelectorMenu({super.key, required this.selectedDuration});

  static Future<AccessDuration?> show(
    BuildContext context, {
    required AccessDuration selectedDuration,
  }) {
    return showModalBottomSheet<AccessDuration>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DurationSelectorMenu(selectedDuration: selectedDuration),
    );
  }

  @override
  State<DurationSelectorMenu> createState() => _DurationSelectorMenuState();
}

class _DurationSelectorMenuState extends State<DurationSelectorMenu> {
  late AccessDuration _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.selectedDuration;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          _MenuHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Duration',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Duration Options
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: AccessDuration.values.length,
              itemBuilder: (context, index) {
                final duration = AccessDuration.values[index];
                final isSelected = _selectedDuration == duration;
                final expiresAt = duration.calculateExpiresAt();

                return _DurationOptionTile(
                  duration: duration,
                  expiresAt: expiresAt,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedDuration = duration);
                    HapticFeedback.selectionClick();
                  },
                );
              },
            ),
          ),

          // Selected Expiry Info
          if (_selectedDuration.calculateExpiresAt() != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(
                    (255 * 0.5).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: ${MentoringHelpers.formatDate(_selectedDuration.calculateExpiresAt())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _selectedDuration),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

class _DurationOptionTile extends StatelessWidget {
  final AccessDuration duration;
  final DateTime? expiresAt;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationOptionTile({
    required this.duration,
    required this.expiresAt,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected
            ? colorScheme.primaryContainer.withAlpha((255 * 0.3).toInt())
            : null,
        child: Row(
          children: [
            Text(duration.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
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
                    duration.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<AccessDuration>(
              value: duration,
              groupValue: isSelected ? duration : null,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// PART 5: PERMISSION SELECTOR MENU
// ================================================================

/// Bottom sheet menu for selecting what details to show
class PermissionSelectorMenu extends StatefulWidget {
  final MentorshipPermissions currentPermissions;
  final RelationshipType? relationshipType;

  const PermissionSelectorMenu({
    super.key,
    required this.currentPermissions,
    this.relationshipType,
  });

  static Future<MentorshipPermissions?> show(
    BuildContext context, {
    required MentorshipPermissions currentPermissions,
    RelationshipType? relationshipType,
  }) {
    return showModalBottomSheet<MentorshipPermissions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionSelectorMenu(
        currentPermissions: currentPermissions,
        relationshipType: relationshipType,
      ),
    );
  }

  @override
  State<PermissionSelectorMenu> createState() => _PermissionSelectorMenuState();
}

class _PermissionSelectorMenuState extends State<PermissionSelectorMenu> {
  late MentorshipPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.currentPermissions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          // Handle Bar
          _MenuHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visible Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose what they can see',
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

          // Quick Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _PresetChip(
                  label: 'Full',
                  isSelected: _permissions.isAll,
                  onTap: () {
                    setState(() => _permissions = MentorshipPermissions.all());
                    HapticFeedback.selectionClick();
                  },
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: 'Basic',
                  isSelected: _permissions.isMinimal,
                  onTap: () {
                    setState(
                      () => _permissions = MentorshipPermissions.minimal(),
                    );
                    HapticFeedback.selectionClick();
                  },
                ),
                if (widget.relationshipType != null) ...[
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Default',
                    isSelected: false,
                    onTap: () {
                      setState(
                        () => _permissions =
                            MentorshipPermissions.forRelationship(
                              widget.relationshipType!,
                            ),
                      );
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Permission Categories
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats & Scores
                  _buildCategoryHeader(theme, 'Stats & Scores'),
                  _PermissionToggle(
                    icon: Icons.stars,
                    title: 'Points & Total Score',
                    value: _permissions.showPoints,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showPoints: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.local_fire_department,
                    title: 'Current Streak',
                    value: _permissions.showStreak,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showStreak: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.leaderboard,
                    title: 'Leaderboard Rank',
                    value: _permissions.showRank,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showRank: v),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tasks & Goals
                  _buildCategoryHeader(theme, 'Tasks & Goals'),
                  _PermissionToggle(
                    icon: Icons.task_alt,
                    title: 'Task Names',
                    value: _permissions.showTasks,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showTasks: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.checklist,
                    title: 'Task Details',
                    subtitle: 'Due dates, progress, etc.',
                    value: _permissions.showTaskDetails,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(
                        showTaskDetails: v,
                      ),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.flag,
                    title: 'Goal Names',
                    value: _permissions.showGoals,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showGoals: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.track_changes,
                    title: 'Goal Details',
                    subtitle: 'Progress, deadlines, etc.',
                    value: _permissions.showGoalDetails,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(
                        showGoalDetails: v,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Personal Data
                  _buildCategoryHeader(theme, 'Personal Data'),
                  _PermissionToggle(
                    icon: Icons.mood,
                    title: 'Mood Data',
                    value: _permissions.showMood,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showMood: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.book,
                    title: 'Diary Entries',
                    value: _permissions.showDiary,
                    onChanged: (v) => setState(
                      () => _permissions = _permissions.copyWith(showDiary: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.emoji_events,
                    title: 'Rewards Earned',
                    value: _permissions.showRewards,
                    onChanged: (v) => setState(
                      () =>
                          _permissions = _permissions.copyWith(showRewards: v),
                    ),
                  ),
                  _PermissionToggle(
                    icon: Icons.trending_up,
                    title: 'Overall Progress',
                    value: _permissions.showProgress,
                    onChanged: (v) => setState(
                      () =>
                          _permissions = _permissions.copyWith(showProgress: v),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Summary & Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_permissions.enabledCount} of 11 details visible',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, _permissions),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionToggle({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        onChanged(!value);
        HapticFeedback.selectionClick();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
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
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withAlpha((255 * 0.3).toInt()),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// PART 6: RELATIONSHIP SELECTOR MENU
// ================================================================

/// Bottom sheet menu for selecting relationship type
class RelationshipSelectorMenu extends StatefulWidget {
  final RelationshipType selectedType;
  final String? customLabel;

  const RelationshipSelectorMenu({
    super.key,
    required this.selectedType,
    this.customLabel,
  });

  static Future<(RelationshipType, String?)?> show(
    BuildContext context, {
    required RelationshipType selectedType,
    String? customLabel,
  }) {
    return showModalBottomSheet<(RelationshipType, String?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RelationshipSelectorMenu(
        selectedType: selectedType,
        customLabel: customLabel,
      ),
    );
  }

  @override
  State<RelationshipSelectorMenu> createState() =>
      _RelationshipSelectorMenuState();
}

class _RelationshipSelectorMenuState extends State<RelationshipSelectorMenu> {
  late RelationshipType _selectedType;
  final TextEditingController _customLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    if (widget.customLabel != null) {
      _customLabelController.text = widget.customLabel!;
    }
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedType != RelationshipType.custom ||
      _customLabelController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
          // Handle Bar
          _MenuHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.handshake,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Relationship',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Relationship Options
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 8, bottom: bottomPadding + 8),
              child: Column(
                children: [
                  ...RelationshipType.values.map((type) {
                    final isSelected = _selectedType == type;
                    final color = MentoringColors.getRelationshipColor(type);

                    return _RelationshipOptionTile(
                      type: type,
                      color: color,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedType = type);
                        HapticFeedback.selectionClick();
                      },
                    );
                  }),

                  // Custom Label Field
                  if (_selectedType == RelationshipType.custom) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _customLabelController,
                        decoration: InputDecoration(
                          labelText: 'Custom Label',
                          hintText: 'e.g., "Math Teacher"',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.edit),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isValid
                        ? () {
                            final label =
                                _selectedType == RelationshipType.custom &&
                                    _customLabelController.text.isNotEmpty
                                ? _customLabelController.text
                                : null;
                            Navigator.pop(context, (_selectedType, label));
                          }
                        : null,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

class _RelationshipOptionTile extends StatelessWidget {
  final RelationshipType type;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RelationshipOptionTile({
    required this.type,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? color.withAlpha((255 * 0.1).toInt()) : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(type.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${type.mentorLabel} monitors ${type.ownerLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<RelationshipType>(
              value: type,
              groupValue: isSelected ? type : null,
              onChanged: (_) => onTap(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SHARED HELPER WIDGETS
// ================================================================

/// Menu handle bar widget
class _MenuHandle extends StatelessWidget {
  const _MenuHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.outline.withAlpha((255 * 0.3).toInt()),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Menu header widget
class _MenuHeader extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;

  const _MenuHeader({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Inline relationship selector widget
class _RelationshipSelector extends StatelessWidget {
  final RelationshipType selectedType;
  final String? customLabel;
  final void Function(RelationshipType type, String? customLabel) onChanged;

  const _RelationshipSelector({
    required this.selectedType,
    this.customLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          final result = await RelationshipSelectorMenu.show(
            context,
            selectedType: selectedType,
            customLabel: customLabel,
          );
          if (result != null) {
            onChanged(result.$1, result.$2);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(
              (255 * 0.5).toInt(),
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: MentoringColors.getRelationshipColor(
                    selectedType,
                  ).withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    selectedType.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customLabel ?? selectedType.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${selectedType.mentorLabel} → ${selectedType.ownerLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline duration selector widget (compact mode)
class _DurationSelector extends StatelessWidget {
  final AccessDuration selectedDuration;
  final ValueChanged<AccessDuration> onChanged;
  final bool compact;

  const _DurationSelector({
    required this.selectedDuration,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      // Horizontal scrollable chips
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: AccessDuration.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final duration = AccessDuration.values[index];
            final isSelected = selectedDuration == duration;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(duration),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        duration.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        duration.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Full selector (tap to open menu)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          final result = await DurationSelectorMenu.show(
            context,
            selectedDuration: selectedDuration,
          );
          if (result != null) {
            onChanged(result);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(
              (255 * 0.5).toInt(),
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
            ),
          ),
          child: Row(
            children: [
              Text(
                selectedDuration.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDuration.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      selectedDuration.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen preview chips widget
class _ScreenPreviewChips extends StatelessWidget {
  final List<AccessibleScreen> screens;
  final VoidCallback onTap;

  const _ScreenPreviewChips({required this.screens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasAll =
        screens.length == AccessibleScreen.values.length &&
        AccessibleScreen.values.every((s) => screens.contains(s));
    final displayScreens = hasAll
        ? [AccessibleScreen.values.first]
        : screens.take(4).toList();
    final remainingCount = hasAll ? 0 : screens.length - 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(
              (255 * 0.3).toInt(),
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withAlpha((255 * 0.1).toInt()),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...displayScreens.map(
                      (screen) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasAll
                              ? colorScheme.primary.withAlpha(
                                  (255 * 0.1).toInt(),
                                )
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAll
                                ? colorScheme.primary.withAlpha(
                                    (255 * 0.3).toInt(),
                                  )
                                : colorScheme.outline.withAlpha(
                                    (255 * 0.2).toInt(),
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              screen.icon,
                              size: 14,
                              color: hasAll
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasAll ? 'All Screens' : screen.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: hasAll
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (remainingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withAlpha(
                            (255 * 0.5).toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$remainingCount more',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permission preview chips widget
class _PermissionPreviewChips extends StatelessWidget {
  final MentorshipPermissions permissions;
  final VoidCallback onTap;

  const _PermissionPreviewChips({
    required this.permissions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final enabledItems = <(IconData, String)>[];
    if (permissions.showPoints) enabledItems.add((Icons.stars, 'Points'));
    if (permissions.showStreak) {
      enabledItems.add((Icons.local_fire_department, 'Streak'));
    }
    if (permissions.showRank) enabledItems.add((Icons.leaderboard, 'Rank'));
    if (permissions.showTasks) enabledItems.add((Icons.task_alt, 'Tasks'));
    if (permissions.showGoals) enabledItems.add((Icons.flag, 'Goals'));
    if (permissions.showMood) enabledItems.add((Icons.mood, 'Mood'));

    final displayItems = enabledItems.take(4).toList();
    final remainingCount = enabledItems.length - 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(
              (255 * 0.3).toInt(),
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withAlpha((255 * 0.1).toInt()),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: displayItems.isEmpty
                    ? Text(
                        'Tap to configure',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...displayItems.map(
                            (item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.$1,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.$2,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (remainingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer.withAlpha(
                                  (255 * 0.5).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+$remainingCount more',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Submit button widget
class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;
  final List<Color>? gradient;

  const _SubmitButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: isEnabled && !isLoading
            ? LinearGradient(
                colors:
                    gradient ??
                    [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha((255 * 0.8).toInt()),
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled && !isLoading
            ? [
                BoxShadow(
                  color: (gradient?.first ?? colorScheme.primary).withAlpha(
                    (255 * 0.3).toInt(),
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled && !isLoading ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isEnabled
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: isEnabled
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: isEnabled
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CUSTOM ANIMATED BUILDER (to avoid conflict with Flutter's)
// ================================================================

/// Custom AnimatedBuilder to avoid conflict with Flutter's built-in
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

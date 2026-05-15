// ================================================================
// FILE: lib/features/mentoring/widgets/cards/mentoring_cards.dart
// All Cards for Mentoring Feature
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mentorship_model.dart';
import '../widgets/mentoring_utils.dart';
import '../widgets/mentoring_common_widgets.dart';
import '../../../chats/widgets/common/user_avatar_cached.dart';

// ================================================================
// PART 1: MENTOR CARD
// ================================================================

/// Card displaying a mentor (someone who can view my data)
class MentorCard extends StatefulWidget {
  final MentorshipConnection connection;
  final String? mentorName;
  final String? mentorAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onSettings;
  final VoidCallback? onPause;
  final VoidCallback? onRevoke;
  final bool showActions;
  final bool compact;

  const MentorCard({
    super.key,
    required this.connection,
    this.mentorName,
    this.mentorAvatar,
    this.onTap,
    this.onSettings,
    this.onPause,
    this.onRevoke,
    this.showActions = true,
    this.compact = false,
  });

  @override
  State<MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends State<MentorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MentoringConstants.fastAnimation,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: MentoringConstants.fastAnimation,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? colorScheme.primary.withAlpha((255 * 0.3).toInt())
                  : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  (255 * (isDarkMode ? 0.3 : 0.08)).toInt(),
                ),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 1 : 2),
              ),
            ],
          ),
          child: widget.compact
              ? _buildCompactContent(theme, colorScheme, isDarkMode)
              : _buildFullContent(theme, colorScheme, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildFullContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              _buildAvatar(colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.mentorName ?? 'Unknown Mentor',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        LiveStatusBadge(
                          isLive: widget.connection.isLiveEnabled,
                          isActive: widget.connection.isActive,
                          size: LiveBadgeSize.small,
                          showLabel: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RelationshipBadge(
                      type: widget.connection.relationshipType,
                      customLabel: widget.connection.relationshipLabel,
                      compact: true,
                    ),
                  ],
                ),
              ),
              if (widget.showActions) _buildPopupMenu(theme, colorScheme),
            ],
          ),

          const SizedBox(height: 16),

          // Screens & Permissions
          _buildInfoRow(
            theme,
            colorScheme,
            icon: Icons.phone_android,
            child: PermissionChips(
              screens: widget.connection.allowedScreens.screens,
              size: PermissionChipSize.small,
              maxVisible: 3,
            ),
          ),

          const SizedBox(height: 12),

          // Encouragement Section (New)
          if (widget.connection.encouragementCount > 0) ...[
            _buildEncouragementInfo(theme, colorScheme),
            const SizedBox(height: 12),
          ],

          // Stats Row
          Row(
            children: [
              // View Count
              _buildStatItem(
                theme,
                colorScheme,
                icon: Icons.visibility,
                value: '${widget.connection.viewCount}',
                label: 'views',
              ),
              const SizedBox(width: 16),
              // Last Viewed
              _buildStatItem(
                theme,
                colorScheme,
                icon: Icons.access_time,
                value: widget.connection.lastViewedLabel,
                label: 'last view',
              ),
              const Spacer(),
              // Expiry
              ExpiryCountdown(
                expiresAt: widget.connection.expiresAt,
                compact: true,
              ),
            ],
          ),

          // Quick Actions
          if (widget.showActions) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildQuickActions(theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildAvatar(colorScheme, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mentorName ?? 'Unknown Mentor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      widget.connection.relationshipType.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.connection.displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LiveStatusBadge(
            isLive: widget.connection.isLiveEnabled,
            isActive: widget.connection.isActive,
            size: LiveBadgeSize.small,
            showLabel: false,
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildEncouragementInfo(ThemeData theme, ColorScheme colorScheme) {
    final type = widget.connection.lastEncouragementType ?? 'emoji';
    final message = widget.connection.lastEncouragementMessage;
    final time = widget.connection.lastEncouragementAt;
    final timeLabel = MentoringHelpers.formatTimeAgo(time);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.pink.withAlpha((255 * 0.05).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withAlpha((255 * 0.15).toInt())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.pink.withAlpha((255 * 0.1).toInt()),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, size: 14, color: Colors.pink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Received encouragement!',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                if (message != null && message.isNotEmpty)
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (type == 'custom_message' || type == 'quick_message')
                  Text(
                    'From ${widget.mentorName ?? 'Mentor'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    '${widget.mentorName ?? 'Mentor'} sent you a boost!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {double size = 48}) {
    return Stack(
      children: [
        UserAvatarCached(
          name: widget.mentorName ?? 'Mentor',
          imageUrl: widget.mentorAvatar,
          size: size,
        ),
        if (!widget.compact)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: MentoringColors.getStatusColor(
                  widget.connection.accessStatus,
                  Theme.of(context).brightness == Brightness.dark,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    final isPaused = widget.connection.isPaused;

    return Row(
      children: [
        // Pause/Resume
        Expanded(
          child: _ActionButton(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            label: isPaused ? 'Resume' : 'Pause',
            color: isPaused ? Colors.green : Colors.orange,
            onTap: widget.onPause,
          ),
        ),
        const SizedBox(width: 8),
        // Settings
        Expanded(
          child: _ActionButton(
            icon: Icons.settings,
            label: 'Settings',
            color: colorScheme.primary,
            onTap: widget.onSettings,
          ),
        ),
        const SizedBox(width: 8),
        // Revoke
        Expanded(
          child: _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Revoke',
            color: Colors.red,
            onTap: widget.onRevoke,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(ThemeData theme, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pause',
          child: Row(
            children: [
              Icon(
                widget.connection.isPaused ? Icons.play_arrow : Icons.pause,
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              Text(widget.connection.isPaused ? 'Resume' : 'Pause'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'revoke',
          child: Row(
            children: [
              const Icon(Icons.remove_circle, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              const Text('Revoke Access', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'settings':
            widget.onSettings?.call();
            break;
          case 'pause':
            widget.onPause?.call();
            break;
          case 'revoke':
            widget.onRevoke?.call();
            break;
        }
      },
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
}

// ================================================================
// PART 2: MENTEE CARD
// ================================================================

/// Card displaying a mentee (someone whose data I can view)
class MenteeCard extends StatefulWidget {
  final MentorshipConnection connection;
  final String? menteeName;
  final String? menteeAvatar;
  final int? currentStreak;
  final int? totalPoints;
  final bool? isActive;
  final VoidCallback? onTap;
  final VoidCallback? onViewProgress;
  final VoidCallback? onEncourage;
  final VoidCallback? onMessage;
  final bool showQuickStats;
  final bool showActions;
  final bool compact;

  const MenteeCard({
    super.key,
    required this.connection,
    this.menteeName,
    this.menteeAvatar,
    this.currentStreak,
    this.totalPoints,
    this.isActive,
    this.onTap,
    this.onViewProgress,
    this.onEncourage,
    this.onMessage,
    this.showQuickStats = true,
    this.showActions = true,
    this.compact = false,
  });

  @override
  State<MenteeCard> createState() => _MenteeCardState();
}

class _MenteeCardState extends State<MenteeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MentoringConstants.fastAnimation,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _needsAttention {
    if (widget.isActive == false) return true;
    return MentoringHelpers.isMenteeInactive(widget.connection);
  }

  int get _inactivityLevel {
    return MentoringHelpers.getInactivityLevel(widget.connection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: MentoringConstants.fastAnimation,
          decoration: BoxDecoration(
            gradient: _needsAttention
                ? LinearGradient(
                    colors: [
                      colorScheme.surface,
                      _inactivityLevel >= 2
                          ? Colors.red.withAlpha((255 * 0.05).toInt())
                          : Colors.orange.withAlpha((255 * 0.05).toInt()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _needsAttention ? null : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _needsAttention
                  ? (_inactivityLevel >= 2 ? Colors.red : Colors.orange)
                        .withAlpha((255 * 0.3).toInt())
                  : colorScheme.outline.withAlpha((255 * 0.2).toInt()),
              width: _needsAttention ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  (255 * (isDarkMode ? 0.3 : 0.08)).toInt(),
                ),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 1 : 2),
              ),
            ],
          ),
          child: widget.compact
              ? _buildCompactContent(theme, colorScheme, isDarkMode)
              : _buildFullContent(theme, colorScheme, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildFullContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attention Banner
          if (_needsAttention) ...[
            _buildAttentionBanner(theme, colorScheme),
            const SizedBox(height: 12),
          ],

          // Header Row
          Row(
            children: [
              _buildAvatar(colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.menteeName ?? 'Unknown Mentee',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildActivityIndicator(colorScheme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RelationshipBadge(
                      type: widget.connection.relationshipType,
                      customLabel: widget.connection.relationshipLabel,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick Stats
          if (widget.showQuickStats) ...[
            const SizedBox(height: 16),
            _buildQuickStats(theme, colorScheme),
          ],

          const SizedBox(height: 12),

          // Last Viewed Info
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Last viewed: ${widget.connection.lastViewedLabel}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (widget.connection.encouragementCount > 0)
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Colors.pink),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.connection.encouragementCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Quick Actions
          if (widget.showActions) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildQuickActions(theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildAvatar(colorScheme, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.menteeName ?? 'Unknown Mentee',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_needsAttention)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (_inactivityLevel >= 2
                                      ? Colors.red
                                      : Colors.orange)
                                  .withAlpha((255 * 0.1).toInt()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('⚠️', style: const TextStyle(fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.currentStreak != null) ...[
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.currentStreak}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.totalPoints != null) ...[
                      Icon(Icons.stars, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        _formatPoints(widget.totalPoints!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildActivityIndicator(colorScheme),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildAttentionBanner(ThemeData theme, ColorScheme colorScheme) {
    final isCritical = _inactivityLevel >= 2;
    final color = isCritical ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).toInt())),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCritical
                  ? 'Inactive for ${_getDaysInactive()} days - needs attention!'
                  : 'Activity has slowed down recently',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onEncourage,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Encourage',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {double size = 52}) {
    return Stack(
      children: [
        UserAvatarCached(
          name: widget.menteeName ?? 'Mentee',
          imageUrl: widget.menteeAvatar,
          size: size,
        ),
        // Streak badge
        if (widget.currentStreak != null && widget.currentStreak! > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Text('🔥', style: TextStyle(fontSize: size * 0.22)),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityIndicator(ColorScheme colorScheme) {
    final isActive = widget.isActive ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.grey).withAlpha(
          (255 * 0.1).toInt(),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Streak
        Expanded(
          child: _buildStatCard(
            theme,
            colorScheme,
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            value: widget.currentStreak?.toString() ?? '0',
            label: 'Streak',
          ),
        ),
        const SizedBox(width: 12),
        // Points
        Expanded(
          child: _buildStatCard(
            theme,
            colorScheme,
            icon: Icons.stars,
            iconColor: Colors.amber,
            value: _formatPoints(widget.totalPoints ?? 0),
            label: 'Points',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(
          (255 * 0.5).toInt(),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // View Progress
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: widget.onViewProgress,
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Progress'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Encourage
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onEncourage,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('👏'),
          ),
        ),
      ],
    );
  }

  int _getDaysInactive() {
    if (widget.connection.lastViewedAt == null) return 0;
    return DateTime.now().difference(widget.connection.lastViewedAt!).inDays;
  }

  String _formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
}

// ================================================================
// PART 3: REQUEST CARD
// ================================================================

/// Card displaying a pending request
class RequestCard extends StatefulWidget {
  final MentorshipConnection request;
  final String? userName;
  final String? userAvatar;
  final bool isIncoming;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onCustomize;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final bool compact;

  const RequestCard({
    super.key,
    required this.request,
    this.userName,
    this.userAvatar,
    required this.isIncoming,
    this.onTap,
    this.onAccept,
    this.onCustomize,
    this.onDecline,
    this.onCancel,
    this.compact = false,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isIncoming
                  ? [
                      colorScheme.surface,
                      colorScheme.primaryContainer.withAlpha(
                        (255 * 0.1).toInt(),
                      ),
                    ]
                  : [
                      colorScheme.surface,
                      colorScheme.secondaryContainer.withAlpha(
                        (255 * 0.1).toInt(),
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isIncoming
                  ? colorScheme.primary.withAlpha((255 * 0.2).toInt())
                  : colorScheme.secondary.withAlpha((255 * 0.2).toInt()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(
                  (255 * (isDarkMode ? 0.3 : 0.08)).toInt(),
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.compact
              ? _buildCompactContent(theme, colorScheme)
              : _buildFullContent(theme, colorScheme, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildFullContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request Type Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (widget.isIncoming
                              ? colorScheme.primary
                              : colorScheme.secondary)
                          .withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isIncoming
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 14,
                      color: widget.isIncoming
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isIncoming ? 'Incoming' : 'Outgoing',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.isIncoming
                            ? colorScheme.primary
                            : colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                MentoringHelpers.formatTimeAgo(widget.request.requestedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Info
          Row(
            children: [
              _buildAvatar(colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName ?? 'Unknown User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isIncoming
                          ? 'wants to view your progress'
                          : 'you requested access',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Request Details
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
                _buildDetailRow(
                  theme,
                  colorScheme,
                  icon: Icons.handshake,
                  label: 'Relationship',
                  child: RelationshipBadge(
                    type: widget.request.relationshipType,
                    customLabel: widget.request.relationshipLabel,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  theme,
                  colorScheme,
                  icon: Icons.phone_android,
                  label: 'Screens',
                  child: PermissionChips(
                    screens: widget.request.allowedScreens.screens,
                    size: PermissionChipSize.small,
                    maxVisible: 2,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  theme,
                  colorScheme,
                  icon: Icons.timer,
                  label: 'Duration',
                  value: widget.request.duration.label,
                ),
              ],
            ),
          ),

          // Message
          if (widget.request.requestMessage?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
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
                      widget.request.requestMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildAvatar(colorScheme, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.userName ?? 'Unknown User',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (widget.isIncoming
                                    ? colorScheme.primary
                                    : colorScheme.secondary)
                                .withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.isIncoming ? '📥' : '📤',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.request.relationshipType.emoji} ${widget.request.displayLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isIncoming) ...[
            IconButton(
              onPressed: widget.onAccept,
              icon: const Icon(Icons.check, color: Colors.green),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withAlpha((255 * 0.1).toInt()),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: widget.onDecline,
              icon: const Icon(Icons.close, color: Colors.red),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withAlpha((255 * 0.1).toInt()),
              ),
            ),
          ] else ...[
            TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, {double size = 48}) {
    final color = MentoringHelpers.getAvatarColor(widget.userName);
    final initials = MentoringHelpers.getInitials(widget.userName);

    return widget.userAvatar != null
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(widget.userAvatar!),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: color,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35,
              ),
            ),
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
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: value != null
              ? Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : child ?? const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    if (widget.isIncoming) {
      return Row(
        children: [
          // Accept
          Expanded(
            child: FilledButton.icon(
              onPressed: widget.onAccept,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Customize
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onCustomize,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Customize'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Decline
          IconButton(
            onPressed: widget.onDecline,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withAlpha((255 * 0.1).toInt()),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for response...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  }
}

// ================================================================
// PART 4: ACCESS STATS CARD
// ================================================================

/// Card displaying access statistics summary
class AccessStatsCard extends StatelessWidget {
  final int totalMentors;
  final int totalMentees;
  final int pendingIncoming;
  final int pendingOutgoing;
  final int activeMentors;
  final int activeMentees;
  final VoidCallback? onMentorsTap;
  final VoidCallback? onMenteesTap;
  final VoidCallback? onRequestsTap;
  final bool compact;

  const AccessStatsCard({
    super.key,
    required this.totalMentors,
    required this.totalMentees,
    required this.pendingIncoming,
    required this.pendingOutgoing,
    this.activeMentors = 0,
    this.activeMentees = 0,
    this.onMentorsTap,
    this.onMenteesTap,
    this.onRequestsTap,
    this.compact = false,
  });

  int get totalPending => pendingIncoming + pendingOutgoing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactCard(theme, colorScheme, isDarkMode);
    }

    return _buildFullCard(theme, colorScheme, isDarkMode);
  }

  Widget _buildFullCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  colorScheme.surface,
                  colorScheme.primaryContainer.withAlpha((255 * 0.1).toInt()),
                ]
              : [
                  colorScheme.primaryContainer.withAlpha((255 * 0.3).toInt()),
                  colorScheme.secondaryContainer.withAlpha((255 * 0.2).toInt()),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withAlpha((255 * 0.1).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha((255 * 0.1).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mentoring Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your connections at a glance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              // My Mentors
              Expanded(
                child: _StatTile(
                  icon: Icons.supervisor_account,
                  iconColor: Colors.blue,
                  value: totalMentors,
                  label: 'My Mentors',
                  subtitle: '$activeMentors active',
                  onTap: onMentorsTap,
                ),
              ),
              const SizedBox(width: 16),
              // My Mentees
              Expanded(
                child: _StatTile(
                  icon: Icons.school,
                  iconColor: Colors.green,
                  value: totalMentees,
                  label: 'My Mentees',
                  subtitle: '$activeMentees active',
                  onTap: onMenteesTap,
                ),
              ),
            ],
          ),

          // Pending Requests
          if (totalPending > 0) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onRequestsTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withAlpha((255 * 0.2).toInt()),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((255 * 0.2).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalPending Pending Request${totalPending > 1 ? 's' : ''}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Text(
                            '$pendingIncoming incoming • $pendingOutgoing outgoing',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange.shade700),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
        ),
      ),
      child: Row(
        children: [
          // Mentors
          Expanded(
            child: _CompactStatItem(
              icon: Icons.supervisor_account,
              iconColor: Colors.blue,
              value: totalMentors,
              label: 'Mentors',
              onTap: onMentorsTap,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
          ),
          // Mentees
          Expanded(
            child: _CompactStatItem(
              icon: Icons.school,
              iconColor: Colors.green,
              value: totalMentees,
              label: 'Mentees',
              onTap: onMenteesTap,
            ),
          ),
          if (totalPending > 0) ...[
            Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withAlpha((255 * 0.2).toInt()),
            ),
            // Pending
            Expanded(
              child: _CompactStatItem(
                icon: Icons.pending_actions,
                iconColor: Colors.orange,
                value: totalPending,
                label: 'Pending',
                onTap: onRequestsTap,
                showBadge: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// HELPER WIDGETS
// ================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withAlpha((255 * 0.1).toInt()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Text(
                  animatedValue.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                );
              },
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(
                    (255 * 0.7).toInt(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final VoidCallback? onTap;
  final bool showBadge;

  const _CompactStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: iconColor, size: 24),
              if (showBadge && value > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      value > 9 ? '9+' : value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Note: Flutter's built-in AnimatedBuilder is used directly throughout this file.

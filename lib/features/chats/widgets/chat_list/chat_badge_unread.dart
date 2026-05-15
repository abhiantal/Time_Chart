// ================================================================
// FILE: lib/features/chat/widgets/chat_list/chat_badge_unread.dart
// PURPOSE: Unread count badge, mention badge, and status indicators
// STYLE: WhatsApp + Snapchat Hybrid
// DEPENDENCIES: None - Pure widget
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BadgeType {
  unread, // Blue circle with count
  mention, // @ badge for mentions
  dot, // Small dot for notifications
  muted, // Muted icon
  pinned, // Pinned icon
  archived, // Archived icon
  verified, // Verified checkmark
}

class ChatBadgeUnread extends StatefulWidget {
  final BadgeType type;
  final int? count;
  final double size;
  final Color? color;
  final bool animate;
  final VoidCallback? onTap;

  const ChatBadgeUnread({
    super.key,
    required this.type,
    this.count,
    this.size = 20,
    this.color,
    this.animate = true,
    this.onTap,
  });

  // Factory constructors
  const ChatBadgeUnread.count({
    super.key,
    required int count,
    this.size = 20,
    this.color,
    this.animate = true,
    this.onTap,
  }) : type = BadgeType.unread,
       count = count;

  const ChatBadgeUnread.mention({
    super.key,
    this.size = 20,
    this.color,
    this.animate = true,
    this.onTap,
  }) : type = BadgeType.mention,
       count = null;

  const ChatBadgeUnread.dot({
    super.key,
    this.size = 10,
    this.color,
    this.animate = true,
    this.onTap,
  }) : type = BadgeType.dot,
       count = null;

  const ChatBadgeUnread.muted({
    super.key,
    this.size = 16,
    this.color,
    this.animate = false,
    this.onTap,
  }) : type = BadgeType.muted,
       count = null;

  const ChatBadgeUnread.pinned({
    super.key,
    this.size = 16,
    this.color,
    this.animate = false,
    this.onTap,
  }) : type = BadgeType.pinned,
       count = null;

  const ChatBadgeUnread.archived({
    super.key,
    this.size = 16,
    this.color,
    this.animate = false,
    this.onTap,
  }) : type = BadgeType.archived,
       count = null;

  const ChatBadgeUnread.verified({
    super.key,
    this.size = 16,
    this.color,
    this.animate = true,
    this.onTap,
  }) : type = BadgeType.verified,
       count = null;

  @override
  State<ChatBadgeUnread> createState() => _ChatBadgeUnreadState();
}

class _ChatBadgeUnreadState extends State<ChatBadgeUnread>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.forward();

      if (widget.type == BadgeType.unread ||
          widget.type == BadgeType.mention ||
          widget.type == BadgeType.dot) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale:
              widget.type == BadgeType.unread ||
                  widget.type == BadgeType.mention ||
                  widget.type == BadgeType.dot
              ? _pulseAnimation.value
              : _scaleAnimation.value,
          child: Opacity(
            opacity: _scaleAnimation.value,
            child: _buildBadge(colorScheme),
          ),
        );
      },
    );
  }

  Widget _buildBadge(ColorScheme colorScheme) {
    switch (widget.type) {
      case BadgeType.unread:
        return _buildUnreadBadge(colorScheme);
      case BadgeType.mention:
        return _buildMentionBadge(colorScheme);
      case BadgeType.dot:
        return _buildDotBadge(colorScheme);
      case BadgeType.muted:
        return _buildMutedBadge(colorScheme);
      case BadgeType.pinned:
        return _buildPinnedBadge(colorScheme);
      case BadgeType.archived:
        return _buildArchivedBadge(colorScheme);
      case BadgeType.verified:
        return _buildVerifiedBadge(colorScheme);
    }
  }

  Widget _buildUnreadBadge(ColorScheme colorScheme) {
    final count = widget.count ?? 0;
    if (count <= 0) return const SizedBox.shrink();

    final displayText = count > 99 ? '99+' : count.toString();
    final isWide = displayText.length > 2;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.size,
          minHeight: widget.size,
        ),
        padding: EdgeInsets.symmetric(horizontal: isWide ? 6 : 0, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color ?? colorScheme.primary,
          borderRadius: BorderRadius.circular(widget.size / 2),
          boxShadow: [
            BoxShadow(
              color: (widget.color ?? colorScheme.primary).withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: widget.size * 0.6,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMentionBadge(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color ?? colorScheme.tertiary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (widget.color ?? colorScheme.tertiary).withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '@',
            style: TextStyle(
              color: colorScheme.onTertiary,
              fontSize: widget.size * 0.6,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotBadge(ColorScheme colorScheme) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color ?? colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (widget.color ?? colorScheme.primary).withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMutedBadge(ColorScheme colorScheme) {
    return Icon(
      Icons.volume_off_rounded,
      size: widget.size,
      color: widget.color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }

  Widget _buildPinnedBadge(ColorScheme colorScheme) {
    return Icon(
      Icons.push_pin_rounded,
      size: widget.size,
      color: widget.color ?? colorScheme.primary,
    );
  }

  Widget _buildArchivedBadge(ColorScheme colorScheme) {
    return Icon(
      Icons.archive_rounded,
      size: widget.size,
      color: widget.color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }

  Widget _buildVerifiedBadge(ColorScheme colorScheme) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: SweepGradient(
          colors: [
            widget.color ?? colorScheme.primary,
            widget.color ?? colorScheme.secondary,
            widget.color ?? colorScheme.primary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (widget.color ?? colorScheme.primary).withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          size: widget.size * 0.7,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// ================================================================
// BADGE WRAPPER - For positioning badges on avatars/icons
// ================================================================

class BadgeWrapper extends StatelessWidget {
  final Widget child;
  final Widget badge;
  final Alignment alignment;
  final Offset offset;
  final bool show;

  const BadgeWrapper({
    super.key,
    required this.child,
    required this.badge,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft
              ? -4 + offset.dy
              : null,
          bottom:
              alignment == Alignment.bottomRight ||
                  alignment == Alignment.bottomLeft
              ? -4 + offset.dy
              : null,
          right:
              alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight
              ? -4 + offset.dx
              : null,
          left:
              alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft
              ? -4 + offset.dx
              : null,
          child: badge,
        ),
      ],
    );
  }
}

// ================================================================
// BADGE ROW - Multiple badges in a row
// ================================================================

class BadgeRow extends StatelessWidget {
  final int unreadCount;
  final bool hasMention;
  final bool isMuted;
  final bool isPinned;
  final bool isArchived;
  final bool isVerified;
  final double spacing;
  final double badgeSize;

  const BadgeRow({
    super.key,
    this.unreadCount = 0,
    this.hasMention = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isVerified = false,
    this.spacing = 4,
    this.badgeSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (isVerified) {
      children.add(ChatBadgeUnread.verified(size: badgeSize, animate: true));
    }

    if (isPinned) {
      children.add(ChatBadgeUnread.pinned(size: badgeSize));
    }

    if (isMuted) {
      children.add(ChatBadgeUnread.muted(size: badgeSize));
    }

    if (isArchived) {
      children.add(ChatBadgeUnread.archived(size: badgeSize));
    }

    if (hasMention) {
      children.add(ChatBadgeUnread.mention(size: badgeSize));
    } else if (unreadCount > 0) {
      children.add(ChatBadgeUnread.count(count: unreadCount, size: badgeSize));
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? spacing : 0),
          child: child,
        );
      }).toList(),
    );
  }
}

// ================================================================
// ANIMATED BADGE - Pulse effect for notifications
// ================================================================

class AnimatedBadge extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;
  final double scale;

  const AnimatedBadge({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1000),
    this.scale = 1.2,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}

// ================================================================
// STATUS BADGE - For admin/owner/mod roles
// ================================================================

enum MemberRole { owner, admin, moderator, member }

class RoleBadge extends StatelessWidget {
  final MemberRole role;
  final bool compact;
  final double size;

  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (role == MemberRole.member) return const SizedBox.shrink();

    final config = _getRoleConfig(colorScheme);

    if (compact) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(config.icon, size: size * 0.6, color: config.color),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  _RoleConfig _getRoleConfig(ColorScheme colorScheme) {
    switch (role) {
      case MemberRole.owner:
        return _RoleConfig(
          label: 'Owner',
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B),
        );
      case MemberRole.admin:
        return _RoleConfig(
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
          color: const Color(0xFF3B82F6),
        );
      case MemberRole.moderator:
        return _RoleConfig(
          label: 'Mod',
          icon: Icons.shield_rounded,
          color: const Color(0xFF10B981),
        );
      case MemberRole.member:
        return _RoleConfig(
          label: 'Member',
          icon: Icons.person_rounded,
          color: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _RoleConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ================================================================
// ONLINE STATUS BADGE - For chat list
// ================================================================

class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool isTyping;
  final double size;
  final bool showPulse;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    this.isTyping = false,
    this.size = 12,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline && !isTyping) return const SizedBox.shrink();

    final color = isTyping
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF22C55E);

    if (isTyping) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return AnimatedBadge(
      animate: showPulse,
      duration: const Duration(milliseconds: 1500),
      scale: 1.3,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          ),
          boxShadow: showPulse
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

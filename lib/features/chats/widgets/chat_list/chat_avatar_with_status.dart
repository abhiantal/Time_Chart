// ================================================================
// FILE: lib/features/chat/widgets/chat_list/chat_avatar_with_status.dart
// PURPOSE: Avatar with online status, story rings, and pulse animation
// STYLE: WhatsApp + Snapchat Hybrid
// DEPENDENCIES: user_avatar_cached.dart
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/user_avatar_cached.dart';

enum AvatarStoryStatus {
  unseen, // Blue ring - has unviewed story
  seen, // Grey ring - viewed story
  none, // No story
  uploading, // Uploading story
}

class ChatAvatarWithStatus extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool isTyping;
  final bool isGroup;
  final bool isCommunity;
  final AvatarStoryStatus storyStatus;
  final double? storyRingWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showPulseAnimation;
  final bool showBorder;

  const ChatAvatarWithStatus({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 52,
    this.isOnline = false,
    this.isTyping = false,
    this.isGroup = false,
    this.isCommunity = false,
    this.storyStatus = AvatarStoryStatus.none,
    this.storyRingWidth,
    this.onTap,
    this.onLongPress,
    this.showPulseAnimation = true,
    this.showBorder = true,
  });

  @override
  State<ChatAvatarWithStatus> createState() => _ChatAvatarWithStatusState();
}

class _ChatAvatarWithStatusState extends State<ChatAvatarWithStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulseAnimation &&
        (widget.isOnline ||
            widget.storyStatus == AvatarStoryStatus.uploading)) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChatAvatarWithStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulseAnimation &&
        (widget.isOnline ||
            widget.storyStatus == AvatarStoryStatus.uploading)) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final storyWidth = widget.storyRingWidth ?? widget.size * 0.06;
    final hasStory = widget.storyStatus != AvatarStoryStatus.none;
    final isStoryUnseen = widget.storyStatus == AvatarStoryStatus.unseen;
    final isStoryUploading = widget.storyStatus == AvatarStoryStatus.uploading;

    Widget avatar = UserAvatarCached(
      imageUrl: widget.imageUrl,
      name: widget.name,
      size: widget.size - (hasStory ? storyWidth * 2 : 0),
      isGroup: widget.isGroup,
      isCommunity: widget.isCommunity,
      borderRadius: widget.isGroup ? 8 : widget.size / 2,
    );

    // Wrap with story ring
    if (hasStory) {
      avatar = Container(
        padding: EdgeInsets.all(storyWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isStoryUnseen
              ? SweepGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.tertiary,
                    colorScheme.primary,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                )
              : null,
          color: isStoryUnseen
              ? null
              : isStoryUploading
              ? Colors.orange
              : Colors.grey.shade400,
        ),
        child: avatar,
      );
    }

    // Add pulse animation for online or uploading
    if (widget.isOnline && widget.showPulseAnimation) {
      avatar = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * _pulseAnimation.value,
                height: widget.size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF22C55E,
                  ).withValues(alpha: 0.3 * (1 - (_pulseAnimation.value - 1) / 0.2)),
                ),
              ),
              child!,
            ],
          );
        },
        child: avatar,
      );
    }

    // Wrap with online/typing indicator
    if (widget.isOnline || widget.isTyping) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.size * 0.22,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                color: widget.isTyping
                    ? colorScheme.primary
                    : const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: widget.showBorder
                    ? Border.all(
                        color: colorScheme.surface,
                        width: widget.size * 0.03,
                      )
                    : null,
              ),
              child: widget.isTyping
                  ? Center(
                      child: SizedBox(
                        width: widget.size * 0.1,
                        height: widget.size * 0.1,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    // Add touch handling
    if (widget.onTap != null || widget.onLongPress != null) {
      avatar = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: avatar,
      );
    }

    return avatar;
  }
}

// ================================================================
// STORY RING AVATAR - Snapchat Style
// ================================================================

class StoryRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool hasUnseenStory;
  final bool isUploading;
  final VoidCallback? onTap;

  const StoryRingAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 56,
    this.hasUnseenStory = false,
    this.isUploading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = hasUnseenStory
        ? AvatarStoryStatus.unseen
        : isUploading
        ? AvatarStoryStatus.uploading
        : AvatarStoryStatus.seen;

    return ChatAvatarWithStatus(
      imageUrl: imageUrl,
      name: name,
      size: size,
      storyStatus: status,
      showPulseAnimation: isUploading,
      onTap: onTap,
    );
  }
}

// ================================================================
// GROUP AVATAR STACK - Multiple Members
// ================================================================

class GroupAvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final String groupName;
  final double size;
  final int maxAvatars;
  final bool isOnline;

  const GroupAvatarStack({
    super.key,
    required this.imageUrls,
    required this.groupName,
    this.size = 52,
    this.maxAvatars = 3,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayUrls = imageUrls.take(maxAvatars).toList();
    final remaining = imageUrls.length - maxAvatars;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Main avatar
          Positioned(
            left: 0,
            bottom: 0,
            child: UserAvatar(
              imageUrl: displayUrls.isNotEmpty ? displayUrls[0] : null,
              name: groupName,
              isGroup: true,
            ),
          ),

          // Secondary avatar (overlap)
          if (displayUrls.length > 1)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: UserAvatar(
                  imageUrl: displayUrls[1],
                  name: groupName,
                  isGroup: true,
                ),
              ),
            ),

          // Remaining count badge
          if (remaining > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

          // Online indicator
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

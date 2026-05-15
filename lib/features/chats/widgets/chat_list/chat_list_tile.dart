// ================================================================
// FILE: lib/features/chat/widgets/chat_list/chat_list_tile.dart
// CHAT LIST TILE - Fixed
// ✅ No swipe icon overlapping avatar
// ✅ Null-safe displayName and displayAvatar
// ✅ Clean avatar — no clipping issues
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/chat_date_utils.dart';
import '../../utils/chat_text_utils.dart';
import '../../widgets/common/user_avatar_cached.dart';
import 'chat_swipe_actions.dart';
import '../../model/chat_model.dart';

enum ChatTileVariant { personal, group, community }

extension ChatModelTileExt on ChatModel {
  ChatTileVariant get variant {
    if (isCommunity) return ChatTileVariant.community;
    if (isGroup) return ChatTileVariant.group;
    return ChatTileVariant.personal;
  }

  bool get hasMentions => unreadMentions > 0;

  String get safeName => displayName;

  String? get safeAvatar => otherUserAvatar;
}

class ChatListTile extends StatefulWidget {
  final ChatModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onMarkRead;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onSelectionToggle;
  final bool isOnline;
  final bool isTyping;
  final List<String> typingUsers;
  final bool isDraft;
  final bool isPinned;

  const ChatListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onArchive,
    this.onDelete,
    this.onPin,
    this.onMute,
    this.onMarkRead,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionToggle,
    this.isOnline = false,
    this.isTyping = false,
    this.typingUsers = const [],
    this.isDraft = false,
    this.isPinned = false,
  });

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.985,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isMultiSelectMode) {
      _tapController.forward();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.isMultiSelectMode) {
      _tapController.reverse();
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (!widget.isMultiSelectMode) {
      _tapController.reverse();
      setState(() => _isPressed = false);
    }
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    if (widget.isMultiSelectMode) {
      widget.onSelectionToggle?.call();
    } else {
      widget.onTap?.call();
    }
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    if (!widget.isMultiSelectMode) widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Only wrap with swipe if NOT in multi-select mode and callbacks exist
    if (!widget.isMultiSelectMode &&
        (widget.onArchive != null || widget.onDelete != null)) {
      return ChatSwipeActions(
        onLeftSwipe: widget.onDelete,
        onRightSwipe: widget.onArchive,
        leftActionType: widget.onDelete != null ? SwipeActionType.delete : null,
        rightActionType: widget.onArchive != null
            ? SwipeActionType.archive
            : null,
        enableLeftSwipe: widget.onDelete != null,
        enableRightSwipe: widget.onArchive != null,
        child: _buildTileContent(),
      );
    }
    return _buildTileContent();
  }

  Widget _buildTileContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isPressed ? _scaleAnimation.value : 1.0,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(colorScheme),
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onTap,
            onLongPress: _onLongPress,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            splashColor: colorScheme.primary.withValues(alpha: 0.05),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.isMultiSelectMode) ...[
                    _buildCheckbox(colorScheme),
                    const SizedBox(width: 12),
                  ],
                  _buildAvatar(colorScheme, item),
                  const SizedBox(width: 12),
                  Expanded(child: _buildChatInfo(theme, colorScheme, item)),
                  const SizedBox(width: 8),
                  _buildTimeAndBadges(theme, colorScheme, item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(ColorScheme colorScheme) {
    if (widget.isSelected) {
      return colorScheme.primaryContainer.withValues(alpha: 0.25);
    }
    if (widget.item.unreadCount > 0 && !widget.item.isMuted) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.25);
    }
    return Colors.transparent;
  }

  Widget _buildAvatar(ColorScheme colorScheme, ChatModel item) {
    const double avatarSize = 52;
    const double dotSize = 14;
    const double dotBorder = 2;

    return SizedBox(
      width: avatarSize + dotSize / 2,
      height: avatarSize + dotSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: ClipOval(
                child: UserAvatarCached(
                  imageUrl: item.otherUserAvatar,
                  name: item.displayName,
                  size: avatarSize,
                  isGroup: item.variant == ChatTileVariant.group,
                  isCommunity: item.variant == ChatTileVariant.community,
                ),
              ),
            ),
          ),
          if (widget.isOnline && !widget.isTyping)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: dotBorder,
                  ),
                ),
              ),
            ),
          if (widget.isTyping)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: dotSize + 2,
                height: dotSize + 2,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: dotBorder,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 7,
                    height: 7,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatInfo(
    ThemeData theme,
    ColorScheme colorScheme,
    ChatModel item,
  ) {
    final hasUnread = item.unreadCount > 0;

    final nameStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
      fontSize: 15,
      color: colorScheme.onSurface,
    );

    final msgStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      color: hasUnread
          ? colorScheme.onSurface
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.safeName,
                style: nameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildMessageIcons(colorScheme, item),
            Expanded(
              child: widget.isTyping
                  ? _buildTypingIndicator(theme, colorScheme)
                  : _buildMessagePreview(theme, colorScheme, item, msgStyle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageIcons(ColorScheme colorScheme, ChatModel item) {
    final icons = <Widget>[];
    if (widget.isDraft) {
      icons.add(Icon(Icons.edit_rounded, size: 13, color: colorScheme.primary));
    }
    if (icons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: icons),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 14,
          child: _TypingDotsAnimation(color: colorScheme.primary),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _typingText(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _typingText() {
    if (widget.item.variant == ChatTileVariant.personal) return 'typing...';
    if (widget.typingUsers.isEmpty) return 'typing...';
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers[0]} is typing...';
    }
    if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing...';
    }
    return '${widget.typingUsers[0]} and ${widget.typingUsers.length - 1} others are typing...';
  }

  Widget _buildMessagePreview(
    ThemeData theme,
    ColorScheme colorScheme,
    ChatModel item,
    TextStyle? style,
  ) {
    if (widget.isDraft) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: style,
          children: [
            TextSpan(
              text: 'Draft: ',
              style: style?.copyWith(
                color: const Color(0xFF00A884), // WhatsApp Teal
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(text: item.lastMessagePreview),
          ],
        ),
      );
    }

    final preview = ChatTextUtils.cleanMentions(item.lastMessagePreview);

    if ((item.variant == ChatTileVariant.group ||
            item.variant == ChatTileVariant.community) &&
        preview.isNotEmpty) {
      if (preview.startsWith('👤') ||
          preview.startsWith('📋') ||
          preview.startsWith('🔗')) {
        return Text(
          preview,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: style,
          children: [
            if (item.otherUserName != null && item.otherUserName!.isNotEmpty)
              TextSpan(
                text: '${item.otherUserName}: ',
                style: style?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            TextSpan(text: preview),
          ],
        ),
      );
    }

    return Text(
      preview.isEmpty ? 'No messages yet' : preview,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

  }

  Widget _buildTimeAndBadges(
    ThemeData theme,
    ColorScheme colorScheme,
    ChatModel item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.lastMessageTime != null)
          Text(
            ChatDateUtils.formatChatListTimeCompact(item.lastMessageTime!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: item.hasUnread
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
              fontWeight: item.hasUnread ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isPinned) ...[
              Icon(
                Icons.push_pin_rounded,
                size: 13,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 3),
            ],
            if (item.unreadMentions > 0)
              _mentionBadge(colorScheme)
            else if (item.unreadCount > 0)
              _unreadBadge(colorScheme, item.unreadCount)
            else if (item.isMuted)
              Icon(
                Icons.volume_off_rounded,
                size: 15,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
          ],
        ),
      ],
    );
  }

  Widget _unreadBadge(ColorScheme colorScheme, int count) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: EdgeInsets.symmetric(
        horizontal: label.length > 2 ? 6 : 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _mentionBadge(ColorScheme colorScheme) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: colorScheme.tertiary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '@',
          style: TextStyle(
            color: colorScheme.onTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(ColorScheme colorScheme) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: widget.isSelected ? 2 : 1.5,
        ),
        color: widget.isSelected ? colorScheme.primary : Colors.transparent,
      ),
      child: widget.isSelected
          ? Icon(Icons.check_rounded, size: 15, color: colorScheme.onPrimary)
          : null,
    );
  }
}

class _TypingDotsAnimation extends StatefulWidget {
  final Color color;
  const _TypingDotsAnimation({required this.color});

  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    _animate();
  }

  void _animate() async {
    while (mounted) {
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].forward();
        await Future.delayed(const Duration(milliseconds: 120));
      }
      await Future.delayed(const Duration(milliseconds: 250));
      for (int i = 0; i < 3; i++) {
        if (!mounted) return;
        _controllers[i].reverse();
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -3.5 * _animations[i].value),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 
                  0.4 + 0.6 * _animations[i].value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

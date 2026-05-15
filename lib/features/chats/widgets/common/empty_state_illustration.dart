// ================================================================
// FILE: lib/features/chat/widgets/common/empty_state_illustration.dart
// PURPOSE: Empty state widgets with illustrations and animations
// STYLE: Clean, colorful illustrations with action buttons
// DEPENDENCIES: None - Pure widget
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum EmptyStateType {
  noChats,
  noMessages,
  noSearchResults,
  noMedia,
  noDocuments,
  noLinks,
  noMembers,
  noNotifications,
  noArchived,
  noBlocked,
  error,
  offline,
  custom,
}

class EmptyStateIllustration extends StatefulWidget {
  final EmptyStateType type;
  final IconData? icon;
  final Widget? illustration;
  final String? title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? additionalContent;
  final bool compact;
  final bool centerVertically;

  const EmptyStateIllustration({
    super.key,
    this.type = EmptyStateType.custom,
    this.icon,
    this.illustration,
    this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.additionalContent,
    this.compact = false,
    this.centerVertically = true,
  });

  // Preset constructors
  const EmptyStateIllustration.noChats({super.key, this.onAction})
    : type = EmptyStateType.noChats,
      icon = null,
      illustration = null,
      title = 'No conversations yet',
      description = 'Start a new chat to connect with friends and groups',
      actionLabel = 'Start Chat',
      secondaryActionLabel = null,
      onSecondaryAction = null,
      additionalContent = null,
      compact = false,
      centerVertically = true;

  const EmptyStateIllustration.noMessages({
    super.key,
    String? customTitle,
    String? customDescription,
  }) : type = EmptyStateType.noMessages,
       icon = null,
       illustration = null,
       title = customTitle ?? 'No messages yet',
       description =
           customDescription ?? 'Send a message to start the conversation',
       actionLabel = null,
       onAction = null,
       secondaryActionLabel = null,
       onSecondaryAction = null,
       additionalContent = null,
       compact = false,
       centerVertically = true;

  const EmptyStateIllustration.noSearchResults({
    super.key,
    String? searchQuery,
    this.onAction,
  }) : type = EmptyStateType.noSearchResults,
       icon = null,
       illustration = null,
       title = 'No results found',
       description = searchQuery != null
           ? 'No results for "$searchQuery"'
           : 'Try a different search term',
       actionLabel = onAction != null ? 'Clear Search' : null,
       secondaryActionLabel = null,
       onSecondaryAction = null,
       additionalContent = null,
       compact = true,
       centerVertically = true;

  const EmptyStateIllustration.noMedia({super.key})
    : type = EmptyStateType.noMedia,
      icon = null,
      illustration = null,
      title = 'No media yet',
      description = 'Photos and videos shared here will appear',
      actionLabel = null,
      onAction = null,
      secondaryActionLabel = null,
      onSecondaryAction = null,
      additionalContent = null,
      compact = false,
      centerVertically = true;

  const EmptyStateIllustration.offline({super.key, this.onAction})
    : type = EmptyStateType.offline,
      icon = null,
      illustration = null,
      title = 'You\'re offline',
      description = 'Check your internet connection',
      actionLabel = 'Retry',
      secondaryActionLabel = null,
      onSecondaryAction = null,
      additionalContent = null,
      compact = false,
      centerVertically = true;

  const EmptyStateIllustration.error({
    super.key,
    String? message,
    this.onAction,
  }) : type = EmptyStateType.error,
       icon = null,
       illustration = null,
       title = 'Something went wrong',
       description = message ?? 'Please try again',
       actionLabel = 'Try Again',
       secondaryActionLabel = null,
       onSecondaryAction = null,
       additionalContent = null,
       compact = false,
       centerVertically = true;

  @override
  State<EmptyStateIllustration> createState() => _EmptyStateIllustrationState();
}

class _EmptyStateIllustrationState extends State<EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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

    if (!widget.centerVertically) {
      return _buildContent(context, theme, colorScheme);
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: widget.compact ? 32 : 48,
          horizontal: 24,
        ),
        child: _buildContent(context, theme, colorScheme),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              _buildIllustration(context, theme, colorScheme),
              SizedBox(height: widget.compact ? 24 : 32),

              // Title
              if (_getTitle() != null) ...[
                Text(
                  _getTitle()!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // Description
              if (_getDescription() != null) ...[
                Text(
                  _getDescription()!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: widget.compact ? 24 : 32),
              ],

              // Additional content
              if (widget.additionalContent != null) ...[
                widget.additionalContent!,
                const SizedBox(height: 24),
              ],

              // Actions
              _buildActions(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (widget.illustration != null) {
      return widget.illustration!;
    }

    final icon = widget.icon ?? _getDefaultIcon();
    final iconColor = _getIconColor(colorScheme);
    final bgColor = _getIconBackgroundColor(colorScheme);
    final size = widget.compact ? 80.0 : 120.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            bgColor.withValues(alpha: 0.3),
            bgColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: size * 0.4, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, ColorScheme colorScheme) {
    final children = <Widget>[];

    if (widget.actionLabel != null) {
      children.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onAction?.call();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(widget.actionLabel!),
          ),
        ),
      );
    }

    if (widget.secondaryActionLabel != null) {
      children.add(const SizedBox(height: 12));
      children.add(
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onSecondaryAction?.call();
          },
          child: Text(widget.secondaryActionLabel!),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  String? _getTitle() {
    if (widget.title != null) return widget.title;

    switch (widget.type) {
      case EmptyStateType.noChats:
        return 'No conversations yet';
      case EmptyStateType.noMessages:
        return 'No messages yet';
      case EmptyStateType.noSearchResults:
        return 'No results found';
      case EmptyStateType.noMedia:
        return 'No media yet';
      case EmptyStateType.noDocuments:
        return 'No documents';
      case EmptyStateType.noLinks:
        return 'No links';
      case EmptyStateType.noMembers:
        return 'No members';
      case EmptyStateType.noNotifications:
        return 'No notifications';
      case EmptyStateType.noArchived:
        return 'No archived chats';
      case EmptyStateType.noBlocked:
        return 'No blocked users';
      case EmptyStateType.error:
        return 'Something went wrong';
      case EmptyStateType.offline:
        return 'You\'re offline';
      case EmptyStateType.custom:
        return null;
    }
  }

  String? _getDescription() {
    if (widget.description != null) return widget.description;

    switch (widget.type) {
      case EmptyStateType.noChats:
        return 'Start a new chat to connect with friends and groups';
      case EmptyStateType.noMessages:
        return 'Send a message to start the conversation';
      case EmptyStateType.noSearchResults:
        return 'Try a different search term';
      case EmptyStateType.noMedia:
        return 'Photos and videos shared here will appear';
      case EmptyStateType.noDocuments:
        return 'Documents shared here will appear';
      case EmptyStateType.noLinks:
        return 'Links shared here will appear';
      case EmptyStateType.noMembers:
        return 'Invite members to join this chat';
      case EmptyStateType.noNotifications:
        return 'You have no notifications';
      case EmptyStateType.noArchived:
        return 'No archived chats';
      case EmptyStateType.noBlocked:
        return 'You haven\'t blocked anyone';
      case EmptyStateType.error:
        return 'Please try again';
      case EmptyStateType.offline:
        return 'Check your internet connection';
      case EmptyStateType.custom:
        return null;
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case EmptyStateType.noChats:
        return Icons.chat_bubble_outline_rounded;
      case EmptyStateType.noMessages:
        return Icons.message_outlined;
      case EmptyStateType.noSearchResults:
        return Icons.search_off_rounded;
      case EmptyStateType.noMedia:
        return Icons.photo_library_outlined;
      case EmptyStateType.noDocuments:
        return Icons.description_outlined;
      case EmptyStateType.noLinks:
        return Icons.link_off_rounded;
      case EmptyStateType.noMembers:
        return Icons.group_outlined;
      case EmptyStateType.noNotifications:
        return Icons.notifications_off_outlined;
      case EmptyStateType.noArchived:
        return Icons.archive_outlined;
      case EmptyStateType.noBlocked:
        return Icons.block_outlined;
      case EmptyStateType.error:
        return Icons.error_outline_rounded;
      case EmptyStateType.offline:
        return Icons.wifi_off_rounded;
      case EmptyStateType.custom:
        return Icons.inbox_outlined;
    }
  }

  Color _getIconBackgroundColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case EmptyStateType.error:
        return colorScheme.error;
      case EmptyStateType.offline:
        return colorScheme.tertiary;
      case EmptyStateType.noSearchResults:
        return colorScheme.secondary;
      default:
        return colorScheme.primary;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (widget.type) {
      case EmptyStateType.error:
        return colorScheme.error;
      case EmptyStateType.offline:
        return colorScheme.tertiary;
      default:
        return colorScheme.primary.withValues(alpha: 0.8);
    }
  }
}

// ================================================================
// MINI EMPTY STATE - For inline use
// ================================================================

class MiniEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const MiniEmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.buttonLabel,
    this.onButtonPressed,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onButtonPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

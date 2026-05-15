import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/social/follow/models/follows_model.dart';
import 'package:the_time_chart/features/social/follow/providers/follow_provider.dart';
import 'package:the_time_chart/widgets/error_handler.dart';

enum FollowButtonSize { small, medium, large }

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final FollowButtonSize size;
  final bool showIcon;
  final bool showUsername;
  final String? username;
  final VoidCallback? onFollowed;
  final VoidCallback? onUnfollowed;
  final VoidCallback? onRequested;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.size = FollowButtonSize.medium,
    this.showIcon = true,
    this.showUsername = false,
    this.username,
    this.onFollowed,
    this.onUnfollowed,
    this.onRequested,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  FollowButtonState? _state;
  bool _isLoading = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeState() async {
    final provider = context.read<FollowProvider>();
    final state = await provider.initializeButtonState(widget.targetUserId);
    if (mounted) {
      setState(() {
        _state = state;
      });
    }
  }

  Future<void> _handleTap() async {
    if (_isLoading || _state == null) return;

    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) => _animationController.reverse());
    setState(() => _isLoading = true);

    try {
      final provider = context.read<FollowProvider>();
      final result = await provider.toggleFollow(widget.targetUserId);

      if (result != null && mounted) {
        setState(() {
          _state = _state!.applyToggleResult(result);
          _isLoading = false;
        });

        if (result.isFollowed) {
          widget.onFollowed?.call();
        } else if (result.isUnfollowed) {
          widget.onUnfollowed?.call();
        } else if (result.isRequested) {
          widget.onRequested?.call();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackbar('Failed to update follow status');
    }
  }

  Future<void> _showUnfollowConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfollow?'),
        content: Text(
          widget.showUsername && widget.username != null
              ? 'Are you sure you want to stop following @${widget.username}?'
              : 'Are you sure you want to unfollow this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              _handleTap();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return _buildLoadingButton();
    }

    final theme = Theme.of(context);
    final isFollowing = _state!.isFollowing;
    final isPending = _state!.isPending;
    final isBlocked = _state!.isBlocked;
    final isMutual = _state!.isMutual;
    final isHovered = _isHovered;

    Widget buttonChild;

    switch (widget.size) {
      case FollowButtonSize.small:
        buttonChild = _buildSmallButton(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        );
        break;
      case FollowButtonSize.medium:
        buttonChild = _buildMediumButton(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        );
        break;
      case FollowButtonSize.large:
        buttonChild = _buildLargeButton(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        );
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: GestureDetector(
          onTap: isFollowing ? _showUnfollowConfirmation : _handleTap,
          child: buttonChild,
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(theme, isFollowing, isPending, isBlocked),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
            )
          else ...[
            if (widget.showIcon) ...[
              Icon(
                _getIcon(
                  isFollowing,
                  isPending,
                  isBlocked,
                  isMutual,
                  _isHovered,
                ),
                size: 14,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              _getButtonText(
                isFollowing,
                isPending,
                isBlocked,
                isMutual,
                _isHovered,
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediumButton(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(theme, isFollowing, isPending, isBlocked),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
            )
          else ...[
            if (widget.showIcon) ...[
              Icon(
                _getIcon(
                  isFollowing,
                  isPending,
                  isBlocked,
                  isMutual,
                  _isHovered,
                ),
                size: 16,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _getButtonText(
                isFollowing,
                isPending,
                isBlocked,
                isMutual,
                _isHovered,
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLargeButton(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(
          theme,
          isFollowing,
          isPending,
          isBlocked,
          isMutual,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getBorderColor(theme, isFollowing, isPending, isBlocked),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
            )
          else ...[
            if (widget.showIcon) ...[
              Icon(
                _getIcon(
                  isFollowing,
                  isPending,
                  isBlocked,
                  isMutual,
                  _isHovered,
                ),
                size: 18,
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _getButtonText(
                isFollowing,
                isPending,
                isBlocked,
                isMutual,
                _isHovered,
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: _getTextColor(theme, isFollowing, isPending, isBlocked),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const SizedBox(
        width: 60,
        height: 16,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
  ) {
    if (isBlocked) return theme.colorScheme.errorContainer;
    if (isPending) return theme.colorScheme.surfaceContainerHighest;
    if (isFollowing) {
      return _isHovered
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHighest;
    }
    if (isMutual) return theme.colorScheme.primaryContainer;
    return theme.colorScheme.primary;
  }

  Color _getBorderColor(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
  ) {
    if (isBlocked) return theme.colorScheme.error;
    if (isFollowing)
      return _isHovered ? theme.colorScheme.error : Colors.transparent;
    if (isPending) return theme.colorScheme.outline;
    return Colors.transparent;
  }

  Color _getTextColor(
    ThemeData theme,
    bool isFollowing,
    bool isPending,
    bool isBlocked,
  ) {
    if (isBlocked) return theme.colorScheme.onErrorContainer;
    if (isPending) return theme.colorScheme.onSurface;
    if (isFollowing) {
      return _isHovered
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.onSurface;
    }
    return theme.colorScheme.onPrimary;
  }

  IconData _getIcon(
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
    bool isHovered,
  ) {
    if (isBlocked) return Icons.block;
    if (isPending) return Icons.hourglass_empty;
    if (isFollowing) {
      return isHovered ? Icons.person_remove : Icons.how_to_reg;
    }
    if (isMutual) return Icons.people;
    return Icons.person_add;
  }

  String _getButtonText(
    bool isFollowing,
    bool isPending,
    bool isBlocked,
    bool isMutual,
    bool isHovered,
  ) {
    if (isBlocked) return 'Blocked';
    if (isPending) return 'Requested';
    if (isFollowing) {
      return isHovered ? 'Unfollow' : 'Following';
    }
    if (isMutual) return 'Friend';
    return 'Follow';
  }
}

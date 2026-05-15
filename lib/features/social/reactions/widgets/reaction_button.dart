import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/features/social/reactions/providers/reaction_provider.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

import 'reaction_picker.dart';

enum ReactionButtonStyle {
  instagram, // Heart icon only
  facebook, // Like button with reactions on long press
  youtube, // Thumb up/down
  linkedin, // Like + celebrate + support + insightful
}

class ReactionButton extends StatefulWidget {
  final ReactionTargetType targetType;
  final String targetId;
  final ReactionType? initialReaction;
  final int initialCount;
  final double size;
  final ReactionButtonStyle style;
  final bool showCount;
  final bool showLabel;
  final VoidCallback? onTap;
  final Function(ReactionType?)? onReactionChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const ReactionButton({
    super.key,
    required this.targetType,
    required this.targetId,
    this.initialReaction,
    this.initialCount = 0,
    this.size = 24,
    this.style = ReactionButtonStyle.instagram,
    this.showCount = true,
    this.showLabel = false,
    this.onTap,
    this.onReactionChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  ReactionType? _currentReaction;
  int _currentCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentReaction = widget.initialReaction;
    _currentCount = widget.initialCount;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReaction != oldWidget.initialReaction) {
      setState(() {
        _currentReaction = widget.initialReaction;
      });
    }
    if (widget.initialCount != oldWidget.initialCount) {
      setState(() {
        _currentCount = widget.initialCount;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) => _animationController.reverse());

    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ReactionProvider>();

      ToggleReactionResult? result;

      if (widget.style == ReactionButtonStyle.youtube) {
        // YouTube style: toggle between like and no reaction
        if (_currentReaction == ReactionType.like) {
          result = await provider.toggleReaction(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reactionType: ReactionType.like,
          );
        } else {
          result = await provider.toggleReaction(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reactionType: ReactionType.like,
          );
        }
      } else {
        // Default: toggle like
        if (_currentReaction == ReactionType.like) {
          result = await provider.toggleReaction(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reactionType: ReactionType.like,
          );
        } else {
          result = await provider.toggleReaction(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reactionType: ReactionType.like,
          );
        }
      }

      if (result != null && result.success) {
        final toggleResult = result; // Promote to non-nullable
        setState(() {
          _currentReaction = toggleResult.reactionType;
          if (toggleResult.isAdded) {
            _currentCount += 1;
          } else if (toggleResult.isRemoved) {
            _currentCount -= 1;
          }
          _isLoading = false;
        });

        widget.onReactionChanged?.call(_currentReaction);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showReactionPicker(BuildContext context, Offset position) async {
    HapticFeedback.mediumImpact();

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final selectedReaction = await showDialog<ReactionType>(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: false,
      builder: (context) => ReactionPicker(
        anchorOffset: offset,
        anchorSize: renderBox.size,
        currentReaction: _currentReaction,
      ),
    );

    if (selectedReaction != null && mounted) {
      setState(() => _isLoading = true);

      final provider = context.read<ReactionProvider>();
      final result = await provider.toggleReaction(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reactionType: selectedReaction,
      );

      if (result != null && result.success) {
        final toggleResult = result; // Promote to non-nullable
        setState(() {
          _currentReaction = toggleResult.reactionType;
          if (toggleResult.isAdded) {
            _currentCount += 1;
          } else if (toggleResult.isRemoved) {
            _currentCount -= 1;
          } else if (toggleResult.isChanged) {
            // Count stays the same
          }
          _isLoading = false;
        });

        widget.onReactionChanged?.call(_currentReaction);

        // Show snackbar for non-like reactions
        if (selectedReaction != ReactionType.like && toggleResult.isAdded) {
          AppSnackbar.info(
            title: '${selectedReaction.emoji} ${selectedReaction.label}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReacted = _currentReaction != null;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final inactiveColor =
        widget.inactiveColor ?? theme.colorScheme.onSurfaceVariant;

    Widget buttonChild;

    switch (widget.style) {
      case ReactionButtonStyle.instagram:
        buttonChild = Icon(
          isReacted ? Icons.favorite : Icons.favorite_border,
          color: isReacted ? Colors.red : inactiveColor,
          size: widget.size,
        );
        break;

      case ReactionButtonStyle.youtube:
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentReaction == ReactionType.like
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              color: _currentReaction == ReactionType.like
                  ? activeColor
                  : inactiveColor,
              size: widget.size,
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 4),
              Text(
                _currentReaction == ReactionType.like ? 'Liked' : 'Like',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _currentReaction == ReactionType.like
                      ? activeColor
                      : inactiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
        break;

      case ReactionButtonStyle.facebook:
      case ReactionButtonStyle.linkedin:
        buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentReaction != null)
              Text(
                _currentReaction!.emoji,
                style: TextStyle(fontSize: widget.size),
              )
            else
              Icon(
                Icons.thumb_up_outlined,
                color: inactiveColor,
                size: widget.size,
              ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _currentReaction?.label ?? 'Like',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isReacted ? activeColor : inactiveColor,
                  fontWeight: isReacted ? FontWeight.w600 : null,
                ),
              ),
            ],
          ],
        );
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.style != ReactionButtonStyle.youtube
            ? () {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  _showReactionPicker(context, box.localToGlobal(Offset.zero));
                }
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isReacted && widget.style == ReactionButtonStyle.facebook
                ? activeColor.withOpacity(0.1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: activeColor,
                  ),
                )
              else
                buttonChild,
              if (widget.showCount && _currentCount > 0) ...[
                const SizedBox(width: 6),
                Text(
                  _formatCount(_currentCount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isReacted ? activeColor : inactiveColor,
                    fontWeight: isReacted ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) {
      final formatted = (count / 1000).toStringAsFixed(1);
      return formatted.endsWith('.0')
          ? '${(count / 1000).floor()}K'
          : '${formatted}K';
    }
    if (count < 1000000) return '${(count / 1000).floor()}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

// Extension for reaction type emoji
extension ReactionTypeEmoji on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.celebrate:
        return '🎉';
      case ReactionType.support:
        return '🙌';
      case ReactionType.insightful:
        return '💡';
      case ReactionType.curious:
        return '🤔';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }
}

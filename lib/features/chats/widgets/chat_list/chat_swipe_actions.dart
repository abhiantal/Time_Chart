// ================================================================
// FILE: lib/features/chat/widgets/common/chat_swipe_actions.dart
// CHAT SWIPE ACTIONS - Fixed
// ✅ Background ONLY visible when user is actively dragging
// ✅ No ghost icon at rest position
// ✅ Smooth reveal as drag progresses
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SwipeActionType { archive, delete, pin, mute, read }

class ChatSwipeActions extends StatefulWidget {
  final Widget child;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onRead;
  final bool isPinned;
  final bool isMuted;
  final VoidCallback? onLeftSwipe;
  final VoidCallback? onRightSwipe;
  final SwipeActionType? leftActionType;
  final SwipeActionType? rightActionType;
  final bool enableLeftSwipe;
  final bool enableRightSwipe;

  const ChatSwipeActions({
    super.key,
    required this.child,
    this.onArchive,
    this.onDelete,
    this.onPin,
    this.onMute,
    this.onRead,
    this.isPinned = false,
    this.isMuted = false,
    this.onLeftSwipe,
    this.onRightSwipe,
    this.leftActionType,
    this.rightActionType,
    this.enableLeftSwipe = true,
    this.enableRightSwipe = true,
  });

  @override
  State<ChatSwipeActions> createState() => _ChatSwipeActionsState();
}

class _ChatSwipeActionsState extends State<ChatSwipeActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  double _dragExtent = 0;
  double _animatedDrag = 0;
  bool _hasTriggeredHaptic = false;
  bool _isDragging = false;

  static const double _threshold = 72.0;
  static const double _maxReveal = 90.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails _) {
    _isDragging = true;
    _snapController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final delta = details.primaryDelta ?? 0;

    if (delta > 0 && !widget.enableRightSwipe) return;
    if (delta < 0 && !widget.enableLeftSwipe) return;

    setState(() {
      _dragExtent += delta;
      // ✅ Rubber-band resistance past threshold
      if (_dragExtent.abs() > _threshold) {
        final over = _dragExtent.abs() - _threshold;
        final sign = _dragExtent.sign;
        _dragExtent = sign * (_threshold + over * 0.3);
      }
      _dragExtent = _dragExtent.clamp(-_maxReveal, _maxReveal);
      _animatedDrag = _dragExtent;
    });

    if (_dragExtent.abs() >= _threshold && !_hasTriggeredHaptic) {
      HapticFeedback.mediumImpact();
      _hasTriggeredHaptic = true;
    } else if (_dragExtent.abs() < _threshold * 0.5) {
      _hasTriggeredHaptic = false;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;

    if ((_dragExtent >= _threshold || velocity > 600) &&
        widget.enableRightSwipe) {
      // Right swipe → archive
      _snapBack(() {
        widget.onArchive?.call();
        widget.onRightSwipe?.call();
      });
    } else if ((_dragExtent <= -_threshold || velocity < -600) &&
        widget.enableLeftSwipe) {
      // Left swipe → delete
      _snapBack(() {
        widget.onDelete?.call();
        widget.onLeftSwipe?.call();
      });
    } else {
      // Not past threshold — snap back without action
      _snapBack(null);
    }
  }

  void _snapBack(VoidCallback? onComplete) {
    final startDrag = _dragExtent;
    _snapAnimation =
        Tween<double>(begin: startDrag, end: 0).animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (mounted) setState(() => _animatedDrag = _snapAnimation.value);
        });

    _snapController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
          _animatedDrag = 0;
          _hasTriggeredHaptic = false;
        });
        onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Progress: 0.0 = no drag, 1.0 = at threshold
    final rightProgress = (_animatedDrag > 0
        ? (_animatedDrag / _threshold).clamp(0.0, 1.0)
        : 0.0);
    final leftProgress = (_animatedDrag < 0
        ? (_animatedDrag.abs() / _threshold).clamp(0.0, 1.0)
        : 0.0);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        clipBehavior: Clip.hardEdge, // ✅ Clips anything outside bounds
        children: [
          // ── Right-swipe background (Archive) — left side ──
          // ✅ Only renders when rightProgress > 0 (user is dragging right)
          if (widget.enableRightSwipe && rightProgress > 0)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ActionBackground(
                  type: widget.rightActionType ?? SwipeActionType.archive,
                  width: _animatedDrag.clamp(0.0, _maxReveal),
                  progress: rightProgress,
                ),
              ),
            ),

          // ── Left-swipe background (Delete) — right side ──
          // ✅ Only renders when leftProgress > 0 (user is dragging left)
          if (widget.enableLeftSwipe && leftProgress > 0)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: _ActionBackground(
                  type: widget.leftActionType ?? SwipeActionType.delete,
                  width: _animatedDrag.abs().clamp(0.0, _maxReveal),
                  progress: leftProgress,
                ),
              ),
            ),

          // ── Sliding tile content ──
          Transform.translate(
            offset: Offset(_animatedDrag, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ── Action background strip ───────────────────────────
class _ActionBackground extends StatelessWidget {
  const _ActionBackground({
    required this.type,
    required this.width,
    required this.progress,
  });

  final SwipeActionType type;
  final double width;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final config = _config();

    // ✅ Icon only appears after 30% drag — no ghost at rest
    final iconOpacity = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
    final iconScale = 0.6 + (0.4 * progress);

    return Container(
      width: width,
      color: Color.lerp(config.color.withValues(alpha: 0.6), config.color, progress),
      child: iconOpacity > 0
          ? Center(
              child: Opacity(
                opacity: iconOpacity,
                child: Transform.scale(
                  scale: iconScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, color: Colors.white, size: 26),
                      if (progress > 0.75) ...[
                        const SizedBox(height: 4),
                        Text(
                          config.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  _SwipeConfig _config() {
    switch (type) {
      case SwipeActionType.archive:
        return const _SwipeConfig(
          icon: Icons.archive_rounded,
          label: 'Archive',
          color: Color(0xFF3B82F6),
        );
      case SwipeActionType.delete:
        return const _SwipeConfig(
          icon: Icons.delete_rounded,
          label: 'Delete',
          color: Color(0xFFEF4444),
        );
      case SwipeActionType.pin:
        return const _SwipeConfig(
          icon: Icons.push_pin_rounded,
          label: 'Pin',
          color: Color(0xFFF59E0B),
        );
      case SwipeActionType.mute:
        return const _SwipeConfig(
          icon: Icons.volume_off_rounded,
          label: 'Mute',
          color: Color(0xFF6B7280),
        );
      case SwipeActionType.read:
        return const _SwipeConfig(
          icon: Icons.done_all_rounded,
          label: 'Read',
          color: Color(0xFF10B981),
        );
    }
  }
}

class _SwipeConfig {
  final IconData icon;
  final String label;
  final Color color;
  const _SwipeConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}

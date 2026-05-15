// ================================================================
// FILE: lib/features/chat/widgets/members/add_member_button.dart
// PURPOSE: FAB-style button for adding members to group
// STYLE: WhatsApp-style floating action button
// DEPENDENCIES: None
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddMemberButton extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AddMemberButton({
    super.key,
    required this.onPressed,
    this.size = 56,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AddMemberButton> createState() => _AddMemberButtonState();
}

class _AddMemberButtonState extends State<AddMemberButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.backgroundColor ?? colorScheme.primary,
                      widget.backgroundColor?.withValues(alpha: 0.8) ??
                          colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backgroundColor ?? colorScheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: widget.foregroundColor ?? colorScheme.onPrimary,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Add member button with extended label
class AddMemberButtonExtended extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AddMemberButtonExtended({
    super.key,
    required this.onPressed,
    this.label = 'Add Members',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.person_add_rounded),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Add member button with counter
class AddMemberButtonWithCounter extends StatelessWidget {
  final VoidCallback onPressed;
  final int memberCount;
  final int maxMembers;

  const AddMemberButtonWithCounter({
    super.key,
    required this.onPressed,
    required this.memberCount,
    required this.maxMembers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = memberCount / maxMembers;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$memberCount/$maxMembers',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: colorScheme.primary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.small(
            heroTag: 'chat_add_member_fab',
            onPressed: onPressed,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

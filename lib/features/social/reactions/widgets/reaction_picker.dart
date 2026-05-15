import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/social/reactions/models/reactions_model.dart';

class ReactionPicker extends StatefulWidget {
  final Offset anchorOffset;
  final Size anchorSize;
  final ReactionType? currentReaction;
  final Function(ReactionType)? onReactionSelected;

  const ReactionPicker({
    super.key,
    required this.anchorOffset,
    required this.anchorSize,
    this.currentReaction,
    this.onReactionSelected,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  ReactionType? _hoveredReaction;

  final List<ReactionType> _reactions = [
    ReactionType.like,
    ReactionType.love,
    ReactionType.celebrate,
    ReactionType.support,
    ReactionType.insightful,
    ReactionType.curious,
    ReactionType.haha,
    ReactionType.wow,
    ReactionType.sad,
    ReactionType.angry,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

    // Calculate position
    final screenSize = MediaQuery.of(context).size;
    double left = widget.anchorOffset.dx - 180;
    if (left < 16) left = 16;
    if (left + 360 > screenSize.width) left = screenSize.width - 376;

    double top = widget.anchorOffset.dy - 80;
    if (top < 16) top = widget.anchorOffset.dy + widget.anchorSize.height + 16;

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Picker
        Positioned(
          left: left,
          top: top,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                color: theme.cardColor,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _reactions.map((reaction) {
                      final isSelected = reaction == widget.currentReaction;
                      final isHovered = reaction == _hoveredReaction;

                      return _ReactionItem(
                        reaction: reaction,
                        isSelected: isSelected,
                        isHovered: isHovered,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context, reaction);
                          widget.onReactionSelected?.call(reaction);
                        },
                        onHover: (hovered) {
                          setState(() {
                            _hoveredReaction = hovered ? reaction : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionItem extends StatefulWidget {
  final ReactionType reaction;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _ReactionItem({
    required this.reaction,
    required this.isSelected,
    required this.isHovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ReactionItem> createState() => _ReactionItemState();
}

class _ReactionItemState extends State<_ReactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant _ReactionItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _hoverController.forward();
    } else if (!widget.isHovered && oldWidget.isHovered) {
      _hoverController.reverse();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.reaction.emoji,
                        style: TextStyle(
                          fontSize: 28 + (widget.isHovered ? 4 : 0),
                        ),
                      ),
                      if (widget.isHovered) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.reaction.label,
                          style: Theme.of(context).textScheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

extension _ThemeTextScheme on ThemeData {
  TextTheme get textScheme => textTheme;
}

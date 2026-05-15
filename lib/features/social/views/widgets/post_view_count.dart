import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/social/views/models/post_views_model.dart';
import 'package:the_time_chart/features/social/views/providers/post_view_provider.dart';
import 'package:the_time_chart/widgets/logger.dart';

class PostViewCount extends StatefulWidget {
  final String postId;
  final int initialCount;
  final bool showLabel;
  final double size;
  final VoidCallback? onTap;
  final bool isAuthor;

  const PostViewCount({
    super.key,
    required this.postId,
    required this.initialCount,
    this.showLabel = true,
    this.size = 20,
    this.onTap,
    this.isAuthor = false,
  });

  @override
  State<PostViewCount> createState() => _PostViewCountState();
}

class _PostViewCountState extends State<PostViewCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _currentCount = 0;
  bool _isAnimating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentCount = widget.initialCount;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    _recordView();
  }

  @override
  void didUpdateWidget(PostViewCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCount != oldWidget.initialCount) {
      setState(() {
        _currentCount = widget.initialCount;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _recordView() async {
    if (widget.isAuthor) return; // Don't record author's own views

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      try {
        final provider = context.read<PostViewProvider>();
        final result = await provider.recordView(
          postId: widget.postId,
          source: ViewSource.feed,
        );

        if (result.isNewView && mounted) {
          setState(() {
            _currentCount += 1;
          });
          _animationController.forward();
        }
      } catch (e) {
        logW('Failed to record view: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap ?? (widget.isAuthor ? _showAnalytics : null),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(widget.size * 0.15),
                  decoration: BoxDecoration(
                    color: _currentCount > 0
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _currentCount > 0
                        ? Icons.visibility
                        : Icons.visibility_outlined,
                    size: widget.size,
                    color: _currentCount > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(_currentCount),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _currentCount > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: _currentCount > 0 ? FontWeight.w600 : null,
              ),
            ),
            if (widget.isAuthor && _currentCount > 0) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showAnalytics() async {
    HapticFeedback.selectionClick();

    // Navigate to analytics screen
    // This will be handled by the parent widget
    if (widget.onTap != null) {
      widget.onTap!();
    }
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

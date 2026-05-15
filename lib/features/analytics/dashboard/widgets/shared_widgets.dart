// ================================================================
// FILE: lib/features/personal/dashboard/widgets/shared_widgets.dart
// CORE REUSABLE COMPONENTS - Used across all screens
// ================================================================

import 'package:flutter/material.dart';
import '../../../../widgets/bar_progress_indicator.dart';
import '../../../../widgets/metric_indicators.dart';

// ================================================================
// 1. GRADIENT CARD CONTAINERS
// ================================================================

/// Reusable gradient card with customizable styling
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final bool showShadow;
  final bool showClickEffect;

  const GradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.onTap,
    this.boxShadow,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.showShadow = true,
    this.showClickEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: gradientBegin,
          end: gradientEnd,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: (showShadow)
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: showClickEffect ? null : Colors.transparent,
          highlightColor: showClickEffect ? null : Colors.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Animated gradient card with entrance animation
class AnimatedGradientCard extends StatefulWidget {
  final List<Color> colors;
  final Widget child;
  final Duration animationDuration;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const AnimatedGradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 500),
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  });

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GradientCard(
          colors: widget.colors,
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          child: widget.child,
        ),
      ),
    );
  }
}

// ================================================================
// 2. STAT METRIC CARDS
// ================================================================

/// Displays a metric with title, value, icon, and optional progress
class StatMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? progress;
  final bool showProgressBar;
  final TextStyle? valueStyle;

  final bool showBackground;
  final bool showShadow;

  const StatMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.progress,
    this.showProgressBar = false,
    this.valueStyle,
    this.showBackground = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style:
                        valueStyle ??
                        theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
        if (showProgressBar && progress != null) ...[
          const SizedBox(height: 8),
          CustomProgressIndicator(
            progress: (progress! / 100).clamp(0, 1),
            progressBarName: '',
            baseHeight: 4,
            maxHeightIncrease: 0,
            backgroundColor: color.withValues(alpha: 0.2),
            progressColor: color,
            gradientColors: [color, color.withValues(alpha: 0.6)],
            borderRadius: 2,
            progressLabelDisplay: ProgressLabelDisplay.none,
            animated: true,
          ),
        ],
      ],
    );

    if (!showBackground) {
      if (onTap != null) {
        return InkWell(onTap: onTap, child: content);
      }
      return content;
    }

    return GradientCard(
      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(0),
      showShadow: showShadow,
      child: content,
    );
  }
}

// ================================================================
// 4. BADGES & INDICATORS
// ================================================================

/// Status badge for task status display
class StatusBadge extends StatelessWidget {
  final String status;
  final IconData? icon;
  final Color? color;
  final EdgeInsets padding;
  final double borderRadius;

  const StatusBadge({
    super.key,
    required this.status,
    this.icon,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine color based on status
    final cleanStatus = status.toLowerCase().trim();
    Color statusColor;
    if (color != null) {
      statusColor = color!;
    } else {
      switch (cleanStatus) {
        case 'completed':
        case 'complete':
          statusColor = const Color(0xFF10B981); // Emerald Green
          break;
        case 'inprogress':
        case 'in progress':
          statusColor = const Color(0xFF3B82F6); // Blue
          break;
        case 'pending':
          statusColor = const Color(0xFF6B7280); // Grey
          break;
        case 'missed':
        case 'failed':
          statusColor = const Color(0xFFEF4444); // Red
          break;
        case 'cancelled':
        case 'canceled':
          statusColor = const Color(0xFF9CA3AF); // Muted Grey
          break;
        case 'skipped':
          statusColor = const Color(0xFFD97706); // Amber/Brown
          break;
        case 'postponed':
          statusColor = const Color(0xFFF59E0B); // Orange
          break;
        default:
          statusColor = theme.colorScheme.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Priority badge
class PriorityBadge extends StatelessWidget {
  final String priority;
  final EdgeInsets padding;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.priority,
      value: priority,
      size: 24,
      showLabel: true,
    );
  }
}

/// Points badge with simplified wrapper
class PointsBadge extends StatelessWidget {
  final int points;
  final bool animate;
  final Duration animationDuration;
  final Color? color;

  const PointsBadge({
    super.key,
    required this.points,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.pointsEarned,
      value: points,
      size: 24,
      showLabel: true,
      customColor: color,
      animate: animate,
    );
  }
}

/// Reward/Achievement badge
class RewardBadge extends StatelessWidget {
  final String tier;
  final String? emoji;
  final String? tagName;
  final EdgeInsets padding;

  const RewardBadge({
    super.key,
    required this.tier,
    this.emoji,
    this.tagName,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.reward,
      value: tier,
      size: 24,
      showLabel: true,
      customLabel: tagName ?? tier,
    );
  }
}

/// Trend indicator
class TrendIndicator extends StatelessWidget {
  final String trend; // "improving", "declining", "stable"
  final double value;
  final IconData? customIcon;

  const TrendIndicator({
    super.key,
    required this.trend,
    this.value = 0,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.efficiency,
      value: value / 100, // Assuming value is percentage
      size: 24,
      showLabel: true,
      customLabel: trend,
    );
  }
}

// ================================================================
// 5. DIVIDERS & SEPARATORS
// ================================================================

/// Styled divider with optional label
class StyledDivider extends StatelessWidget {
  final String? label;
  final double height;
  final Color? color;
  final EdgeInsets padding;

  const StyledDivider({
    super.key,
    this.label,
    this.height = 1,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor =
        color ?? theme.colorScheme.outline.withValues(alpha: 0.2);

    if (label == null) {
      return Padding(
        padding: padding,
        child: Divider(height: height, color: dividerColor, thickness: height),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Divider(height: height, color: dividerColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(height: height, color: dividerColor),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 6. EMPTY STATE & ERROR WIDGETS
// ================================================================

/// Reusable empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state widget
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// 7. SECTION CONTAINERS
// ================================================================

/// Section header with title and optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          if (onAction != null && actionLabel != null)
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.arrow_forward_rounded),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Expandable section container
class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.onExpand,
    this.onCollapse,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          title: Text(
            widget.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
            if (_isExpanded) {
              widget.onExpand?.call();
            } else {
              widget.onCollapse?.call();
            }
          },
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: widget.child,
          ),
        ],
      ],
    );
  }
}

// ================================================================
// Legacy components removed. Use CustomTextField and TaskMetricIndicator from their respective files.

// ================================================================

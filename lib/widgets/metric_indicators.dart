// message_bubbles/task_metric_indicators.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Represents the different states a task can be in.
enum TaskStatus {
  pending, // Not started yet (future task)
  inProgress, // Time has started
  completed, // User completed the task
  missed, // End time passed and not completed
  cancelled, // User canceled the task
  postponed, // User rescheduled the task
  skipped, // User intentionally skipped
  upcoming, // Will start soon (e.g., in next hour)
  failed, // Similar to missed but used for strict goals
  hold, // Task is on hold
  unknown, // Default or error state
}

/// Represents different measurable or descriptive attributes of a task
enum TaskMetricType {
  status,
  priority,
  rating,
  efficiency,
  progress,
  posted,
  shared,
  mediaCount,
  feedbackCount,
  startingTime,
  endingTime,
  completionTime,
  timeOnComplete,
  timeLeft,
  overdue,
  category,
  deadline,
  reminder,
  tag,
  milestone,
  pointsEarned,
  penalty,
  reward,
  liveSnapshot,
}

/// Main Task Metric Indicator System
class TaskMetricIndicator extends StatefulWidget {
  final TaskMetricType type;
  final dynamic value;
  final Map<String, dynamic>? additionalData;
  final double size;
  final bool showLabel;
  final String? customLabel;
  final VoidCallback? onTap;
  final bool animate;
  final bool adaptToTheme;
  final Color? customColor;
  final String? recordId;

  const TaskMetricIndicator({
    super.key,
    required this.type,
    this.value,
    this.additionalData,
    this.size = 32,
    this.showLabel = false,
    this.customLabel,
    this.onTap,
    this.animate = true,
    this.adaptToTheme = true,
    this.customColor,
    this.recordId,
  });

  @override
  State<TaskMetricIndicator> createState() => _TaskMetricIndicatorState();
}

class _TaskMetricIndicatorState extends State<TaskMetricIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _labelController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _labelAnimation;
  bool _showingLabel = false;

  @override
  void initState() {
    super.initState();
    _showingLabel = widget.showLabel;

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Label animation controller
    _labelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _labelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }

    if (_showingLabel) {
      _labelController.forward();
    }
  }

  @override
  void didUpdateWidget(TaskMetricIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLabel != oldWidget.showLabel) {
      _toggleLabel();
    }
  }

  void _toggleLabel() {
    setState(() {
      _showingLabel = !_showingLabel;
      if (_showingLabel) {
        _labelController.forward();
      } else {
        _labelController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  // =========== FIX: IMPROVED HELPER FUNCTION TO PREVENT CRASH ===========
  /// Safely parses the dynamic value into a TaskStatus enum.
  /// This handles both String and TaskStatus inputs.
  TaskStatus _parseTaskStatus(dynamic value) {
    if (value is TaskStatus) {
      return value;
    }
    if (value is String) {
      // Normalize the string by removing spaces and underscores, converting to lowercase
      final normalized = value.toLowerCase().replaceAll(
        RegExp(r'[\s_\-]+'),
        '',
      );

      switch (normalized) {
        case 'pending':
          return TaskStatus.pending;
        case 'inprogress':
        case 'in progress':
        case 'progress':
          return TaskStatus.inProgress;
        case 'completed':
        case 'complete':
          return TaskStatus.completed;
        case 'missed':
          return TaskStatus.missed;
        case 'cancelled':
        case 'canceled':
          return TaskStatus.cancelled;
        case 'postponed':
          return TaskStatus.postponed;
        case 'onhold':
        case 'onholdstatus':
        case 'onholded':
        case 'onholdtask':
        case 'onholdgoal':
        case 'on hold':
          return TaskStatus.postponed;
        case 'skipped':
          return TaskStatus.skipped;
        case 'upcoming':
          return TaskStatus.upcoming;
        case 'failed':
          return TaskStatus.failed;
        case 'overdue':
          return TaskStatus.missed; // Map overdue to missed for consistency
        default:
          return TaskStatus.unknown;
      }
    }
    return TaskStatus.unknown;
  }
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget indicator = _buildIndicator(context);

    if (widget.animate) {
      indicator = ScaleTransition(scale: _scaleAnimation, child: indicator);
    }

    return GestureDetector(
      onTap: widget.onTap ?? () => _toggleLabel(),
      onLongPress: () {
        HapticFeedback.lightImpact();
        _toggleLabel();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          if (_showingLabel) ...[
            SizeTransition(
              sizeFactor: _labelAnimation,
              child: FadeTransition(
                opacity: _labelAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _getLabel(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    switch (widget.type) {
      case TaskMetricType.status:
        return _StatusMetric(
          // FIX: Use the safe parsing function
          status: _parseTaskStatus(widget.value),
          size: widget.size,
          customColor: widget.customColor,
          adaptToTheme: widget.adaptToTheme,
        );

      // ... (rest of the cases are unchanged)
      case TaskMetricType.priority:
        return _PriorityMetric(
          priority: widget.value?.toString(),
          size: widget.size,
          customColor: widget.customColor,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.rating:
        return _RatingMetric(
          rating: widget.value is num ? widget.value.toDouble() : 0.0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.efficiency:
        return _EfficiencyMetric(
          efficiency: widget.value is num ? widget.value.toDouble() : 0.0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.progress:
        return _ProgressMetric(
          progress: widget.value is num ? widget.value.toInt() : 0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.posted:
        return _PostedMetric(
          data: widget.value is Map<String, dynamic>
              ? widget.value
              : {'live': widget.value == true}, // Support both Map and bool
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.shared:
        return _SharedMetric(
          data: widget.value is Map<String, dynamic> ? widget.value : null,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.mediaCount:
        return _MediaCountMetric(
          count: widget.value is int ? widget.value : 0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.feedbackCount:
        return _FeedbackCountMetric(
          count: widget.value is int ? widget.value : 0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.startingTime:
      case TaskMetricType.endingTime:
      case TaskMetricType.completionTime:
        return _TimeMetric(
          time: widget.value is DateTime ? widget.value : null,
          type: widget.type,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.timeOnComplete:
        return _TimeOnCompleteMetric(
          duration: widget.value is Duration ? widget.value : null,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.timeLeft:
        return _TimeLeftMetric(
          timeLeft: widget.value?.toString() ?? '',
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.overdue:
        return _OverdueMetric(
          isOverdue: widget.value == true,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.category:
        return _CategoryMetric(
          category: widget.value?.toString() ?? '',
          size: widget.size,
          customColor: widget.customColor,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.deadline:
        return _DeadlineMetric(
          deadline: widget.value is DateTime ? widget.value : null,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.reminder:
        return _ReminderMetric(
          hasReminder: widget.value == true,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.tag:
        return _TagMetric(
          tags: widget.value is List ? widget.value.cast<String>() : [],
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.milestone:
        return _MilestoneMetric(
          isMilestone: widget.value == true,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.pointsEarned:
        return _PointsMetric(
          points: widget.value is num ? widget.value.toInt() : 0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.penalty:
        return _PenaltyMetric(
          penalty: widget.value is num ? widget.value.toDouble() : 0.0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.reward:
        return _RewardMetric(
          reward: widget.value is num ? widget.value.toDouble() : 0.0,
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );

      case TaskMetricType.liveSnapshot:
        return _LiveSnapshotMetric(
          isLive: widget.value == true || (widget.value is Map && widget.value['live'] == true),
          size: widget.size,
          adaptToTheme: widget.adaptToTheme,
        );
    }
  }

  String _getLabel() {
    if (widget.customLabel != null) return widget.customLabel!;

    switch (widget.type) {
      case TaskMetricType.status:
        // FIX: Use the safe parsing function and improve label readability
        final status = _parseTaskStatus(widget.value);
        String name = status.name;
        // Add a space before capital letters for readability (e.g., inProgress -> in Progress)
        name = name.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        );
        // Capitalize the first letter
        name = name[0].toUpperCase() + name.substring(1);
        return name;

      // ... (rest of the cases are unchanged)
      case TaskMetricType.priority:
        return '${widget.value ?? 'Priority'} Priority';
      case TaskMetricType.rating:
        return 'Rating: ${widget.value ?? 0}';
      case TaskMetricType.efficiency:
        return '${((widget.value as num? ?? 0) * 100).toInt()}% Efficiency';
      case TaskMetricType.progress:
        return '${widget.value ?? 0}% Complete';

      case TaskMetricType.posted:
        if (widget.value is Map) {
          final isLive = widget.value['live'] == true;
          return isLive ? 'Live Posted' : 'Posted';
        }
        return widget.value == true ? 'Live Posted' : 'Not Posted';

      case TaskMetricType.shared:
        if (widget.value is Map) {
          final isLive = widget.value['live'] == true;
          final count = widget.value['count'] ?? 0;
          if (count > 0) {
            return isLive ? 'Live Shared ($count)' : 'Shared ($count)';
          }
          return isLive ? 'Live Shared' : 'Shared';
        }
        return 'Not Shared';

        // ignore: dead_code
        return 'Shared ${widget.value ?? 0} times';
      case TaskMetricType.mediaCount:
        return '${widget.value ?? 0} Media';
      case TaskMetricType.feedbackCount:
        return '${widget.value ?? 0} Feedback';
      case TaskMetricType.startingTime:
        return 'Started';
      case TaskMetricType.endingTime:
        return 'Ended';
      case TaskMetricType.completionTime:
        return 'Completed';
      case TaskMetricType.timeOnComplete:
        return 'Time Spent';
      case TaskMetricType.timeLeft:
        return widget.value?.toString() ?? 'Time Left';
      case TaskMetricType.overdue:
        return widget.value == true ? 'Overdue' : 'On Time';
      case TaskMetricType.category:
        return widget.value?.toString() ?? 'Category';
      case TaskMetricType.deadline:
        return 'Deadline';
      case TaskMetricType.reminder:
        return widget.value == true ? 'Reminder Set' : 'No Reminder';
      case TaskMetricType.tag:
        final tags = widget.value as List?;
        return '${tags?.length ?? 0} Tags';
      case TaskMetricType.milestone:
        return widget.value == true ? 'Milestone' : 'Regular';
      case TaskMetricType.pointsEarned:
        return '${widget.value ?? 0} Points';
      case TaskMetricType.penalty:
        return 'Penalty: ${widget.value ?? 0}';
      case TaskMetricType.reward:
        return 'Reward: ${widget.value ?? 0}';
      case TaskMetricType.liveSnapshot:
        final isLive = widget.value == true || (widget.value is Map && widget.value['live'] == true);
        return isLive ? 'Live Update' : 'Snapshot';
    }
  }
}

// ================================================================
// INDIVIDUAL METRIC IMPLEMENTATIONS (No changes needed below)
// The _StatusMetric widget already supports all the different statuses.
// ================================================================

class _StatusMetric extends StatelessWidget {
  final TaskStatus status;
  final double size;
  final Color? customColor;
  final bool adaptToTheme;

  const _StatusMetric({
    required this.status,
    required this.size,
    this.customColor,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getStatusConfig(theme);
    final color = customColor ?? config.$1;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(config.$2, color: Colors.white, size: size * 0.6),
    );
  }

  /// Provides a unique color and icon for each TaskStatus
  (Color, IconData) _getStatusConfig(ThemeData theme) {
    switch (status) {
      case TaskStatus.completed:
        return (theme.colorScheme.primary, Icons.check_circle);
      case TaskStatus.inProgress:
        return (theme.colorScheme.secondary, Icons.play_circle_filled);
      case TaskStatus.pending:
        return (Colors.grey.shade600, Icons.pending);
      case TaskStatus.postponed:
        return (Colors.orange, Icons.schedule_send);
      case TaskStatus.upcoming:
        return (Colors.lightBlue, Icons.hourglass_top);
      case TaskStatus.missed:
        return (theme.colorScheme.error, Icons.event_busy);
      case TaskStatus.failed:
        return (Colors.red.shade900, Icons.error);
      case TaskStatus.cancelled:
        return (Colors.blueGrey, Icons.cancel);
      case TaskStatus.skipped:
        return (Colors.brown.shade400, Icons.skip_next_rounded);
      case TaskStatus.unknown:
      default:
        return (Colors.grey, Icons.help_outline);
    }
  }
}

// ================================================================
// INDIVIDUAL METRIC IMPLEMENTATIONS
// ================================================================

class _PriorityMetric extends StatelessWidget {
  final String? priority;
  final double size;
  final Color? customColor;
  final bool adaptToTheme;

  const _PriorityMetric({
    this.priority,
    required this.size,
    this.customColor,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getPriorityConfig(theme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            customColor ?? config.$1,
            (customColor ?? config.$1).withOpacity(0.6),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (customColor ?? config.$1).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(config.$2, color: Colors.white, size: size * 0.65),
    );
  }

  (Color, IconData) _getPriorityConfig(ThemeData theme) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return (theme.colorScheme.error, Icons.priority_high);
      case 'high':
        return (Colors.deepOrange, Icons.keyboard_double_arrow_up);
      case 'medium':
        return (Colors.orange, Icons.remove);
      case 'low':
        return (Colors.green, Icons.keyboard_arrow_down);
      default:
        return (Colors.grey, Icons.remove);
    }
  }
}

class _RatingMetric extends StatelessWidget {
  final double rating;
  final double size;
  final bool adaptToTheme;

  const _RatingMetric({
    required this.rating,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          Widget star;
          if (index < fullStars) {
            star = Icon(
              Icons.star,
              color: adaptToTheme ? theme.colorScheme.tertiary : Colors.amber,
              size: size * 0.9,
            );
          } else if (index == fullStars && hasHalfStar) {
            star = Icon(
              Icons.star_half,
              color: adaptToTheme ? theme.colorScheme.tertiary : Colors.amber,
              size: size * 0.9,
            );
          } else {
            star = Icon(
              Icons.star_border,
              color: adaptToTheme
                  ? theme.colorScheme.tertiary.withOpacity(0.3)
                  : Colors.amber.withOpacity(0.3),
              size: size * 0.9,
            );
          }
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: star,
          );
        }),
      ),
    );
  }
}

class _EfficiencyMetric extends StatelessWidget {
  final double efficiency;
  final double size;
  final bool adaptToTheme;

  const _EfficiencyMetric({
    required this.efficiency,
    required this.size,
    this.adaptToTheme = true,
  });

  Color _getColor(ThemeData theme) {
    if (!adaptToTheme) {
      if (efficiency >= 1.5) return Colors.green;
      if (efficiency >= 1.0) return Colors.lightGreen;
      if (efficiency >= 0.7) return Colors.orange;
      return Colors.red;
    }

    if (efficiency >= 1.5) return theme.colorScheme.primary;
    if (efficiency >= 1.0) return theme.colorScheme.secondary;
    if (efficiency >= 0.7) return Colors.orange;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(theme);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: efficiency),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${(value * 100).toInt()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressMetric extends StatefulWidget {
  final int progress;
  final double size;
  final bool adaptToTheme;

  const _ProgressMetric({
    required this.progress,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  State<_ProgressMetric> createState() => _ProgressMetricState();
}

class _ProgressMetricState extends State<_ProgressMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors = widget.adaptToTheme
        ? [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.primary,
          ]
        : const [Colors.blue, Colors.purple, Colors.blue];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.progress / 100),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: widget.size * 1.2,
          height: widget.size * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ShaderMask(
                shaderCallback: (rect) {
                  // Ensure the rect is valid before creating shader
                  if (rect.width <= 0 || rect.height <= 0) {
                    return const LinearGradient(
                      colors: [Colors.white],
                    ).createShader(rect);
                  }

                  // Validate SweepGradient parameters
                  const startAngle = -math.pi / 2;
                  const endAngle = 3 * math.pi / 2;

                  // Ensure endAngle >= startAngle for SweepGradient
                  if (endAngle >= startAngle) {
                    try {
                      return SweepGradient(
                        startAngle: startAngle,
                        endAngle: endAngle,
                        tileMode: TileMode.repeated,
                        colors: gradientColors,
                      ).createShader(rect);
                    } catch (e) {
                      // Fallback to simple gradient if SweepGradient fails
                      return LinearGradient(
                        colors: [gradientColors.first, gradientColors.last],
                      ).createShader(rect);
                    }
                  } else {
                    // Fallback to simple gradient if angles are invalid
                    return LinearGradient(
                      colors: [gradientColors.first, gradientColors.last],
                    ).createShader(rect);
                  }
                },

                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: widget.size * 0.12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              CircularProgressIndicator(
                value: animatedProgress,
                strokeWidth: widget.size * 0.12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.transparent,
                ),
              ),
              Text(
                '${(animatedProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: widget.size * 0.3,
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(
                    gradientColors.first,
                    gradientColors.last,
                    animatedProgress,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// REPLACE the _PostedMetric class with this updated version:
class _PostedMetric extends StatefulWidget {
  final Map<String, dynamic>? data;
  final double size;
  final bool adaptToTheme;

  const _PostedMetric({
    this.data,
    required this.size,
    required this.adaptToTheme,
  });

  @override
  State<_PostedMetric> createState() => _PostedMetricState();
}

class _PostedMetricState extends State<_PostedMetric>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _isLive = widget.data?['live'] == true;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (_isLive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PostedMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIsLive = widget.data?['live'] == true;
    if (newIsLive != _isLive) {
      setState(() {
        _isLive = newIsLive;
        if (_isLive) {
          _controller.repeat();
        } else {
          _controller.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show anything if no data
    if (widget.data == null) return const SizedBox.shrink();

    return _isLive
        ? _buildLiveIndicator(theme)
        : _buildSnapshotIndicator(theme);
  }

  Widget _buildLiveIndicator(ThemeData theme) {
    final color = widget.adaptToTheme
        ? theme.colorScheme.primary
        : Colors.green;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = 1.0 - _controller.value;
            final scale = 1.0 + _controller.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(opacity * 0.3),
                ),
              ),
            );
          },
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.cell_tower,
            color: Colors.white,
            size: widget.size * 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotIndicator(ThemeData theme) {
    final color = widget.adaptToTheme
        ? theme.colorScheme.tertiary
        : Colors.indigo;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.public, color: Colors.white, size: widget.size * 0.6),
    );
  }
}

// REPLACE the _SharedMetric class with this updated version:
class _SharedMetric extends StatefulWidget {
  final Map<String, dynamic>? data;
  final double size;
  final bool adaptToTheme;

  const _SharedMetric({
    this.data,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  State<_SharedMetric> createState() => _SharedMetricState();
}

class _SharedMetricState extends State<_SharedMetric>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLive = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _updateFromData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (_isLive) {
      _controller.repeat();
    }
  }

  void _updateFromData() {
    _isLive = widget.data?['live'] == true;
    _count = widget.data?['count'] ?? 0;
  }

  @override
  void didUpdateWidget(covariant _SharedMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIsLive = _isLive;
    _updateFromData();
    if (_isLive != oldIsLive) {
      if (_isLive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show anything if no data
    if (widget.data == null) return const SizedBox.shrink();

    return _isLive
        ? _buildLiveIndicator(theme)
        : _buildSnapshotIndicator(theme);
  }

  Widget _buildLiveIndicator(ThemeData theme) {
    final color = widget.adaptToTheme
        ? theme.colorScheme.secondary
        : Colors.blue;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = 1.0 - _controller.value;
            final scale = 1.0 + _controller.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(opacity * 0.3),
                ),
              ),
            );
          },
        ),
        Container(
          height: widget.size,
          padding: _count > 0
              ? EdgeInsets.symmetric(horizontal: widget.size * 0.3)
              : null,
          width: _count > 0 ? null : widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(widget.size / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share_location, // Live share icon
                color: Colors.white,
                size: widget.size * 0.6,
              ),
              if (_count > 0) ...[
                SizedBox(width: widget.size * 0.15),
                Text(
                  '$_count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotIndicator(ThemeData theme) {
    final color = widget.adaptToTheme
        ? theme.colorScheme.secondary
        : Colors.blue;

    return Container(
      height: widget.size,
      padding: _count > 0
          ? EdgeInsets.symmetric(horizontal: widget.size * 0.3)
          : null,
      width: _count > 0 ? null : widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(widget.size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.share, color: Colors.white, size: widget.size * 0.6),
          if (_count > 0) ...[
            SizedBox(width: widget.size * 0.15),
            Text(
              '$_count',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaCountMetric extends StatelessWidget {
  final int count;
  final double size;
  final bool adaptToTheme;

  const _MediaCountMetric({
    required this.count,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (count == 0) return const SizedBox.shrink();

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: adaptToTheme ? theme.colorScheme.tertiary : Colors.purple,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: (adaptToTheme ? theme.colorScheme.tertiary : Colors.purple)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library, color: Colors.white, size: size * 0.6),
          SizedBox(width: size * 0.15),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCountMetric extends StatelessWidget {
  final int count;
  final double size;
  final bool adaptToTheme;

  const _FeedbackCountMetric({
    required this.count,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (count == 0) return const SizedBox.shrink();

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: Colors.cyan,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.comment, color: Colors.white, size: size * 0.6),
          SizedBox(width: size * 0.15),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeMetric extends StatelessWidget {
  final DateTime? time;
  final TaskMetricType type;
  final double size;
  final bool adaptToTheme;

  const _TimeMetric({
    this.time,
    required this.type,
    required this.size,
    this.adaptToTheme = true,
  });

  IconData _getIcon() {
    switch (type) {
      case TaskMetricType.startingTime:
        return Icons.play_arrow;
      case TaskMetricType.endingTime:
        return Icons.stop;
      case TaskMetricType.completionTime:
        return Icons.check_circle_outline;
      default:
        return Icons.schedule;
    }
  }

  Color _getColor(ThemeData theme) {
    switch (type) {
      case TaskMetricType.startingTime:
        return Colors.green;
      case TaskMetricType.endingTime:
        return Colors.orange;
      case TaskMetricType.completionTime:
        return theme.colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (time == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(theme),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getColor(theme).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(_getIcon(), color: Colors.white, size: size * 0.6),
    );
  }
}

class _TimeOnCompleteMetric extends StatelessWidget {
  final Duration? duration;
  final double size;
  final bool adaptToTheme;

  const _TimeOnCompleteMetric({
    this.duration,
    required this.size,
    this.adaptToTheme = true,
  });

  String _formatDuration() {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (duration == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: theme.colorScheme.onPrimaryContainer,
            size: size * 0.6,
          ),
          SizedBox(width: size * 0.15),
          Text(
            _formatDuration(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLeftMetric extends StatelessWidget {
  final String timeLeft;
  final double size;
  final bool adaptToTheme;

  const _TimeLeftMetric({
    required this.timeLeft,
    required this.size,
    this.adaptToTheme = true,
  });

  bool get _isOverdue => timeLeft.toLowerCase().contains('overdue');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOverdue ? Icons.warning : Icons.schedule,
            color: Colors.white,
            size: size * 0.6,
          ),
          SizedBox(width: size * 0.15),
          Text(
            timeLeft,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverdueMetric extends StatefulWidget {
  final bool isOverdue;
  final double size;
  final bool adaptToTheme;

  const _OverdueMetric({
    required this.isOverdue,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  State<_OverdueMetric> createState() => _OverdueMetricState();
}

class _OverdueMetricState extends State<_OverdueMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.isOverdue) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.size,
          padding: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(
              0.8 + (0.2 * math.sin(_controller.value * 2 * math.pi)),
            ),
            borderRadius: BorderRadius.circular(widget.size / 2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, color: Colors.white, size: widget.size * 0.6),
              SizedBox(width: widget.size * 0.15),
              Text(
                'OVERDUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class _CategoryMetric extends StatelessWidget {
  final String category;
  final double size;
  final Color? customColor;
  final bool adaptToTheme;

  const _CategoryMetric({
    required this.category,
    required this.size,
    this.customColor,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine specific visual properties based on category
    final categoryLower = category.toLowerCase();

    IconData icon;
    Color lightningColor;

    if (categoryLower.contains('week')) {
      icon = Icons.calendar_view_week_rounded;
      lightningColor = const Color(0xFF00E5FF); // Cyber Cyan
    } else if (categoryLower.contains('day')) {
      icon = Icons.today_rounded;
      lightningColor = const Color(0xFFFFD600); // Electric Yellow
    } else if (categoryLower.contains('goal')) {
      icon = Icons.auto_awesome_rounded; // More "Goal/Success" feel
      lightningColor = const Color(0xFF7C4DFF); // Neon Purple
    } else if (categoryLower.contains('bucket')) {
      icon = Icons.shopping_basket_rounded;
      lightningColor = const Color(0xFFFF4081); // Plasma Pink
    } else {
      icon = Icons.category_rounded;
      lightningColor = customColor ?? theme.colorScheme.primary;
    }

    final baseColor = lightningColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [baseColor.withOpacity(0.4), baseColor.withOpacity(0.1)],
        ),
        boxShadow: [
          // Inner glow
          BoxShadow(
            color: baseColor.withOpacity(0.5),
            blurRadius: size * 0.3,
            spreadRadius: -2,
          ),
          // Outer lightning / blast glow
          BoxShadow(
            color: baseColor.withOpacity(0.25),
            blurRadius: size * 0.5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: baseColor.withOpacity(0.6), width: 2),
            ),
          ),
          // The Icon
          Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
            shadows: [
              Shadow(color: baseColor, blurRadius: 10),
              const Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          // Lightning spark with pulse animation
          Positioned(
            top: size * 0.2,
            right: size * 0.2,
            child: _PulseAnimation(
              child: Container(
                width: size * 0.15,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: baseColor, blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineMetric extends StatelessWidget {
  final DateTime? deadline;
  final double size;
  final bool adaptToTheme;

  const _DeadlineMetric({
    this.deadline,
    required this.size,
    this.adaptToTheme = true,
  });

  String _getDeadlineText() {
    if (deadline == null) return 'No deadline';
    final diff = deadline!.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  Color _getColor(ThemeData theme) {
    if (deadline == null) return Colors.grey;
    final diff = deadline!.difference(DateTime.now());
    if (diff.isNegative) return theme.colorScheme.error;
    if (diff.inDays <= 1) return Colors.orange;
    if (diff.inDays <= 7) return Colors.amber;
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(theme);
    final text = _getDeadlineText();

    return Container(
      width: text.length > 3 ? null : size,
      height: size,
      padding: text.length > 3
          ? EdgeInsets.symmetric(horizontal: size * 0.3)
          : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (text.length > 3) ...[
            Icon(Icons.event, color: Colors.white, size: size * 0.6),
            SizedBox(width: size * 0.15),
          ],
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderMetric extends StatefulWidget {
  final bool hasReminder;
  final double size;
  final bool adaptToTheme;

  const _ReminderMetric({
    required this.hasReminder,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  State<_ReminderMetric> createState() => _ReminderMetricState();
}

class _ReminderMetricState extends State<_ReminderMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (!widget.hasReminder) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: math.sin(_controller.value * 2 * math.pi) * 0.1,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: widget.size * 0.6,
            ),
          ),
        );
      },
    );
  }
}

class _TagMetric extends StatelessWidget {
  final List<String> tags;
  final double size;
  final bool adaptToTheme;

  const _TagMetric({
    required this.tags,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: Colors.pink,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label, color: Colors.white, size: size * 0.6),
          SizedBox(width: size * 0.15),
          Text(
            '${tags.length}',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneMetric extends StatefulWidget {
  final bool isMilestone;
  final double size;
  final bool adaptToTheme;

  const _MilestoneMetric({
    required this.isMilestone,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  State<_MilestoneMetric> createState() => _MilestoneMetricState();
}

class _MilestoneMetricState extends State<_MilestoneMetric>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (!widget.isMilestone) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: SweepGradient(
              colors: const [Colors.amber, Colors.orange, Colors.amber],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.flag, color: Colors.white, size: widget.size * 0.6),
        );
      },
    );
  }
}

class _PointsMetric extends StatelessWidget {
  final int points;
  final double size;
  final bool adaptToTheme;

  const _PointsMetric({
    required this.points,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (points == 0) return const SizedBox.shrink();

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: points),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          height: size,
          padding: EdgeInsets.symmetric(horizontal: size * 0.3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.shade300],
            ),
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.white, size: size * 0.6),
              SizedBox(width: size * 0.15),
              Text(
                '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PenaltyMetric extends StatelessWidget {
  final double penalty;
  final double size;
  final bool adaptToTheme;

  const _PenaltyMetric({
    required this.penalty,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (penalty == 0) return const SizedBox.shrink();

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.error.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_circle_outline,
            color: Colors.white,
            size: size * 0.6,
          ),
          SizedBox(width: size * 0.15),
          Text(
            '-${penalty.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardMetric extends StatelessWidget {
  final double reward;
  final double size;
  final bool adaptToTheme;

  const _RewardMetric({
    required this.reward,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (reward == 0) return const SizedBox.shrink();

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green, Colors.green.shade300]),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard, color: Colors.white, size: size * 0.6),
          SizedBox(width: size * 0.15),
          Text(
            '+${reward.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSnapshotMetric extends StatelessWidget {
  final bool isLive;
  final double size;
  final bool adaptToTheme;

  const _LiveSnapshotMetric({
    required this.isLive,
    required this.size,
    this.adaptToTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLive ? Colors.teal : Colors.blueGrey;
    final icon = isLive ? Icons.sensors_rounded : Icons.camera_rounded;

    return Container(
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: size * 0.6),
          SizedBox(width: size * 0.15),
          Text(
            isLive ? 'LIVE' : 'SNAP',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// INDICATOR ROW WIDGET FOR MULTIPLE INDICATORS
// ================================================================

class TaskMetricIndicatorRow extends StatelessWidget {
  final List<TaskMetricIndicator> indicators;
  final double spacing;
  final MainAxisAlignment alignment;
  final bool wrapInScroll;

  const TaskMetricIndicatorRow({
    super.key,
    required this.indicators,
    this.spacing = 8.0,
    this.alignment = MainAxisAlignment.start,
    this.wrapInScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < indicators.length; i++) ...[
          indicators[i],
          if (i < indicators.length - 1) SizedBox(width: spacing),
        ],
      ],
    );

    if (wrapInScroll) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return content;
  }
}

// ================================================================
// QUICK ACCESS WIDGETS
// ================================================================

class QuickStatusIndicator extends StatelessWidget {
  final TaskStatus? status;
  final double size;
  final bool showLabel;
  final Color? customColor;

  const QuickStatusIndicator({
    super.key,
    this.status,
    this.size = 32,
    this.showLabel = false,
    this.customColor,
  });



  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.status,
      value: status ?? TaskStatus.unknown,
      size: size,
      showLabel: showLabel,
    );
  }
}

class QuickProgressIndicator extends StatelessWidget {
  final int progress;
  final double size;
  final bool showLabel;

  const QuickProgressIndicator({
    super.key,
    required this.progress,
    this.size = 32,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.progress,
      value: progress,
      size: size,
      showLabel: showLabel,
    );
  }
}

class QuickPriorityIndicator extends StatelessWidget {
  final String? priority;
  final double size;
  final bool showLabel;

  const QuickPriorityIndicator({
    super.key,
    this.priority,
    this.size = 32,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return TaskMetricIndicator(
      type: TaskMetricType.priority,
      value: priority,
      size: size,
      showLabel: showLabel,
    );
  }
}

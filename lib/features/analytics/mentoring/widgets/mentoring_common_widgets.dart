// ================================================================
// FILE: lib/features/mentoring/widgets/common/mentoring_common_widgets.dart
// Common Widgets for Mentoring Feature
// ================================================================

import 'package:flutter/material.dart';
import '../models/mentorship_model.dart';
import 'mentoring_utils.dart';

// ================================================================
// PART 1: EMPTY STATE WIDGET
// ================================================================

/// Empty state widget for mentoring screen
class MentoringEmptyState extends StatefulWidget {
  final MentoringEmptyType type;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? customIcon;
  final String? customEmoji;
  final bool showAnimation;

  const MentoringEmptyState({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.customIcon,
    this.customEmoji,
    this.showAnimation = true,
  });

  // Factory constructors for common types
  factory MentoringEmptyState.noMentors({VoidCallback? onAddMentor}) {
    return MentoringEmptyState(
      type: MentoringEmptyType.noMentors,
      onAction: onAddMentor,
    );
  }

  factory MentoringEmptyState.noMentees({VoidCallback? onRequestAccess}) {
    return MentoringEmptyState(
      type: MentoringEmptyType.noMentees,
      onAction: onRequestAccess,
    );
  }

  factory MentoringEmptyState.noRequests() {
    return const MentoringEmptyState(type: MentoringEmptyType.noRequests);
  }

  factory MentoringEmptyState.noResults({String? searchQuery}) {
    return MentoringEmptyState(
      type: MentoringEmptyType.noResults,
      subtitle: searchQuery != null
          ? 'No results for "$searchQuery"'
          : 'No results found',
    );
  }

  factory MentoringEmptyState.error({String? message, VoidCallback? onRetry}) {
    return MentoringEmptyState(
      type: MentoringEmptyType.error,
      subtitle: message,
      onAction: onRetry,
    );
  }

  @override
  State<MentoringEmptyState> createState() => _MentoringEmptyStateState();
}

class _MentoringEmptyStateState extends State<MentoringEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
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
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final config = _getEmptyConfig();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon/Emoji Container
              _buildIconContainer(config, colorScheme, isDarkMode),

              const SizedBox(height: 24),

              // Title
              Text(
                widget.title ?? config.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                widget.subtitle ?? config.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Action Button
              if (widget.onAction != null) ...[
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: child,
                    );
                  },
                  child: FilledButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(config.actionIcon),
                    label: Text(widget.actionLabel ?? config.actionLabel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(
    _EmptyStateConfig config,
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    final iconWidget = widget.customEmoji != null
        ? Text(widget.customEmoji!, style: const TextStyle(fontSize: 64))
        : Icon(
            widget.customIcon ?? config.icon,
            size: 80,
            color:
                config.iconColor ??
                colorScheme.primary.withAlpha((255 * 0.7).toInt()),
          );

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (config.iconColor ?? colorScheme.primary).withAlpha(
              (255 * 0.1).toInt(),
            ),
            (config.iconColor ?? colorScheme.primary).withAlpha(
              (255 * 0.05).toInt(),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: (config.iconColor ?? colorScheme.primary).withAlpha(
            (255 * 0.2).toInt(),
          ),
          width: 2,
        ),
      ),
      child: Center(child: iconWidget),
    );
  }

  _EmptyStateConfig _getEmptyConfig() {
    switch (widget.type) {
      case MentoringEmptyType.noMentors:
        return _EmptyStateConfig(
          icon: Icons.people_outline,
          title: 'No Mentors Yet',
          subtitle:
              'Share your progress with a teacher, parent, or coach to get started.',
          actionLabel: 'Share Access',
          actionIcon: Icons.share,
        );
      case MentoringEmptyType.noMentees:
        return _EmptyStateConfig(
          icon: Icons.person_search,
          title: 'No Mentees Yet',
          subtitle:
              'Request access to monitor someone\'s progress and help them grow.',
          actionLabel: 'Request Access',
          actionIcon: Icons.person_add,
        );
      case MentoringEmptyType.noRequests:
        return _EmptyStateConfig(
          icon: Icons.inbox_outlined,
          title: 'No Pending Requests',
          subtitle: 'You\'re all caught up! No pending requests at the moment.',
          actionLabel: '',
          actionIcon: Icons.refresh,
        );
      case MentoringEmptyType.noResults:
        return _EmptyStateConfig(
          icon: Icons.search_off,
          title: 'No Results',
          subtitle: 'Try adjusting your search or filters.',
          actionLabel: 'Clear Search',
          actionIcon: Icons.clear,
        );
      case MentoringEmptyType.error:
        return _EmptyStateConfig(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: 'Something Went Wrong',
          subtitle: 'We couldn\'t load the data. Please try again.',
          actionLabel: 'Retry',
          actionIcon: Icons.refresh,
        );
      case MentoringEmptyType.offline:
        return _EmptyStateConfig(
          icon: Icons.cloud_off,
          iconColor: Colors.orange,
          title: 'You\'re Offline',
          subtitle:
              'Some features may be limited. Connect to the internet to sync.',
          actionLabel: 'Refresh',
          actionIcon: Icons.refresh,
        );
      case MentoringEmptyType.noActive:
        return _EmptyStateConfig(
          icon: Icons.person_off,
          title: 'No Active Connections',
          subtitle: 'Your active mentoring connections will appear here.',
          actionLabel: '',
          actionIcon: Icons.add,
        );
    }
  }
}

enum MentoringEmptyType {
  noMentors,
  noMentees,
  noRequests,
  noResults,
  error,
  offline,
  noActive,
}

class _EmptyStateConfig {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;

  const _EmptyStateConfig({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
  });
}

// ================================================================
// PART 2: LOADING STATE WIDGET
// ================================================================

/// Loading shimmer/skeleton for mentoring screen
class MentoringLoadingState extends StatefulWidget {
  final MentoringLoadingType type;
  final int itemCount;
  final bool showHeader;

  const MentoringLoadingState({
    super.key,
    required this.type,
    this.itemCount = 3,
    this.showHeader = false,
  });

  factory MentoringLoadingState.cards({int count = 3}) {
    return MentoringLoadingState(
      type: MentoringLoadingType.cards,
      itemCount: count,
    );
  }

  factory MentoringLoadingState.list({int count = 5}) {
    return MentoringLoadingState(
      type: MentoringLoadingType.list,
      itemCount: count,
    );
  }

  factory MentoringLoadingState.detail() {
    return const MentoringLoadingState(type: MentoringLoadingType.detail);
  }

  factory MentoringLoadingState.hub() {
    return const MentoringLoadingState(
      type: MentoringLoadingType.hub,
      showHeader: true,
    );
  }

  @override
  State<MentoringLoadingState> createState() => _MentoringLoadingStateState();
}

class _MentoringLoadingStateState extends State<MentoringLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: MentoringConstants.shimmerAnimation,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case MentoringLoadingType.cards:
        return _buildCardsLoading();
      case MentoringLoadingType.list:
        return _buildListLoading();
      case MentoringLoadingType.detail:
        return _buildDetailLoading();
      case MentoringLoadingType.hub:
        return _buildHubLoading();
      case MentoringLoadingType.single:
        return _buildSingleCardLoading();
    }
  }

  Widget _buildCardsLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ShimmerCard(
            controller: _shimmerController,
            height: 140,
            delay: index * 0.15,
          ),
        );
      },
    );
  }

  Widget _buildListLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerListTile(
            controller: _shimmerController,
            delay: index * 0.1,
          ),
        );
      },
    );
  }

  Widget _buildDetailLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _ShimmerCard(controller: _shimmerController, height: 100, delay: 0),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 80,
                  delay: 0.1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 80,
                  delay: 0.15,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 80,
                  delay: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content Cards
          for (int i = 0; i < 3; i++) ...[
            _ShimmerCard(
              controller: _shimmerController,
              height: 120,
              delay: 0.25 + (i * 0.1),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildHubLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 120,
                  delay: 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 120,
                  delay: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section Title
          _ShimmerBox(
            controller: _shimmerController,
            width: 150,
            height: 20,
            delay: 0.2,
          ),
          const SizedBox(height: 16),

          // Request Cards
          for (int i = 0; i < 2; i++) ...[
            _ShimmerCard(
              controller: _shimmerController,
              height: 100,
              delay: 0.25 + (i * 0.1),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 24),

          // Quick Actions
          _ShimmerBox(
            controller: _shimmerController,
            width: 120,
            height: 20,
            delay: 0.45,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 56,
                  delay: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ShimmerCard(
                  controller: _shimmerController,
                  height: 56,
                  delay: 0.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleCardLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _ShimmerCard(
        controller: _shimmerController,
        height: 140,
        delay: 0,
      ),
    );
  }
}

enum MentoringLoadingType { cards, list, detail, hub, single }

// Shimmer Card Widget
class _ShimmerCard extends StatelessWidget {
  final AnimationController controller;
  final double height;
  final double delay;
  final double? width;

  const _ShimmerCard({
    required this.controller,
    required this.height,
    required this.delay,
    // ignore: unused_element_parameter
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shimmerValue = ((controller.value + delay) % 1.0);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
              end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
              colors: isDarkMode
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF3A3A3A),
                      const Color(0xFF2A2A2A),
                    ]
                  : [
                      const Color(0xFFE8E8E8),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE8E8E8),
                    ],
            ),
          ),
        );
      },
    );
  }
}

// Shimmer List Tile Widget
class _ShimmerListTile extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _ShimmerListTile({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shimmerValue = ((controller.value + delay) % 1.0);
        final baseColor = isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE8E8E8);
        final highlightColor = isDarkMode
            ? const Color(0xFF3A3A3A)
            : const Color(0xFFF5F5F5);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
                    end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
                    colors: [baseColor, highlightColor, baseColor],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
                          end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
                          colors: [baseColor, highlightColor, baseColor],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
                          end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
                          colors: [baseColor, highlightColor, baseColor],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
                    end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
                    colors: [baseColor, highlightColor, baseColor],
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

// Shimmer Box Widget
class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final double width;
  final double height;
  final double delay;

  const _ShimmerBox({
    required this.controller,
    required this.width,
    required this.height,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final shimmerValue = ((controller.value + delay) % 1.0);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * shimmerValue), 0),
              end: Alignment(-0.5 + (2.0 * shimmerValue), 0),
              colors: isDarkMode
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF3A3A3A),
                      const Color(0xFF2A2A2A),
                    ]
                  : [
                      const Color(0xFFE8E8E8),
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE8E8E8),
                    ],
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// PART 3: LIVE STATUS BADGE
// ================================================================

/// Animated badge showing live access status
class LiveStatusBadge extends StatefulWidget {
  final bool isLive;
  final bool isActive;
  final bool showLabel;
  final LiveBadgeSize size;
  final DateTime? lastUpdated;

  const LiveStatusBadge({
    super.key,
    required this.isLive,
    this.isActive = true,
    this.showLabel = true,
    this.size = LiveBadgeSize.medium,
    this.lastUpdated,
  });

  factory LiveStatusBadge.small({required bool isLive, bool isActive = true}) {
    return LiveStatusBadge(
      isLive: isLive,
      isActive: isActive,
      showLabel: false,
      size: LiveBadgeSize.small,
    );
  }

  factory LiveStatusBadge.large({
    required bool isLive,
    bool isActive = true,
    DateTime? lastUpdated,
  }) {
    return LiveStatusBadge(
      isLive: isLive,
      isActive: isActive,
      showLabel: true,
      size: LiveBadgeSize.large,
      lastUpdated: lastUpdated,
    );
  }

  @override
  State<LiveStatusBadge> createState() => _LiveStatusBadgeState();
}

class _LiveStatusBadgeState extends State<LiveStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: MentoringConstants.pulseAnimation,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isLive && widget.isActive) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(LiveStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && widget.isActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final config = _getSizeConfig();

    if (!widget.showLabel) {
      return _buildDotOnly(config, isDarkMode);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(config.borderRadius),
        border: Border.all(color: _getBorderColor(isDarkMode), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(config, isDarkMode),
          SizedBox(width: config.spacing),
          Text(
            _getLabel(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getTextColor(isDarkMode),
              fontWeight: FontWeight.w600,
              fontSize: config.fontSize,
            ),
          ),
          if (widget.lastUpdated != null &&
              widget.size == LiveBadgeSize.large) ...[
            SizedBox(width: config.spacing),
            Text(
              '• ${MentoringHelpers.formatTimeAgo(widget.lastUpdated)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: _getTextColor(isDarkMode).withAlpha((255 * 0.7).toInt()),
                fontSize: config.fontSize - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDotOnly(_LiveBadgeSizeConfig config, bool isDarkMode) {
    return SizedBox(
      width: config.dotSize * 2,
      height: config.dotSize * 2,
      child: _buildDot(config, isDarkMode),
    );
  }

  Widget _buildDot(_LiveBadgeSizeConfig config, bool isDarkMode) {
    final dotColor = _getDotColor(isDarkMode);

    return SizedBox(
      width: config.dotSize,
      height: config.dotSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring (only when live and active)
          if (widget.isLive && widget.isActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: config.dotSize,
                    height: config.dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor.withAlpha(
                        (255 * _opacityAnimation.value).toInt(),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Main dot
          Container(
            width: config.dotSize,
            height: config.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: widget.isLive && widget.isActive
                  ? [
                      BoxShadow(
                        color: dotColor.withAlpha((255 * 0.4).toInt()),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDotColor(bool isDarkMode) {
    if (!widget.isActive) {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    }
    if (widget.isLive) {
      return isDarkMode ? Colors.red.shade400 : Colors.red;
    }
    return isDarkMode ? Colors.green.shade400 : Colors.green;
  }

  Color _getBackgroundColor(bool isDarkMode) {
    if (!widget.isActive) {
      return isDarkMode
          ? Colors.grey.shade900.withAlpha((255 * 0.5).toInt())
          : Colors.grey.shade100;
    }
    if (widget.isLive) {
      return isDarkMode
          ? Colors.red.shade900.withAlpha((255 * 0.3).toInt())
          : Colors.red.shade50;
    }
    return isDarkMode
        ? Colors.green.shade900.withAlpha((255 * 0.3).toInt())
        : Colors.green.shade50;
  }

  Color _getBorderColor(bool isDarkMode) {
    if (!widget.isActive) {
      return isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    }
    if (widget.isLive) {
      return isDarkMode ? Colors.red.shade700 : Colors.red.shade200;
    }
    return isDarkMode ? Colors.green.shade700 : Colors.green.shade200;
  }

  Color _getTextColor(bool isDarkMode) {
    if (!widget.isActive) {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
    if (widget.isLive) {
      return isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
    }
    return isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
  }

  String _getLabel() {
    if (!widget.isActive) return 'Inactive';
    if (widget.isLive) return 'Live';
    return 'Active';
  }

  _LiveBadgeSizeConfig _getSizeConfig() {
    switch (widget.size) {
      case LiveBadgeSize.small:
        return const _LiveBadgeSizeConfig(
          dotSize: 6,
          fontSize: 10,
          horizontalPadding: 6,
          verticalPadding: 2,
          borderRadius: 8,
          spacing: 4,
        );
      case LiveBadgeSize.medium:
        return const _LiveBadgeSizeConfig(
          dotSize: 8,
          fontSize: 11,
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 10,
          spacing: 6,
        );
      case LiveBadgeSize.large:
        return const _LiveBadgeSizeConfig(
          dotSize: 10,
          fontSize: 12,
          horizontalPadding: 12,
          verticalPadding: 6,
          borderRadius: 12,
          spacing: 8,
        );
    }
  }
}

enum LiveBadgeSize { small, medium, large }

class _LiveBadgeSizeConfig {
  final double dotSize;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double spacing;

  const _LiveBadgeSizeConfig({
    required this.dotSize,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.spacing,
  });
}

// ================================================================
// PART 4: PERMISSION CHIPS
// ================================================================

/// Display allowed screen/permissions as chips
class PermissionChips extends StatelessWidget {
  final List<AccessibleScreen> screens;
  final MentorshipPermissions? permissions;
  final PermissionChipSize size;
  final int maxVisible;
  final bool interactive;
  final bool showIcons;
  final void Function(AccessibleScreen)? onScreenTap;
  final VoidCallback? onMoreTap;

  const PermissionChips({
    super.key,
    required this.screens,
    this.permissions,
    this.size = PermissionChipSize.medium,
    this.maxVisible = 3,
    this.interactive = false,
    this.showIcons = true,
    this.onScreenTap,
    this.onMoreTap,
  });

  factory PermissionChips.compact({required List<AccessibleScreen> screens}) {
    return PermissionChips(
      screens: screens,
      size: PermissionChipSize.small,
      maxVisible: 2,
      showIcons: false,
    );
  }

  factory PermissionChips.detailed({
    required List<AccessibleScreen> screens,
    required MentorshipPermissions permissions,
    void Function(AccessibleScreen)? onScreenTap,
  }) {
    return PermissionChips(
      screens: screens,
      permissions: permissions,
      size: PermissionChipSize.large,
      maxVisible: 5,
      interactive: true,
      onScreenTap: onScreenTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final config = _getSizeConfig();

    // Check if "all" is selected
    final allPossibleScreens = AccessibleScreen.values;
    final hasAll =
        screens.length == allPossibleScreens.length &&
        allPossibleScreens.every((s) => screens.contains(s));

    final displayScreens = hasAll
        ? [allPossibleScreens.first] // Placeholder for logic below
        : screens;

    final visibleScreens = hasAll
        ? [allPossibleScreens.first] // Special handling for "All" label
        : displayScreens.take(maxVisible).toList();

    final remainingCount = hasAll ? 0 : displayScreens.length - maxVisible;

    return Wrap(
      spacing: config.spacing,
      runSpacing: config.runSpacing,
      children: [
        if (hasAll)
          _buildChip(
            context,
            allPossibleScreens.first,
            config,
            isDarkMode,
            labelOverride: 'All Screens',
          )
        else ...[
          // Visible screen chips
          ...visibleScreens.map(
            (screen) => _buildChip(context, screen, config, isDarkMode),
          ),

          // "More" chip if there are hidden items
          if (remainingCount > 0)
            _buildMoreChip(context, remainingCount, config, isDarkMode),
        ],
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    AccessibleScreen screen,
    _PermissionChipSizeConfig config,
    bool isDarkMode, {
    String? labelOverride,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isAll = labelOverride != null;
    final backgroundColor = isAll
        ? (isDarkMode
              ? colorScheme.primary.withAlpha((255 * 0.2).toInt())
              : colorScheme.primary.withAlpha((255 * 0.1).toInt()))
        : (isDarkMode
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHighest);
    final textColor = isAll
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderColor = isAll
        ? colorScheme.primary.withAlpha((255 * 0.3).toInt())
        : colorScheme.outline.withAlpha((255 * 0.3).toInt());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: interactive ? () => onScreenTap?.call(screen) : null,
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: AnimatedContainer(
          duration: MentoringConstants.fastAnimation,
          padding: EdgeInsets.symmetric(
            horizontal: config.horizontalPadding,
            vertical: config.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcons) ...[
                Icon(
                  isAll ? Icons.apps : screen.icon,
                  size: config.iconSize,
                  color: textColor,
                ),
                SizedBox(width: config.iconSpacing),
              ],
              Text(
                labelOverride ?? screen.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: isAll ? FontWeight.w600 : FontWeight.w500,
                  fontSize: config.fontSize,
                ),
              ),
              if (isAll) ...[
                SizedBox(width: config.iconSpacing),
                Icon(
                  Icons.verified,
                  size: config.iconSize - 2,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreChip(
    BuildContext context,
    int count,
    _PermissionChipSizeConfig config,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMoreTap,
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: config.horizontalPadding,
            vertical: config.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withAlpha(
              (255 * 0.5).toInt(),
            ),
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(
              color: colorScheme.secondary.withAlpha((255 * 0.3).toInt()),
              width: 1,
            ),
          ),
          child: Text(
            '+$count more',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
              fontSize: config.fontSize,
            ),
          ),
        ),
      ),
    );
  }

  _PermissionChipSizeConfig _getSizeConfig() {
    switch (size) {
      case PermissionChipSize.small:
        return const _PermissionChipSizeConfig(
          fontSize: 10,
          iconSize: 12,
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 6,
          spacing: 4,
          runSpacing: 4,
          iconSpacing: 4,
        );
      case PermissionChipSize.medium:
        return const _PermissionChipSizeConfig(
          fontSize: 11,
          iconSize: 14,
          horizontalPadding: 10,
          verticalPadding: 6,
          borderRadius: 8,
          spacing: 6,
          runSpacing: 6,
          iconSpacing: 5,
        );
      case PermissionChipSize.large:
        return const _PermissionChipSizeConfig(
          fontSize: 12,
          iconSize: 16,
          horizontalPadding: 12,
          verticalPadding: 8,
          borderRadius: 10,
          spacing: 8,
          runSpacing: 8,
          iconSpacing: 6,
        );
    }
  }
}

enum PermissionChipSize { small, medium, large }

class _PermissionChipSizeConfig {
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double spacing;
  final double runSpacing;
  final double iconSpacing;

  const _PermissionChipSizeConfig({
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.spacing,
    required this.runSpacing,
    required this.iconSpacing,
  });
}

// ================================================================
// PART 5: ADDITIONAL COMMON WIDGETS
// ================================================================

/// Status indicator dot with optional animation
class StatusDot extends StatefulWidget {
  final AccessStatus status;
  final double size;
  final bool animate;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 10,
    this.animate = false,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.animate && widget.status == AccessStatus.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && widget.status == AccessStatus.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = MentoringColors.getStatusColor(widget.status, isDarkMode);

    if (widget.animate && widget.status == AccessStatus.active) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(
                    (255 * 0.5 * _controller.value).toInt(),
                  ),
                  blurRadius: 4 + (4 * _controller.value),
                  spreadRadius: 1 * _controller.value,
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Relationship type badge
class RelationshipBadge extends StatelessWidget {
  final RelationshipType type;
  final String? customLabel;
  final bool showEmoji;
  final bool compact;

  const RelationshipBadge({
    super.key,
    required this.type,
    this.customLabel,
    this.showEmoji = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final color = MentoringColors.getRelationshipColor(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * (isDarkMode ? 0.2 : 0.1)).toInt()),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: color.withAlpha((255 * 0.3).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showEmoji) ...[
            Text(type.emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            customLabel ?? type.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated counter for leaderboard
class AnimatedCounter extends StatelessWidget {
  final int value;
  final String? label;
  final IconData? icon;
  final Color? color;
  final bool large;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.label,
    this.icon,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: large ? 24 : 18, color: displayColor),
              SizedBox(width: large ? 8 : 4),
            ],
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toString(),
                  style: large
                      ? theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        )
                      : theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: displayColor,
                        ),
                );
              },
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Progress ring indicator
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.backgroundColor,
    this.progressColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        backgroundColor ??
        theme.colorScheme.outline.withAlpha((255 * 0.2).toInt());
    final fgColor = progressColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation(bgColor),
            ),
          ),

          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(fgColor),
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),

          // Child widget
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Expiry countdown widget
class ExpiryCountdown extends StatelessWidget {
  final DateTime? expiresAt;
  final bool showIcon;
  final bool compact;

  const ExpiryCountdown({
    super.key,
    required this.expiresAt,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (expiresAt == null) {
      return _buildContent(
        context,
        icon: Icons.all_inclusive,
        label: compact ? '∞' : 'Never expires',
        color: isDarkMode ? Colors.green.shade400 : Colors.green,
      );
    }

    final remaining = MentoringHelpers.getRemainingTime(expiresAt);

    if (remaining == null || remaining.inSeconds <= 0) {
      return _buildContent(
        context,
        icon: Icons.timer_off,
        label: 'Expired',
        color: isDarkMode ? Colors.red.shade400 : Colors.red,
      );
    }

    final isExpiringSoon = remaining.inDays <= 7;
    final color = isExpiringSoon
        ? (isDarkMode ? Colors.orange.shade400 : Colors.orange)
        : (isDarkMode ? Colors.blue.shade400 : Colors.blue);

    return _buildContent(
      context,
      icon: Icons.timer,
      label: MentoringHelpers.formatRemainingTime(remaining),
      color: color,
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? 4 : 6),
        ],
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: compact ? 10 : 11,
          ),
        ),
      ],
    );
  }
}

/// View count widget with icon
class ViewCountBadge extends StatelessWidget {
  final int count;
  final bool compact;
  final DateTime? lastViewedAt;

  const ViewCountBadge({
    super.key,
    required this.count,
    this.compact = false,
    this.lastViewedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility,
          size: compact ? 14 : 16,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          '$count view${count == 1 ? '' : 's'}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: compact ? 10 : 11,
          ),
        ),
        if (lastViewedAt != null) ...[
          Text(
            ' • ${MentoringHelpers.formatTimeAgo(lastViewedAt)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(
                (255 * 0.7).toInt(),
              ),
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ],
    );
  }
}

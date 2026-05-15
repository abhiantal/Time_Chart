// lib/features/personal/dashboard_model/dashboard_sidebar.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
// removed unused imports
import 'package:the_time_chart/features/analytics/solar_system.dart';
import 'package:the_time_chart/features/analytics/leaderboard/screens/stats_screen.dart';


import 'mentoring/screens/mentoring_hub_screen.dart';

// ================================================================
// SIDEBAR ITEM MODEL
// ================================================================

class DashboardSidebarItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final List<Color> gradient;
  final Widget screen;

  const DashboardSidebarItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.gradient,
    required this.screen,
  });
}

// ================================================================
// DASHBOARD SIDEBAR CONTROLLER
// ================================================================

class DashboardSidebarController extends GetxController
    with GetTickerProviderStateMixin {
  static DashboardSidebarController get to => Get.find();

  // Observable states
  final RxBool isOpen = false.obs;
  final RxInt selectedIndex = 0.obs;
  final RxInt hoveredIndex = (-1).obs;

  // Animation controllers
  late AnimationController slideController;
  late AnimationController fadeController;
  late AnimationController scaleController;
  late AnimationController itemsController;

  // Animations
  late Animation<double> slideAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> blurAnimation;
  late Animation<double> itemsAnimation;

  @override
  void onInit() {
    super.onInit();
    _initAnimations();
  }

  void _initAnimations() {
    slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    itemsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeOutCubic),
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeOut));

    scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.easeOutCubic),
    );

    blurAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeOut));

    itemsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: itemsController, curve: Curves.easeOutCubic),
    );
  }

  void toggleSidebar() {
    if (isOpen.value) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }

  void openSidebar() {
    isOpen.value = true;
    slideController.forward();
    fadeController.forward();
    scaleController.forward();
    itemsController.forward();
    HapticFeedback.mediumImpact();
  }

  void closeSidebar() {
    isOpen.value = false;
    slideController.reverse();
    fadeController.reverse();
    scaleController.reverse();
    itemsController.reverse();
    HapticFeedback.lightImpact();
  }

  void selectItem(int index) {
    selectedIndex.value = index;
    closeSidebar();
  }

  void setHoveredIndex(int index) {
    hoveredIndex.value = index;
    if (index >= 0) {
      HapticFeedback.selectionClick();
    }
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void onClose() {
    slideController.dispose();
    fadeController.dispose();
    scaleController.dispose();
    itemsController.dispose();
    super.onClose();
  }
}

// ================================================================
// DASHBOARD SIDEBAR WRAPPER
// ================================================================

class DashboardSidebar extends StatefulWidget {
  const DashboardSidebar({super.key});

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  late DashboardSidebarController _controller;
  late final List<DashboardSidebarItem> _items;

  @override
  void initState() {
    super.initState();

    // Initialize controller FIRST
    if (!Get.isRegistered<DashboardSidebarController>()) {
      _controller = Get.put(DashboardSidebarController());
    } else {
      _controller = Get.find<DashboardSidebarController>();
    }

    // Initialize items
    _items = [
      DashboardSidebarItem(
        icon: Icons.analytics_rounded,
        label: 'Analytics Hub',
        subtitle: 'Performance metrics',
        route: 'statsScreen',
        gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
        screen: const LeaderboardScreen(),
      ),
      DashboardSidebarItem(
        icon: Icons.people_rounded,
        label: 'Mentor Connect',
        subtitle: 'Guidance & growth',
        route: 'mentoringHubScreen',
        gradient: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
        screen: const MentoringHubScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),

          // Overlay
          _buildOverlay(),

          // Sidebar
          _buildSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Obx(() {
      final selectedIndex = _controller.selectedIndex.value;
      final isOpen = _controller.isOpen.value;

      return AnimatedBuilder(
        animation: Listenable.merge([
          _controller.scaleAnimation,
          _controller.slideAnimation,
          _controller.blurAnimation,
        ]),
        builder: (context, child) {
          final slideValue = _controller.slideAnimation.value;
          final scaleValue = _controller.scaleAnimation.value;
          final blurValue = _controller.blurAnimation.value;
          final translateX = (slideValue + 1) * 280;

          return Transform(
            transform: Matrix4.identity()
              ..translate(translateX, 0.0, 0.0)
              ..scale(scaleValue),
            alignment: Alignment.centerLeft,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isOpen ? 24 : 0),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurValue,
                  sigmaY: blurValue,
                ),
                child: _items[selectedIndex].screen,
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildOverlay() {
    return Obx(() {
      final isOpen = _controller.isOpen.value;

      return AnimatedBuilder(
        animation: _controller.fadeAnimation,
        builder: (context, child) {
          final fadeValue = _controller.fadeAnimation.value;

          if (!isOpen && fadeValue == 0) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: _controller.closeSidebar,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withAlpha((255 * 0.6 * fadeValue).toInt()),
                    Colors.black.withAlpha((255 * 0.3 * fadeValue).toInt()),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _controller.slideAnimation,
      builder: (context, child) {
        final slideValue = _controller.slideAnimation.value;

        return Positioned(
          left: 280 * slideValue,
          top: 0,
          bottom: 0,
          child: _DashboardSidebarContent(
            items: _items,
            controller: _controller,
          ),
        );
      },
    );
  }
}

// ================================================================
// SIDEBAR CONTENT
// ================================================================

class _DashboardSidebarContent extends StatefulWidget {
  final List<DashboardSidebarItem> items;
  final DashboardSidebarController controller;

  const _DashboardSidebarContent({
    required this.items,
    required this.controller,
  });

  @override
  State<_DashboardSidebarContent> createState() =>
      _DashboardSidebarContentState();
}

class _DashboardSidebarContentState extends State<_DashboardSidebarContent>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  late AnimationController _glowController;

  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  double _safeEaseOutCubic(double t) {
    t = t.clamp(0.0, 1.0);
    final result = 1.0 - ((1.0 - t) * (1.0 - t) * (1.0 - t));
    return result.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.35).toInt()),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Enhanced Animated Header
            SolarSystem3DHeader(isDark: true),

            // Animated Divider
            _buildAnimatedDivider(isDark),

            // Menu Items
            Expanded(child: _buildMenuItems(theme, isDark)),

            // Enhanced Footer with Navigation
            _buildEnhancedFooter(context, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDivider(bool isDark) {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                (isDark ? const Color(0xFF667eea) : const Color(0xFF764ba2))
                    .withAlpha(
                      (255 * (0.5 + 0.3 * math.sin(_waveAnimation.value)))
                          .toInt(),
                    ),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF667eea) : const Color(0xFF764ba2))
                        .withAlpha((255 * 0.3).toInt()),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: widget.controller.itemsAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];

            final animationValue = widget.controller.itemsAnimation.value.clamp(
              0.0,
              1.0,
            );
            const delayPerItem = 0.12;
            final startTime = (index * delayPerItem).clamp(0.0, 0.5);
            final endTime = (startTime + 0.5).clamp(0.0, 1.0);

            double staggeredAnimation;
            if (animationValue <= startTime) {
              staggeredAnimation = 0.0;
            } else if (animationValue >= endTime) {
              staggeredAnimation = 1.0;
            } else {
              staggeredAnimation =
                  ((animationValue - startTime) / (endTime - startTime)).clamp(
                    0.0,
                    1.0,
                  );
              staggeredAnimation = _safeEaseOutCubic(staggeredAnimation);
            }

            return Transform.translate(
              offset: Offset(-70 * (1 - staggeredAnimation), 0),
              child: Transform.rotate(
                angle: (1 - staggeredAnimation) * -0.05,
                child: Opacity(
                  opacity: staggeredAnimation.clamp(0.0, 1.0),
                  child: _buildMenuItem(
                    item: item,
                    index: index,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem({
    required DashboardSidebarItem item,
    required int index,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => widget.controller.setHoveredIndex(index),
        onExit: (_) => widget.controller.setHoveredIndex(-1),
        child: GestureDetector(
          onTap: () {
            widget.controller.selectItem(index);
            HapticFeedback.lightImpact();
          },
          child: Obx(() {
            final isSelected = widget.controller.selectedIndex.value == index;
            final isHovered = widget.controller.hoveredIndex.value == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
               transform: Matrix4.translationValues(isHovered ? 6.0 : 0.0, 0.0, 0.0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item.gradient,
                      )
                    : null,
                color: !isSelected
                    ? (isHovered
                          ? (isDark
                                ? Colors.white.withAlpha((255 * 0.08).toInt())
                                : Colors.grey.withAlpha((255 * 0.1).toInt()))
                          : Colors.transparent)
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isHovered
                      ? item.gradient[0].withAlpha((255 * 0.5).toInt())
                      : (isDark
                            ? Colors.white.withAlpha((255 * 0.06).toInt())
                            : Colors.grey.withAlpha((255 * 0.12).toInt())),
                  width: isHovered ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.gradient[0].withAlpha(
                            (255 * 0.4).toInt(),
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: item.gradient[1].withAlpha(
                            (255 * 0.2).toInt(),
                          ),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          spreadRadius: -5,
                        ),
                      ]
                    : isHovered
                    ? [
                        BoxShadow(
                          color: item.gradient[0].withAlpha(
                            (255 * 0.2).toInt(),
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Icon container with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha((255 * 0.25).toInt())
                          : item.gradient[0].withAlpha((255 * 0.12).toInt()),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withAlpha(
                                (255 * 0.2).toInt(),
                              ),
                              width: 1,
                            )
                          : null,
                    ),
                    child: AnimatedScale(
                      scale: isHovered || isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedRotation(
                        turns: isSelected ? 0.02 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.white : item.gradient[0],
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.titleSmall!.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: isHovered ? 14 : 13,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: isSelected
                                ? Colors.white.withAlpha((255 * 0.85).toInt())
                                : (isDark
                                      ? Colors.white.withAlpha(
                                          (255 * 0.5).toInt(),
                                        )
                                      : Colors.black54),
                            fontSize: isHovered ? 11 : 10,
                          ),
                          child: Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow indicator with rotation
                  AnimatedRotation(
                    turns: isSelected
                        ? 0.25
                        : isHovered
                        ? 0.1
                        : 0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedOpacity(
                      opacity: isSelected || isHovered ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : item.gradient[0],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEnhancedFooter(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withAlpha((255 * 0.06).toInt())
                : Colors.black.withAlpha((255 * 0.06).toInt()),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAnimatedFooterButton(
                context: context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                color: const Color(0xFF667eea),
                isDark: isDark,
                onTap: () {
                  widget.controller.closeSidebar();
                  HapticFeedback.lightImpact();
                  // Navigate to settings
                  context.pushNamed('settingsScreen');
                },
              ),
              _buildAnimatedFooterButton(
                context: context,
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                color: const Color(0xFFF093FB),
                isDark: isDark,
                badgeCount: 3, // Show notification count
                onTap: () {
                  widget.controller.closeSidebar();
                  HapticFeedback.lightImpact();
                  // Navigate to notifications
                  context.pushNamed('notificationsScreen');
                },
              ),
              _buildAnimatedFooterButton(
                context: context,
                icon: Icons.help_outline_rounded,
                label: 'Help',
                color: const Color(0xFF4FACFE),
                isDark: isDark,
                onTap: () {
                  widget.controller.closeSidebar();
                  HapticFeedback.lightImpact();
                  // Show help dialog or navigate
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Version info with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Version 1.0.0 • ${DateTime.now().year}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white30 : Colors.black26,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFooterButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: _FooterButtonWithHover(
            icon: icon,
            label: label,
            color: color,
            isDark: isDark,
            onTap: onTap,
            badgeCount: badgeCount,
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4FACFE).withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF4FACFE),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Need Help?'),
          ],
        ),
        content: const Text(
          'For support and documentation, please visit our help center or contact us at support@example.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FOOTER BUTTON WITH HOVER STATE
// ================================================================

class _FooterButtonWithHover extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final int? badgeCount;

  const _FooterButtonWithHover({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.badgeCount,
  });

  @override
  State<_FooterButtonWithHover> createState() => _FooterButtonWithHoverState();
}

class _FooterButtonWithHoverState extends State<_FooterButtonWithHover>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _bounceController.forward(),
        onTapUp: (_) {
          _bounceController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _bounceController.reverse(),
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.color.withAlpha((255 * 0.15).toInt())
                      : (widget.isDark
                            ? Colors.white.withAlpha((255 * 0.05).toInt())
                            : Colors.grey.withAlpha((255 * 0.08).toInt())),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHovered
                        ? widget.color.withAlpha((255 * 0.3).toInt())
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withAlpha((255 * 0.2).toInt()),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.icon,
                            size: _isHovered ? 22 : 20,
                            color: _isHovered
                                ? widget.color
                                : (widget.isDark
                                      ? Colors.white60
                                      : Colors.black54),
                          ),
                        ),
                        if (widget.badgeCount != null && widget.badgeCount! > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(
                                      (255 * 0.4).toInt(),
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: _isHovered
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _isHovered
                            ? widget.color
                            : (widget.isDark ? Colors.white54 : Colors.black45),
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

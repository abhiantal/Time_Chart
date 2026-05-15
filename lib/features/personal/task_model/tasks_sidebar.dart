// lib/features/personal/task_model/tasks_sidebar.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../diary_model/screens/diary_dashboard_screen.dart';
import 'day_tasks/screens/day_schedule_screen.dart';
import 'enhanced_sidebar_header.dart';
import 'long_goal/screens/long_goals_home_screen.dart';
import 'week_task/screens/weekly_schedule_screen.dart';

// ================================================================
// TASK SIDEBAR ITEM MODEL
// ================================================================

class TaskSidebarItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String tag;
  final List<Color> gradient;
  final Widget screen;

  const TaskSidebarItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.tag,
    required this.gradient,
    required this.screen,
  });
}

// ================================================================
// TASK SIDEBAR CONTROLLER
// ================================================================

class TaskSidebarController extends GetxController
    with GetTickerProviderStateMixin {
  static TaskSidebarController get to => Get.find();

  final RxBool _isOpen = false.obs;
  final RxInt _selectedIndex = 0.obs;
  final RxInt _hoveredIndex = (-1).obs;

  late AnimationController slideController;
  late AnimationController fadeController;
  late AnimationController scaleController;
  late AnimationController itemsController;

  late Animation<double> slideAnimation;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> blurAnimation;
  late Animation<double> itemsAnimation;

  bool get isOpen => _isOpen.value;
  int get selectedIndex => _selectedIndex.value;
  int get hoveredIndex => _hoveredIndex.value;

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

    scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.easeOutCubic),
    );

    blurAnimation = Tween<double>(
      begin: 0.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeOut));

    itemsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: itemsController, curve: Curves.easeOutCubic),
    );
  }

  void toggleSidebar() {
    if (_isOpen.value) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }

  void openSidebar() {
    _isOpen.value = true;
    slideController.forward();
    fadeController.forward();
    scaleController.forward();
    itemsController.forward();
    HapticFeedback.mediumImpact();
  }

  void closeSidebar() {
    _isOpen.value = false;
    slideController.reverse();
    fadeController.reverse();
    scaleController.reverse();
    itemsController.reverse();
    HapticFeedback.lightImpact();
  }

  void selectItem(int index) {
    _selectedIndex.value = index;
    closeSidebar();
  }

  void setHoveredIndex(int index) {
    _hoveredIndex.value = index;
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
// TASK SIDEBAR WRAPPER
// ================================================================

class TasksSidebar extends StatefulWidget {
  const TasksSidebar({super.key});

  @override
  State<TasksSidebar> createState() => _TasksSidebarState();
}

class _TasksSidebarState extends State<TasksSidebar> {
  late TaskSidebarController _controller;
  late final List<TaskSidebarItem> _items;

  @override
  void initState() {
    super.initState();

    // Initialize controller FIRST
    if (!Get.isRegistered<TaskSidebarController>()) {
      _controller = Get.put(TaskSidebarController());
    } else {
      _controller = Get.find<TaskSidebarController>();
    }

    // Initialize items
    _items = [
      TaskSidebarItem(
        icon: Icons.today_rounded,
        label: "Today's Focus",
        subtitle: 'Daily priorities & tasks',
        tag: 'DAILY',
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
        screen: const DayScheduleScreen(),
      ),
      TaskSidebarItem(
        icon: Icons.calendar_view_week_rounded,
        label: 'Weekly Planner',
        subtitle: '7-day task overview',
        tag: 'WEEKLY',
        gradient: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
        screen: const WeeklyScheduleScreen(),
      ),
      TaskSidebarItem(
        icon: Icons.flag_rounded,
        label: 'Vision Board',
        subtitle: 'Long-term goals & dreams',
        tag: 'GOALS',
        gradient: [const Color(0xFFA770EF), const Color(0xFFCF8BF3)],
        screen: const LongGoalsHomeScreen(),
      ),
      TaskSidebarItem(
        icon: Icons.flag_rounded,
        label: 'Diary Entries',
        subtitle: 'Reflect on your journey',
        tag: 'DIARY',
        gradient: [const Color(0xFFA770EF), const Color(0xFFCF8BF3)],
        screen: DiaryDashboardScreen(),
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
      final selectedIndex = _controller.selectedIndex;
      final isOpen = _controller.isOpen;

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
              borderRadius: BorderRadius.circular(isOpen ? 28 : 0),
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
      final isOpen = _controller.isOpen;

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
                    Colors.black.withOpacity(0.6 * fadeValue),
                    Colors.black.withOpacity(0.3 * fadeValue),
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
          child: Offstage(
            offstage: slideValue == -1.0,
            child: _TaskSidebarContent(items: _items, controller: _controller),
          ),
        );
      },
    );
  }
}

// ================================================================
// TASK SIDEBAR CONTENT
// ================================================================

class _TaskSidebarContent extends StatefulWidget {
  final List<TaskSidebarItem> items;
  final TaskSidebarController controller;

  const _TaskSidebarContent({required this.items, required this.controller});

  @override
  State<_TaskSidebarContent> createState() => _TaskSidebarContentState();
}

class _TaskSidebarContentState extends State<_TaskSidebarContent>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;

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

    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _particleController.dispose();
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
            color: Colors.black.withOpacity(0.35),
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
            CinematicOceanScene(height: 200, width: 280),

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
                (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF8E53))
                    .withOpacity(0.5 + 0.3 * math.sin(_waveAnimation.value)),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF8E53))
                        .withOpacity(0.3),
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
    required TaskSidebarItem item,
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
            final isSelected = widget.controller.selectedIndex == index;
            final isHovered = widget.controller.hoveredIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              transform: Matrix4.identity()
                ..translate(isHovered ? 6.0 : 0.0, 0.0),
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
                                ? Colors.white.withOpacity(0.08)
                                : Colors.grey.withOpacity(0.1))
                          : Colors.transparent)
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isHovered
                      ? item.gradient[0].withOpacity(0.5)
                      : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.withOpacity(0.12)),
                  width: isHovered ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.gradient[0].withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: item.gradient[1].withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          spreadRadius: -5,
                        ),
                      ]
                    : isHovered
                    ? [
                        BoxShadow(
                          color: item.gradient[0].withOpacity(0.2),
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
                          ? Colors.white.withOpacity(0.25)
                          : item.gradient[0].withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withOpacity(0.2),
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
                                ? Colors.white.withOpacity(0.85)
                                : (isDark
                                      ? Colors.white.withOpacity(0.5)
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

                  // Tag badge with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : item.gradient[0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : item.gradient[0].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : item.gradient[0],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 8,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
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
                  context.pushNamed('settingsScreen');
                },
              ),
              _buildAnimatedFooterButton(
                context: context,
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                color: const Color(0xFFFF6B6B),
                isDark: isDark,
                badgeCount: 5,
                onTap: () {
                  widget.controller.closeSidebar();
                  HapticFeedback.lightImpact();
                  context.pushNamed('notificationsScreen');
                },
              ),
              _buildAnimatedFooterButton(
                context: context,
                icon: Icons.help_outline_rounded,
                label: 'Help',
                color: const Color(0xFF4ECDC4),
                isDark: isDark,
                onTap: () {
                  widget.controller.closeSidebar();
                  HapticFeedback.lightImpact();
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
                  'Task Hub v1.0 • ${DateTime.now().year}',
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
                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF4ECDC4),
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
                      ? widget.color.withOpacity(0.15)
                      : (widget.isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHovered
                        ? widget.color.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.2),
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
                                    color: Colors.red.withOpacity(0.4),
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

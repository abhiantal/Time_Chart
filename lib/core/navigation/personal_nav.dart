import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';
import 'package:the_time_chart/core/Mode/navigation_bar_type.dart';
import 'package:the_time_chart/features/personal/task_model/tasks_sidebar.dart';
import 'package:the_time_chart/features/personal/bucket_model/screen/bucket_list_screen.dart';
import '../../features/analytics/competition/screens/competition_overview_screen.dart';
import '../../features/analytics/dashboard/screens/dashboard_home_screen.dart';
import '../../features/analytics/dashboard_sidebar.dart';

class PersonalNav extends StatefulWidget {
  const PersonalNav({super.key});

  @override
  State<PersonalNav> createState() => _PersonalNavState();
}

class _PersonalNavState extends State<PersonalNav> {
  int _currentIndex = 0;

  final List<Color> _navColors = [
    const Color(0xFF00ACC1), // Cyan for Sidebar/Hub
    const Color(0xFF5E35B1), // Deep Purple for Tasks
    const Color(0xFFFB8C00), // Orange for Bucket/Mode
    const Color(0xFFFDD835), // Gold for Competition
    const Color(0xFF1E88E5), // Blue for Dashboard Home
  ];

  Future<void> _toggleMode() async {
    await HapticFeedback.heavyImpact();
    if (mounted) {
      final provider = context.read<SettingsProvider>();
      await provider.setNavigationBarType(NavigationBarType.social);
      if (mounted) {
        context.goNamed('socialNav');
      }
    }
  }

  final List<Widget> _screens = [
    const DashboardSidebar(),
    const TasksSidebar(),
    const BucketListScreen(),
    const CompetitionOverviewScreen(),
    const DashboardHomeScreen(),
  ];

  List<Widget> _buildIcons(bool isDark) {
    final activeColor = Colors.white;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return [
      _buildIcon(Icons.grid_view_rounded, 0, activeColor, inactiveColor),
      _buildIcon(Icons.checklist_rounded, 1, activeColor, inactiveColor),
      _buildCenterIcon(activeColor, inactiveColor),
      _buildIcon(Icons.leaderboard_rounded, 3, activeColor, inactiveColor),
      _buildIcon(Icons.insights_rounded, 4, activeColor, inactiveColor),
    ];
  }

  Widget _buildIcon(
    IconData icon,
    int index,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;
    return Icon(
      icon,
      size: isSelected ? 30 : 26,
      color: isSelected ? activeColor : inactiveColor,
    );
  }

  Widget _buildCenterIcon(Color activeColor, Color inactiveColor) {
    final isSelected = _currentIndex == 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _toggleMode,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: isSelected ? 32 : 28,
        color: isSelected ? activeColor : inactiveColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Scaffold(
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          color: theme.cardColor,
          buttonBackgroundColor: _navColors[_currentIndex],
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 500),
          index: _currentIndex,
          items: _buildIcons(isDark),
          onTap: (index) {
            HapticFeedback.lightImpact();
            if (index == 2 && _currentIndex == 2) {
              _toggleMode();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          height: 65,
        ),
      ),
    );
  }
}

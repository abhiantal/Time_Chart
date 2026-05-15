import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/user_profile/view_profile/screens/user_profile_screen.dart';
import '../../features/chats/screens/home/chat_hub_screen.dart';
import '../../features/social/feed/screens/feed_screen.dart';
import '../../features/social/screens/create_post_screen.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';
import 'package:the_time_chart/core/Mode/navigation_bar_type.dart';
import '../../notifications/notifications_screen.dart';
import '../../widgets/logger.dart';

/// Social Navigation Screen
/// Manages navigation between social features (Feed, Reels, Create Post, Notifications, Profile)
class SocialNav extends StatefulWidget {
  const SocialNav({super.key});

  @override
  State<SocialNav> createState() => _SocialNavState();
}

class _SocialNavState extends State<SocialNav> {
  int _currentIndex = 0;
  late String _currentUserId;
  late List<Widget> _screens;
  bool _isInitialized = false;

  final List<Color> _navColors = [
    const Color(0xFFE91E63), // Pink for Feed
    const Color(0xFF00BFA5), // Teal for Notifications
    const Color(0xFFFF5252), // Red for Create
    const Color(0xFF7C4DFF), // Deep Purple for Chats
    const Color(0xFF448AFF), // Blue for Profile
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.read<AuthProvider>().currentUser;
      _currentUserId = user?.id ?? '';

      if (_currentUserId.isEmpty) {
        logW('SocialNav initialized without a user ID');
      }

      _screens = [
        FeedScreen(currentUserId: _currentUserId),
        const NotificationsScreen(),
        CreatePostScreen(
          currentUserId: _currentUserId,
          onPostSuccess: () {
            setState(() {
              _currentIndex = 0; // Switch back to Feed
            });
          },
        ),
        const ChatHubScreen(),
        const UserProfileScreen(),
      ];
      _isInitialized = true;
    }
  }

  Future<void> _toggleMode() async {
    await HapticFeedback.heavyImpact();
    if (mounted) {
      final provider = context.read<SettingsProvider>();
      await provider.setNavigationBarType(NavigationBarType.personal);
      if (mounted) {
        context.goNamed('personalNav');
      }
    }
  }

  List<Widget> _buildIcons(bool isDark) {
    final activeColor = Colors.white;
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;

    return [
      _buildIcon(Icons.home_max_rounded, 0, activeColor, inactiveColor),
      _buildIcon(
        Icons.notifications_active_rounded,
        1,
        activeColor,
        inactiveColor,
      ),
      _buildCenterIcon(activeColor, inactiveColor),
      _buildIcon(Icons.forum_rounded, 3, activeColor, inactiveColor),
      _buildIcon(Icons.account_circle_rounded, 4, activeColor, inactiveColor),
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
        Icons.add_box_rounded,
        size: isSelected ? 32 : 28,
        color: isSelected ? activeColor : inactiveColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

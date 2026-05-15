// ================================================================
// FILE: lib/features/user_profile/view_profile/user_profile_menu.dart
// Updated Profile Menu integrated with Mentorship Feature
// ================================================================

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Needed for MentorshipProvider
import 'package:the_time_chart/features/analytics/mentoring/models/mentorship_model.dart';
import 'package:the_time_chart/features/analytics/mentoring/providers/mentorship_provider.dart';
import 'package:the_time_chart/features/analytics/mentoring/screens/mentoring_hub_screen.dart';
import 'package:the_time_chart/features/analytics/mentoring/widgets/mentoring_menus.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_repository.dart';

// Existing Imports
import 'user_profile_card.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/logger.dart';
import '../../create_edit_profile/profile_models.dart';

/// A popup menu for user profile actions.
class ProfileMenu extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;
  final String? validAvatarUrl;

  const ProfileMenu({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.validAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => _buildMenuItems(context),
    );
  }

  /// Builds the list of menu items based on profile ownership and visibility.
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
      const PopupMenuItem(
        value: 'search_user',
        child: Row(
          children: [
            Icon(Icons.search_off_rounded),
            SizedBox(width: 12),
            Text('Search User'),
          ],
        ),
      ),
    );

    // 1. View Profile Card (Always visible if own, or if public)
    if (isOwnProfile || profile.isProfilePublic) {
      items.add(
        const PopupMenuItem(
          value: 'view_card',
          child: Row(
            children: [
              Icon(Icons.badge_outlined),
              SizedBox(width: 12),
              Text('View Profile Card'),
            ],
          ),
        ),
      );
    }

    // 2. Saved Items, Analytics (Only own)
    if (isOwnProfile) {
      items.add(
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem(
          value: 'saved_items',
          child: Row(
            children: [
              Icon(Icons.bookmark_border),
              SizedBox(width: 12),
              Text('Saved Items'),
            ],
          ),
        ),
      );

      items.add(
        const PopupMenuItem(
          value: 'view_analytics',
          child: Row(
            children: [
              Icon(Icons.analytics_outlined),
              SizedBox(width: 12),
              Text('Profile Analytics'),
            ],
          ),
        ),
      );

      // Share My Performance (Mentorship Feature)
      items.add(
        const PopupMenuItem(
          value: 'share_performance',
          child: Row(
            children: [
              Icon(Icons.auto_awesome),
              SizedBox(width: 12),
              Text('Share My Performance'),
            ],
          ),
        ),
      );

      // Manage Connections (New: To view lists of requests/shares)
      items.add(
        const PopupMenuItem(
          value: 'manage_connections',
          child: Row(
            children: [
              Icon(Icons.people_outline),
              SizedBox(width: 12),
              Text('Mentoring Hub'),
            ],
          ),
        ),
      );
    } else {
      // Request Access (New for others)
      items.add(
        const PopupMenuItem(
          value: 'request_access',
          child: Row(
            children: [
              Icon(Icons.lock_open_outlined),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Request Access to Performance',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Share Profile (Always)
    items.add(
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share_outlined),
            SizedBox(width: 12),
            Text('Share Profile'),
          ],
        ),
      ),
    );
    return items;
  }

  /// Handles the selection of a menu item.
  void _handleMenuSelection(BuildContext context, String value) {
    logI('Menu selection: $value');
    switch (value) {
      case 'search_user':
        _navigateToSearchUser(context);
        break;
      case 'view_card':
        _showProfileCard(context);
        break;
      case 'settings':
        _navigateToSettings(context);
        break;
      case 'saved_items':
        _navigateToSavedItems(context);
        break;
      case 'view_analytics':
        _navigateToViewAnalytics(context);
        break;
      // --- Mentoring Actions ---
      case 'share_performance':
        _showShareAccessMenu(context);
        break;
      case 'request_access':
        _showRequestAccessMenu(context);
        break;
      case 'manage_connections':
        _navigateToMentoringHub(context);
        break;
      // -------------------------
      case 'share':
        _shareProfile(context);
        break;
      case 'chat':
        AppSnackbar.info(
          title: 'Coming Soon',
          message: 'Chat feature coming soon!',
        );
        break;
    }
  }

  /// Shows the profile card in a dialog.
  void _showProfileCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: UserProfileCard(
                profile: profile,
                validAvatarUrl: validAvatarUrl,
                isOwnProfile: isOwnProfile,
                onAvatarTap: !isOwnProfile
                    ? () {
                        Navigator.pop(context); // Close dialog
                        context.go('/otherUserProfileScreen/${profile.id}');
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to the profile settings screen.
  void _navigateToSettings(BuildContext context) {
    logI('Navigating to settings profile');
    context.pushNamed('settingsScreen');
  }

  /// Navigates to the user search screen.
  void _navigateToSearchUser(BuildContext context) {
    logI('Navigating to profile search page');
    context.pushNamed('profileSearchPage');
  }

  /// Navigates to the saved items screen.
  void _navigateToSavedItems(BuildContext context) {
    logI('Navigating to savedItems');
    context.pushNamed(
      'savedItems',
      extra: {'userId': profile.id, 'initialCollection': null},
    );
  }

  /// Navigates to the view analytics screen.
  void _navigateToViewAnalytics(BuildContext context) {
    logI('Navigating to viewAnalytics');
    context.pushNamed(
      'viewAnalytics',
      extra: {
        'targetType': 'user',
        'targetId': profile.id,
        'targetOwnerId': profile.id,
      },
    );
  }

  /// Shares the profile URL/Text.
  void _shareProfile(BuildContext context) {
    Share.share('Check out ${profile.username}\'s profile on The Time Chart!');
  }

  // ================================================================
  // MENTORING INTEGRATION METHODS
  // ================================================================

  /// Opens the Share Access bottom sheet (Action 2: Share screen with others)
  Future<void> _showShareAccessMenu(BuildContext context) async {
    // We use the Provider to handle the logic
    final provider = Provider.of<MentorshipProvider>(context, listen: false);

    await ShareAccessMenu.show(
      context,
      // We are sharing OUR access, so we are searching for a viewer.
      // But if we are on our own profile, we might not have a preselected user.
      // If we clicked this from OUR profile, we need to search.
      // If we clicked this from ANOTHER user's profile (unlikely for "Share My"),
      // we usually search.
      // NOTE: "Share My Performance" usually implies picking a friend to share WITH.
      onSearchUsers: (query) async {
        final users = await ProfileRepository().searchProfiles(query);
        return users
            .map(
              (u) => {'id': u.id, 'name': u.username, 'avatar': u.profileUrl},
            )
            .toList();
      },
      onSubmit:
          ({
            required String viewerId,
            required RelationshipType relationshipType,
            String? relationshipLabel,
            required List<AccessibleScreen> screens,
            required MentorshipPermissions permissions,
            required AccessDuration duration,
            required bool isLiveEnabled,
          }) async {
            final result = await provider.shareAccessWith(
              viewerId: viewerId,
              relationshipType: relationshipType,
              relationshipLabel: relationshipLabel,
              screens: screens,
              permissions: permissions,
              duration: duration,
              isLiveEnabled: isLiveEnabled,
            );
            return result != null;
          },
    );
  }

  /// Opens the Request Access bottom sheet (Action 1: Request to view others)
  Future<void> _showRequestAccessMenu(BuildContext context) async {
    // We use the Provider to handle the logic
    final provider = Provider.of<MentorshipProvider>(context, listen: false);

    await RequestAccessMenu.show(
      context,
      targetUserId: profile.id, // The user we want to view
      targetUserName: profile.username, // Name for display
      targetUserAvatar: validAvatarUrl, // Avatar for display
      onSubmit:
          ({
            required String targetUserId,
            required RelationshipType relationshipType,
            String? relationshipLabel,
            required List<AccessibleScreen> screens,
            required AccessDuration duration,
            String? message,
          }) async {
            final result = await provider.sendAccessRequest(
              targetUserId: targetUserId,
              relationshipType: relationshipType,
              relationshipLabel: relationshipLabel,
              screens: screens,
              duration: duration,
              message: message,
            );
            return result != null;
          },
    );
  }

  /// Navigates to the Mentoring Hub to view lists of requests/shares
  void _navigateToMentoringHub(BuildContext context) {
    // You can use GoRouter or simple Navigation depending on your setup
    // Assuming standard navigation for now or add route to your GoRouter config
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MentoringHubScreen()),
    );
    //Alternatively if you add a route:
    context.pushNamed('mentoringHub');
  }
}

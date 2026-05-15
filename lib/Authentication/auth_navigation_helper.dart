import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../user_profile/create_edit_profile/profile_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/logger.dart';

/// Centralized helper for authentication-related navigation and profile verification
class AuthNavigationHelper {
  AuthNavigationHelper._();

  static final _snackbar = SnackbarService();

  /// Verifies profile completion and navigates to the appropriate screen
  /// [showFeedback] - Whether to show success/info snackbars
  static Future<void> checkProfileAndNavigate(
    BuildContext context, {
    bool showFeedback = true,
  }) async {
    final profileProvider = context.read<ProfileProvider>();

    // 1. Quick check: If profile is already loaded and complete, navigate immediately
    if (profileProvider.myProfile != null &&
        profileProvider.myProfile!.onboardingCompleted) {
      if (showFeedback) {
        _snackbar.showSuccess(
          'Welcome back, ${profileProvider.myProfile!.displayName}!',
        );
      }
      if (context.mounted) {
        context.goNamed('personalNav');
      }
      return;
    }

    // 2. Load profile if not already loaded or if missing data
    try {
      // Use silent: true to avoid triggering "Loading" status and unnecessary UI rebuilds
      await profileProvider.loadMyProfile(silent: true);

      if (!context.mounted) return;

      final profile = profileProvider.myProfile;

      // 3. Check for completeness
      if (profile != null && profile.onboardingCompleted) {
        if (showFeedback) {
          _snackbar.showSuccess('Welcome back!');
        }
        context.goNamed('personalNav');
      } else {
        // Incomplete profile - find missing field and step
        final missingField = profile?.getFirstMissingField() ?? 'Profile Info';
        final initialStep = profile?.getOnboardingStepIndex() ?? 0;

        logI(
          'Profile incomplete. Missing: $missingField. Navigating to step: $initialStep',
        );

        if (showFeedback) {
          _snackbar.showInfo(
            'Incomplete profile',
            description: 'Please complete your $missingField',
          );
        }

        context.goNamed(
          'profileCreate',
          extra: {
            'userId': profileProvider.currentUserId,
            'email': profileProvider.email,
            'initialStep': initialStep,
          },
        );
      }
    } catch (e) {
      logE('Failed to verify profile during navigation', error: e);
      if (showFeedback && context.mounted) {
        _snackbar.showError(
          'Navigation failed',
          description: 'Could not verify profile',
        );
      }
    }
  }
}

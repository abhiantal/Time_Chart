// ================================================================
// FILE: lib/config/splash_screen.dart
// OPTIMIZED - Fast loading with progress feedback
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../Authentication/auth_navigation_helper.dart';
import '../Authentication/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../app_initializer.dart';
import '../core/Mode/navigation_bar_type.dart';
import '../user_profile/create_edit_profile/profile_provider.dart';
import '../user_settings/providers/settings_provider.dart';
import '../widgets/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  String _currentStep = 'Starting...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Remove native splash immediately to show our animated splash or progress
      FlutterNativeSplash.remove();
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize app services with progress updates
      // This runs heavy tasks in background
      await AppInitializer().initialize(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _currentStep = step;
              _progress = progress;
            });
          }
          logI('Init: $step - ${(progress * 100).toInt()}%');
        },
      );

      if (!mounted || _hasNavigated) return;

      final authProvider = context.read<AuthProvider>();
      final profileProvider = context.read<ProfileProvider>();

      // Check authentication
      // AuthProvider lazily initializes, so accessing currentUser might trigger it
      // But AppInitializer should have set up the listener already
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        logI('✓ User authenticated: ${currentUser.email}');

        // Load profile (fire and forget)
        // Ensure this doesn't block navigation significantly
        // We use microtask to detach it from current execution frame if needed
        Future.microtask(() => profileProvider.loadProfile());

        // Navigate immediately
        if (mounted && !_hasNavigated) {
          _navigateToHome();
        }
      } else {
        logI('→ No session - showing sign in');

        if (mounted && !_hasNavigated) {
          _navigateToSignIn();
        }
      }
    } catch (e, stackTrace) {
      logE('❌ Init failed', error: e, stackTrace: stackTrace);

      // Even on failure, try to navigate to sign in or show error
      if (mounted && !_hasNavigated) {
        _navigateToSignIn();
      }
    }
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Use centralized navigation helper to check profile completion
    AuthNavigationHelper.checkProfileAndNavigate(context, showFeedback: false);
  }

  void _navigateToSignIn() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    context.goNamed('signIn');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 32),

            // App Name
            Text(
              'Time Chart',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 48),

            // Progress Indicator with percentage
            SizedBox(
              width: 220,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 3,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentStep,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

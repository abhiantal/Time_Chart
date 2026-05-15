// ================================================================
// FILE: lib/main.dart
// OPTIMIZED - Fastest possible startup with proper initialization
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';
import 'config/env_config.dart';
import 'core/providers/app_setup.dart';
import 'core/routes/app_routes.dart';
import 'notifications/notification_setup.dart';
import 'notifications/core/firebase_notification_core.dart';
import 'notifications/presentation/firebase_options.dart';
import 'services/supabase_service.dart';
import 'user_settings/providers/settings_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI immediately
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // 1. Firebase FIRST — before any other service
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Register FCM background message handler immediately after Firebase init
    // This must happen in main(), at the top level, before runApp().
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 3. Other services
    // Load environment config
    await EnvConfig.load();

    // Initialize Supabase - Minimal setup required for Providers
    // We do NOT wait for session verification here.
    await SupabaseService().initialize();

    // Initialize SettingsProvider for Theme - Fast local storage read
    // Only load local prefs here. Full DB init happens in AppInitializer.
    await SettingsProvider().loadLocalPreferences();

    // Run the app IMMEDIATELY
    // Heavy initialization happens in SplashScreen
    runApp(const MyApp());
  } catch (e, stackTrace) {
    logE("Fatal initialization error: $e", error: e, stackTrace: stackTrace);
    // Fallback UI
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Failed to start app: $e'))),
      ),
    );
  }
}

// ================================================================
// APP WIDGET
// ================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [...AppSetup.getProviders()],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final themeData = settings.getThemeData(context);

          return MaterialApp.router(
            title: 'Time Chart',
            debugShowCheckedModeBanner: false,
            theme: themeData,
            darkTheme: themeData,
            themeMode: settings.flutterThemeMode,
            locale: settings.getLocale(),
            supportedLocales: settings.supportedLocales,
            localizationsDelegates: settings.localizationsDelegates,
            routerConfig: AppRoutes.router,
            builder: (context, child) {
              // Notification context update if initialized
              if (notificationSetup.isInitialized) {
                notificationSetup.updateContext(context);
              }

              return AppLockWrapper(
                child: Stack(
                  children: [
                    child!,
                    AppSnackbar(key: snackbarService.snackbarKey),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ================================================================
// APP LOCK WRAPPER
// ================================================================

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check if provider is available before accessing
    if (!mounted) return;

    try {
      final settings = context.read<SettingsProvider>().settings;
      if (settings == null) return;

      final security = settings.security;
      if (!security.appLockEnabled && !security.biometricLock) return;

      if (state == AppLifecycleState.paused) {
        _pausedAt = DateTime.now();
      } else if (state == AppLifecycleState.resumed) {
        if (_pausedAt == null) return;
        final elapsed = DateTime.now().difference(_pausedAt!);

        if (security.appLockTimeout == 0 ||
            elapsed.inSeconds >= security.appLockTimeout) {
          setState(() {
            _isLocked = true;
          });
        }
      }
    } catch (_) {
      // Ignore provider errors during shutdown/reload
    }
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
      _pausedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 24),
                Text(
                  'App Locked',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

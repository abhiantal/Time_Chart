// lib/features/settings/screen/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:provider/provider.dart';
import 'package:the_time_chart/user_settings/screens/storage_settings_screen.dart';
import 'package:the_time_chart/user_settings/screens/task_settings_screen.dart';
import '../../user_profile/create_edit_profile/profile_provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import 'ai_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'chat_settings_screen.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import 'notification_settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/error_handler.dart';
import '../../widgets/logger.dart';
import 'dart:async';
import 'social_settings_screen.dart';
import 'analytics_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/powersync_service.dart';
import '../../media_utility/universal_media_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && !provider.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.hasError) {
              return _buildErrorState(context, provider);
            }

            return _buildSettingsList(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SettingsProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.reload(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Profile Section
        _buildProfileCardCompact(context, provider),

        // Preferences
        const SettingsSectionHeader(title: 'Preferences', icon: Icons.tune),
        SettingsCard(
          children: [
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _getThemeSubtitle(provider),
              onTap: () =>
                  _navigateTo(context, const AppearanceSettingsScreen()),
            ),
            SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'System, sound & quiet hours',
              onTap: () =>
                  _navigateTo(context, const NotificationSettingsScreen()),
            ),
          ],
        ),

        // Features
        const SettingsSectionHeader(
          title: 'Features',
          icon: Icons.widgets_outlined,
        ),
        SettingsCard(
          children: [
            SettingsTile(
              icon: Icons.task_alt_outlined,
              title: 'Tasks',
              subtitle: 'Default view, priorities & more',
              onTap: () => _navigateTo(context, const TaskSettingsScreen()),
            ),
            SettingsTile(
              icon: Icons.chat_outlined,
              title: 'Chat',
              subtitle: 'Messages, media & backup',
              onTap: () => _navigateTo(context, const ChatSettingsScreen()),
            ),
            SettingsTile(
              icon: Icons.auto_awesome_outlined,
              iconColor: Colors.purple,
              title: 'AI Assistant',
              subtitle: provider.ai.enabled ? 'Enabled' : 'Disabled',
              onTap: () => _navigateTo(context, const AiSettingsScreen()),
            ),
            SettingsTile(
              icon: Icons.people_outline,
              title: 'Social',
              subtitle: 'Feed visibility & muted content',
              onTap: () => _navigateTo(context, const SocialSettingsScreen()),
            ),
            SettingsTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics & Competition',
              subtitle: 'Insights, reports & challenges',
              onTap: () =>
                  _navigateTo(context, const AnalyticsSettingsScreen()),
            ),
          ],
        ),

        // Security
        const SettingsSectionHeader(
          title: 'Security',
          icon: Icons.shield_outlined,
        ),
        SettingsCard(
          children: [
            SettingsTile(
              icon: Icons.password_outlined,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePasswordDialog(context),
            ),
          ],
        ),

        // More Section (Storage)
        const SettingsSectionHeader(title: 'More', icon: Icons.more_horiz),
        SettingsCard(
          children: [
            SettingsTile(
              icon: Icons.storage_outlined,
              title: 'Storage & Data',
              subtitle: 'Sync, backup & cache',
              onTap: () => _navigateTo(context, const StorageSettingsScreen()),
            ),
          ],
        ),

        // Danger Zone
        const SettingsSectionHeader(
          title: 'Danger Zone',
          icon: Icons.warning_amber_outlined,
        ),
        SettingsCard(
          children: [
            SettingsTile(
              icon: Icons.restore,
              iconColor: Colors.orange,
              title: 'Reset Settings',
              subtitle: 'Restore all settings to default',
              showChevron: false,
              onTap: () => _showResetConfirmation(context, provider),
            ),
            SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Sign Out',
              isDestructive: true,
              showChevron: false,
              onTap: () => _showSignOutConfirmation(context),
            ),
            SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              title: 'Delete Account',
              subtitle: 'Permanently delete account & all data',
              isDestructive: true,
              showChevron: false,
              onTap: () => _showDeleteAccountConfirmation(context),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileCardCompact(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final userProfileProvider = context.watch<ProfileProvider>();
    final profile = userProfileProvider.currentProfile;

    final displayName = profile?.username ?? 'Guest User';
    final email = profile?.email ?? '';
    final avatarUrl = profile?.profileUrl;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: isDark ? 2 : 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToProfile(context, profile),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Gradient Avatar Container
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.surface,
                  child: ClipOval(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? (avatarUrl.startsWith('http') || avatarUrl.startsWith('https')
                              ? Image.network(
                                  avatarUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _getInitials(displayName),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(avatarUrl),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _getInitials(displayName),
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    );
                                  },
                                ))
                          : Center(
                              child: Text(
                                _getInitials(displayName),
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'G';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  void _navigateToProfile(BuildContext context, dynamic profile) {
    if (profile?.id != null) {
      context.pushNamed('profileEdit');
    }
  }

  String _getThemeSubtitle(SettingsProvider provider) {
    switch (provider.themeMode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showResetConfirmation(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.orange),
            SizedBox(width: 12),
            Text('Reset Settings'),
          ],
        ),
        content: const Text(
          'This will restore all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              AppSnackbar.loading(title: 'Resetting settings...');
              try {
                final success = await provider.resetAllSettings();
                AppSnackbar.hideLoading();
                if (success) {
                  AppSnackbar.success('Settings restored to defaults');
                } else {
                  AppSnackbar.error('Failed to reset settings');
                }
              } catch (e) {
                AppSnackbar.hideLoading();
                AppSnackbar.error(
                  'Error resetting settings',
                  description: e.toString(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: colorScheme.error),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? You\'ll need to sign in again to access your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              AppSnackbar.loading(title: 'Signing out...');

              try {
                // 1. Clear local settings cache fast
                context.read<SettingsProvider>().clearCache();

                // 2. Clear local media cache
                UniversalMediaService().clearCache().catchError((_) {});

                // 3. Trigger remote sign out in the background (fire-and-forget)
                SupabaseService.instance.signOut().catchError((_) {});

                // 4. Wipe local data immediately
                await PowerSyncService().clearLocalData(reinitialize: false).timeout(const Duration(seconds: 5));
              } catch (_) {}

              // 5. Navigate immediately
              if (context.mounted) {
                AppSnackbar.hideLoading();
                context.go('/signIn');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ensure your new password is at least 6 characters long and includes a mix of characters.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // New Password Field
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 characters required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Repeat your password',
                      prefixIcon: const Icon(Icons.shield_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);
                        try {
                          await Supabase.instance.client.auth.updateUser(
                            UserAttributes(password: passwordController.text),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          ErrorHandler.showSuccessSnackbar(
                            'Password updated successfully',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                          }
                          ErrorHandler.showErrorSnackbar(
                            'Failed to update password: ${e.toString()}',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Update Password',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is PERMANENT and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'EVERYTHING will be deleted:\n'
              '• Your profile and account\n'
              '• All tasks, goals, and diary entries\n'
              '• All chat history and media\n'
              '• All cloud and local data',
            ),
            const SizedBox(height: 16),
            const Text('Are you absolutely sure you want to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteAccountConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Final Confirmation'),
        content: const Text(
          'Last chance: Do you really want to delete your entire account and all data forever?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeDeleteAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('YES, DELETE ALL'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount(BuildContext context) async {
    AppSnackbar.loading(title: 'Permanently deleting account...');

    try {
      final supabase = SupabaseService.instance;
      final powerSync = PowerSyncService();
      final mediaService = UniversalMediaService();

      // 1. Pre-emptive disconnect: Stop all sync activity immediately
      await powerSync.disconnect();

      // 2. Fire backend wipes in the background (fire-and-forget)
      // This runs on Supabase server completely independent of client UI, bypassing slow transactions.
      logI('Initiating background backend wipe...');
      supabase.wipeAllUserStorage(includeProfile: true).catchError((e) {
        logW('Background user storage delete failed: $e');
      });
      supabase.callRpc(functionName: 'delete_own_account').catchError((e) {
        logW('Background user account delete RPC failed: $e');
      });

      // 3. Clean up all local storage instantly
      logI('Executing local database and cache wipe...');
      await Future.wait([
        powerSync.clearLocalData(reinitialize: false),
        mediaService.clearCache(),
        SharedPreferences.getInstance().then((prefs) => prefs.clear()),
      ]).timeout(const Duration(seconds: 5));

      // 4. Reset settings provider cache
      if (context.mounted) {
        context.read<SettingsProvider>().clearCache();
      }

      // 5. Fire-and-forget Supabase client sign out
      supabase.signOut().catchError((_) {});

      // 6. Complete and navigate instantly
      AppSnackbar.hideLoading();
      AppSnackbar.success('Account and all data deleted forever');
      
      if (context.mounted) {
        context.go('/signIn');
      }
    } catch (e) {
      logE('Delete account local cleanup failed', error: e);
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Deletion failed',
        description: 'Failed to complete local cleanup.',
      );
    }
  }
}

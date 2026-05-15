// lib/features/settings/screen/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('General Notifications'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final notifications = provider.notifications;
            final channels = notifications.channels;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Master Toggle
                SettingsCard(
                  margin: const EdgeInsets.all(16),
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: provider.notificationsEnabled
                          ? Colors.green
                          : null,
                      title: 'Enable Notifications',
                      subtitle: 'Receive push notifications',
                      value: provider.notificationsEnabled,
                      isLoading: provider.isLoadingFor('notifications'),
                      onChanged: (_) => provider.toggleNotifications(),
                    ),
                  ],
                ),

                if (provider.notificationsEnabled) ...[
                  // Notification Preferences
                  const SettingsSectionHeader(
                    title: 'Preferences',
                    icon: Icons.tune,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.volume_up_outlined,
                        title: 'Sound',
                        subtitle: 'Play sound for notifications',
                        value: notifications.sound,
                        onChanged: (_) => provider.toggleSound(),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.vibration_outlined,
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: notifications.vibration,
                        onChanged: (_) => provider.toggleVibration(),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.badge_outlined,
                        title: 'Badge count',
                        subtitle: 'Show unread count on app icon',
                        value: notifications.badgeCount,
                        onChanged: (value) {
                          provider.updateNotifications(
                            notifications.copyWith(badgeCount: value),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.visibility_outlined,
                        title: 'Preview content',
                        subtitle: 'Show message preview in notifications',
                        value: notifications.previewContent,
                        onChanged: (value) {
                          provider.updateNotifications(
                            notifications.copyWith(previewContent: value),
                          );
                        },
                      ),
                    ],
                  ),

                  // Quiet Hours
                  const SettingsSectionHeader(
                    title: 'Quiet Hours',
                    icon: Icons.do_not_disturb_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.bedtime_outlined,
                        title: 'Enable quiet hours',
                        subtitle: 'Silence notifications during set times',
                        value: notifications.quietHours.enabled,
                        onChanged: (value) {
                          provider.setQuietHours(enabled: value);
                        },
                      ),
                      if (notifications.quietHours.enabled) ...[
                        SettingsTimeTile(
                          icon: Icons.access_time,
                          title: 'Start time',
                          value: _parseTime(notifications.quietHours.start),
                          onChanged: (time) {
                            provider.setQuietHours(
                              enabled: true,
                              startTime: _formatTime(time),
                            );
                          },
                        ),
                        SettingsTimeTile(
                          icon: Icons.access_time_filled,
                          title: 'End time',
                          value: _parseTime(notifications.quietHours.end),
                          onChanged: (time) {
                            provider.setQuietHours(
                              enabled: true,
                              endTime: _formatTime(time),
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  // Channels
                  const SettingsSectionHeader(
                    title: 'System Notifications',
                    icon: Icons.system_update_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.system_update_outlined,
                        title: 'System alerts',
                        subtitle: 'Updates, security & critical alerts',
                        value: channels.system.enabled,
                        onChanged: (value) {
                          provider.setNotificationChannel(
                            channel: 'system',
                            enabled: value,
                          );
                        },
                      ),
                    ],
                  ),
                ],

                // Info Banner for disabled notifications
                if (!provider.notificationsEnabled)
                  SettingsInfoBanner(
                    icon: Icons.notifications_off_outlined,
                    title: 'Notifications are disabled',
                    message:
                        'Enable notifications to receive important updates about your tasks, goals, and messages.',
                    color: Colors.orange,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

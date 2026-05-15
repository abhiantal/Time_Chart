import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/dialogs/mute_options_sheet.dart';
import '../../../../user_settings/widgets/settings_widgets.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/logger.dart';

class ChatNotificationSettingsScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;

  const ChatNotificationSettingsScreen({super.key, required this.chatId, this.chatName});

  @override
  State<ChatNotificationSettingsScreen> createState() => _ChatNotificationSettingsScreenState();
}

class _ChatNotificationSettingsScreenState extends State<ChatNotificationSettingsScreen> {
  NotificationLevel _notificationLevel = NotificationLevel.all;
  bool _isMuted = false;
  bool _vibrationEnabled = true;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final provider = context.read<ChatProvider>();
    try {
      final chat = provider.chats.firstWhere((c) => c.id == widget.chatId);
      setState(() {
        _isMuted = chat.isMuted;
        final levelStr = chat.metadata['notification_level'] as String?;
        if (levelStr != null) {
          _notificationLevel = NotificationLevel.fromString(levelStr);
        }
        
        // Add hardening for vibration and preview
        _vibrationEnabled = chat.metadata['vibration_enabled'] as bool? ?? true;
        _showPreview = chat.metadata['show_preview'] as bool? ?? true;
      });
    } catch (_) {}
  }

  Future<void> _updateMetadata(String key, dynamic value) async {
    final provider = context.read<ChatProvider>();
    try {
      final chat = provider.chats.firstWhere((c) => c.id == widget.chatId);
      final newMetadata = Map<String, dynamic>.from(chat.metadata);
      newMetadata[key] = value;
      
      await provider.updateChatMetadata(widget.chatId, newMetadata);
    } catch (e, stackTrace) {
      logE('Error updating chat setting: $key', error: e, stackTrace: stackTrace);
      AppSnackbar.error('Failed to update setting');
    }
  }

  Future<void> _updateNotificationLevel(NotificationLevel level) async {
    await _updateMetadata('notification_level', level.name);
    setState(() => _notificationLevel = level);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.chatName ?? 'Notifications'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SettingsSectionHeader(
            title: 'Alerts',
            icon: Icons.notifications_outlined,
          ),
          SettingsCard(
            children: [
              SettingsSwitchTile(
                icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                title: 'Mute Notifications',
                subtitle: _isMuted ? 'Currently muted' : 'Currently active',
                value: _isMuted,
                onChanged: (value) async {
                  if (value) {
                    _showMuteOptions();
                  } else {
                    await context.read<ChatProvider>().toggleMute(widget.chatId, false);
                    setState(() => _isMuted = false);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SettingsChoiceChips<NotificationLevel>(
                  title: 'Notification Level',
                  subtitle: 'Choose which messages trigger an alert',
                  value: _notificationLevel,
                  choices: const [
                    SettingsChoice(
                      value: NotificationLevel.all,
                      label: 'All Messages',
                    ),
                    SettingsChoice(
                      value: NotificationLevel.mentions,
                      label: 'Only Mentions',
                    ),
                    SettingsChoice(
                      value: NotificationLevel.none,
                      label: 'None',
                    ),
                  ],
                  onChanged: (value) {
                    _updateNotificationLevel(value);
                  },
                ),
              ),
            ],
          ),
          
          const SettingsSectionHeader(
            title: 'Privacy & Sound',
            icon: Icons.security_outlined,
          ),
          SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.music_note_outlined,
                title: 'Custom Sound',
                subtitle: 'Default', // TODO: Implement custom sounds
                onTap: () {},
              ),
              SettingsSwitchTile(
                icon: Icons.vibration_outlined,
                title: 'Vibration',
                subtitle: 'Vibrate on message arrival',
                value: _vibrationEnabled,
                onChanged: (v) {
                  _updateMetadata('vibration_enabled', v);
                  setState(() => _vibrationEnabled = v);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.preview_outlined,
                title: 'Show Preview',
                subtitle: 'Show message text in notifications',
                value: _showPreview,
                onChanged: (v) {
                  _updateMetadata('show_preview', v);
                  setState(() => _showPreview = v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMuteOptions() {
    showMuteOptionsSheet(
      context,
      isCurrentlyMuted: _isMuted,
      onUnmute: () {
        context.read<ChatProvider>().toggleMute(widget.chatId, false);
        setState(() => _isMuted = false);
      },
    ).then((duration) {
      if (duration != null) {
        final provider = context.read<ChatProvider>();
        Duration? d;
        switch (duration) {
          case MuteDuration.oneHour: d = const Duration(hours: 1); break;
          case MuteDuration.eightHours: d = const Duration(hours: 8); break;
          case MuteDuration.oneDay: d = const Duration(days: 1); break;
          case MuteDuration.oneWeek: d = const Duration(days: 7); break;
          case MuteDuration.always: d = null; break;
          default: d = null;
        }
        provider.toggleMute(widget.chatId, true, muteDuration: d);
        setState(() => _isMuted = true);
      }
    });
  }
}

// lib/features/settings/screen/chat_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/community_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chat Settings'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final chat = provider.chat;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Chat Behavior
                const SettingsSectionHeader(
                  title: 'Chat Behavior',
                  icon: Icons.chat_bubble_outline,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.keyboard_return,
                      title: 'Enter to send',
                      subtitle: 'Send messages with Enter key',
                      value: chat.enterToSend,
                      onChanged: (_) => provider.toggleEnterToSend(),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emoji_emotions_outlined,
                      title: 'Emoji suggestions',
                      subtitle: 'Show emoji suggestions while typing',
                      value: chat.emojiSuggestions,
                      onChanged: (value) {
                        provider.updateChat(
                          chat.copyWith(emojiSuggestions: value),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'Sticker suggestions',
                      subtitle: 'Show sticker suggestions',
                      value: chat.stickerSuggestions,
                      onChanged: (value) {
                        provider.updateChat(
                          chat.copyWith(stickerSuggestions: value),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.link_outlined,
                      title: 'Link preview',
                      subtitle: 'Show preview for links',
                      value: chat.linkPreview,
                      onChanged: (value) {
                        provider.updateChat(chat.copyWith(linkPreview: value));
                      },
                    ),
                  ],
                ),

                // Media & Downloads
                const SettingsSectionHeader(
                  title: 'Media & Downloads',
                  icon: Icons.download_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSegmentedControl<MediaAutoDownload>(
                      title: 'Auto-download media',
                      value: chat.mediaAutoDownload,
                      segments: const {
                        MediaAutoDownload.never: 'Never',
                        MediaAutoDownload.wifi: 'Wi-Fi',
                        MediaAutoDownload.always: 'Always',
                      },
                      onChanged: (value) =>
                          provider.setMediaAutoDownload(value),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Save to gallery',
                      subtitle: 'Automatically save received media',
                      value: chat.saveToGallery,
                      onChanged: (value) {
                        provider.updateChat(
                          chat.copyWith(saveToGallery: value),
                        );
                      },
                    ),
                  ],
                ),

                // Appearance
                const SettingsSectionHeader(
                  title: 'Appearance',
                  icon: Icons.palette_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsChoiceChips<BubbleStyle>(
                      title: 'Message bubbles',
                      subtitle: 'Choose your preferred bubble style',
                      value: chat.bubbleStyle,
                      choices: const [
                        SettingsChoice(
                          value: BubbleStyle.defaultStyle,
                          label: 'Default',
                        ),
                        SettingsChoice(
                          value: BubbleStyle.minimal,
                          label: 'Minimal',
                        ),
                        SettingsChoice(
                          value: BubbleStyle.classic,
                          label: 'Classic',
                        ),
                        SettingsChoice(
                          value: BubbleStyle.modern,
                          label: 'Modern',
                        ),
                      ],
                      onChanged: (value) {
                        provider.updateChat(chat.copyWith(bubbleStyle: value));
                      },
                    ),
                    SettingsTile(
                      icon: Icons.wallpaper_outlined,
                      title: 'Chat wallpaper',
                      subtitle: chat.chatWallpaper ?? 'Default',
                      onTap: () => _showWallpaperPicker(context, provider),
                    ),
                    SettingsDropdownTile<String>(
                      icon: Icons.format_size_outlined,
                      title: 'Font size',
                      value: chat.fontSize,
                      items: const [
                        DropdownMenuItem(value: 'small', child: Text('Small')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'large', child: Text('Large')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateChat(chat.copyWith(fontSize: value));
                        }
                      },
                    ),
                  ],
                ),

                // Privacy
                const SettingsSectionHeader(
                  title: 'Chat Privacy',
                  icon: Icons.lock_outline,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.done_all_outlined,
                      title: 'Read receipts',
                      subtitle: 'Show when you have read messages',
                      value: provider.privacy.showReadReceipts,
                      onChanged: (value) => provider.updatePrivacy(
                        provider.privacy.copyWith(showReadReceipts: value),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.online_prediction_outlined,
                      title: 'Last seen & online',
                      subtitle: 'Show your current activity status',
                      value: provider.privacy.showLastSeen,
                      onChanged: (value) => provider.updatePrivacy(
                        provider.privacy.copyWith(
                          showLastSeen: value,
                          showOnlineStatus: value,
                        ),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.text_fields_outlined,
                      title: 'Typing indicator',
                      subtitle: 'Show when you are typing',
                      value: provider.privacy.showTypingIndicator,
                      onChanged: (value) => provider.updatePrivacy(
                        provider.privacy.copyWith(showTypingIndicator: value),
                      ),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Profile Availability',
                  icon: Icons.account_circle_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Open to Chat',
                      subtitle: 'Allow others to start new chats with you',
                      value: (provider.chat.openToChat),
                      onChanged: (value) {
                        provider.updateChat(
                          provider.chat.copyWith(openToChat: value),
                        );
                      },
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Community Promotion',
                  icon: Icons.campaign_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.star_outline,
                      title: 'Promoted Community',
                      subtitle: provider.social.promotedCommunityId != null
                          ? 'Community ID: ${provider.social.promotedCommunityId}'
                          : 'Select a community to feature on your profile',
                      onTap: () {
                        CommunityPicker.show(
                          context,
                          initialValue: provider.social.promotedCommunityId,
                          onSelected: (communityId) {
                            provider.updateSocialSettings(
                              provider.social.copyWith(
                                promotedCommunityId: communityId,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (provider.social.createdCommunityId != null)
                      SettingsTile(
                        icon: Icons.create_new_folder_outlined,
                        title: 'Your Community',
                        subtitle: 'Manage the community you created',
                        onTap: () {
                          context.pushNamed(
                            'communityPreviewScreen',
                            pathParameters: {
                              'communityId':
                                  provider.social.createdCommunityId!,
                            },
                          );
                        },
                      ),
                  ],
                ),

                // Notifications
                const SettingsSectionHeader(
                  title: 'Chat Notifications',
                  icon: Icons.notifications_active_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Enable Chat Notifications',
                      subtitle: 'Master toggle for all chat-related alerts',
                      value: provider.notifications.channels.chat.enabled,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              chat: provider.notifications.channels.chat
                                  .copyWith(enabled: value),
                            ),
                          ),
                        );
                      },
                    ),
                    if (provider.notifications.channels.chat.enabled) ...[
                      SettingsSwitchTile(
                        icon: Icons.person_outline,
                        title: 'Direct messages',
                        value: provider.notifications.channels.chat.messages,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels
                                  .copyWith(
                                    chat: provider.notifications.channels.chat
                                        .copyWith(messages: value),
                                  ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.groups_outlined,
                        title: 'Group messages',
                        value:
                            provider.notifications.channels.chat.groupMessages,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels
                                  .copyWith(
                                    chat: provider.notifications.channels.chat
                                        .copyWith(groupMessages: value),
                                  ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.alternate_email_outlined,
                        title: 'Mentions',
                        value: provider.notifications.channels.chat.mentions,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels
                                  .copyWith(
                                    chat: provider.notifications.channels.chat
                                        .copyWith(mentions: value),
                                  ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.add_reaction_outlined,
                        title: 'Reactions',
                        value: provider.notifications.channels.chat.reactions,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels
                                  .copyWith(
                                    chat: provider.notifications.channels.chat
                                        .copyWith(reactions: value),
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),

                // Backup
                const SettingsSectionHeader(
                  title: 'Backup',
                  icon: Icons.backup_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.cloud_upload_outlined,
                      title: 'Chat backup',
                      subtitle: 'Automatically backup your chats',
                      value: chat.chatBackup.enabled,
                      onChanged: (value) {
                        provider.updateChat(
                          chat.copyWith(
                            chatBackup: chat.chatBackup.copyWith(
                              enabled: value,
                            ),
                          ),
                        );
                      },
                    ),
                    if (chat.chatBackup.enabled) ...[
                      SettingsDropdownTile<String>(
                        icon: Icons.schedule_outlined,
                        title: 'Backup frequency',
                        value: chat.chatBackup.frequency,
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateChat(
                              chat.copyWith(
                                chatBackup: chat.chatBackup.copyWith(
                                  frequency: value,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.photo_outlined,
                        title: 'Include media',
                        subtitle: 'Backup photos and videos',
                        value: chat.chatBackup.includeMedia,
                        onChanged: (value) {
                          provider.updateChat(
                            chat.copyWith(
                              chatBackup: chat.chatBackup.copyWith(
                                includeMedia: value,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    SettingsTile(
                      icon: Icons.backup_table_outlined,
                      title: 'Backup now',
                      subtitle: 'Manually backup your chats',
                      showChevron: false,
                      onTap: () => _performBackup(context),
                    ),
                  ],
                ),

                // Swipe Actions
                const SettingsSectionHeader(
                  title: 'Swipe Actions',
                  icon: Icons.swipe,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<SwipeAction>(
                      icon: Icons.swipe_left,
                      title: 'Swipe left',
                      value: chat.swipeActions.left,
                      items: const [
                        DropdownMenuItem(
                          value: SwipeAction.reply,
                          child: Text('Reply'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.archive,
                          child: Text('Archive'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.delete,
                          child: Text('Delete'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.pin,
                          child: Text('Pin'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.mute,
                          child: Text('Mute'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateChat(
                            chat.copyWith(
                              swipeActions: chat.swipeActions.copyWith(
                                left: value,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    SettingsDropdownTile<SwipeAction>(
                      icon: Icons.swipe_right,
                      title: 'Swipe right',
                      value: chat.swipeActions.right,
                      items: const [
                        DropdownMenuItem(
                          value: SwipeAction.reply,
                          child: Text('Reply'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.archive,
                          child: Text('Archive'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.delete,
                          child: Text('Delete'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.pin,
                          child: Text('Pin'),
                        ),
                        DropdownMenuItem(
                          value: SwipeAction.mute,
                          child: Text('Mute'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateChat(
                            chat.copyWith(
                              swipeActions: chat.swipeActions.copyWith(
                                right: value,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                // Advanced
                const SettingsSectionHeader(
                  title: 'Advanced',
                  icon: Icons.settings_applications_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSliderTile(
                      icon: Icons.timer_off_outlined,
                      title: 'Default disappearing messages',
                      subtitle: 'Auto-delete messages after',
                      value: (chat.defaultDisappearing ?? 0).toDouble(),
                      min: 0,
                      max: 90,
                      divisions: 6,
                      valueLabel:
                          chat.defaultDisappearing == null ||
                              chat.defaultDisappearing == 0
                          ? 'Off'
                          : '${chat.defaultDisappearing} days',
                      onChanged: (value) {
                        provider.updateChat(
                          chat.copyWith(
                            defaultDisappearing: value == 0
                                ? null
                                : value.toInt(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Storage
                const SettingsSectionHeader(
                  title: 'Storage',
                  icon: Icons.storage_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Clear chat cache',
                      subtitle: 'Free up storage space',
                      showChevron: false,
                      onTap: () => _showClearCacheDialog(context),
                    ),
                    SettingsTile(
                      icon: Icons.delete_outline,
                      title: 'Delete all chats',
                      subtitle: 'Permanently delete all messages',
                      iconColor: Colors.red,
                      isDestructive: true,
                      showChevron: false,
                      onTap: () => _showDeleteAllChatsDialog(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showWallpaperPicker(BuildContext context, SettingsProvider provider) {
    final wallpapers = [
      'Default',
      'Gradient Blue',
      'Gradient Purple',
      'Gradient Green',
      'Gradient Orange',
      'Pattern 1',
      'Pattern 2',
      'Solid Color',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Wallpaper',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: wallpapers.map((wallpaper) {
                return GestureDetector(
                  onTap: () {
                    provider.updateChat(
                      provider.chat.copyWith(
                        chatWallpaper: wallpaper == 'Default'
                            ? null
                            : wallpaper,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _getWallpaperColor(wallpaper),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.chat.chatWallpaper == wallpaper
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        wallpaper.split(' ').last,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getWallpaperColor(String wallpaper) {
    switch (wallpaper) {
      case 'Gradient Blue':
        return Colors.blue;
      case 'Gradient Purple':
        return Colors.purple;
      case 'Gradient Green':
        return Colors.green;
      case 'Gradient Orange':
        return Colors.orange;
      case 'Pattern 1':
        return Colors.grey;
      case 'Pattern 2':
        return Colors.blueGrey;
      case 'Solid Color':
        return Colors.indigo;
      default:
        return Colors.grey.shade300;
    }
  }

  void _performBackup(BuildContext context) {
    AppSnackbar.info(title: 'Backup', message: 'Starting backup...');
    // TODO: Implement backup logic
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will delete temporary files and free up storage space. Your messages will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Clear cache
              AppSnackbar.success('Cache cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllChatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Delete All Chats?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your chats and cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete all chats
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

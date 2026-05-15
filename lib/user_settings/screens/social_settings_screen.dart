// lib/features/social/screens/social_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/community_picker.dart';
import 'package:go_router/go_router.dart';

class SocialSettingsScreen extends StatelessWidget {
  const SocialSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Social Settings'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final social = provider.social;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SettingsSectionHeader(
                  title: 'Visibility & Profile',
                  icon: Icons.public_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<ProfileVisibility>(
                      icon: Icons.visibility_outlined,
                      title: 'Default Post Visibility',
                      value: social.defaultPostVisibility,
                      items: const [
                        DropdownMenuItem(
                          value: ProfileVisibility.public,
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: ProfileVisibility.friendsOnly,
                          child: Text('Friends Only'),
                        ),
                        DropdownMenuItem(
                          value: ProfileVisibility.private,
                          child: Text('Private'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          provider.updateSocialSettings(
                            social.copyWith(defaultPostVisibility: value),
                          );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Auto-share Achievements',
                      value: social.autoShareAchievements,
                      onChanged: (value) => provider.updateSocialSettings(
                        social.copyWith(autoShareAchievements: value),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.history_outlined,
                      title: 'Show Activity on Profile',
                      value: social.showActivityOnProfile,
                      onChanged: (value) => provider.updateSocialSettings(
                        social.copyWith(showActivityOnProfile: value),
                      ),
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
                      subtitle: social.promotedCommunityId != null
                          ? 'Community ID: ${social.promotedCommunityId}'
                          : 'Select a community to feature on your profile',
                      onTap: () {
                        CommunityPicker.show(
                          context,
                          initialValue: social.promotedCommunityId,
                          onSelected: (communityId) {
                            provider.updateSocialSettings(
                              social.copyWith(
                                promotedCommunityId: communityId,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (social.createdCommunityId != null)
                      SettingsTile(
                        icon: Icons.create_new_folder_outlined,
                        title: 'Your Community',
                        subtitle: 'Manage the community you created',
                        onTap: () {
                          context.pushNamed(
                            'communityPreviewScreen',
                            pathParameters: {'communityId': social.createdCommunityId!},
                          );
                        },
                      ),
                  ],
                ),

                const SettingsSectionHeader(title: 'Feed Preferences', icon: Icons.dynamic_feed_outlined),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<FeedShowFrom>(
                      icon: Icons.filter_alt_outlined,
                      title: 'Show Feed From',
                      value: social.feedPreferences.showFrom,
                      items: const [
                        DropdownMenuItem(value: FeedShowFrom.all, child: Text('Everyone')),
                        DropdownMenuItem(value: FeedShowFrom.following, child: Text('Following')),
                        DropdownMenuItem(value: FeedShowFrom.friends, child: Text('Friends Only')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateSocialSettings(
                            social.copyWith(feedPreferences: social.feedPreferences.copyWith(showFrom: value)),
                          );
                        }
                      },
                    ),
                    SettingsDropdownTile<FeedSortBy>(
                      icon: Icons.sort_outlined,
                      title: 'Sort Feed By',
                      value: social.feedPreferences.sortBy,
                      items: const [
                        DropdownMenuItem(value: FeedSortBy.recent, child: Text('Most Recent')),
                        DropdownMenuItem(value: FeedSortBy.popular, child: Text('Most Popular')),
                        DropdownMenuItem(value: FeedSortBy.relevant, child: Text('Most Relevant')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateSocialSettings(
                            social.copyWith(feedPreferences: social.feedPreferences.copyWith(sortBy: value)),
                          );
                        }
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.article_outlined,
                      title: 'Show Posts',
                      value: social.feedPreferences.contentTypes.contains('posts'),
                      onChanged: (value) {
                        final types = List<String>.from(social.feedPreferences.contentTypes);
                        if (value && !types.contains('posts')) types.add('posts');
                        if (!value) types.remove('posts');
                        provider.updateSocialSettings(
                          social.copyWith(feedPreferences: social.feedPreferences.copyWith(contentTypes: types)),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Show Achievements',
                      value: social.feedPreferences.contentTypes.contains('achievements'),
                      onChanged: (value) {
                        final types = List<String>.from(social.feedPreferences.contentTypes);
                        if (value && !types.contains('achievements')) types.add('achievements');
                        if (!value) types.remove('achievements');
                        provider.updateSocialSettings(
                          social.copyWith(feedPreferences: social.feedPreferences.copyWith(contentTypes: types)),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.flag_outlined,
                      title: 'Show Goals',
                      value: social.feedPreferences.contentTypes.contains('goals'),
                      onChanged: (value) {
                        final types = List<String>.from(social.feedPreferences.contentTypes);
                        if (value && !types.contains('goals')) types.add('goals');
                        if (!value) types.remove('goals');
                        provider.updateSocialSettings(
                          social.copyWith(feedPreferences: social.feedPreferences.copyWith(contentTypes: types)),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.format_list_bulleted_outlined,
                      title: 'Show Bucket Lists',
                      value: social.feedPreferences.contentTypes.contains('buckets'),
                      onChanged: (value) {
                        final types = List<String>.from(social.feedPreferences.contentTypes);
                        if (value && !types.contains('buckets')) types.add('buckets');
                        if (!value) types.remove('buckets');
                        provider.updateSocialSettings(
                          social.copyWith(feedPreferences: social.feedPreferences.copyWith(contentTypes: types)),
                        );
                      },
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Media & Data',
                  icon: Icons.perm_media_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<MediaAutoDownload>(
                      icon: Icons.smart_display_outlined,
                      title: 'Auto-play Videos',
                      value: social.autoPlayVideos,
                      items: const [
                        DropdownMenuItem(
                          value: MediaAutoDownload.always,
                          child: Text('Always'),
                        ),
                        DropdownMenuItem(
                          value: MediaAutoDownload.wifi,
                          child: Text('Wi-Fi Only'),
                        ),
                        DropdownMenuItem(
                          value: MediaAutoDownload.never,
                          child: Text('Never'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          provider.updateSocialSettings(
                            social.copyWith(autoPlayVideos: value),
                          );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.data_usage_outlined,
                      title: 'Reduce Data Usage',
                      value: social.reduceDataUsage,
                      onChanged: (value) => provider.updateSocialSettings(
                        social.copyWith(reduceDataUsage: value),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.remove_red_eye_outlined,
                      title: 'Hide Seen Posts',
                      value: social.hideSeenPosts,
                      onChanged: (value) => provider.updateSocialSettings(
                        social.copyWith(hideSeenPosts: value),
                      ),
                    ),
                  ],
                ),

                const SettingsSectionHeader(
                  title: 'Social Notifications',
                  icon: Icons.notifications_active_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Enable Social Notifications',
                      subtitle: 'Master toggle for all social interactions',
                      value: provider.notifications.channels.social.enabled,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              social: provider.notifications.channels.social.copyWith(enabled: value),
                            ),
                          ),
                        );
                      },
                    ),
                    if (provider.notifications.channels.social.enabled) ...[
                      SettingsSwitchTile(
                        icon: Icons.favorite_border,
                        title: 'Likes',
                        subtitle: 'When someone likes your post',
                        value: provider.notifications.channels.social.likes,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels.copyWith(
                                social: provider.notifications.channels.social.copyWith(
                                  likes: value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    SettingsSwitchTile(
                      icon: Icons.comment_outlined,
                      title: 'Comments',
                      subtitle: 'When someone comments on your post',
                      value: provider.notifications.channels.social.comments,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              social: provider.notifications.channels.social.copyWith(
                                comments: value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.person_add_outlined,
                      title: 'Follows',
                      subtitle: 'When someone follows you',
                      value: provider.notifications.channels.social.follows,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              social: provider.notifications.channels.social.copyWith(
                                follows: value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.alternate_email_outlined,
                      title: 'Mentions',
                      subtitle: 'When someone mentions you',
                      value: provider.notifications.channels.social.mentions,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              social: provider.notifications.channels.social.copyWith(
                                mentions: value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.share_outlined,
                      title: 'Shares',
                      subtitle: 'When someone shares your post',
                      value: provider.notifications.channels.social.shares,
                      onChanged: (value) {
                        provider.updateNotifications(
                          provider.notifications.copyWith(
                            channels: provider.notifications.channels.copyWith(
                              social: provider.notifications.channels.social.copyWith(
                                shares: value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),

                const SettingsSectionHeader(
                  title: 'Muted Content',
                  icon: Icons.volume_off_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.do_not_disturb_alt_outlined,
                      title: 'Muted Words',
                      subtitle: '${social.mutedWords.length} words muted',
                      onTap: () {
                        // TODO: Navigate to muted words or show dialog
                      },
                    ),
                    SettingsTile(
                      icon: Icons.person_off_outlined,
                      title: 'Muted Accounts',
                      subtitle: '${social.mutedAccounts.length} accounts muted',
                      onTap: () {
                        // TODO: Navigate to muted accounts or show dialog
                      },
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
}

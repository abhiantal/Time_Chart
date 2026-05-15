// lib/user_settings/screens/analytics_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/analytics/dashboard/providers/user_dashboard_provider.dart';
import '../../features/analytics/dashboard/services/performance_report_service.dart';
import '../../features/analytics/dashboard/models/dashboard_model.dart';
import '../../user_profile/create_edit_profile/profile_provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_snackbar.dart';

class AnalyticsSettingsScreen extends StatefulWidget {
  const AnalyticsSettingsScreen({super.key});

  @override
  State<AnalyticsSettingsScreen> createState() =>
      _AnalyticsSettingsScreenState();
}

class _AnalyticsSettingsScreenState extends State<AnalyticsSettingsScreen> {
  bool _isGeneratingReport = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics & Competition'),
          centerTitle: true,
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, _) {
            final analytics = provider.analytics;
            final competition = provider.competition;
            final mentoring = provider.mentoring;
            final notifications = provider.notifications;
            final analyticsNotify = notifications.channels.analytics;
            final competitionNotify = notifications.channels.competition;
            final mentoringNotify = notifications.channels.mentoring;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // ==========================================
                // INSIGHTS & REPORTS (ANALYTICS)
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Insights & Reports',
                  icon: Icons.analytics_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.summarize_outlined,
                      title: 'Weekly Report',
                      subtitle: 'Get a summary of your week',
                      value: analytics.weeklyReport,
                      onChanged: (val) => provider.updateAnalyticsSettings(
                        analytics.copyWith(weeklyReport: val),
                      ),
                    ),
                    if (analytics.weeklyReport)
                      SettingsDropdownTile<WeekDay>(
                        icon: Icons.calendar_today_outlined,
                        title: 'Report Day',
                        value: analytics.weeklyReportDay,
                        items: WeekDay.values.map((day) {
                          return DropdownMenuItem(
                            value: day,
                            child: Text(_getDayName(day)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.updateAnalyticsSettings(
                              analytics.copyWith(weeklyReportDay: val),
                            );
                          }
                        },
                      ),
                    SettingsSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'Monthly Insights',
                      value: analytics.monthlyInsights,
                      onChanged: (val) => provider.updateAnalyticsSettings(
                        analytics.copyWith(monthlyInsights: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.insights_outlined,
                      title: 'Productivity Tracking',
                      subtitle: 'Detailed breakdown of your efficiency',
                      value: analytics.productivityTracking,
                      onChanged: (val) => provider.updateAnalyticsSettings(
                        analytics.copyWith(productivityTracking: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.psychology_outlined,
                      title: 'Mood Analytics',
                      value: analytics.moodAnalytics,
                      onChanged: (val) => provider.updateAnalyticsSettings(
                        analytics.copyWith(moodAnalytics: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.security_outlined,
                      title: 'Anonymous Data Sharing',
                      subtitle: 'Help us improve by sharing usage data',
                      value: analytics.shareAnonymousData,
                      onChanged: (val) => provider.updateAnalyticsSettings(
                        analytics.copyWith(shareAnonymousData: val),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // PERFORMANCE REPORT DOWNLOAD
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Performance Report',
                  icon: Icons.picture_as_pdf_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsTile(
                      icon: Icons.download_outlined,
                      iconColor: const Color(0xFFD4A843),
                      title: 'Download Performance Report',
                      subtitle: _isGeneratingReport
                          ? 'Generating 7-page certificate PDF…'
                          : 'Full PDF certificate with AI mindset analysis',
                      showChevron: !_isGeneratingReport,
                      trailing: _isGeneratingReport
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                      onTap: _isGeneratingReport
                          ? null
                          : () => _downloadReport(context),
                    ),
                  ],
                ),

                // ==========================================
                // COMPETITION & CHALLENGES
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Competition & Challenges',
                  icon: Icons.emoji_events_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.sports_kabaddi_outlined,
                      title: 'Allow Challenges',
                      subtitle: 'Receive head-to-head requests',
                      value: competition.allowChallenges,
                      onChanged: (val) => provider.updateCompetitionSettings(
                        competition.copyWith(allowChallenges: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.group_add_outlined,
                      title: 'Auto-Accept from Friends',
                      value: competition.autoAcceptFromFriends,
                      onChanged: (val) => provider.updateCompetitionSettings(
                        competition.copyWith(autoAcceptFromFriends: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.leaderboard_outlined,
                      title: 'Show on Leaderboard',
                      value: competition.showOnLeaderboard,
                      onChanged: (val) => provider.updateCompetitionSettings(
                        competition.copyWith(showOnLeaderboard: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.share_outlined,
                      title: 'Share Stats in Community',
                      value: competition.shareStats,
                      onChanged: (val) => provider.updateCompetitionSettings(
                        competition.copyWith(shareStats: val),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // MENTORING & DATA SHARING
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Mentoring & Feedback',
                  icon: Icons.school_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.handshake_outlined,
                      title: 'Enable Mentoring',
                      subtitle: 'Allow sharing data with mentors',
                      value: mentoring.mentoringEnabled,
                      onChanged: (val) => provider.updateMentoringSettings(
                        mentoring.copyWith(mentoringEnabled: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.person_search_outlined,
                      title: 'Public Profile',
                      subtitle: 'Allow others to find and request to mentor you',
                      value: mentoring.isPublic,
                      onChanged: (val) => provider.updateMentoringSettings(
                        mentoring.copyWith(isPublic: val),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.add_moderator_outlined,
                      title: 'Allow Mentoring Requests',
                      value: mentoring.allowMentoringRequests,
                      onChanged: (val) => provider.updateMentoringSettings(
                        mentoring.copyWith(allowMentoringRequests: val),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // ANALYTICS NOTIFICATIONS
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Analytics Notifications',
                  icon: Icons.notifications_paused_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Enable Analytics Alerts',
                      value: analyticsNotify.enabled,
                      onChanged: (val) => provider.updateNotifications(
                        notifications.copyWith(
                          channels: notifications.channels.copyWith(
                            analytics: analyticsNotify.copyWith(enabled: val),
                          ),
                        ),
                      ),
                    ),
                    if (analyticsNotify.enabled) ...[
                      SettingsSwitchTile(
                        icon: Icons.description_outlined,
                        title: 'Weekly Report Ready',
                        value: analyticsNotify.weeklyReports,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              analytics: analyticsNotify.copyWith(weeklyReports: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.trending_up,
                        title: 'Trend Alerts',
                        value: analyticsNotify.trendAlerts,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              analytics: analyticsNotify.copyWith(trendAlerts: val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ==========================================
                // COMPETITION NOTIFICATIONS
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Competition Notifications',
                  icon: Icons.military_tech_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Enable Competition Alerts',
                      value: competitionNotify.enabled,
                      onChanged: (val) => provider.updateNotifications(
                        notifications.copyWith(
                          channels: notifications.channels.copyWith(
                            competition: competitionNotify.copyWith(enabled: val),
                          ),
                        ),
                      ),
                    ),
                    if (competitionNotify.enabled) ...[
                      SettingsSwitchTile(
                        icon: Icons.person_add_alt_outlined,
                        title: 'New Challenges',
                        value: competitionNotify.challengeReceived,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              competition: competitionNotify.copyWith(challengeReceived: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.trending_up_outlined,
                        title: 'Rank Changes',
                        value: competitionNotify.rankChanges,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              competition: competitionNotify.copyWith(rankChanges: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Milestones Reached',
                        value: competitionNotify.milestoneReached,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              competition: competitionNotify.copyWith(milestoneReached: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.card_membership_outlined,
                        title: 'Tournament Invites',
                        value: competitionNotify.tournamentInvites,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              competition: competitionNotify.copyWith(tournamentInvites: val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ==========================================
                // MENTORING NOTIFICATIONS
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Mentoring Notifications',
                  icon: Icons.notifications_on_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Enable Mentoring Alerts',
                      value: mentoringNotify.enabled,
                      onChanged: (val) => provider.updateNotifications(
                        notifications.copyWith(
                          channels: notifications.channels.copyWith(
                            mentoring: mentoringNotify.copyWith(enabled: val),
                          ),
                        ),
                      ),
                    ),
                    if (mentoringNotify.enabled) ...[
                      SettingsSwitchTile(
                        icon: Icons.person_add_outlined,
                        title: 'Requests & Invites',
                        value: mentoringNotify.requests,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              mentoring: mentoringNotify.copyWith(requests: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.event_note_outlined,
                        title: 'Session Reminders',
                        value: mentoringNotify.sessions,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              mentoring: mentoringNotify.copyWith(sessions: val),
                            ),
                          ),
                        ),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.rate_review_outlined,
                        title: 'Mentorship Feedback',
                        value: mentoringNotify.feedback,
                        onChanged: (val) => provider.updateNotifications(
                          notifications.copyWith(
                            channels: notifications.channels.copyWith(
                              mentoring: mentoringNotify.copyWith(feedback: val),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getDayName(WeekDay day) {
    return day.name[0].toUpperCase() + day.name.substring(1);
  }

  // ── Performance Report Download ──────────────────────────────

  Future<void> _downloadReport(BuildContext context) async {
    setState(() => _isGeneratingReport = true);

    try {
      // Get dashboard data from the provider
      final dashProvider = context.read<UserDashboardProvider>();
      final profileProvider = context.read<ProfileProvider>();

      var dashboard = dashProvider.userDashboard;
      if (dashboard == null) {
        final userId = (profileProvider.currentUserId != null && profileProvider.currentUserId!.isNotEmpty)
            ? profileProvider.currentUserId
            : SupabaseService.instance.currentUserId;
        if (userId != null && userId.isNotEmpty) {
          AppSnackbar.loading(title: 'Loading dashboard metrics...');
          await dashProvider.initialize(userId);
          dashboard = dashProvider.userDashboard;
          AppSnackbar.hideLoading();
        }
      }

      if (dashboard == null) {
        final userId = (profileProvider.currentUserId != null && profileProvider.currentUserId!.isNotEmpty)
            ? profileProvider.currentUserId!
            : SupabaseService.instance.currentUserId ?? 'empty';
        dashboard = UserDashboard.empty(userId);
      }

      // Get user name from profile, fall back to auth metadata
      final userName = profileProvider.displayName.isNotEmpty
          ? profileProvider.displayName
          : profileProvider.authDisplayName.isNotEmpty
              ? profileProvider.authDisplayName
              : 'User';

      AppSnackbar.loading(title: 'Generating report PDF...');

      // Generate and share the PDF
      await PerformanceReportService.share(
        dashboard: dashboard,
        userName: userName,
      );

      AppSnackbar.hideLoading();
      AppSnackbar.success('Report generated successfully!');
    } catch (e) {
      AppSnackbar.hideLoading();
      AppSnackbar.error(
        'Generation Failed',
        description: 'Failed to generate report: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }
}

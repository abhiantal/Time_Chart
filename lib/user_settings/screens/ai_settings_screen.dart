// lib/features/settings/screen/ai_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../../ai_services/constants/ai_constants.dart';
import '../../ai_services/services/token_manager_service.dart';

class AiSettingsScreen extends StatelessWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('AI Assistant'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final ai = provider.ai;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // AI Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.15),
                        Colors.blue.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Assistant',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ai.enabled
                                  ? 'Powered by advanced AI'
                                  : 'Currently disabled',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: ai.enabled,
                        onChanged: (_) => provider.toggleAI(),
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                ),

                if (ai.enabled) ...[
                  // Suggestions
                  const SettingsSectionHeader(
                    title: 'Suggestions',
                    icon: Icons.lightbulb_outline,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.auto_fix_high_outlined,
                        title: 'Auto suggestions',
                        subtitle: 'Get proactive suggestions as you work',
                        value: ai.autoSuggestions,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(autoSuggestions: value),
                          );
                        },
                      ),
                      if (ai.autoSuggestions)
                        SettingsChoiceChips<SuggestionFrequency>(
                          title: 'Suggestion frequency',
                          value: ai.suggestionFrequency,
                          choices: const [
                            SettingsChoice(
                              value: SuggestionFrequency.minimal,
                              label: 'Minimal',
                              icon: Icons.remove,
                            ),
                            SettingsChoice(
                              value: SuggestionFrequency.moderate,
                              label: 'Moderate',
                              icon: Icons.horizontal_rule,
                            ),
                            SettingsChoice(
                              value: SuggestionFrequency.frequent,
                              label: 'Frequent',
                              icon: Icons.add,
                            ),
                          ],
                          onChanged: (value) {
                            provider.updateAI(
                              ai.copyWith(suggestionFrequency: value),
                            );
                          },
                        ),
                    ],
                  ),

                  // Model & Provider
                  const SettingsSectionHeader(
                    title: 'Model & Provider',
                    icon: Icons.hub_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsDropdownTile<String>(
                        icon: Icons.psychology_outlined,
                        title: 'Preferred AI Provider',
                        subtitle: 'Override the default system provider',
                        value: ai.preferredModel,
                        items: [
                          const DropdownMenuItem(
                            value: 'default',
                            child: Text('System Default (Auto)'),
                          ),
                          ...AIProvider.values.map(
                            (p) => DropdownMenuItem(
                              value: p.name,
                              child: Text(
                                p.name[0].toUpperCase() + p.name.substring(1),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateAI(ai.copyWith(preferredModel: value));
                          }
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.sync_problem_outlined,
                        title: 'Auto fallback',
                        subtitle: 'Switch providers if primary is busy',
                        value: ai.autoFallback,
                        onChanged: (value) {
                          provider.updateAI(ai.copyWith(autoFallback: value));
                        },
                      ),
                      SettingsSliderTile(
                        icon: Icons.history_edu_outlined,
                        title: 'Context depth',
                        subtitle: 'Number of past messages AI remembers',
                        value: ai.contextDepth.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        valueLabel: ai.contextDepth.toString(),
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(contextDepth: value.round()),
                          );
                        },
                      ),
                    ],
                  ),

                  // Response Style
                  const SettingsSectionHeader(
                    title: 'Response Style',
                    icon: Icons.format_quote_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSegmentedControl<ResponseStyle>(
                        title: 'How should AI respond?',
                        value: ai.responseStyle,
                        segments: const {
                          ResponseStyle.concise: 'Concise',
                          ResponseStyle.balanced: 'Balanced',
                          ResponseStyle.detailed: 'Detailed',
                        },
                        onChanged: (value) {
                          provider.updateAI(ai.copyWith(responseStyle: value));
                        },
                      ),
                    ],
                  ),

                  // AI Features
                  const SettingsSectionHeader(
                    title: 'AI Features',
                    icon: Icons.extension_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.task_outlined,
                        title: 'Task suggestions',
                        subtitle: 'Get smart task recommendations',
                        value: ai.useFor.taskSuggestions,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(
                                taskSuggestions: value,
                              ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.flag_outlined,
                        title: 'Goal planning',
                        subtitle: 'AI-assisted goal breakdown',
                        value: ai.useFor.goalPlanning,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(goalPlanning: value),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.book_outlined,
                        title: 'Diary prompts',
                        subtitle: 'Creative writing prompts',
                        value: ai.useFor.diaryPrompts,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(diaryPrompts: value),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.insights_outlined,
                        title: 'Productivity insights',
                        subtitle: 'Analysis of your productivity patterns',
                        value: ai.useFor.productivityInsights,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(
                                productivityInsights: value,
                              ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.edit_outlined,
                        title: 'Writing assistance',
                        subtitle: 'Help with writing and editing',
                        value: ai.useFor.writingAssistance,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(
                                writingAssistance: value,
                              ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Media verification',
                        subtitle: 'AI verification of task completion',
                        value: ai.useFor.mediaVerification,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              useFor: ai.useFor.copyWith(
                                mediaVerification: value,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Notifications
                  const SettingsSectionHeader(
                    title: 'AI Notifications',
                    icon: Icons.notifications_active_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Assistant Alerts',
                        subtitle: 'Suggestions, insights & model updates',
                        value: provider.notifications.channels.ai.enabled,
                        onChanged: (value) {
                          provider.updateNotifications(
                            provider.notifications.copyWith(
                              channels: provider.notifications.channels.copyWith(
                                ai: provider.notifications.channels.ai.copyWith(
                                  enabled: value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Data & Learning
                  const SettingsSectionHeader(
                    title: 'Data & Learning',
                    icon: Icons.school_outlined,
                  ),
                  SettingsCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.history_outlined,
                        title: 'Learn from history',
                        subtitle: 'Improve suggestions based on your usage',
                        value: ai.dataUsage.learnFromHistory,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              dataUsage: ai.dataUsage.copyWith(
                                learnFromHistory: value,
                              ),
                            ),
                          );
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.person_search_outlined,
                        title: 'Personalized suggestions',
                        subtitle: 'Tailored recommendations for you',
                        value: ai.dataUsage.personalizedSuggestions,
                        onChanged: (value) {
                          provider.updateAI(
                            ai.copyWith(
                              dataUsage: ai.dataUsage.copyWith(
                                personalizedSuggestions: value,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Usage Stats
                  const SettingsSectionHeader(
                    title: 'Token Usage',
                    icon: Icons.bar_chart_outlined,
                  ),
                  SettingsCard(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: TokenManagerService().getUsageStats(
                          provider.settings?.userId ?? '',
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final stats = snapshot.data!;
                          final used = stats['tokensUsed'] as int;
                          final limit = stats['tokenLimit'] as int;
                          final percentage = stats['percentage'] as double;
                          final hoursLeft = stats['hoursUntilReset'] as int;

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Daily Token Quota',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${(percentage).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: percentage > 80
                                            ? Colors.red
                                            : Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: used / limit,
                                    backgroundColor:
                                        Colors.purple.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation(
                                      percentage > 80
                                          ? Colors.red
                                          : Colors.purple,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$used / $limit tokens',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Resets in $hoursLeft hours',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (ai.showUsageStats) ...[
                                  const Divider(height: 32),
                                  SettingsTile(
                                    icon: Icons.history_outlined,
                                    title: 'Detailed History',
                                    subtitle: 'View recent AI interactions',
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () {
                                      // Navigate to history
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  // Disabled state info
                  SettingsInfoBanner(
                    icon: Icons.info_outline,
                    title: 'AI Assistant is disabled',
                    message: 'This feature requires AI to be enabled in your plan.',
                    color: Colors.purple,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

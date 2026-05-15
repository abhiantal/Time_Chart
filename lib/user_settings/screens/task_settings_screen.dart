// lib/features/settings/screen/task_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class TaskSettingsScreen extends StatelessWidget {
  const TaskSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Personal & Task Settings'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final tasks = provider.tasks;
            final goals = provider.goals;
            final bucket = provider.bucketList;
            final diary = provider.diary;
            final notifications = provider.notifications;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // ==========================================
                // TASKS SECTION
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Task Management',
                  icon: Icons.task_alt_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<TaskView>(
                      icon: Icons.grid_view_outlined,
                      title: 'Default View',
                      value: tasks.defaultView,
                      items: const [
                        DropdownMenuItem(value: TaskView.list, child: Text('List')),
                        DropdownMenuItem(value: TaskView.grid, child: Text('Grid')),
                        DropdownMenuItem(value: TaskView.kanban, child: Text('Kanban')),
                        DropdownMenuItem(value: TaskView.calendar, child: Text('Calendar')),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setDefaultTaskView(value);
                      },
                    ),
                    SettingsChoiceChips<Priority>(
                      title: 'Default Priority',
                      subtitle: 'Priority for new tasks',
                      value: tasks.defaultPriority,
                      choices: const [
                        SettingsChoice(value: Priority.low, label: 'Low', icon: Icons.arrow_downward),
                        SettingsChoice(value: Priority.medium, label: 'Medium', icon: Icons.remove),
                        SettingsChoice(value: Priority.high, label: 'High', icon: Icons.arrow_upward),
                        SettingsChoice(value: Priority.urgent, label: 'Urgent', icon: Icons.priority_high),
                      ],
                      onChanged: (value) => provider.setDefaultPriority(value),
                    ),
                    SettingsSliderTile(
                      icon: Icons.alarm_on_outlined,
                      title: 'Default Reminder',
                      subtitle: 'Minutes before due time',
                      value: tasks.defaultReminder.toDouble(),
                      min: 0,
                      max: 120,
                      divisions: 12,
                      valueLabel: '${tasks.defaultReminder} min',
                      onChanged: (value) => provider.updateTasks(tasks.copyWith(defaultReminder: value.toInt())),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.check_circle_outline,
                      title: 'Show Completed',
                      value: tasks.showCompleted,
                      onChanged: (value) => provider.updateTasks(tasks.copyWith(showCompleted: value)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.auto_mode_outlined,
                      title: 'Rollover Incomplete',
                      subtitle: 'Move unfinished tasks to next day',
                      value: tasks.rolloverIncomplete,
                      onChanged: (_) => provider.toggleRolloverTasks(),
                    ),
                  ],
                ),

                // ==========================================
                // GOALS SECTION
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Goals & Ambitions',
                  icon: Icons.flag_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<GoalView>(
                      icon: Icons.view_headline_outlined,
                      title: 'Default View',
                      value: goals.defaultView,
                      items: const [
                        DropdownMenuItem(value: GoalView.grid, child: Text('Grid')),
                        DropdownMenuItem(value: GoalView.list, child: Text('List')),
                        DropdownMenuItem(value: GoalView.timeline, child: Text('Timeline')),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.updateGoals(goals.copyWith(defaultView: value));
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.auto_fix_high_outlined,
                      title: 'AI Suggestions',
                      subtitle: 'Get AI-powered goal recommendations',
                      value: goals.aiSuggestions,
                      onChanged: (value) => provider.updateGoals(goals.copyWith(aiSuggestions: value)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.trending_up,
                      title: 'Show Streaks',
                      subtitle: 'Display consecutive days of progress',
                      value: goals.showStreak,
                      onChanged: (value) => provider.updateGoals(goals.copyWith(showStreak: value)),
                    ),
                    SettingsTile(
                      icon: Icons.rate_review_outlined,
                      title: 'Weekly Review',
                      subtitle: '${_getDayName(goals.weeklyReviewDay)} at ${goals.weeklyReviewTime}',
                      onTap: () => _updateWeeklyReview(context, provider),
                    ),
                  ],
                ),

                // ==========================================
                // BUCKET LIST SECTION
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Bucket List',
                  icon: Icons.shopping_bag_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.attach_money_outlined,
                      title: 'Show Cost Estimates',
                      value: bucket.showCostEstimates,
                      onChanged: (value) => provider.updateBucketListSettings(bucket.copyWith(showCostEstimates: value)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'Inspiration Feed',
                      subtitle: 'Discover popular items from others',
                      value: bucket.inspirationFeed,
                      onChanged: (value) => provider.updateBucketListSettings(bucket.copyWith(inspirationFeed: value)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location Suggestions',
                      value: bucket.locationSuggestions,
                      onChanged: (value) => provider.updateBucketListSettings(bucket.copyWith(locationSuggestions: value)),
                    ),
                  ],
                ),

                // ==========================================
                // DIARY SECTION
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Personal Diary',
                  icon: Icons.book_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.edit_notifications_outlined,
                      title: 'Daily Prompt',
                      subtitle: 'Receive a fresh writing prompt daily',
                      value: diary.dailyPrompt,
                      onChanged: (value) => provider.updateDiary(diary.copyWith(dailyPrompt: value)),
                    ),
                    if (diary.dailyPrompt)
                      SettingsTile(
                        icon: Icons.schedule_outlined,
                        title: 'Prompt Time',
                        subtitle: diary.promptTime,
                        onTap: () => _updateDiaryPromptTime(context, provider),
                      ),
                    SettingsSwitchTile(
                      icon: Icons.save_outlined,
                      title: 'Auto-save',
                      value: diary.autoSave,
                      onChanged: (value) => provider.updateDiary(diary.copyWith(autoSave: value)),
                    ),
                    if (diary.autoSave)
                      SettingsSliderTile(
                        icon: Icons.timer_outlined,
                        title: 'Save Interval',
                        subtitle: 'Seconds between saves',
                        value: diary.autoSaveInterval.toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        valueLabel: '${diary.autoSaveInterval}s',
                        onChanged: (value) => provider.updateDiary(diary.copyWith(autoSaveInterval: value.toInt())),
                      ),
                    SettingsSwitchTile(
                      icon: Icons.cloud_outlined,
                      title: 'Show Weather & Location',
                      value: diary.showWeather && diary.showLocation,
                      onChanged: (value) => provider.updateDiary(diary.copyWith(showWeather: value, showLocation: value)),
                    ),
                  ],
                ),

                // ==========================================
                // NOTIFICATION CHANNELS
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Notification Settings',
                  icon: Icons.notifications_active_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'All Task Notifications',
                      subtitle: 'Enable/disable all reminders and task alerts',
                      value: notifications.channels.tasks.enabled,
                      onChanged: (val) => provider.updateNotifications(notifications.copyWith(
                        channels: notifications.channels.copyWith(
                          tasks: notifications.channels.tasks.copyWith(enabled: val),
                        ),
                      )),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Goal Notifications',
                      subtitle: 'Milestones & progress updates',
                      value: notifications.channels.goals.enabled,
                      onChanged: (val) => provider.updateNotifications(notifications.copyWith(
                        channels: notifications.channels.copyWith(
                          goals: notifications.channels.goals.copyWith(enabled: val),
                        ),
                      )),
                    ),
                    _buildNotificationCategory(
                      context,
                      'Diary Notifications',
                      Icons.history_edu_outlined,
                      notifications.channels.diary.enabled,
                      (val) => provider.updateNotifications(notifications.copyWith(
                        channels: notifications.channels.copyWith(
                          diary: notifications.channels.diary.copyWith(enabled: val),
                        ),
                      )),
                    ),
                  ],
                ),

                // ==========================================
                // CALENDAR & WORKING HOURS
                // ==========================================
                const SettingsSectionHeader(
                  title: 'Schedule & Workspace',
                  icon: Icons.calendar_month_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<WeekDay>(
                      icon: Icons.today_outlined,
                      title: 'Week Starts On',
                      value: tasks.weekStartsOn,
                      items: WeekDay.values.map((day) => DropdownMenuItem(value: day, child: Text(_getDayName(day)))).toList(),
                      onChanged: (value) => value != null ? provider.setWeekStartDay(value) : null,
                    ),
                    SettingsTile(
                      icon: Icons.work_outline,
                      title: 'Working Days',
                      subtitle: '${tasks.workingDays.length} days selected',
                      onTap: () => _showWorkingDaysDialog(context, provider),
                    ),
                    SettingsTile(
                      icon: Icons.access_time_outlined,
                      title: 'Working Hours',
                      subtitle: '${tasks.workingHours.start} - ${tasks.workingHours.end}',
                      onTap: () => _showWorkingHoursDialog(context, provider),
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

  Widget _buildNotificationCategory(BuildContext context, String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SettingsSwitchTile(
      icon: icon,
      title: title,
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _updateWeeklyReview(BuildContext context, SettingsProvider provider) async {
    final goals = provider.goals;
    final timeStr = goals.weeklyReviewTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(timeStr[0]), minute: int.parse(timeStr[1]));

    final time = await showTimePicker(context: context, initialTime: initialTime);
    if (time != null) {
      provider.updateGoals(goals.copyWith(
        weeklyReviewTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      ));
    }
  }

  Future<void> _updateDiaryPromptTime(BuildContext context, SettingsProvider provider) async {
    final diary = provider.diary;
    final timeStr = diary.promptTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(timeStr[0]), minute: int.parse(timeStr[1]));

    final time = await showTimePicker(context: context, initialTime: initialTime);
    if (time != null) {
      provider.updateDiary(diary.copyWith(
        promptTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      ));
    }
  }

  void _showWorkingDaysDialog(BuildContext context, SettingsProvider provider) {
    final tasks = provider.tasks;
    List<WeekDay> selectedDays = List.from(tasks.workingDays);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Working Days'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: WeekDay.values.map((day) {
              return CheckboxListTile(
                title: Text(_getDayName(day)),
                value: selectedDays.contains(day),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) selectedDays.add(day);
                    else selectedDays.remove(day);
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateTasks(tasks.copyWith(workingDays: selectedDays));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog(BuildContext context, SettingsProvider provider) {
    final tasks = provider.tasks;
    final startParts = tasks.workingHours.start.split(':');
    final endParts = tasks.workingHours.end.split(':');

    TimeOfDay startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    TimeOfDay endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Working Hours'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Start Time'),
                trailing: Text(_formatTime(startTime)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: startTime);
                  if (time != null) {
                    setState(() => startTime = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('End Time'),
                trailing: Text(_formatTime(endTime)),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: endTime);
                  if (time != null) {
                    setState(() => endTime = time);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateTasks(tasks.copyWith(
                workingHours: tasks.workingHours.copyWith(
                  start: _formatTime(startTime),
                  end: _formatTime(endTime),
                ),
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getDayName(WeekDay day) => day.name[0].toUpperCase() + day.name.substring(1);
  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:the_time_chart/features/personal/task_model/week_task/services/weekly_task_ai_service.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/widgets/week_task_calendar_widget.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../providers/week_task_provider.dart';
import '../models/week_task_model.dart';
import '../../../../chats/widgets/shared_content/chat_picker_sheet.dart';
import '../../../../../../features/social/post/repositories/post_repository.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../../widgets/feature_info_widgets.dart';

class WeeklyTaskOptionsMenu {
  WeeklyTaskOptionsMenu._();

  static Future<void> show({
    required BuildContext context,
    required WeekTaskModel task,
    Offset? position,
    DateTime? selectedDate,
  }) async {
    // 1. Check if posted (fresh from DB)
    bool isPostedRaw = task.socialInfo.isPosted;
    try {
      final postRepo = PostRepository();
      isPostedRaw = await postRepo.isSourcePosted(
        sourceType: 'week_task',
        sourceId: task.id,
      );
    } catch (e) {
      logW('Failed to check weekly task post status: $e');
    }

    if (!context.mounted) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final pos = position != null
        ? RelativeRect.fromLTRB(
            position.dx,
            position.dy,
            overlay.size.width - position.dx,
            overlay.size.height - position.dy,
          )
        : RelativeRect.fromLTRB(
            overlay.size.width / 2 - 100,
            overlay.size.height / 2 - 150,
            overlay.size.width / 2 - 100,
            overlay.size.height / 2 - 150,
          );

    final theme = Theme.of(context);

    // Update task with fresh status for the menu items
    final updatedTask = task.copyWith(
      socialInfo: SocialInfo(
        isPosted: isPostedRaw,
        posted: task.socialInfo.posted,
      ),
    );

    await showMenu<String>(
      context: context,
      position: pos,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: _buildMenuItems(context, updatedTask, theme, selectedDate),
    ).then((value) {
      if (value != null) {
        _handleMenuAction(context, value, updatedTask, selectedDate);
      }
    });
  }

  static void showFromContext({
    required BuildContext context,
    required WeekTaskModel task,
    DateTime? selectedDate,
  }) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final position = Offset(
      offset.dx + size.width / 2,
      offset.dy + size.height / 2,
    );
    show(
      context: context,
      task: task,
      position: position,
      selectedDate: selectedDate,
    );
  }

  static List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    WeekTaskModel task,
    ThemeData theme,
    DateTime? selectedDate,
  ) {
    return [
      PopupMenuItem<String>(
        enabled: false,
        height: 40,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.task_alt_rounded,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.aboutTask.taskName,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 8),
      _buildMenuItem(
        value: 'detail',
        icon: Icons.visibility_rounded,
        label: 'View Details',
        iconColor: theme.colorScheme.primary,
      ),
      _buildMenuItem(
        value: 'analysis',
        icon: Icons.analytics_outlined,
        label: 'View Analysis',
        iconColor: theme.colorScheme.secondary,
      ),
      _buildMenuItem(
        value: 'calendar',
        icon: Icons.calendar_month_rounded,
        label: 'View Calendar',
        iconColor: theme.colorScheme.primary,
      ),
      if (_canAddFeedbackToday(task, selectedDate: selectedDate))
        _buildMenuItem(
          value: 'feedback',
          icon: Icons.comment_outlined,
          label: 'Add Feedback',
          iconColor: theme.colorScheme.tertiary,
        ),
      const PopupMenuDivider(height: 8),
      if (!task.socialInfo.isPosted) ...[
        _buildMenuItem(
          value: 'post_live',
          icon: Icons.live_tv_rounded,
          label: 'Post Live',
          iconColor: Colors.red,
        ),
        _buildMenuItem(
          value: 'post_snapshot',
          icon: Icons.photo_camera_rounded,
          label: 'Post Snapshot',
          iconColor: Colors.blue,
        ),
      ] else ...[
        _buildMenuItem(
          value: 'view_post',
          icon: Icons.public_rounded,
          label: 'View Post',
          iconColor: Colors.blue,
        ),
        _buildMenuItem(
          value: 'delete_post',
          icon: Icons.remove_circle_outline,
          label: 'Remove Post',
          iconColor: Colors.orange,
        ),
      ],
      const PopupMenuDivider(height: 8),
      _buildMenuItem(
        value: 'share_live',
        icon: Icons.share_rounded,
        label: 'Share Live',
        iconColor: Colors.teal,
      ),
      _buildMenuItem(
        value: 'share_snapshot',
        icon: Icons.photo_camera_outlined,
        label: 'Share Snapshot',
        iconColor: Colors.deepOrange,
      ),
      const PopupMenuDivider(height: 8),
      if (task.indicators.status.toLowerCase() != 'completed') ...[
        _buildMenuItem(
          value: 'hold',
          icon: Icons.pause_circle_rounded,
          label: 'Hold Task',
          iconColor: Colors.teal,
        ),
        _buildMenuItem(
          value: 'complete',
          icon: Icons.check_circle_rounded,
          label: 'Complete Task',
          iconColor: Colors.orange,
        ),
      ] else ...[
        _buildMenuItem(
          value: 'continue',
          icon: Icons.play_arrow_rounded,
          label: 'Continue Task',
          iconColor: Colors.green,
        ),
        _buildMenuItem(
          value: 'complete_view',
          icon: Icons.check_circle_rounded,
          label: 'Complete Task',
          iconColor: Colors.orange,
        ),
      ],
      const PopupMenuDivider(height: 8),
      _buildMenuItem(
        value: 'edit',
        icon: Icons.edit_outlined,
        label: 'Edit Task',
        iconColor: Colors.amber,
      ),
      _buildMenuItem(
        value: 'delete',
        icon: Icons.delete_outline_rounded,
        label: 'Delete Task',
        iconColor: Colors.red,
        textColor: Colors.red,
      ),
      const PopupMenuDivider(height: 8),
      _buildMenuItem(
        value: 'how_it_works',
        icon: Icons.info_outline_rounded,
        label: 'How it Works',
        iconColor: theme.colorScheme.tertiary,
      ),
    ];
  }

  static PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
    Color? textColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static void _handleMenuAction(
    BuildContext context,
    String action,
    WeekTaskModel task,
    DateTime? selectedDate,
  ) {
    switch (action) {
      case 'detail':
        _handleViewDetail(context, task);
        break;
      case 'analysis':
        _handleViewAnalysis(context, task);
        break;
      case 'calendar':
        _handleViewCalendar(context, task);
        break;
      case 'feedback':
        _handleAddFeedback(context, task, selectedDate);
        break;
      case 'hold':
        _handleHoldTask(context, task);
        break;
      case 'continue':
        _handleContinueTask(context, task);
        break;
      case 'post_live':
        _handlePostLive(context, task);
        break;
      case 'post_snapshot':
        _handlePostSnapshot(context, task);
        break;
      case 'view_post':
        _handleViewPost(context, task);
        break;
      case 'delete_post':
        _handleDeletePost(context, task);
        break;
      case 'share_live':
        _openShareScreen(context, task, 'live');
        break;
      case 'share_snapshot':
        _openShareScreen(context, task, 'snapshot');
        break;
      case 'unshare':
        _handleUnshare(context, task);
        break;
      case 'edit':
        _handleEdit(context, task);
        break;
      case 'delete':
        _showDeleteDialog(context, task);
        break;
      case 'how_it_works':
        FeatureInfoCard.showEliteDialog(context, EliteFeatures.weekTasks);
        break;
    }
  }

  static void _handleViewDetail(BuildContext context, WeekTaskModel task) {
    context.push('/personalNav/week-task/${task.id}', extra: task);
  }

  static void _handleAddFeedback(
    BuildContext context,
    WeekTaskModel task,
    DateTime? selectedDate,
  ) {
    final now = selectedDate ?? DateTime.now();
    context.push(
      '/personalNav/AddWeeklyFeedbackScreen',
      extra: {'task': task, 'selectedDate': now},
    );
  }

  static bool _canAddFeedbackToday(
    WeekTaskModel task, {
    DateTime? selectedDate,
  }) {
    final status = task.indicators.status.toLowerCase();
    if (status.contains('completed') || status.contains('hold')) return false;

    // Use selectedDate if provided, otherwise the actual current time.
    final now = DateTime.now();
    final targetDate = selectedDate ?? now;
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    // Requirement: feedback option ONLY for the scheduled day AND only between starting and ending time.
    // 1. Check if targetDate is a scheduled day
    final isDateScheduled = task.timeline.isScheduledDate(targetDate);
    if (!isDateScheduled) return false;

    // 2. Requirement: "only between starting and ending time"
    // Usually, we only allow adding feedback for "now" if it's currently within the window.
    // However, if the user is looking at a specific date in the calendar, they might want to see if they *could* have added it.
    // But the user said "i want my feedback option only for that day on which user has task sedule and only between stating and ending time"

    // If it's a different day than today, we don't show the "Add Feedback" option because it's a real-time action.
    if (formatter.format(targetDate) != formatter.format(now)) {
      return false;
    }

    final nowMins = now.hour * 60 + now.minute;
    final startMins =
        task.timeline.startingTime.hour * 60 +
        task.timeline.startingTime.minute;
    final endMins =
        task.timeline.endingTime.hour * 60 + task.timeline.endingTime.minute;

    if (startMins <= endMins) {
      return nowMins >= startMins && nowMins <= endMins;
    }
    return nowMins >= startMins || nowMins <= endMins;
  }

  static void _handleViewAnalysis(BuildContext context, WeekTaskModel task) {
    context.push(
      '/personalNav/WeeklyTaskDailyAnalysisScreen/${task.id}',
      extra: {'selectedDate': DateTime.now()},
    );
  }

  static void _handleViewCalendar(BuildContext context, WeekTaskModel task) {
    WeekTaskCalendarWidget.show(context, task: task);
  }

  static Future<void> _handleContinueTask(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Continue Task'),
          ],
        ),
        content: Text(
          'Resume working on this task?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final success = await provider.continueTask(task.id);
      if (success) {
        AppSnackbar.success('Task continued', description: 'Continue');
      } else {
        AppSnackbar.error('Failed to continue task', description: 'Error');
      }
    }
  }

  static Future<void> _handleHoldTask(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pause_circle_rounded, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            const Text('Hold Task'),
          ],
        ),
        content: Text(
          'Pause this task and continue later?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hold'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final success = await provider.holdTask(task.id);
      if (success) {
        AppSnackbar.success('Task on hold', description: 'Paused');
      } else {
        AppSnackbar.error('Failed to hold task', description: 'Error');
      }
    }
  }

  static Future<void> _handlePostLive(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final captionController = TextEditingController();
    final visibilityOptions = ['public', 'friends', 'private'];
    var selectedVisibility = 'public';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.live_tv_rounded, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('Create Live Post'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live posts show real-time task progress',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: captionController,
                  hint: 'Write a caption... (optional)',
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                  minLines: 3,
                  prefixIcon: Icons.edit_note_rounded,
                  suffixIcon: Icons.auto_awesome,
                  onSuffixIconTap: () async {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (userId == null) {
                      ErrorHandler.showErrorSnackbar(
                        'Login required to use AI',
                        title: 'Auth',
                      );
                      return;
                    }
                    try {
                      final caption = await WeeklyTaskAIService()
                          .generateCaption(task, userId, isLive: true);
                      if (caption != null && caption.isNotEmpty) {
                        captionController.text = caption;
                        ErrorHandler.showSuccessSnackbar(
                          'Caption generated',
                          title: 'AI',
                        );
                      } else {
                        ErrorHandler.showErrorSnackbar(
                          'Could not generate caption',
                          title: 'AI',
                        );
                      }
                    } catch (_) {
                      ErrorHandler.showErrorSnackbar(
                        'AI Error',
                        title: 'Error',
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Visibility',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...visibilityOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(option[0].toUpperCase() + option.substring(1)),
                    value: option,
                    groupValue: selectedVisibility,
                    onChanged: (value) {
                      setState(() => selectedVisibility = value!);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.live_tv_rounded, size: 18),
              label: const Text('Post Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final postId = await provider.createLivePost(
        taskId: task.id,
        caption: captionController.text.isNotEmpty
            ? captionController.text
            : null,
        visibility: selectedVisibility,
      );
      if (postId != null) {
        ErrorHandler.showSuccessSnackbar('Live post created', title: 'Posted');
      } else {
        ErrorHandler.showErrorSnackbar('Failed to post task', title: 'Error');
      }
    }
  }

  static Future<void> _handlePostSnapshot(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final captionController = TextEditingController();
    final visibilityOptions = ['public', 'friends', 'private'];
    var selectedVisibility = 'public';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Create Snapshot Post'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Snapshot posts capture current progress',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: captionController,
                  hint: 'Write a caption... (optional)',
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 3,
                  minLines: 3,
                  prefixIcon: Icons.edit_note_rounded,
                  suffixIcon: Icons.auto_awesome,
                  onSuffixIconTap: () async {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (userId == null) {
                      ErrorHandler.showErrorSnackbar(
                        'Login required to use AI',
                        title: 'Auth',
                      );
                      return;
                    }
                    try {
                      final caption = await WeeklyTaskAIService()
                          .generateCaption(task, userId, isLive: false);
                      if (caption != null && caption.isNotEmpty) {
                        captionController.text = caption;
                        ErrorHandler.showSuccessSnackbar(
                          'Caption generated',
                          title: 'AI',
                        );
                      } else {
                        ErrorHandler.showErrorSnackbar(
                          'Could not generate caption',
                          title: 'AI',
                        );
                      }
                    } catch (_) {
                      ErrorHandler.showErrorSnackbar(
                        'AI Error',
                        title: 'Error',
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Visibility',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...visibilityOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(option[0].toUpperCase() + option.substring(1)),
                    value: option,
                    groupValue: selectedVisibility,
                    onChanged: (value) {
                      setState(() => selectedVisibility = value!);
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.photo_camera_rounded, size: 18),
              label: const Text('Post Snapshot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final postId = await provider.createSnapshotPost(
        taskId: task.id,
        caption: captionController.text.isNotEmpty
            ? captionController.text
            : null,
        visibility: selectedVisibility,
      );
      if (postId != null) {
        ErrorHandler.showSuccessSnackbar(
          'Snapshot post created',
          title: 'Posted',
        );
      } else {
        ErrorHandler.showErrorSnackbar('Failed to post task', title: 'Error');
      }
    }
  }

  static void _handleViewPost(BuildContext context, WeekTaskModel task) {
    if (task.socialInfo.posted == null) {
      ErrorHandler.showErrorSnackbar(
        'Post information not available',
        title: 'Error',
      );
      return;
    }
    final postId = task.socialInfo.posted!.postId;
    context.push('/socialNav/post-details/$postId');
  }

  static Future<void> _handleDeletePost(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final posted = task.socialInfo.posted;
    if (posted == null) {
      ErrorHandler.showErrorSnackbar(
        'Post information not available',
        title: 'Error',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Remove Post'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to remove this post from your feed?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              'This will not delete the task, only the social post.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final success = await provider.deletePost(posted.postId, task.id);
      if (success) {
        ErrorHandler.showSuccessSnackbar(
          'Post removed from feed',
          title: 'Removed',
        );
      } else {
        ErrorHandler.showErrorSnackbar('Failed to remove post', title: 'Error');
      }
    }
  }

  static Future<void> _openShareScreen(
    BuildContext context,
    WeekTaskModel task,
    String shareType,
  ) async {
    final chatIds = await showChatPicker(
      context,
      title: 'Share $shareType Task...',
      multiSelect: true,
    );

    if (chatIds != null && chatIds.isNotEmpty && context.mounted) {
      final provider = context.read<WeekTaskProvider>();
      bool allSuccess = true;
      for (final chatId in chatIds) {
        final success = await provider.shareTaskViaChat(
          taskId: task.id,
          chatId: chatId,
          isLive: shareType == 'live',
        );
        if (!success) allSuccess = false;
      }

      if (allSuccess) {
        ErrorHandler.showSuccessSnackbar(
          'Task shared to ${chatIds.length} chat(s)',
          title: 'Shared',
        );
      } else {
        ErrorHandler.showErrorSnackbar(
          'Failed to share to some chats',
          title: 'Error',
        );
      }
    }
  }

  static Future<void> _handleUnshare(
    BuildContext context,
    WeekTaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_off_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            const Text('Unshare Task'),
          ],
        ),
        content: Text(
          'Remove this task from all chats where it was shared?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Unshare'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final provider = Provider.of<WeekTaskProvider>(context, listen: false);
      final success = await provider.unshareTaskFromChat(taskId: task.id);
      if (success) {
        AppSnackbar.success(
          'Task unshared from all chats',
          description: 'Unshared',
        );
      } else {
        AppSnackbar.error('Failed to unshare', description: 'Error');
      }
    }
  }

  static void _handleEdit(BuildContext context, WeekTaskModel task) {
    context.push('/personalNav/addWeeklyTask', extra: {'existingTask': task});
  }

  static void _showDeleteDialog(BuildContext context, WeekTaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red.shade400),
            ),
            const SizedBox(width: 12),
            const Text('Delete Task'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this task?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.task_alt, color: Colors.red.shade300, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.aboutTask.taskName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade500, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This action cannot be undone. All associated data will be removed.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final provider = Provider.of<WeekTaskProvider>(
                context,
                listen: false,
              );
              Navigator.pop(context);
              final success = await provider.deleteTask(task.id);
              if (success) {
                ErrorHandler.showSuccessSnackbar(
                  'Your weekly task has been removed',
                  title: 'Task Deleted',
                );
              } else {
                ErrorHandler.showErrorSnackbar(
                  'Failed to delete task',
                  title: 'Error',
                );
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

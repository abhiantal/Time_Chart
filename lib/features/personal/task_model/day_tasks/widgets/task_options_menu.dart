// lib/features/day_task/screens_widgets/task_options_menu.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/providers/day_task_provider.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/logger.dart';
import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../Authentication/auth_provider.dart';
import '../models/day_task_model.dart';
import '../screens/add_feedback_screen.dart';
import '../widgets/task_analysis_dialog.dart';
import '../screens/task_form_bottom_sheet.dart';
import '../services/day_task_ai_service.dart';
import '../../../../Chats/widgets/shared_content/chat_picker_sheet.dart';
import '../../../../../../features/social/post/repositories/post_repository.dart';
import '../../../../../../widgets/feature_info_widgets.dart';

/// Show popup menu for a task (matches weekly menu style)
Future<void> showTaskOptionsMenu(
  BuildContext context,
  DayTaskModel task, {
  Offset? position,
}) async {
  bool isPostedRaw = task.socialInfo.isPosted;
  try {
    final postRepo = PostRepository();
    isPostedRaw = await postRepo.isSourcePosted(
      sourceType: 'day_task',
      sourceId: task.id,
    );
  } catch (e) {
    logW('Failed to check task post status: $e');
  }

  if (!context.mounted) return;

  final updatedTask = task.copyWith(
    socialInfo: SocialInfo(
      isPosted: isPostedRaw,
      posted: task.socialInfo.posted,
    ),
  );

  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  final RelativeRect pos = (overlay != null && position != null)
      ? RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          overlay.size.width - position.dx,
          overlay.size.height - position.dy,
        )
      : const RelativeRect.fromLTRB(100, 100, 0, 0);

  final theme = Theme.of(context);

  showMenu<String>(
    context: context,
    position: pos,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 8,
    items: [
      PopupMenuItem<String>(
        enabled: false,
        height: 40,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
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
                updatedTask.aboutTask.taskName,
                style: const TextStyle(
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
      _popupItem(
        'analysis',
        Icons.analytics_rounded,
        'Task Analysis',
        Colors.indigo,
      ),

      if (_canAddFeedback(updatedTask))
        _popupItem(
          'feedback',
          Icons.add_comment_rounded,
          'Add Feedback',
          Colors.blue,
        ),
      const PopupMenuDivider(height: 8),
      if (!updatedTask.socialInfo.isPosted) ...[
        _popupItem('post_live', Icons.live_tv_rounded, 'Post Live', Colors.red),
        _popupItem(
          'post_snapshot',
          Icons.photo_camera_rounded,
          'Post Snapshot',
          Colors.blue,
        ),
      ] else ...[
        _popupItem('view_post', Icons.public_rounded, 'View Post', Colors.blue),
        _popupItem(
          'delete_post',
          Icons.remove_circle_outline,
          'Remove Post',
          Colors.orange,
        ),
      ],
      const PopupMenuDivider(height: 8),
      _popupItem('share_live', Icons.share_rounded, 'Share Live', Colors.teal),
      _popupItem(
        'share_snapshot',
        Icons.photo_camera_outlined,
        'Share Snapshot',
        Colors.deepOrange,
      ),
      const PopupMenuDivider(height: 8),
      _popupItem(
        'edit',
        Icons.edit_rounded,
        'Edit Task',
        theme.colorScheme.primary,
        enabled: !updatedTask.metadata.isComplete,
      ),
      _popupItem(
        'delete',
        Icons.delete_rounded,
        'Delete Task',
        theme.colorScheme.error,
        textColor: theme.colorScheme.error,
      ),
      const PopupMenuDivider(height: 8),
      _popupItem(
        'how_it_works',
        Icons.info_outline_rounded,
        'How it Works',
        theme.colorScheme.tertiary,
      ),
    ],
  ).then((value) {
    if (value == null) return;
    switch (value) {
      case 'analysis':
        TaskAnalysisDialog.show(context, updatedTask);
        break;
      case 'feedback':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddFeedbackScreen(task: updatedTask),
          ),
        );
        break;
      case 'post_live':
        _handlePost(context, updatedTask, true);
        break;
      case 'post_snapshot':
        _handlePost(context, updatedTask, false);
        break;
      case 'view_post':
        ErrorHandler.showInfoSnackbar('Already posted', title: 'Post');
        break;
      case 'delete_post':
        _handleDeletePost(context, updatedTask);
        break;
      case 'share_live':
        _openShareScreen(context, updatedTask, 'live');
        break;
      case 'share_snapshot':
        _openShareScreen(context, updatedTask, 'snapshot');
        break;
      case 'edit':
        _editTask(context, updatedTask);
        break;
      case 'delete':
        _deleteTask(context, updatedTask);
        break;
      case 'how_it_works':
        FeatureInfoCard.showEliteDialog(context, EliteFeatures.dayTasks);
        break;
    }
  });
}

// ================================================================
// POPUP ITEM BUILDER
// ================================================================
PopupMenuItem<String> _popupItem(
  String value,
  IconData icon,
  String label,
  Color iconColor, {
  Color? textColor,
  bool enabled = true,
}) {
  return PopupMenuItem<String>(
    value: value,
    enabled: enabled,
    height: 44,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: enabled
                ? iconColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: enabled ? iconColor : Colors.grey, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: enabled ? textColor : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

bool _canAddFeedback(DayTaskModel task) {
  // Once completed, do not allow any updates (feedback)
  if (task.metadata.isComplete || task.indicators.status == 'completed') {
    return false;
  }

  final now = DateTime.now();
  final start = task.timeline.startingTime;
  final end = task.timeline.endingTime;

  // Show only between starting and ending time (inclusive)
  final isBetweenStartAndEnd = (now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                               (now.isBefore(end) || now.isAtSameMomentAs(end));

  // Or if the task status is overdue
  final isOverdue = task.indicators.status == 'overdue' || task.timeline.overdue;

  return isBetweenStartAndEnd || isOverdue;
}

// ================================================================
// HANDLE POST
// ================================================================
Future<void> _handlePost(
  BuildContext context,
  DayTaskModel task,
  bool isLive,
) async {
  final captionController = TextEditingController();
  final visibilityOptions = ['public', 'friends', 'private'];
  String selectedVisibility = 'public';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (builderContext, setState) {
        final titleColor = isLive ? Colors.red : Colors.blue;
        final titleIcon = isLive
            ? Icons.live_tv_rounded
            : Icons.photo_camera_rounded;
        final titleText = isLive ? 'Create Live Post' : 'Create Snapshot Post';
        final infoText = isLive
            ? 'Live posts show real-time task progress'
            : 'Snapshot posts capture current progress';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: titleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(titleIcon, color: titleColor),
              ),
              const SizedBox(width: 12),
              Text(titleText),
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
                    color: titleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: titleColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLive ? Icons.circle : Icons.camera_alt_rounded,
                        color: titleColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(infoText)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                    try {
                      final userId = context
                          .read<AuthProvider>()
                          .currentUser
                          ?.id;
                      if (userId == null) {
                        AppSnackbar.error(
                          'Login required to use AI',
                        );
                        return;
                      }
                      final service = DayTaskAIService();
                      final caption = await service.generateCaption(
                        task,
                        userId,
                        isLive: isLive,
                      );
                      if (caption != null && caption.isNotEmpty) {
                        captionController.text = caption;
                        AppSnackbar.success(
                          'Caption generated',
                        );
                      } else {
                        AppSnackbar.error(
                          'Could not generate caption',
                        );
                      }
                    } catch (e, s) {
                      ErrorHandler.handleError(e, s, 'Generate Caption');
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Visibility',
                  style: Theme.of(
                    builderContext,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                ...visibilityOptions.map(
                  (v) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: v,groupValue: selectedVisibility,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedVisibility = val);
                        }
                      },
                    ),
                    title: Text(v[0].toUpperCase() + v.substring(1)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: titleColor),
              child: Text(isLive ? 'Post Live' : 'Post Snapshot'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed == true && context.mounted) {
    final provider = context.read<DayTaskProvider>();
    final success = await provider.postTask(
      taskId: task.id,
      isLive: isLive,
      caption: captionController.text.isNotEmpty
          ? captionController.text
          : null,
      visibility: selectedVisibility,
    );
    if (success) {
      AppSnackbar.success(
        isLive ? 'Live Post Created! 🎉' : 'Snapshot Post Created! 📸',
      );
    } else {
      AppSnackbar.error('Failed to create post');
    }
  }
}

// ================================================================
// HANDLE DELETE POST
// ================================================================
Future<void> _handleDeletePost(BuildContext context, DayTaskModel task) async {
  final confirmed = await ErrorHandler.showConfirmationDialog(
    context,
    title: 'Remove Post',
    message: 'Are you sure you want to remove this post from the feed?',
  );

  if (confirmed && context.mounted) {
    final provider = context.read<DayTaskProvider>();
    final success = await provider.removePost(task.id);
    if (success) {
      AppSnackbar.success('Post removed');
    } else {
      AppSnackbar.error('Failed to remove post');
    }
  }
}

// ================================================================
// OPEN SHARE SCREEN
// ================================================================
void _openShareScreen(
  BuildContext context,
  DayTaskModel task,
  String shareType,
) async {
  final chatIds = await showChatPicker(
    context,
    title: 'Share $shareType Task...',
    multiSelect: true,
  );

  if (chatIds != null && chatIds.isNotEmpty && context.mounted) {
    final provider = context.read<DayTaskProvider>();
    bool allSuccess = true;
    for (final chatId in chatIds) {
      final success = await provider.shareTaskViaChat(
        taskId: task.id,
        chatId: chatId,
        messageText: '',
        isLive: shareType == 'live',
      );
      if (!success) allSuccess = false;
    }

    if (allSuccess) {
      AppSnackbar.success(
        'Task shared to ${chatIds.length} chat(s)',
      );
    } else {
      AppSnackbar.error('Failed to share to some chats');
    }
  }
}

// ================================================================
// EDIT TASK
// ================================================================
void _editTask(BuildContext context, DayTaskModel task) {
  try {
    logI('✏️ Opening edit task for: ${task.id}');
    TaskFormBottomSheet.showEditTask(context, task);
  } catch (e, stack) {
    ErrorHandler.handleError(e, stack, 'Edit Task');
    ErrorHandler.showErrorSnackbar(
      'Failed to open edit form. Please try again.',
      context: context,
    );
  }
}

// ================================================================
// DELETE TASK
// ================================================================
Future<void> _deleteTask(BuildContext context, DayTaskModel task) async {
  try {
    final colorScheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_rounded, color: colorScheme.error, size: 48),
        title: const Text('Delete Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this task?',
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                   Icon(
                    Icons.info_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '📋 ${task.aboutTask.taskName}',
              style: Theme.of(
                dialogContext,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    ErrorHandler.showLoading('Deleting task...');
    final provider = context.read<DayTaskProvider>();
    final success = await provider.deleteTask(task.id);
    ErrorHandler.hideLoading();

    if (!context.mounted) return;

    if (success) {
      ErrorHandler.showSuccessSnackbar(
        '${task.aboutTask.taskName} has been removed',
        context: context,
        title: 'Task Deleted',
      );
    } else {
      throw Exception(provider.error ?? 'Failed to delete task');
    }
  } catch (e, stack) {
    ErrorHandler.handleError(e, stack, 'Delete Task');
    ErrorHandler.hideLoading();

    if (context.mounted) {
      ErrorHandler.showErrorSnackbar(
        'Failed to update task status.',
        context: context,
      );
    }
  }
}

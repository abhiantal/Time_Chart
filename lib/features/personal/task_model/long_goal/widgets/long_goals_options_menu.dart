import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/providers/long_goals_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../../../../../../widgets/error_handler.dart';
import '../../../../../../widgets/custom_text_field.dart';
import '../../../../../../ai_services/services/universal_ai_service.dart';
import '../models/long_goal_model.dart';
import 'long_goal_calendar_widget.dart';
import '../../../../chats/widgets/shared_content/chat_picker_sheet.dart';
import '../screens/create_goal_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../widgets/feature_info_widgets.dart';

/// Long Goals Options Menu
/// Matches Weekly Task menu UI and behavior (popup menu via showMenu)
class LongGoalsOptionsMenu {
  LongGoalsOptionsMenu._();

  static Future<void> show({
    required BuildContext context,
    required LongGoalModel goal,
    Offset? position,
  }) async {
    bool isPostedRaw = goal.socialInfo.isPosted;
    if (!context.mounted) return;

    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect pos = position != null
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

    // Update goal with fresh status
    final updatedGoal = goal.copyWith(
      socialInfo: SocialInfo(
        isPosted: isPostedRaw,
        posted: goal.socialInfo.posted,
      ),
    );

    final value = await showMenu<String>(
      context: context,
      position: pos,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: _buildMenuItems(context, updatedGoal, theme),
    );

    if (value != null && context.mounted) {
      await _handleMenuAction(context, value, updatedGoal);
    }
  }

  static Future<void> showFromContext({
    required BuildContext context,
    required LongGoalModel goal,
  }) async {
    final ro = context.findRenderObject();
    if (ro is RenderBox) {
      final Offset offset = ro.localToGlobal(Offset.zero);
      final Size size = ro.size;
      final position = Offset(
        offset.dx + size.width / 2,
        offset.dy + size.height / 2,
      );
      await show(context: context, goal: goal, position: position);
      return;
    }
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay != null) {
      final center = Offset(overlay.size.width / 2, overlay.size.height / 2);
      await show(context: context, goal: goal, position: center);
    } else {
      await show(context: context, goal: goal);
    }
  }

  static List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    LongGoalModel goal,
    ThemeData theme,
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
                Icons.flag_rounded,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                goal.title,
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

      _item(
        'calendar',
        Icons.calendar_today_rounded,
        'View Calendar',
        theme.colorScheme.primary,
      ),
      _item(
        'detail',
        Icons.visibility_rounded,
        'View Details',
        theme.colorScheme.primary,
      ),

      const PopupMenuDivider(height: 8),

      if (!goal.socialInfo.isPosted) ...[
        _item('post_live', Icons.live_tv_rounded, 'Post Live', Colors.red),
        _item(
          'post_snapshot',
          Icons.photo_camera_rounded,
          'Post Snapshot',
          Colors.blue,
        ),
      ] else ...[
        _item('view_post', Icons.public_rounded, 'View Post', Colors.blue),
        _item(
          'delete_post',
          Icons.remove_circle_outline,
          'Remove Post',
          Colors.orange,
        ),
      ],

      const PopupMenuDivider(height: 8),
      _item('share_live', Icons.share_rounded, 'Share Live', Colors.teal),
      _item(
        'share_snapshot',
        Icons.photo_camera_rounded,
        'Share Snapshot',
        Colors.deepOrange,
      ),

      const PopupMenuDivider(height: 8),
      if (goal.indicators.status.toLowerCase() != 'completed') ...[
        if (goal.timeline.startDate != null) ...[
          _item('hold', Icons.pause_circle_rounded, 'Hold Task', Colors.teal),
          _item(
            'complete',
            Icons.check_circle_rounded,
            'Complete Task',
            Colors.orange,
          ),
        ] else ...[
          _item(
            'continue',
            Icons.play_arrow_rounded,
            'Continue Task',
            Colors.green,
          ),
          _item(
            'complete_view',
            Icons.check_circle_rounded,
            'Complete Task',
            Colors.orange,
          ),
        ],
      ],

      const PopupMenuDivider(height: 8),

      _item('edit', Icons.edit_outlined, 'Edit Goal', Colors.amber),
      _item(
        'delete',
        Icons.delete_outline_rounded,
        'Delete Goal',
        Colors.red,
        textColor: Colors.red,
      ),

      const PopupMenuDivider(height: 8),
      _item(
        'how_it_works',
        Icons.info_outline_rounded,
        'How it Works',
        theme.colorScheme.tertiary,
      ),
    ];
  }

  static PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label,
    Color iconColor, {
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

  static Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    LongGoalModel goal,
  ) async {
    switch (action) {
      case 'calendar':
        await _handleViewCalendar(context, goal);
        break;
      case 'detail':
        context.pushNamed(
          'longGoalDetailScreen',
          pathParameters: {'goalId': goal.goalId},
        );
        break;
      case 'start':
        _updateStatus(context, goal, 'inProgress', 'Goal started');
        break;
      case 'stop':
        _updateStatus(context, goal, 'onHold', 'Goal put on hold');
        break;
      case 'continue':
        _updateStatus(context, goal, 'inProgress', 'Goal continued');
        break;
      case 'complete':
        await _updateStatus(context, goal, 'completed', 'Goal completed');
        break;
      case 'analysis':
        ErrorHandler.showInfoSnackbar('Analysis is coming soon', title: 'Info');
        break;
      case 'post_live':
        _handlePost(context, goal, true);
        break;
      case 'post_snapshot':
        _handlePost(context, goal, false);
        break;
      case 'view_post':
        _handleViewPost(context, goal);
        break;
      case 'delete_post':
        _handleDeletePost(context, goal);
        break;
      case 'share_live':
        _openShareScreen(context, goal, 'live');
        break;
      case 'share_snapshot':
        _openShareScreen(context, goal, 'snapshot');
        break;
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateLongGoalScreen(initialGoal: goal),
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(context, goal);
        break;
      case 'complete_view':
        await _handleViewCalendar(context, goal);
        break;
      case 'how_it_works':
        FeatureInfoCard.showEliteDialog(context, EliteFeatures.longGoals);
        break;
    }
  }

  static Future<void> _handleViewCalendar(
    BuildContext context,
    LongGoalModel goal,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => LongGoalCalendarWidget(
        goal: goal,
        onAddFeedback: (date) => navigateToAddFeedback(context, goal, date: date),
      ),
    );
  }

  /// Shared navigation to add feedback screen
  static void navigateToAddFeedback(
    BuildContext context,
    LongGoalModel goal, {
    DateTime? date,
  }) {
    if (goal.indicators.weeklyPlans.isEmpty) {
      AppSnackbar.warning(
        'No weekly plan generated yet. Please generate a plan first.',
      );
      return;
    }

    final selectedDate = date ?? DateTime.now();
    final weekId = goal.getWeekIdForDate(selectedDate);

    // Find the weekly plan data for this weekId to get the weekly goal
    final weekPlan = goal.indicators.weeklyPlans.firstWhere(
      (w) => w.weekId == weekId,
      orElse: () => goal.indicators.weeklyPlans.last,
    );

    context.push(
      '/personalNav/AddDailyFeedbackScreen/${goal.id}',
      extra: {
        'weekId': weekId,
        'goalTitle': goal.title,
        'weeklyGoal': weekPlan.weeklyGoal,
        'selectedDate': selectedDate,
      },
    );
  }

  static Future<void> _openShareScreen(
    BuildContext context,
    LongGoalModel goal,
    String shareType,
  ) async {
    final chatIds = await showChatPicker(
      context,
      title: 'Share $shareType Goal...',
      multiSelect: true,
    );

    if (chatIds != null && chatIds.isNotEmpty && context.mounted) {
      final provider = context.read<LongGoalsProvider>();
      bool allSuccess = true;
      for (final chatId in chatIds) {
        final success = await provider.shareGoalViaChat(
          goalId: goal.goalId,
          chatId: chatId,
          isLive: shareType == 'live',
        );
        if (!success) allSuccess = false;
      }

      if (allSuccess) {
        ErrorHandler.showSuccessSnackbar(
          'Goal shared to ${chatIds.length} chat(s)',
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

  static Future<void> _updateStatus(
    BuildContext context,
    LongGoalModel goal,
    String newStatus,
    String successMessage,
  ) async {
    try {
      final provider = context.read<LongGoalsProvider>();
      final ok = await provider.updateGoalStatus(
        goalId: goal.goalId,
        newStatus: newStatus,
      );
      if (ok) {
        ErrorHandler.showSuccessSnackbar(successMessage, title: 'Updated');
      } else {
        ErrorHandler.showErrorSnackbar(
          'Failed to update status',
          title: 'Error',
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackbar('Status update error', title: 'Error');
    }
  }

  static Future<void> _handlePost(
    BuildContext context,
    LongGoalModel goal,
    bool isLive,
  ) async {
    final captionController = TextEditingController();
    final visibilityOptions = ['public', 'friends', 'private'];
    String selectedVisibility = 'public';

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
                  color: (isLive ? Colors.red : Colors.blue).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLive ? Icons.live_tv_rounded : Icons.photo_camera_rounded,
                  color: isLive ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(isLive ? 'Create Live Post' : 'Create Snapshot Post'),
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
                    color: (isLive ? Colors.red : Colors.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isLive ? Colors.red : Colors.blue).withValues(alpha: 
                        0.3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isLive ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLive
                              ? 'Live posts show real-time goal progress'
                              : 'Snapshot captures the current moment of your goal',
                          style: TextStyle(
                            color: (isLive ? Colors.red : Colors.blue).shade700,
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
                    try {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId == null) {
                        ErrorHandler.showErrorSnackbar(
                          'Login required to use AI',
                          title: 'Auth',
                        );
                        return;
                      }
                      final ai = UniversalAIService();
                      final prompt =
                          'Goal: ${goal.title}. Create a short, motivational caption under 120 characters that aligns with this goal.';
                      final response = await ai.generateResponse(
                        prompt: prompt,
                        systemPrompt:
                            'Write concise, uplifting captions matching the goal context.',
                        maxTokens: 60,
                        temperature: 0.7,
                      );
                      final gen = response.response.trim();
                      if (response.isSuccess && gen.isNotEmpty) {
                        captionController.text = gen;
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
                    } catch (e) {
                      ErrorHandler.showErrorSnackbar(
                        'AI error',
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
                    title: Text(GetStringUtils(option).capitalize!),
                    value: option,
                    groupValue: selectedVisibility,
                    onChanged: (value) =>
                        setState(() => selectedVisibility = value!),
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
              icon: Icon(
                isLive ? Icons.live_tv_rounded : Icons.photo_camera_rounded,
                size: 18,
              ),
              label: Text(isLive ? 'Post Live' : 'Post Snapshot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLive ? Colors.red : Colors.blue,
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

    if (confirmed == true && context.mounted) {
      final provider = context.read<LongGoalsProvider>();
      final success = await provider.postLongGoal(
        goalId: goal.goalId,
        isLive: isLive,
        caption: captionController.text.isNotEmpty
            ? captionController.text
            : null,
      );
      if (success) {
        snackbarService.showSuccess(
          isLive ? 'Live Post Created! 🎉' : 'Snapshot Post Created! 📸',
        );
      }
    }
  }

  static void _handleViewPost(BuildContext context, LongGoalModel goal) {
    if (goal.socialInfo.posted == null) {
      ErrorHandler.showErrorSnackbar(
        'Post information not available',
        title: 'Error',
      );
      return;
    }
    final postTime = goal.socialInfo.posted!.time;
    snackbarService.showInfo(
      'Posted: ${DateFormat('yyyy-MM-dd HH:mm').format(postTime)}',
    );
  }

  static Future<void> _handleDeletePost(
    BuildContext context,
    LongGoalModel goal,
  ) async {
    final provider = context.read<LongGoalsProvider>();
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
        content: Text(
          'Are you sure you want to remove this post from your goal feed?',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final postId = goal.socialInfo.posted?.postId;
      if (postId != null) {
        final success = await provider.deletePost(postId);
        if (success) {
          snackbarService.showSuccess('Post removed from feed');
        } else {
          snackbarService.showError('Failed to remove post');
        }
      } else {
        // Fallback if postId is missing but marked as posted
        await provider.updateShareInfo(goalId: goal.goalId, isShare: false);
        snackbarService.showSuccess('Post removed from feed');
      }
    }
  }

  static Future<void> _showDeleteDialog(
    BuildContext context,
    LongGoalModel goal,
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
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Delete Goal'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${goal.title}"? This will permanently remove all logs and progress.',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await context.read<LongGoalsProvider>().deleteGoal(goal.id);
      if (success) {
        context.pop();
        ErrorHandler.showSuccessSnackbar('Goal deleted', title: 'Deleted');
      } else {
        ErrorHandler.showErrorSnackbar('Failed to delete goal', title: 'Error');
      }
    }
  }
}

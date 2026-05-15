import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:the_time_chart/widgets/error_handler.dart';
import 'package:the_time_chart/widgets/custom_text_field.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';
import 'package:the_time_chart/features/personal/bucket_model/providers/bucket_provider.dart';
import 'package:the_time_chart/features/social/post/providers/post_provider.dart';
import 'package:the_time_chart/features/personal/bucket_model/services/bucket_ai_service.dart';
import 'package:the_time_chart/widgets/feature_info_widgets.dart';

import 'package:the_time_chart/widgets/logger.dart';
import 'package:the_time_chart/features/social/post/repositories/post_repository.dart';
import 'package:the_time_chart/features/chats/widgets/shared_content/chat_picker_sheet.dart';

/// Shows a popup menu with options for managing a bucket
Future<void> showBucketOptionsMenu({
  required BuildContext context,
  required BucketModel bucket,
  required Offset position,
}) async {
  final theme = Theme.of(context);

  // 1. Check if posted (fresh from DB)
  bool isPostedRaw = bucket.socialInfo?.isPosted ?? false;
  try {
    final postRepo = PostRepository();
    isPostedRaw = await postRepo.isSourcePosted(
      sourceType: 'bucket_model',
      sourceId: bucket.bucketId,
    );
  } catch (e) {
    logW('Failed to check bucket post status: $e');
  }

  if (!context.mounted) return;

  // Update bucket with fresh status
  final updatedBucket = bucket.copyWith(
    socialInfo: SocialInfo(
      isPosted: isPostedRaw,
      posted: bucket.socialInfo?.posted,
    ),
  );

  await showMenu<String>(
    context: context,
    color: theme.colorScheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: _buildMenuItems(context, updatedBucket, theme),
  ).then((value) {
    if (value != null) {
      _handleMenuAction(context, value, updatedBucket);
    }
  });
}

/// Widget that displays a popup menu button for bucket options
class BucketOptionsMenu extends StatelessWidget {
  final BucketModel bucket;

  const BucketOptionsMenu({super.key, required this.bucket});

  /// Builds the popup menu button
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: (value) => _handleMenuAction(context, value, bucket),
      itemBuilder: (ctx) => _buildMenuItems(ctx, bucket, theme),
    );
  }
}

/// Builds the list of menu items based on the bucket state
List<PopupMenuEntry<String>> _buildMenuItems(
  BuildContext context,
  BucketModel bucket,
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
              color: theme.colorScheme.primary.withOpacity(0.1),
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
              bucket.title,
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

    if (!(bucket.socialInfo?.isPosted ?? false)) ...[
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
    _item('edit', Icons.edit_outlined, 'Edit Bucket', Colors.amber),
    _item(
      'delete',
      Icons.delete_outline_rounded,
      'Delete Bucket',
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

/// Creates a standardized popup menu item
PopupMenuItem<String> _item(
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
            color: iconColor.withOpacity(0.1),
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

/// Handles the selected menu action
void _handleMenuAction(
  BuildContext context,
  String action,
  BucketModel bucket,
) {
  switch (action) {
    case 'calendar':
      _handleViewCalendar(context, bucket);
      break;
    case 'detail':
      context.push(
        '/personalNav/BucketDetailScreen/${bucket.bucketId}',
        extra: bucket,
      );
      break;
    case 'analysis':
      ErrorHandler.showInfoSnackbar('Analysis is coming soon', title: 'Info');
      break;
    case 'post_live':
      _handlePost(context, bucket, true);
      break;
    case 'post_snapshot':
      _handlePost(context, bucket, false);
      break;
    case 'view_post':
      _handleViewPost(context, bucket);
      break;
    case 'delete_post':
      _handleDeletePost(context, bucket);
      break;
    case 'share_live':
      _openShareScreen(context, bucket, 'live');
      break;
    case 'share_snapshot':
      _openShareScreen(context, bucket, 'snapshot');
      break;
    case 'view_share':
      _handleViewShare(context, bucket);
      break;
    case 'unshare':
      _handleUnshare(context, bucket);
      break;
    case 'edit':
      context.push('/personalNav/AddEditBucketPage/${bucket.bucketId}');
      break;
    case 'delete':
      _showDeleteDialog(context, bucket);
      break;
    case 'how_it_works':
      FeatureInfoCard.showEliteDialog(context, EliteFeatures.buckets);
      break;
  }
}

/// Shows a dialog with the bucket's timeline calendar details
Future<void> _handleViewCalendar(
  BuildContext context,
  BucketModel bucket,
) async {
  await showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final timeline = bucket.timeline;
      final start = timeline.startDate;
      final due = timeline.dueDate;
      final progress = bucket.metadata.averageProgress;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          height: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bucket.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Bucket Timeline',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Start', style: theme.textTheme.bodySmall),
                        Text(
                          start != null
                              ? DateFormat('yyyy-MM-dd').format(start)
                              : 'Unspecified',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Due', style: theme.textTheme.bodySmall),
                        Text(
                          due != null
                              ? DateFormat('yyyy-MM-dd').format(due)
                              : 'Unspecified',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Progress', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (progress.clamp(0, 100)) / 100,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Handles posting the bucket to social media (live or snapshot)
Future<void> _handlePost(
  BuildContext context,
  BucketModel bucket,
  bool isLive,
) async {
  final captionController = TextEditingController();
  final visibilityOptions = ['public', 'friends', 'private'];
  String selectedVisibility = 'public';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isLive ? Colors.red : Colors.blue).withOpacity(0.1),
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
                    final userId = context.read<AuthProvider>().currentUser?.id;
                    if (userId == null) {
                      ErrorHandler.showErrorSnackbar(
                        'Login required to use AI',
                        title: 'Auth',
                      );
                      return;
                    }
                    final ai = BucketAiService();
                    final gen = await ai.generateCaption(
                      bucket,
                      userId,
                      isLive: isLive,
                    );
                    if (gen != null && gen.isNotEmpty) {
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
                  } catch (e, s) {
                    ErrorHandler.handleError(e, s, 'Bucket Caption AI');
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
                  title: Text(option.capitalize!),
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

  if (confirmed == true) {
    final provider = context.read<BucketProvider>();
    final success = await provider.postBucket(
      bucketId: bucket.bucketId,
      isLive: isLive,
      caption: captionController.text.isNotEmpty
          ? captionController.text
          : null,
    );
    if (success) {
      AppSnackbar.success(
        isLive ? 'Live Post Created! 🎉' : 'Snapshot Post Created! 📸',
      );
    }
  }
}

/// Handles the display of post information
void _handleViewPost(BuildContext context, BucketModel bucket) {
  if (bucket.socialInfo?.posted == null) {
    ErrorHandler.showErrorSnackbar(
      'Post information not available',
      title: 'Error',
    );
    return;
  }
  final postTime = bucket.socialInfo!.posted!.time;
  AppSnackbar.info(
    title: 'Posted: ${DateFormat('yyyy-MM-dd HH:mm').format(postTime)}',
  );
}

/// Shows a confirmation dialog and deletes the post
Future<void> _handleDeletePost(BuildContext context, BucketModel bucket) async {
  final provider = context.read<BucketProvider>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
    final success = await provider.removePost(bucket.bucketId);
    if (success) {
      snackbarService.showSuccess('Post removed from feed');
    } else {
      ErrorHandler.showErrorSnackbar('Failed to remove post', title: 'Error');
    }
  }
}

/// Shows info message about sharing
Future<void> _openShareScreen(
  BuildContext context,
  BucketModel bucket,
  String shareType,
) async {
  final chatIds = await showChatPicker(
    context,
    title: 'Share $shareType Bucket...',
    multiSelect: true,
  );

  if (chatIds != null && chatIds.isNotEmpty && context.mounted) {
    final provider = context.read<BucketProvider>();
    bool allSuccess = true;
    for (final chatId in chatIds) {
      final success = await provider.shareBucketViaChat(
        bucketId: bucket.bucketId,
        chatId: chatId,
        isLive: shareType == 'live',
      );
      if (!success) allSuccess = false;
    }

    if (allSuccess) {
      ErrorHandler.showSuccessSnackbar(
        'Bucket shared to ${chatIds.length} chat(s)',
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

/// Displays information about who the bucket is shared with
void _handleViewShare(BuildContext context, BucketModel bucket) {
  final info = bucket.shareInfo?.shareId;
  if (info == null) {
    ErrorHandler.showInfoSnackbar('No share info available', title: 'Info');
    return;
  }
  final withId = info.withId;
  ErrorHandler.showInfoSnackbar('Shared with: $withId', title: 'Share Info');
}

/// Unshares the bucket
Future<void> _handleUnshare(BuildContext context, BucketModel bucket) async {
  final provider = context.read<BucketProvider>();
  final updated = bucket.copyWith(shareInfo: ShareInfo(isShare: false));
  final success = await provider.updateBucket(updated);
  if (success) {
    ErrorHandler.showSuccessSnackbar('Unshared successfully', title: 'Unshare');
  }
}

/// Shows a dialog to confirm bucket deletion
void _showDeleteDialog(BuildContext context, BucketModel bucket) {
  final provider = context.read<BucketProvider>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade400),
          const SizedBox(width: 12),
          const Text('Delete Bucket'),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "${bucket.title}"? '
        'This action cannot be undone and will remove all associated data.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final success = await provider.deleteBucket(bucket.bucketId);
            if (success) {
              // Sync with PostProvider (Feed)
              if (context.mounted) {
                context.read<PostProvider>().removePostBySourceId(
                  bucket.bucketId,
                );
              }
              ErrorHandler.showSuccessSnackbar(
                'Your bucket has been removed',
                title: 'Bucket Deleted',
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

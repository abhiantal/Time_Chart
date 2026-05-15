import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../Authentication/auth_provider.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../../../widgets/logger.dart';
import '../../../../ai_services/services/universal_ai_service.dart';
import '../../../../features/social/post/repositories/post_repository.dart';
import '../models/diary_entry_model.dart';

/// Show popup menu for a diary entry (matches task menu style)
void showDiaryOptionsMenu(
  BuildContext context,
  DiaryEntryModel entry, {
  Offset? position,
  VoidCallback? onStateChanged,
}) async {
  // Refetch isPosted status to ensure menu is up to date
  // We can't do async inside showMenu directly for the items, but we can do a quick check
  // However, showMenu blocks.
  // Better pattern: Check status effectively or assume the passed 'entry' might be stale?
  // The user says "whan use post after that it stile show post option".
  // WE MUST CHECK DB STATUS.

  bool isPosted = false;
  try {
    final postRepo = PostRepository();
    isPosted = await postRepo.isSourcePosted(
      sourceType: 'diary_entry',
      sourceId: entry.id,
    );
  } catch (e) {
    logW('Failed to check diary post status: $e');
  }

  // If context is gone after async gap
  if (!context.mounted) return;

  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final pos = (overlay != null && position != null)
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
                Icons.auto_stories_rounded,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.title ??
                    DateFormat('MMM d, yyyy').format(entry.entryDate),
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

      // SHARE OPTIONS
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

      // POST OPTIONS - Using the FRESH FETCHED 'isPosted'
      if (!isPosted) ...[
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
    ],
  ).then((value) async {
    if (value == null) return;

    // Perform Action
    switch (value) {
      case 'post_live':
        await _handlePost(context, entry, true);
        if (onStateChanged != null) onStateChanged();
        break;
      case 'post_snapshot':
        await _handlePost(context, entry, false);
        if (onStateChanged != null) onStateChanged();
        break;
      case 'view_post':
        _handleViewPost(context, entry);
        break;
      case 'delete_post':
        await _handleDeletePost(context, entry);
        if (onStateChanged != null) onStateChanged();
        break;
      case 'share_live':
        _openShareScreen(context, entry, 'live');
        break;
      case 'share_snapshot':
        _openShareScreen(context, entry, 'snapshot');
        break;
    }
  });
}

// Helper for standard menu item
PopupMenuItem<String> _buildMenuItem({
  required String value,
  required IconData icon,
  required String label,
  required Color iconColor,
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

// ================================================================
// HANDLE POST (With AI Caption)
// ================================================================
Future<void> _handlePost(
  BuildContext context,
  DiaryEntryModel entry,
  bool isLive,
) async {
  final captionController = TextEditingController();
  const visibilityOptions = ['public', 'friends', 'private'];
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
            ? 'Live posts show your diary updates in real time'
            : 'Snapshot posts capture this diary entry as it is now';

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
                      Icon(Icons.info_outline, color: titleColor, size: 20),
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
                          description: 'Auth',
                        );
                        return;
                      }

                      final prompt = StringBuffer()
                        ..writeln(
                          'Create a short social caption for a diary entry.',
                        )
                        ..writeln('User id: $userId')
                        ..writeln('Date: ${entry.entryDate}')
                        ..writeln('Title: ${entry.title ?? ''}')
                        ..writeln('Content: ${entry.content ?? ''}');

                      if (entry.mood != null) {
                        prompt.writeln(
                          'Mood: ${entry.mood!.label} (${entry.mood!.rating}/10)',
                        );
                      }

                      if (entry.metadata?.aiSummary != null) {
                        prompt.writeln(
                          'AI summary: ${entry.metadata!.aiSummary}',
                        );
                      }

                      ErrorHandler.showLoading('Generating caption...');

                      final ai = UniversalAIService();
                      final result = await ai.generateResponse(
                        prompt: prompt.toString(),
                        systemPrompt:
                            'You write engaging, warm, personal but concise captions for diary posts (max 2 sentences).',
                        maxTokens: 80,
                        temperature: 0.7,
                        contextType: 'diary_caption',
                        aiUsageSource: 'diary_post_caption',
                        sourceTable: 'diary_entries',
                        sourceRecordId: entry.id,
                      );

                      ErrorHandler.hideLoading();

                      if (result.isSuccess &&
                          result.response.trim().isNotEmpty) {
                        captionController.text = result.response.trim();
                        AppSnackbar.success(
                          'Caption generated',
                          description: 'AI',
                        );
                      } else {
                        AppSnackbar.error(
                          'Could not generate caption',
                          description: 'AI',
                        );
                      }
                    } catch (e, s) {
                      ErrorHandler.hideLoading();
                      ErrorHandler.handleError(e, s, 'Generate diary caption');
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
                      value: v,
                      groupValue: selectedVisibility,
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
    try {
      final postRepo = PostRepository();

      ErrorHandler.showLoading('Posting...');

      final post = await postRepo.createPostFromSource(
        sourceType: 'diary_entry',
        sourceId: entry.id,
        isLive: isLive,
        caption: captionController.text.isNotEmpty
            ? captionController.text
            : null,
        visibility: selectedVisibility,
      );

      ErrorHandler.hideLoading();

      if (post != null) {
        AppSnackbar.success(
          isLive ? 'Live Post Created!' : 'Snapshot Post Created!',
          description: 'Posted',
        );
      } else {
        AppSnackbar.error('Failed to create post', description: 'Error');
      }
    } catch (e, s) {
      ErrorHandler.hideLoading();
      ErrorHandler.handleError(e, s, 'Post diary entry');
      AppSnackbar.error('Failed to create post', description: 'Error');
    }
  }
}

// ================================================================
// VIEW POST
// ================================================================
Future<void> _handleViewPost(
  BuildContext context,
  DiaryEntryModel entry,
) async {
  try {
    final postRepo = PostRepository();
    final post = await postRepo.getPostBySource(
      sourceType: 'diary_entry',
      sourceId: entry.id,
    );
    if (post != null) {
      // TODO: Navigate to unique post View (currently just showing info)
      AppSnackbar.info(
        title: 'Posted',
        message:
            'Posted on ${DateFormat('MMM d, h:mm a').format(post.publishedAt)}',
      );
    } else {
      AppSnackbar.error('Post not found', description: 'Error');
    }
  } catch (e) {
    // ignore
  }
}

// ================================================================
// DELETE POST
// ================================================================
Future<void> _handleDeletePost(
  BuildContext context,
  DiaryEntryModel entry,
) async {
  final confirmed = await ErrorHandler.showConfirmationDialog(
    context,
    title: 'Remove Post',
    message: 'Are you sure you want to remove this post from the feed?',
  );

  if (!confirmed || !context.mounted) return;

  try {
    ErrorHandler.showLoading('Removing post...');

    final postRepo = PostRepository();
    final post = await postRepo.getPostBySource(
      sourceType: 'diary_entry',
      sourceId: entry.id,
    );
    if (post == null) {
      ErrorHandler.hideLoading();
      AppSnackbar.error('Post not found', description: 'Error');
      return;
    }

    final success = await postRepo.deletePost(post.id);

    ErrorHandler.hideLoading();

    if (success) {
      AppSnackbar.success('Post removed', description: 'Deleted');
    } else {
      AppSnackbar.error('Failed to remove post', description: 'Error');
    }
  } catch (e, s) {
    ErrorHandler.hideLoading();
    ErrorHandler.handleError(e, s, 'Delete diary post');
    AppSnackbar.error('Failed to remove post', description: 'Error');
  }
}

// ================================================================
// SHARE
// ================================================================
void _openShareScreen(
  BuildContext context,
  DiaryEntryModel entry,
  String shareType,
) {
  // Show info message about sharing
  AppSnackbar.info(
    title: 'Share via chat',
    message: 'Navigate to a chat and use the share button',
  );

  // TODO: Implement proper chat selection dialog
  // You can use ShareContentSheet from lib/features/chats/widgets/shared_content/pickers/share_content_sheet.dart
  // when you have a chatId context
}

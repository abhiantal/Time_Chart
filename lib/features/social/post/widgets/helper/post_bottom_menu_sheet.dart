import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../widgets/error_handler.dart';
import '../../models/post_model.dart';

/// Post Bottom Sheet - Handles all post menu options
class PostBottomSheet {
  static void show({
    required BuildContext context,
    required String postId,
    required String userId,
    required String currentUserId,
    required String username,
    required VoidCallback? onEdit,
    required VoidCallback? onDelete,
    required VoidCallback? onShare,
    required VoidCallback? onReport,
    required VoidCallback? onBlock,
    required VoidCallback? onCopyLink,
  }) {
    final isOwnPost = userId == currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),

            // Own Post Options
            if (isOwnPost) ...[
              _buildMenuItem(
                context: context,
                icon: Icons.edit_rounded,
                label: 'Edit Post',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildMenuItem(
                context: context,
                icon: Icons.delete_rounded,
                label: 'Delete Post',
                color: Colors.red,
                onTap: () async {
                  final confirmed = await ErrorHandler.showConfirmationDialog(
                    context,
                    title: 'Delete Post',
                    message:
                        'Are you sure you want to delete this post? This action cannot be undone.',
                    isDangerous: true,
                  );
                  if (confirmed && context.mounted) {
                    Navigator.pop(context);
                    onDelete?.call();
                  }
                },
              ),
            ],

            // Other User Options
            if (!isOwnPost) ...[
              _buildMenuItem(
                context: context,
                icon: Icons.flag_rounded,
                label: 'Report Post',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onReport?.call();
                },
              ),
              _buildMenuItem(
                context: context,
                icon: Icons.block_rounded,
                label: 'Block User',
                color: Colors.red,
                onTap: () async {
                  final confirmed = await ErrorHandler.showConfirmationDialog(
                    context,
                    title: 'Block User',
                    message:
                        'Block @$username? They won\'t be able to interact with you.',
                    isDangerous: true,
                  );
                  if (confirmed && context.mounted) {
                    Navigator.pop(context);
                    onBlock?.call();
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  static void showReportDialog(
    BuildContext context, {
    required void Function(String) onSubmitted,
  }) {
    String reason = 'Spam or misleading';
    final reasons = [
      'Spam or misleading',
      'Inappropriate content',
      'Harassment or hate speech',
      'Violence or dangerous intent',
    ];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Report Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why are you reporting this post?'),
                const SizedBox(height: 16),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    title: Text(r, style: const TextStyle(fontSize: 14)),
                    value: r,
                    groupValue: reason,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) {
                      if (val != null) setState(() => reason = val);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSubmitted(reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void navigateToEditPost(BuildContext context, FeedPost post) {
    context.pushNamed(
      'editPost',
      pathParameters: {'postId': post.post.id},
      extra: {'post': post},
    );
  }

  static void handleAdCta(PostModel post) {
    // Handle ad interaction
  }
}

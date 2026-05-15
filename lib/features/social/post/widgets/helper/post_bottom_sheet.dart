// lib/features/social/posts/widgets/post_bottom_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../../../../../widgets/error_handler.dart';
import '../../../saves/providers/save_provider.dart';

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

            // Save Post (always show)
            _buildMenuItem(
              context: context,
              icon: Icons.bookmark_border_rounded,
              label: 'Save Post',
              onTap: () {
                try {
                  context.read<SaveProvider>().toggleSave(postId);
                  Navigator.pop(context);
                  AppSnackbar.success('Post saved');
                } catch (e) {
                  ErrorHandler.showErrorSnackbar('Failed to save post');
                }
              },
            ),

            // Share
            _buildMenuItem(
              context: context,
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),

            // Copy Link
            _buildMenuItem(
              context: context,
              icon: Icons.link_rounded,
              label: 'Copy Link',
              onTap: () async {
                Navigator.pop(context);
                await Clipboard.setData(
                  ClipboardData(text: 'https://app.com/post/$postId'),
                );
                if (context.mounted) {
                  AppSnackbar.success('Link copied to clipboard');
                }
              },
            ),

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
                  Navigator.pop(context);
                  final confirmed = await ErrorHandler.showConfirmationDialog(
                    context,
                    title: 'Delete Post',
                    message:
                        'Are you sure you want to delete this post? This action cannot be undone.',
                    isDangerous: true,
                  );
                  if (confirmed && context.mounted) {
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
                  Navigator.pop(context);
                  final confirmed = await ErrorHandler.showConfirmationDialog(
                    context,
                    title: 'Block User',
                    message:
                        'Block @$username? They won\'t be able to interact with you.',
                    isDangerous: true,
                  );
                  if (confirmed && context.mounted) {
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
}

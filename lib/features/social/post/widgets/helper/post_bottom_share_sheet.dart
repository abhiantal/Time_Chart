import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_time_chart/features/chats/widgets/shared_content/chat_picker_sheet.dart';

import '../../models/post_model.dart';
import '../../providers/post_provider.dart';

class PostBottomShareSheet {
  static void show(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                _navigateToAnalytics(context, post.post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send via Direct Message'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDirectMessage(context, post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                _copyPostLink(context, post.post.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share to...'),
              onTap: () {
                Navigator.pop(context);
                _shareToExternal(context, post);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _navigateToDirectMessage(BuildContext context, FeedPost post) async {
    final chatIds = await showChatPicker(
      context,
      title: 'Send Post to...',
      multiSelect: true,
    );

    if (chatIds != null && chatIds.isNotEmpty && context.mounted) {
      final postProvider = context.read<PostProvider>();
      
      final successCount = await postProvider.sharePostViaChat(
        post: post.post,
        chatIds: chatIds,
      );

      if (context.mounted) {
        if (successCount > 0) {
          AppSnackbar.success('Post shared with $successCount chats');
        } else {
          AppSnackbar.error('Failed to share post');
        }
      }
    }
  }

  static void _copyPostLink(BuildContext context, String postId) async {
    await Clipboard.setData(
      ClipboardData(text: 'https://yourapp.com/post/$postId'),
    );
    if (context.mounted) {
      AppSnackbar.success('Link copied to clipboard');
    }
  }

  static void _shareToExternal(BuildContext context, FeedPost post) {
    final text = post.post.caption ?? 'Check out this post on Time Chart';
    final url = 'https://yourapp.com/post/${post.post.id}';
    Share.share('$text\n\n$url');
  }

  static void _navigateToAnalytics(BuildContext context, PostModel post) {
    context.pushNamed(
      'viewAnalytics',
      extra: {
        'targetType': 'post',
        'targetId': post.id,
        'targetOwnerId': post.userId,
      },
    );
  }
}

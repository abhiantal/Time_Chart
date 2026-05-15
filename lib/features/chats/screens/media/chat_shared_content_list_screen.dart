import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/error_handler.dart';
import '../../providers/chat_provider.dart';
import '../../model/chat_attachment_model.dart';
import '../../model/chat_message_model.dart';
import '../../model/chat_model.dart';
import '../../utils/chat_file_utils.dart';
import '../../utils/chat_date_utils.dart';
import '../../widgets/common/empty_state_illustration.dart';
import '../../widgets/common/loading_shimmer_list.dart';
import '../../widgets/common/user_avatar_cached.dart';

enum UnifiedSharedContentType {
  media,
  documents,
  links,
  buckets,
  dayTasks,
  weekTasks,
  goals,
  diaries,
  posts,
}

class ChatSharedContentListScreen extends StatefulWidget {
  final String chatId;
  final UnifiedSharedContentType type;
  final String? chatName;

  const ChatSharedContentListScreen({
    super.key,
    required this.chatId,
    required this.type,
    this.chatName,
  });

  @override
  State<ChatSharedContentListScreen> createState() =>
      _ChatSharedContentListScreenState();
}

class _ChatSharedContentListScreenState
    extends State<ChatSharedContentListScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      final provider = context.read<ChatProvider>();
      provider.setActiveChatId(widget.chatId);

      // Simple delay to simulate loading as most of these use mock data in their original files
      await Future.delayed(const Duration(milliseconds: 600));

      List<dynamic> results = [];

      switch (widget.type) {
        case UnifiedSharedContentType.documents:
          results = await provider.getAllDocuments();
          break;
        case UnifiedSharedContentType.links:
          results = await provider.getAllLinks();
          break;
        case UnifiedSharedContentType.media:
          results = await provider.getAllMedia();
          break;
        case UnifiedSharedContentType.buckets:
          final messages = await provider.getSharedContent(
            type: SharedContentType.bucketModel,
          );
          results = messages;
          break;
        case UnifiedSharedContentType.dayTasks:
          final messages = await provider.getSharedContent(
            type: SharedContentType.dayTask,
          );
          results = messages;
          break;
        case UnifiedSharedContentType.weekTasks:
          final messages = await provider.getSharedContent(
            type: SharedContentType.weeklyTask,
          );
          results = messages;
          break;
        case UnifiedSharedContentType.goals:
          final messages = await provider.getSharedContent(
            type: SharedContentType.longGoal,
          );
          results = messages;
          break;
        case UnifiedSharedContentType.diaries:
          final messages = await provider.getSharedContent(
            type: SharedContentType.diaryEntry,
          );
          results = messages;
          break;
        case UnifiedSharedContentType.posts:
          final messages = await provider.getSharedContent(
            type: SharedContentType.post,
          );
          results = messages;
          break;
      }

      if (mounted) {
        setState(() {
          _items = results;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(
        e,
        st,
        'ChatSharedContentListScreen.loadContent',
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadContent,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingShimmerList(itemCount: 5)
          : _items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildItem(context, item);
              },
            ),
    );
  }

  String _getTitle() {
    final prefix = widget.chatName != null ? '${widget.chatName} - ' : '';
    switch (widget.type) {
      case UnifiedSharedContentType.media:
        return '${prefix}Media';
      case UnifiedSharedContentType.documents:
        return '${prefix}Documents';
      case UnifiedSharedContentType.links:
        return '${prefix}Links';
      case UnifiedSharedContentType.buckets:
        return '${prefix}Buckets';
      case UnifiedSharedContentType.dayTasks:
        return '${prefix}Day Tasks';
      case UnifiedSharedContentType.weekTasks:
        return '${prefix}Week Tasks';
      case UnifiedSharedContentType.goals:
        return '${prefix}Goals';
      case UnifiedSharedContentType.diaries:
        return '${prefix}Diaries';
      case UnifiedSharedContentType.posts:
        return '${prefix}Posts';
    }
  }

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    switch (widget.type) {
      case UnifiedSharedContentType.media:
        icon = Icons.perm_media_outlined;
        title = 'No Media';
        break;
      case UnifiedSharedContentType.documents:
        icon = Icons.description_outlined;
        title = 'No Documents';
        break;
      case UnifiedSharedContentType.links:
        icon = Icons.link_off_rounded;
        title = 'No Links';
        break;
      default:
        icon = Icons.folder_open_rounded;
        title = 'No Shared Items';
    }
    return EmptyStateIllustration(
      type: EmptyStateType.custom,
      icon: icon,
      title: title,
      description: 'Items shared in this chat will appear here',
      compact: true,
    );
  }

  Widget _buildItem(BuildContext context, dynamic item) {
    if (item is ChatMessageAttachmentModel) {
      return _buildAttachmentItem(context, item);
    } else if (item is ExtractedLink) {
      return _buildLinkItem(context, item);
    } else if (item is ChatMessageModel) {
      return _buildSharedContentMessage(context, item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildAttachmentItem(
    BuildContext context,
    ChatMessageAttachmentModel doc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = ChatFileUtils.getFileIcon(doc.fileName);
    final iconColor = ChatFileUtils.getFileIconColor(context, doc.fileName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          doc.fileName ?? 'File',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${ChatFileUtils.formatFileSize(doc.fileSize)} • ${ChatDateUtils.formatRelativeTime(doc.createdAt)}',
          style: theme.textTheme.labelSmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // Document viewer logic or specific triggers
        },
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, ExtractedLink link) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => _launchURL(link.url),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.url,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (link.title != null) ...[
                const SizedBox(height: 8),
                Text(
                  link.title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
              ],
              Text(
                'Shared ${ChatDateUtils.formatRelativeTime(link.timestamp)}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedContentMessage(
    BuildContext context,
    ChatMessageModel message,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snapshot = message.sharedContentSnapshot ?? {};
    final title = snapshot['title'] ?? snapshot['name'] ?? 'Shared Item';
    final description = snapshot['description'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: UserAvatarCached(
          imageUrl: message.senderAvatar,
          name: message.senderName ?? 'User',
          size: 40,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            Text(
              'Shared by ${message.senderName ?? 'User'} • ${ChatDateUtils.formatRelativeTime(message.sentAt)}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
        onTap: () {
          // Open detail screen based on sharedContentType
          if (message.sharedContentType == SharedContentType.bucketModel) {
            context.pushNamed(
              'bucketDetailScreen',
              pathParameters: {'bucketId': message.sharedContentId!},
            );
          } else if (message.sharedContentType == SharedContentType.longGoal) {
            context.pushNamed(
              'longGoalDetailScreen',
              pathParameters: {'goalId': message.sharedContentId!},
            );
          } else if (message.sharedContentType == SharedContentType.dayTask) {
            context.pushNamed(
              'dayScheduleScreen',
              extra: {'initialDate': snapshot['scheduled_date']},
            );
          } else if (message.sharedContentType == SharedContentType.weeklyTask) {
            context.pushNamed(
              'weekTaskDetailScreen',
              pathParameters: {'taskId': message.sharedContentId!},
            );
          }
        },
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ================================================================
// FILE: lib/features/chat/widgets/search/search_result_tile.dart
// PURPOSE: Search result tile for chats, messages, contacts
// STYLE: WhatsApp-style search results
// ================================================================

import 'package:flutter/material.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';
import 'package:the_time_chart/features/chats/utils/chat_file_utils.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';

import '../../utils/chat_date_utils.dart';

class SearchResultTile extends StatelessWidget {
  final ChatSearchResult result;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const SearchResultTile({
    super.key,
    required this.result,
    this.isHighlighted = false,
    this.onTap,
  });

  factory SearchResultTile.chat({
    required ChatSearchResult result,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return SearchResultTile(
      result: result,
      isHighlighted: isHighlighted,
      onTap: onTap,
    );
  }

  factory SearchResultTile.message({
    required MessageSearchResult result,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    // Convert to ChatSearchResult
    final chatResult = ChatSearchResult(
      type: SearchResultType.message,
      id: result.message!.id,
      title: result.senderName ?? 'Message',
      subtitle: result.message!.textContent,
      imageUrl: result.message!.senderAvatar,
      timestamp: result.message!.sentAt,
      metadata: {
        'chat_id': result.message!.chatId,
        'sender_id': result.message!.senderId,
        'match_snippet': result.subtitle,
      },
      message: result.message,
    );

    return SearchResultTile(
      result: chatResult,
      isHighlighted: isHighlighted,
      onTap: onTap,
    );
  }

  factory SearchResultTile.document({
    required ChatMessageAttachmentModel attachment,
    VoidCallback? onTap,
  }) {
    final result = ChatSearchResult(
      type: SearchResultType.file,
      id: attachment.id,
      title: attachment.fileName ?? 'Document',
      subtitle:
          '${attachment.fileSize != null ? ChatFileUtils.formatFileSize(attachment.fileSize!) : ''} • ${ChatDateUtils.formatRelativeShort(attachment.createdAt)}',
      timestamp: attachment.createdAt,
      metadata: {'chat_id': attachment.chatId},
    );

    return SearchResultTile(result: result, onTap: onTap);
  }

  factory SearchResultTile.link({
    required ExtractedLink link,
    VoidCallback? onTap,
  }) {
    final domain = Uri.tryParse(link.url)?.host ?? link.url;
    final result = ChatSearchResult(
      type: SearchResultType.link,
      id: link.messageId,
      title: link.url,
      subtitle: domain,
      timestamp: link.timestamp,
      metadata: {'chat_id': link.chatId},
    );

    return SearchResultTile(result: result, onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: isHighlighted
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: _buildLeading(context, colorScheme),
        title: _buildTitle(theme, colorScheme),
        subtitle: _buildSubtitle(theme, colorScheme),
        trailing: _buildTrailing(theme, colorScheme),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, ColorScheme colorScheme) {
    if (result.imageUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(result.imageUrl!),
        backgroundColor: colorScheme.primaryContainer,
        radius: 24,
      );
    }

    switch (result.type) {
      case SearchResultType.chat:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        );
      case SearchResultType.message:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.message_rounded,
            color: colorScheme.onSecondaryContainer,
            size: 24,
          ),
        );
      case SearchResultType.contact:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_rounded,
            color: colorScheme.onTertiaryContainer,
            size: 24,
          ),
        );
      case SearchResultType.file:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.insert_drive_file_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        );
      case SearchResultType.link:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.link_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        );
      default:
        return const SizedBox(width: 48, height: 48);
    }
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      result.title,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme, ColorScheme colorScheme) {
    if (result.subtitle == null) return const SizedBox.shrink();

    return Text(
      result.subtitle!,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      maxLines: result.type == SearchResultType.message ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailing(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          ChatDateUtils.formatChatListTimeCompact(result.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        if (result.type == SearchResultType.message)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Message',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/chat_message_model.dart';
import '../../providers/chat_message_provider.dart';
import '../../utils/chat_scroll_controller.dart';
import '../../utils/chat_date_utils.dart';

class PinnedMessagesSheet extends StatelessWidget {
  final String chatId;
  final ChatScrollController scrollController;

  const PinnedMessagesSheet({
    super.key,
    required this.chatId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ChatMessageProvider>();
    final pinnedMessages = provider.pinnedMessages;

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.push_pin_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Pinned Messages',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pinnedMessages.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: pinnedMessages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.push_pin_outlined,
                          size: 48,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pinned messages',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pinnedMessages.length,
                    itemBuilder: (context, index) {
                      final message = pinnedMessages[index];
                      return _buildPinnedItem(context, message, provider);
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPinnedItem(
    BuildContext context,
    ChatMessageModel message,
    ChatMessageProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            Navigator.pop(context);
            // Scroll to the message
            await scrollController.scrollToMessage(message.id, highlight: true);

            // Auto-unpin as requested: "one user see that it automatcly unpin"
            // We'll unpin it after they've clicked to see it from the list too
            await provider.togglePinMessage(message.id, false);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.pinnedBy != null
                            ? 'Pinned by User'
                            : 'Pinned Message',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      ChatDateUtils.formatMessageTime(
                        message.pinnedAt ?? message.sentAt,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        provider.togglePinMessage(message.id, false);
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPinnedMessagesSheet(
  BuildContext context, {
  required String chatId,
  required ChatScrollController scrollController,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        PinnedMessagesSheet(chatId: chatId, scrollController: scrollController),
  );
}

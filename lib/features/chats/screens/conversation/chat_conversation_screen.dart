import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/features/chats/model/chat_attachment_model.dart';

import '../../model/chat_model.dart';
import '../../model/chat_message_model.dart';
import '../../providers/chat_message_provider.dart';
import '../../providers/chat_ui_provider.dart';
import '../../providers/chat_attachment_provider.dart';
import '../../utils/chat_scroll_controller.dart';
import '../../utils/chat_date_utils.dart';
import '../../utils/mention_text_controller.dart';
import '../../widgets/conversation/components/pinned_message_banner.dart';
import '../../widgets/input/chat_input_container.dart';
import '../../widgets/common/user_avatar_cached.dart';
import '../../widgets/common/connection_banner.dart';
import '../../widgets/conversation/bubbles/text_message_bubble.dart';
import '../../widgets/conversation/bubbles/image_message_bubble.dart';
import '../../widgets/conversation/bubbles/video_message_bubble.dart';
import '../../widgets/conversation/bubbles/voice_message_bubble.dart';
import '../../widgets/conversation/bubbles/document_message_bubble.dart';
import '../../widgets/conversation/bubbles/shared_content_bubble.dart';
import '../../widgets/conversation/bubbles/system_message_bubble.dart';
import '../../widgets/conversation/bubbles/deleted_message_bubble.dart';
import '../../widgets/conversation/components/message_date_header.dart';
import '../../widgets/conversation/components/message_actions_sheet.dart';
import 'widgets/chat_info_panel.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatId;
  final VoidCallback? onTapSharedDayTasks;

  const ChatConversationScreen({
    super.key,
    required this.chatId,
    this.onTapSharedDayTasks,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late ChatScrollController _scrollController;
  late MentionTextController _textController;
  late FocusNode _focusNode;

  Timer? _typingDebounceTimer;
  ChatMessageProvider? _chatMessageProvider;

  @override
  void initState() {
    super.initState();
    _scrollController = ChatScrollController();
    _textController = MentionTextController();
    _focusNode = FocusNode();

    _scrollController.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _saveDraft();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _typingDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _saveDraft() {
    if (_activeChatId != null && _chatMessageProvider != null) {
      _chatMessageProvider!.saveDraft(_activeChatId!, _textController.text);
    }
  }

  String? get _activeChatId => widget.chatId;

  Future<void> _initializeChat() async {
    _chatMessageProvider = context.read<ChatMessageProvider>();
    final provider = _chatMessageProvider!;
    if (!provider.initialized) {
      // In a real app, userId comes from AuthProvider
      // For now, let's assume it's initialized elsewhere or we can get it if needed.
    }
    await provider.openChat(widget.chatId);

    // Load draft
    final draft = provider.getDraft(widget.chatId);
    if (draft != null && draft.isNotEmpty) {
      _textController.text = draft;
    }

    // Initialize attachment & UI providers
    final attachmentProvider = context.read<ChatAttachmentProvider>();
    attachmentProvider.setActiveChatId(widget.chatId);

    final uiProvider = context.read<ChatUIProvider>();
    uiProvider.setActiveChatId(widget.chatId);
  }

  void _onScroll() {
    // Logic for FAB visibility could go here
  }

  void _onTyping() {
    context.read<ChatMessageProvider>().onTyping();
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatMessageProvider>().onStopTyping();
    });
  }

  void _toggleInfoPanel() {
    HapticFeedback.lightImpact();
    ChatInfoPanel.show(context, widget.chatId);
  }

  void _showActions(ChatMessageModel message) {
    MessageActionsSheet.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Consumer<ChatMessageProvider>(
      builder: (context, provider, _) {
        final chat = provider.activeChat;

        if (provider.state == ConversationState.error) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: Text('Error: ${provider.error}')),
          );
        }

        if (chat == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Column(
            children: [
              // --- AppBar Block ---
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    SizedBox(height: statusBarHeight),
                    _buildAppBar(context, chat, provider),
                    if (provider.pinnedMessages.isNotEmpty)
                      PinnedMessageBanner(
                        message: provider.pinnedMessages.first,
                        scrollController: _scrollController,
                      ),
                    if (!provider.isConnected) const ConnectionBanner(),
                  ],
                ),
              ),

              // --- Messages List ---
              Expanded(
                child: Consumer<ChatUIProvider>(
                  builder: (context, uiProvider, _) {
                    return Container(
                      decoration: uiProvider.getWallpaperDecoration(context),
                      child: _buildMessagesList(provider),
                    );
                  },
                ),
              ),

              // --- Input ---
              if (provider.canSendMessage)
                ChatInputContainer(
                  chatId: widget.chatId,
                  textController: _textController,
                  focusNode: _focusNode,
                  onTyping: _onTyping,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ChatModel chat,
    ChatMessageProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final otherUserId = chat.otherUserId;
    final isOnline = otherUserId != null && provider.isUserOnline(otherUserId);
    final typingUsers = provider.typingUserIds;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          GestureDetector(
            onTap: _toggleInfoPanel,
            child: Row(
              children: [
                UserAvatarCached(
                  imageUrl: chat.isOneOnOne
                      ? chat.otherUserAvatar
                      : chat.avatar,
                  name: chat.displayName,
                  size: 40,
                  isGroup: !chat.isOneOnOne,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildSubtitle(
                      chat,
                      isOnline,
                      typingUsers,
                      provider.members.length,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _toggleInfoPanel,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(
    ChatModel chat,
    bool isOnline,
    List<String> typingUsers,
    int memberCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (typingUsers.isNotEmpty) {
      return Text(
        'Typing...',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (chat.isOneOnOne) {
      return Text(
        isOnline ? 'Online' : 'Last seen recently',
        style: TextStyle(
          fontSize: 12,
          color: isOnline ? Colors.green : colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Text(
      '$memberCount members',
      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildMessagesList(ChatMessageProvider provider) {
    final messages = provider.messages;
    final chat = provider.activeChat;

    return ListView.builder(
      controller: _scrollController.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: messages.length,
      reverse: true,
      itemBuilder: (context, index) {
        final message = messages[index];

        bool showHeader = false;
        if (index == messages.length - 1) {
          showHeader = true;
        } else if (index < messages.length - 1) {
          final nextMessage = messages[index + 1];
          showHeader = ChatDateUtils.needsDateHeader(
            nextMessage.sentAt,
            message.sentAt,
          );
        }

        return Column(
          children: [
            if (showHeader) MessageDateHeader(dateTime: message.sentAt),
            if (chat != null) _buildMessageWithGrouping(messages, index, chat),
          ],
        );
      },
    );
  }

  Widget _buildMessageWithGrouping(
    List<ChatMessageModel> messages,
    int index,
    ChatModel chat,
  ) {
    final message = messages[index];
    final isMe = message.isMine;

    // We no longer use cluster grouping for visibility, showing on every message as requested
    final bool isGroupChat = chat.isGroup || chat.isCommunity;

    return _buildMessageBubble(
      message: message,
      isMe: isMe,
      chat: chat,
      // Always show name and avatar for received messages in groups/communities
      showName: !isMe && isGroupChat,
      showAvatar: !isMe && isGroupChat,
    );
  }

  Widget _buildMessageBubble({
    required ChatMessageModel message,
    required bool isMe,
    required ChatModel chat,
    required bool showName,
    required bool showAvatar,
  }) {
    if (message.isDeleted)
      return DeletedMessageBubble(message: message, isMe: isMe);
    if (message.isSystem) return SystemMessageBubble(message: message);

    final attachments = message.attachments;
    final firstAttachment = attachments.isNotEmpty
        ? attachments.first
        : message.placeholderAttachment;

    // Sender details from message
    final String? senderName = chat.isGroup ? message.senderName : null;
    final String? senderAvatar = chat.isGroup ? message.senderAvatar : null;

    // Fallback for missing media
    if (firstAttachment == null && message.isMediaMessage) {
      return TextMessageBubble(
        message: message.copyWith(
          textContent: 'Media attachment missing or still loading...',
        ),
        isMe: isMe,
        senderName: senderName,
        senderAvatar: senderAvatar,
        showName: showName,
        showAvatar: showAvatar,
        onLongPress: () => _showActions(message),
      );
    }

    // Prepare resolved attachments list for multi-image support
    final List<ChatMessageAttachmentModel> resolvedAttachments =
        attachments.isNotEmpty
        ? attachments
        : (firstAttachment != null ? [firstAttachment] : []);

    switch (message.type) {
      case ChatMessageType.text:
        return TextMessageBubble(
          message: message,
          isMe: isMe,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      case ChatMessageType.image:
        return ImageMessageBubble(
          message: message,
          isMe: isMe,
          attachments: resolvedAttachments,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      case ChatMessageType.video:
        return VideoMessageBubble(
          message: message,
          isMe: isMe,
          attachment: firstAttachment!,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      case ChatMessageType.voice:
        return VoiceMessageBubble(
          message: message,
          isMe: isMe,
          attachment: firstAttachment!,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      case ChatMessageType.document:
        return DocumentMessageBubble(
          message: message,
          isMe: isMe,
          attachment: firstAttachment!,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      case ChatMessageType.sharedContent:
        return SharedContentMessageBubble(
          message: message,
          isMe: isMe,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
      default:
        return TextMessageBubble(
          message: message,
          isMe: isMe,
          senderName: senderName,
          senderAvatar: senderAvatar,
          showName: showName,
          showAvatar: showAvatar,
          onLongPress: () => _showActions(message),
        );
    }
  }
}

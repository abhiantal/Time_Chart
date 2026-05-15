import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_message_provider.dart';
import '../../providers/chat_provider.dart';

class ChatDispatcherScreen extends StatefulWidget {
  final String chatId;

  const ChatDispatcherScreen({super.key, required this.chatId});

  @override
  State<ChatDispatcherScreen> createState() => _ChatDispatcherScreenState();
}

class _ChatDispatcherScreenState extends State<ChatDispatcherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveChat();
    });
  }

  Future<void> _resolveChat() async {
    final messageProvider = context.read<ChatMessageProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Check if initializing needed
    if (!messageProvider.initialized) {
      if (chatProvider.currentUserId != null) {
        await messageProvider.initialize(userId: chatProvider.currentUserId!);
      }
    }

    // Load chat if not already active
    if (messageProvider.activeChat?.id != widget.chatId) {
      await messageProvider.openChat(widget.chatId);
    }

    if (!mounted) return;

    final chat = messageProvider.activeChat;
    if (chat != null && chat.id == widget.chatId) {
      _redirectToChat(chat);
    }
  }

  void _redirectToChat(ChatModel chat) {
    // Determine screen based on chat type
    String routeName = 'personalChatScreen';
    if (chat.isCommunity) {
      routeName = 'communityChatScreen';
    } else if (chat.isGroup) {
      routeName = 'groupChatScreen';
    }

    context.pushReplacementNamed(
      routeName,
      pathParameters: {'chatId': chat.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<ChatMessageProvider>(
        builder: (context, provider, _) {
          if (provider.state == ConversationState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load chat: ${provider.error}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _resolveChat,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

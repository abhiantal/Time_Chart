import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/user_avatar_cached.dart';

class QrCodeScreen extends StatelessWidget {
  final String chatId;

  const QrCodeScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.read<ChatProvider>();
    
    final chat = provider.chats.firstWhere((c) => c.id == chatId, orElse: () => provider.archivedChats.firstWhere((c) => c.id == chatId, orElse: () => ChatModel(id: chatId, type: ChatType.group, name: 'Chat', createdBy: '', createdAt: DateTime.now(), updatedAt: DateTime.now())));

    final String joinUrl = 'https://thetimechart.com/join?c=$chatId';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const Text('QR Code'),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => Share.share(
                  'Join our chat on Time Chart: $joinUrl'))
        ],
      ),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        UserAvatarCached(imageUrl: chat.avatar, name: chat.displayName, size: 80, isGroup: chat.isGroup),
        const SizedBox(height: 16),
        Text(chat.displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: QrImageView(data: joinUrl, version: QrVersions.auto, size: 250.0)),
      ])),
    );
  }
}

// ================================================================
// FILE: lib/notifications/handlers/chat_notification_handler.dart
// Handles chat-specific notifications with user preference enforcement
// ================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import '../../../widgets/logger.dart';
import '../core/notification_handler_interface.dart';
import '../core/notification_types.dart';

class ChatNotificationHandler extends NotificationHandler {
  final ChatRepository _chatRepo = ChatRepository();

  @override
  String get handlerId => 'chat_notifications';

  @override
  List<NotificationType> get supportedTypes => [
    NotificationType.chatMessage,
    NotificationType.chatMention,
    NotificationType.chatInviteReceived,
  ];

  @override
  Future<bool> handleNotificationTap(
    BuildContext context,
    NotificationData data,
  ) async {
    logActivity('Chat Notification tapped: ${data.type}');

    final chatId = data.data['chat_id'] ?? data.targetId;
    if (chatId == null) {
      logW('⚠️ No chat ID in notification data');
      return false;
    }

    try {
      // Navigate to the specific chat
      context.pushNamed('chatDetailScreen', pathParameters: {'chatId': chatId});
      return true;
    } catch (e) {
      logE('❌ Navigation to chat failed: $e');
      return false;
    }
  }

  @override
  Future<bool> handleForegroundNotification(NotificationData data) async {
    logActivity('Chat Notification (Foreground): ${data.type}');
    // Default behavior is usually fine for foreground
    return true; 
  }

  @override
  Future<bool> handleBackgroundNotification(NotificationData data) async {
    logActivity('Chat Notification (Background): ${data.type}');
    return true;
  }

  @override
  Future<Map<String, dynamic>?> customNotificationDisplay(
    NotificationData data,
  ) async {
    final chatId = data.data['chat_id'] ?? data.targetId;
    if (chatId == null) return null;

    try {
      // Fetch chat metadata to check for vibration and preview settings
      final chat = await _chatRepo.getChatById(chatId);
      if (chat == null) return null;

      final bool showPreview = chat.metadata['show_preview'] as bool? ?? true;
      final bool vibrationEnabled = chat.metadata['vibration_enabled'] as bool? ?? true;

      return {
        'title': data.title,
        'body': showPreview ? data.body : 'New message from ${data.title}',
        'vibrate': vibrationEnabled,
        'playSound': true,
        'icon': '@mipmap/ic_launcher',
      };
    } catch (e) {
      logW('⚠️ Failed to fetch chat metadata for notification: $e');
      return null;
    }
  }
}

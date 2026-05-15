import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/notifications/core/notification_types.dart';

void main() {
  group('NotificationType', () {
    test('fromString should return correct type for valid string', () {
      expect(NotificationType.fromString('chat_message'), NotificationType.chatMessage);
      expect(NotificationType.fromString('day_task_reminder'), NotificationType.dayTaskReminder);
    });

    test('fromString should return defaultType for unknown string', () {
      expect(NotificationType.fromString('unknown_type'), NotificationType.defaultType);
    });

    test('NotificationData.fromRemoteMessage should parse valid data', () {
      final message = {
        'type': 'chat_message',
        'title': 'Hello',
        'body': 'How are you?',
        'targetId': '123',
      };
      final data = NotificationData.fromRemoteMessage(message);
      
      expect(data.type, 'chat_message');
      expect(data.notificationType, NotificationType.chatMessage);
      expect(data.title, 'Hello');
      expect(data.targetId, '123');
    });

    test('NotificationData.fromRemoteMessage should handle null values gracefully', () {
      final data = NotificationData.fromRemoteMessage({});
      expect(data.type, 'default');
      expect(data.title, '');
      expect(data.body, '');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';

void main() {
  group('ChatMessageModel', () {
    test('fromJson handles standard text message', () {
      final json = {
        'id': 'msg-1',
        'chat_id': 'chat-1',
        'sender_id': 'user-1',
        'type': 'text',
        'text_content': 'Hello world',
        'sent_at': '2024-03-25T10:00:00Z',
        'created_at': '2024-03-25T10:00:00Z',
        'updated_at': '2024-03-25T10:00:00Z',
        'status': 'sent',
      };

      final model = ChatMessageModel.fromJson(json, currentUserId: 'user-1');

      expect(model.id, 'msg-1');
      expect(model.type, ChatMessageType.text);
      expect(model.textContent, 'Hello world');
      expect(model.isMine, true);
    });

    test('fromJson handles boolean fields from integer (PowerSync)', () {
      final json = {
        'id': 'msg-1',
        'chat_id': 'chat-1',
        'sender_id': 'user-1',
        'is_edited': 1,
        'is_deleted': 0,
        'sent_at': '2024-03-25T10:00:00Z',
        'created_at': '2024-03-25T10:00:00Z',
        'updated_at': '2024-03-25T10:00:00Z',
      };

      final model = ChatMessageModel.fromJson(json);

      expect(model.isEdited, true);
      expect(model.isDeleted, false);
    });

    test('previewText returns correct value for each type', () {
      final base = ChatMessageModel.text(
        id: '1',
        chatId: '1',
        senderId: '1',
        text: 'test',
      );

      expect(base.previewText, 'test');
      
      final image = base.copyWith(type: ChatMessageType.image);
      expect(image.previewText, '📷 Image');

      final deleted = base.copyWith(isDeleted: true);
      expect(deleted.previewText, '🚫 This message was deleted');
    });

    test('toJson returns consistent map', () {
      final model = ChatMessageModel.text(
        id: '1',
        chatId: '1',
        senderId: '1',
        text: 'hello',
        sentAt: DateTime(2024, 3, 25),
      );

      final json = model.toJson();

      expect(json['id'], '1');
      expect(json['text_content'], 'hello');
      expect(json['type'], 'text');
    });
  });
}

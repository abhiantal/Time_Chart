import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/notifications/presentation/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('fromSyncedTable parses valid JSON correctly', () {
      final jsonRow = {
        'id': '002cfa4f-4cc0-470c-b4a4-780bb71433f5',
        'user_id': '040fa69d-fe30-41fa-a422-d261a865a7ce',
        'notification_info': '{"body": "The day is almost over. Take a moment to record your thoughts in your diary.", "data": {"screen": "diary_dashboard", "targetId": "", "image_url": ""}, "type": "diary_evening_reminder", "title": "📔 Reflection Time"}',
        'is_read': 0,
        'read_at': null,
        'created_at': '2026-05-13 10:22:06.303+00',
        'updated_at': '2026-05-13 10:22:06.318453+00'
      };

      final model = NotificationModel.fromSyncedTable(jsonRow);

      expect(model.id, '002cfa4f-4cc0-470c-b4a4-780bb71433f5');
      expect(model.userId, '040fa69d-fe30-41fa-a422-d261a865a7ce');
      expect(model.title, '📔 Reflection Time');
      expect(model.body, 'The day is almost over. Take a moment to record your thoughts in your diary.');
      expect(model.type, 'diary_evening_reminder');
      expect(model.isRead, false);
      expect(model.payload['screen'], 'diary_dashboard');
    });

    test('fromSyncedTable parses bool is_read correctly', () {
      final jsonRow = {
        'id': '002cfa4f-4cc0-470c-b4a4-780bb71433f5',
        'user_id': '040fa69d-fe30-41fa-a422-d261a865a7ce',
        'notification_info': '{"body": "Test", "type": "system", "title": "Test Title"}',
        'is_read': true,
        'created_at': '2026-05-13 10:22:06.303+00',
      };

      final model = NotificationModel.fromSyncedTable(jsonRow);
      expect(model.isRead, true);
    });

    test('fromSyncedTable fallback handles missing payload fields gracefully', () {
      final jsonRow = {
        'id': '002cfa4f-4cc0-470c-b4a4-780bb71433f5',
        'user_id': '040fa69d-fe30-41fa-a422-d261a865a7ce',
        'notification_info': '{}',
        'is_read': 0,
        'created_at': '2026-05-13 10:22:06.303+00',
      };

      final model = NotificationModel.fromSyncedTable(jsonRow);
      expect(model.title, 'Notification');
      expect(model.body, '');
      expect(model.type, 'system');
      expect(model.payload, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';

void main() {
  group('Sharing Logic Tests', () {
    test('PostModel correctly handles ID-only shared content', () {
      final json = {
        'id': 'post-123',
        'user_id': 'user-123',
        'post_type': 'text',
        'caption': 'Check out my task',
        'source_type': 'day_task',
        'source_id': 'task-456',
        'source_mode': 'live',
        'source_data': null, // This is what we want now
        'visibility': 'public',
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'comments_count': 0,
        'reposts_count': 0,
        'views_count': 0,
      };

      final post = PostModel.fromJson(json);

      expect(post.sourceType, equals('day_task'));
      expect(post.sourceId, equals('task-456'));
      expect(post.sourceData, isNull);
      expect(post.isLive, isTrue);
    });

    test('PostModel handles snapshot mode correctly', () {
       final json = {
        'id': 'post-789',
        'user_id': 'user-123',
        'post_type': 'text',
        'source_type': 'bucket',
        'source_id': 'bucket-101',
        'source_mode': 'snapshot',
        'source_data': null,
        'visibility': 'public',
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'comments_count': 0,
        'reposts_count': 0,
        'views_count': 0,
      };

      final post = PostModel.fromJson(json);
      expect(post.isLive, isFalse);
    });

    test('PostModel parses with missing social info gracefully', () {
       final json = {
        'id': 'post-000',
        'user_id': 'user-123',
        'post_type': 'text',
        'source_type': 'week_task',
        'source_id': 'week-1',
        'published_at': DateTime.now().toUtc().toIso8601String(),
      };

      final post = PostModel.fromJson(json);
      expect(post.sourceType, equals('week_task'));
      expect(post.sourceId, equals('week-1'));
    });
  });
}

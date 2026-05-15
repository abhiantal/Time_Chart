import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/analytics/dashboard/models/dashboard_model.dart';
import 'package:the_time_chart/features/analytics/competition/models/competition_model.dart';

void main() {
  group('Analytics Models Unit Tests', () {
    test('UserDashboard.fromJson and toJson', () {
      final jsonMap = {
        'id': 'test-id',
        'user_id': 'test-user-id',
        'overview': {
          'summary': {'total_points': 1000, 'current_streak': 5},
          'daily_tasks_stats': {'total_day_tasks': 10},
          'weekly_tasks_stats': {'total_week_tasks': 2},
          'long_goals_stats': {'total_long_goals': 1},
          'bucket_list_stats': {'total_bucket_items': 5},
        },
        'today': {
          'date': '2026-03-15T00:00:00.000',
          'day_name': 'Sunday',
          'diary_entry': {'has_entry': true, 'mood_rating': 8},
          'summary': {'total_points': 50},
        },
        'active_items': {'day_tasks': []},
        'progress_history': {'days': []},
        'weekly_history': {'weeks': []},
        'category_stats': {'categories': {}},
        'rewards': {'total_rewards': 5},
        'streaks': {'current': {'days': 5}},
        'mood': {'today_mood': {'rating': 8}},
        'recent_activity': [],
        'updated_at': '2026-03-15T12:00:00.000',
      };

      final model = UserDashboard.fromJson(jsonMap);
      expect(model.id, 'test-id');
      expect(model.overview.summary.totalPoints, 1000);
      expect(model.today.diaryEntry.moodRating, 8);

      final backToJson = model.toJson();
      expect(backToJson['id'], 'test-id');
      expect(backToJson['overview']['summary']['total_points'], 1000);
    });

    test('BattleChallenge.fromJson and toJson', () {
      final jsonMap = {
        'id': 'battle-id',
        'user_id': 'creator-id',
        'title': 'Test Battle',
        'status': 'active',
        'starts_at': '2026-03-15T00:00:00.000',
        'user_stats': {
          'profile': {'id': 'creator-id', 'username': 'testuser'},
          'diary_stats': {'diaryEntries': 10},
          'overview': {
            'summary': {'total_points': 500},
            'daily_tasks_stats': {},
            'weekly_tasks_stats': {},
            'long_goals_stats': {},
            'bucket_list_stats': {},
          }
        }
      };

      final model = BattleChallenge.fromJson(jsonMap);
      expect(model.id, 'battle-id');
      expect(model.title, 'Test Battle');
      expect(model.userStats?.profile.username, 'testuser');
      expect(model.userStats?.totalPoints, 500);

      final backToJson = model.toJson();
      expect(backToJson['id'], 'battle-id');
      expect(backToJson['user_stats']['profile']['username'], 'testuser');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/analytics/dashboard/models/dashboard_model.dart';
import 'package:the_time_chart/features/analytics/competition/models/competition_model.dart';

void main() {
  group('Analytics Models Unit Tests', () {
    test('DashboardSummary.fromJson correctly parses points and streaks', () {
      final json = {
        'points_today': 150,
        'current_streak': 5,
        'completion_rate_all': 85.5,
      };
      final summary = DashboardSummary.fromJson(json);
      expect(summary.pointsToday, equals(150));
      expect(summary.currentStreak, equals(5));
      expect(summary.completionRateAll, equals(85.5));
    });

    test('BattleMemberStats.fromJson parses nested profile and overview', () {
      final json = {
        'profile': {
          'username': 'tester',
          'competition_rank': 1,
        },
        'overview': {
          'summary': {'total_points': 1000},
          'daily_tasks_stats': {},
          'weekly_tasks_stats': {},
          'long_goals_stats': {},
          'bucket_list_stats': {},
        },
        'diary_stats': {
          'logesteStreak': 10,
        }
      };
      final stats = BattleMemberStats.fromJson(json);
      expect(stats.username, equals('tester'));
      expect(stats.competitionRank, equals(1));
      expect(stats.totalPoints, equals(1000));
      expect(stats.longestStreak, equals(10));
    });
  });
}

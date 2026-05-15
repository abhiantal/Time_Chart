import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/analytics/dashboard/models/dashboard_model.dart';
import 'package:the_time_chart/features/social/post/models/post_model.dart';
import 'package:the_time_chart/features/chats/model/chat_message_model.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart' as lg;
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart' as bm;
import 'package:the_time_chart/features/personal/task_model/day_tasks/models/day_task_model.dart' as dt;
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart' as wt;
import 'package:the_time_chart/user_settings/models/settings_model.dart' as us;

void main() {
  group('Global JSON Consistency Tests', () {
    test('DashboardModel toJson wraps lists in objects', () {
      final jsonInput = {
        'id': 'test',
        'user_id': 'user',
        'recent_activity': [{'id': '1', 'type': 'test', 'title': 'Activity'}],
        'today': {
          'buckets_entry': [{'id': '1', 'title': 'Bucket', 'is_done': false}],
        },
      };

      final dashboard = UserDashboard.fromJson(jsonInput);
      final jsonOutput = dashboard.toJson();
      
      expect(jsonOutput['recent_activity'], isA<Map<String, dynamic>>());
      expect(jsonOutput['recent_activity']['items'], isA<List>());
      
      expect(jsonOutput['today']['buckets_entry'], isA<Map<String, dynamic>>());
      expect(jsonOutput['today']['buckets_entry']['items'], isA<List>());
    });

    test('PostModel toJson wraps lists in objects', () {
      final jsonInput = {
        'id': 'post1',
        'user_id': 'user1',
        'post_type': 'text',
        'caption': 'Hello',
        'media': {'items': []},
        'edit_history': ['v1'],
      };

      final post = PostModel.fromJson(jsonInput);
      final jsonOutput = post.toJson();
      
      expect(jsonOutput['media'], isA<Map<String, dynamic>>());
      expect(jsonOutput['media']['items'], isA<List>());
      
      expect(jsonOutput['edit_history'], isA<Map<String, dynamic>>());
      expect(jsonOutput['edit_history']['items'], isA<List>());
    });

    test('ChatMessageModel toJson wraps attachments', () {
      final jsonInput = {
        'id': 'msg1',
        'chat_id': 'chat1',
        'sender_id': 'user1',
        'text_content': 'Hi',
        'attachments_data': [],
      };

      final message = ChatMessageModel.fromJson(jsonInput);
      final jsonOutput = message.toJson();
      
      expect(jsonOutput['attachments'], isA<Map<String, dynamic>>());
      expect(jsonOutput['attachments']['items'], isA<List>());
    });

    test('BucketModel toJson wraps checklist', () {
      final jsonInput = {
        'id': 'b1',
        'user_id': 'u1',
        'title': 'Bucket',
        'details': {'media_url': []},
        'checklist': [],
      };

      final bucket = bm.BucketModel.fromJson(jsonInput);
      final jsonOutput = bucket.toJson();
      
      expect(jsonOutput['checklist'], isA<Map<String, dynamic>>());
      expect(jsonOutput['checklist']['items'], isA<List>());
      
      expect(jsonOutput['details']['media_url'], isA<Map<String, dynamic>>());
      expect(jsonOutput['details']['media_url']['items'], isA<List>());
    });

    test('LongGoalModel toJson wraps indicators and logs', () {
      final jsonInput = {
        'id': 'g1',
        'user_id': 'u1',
        'title': 'Goal',
        'indicators': {'weekly_plans': []},
        'goal_log': {'weekly_logs': []},
      };

      final goal = lg.LongGoalModel.fromJson(jsonInput);
      final jsonOutput = goal.toJson();
      
      final indicatorsJson = jsonOutput['indicators'] as Map<String, dynamic>;
      expect(indicatorsJson['weekly_plans'], isA<Map<String, dynamic>>());
      expect(indicatorsJson['weekly_plans']['items'], isA<List>());
      
      final logJson = jsonOutput['goal_log'] as Map<String, dynamic>;
      expect(logJson['weekly_logs'], isA<Map<String, dynamic>>());
      expect(logJson['weekly_logs']['items'], isA<List>());
    });

    test('DayTaskModel toJson wraps feedback', () {
      final jsonInput = {
        'task_id': 'dt1',
        'user_id': 'u1',
        'feedback': {'comments': []},
      };

      final task = dt.DayTaskModel.fromJson(jsonInput);
      final jsonOutput = task.toJson();
      
      expect(jsonOutput['feedback'], isA<Map<String, dynamic>>());
      expect(jsonOutput['feedback']['comments'], isA<Map<String, dynamic>>());
      expect(jsonOutput['feedback']['comments']['items'], isA<List>());
    });

    test('WeekTaskModel toJson wraps progress and feedback', () {
      final jsonInput = {
        'task_id': 'wt1',
        'user_id': 'u1',
        'feedback': {'daily_progress_list': []},
      };

      final task = wt.WeekTaskModel.fromJson(jsonInput);
      final jsonOutput = task.toJson();
      
      expect(jsonOutput['feedback'], isA<Map<String, dynamic>>());
      expect(jsonOutput['feedback']['daily_progress_list'], isA<Map<String, dynamic>>());
      expect(jsonOutput['feedback']['daily_progress_list']['items'], isA<List>());
    });

    test('UserSettings toJson wraps days and user lists', () {
      final jsonInput = {
        'id': 's1',
        'user_id': 'u1',
        'notifications': {
          'quiet_hours': {
            'days': ['monday'],
          },
        },
        'privacy': {
          'blocked_users': ['user2'],
        },
        'tasks': {
          'working_days': ['monday'],
        },
      };

      final settings = us.UserSettings.fromJson(jsonInput);
      final jsonOutput = settings.toJson();
      
      final notifJson = jsonOutput['notifications'] as Map<String, dynamic>;
      expect(notifJson['quiet_hours']['days'], isA<Map<String, dynamic>>());
      expect(notifJson['quiet_hours']['days']['items'], isA<List>());
      
      final privacyJson = jsonOutput['privacy'] as Map<String, dynamic>;
      expect(privacyJson['blocked_users'], isA<Map<String, dynamic>>());
      expect(privacyJson['blocked_users']['items'], isA<List>());
      
      final taskJson = jsonOutput['tasks'] as Map<String, dynamic>;
      expect(taskJson['working_days'], isA<Map<String, dynamic>>());
      expect(taskJson['working_days']['items'], isA<List>());
    });
  });
}

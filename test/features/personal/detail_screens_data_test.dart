import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart' as wt;
import 'package:the_time_chart/features/personal/task_model/week_task/screens/week_task_detail_screen.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart' as lg;
import 'package:the_time_chart/features/personal/task_model/long_goal/screens/long_goal_detail_screen.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart' as bm;
import 'package:the_time_chart/features/personal/bucket_model/screen/bucket_detail_screen.dart';

void main() {
  group('Detail Screens Data Visibility Tests', () {
    
    testWidgets('WeekTaskDetailScreen shows Description even when empty', (WidgetTester tester) async {
      final task = wt.WeekTaskModel.fromJson({
        'task_id': '1',
        'user_id': 'u1',
        'category_type': 'test',
        'sub_types': 'test',
        'about_task': {'task_name': 'Test Task', 'task_description': ''},
        'indicators': {'status': 'pending', 'priority': 'medium'},
        'timeline': {
          'task_days': 'monday',
          'starting_date': DateTime.now().toIso8601String(),
          'expected_ending_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'starting_time': DateTime.now().toIso8601String(),
          'ending_time': DateTime.now().toIso8601String(),
          'task_duration': '1 hour',
        },
        'feedback': {'daily_progress_list': []},
        'metadata': {'progress': 0, 'rating': 0, 'points_earned': 0},
      });

      await tester.pumpWidget(MaterialApp(
        home: WeekTaskDetailScreen(task: task),
      ));
      
      await tester.pumpAndSettle();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('LongGoalDetailScreen shows Start/End Time even when slot is null', (WidgetTester tester) async {
      final goal = lg.LongGoalModel.fromJson({
        'id': '1',
        'user_id': 'u1',
        'title': 'Test Goal',
        'description': {'need': '', 'motivation': '', 'outcome': ''},
        'timeline': {
          'is_unspecified': false,
          'work_schedule': {
            'work_days': ['Monday'], 
            'hours_per_day': 2, 
            'preferred_time_slot': null
          }
        },
        'indicators': {'status': 'pending', 'priority': 'medium', 'weekly_plans': []},
        'metrics': {'total_days': 10, 'completed_days': 0, 'tasks_pending': 5},
        'analysis': {'average_progress': 0, 'average_rating': 0, 'points_earned': 0, 'suggestions': []},
        'goal_log': {'weekly_logs': []},
      });

      await tester.pumpWidget(MaterialApp(
        home: LongGoalDetailScreen(goal: goal),
      ));

      await tester.pumpAndSettle();
      
      // Tap on Timeline tab - use a more specific finder if possible
      final timelineTab = find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Timeline'),
      );
      await tester.tap(timelineTab);
      await tester.pumpAndSettle();

      final startTimeFinder = find.text('Start Time');
      await tester.scrollUntilVisible(startTimeFinder, 500.0, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();

      expect(startTimeFinder, findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(2));
    });

    testWidgets('BucketDetailScreen shows Description/Motivation/Outcome even when empty', (WidgetTester tester) async {
      final bucket = bm.BucketModel.fromJson({
        'id': '1',
        'user_id': 'u1',
        'title': 'Test Bucket',
        'details': {'description': '', 'motivation': '', 'out_come': ''},
        'timeline': {
          'is_unspecified': true,
          'added_date': DateTime.now().toIso8601String(),
        },
        'metadata': {
          'priority': 'medium',
          'average_rating': 0.0,
          'average_progress': 0.0,
        },
        'checklist': [],
      });

      await tester.pumpWidget(MaterialApp(
        home: BucketDetailScreen(bucket: bucket),
      ));
      
      await tester.pumpAndSettle();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Motivation'), findsOneWidget);
      expect(find.text('Outcome'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });
  });
}

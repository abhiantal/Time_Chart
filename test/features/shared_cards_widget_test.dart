import 'package:flutter/material.dart' hide Feedback;
import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/post_shared/day_task/post_shared_day_task_card.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/models/day_task_model.dart' as dt;

void main() {
  group('Shared Cards Widget Tests', () {
    testWidgets('PostSharedDayTaskCard renders task details correctly', (WidgetTester tester) async {
      final now = DateTime.now();
      final task = dt.DayTaskModel(
        id: 'task-123',
        userId: 'user-123',
        categoryId: 'cat-123',
        categoryType: 'Work',
        subTypes: 'Coding',
        aboutTask: dt.AboutTask(
          taskName: 'Refactor Social Sharing',
          taskDescription: 'Move to ID-based storage',
        ),
        indicators: dt.Indicators(
          status: 'inProgress',
          priority: 'high',
        ),
        timeline: dt.Timeline(
          taskDate: '2026-04-09',
          startingTime: now,
          endingTime: now.add(const Duration(hours: 2)),
          overdue: false,
          isUnspecified: false,
        ),
        feedback: dt.Feedback(comments: []),
        metadata: dt.Metadata(
          progress: 50,
          pointsEarned: 20,
          rating: 4.5,
          taskColor: '#FF5733',
          isComplete: false,
        ),
        socialInfo: dt.SocialInfo(
          isPosted: true,
          posted: dt.PostedInfo(live: true, time: now),
        ),
        shareInfo: dt.ShareInfo(
          isShare: true,
        ),
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostSharedDayTaskCard(task: task),
          ),
        ),
      );

      // Verify task name is displayed
      expect(find.text('Refactor Social Sharing'), findsOneWidget);
    });
  });
}

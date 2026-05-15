import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/models/day_task_model.dart';

void main() {
  group('DayTaskModel Evaluation Logic', () {
    test('evaluateTask - Missed Task (No feedback, past 23:59)', () {
      final taskDate = DateTime.now().subtract(const Duration(days: 1));
      final taskDateStr = taskDate.toIso8601String().split('T')[0];
      
      final task = DayTaskModel(
        id: 'test_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        categoryType: 'Type',
        subTypes: 'Sub',
        aboutTask: AboutTask(taskName: 'Missed Task'),
        indicators: Indicators(status: 'pending', priority: 'high'),
        timeline: Timeline(
          taskDate: taskDateStr,
          startingTime: taskDate.add(const Duration(hours: 9)),
          endingTime: taskDate.add(const Duration(hours: 10)),
          overdue: false,
          isUnspecified: false,
        ),
        feedback: Feedback(comments: []),
        metadata: Metadata(
          progress: 0,
          pointsEarned: 0,
          rating: 0,
          isComplete: false,
          taskColor: '#667EEA',
        ),
        socialInfo: SocialInfo(isPosted: false),
        shareInfo: ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final evaluation = task.evaluateTask(now: DateTime.now());

      expect(evaluation['status'], 'missed');
      expect(evaluation['final_score'], -100);
      expect(evaluation['penalty'], 100);
      expect(evaluation['points_earned'], 0);
    });

    test('evaluateTask - Completed Task with Feedback', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 2));
      final endTime = now.subtract(const Duration(hours: 1));
      final taskDateStr = now.toIso8601String().split('T')[0];

      final task = DayTaskModel(
        id: 'test_2',
        userId: 'user_1',
        categoryId: 'cat_1',
        categoryType: 'Type',
        subTypes: 'Sub',
        aboutTask: AboutTask(taskName: 'Completed Task'),
        indicators: Indicators(status: 'pending', priority: 'medium'),
        timeline: Timeline(
          taskDate: taskDateStr,
          startingTime: startTime,
          endingTime: endTime,
          overdue: false,
          isUnspecified: false,
        ),
        feedback: Feedback(comments: [
          Comment(
            feedbackNumber: '1',
            text: 'Started working',
            timestamp: startTime.add(const Duration(minutes: 19)),
          ),
          Comment(
            feedbackNumber: '2',
            text: 'Finished work',
            timestamp: endTime.subtract(const Duration(minutes: 5)),
            mediaUrl: 'https://example.com/image.jpg',
          ),
        ]),
        metadata: Metadata(
          progress: 100,
          pointsEarned: 0,
          rating: 0,
          isComplete: false,
          taskColor: '#667EEA',
        ),
        socialInfo: SocialInfo(isPosted: false),
        shareInfo: ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final evaluation = task.evaluateTask(now: now);

      expect(evaluation['status'], 'completed');
      // Points calculation remains the same
      expect(evaluation['points_earned'], 47);
    });

    test('evaluateTask - Overdue Penalties', () {
      final now = DateTime.now();
      final taskDateStr = now.toIso8601String().split('T')[0];
      final endTime = now.subtract(const Duration(hours: 2)); // 2 hours overdue

      final task = DayTaskModel(
        id: 'test_3',
        userId: 'user_1',
        categoryId: 'cat_1',
        categoryType: 'Type',
        subTypes: 'Sub',
        aboutTask: AboutTask(taskName: 'Overdue Task'),
        indicators: Indicators(status: 'pending', priority: 'low'),
        timeline: Timeline(
          taskDate: taskDateStr,
          startingTime: endTime.subtract(const Duration(hours: 1)),
          endingTime: endTime,
          overdue: true,
          isUnspecified: false,
        ),
        feedback: Feedback(comments: [
          Comment(feedbackNumber: '1', text: 'Late start', timestamp: now),
        ]),
        metadata: Metadata(
          progress: 100,
          pointsEarned: 0,
          rating: 0,
          isComplete: false,
          taskColor: '#667EEA',
        ),
        socialInfo: SocialInfo(isPosted: false),
        shareInfo: ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final evaluation = task.evaluateTask(now: now);

      // Penalty: 2 hours * 10 = 20
      expect(evaluation['breakdown']['overduePenalty'], 20);
    });
  });

  group('DayTaskModel CopyWith and Json', () {
    test('toJson and fromJson parity', () {
      final task = DayTaskModel(
        id: 'uuid',
        userId: 'user',
        categoryId: 'cat',
        categoryType: 'Type',
        subTypes: 'Sub',
        aboutTask: AboutTask(taskName: 'Name', taskDescription: 'Desc'),
        indicators: Indicators(status: 'pending', priority: 'high'),
        timeline: Timeline(
          taskDate: '2024-05-02',
          startingTime: DateTime(2024, 5, 2, 9),
          endingTime: DateTime(2024, 5, 2, 10),
          overdue: false,
          isUnspecified: false,
        ),
        feedback: Feedback(comments: []),
        metadata: Metadata(
          progress: 0,
          pointsEarned: 0,
          rating: 0,
          isComplete: false,
          taskColor: '#667EEA',
        ),
        socialInfo: SocialInfo(isPosted: false),
        shareInfo: ShareInfo(isShare: false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = task.toJson();
      final fromJson = DayTaskModel.fromJson(json);

      expect(fromJson.id, task.id);
      expect(fromJson.aboutTask.taskName, task.aboutTask.taskName);
    });
  });
}

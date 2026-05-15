import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/providers/day_task_provider.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/repositories/day_task_repository.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/services/day_task_ai_service.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/models/day_task_model.dart';

class MockDayTaskRepository extends Mock implements DayTaskRepository {}
class MockDayTaskAIService extends Mock implements DayTaskAIService {}

void main() {
  late DayTaskProvider provider;

  setUp(() {
    provider = DayTaskProvider();
  });

  group('DayTaskProvider', () {
    test('initial state is correct', () {
      expect(provider.tasks, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('canAddMediaFeedback returns true for empty feedback', () {
      final task = DayTaskModel(
        id: '1',
        userId: 'u',
        categoryId: 'c',
        categoryType: 'T',
        subTypes: 'S',
        aboutTask: AboutTask(taskName: 'Task'),
        indicators: Indicators(status: 'pending', priority: 'low'),
        timeline: Timeline(
          taskDate: '2024-05-02',
          startingTime: DateTime.now(),
          endingTime: DateTime.now(),
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

      expect(provider.canAddMediaFeedback(task), isTrue);
    });

    test('canAddMediaFeedback returns false if media added < 20 mins ago', () {
      final now = DateTime.now();
      final task = DayTaskModel(
        id: '1',
        userId: 'u',
        categoryId: 'c',
        categoryType: 'T',
        subTypes: 'S',
        aboutTask: AboutTask(taskName: 'Task'),
        indicators: Indicators(status: 'pending', priority: 'low'),
        timeline: Timeline(
          taskDate: '2024-05-02',
          startingTime: now.subtract(const Duration(hours: 1)),
          endingTime: now,
          overdue: false,
          isUnspecified: false,
        ),
        feedback: Feedback(comments: [
          Comment(
            feedbackNumber: '1',
            text: 'text',
            mediaUrl: 'url',
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
        ]),
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

      expect(provider.canAddMediaFeedback(task), isFalse);
    });
  });
}

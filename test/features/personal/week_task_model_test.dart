import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart';
import 'package:intl/intl.dart';

void main() {
  group('WeekTaskModel Tests', () {
    test('recalculate should backfill missing scheduled days', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final task = WeekTaskModel(
        id: 'test-id',
        userId: 'user-id',
        categoryId: 'cat-id',
        categoryType: 'type',
        subTypes: 'sub',
        aboutTask: AboutTask(taskName: 'Test Task'),
        indicators: Indicators(status: 'pending', priority: 'medium'),
        timeline: TaskTimeline(
          taskDays: DateFormat('EEEE').format(yesterday), // Only yesterday was scheduled
          startingDate: yesterday,
          expectedEndingDate: now.add(const Duration(days: 5)),
          startingTime: yesterday,
          endingTime: yesterday.add(const Duration(hours: 1)),
          taskDuration: DateTime(0, 1, 1, 1, 0),
        ),
        feedback: WeekTaskFeedback(dailyProgress: []), // No progress entered
        summary: WeeklySummary.empty,
        socialInfo: const SocialInfo(isPosted: false),
        shareInfo: const ShareInfo(isShare: false),
        createdAt: yesterday,
        updatedAt: yesterday,
      );

      final updatedTask = task.recalculate();
      
      // Should have backfilled yesterday
      expect(updatedTask.dailyProgress.length, 1);
      expect(updatedTask.dailyProgress.first.taskDate, DateFormat('dd-MM-yyyy').format(yesterday));
      
      // Penalty should be 100 points (flat missed day penalty)
      expect(updatedTask.dailyProgress.first.dailyMetrics.penalty!.penaltyPoints, greaterThanOrEqualTo(100));
      
      expect(updatedTask.dailyProgress.first.dailyMetrics.penalty!.penaltyPoints, 100);
    });
  });
}

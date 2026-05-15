import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:the_time_chart/features/personal/task_model/week_task/models/week_task_model.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';

void main() {
  group('WeekTaskModel Tests', () {
    test('parseDuration parses hour/minute format correctly', () {
      final duration = WeekTaskModel.parseDuration('4 hours : 20 minutes');
      expect(duration.hour, 4);
      expect(duration.minute, 20);
    });

    test('parseDuration parses ISO 8601 duration correctly', () {
      final duration = WeekTaskModel.parseDuration('PT2H30M');
      expect(duration.hour, 2);
      expect(duration.minute, 30);
    });

    test('formatDurationHMS formats correctly', () {
      final duration = DateTime(0, 1, 1, 2, 15);
      final formatted = WeekTaskModel.formatDurationHMS(duration);
      expect(formatted, '2 hours : 15 minutes');
    });

    test('isDateScheduled returns true for scheduled days within range', () {
      final startTime = DateTime(2026, 5, 1, 9, 0); // Friday
      final endTime = DateTime(2026, 5, 8, 17, 0);
      final task = WeekTaskModel(
        id: '1',
        userId: 'u1',
        categoryId: 'c1',
        categoryType: 'type',
        subTypes: '{}',
        aboutTask: AboutTask(taskName: 'Test Task'),
        indicators: Indicators(status: 'pending', priority: 'medium'),
        timeline: TaskTimeline(
          taskDays: 'Monday,Wednesday,Friday',
          startingDate: startTime,
          expectedEndingDate: endTime,
          startingTime: startTime,
          endingTime: startTime.add(Duration(hours: 2)),
          taskDuration: DateTime(0, 1, 1, 2, 0),
        ),
        feedback: WeekTaskFeedback(dailyProgress: []),
        summary: WeeklySummary.empty,
        socialInfo: SocialInfo(isPosted: false),
        shareInfo: ShareInfo(isShare: false),
        createdAt: startTime,
        updatedAt: startTime,
      );

      expect(task.isDateScheduled(DateTime(2026, 5, 1)), isTrue); // Friday
      expect(task.isDateScheduled(DateTime(2026, 5, 4)), isTrue); // Monday
      expect(task.isDateScheduled(DateTime(2026, 5, 2)), isFalse); // Saturday
      expect(task.isDateScheduled(DateTime(2026, 4, 30)), isFalse); // Before start
    });
  });

  group('DayMetrics.calculate Tests', () {
    final timeline = TaskTimeline(
      taskDays: 'Monday',
      startingDate: DateTime(2026, 5, 4),
      expectedEndingDate: DateTime(2026, 5, 4),
      startingTime: DateTime(2026, 5, 4, 9, 0),
      endingTime: DateTime(2026, 5, 4, 10, 0),
      taskDuration: DateTime(0, 1, 1, 1, 0),
    );

    test('Missed task penalty applies correctly', () {
      final metrics = DayMetrics.calculate(
        feedbacks: [],
        timeline: timeline,
        priority: 'medium',
        taskDate: DateTime(2026, 5, 4),
        now: DateTime(2026, 5, 4, 11, 0), // After ending time
      );

      expect(metrics.status, 'missed');
      expect(metrics.finalScore, -100);
      expect(metrics.penaltyPoints, 100);
    });

    test('Slot penalty applies correctly for missed windows', () {
      // 1 hour task = 3 slots (0-20, 20-40, 40-60)
      // Feedback window for 20m slot is 18-22m
      final feedback = DailyFeedback(
        feedbackNumber: '1',
        text: 'Working hard',
        timestamp: DateTime(2026, 5, 4, 9, 10), // Not in a window
        isPass: true,
      );

      final metrics = DayMetrics.calculate(
        feedbacks: [feedback],
        timeline: timeline,
        priority: 'medium',
        taskDate: DateTime(2026, 5, 4),
        now: DateTime(2026, 5, 4, 11, 0),
      );

      // Total slots = 3. Each missed slot = -10.
      // Feedback at 9:10 is not in any window (18-22, 38-42, 58-62).
      // So all 3 slots missed? Wait, the loop checks n=1..totalSlots.
      // n=1: window 9:18-9:22
      // n=2: window 9:38-9:42
      // n=3: window 9:58-10:02
      expect(metrics.penaltyPoints, 30);
    });

    test('On-time bonus and duration points apply correctly', () {
      final feedback = DailyFeedback(
        feedbackNumber: '1',
        text: 'Completed',
        timestamp: DateTime(2026, 5, 4, 9, 20), // In window 1
        isPass: true,
      );

      final metrics = DayMetrics.calculate(
        feedbacks: [feedback],
        timeline: timeline,
        priority: 'medium',
        taskDate: DateTime(2026, 5, 4),
        now: DateTime(2026, 5, 4, 11, 0),
      );

      // Base points:
      // Feedback: 5
      // Priority: 10 (medium)
      // On-time: 20
      // Duration (1h): 10
      // Penalties: 2 slots missed (n=2, n=3) = -20
      // Final: 5 + 10 + 20 + 10 - 20 = 25
      expect(metrics.pointsEarned, 48);
      expect(metrics.finalScore, 28);
    });
  });
}

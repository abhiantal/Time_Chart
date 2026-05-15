import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart';
import 'package:intl/intl.dart';

void main() {
  group('LongGoalModel Tests', () {
    test('recalculate should backfill missing scheduled days and apply penalty', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      
      // Goal started 3 days ago, scheduled every day
      final task = LongGoalModel(
        id: 'test-id',
        userId: 'user-id',
        title: 'Long Goal Test',
        description: const GoalDescription(need: '', motivation: '', outcome: ''),
        timeline: GoalTimeline(
          isUnspecified: false,
          startDate: threeDaysAgo,
          endDate: now.add(const Duration(days: 30)),
          workSchedule: WorkSchedule(
            workDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
            hoursPerDay: 2,
          ),
        ),
        indicators: Indicators(
          status: 'pending',
          priority: 'medium',
          weeklyPlans: [
            WeeklyPlan(weekId: 'w1', weeklyGoal: 'Goal 1', mood: 'Happy', isCompleted: false),
          ],
        ),
        metrics: const GoalMetrics(totalDays: 30, completedDays: 0, tasksPending: 30),
        analysis: GoalAnalysis.empty,
        goalLog: const GoalLog(weeklyLogs: []),
        socialInfo: const SocialInfo(isPosted: false),
        shareInfo: const ShareInfo(isShare: false),
        createdAt: threeDaysAgo,
        updatedAt: threeDaysAgo,
      );

      final updatedTask = task.recalculate();
      
      // Should have backfilled 3 days (3 days ago, 2 days ago, 1 day ago) + today?
      // _backfillGoalLog checks up to min(today, endDate).
      // So 4 days if today is also scheduled.
      expect(updatedTask.goalLog.weeklyLogs.length, 1);
      
      final week1 = updatedTask.goalLog.weeklyLogs.first;
      // Depending on exactly when 'now' is, it's at least 3 days.
      expect(week1.dailyFeedback.length, greaterThanOrEqualTo(3));
      
      // Check for -50 penalty on one of the backfilled days
      final missedDay = week1.dailyFeedback.first;
      expect(missedDay.feedbackCount, '0');
      expect(missedDay.dailyProgress, isNotNull);
      
      // DailyProgress.calculateForDay handles the penalty
      // In recalculate loop, we call DailyProgress.calculateForDay(feedback)
      final dp = DailyProgress.calculateForDay(
        weekId: 'w1',
        dayFeedbacks: [missedDay],
        hoursPerDay: 2,
      );
      
      expect(dp.penalty, isNotNull);
      expect(dp.penalty!.penaltyPoints, 50);
    });
  });
}

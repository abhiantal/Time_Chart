import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';

void main() {
  group('LongGoalModel Evaluation Tests', () {
    late LongGoalModel goal;
    final now = DateTime(2026, 5, 2);

    setUp(() {
      goal = LongGoalModel(
        id: 'test_goal',
        userId: 'user_1',
        title: 'Learn Flutter',
        description: const GoalDescription(
          need: 'Job',
          motivation: 'Money',
          outcome: 'Developer',
        ),
        timeline: GoalTimeline(
          isUnspecified: false,
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 31),
          workSchedule: WorkSchedule(
            workDays: ['monday', 'wednesday', 'friday'],
            hoursPerDay: 2,
            preferredTimeSlot: TimeSlot(
              startingTime: DateTime(2026, 5, 2, 9, 0),
              endingTime: DateTime(2026, 5, 2, 10, 0),
            ),
          ),
        ),
        indicators: const Indicators(
          status: 'inProgress',
          priority: 'high',
          weeklyPlans: [
            WeeklyPlan(weekId: 'w1', weeklyGoal: 'Setup', mood: 'focused', isCompleted: false),
          ],
        ),
        metrics: const GoalMetrics(totalDays: 31, completedDays: 0, tasksPending: 1),
        analysis: GoalAnalysis.empty,
        goalLog: GoalLog(
          weeklyLogs: [
            WeeklyGoalLog(
              weekId: 'w1',
              dailyFeedback: [
                DailyFeedback(
                  weekId: 'w1',
                  feedbackDay: DateTime(2026, 5, 1, 9, 5),
                  feedbackCount: '1',
                  feedbackText: 'Working on setup',
                ),
              ],
            ),
          ],
        ),
        socialInfo: const SocialInfo(isPosted: false),
        shareInfo: const ShareInfo(isShare: false),
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );
    });

    test('isDateScheduled returns true for work days', () {
      final mon = DateTime(2026, 5, 4); // Monday
      final tue = DateTime(2026, 5, 5); // Tuesday
      expect(goal.isDateScheduled(mon), isTrue);
      expect(goal.isDateScheduled(tue), isFalse);
    });

    test('evaluateGoal calculates points correctly', () {
      final eval = goal.evaluateGoal(now: now);
      expect(eval['status'], equals('completed'));
      expect(eval['points_earned'], greaterThan(0));
      expect(eval['final_score'], equals(eval['points_earned']));
    });

    test('isOverdue returns true after endDate', () {
      final lateGoal = goal.copyWith(
        timeline: goal.timeline.copyWith(endDate: DateTime(2026, 5, 1)),
      );
      expect(lateGoal.isOverdue, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/models/long_goal_model.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import 'package:the_time_chart/reward_tags/reward_enums.dart';
import 'package:intl/intl.dart';

void main() {
  group('LongGoalModel Evaluation Tests', () {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    final baseGoal = LongGoalModel(
      id: 'test_goal',
      userId: 'user1',
      title: 'Learn Flutter',
      categoryType: 'Education',
      subTypes: 'Programming',
      description: const GoalDescription(
        need: 'I want to build apps',
        motivation: 'Career change',
        outcome: 'Junior Dev Job',
      ),
      timeline: GoalTimeline(
        isUnspecified: false,
        startDate: yesterday,
        endDate: now.add(const Duration(days: 30)),
        workSchedule: const WorkSchedule(
          workDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
          hoursPerDay: 2,
          preferredTimeSlot: null,
        ),
      ),
      indicators: const Indicators(
        status: 'inProgress',
        priority: 'high',
        longGoalColor: '#FF0000',
        weeklyPlans: [],
      ),
      metrics: const GoalMetrics(
        totalDays: 31,
        completedDays: 0,
        tasksPending: 31,
        weeklyMetrics: [],
      ),
      analysis: GoalAnalysis(
        averageProgress: 0,
        averageRating: 0,
        pointsEarned: 0,
        consistencyScore: 0,
        rewardPackage: RewardPackage.empty(source: RewardSource.longGoal, reason: 'Test'),
        suggestions: [],
      ),
      goalLog: const GoalLog(weeklyLogs: []),
      socialInfo: SocialInfo(
        isPosted: false,
      ),
      shareInfo: ShareInfo(
        isShare: false,
      ),
      createdAt: now,
      updatedAt: now,
    );

    test('calculatePointsEarned - feedback points', () {
      final weekId = '2026-W18';
      final goalWithFeedback = baseGoal.copyWith(
        goalLog: GoalLog(
          weeklyLogs: [
            WeeklyGoalLog(
              weekId: weekId,
              dailyFeedback: [
                DailyFeedback(
                  weekId: weekId,
                  feedbackDay: yesterday,
                  feedbackCount: '1',
                  feedbackText: 'Working on layouts',
                  mediaUrl: 'http://example.com/img.png',
                ),
              ],
            ),
          ],
        ),
        indicators: baseGoal.indicators.copyWith(
          weeklyPlans: [
            WeeklyPlan(weekId: weekId, weeklyGoal: 'Goal 1', mood: 'good', isCompleted: false),
          ],
        ),
      );

      final eval = goalWithFeedback.evaluateGoal(now: now);
      
      // Feedback points: 1 * 5 = 5
      // Media points: 1 * 5 = 5
      // Word count: "Working on layouts" = 3 words * 3 = 9
      // Priority bonus (high): 15
      // Total expected: 5 + 5 + 9 + 15 = 34
      
      expect(eval['points_earned'], 34);
    });

    test('Penalty calculation - overdue days', () {
      final pastGoal = baseGoal.copyWith(
        timeline: baseGoal.timeline.copyWith(
          endDate: now.subtract(const Duration(days: 2)),
        ),
      );

      final eval = pastGoal.evaluateGoal(now: now);
      
      // Overdue for 2 full days: 2 * 10 = 20 penalty
      // Plus 100 missed goal penalty because no feedback
      expect(eval['penalty'], 120);
    });

    test('Penalty calculation - missed goal', () {
      final missedGoal = baseGoal.copyWith(
        timeline: baseGoal.timeline.copyWith(
          endDate: now.subtract(const Duration(days: 1)),
        ),
      );

      final eval = missedGoal.evaluateGoal(now: now);
      
      // No feedback till end date: -100 missed penalty
      // Plus 1 day overdue: -10
      // Total: 110
      expect(eval['penalty'], 110);
    });

    test('Consistency score calculation', () {
      final weekId = '2026-W18';
      final consistentGoal = baseGoal.copyWith(
        goalLog: GoalLog(
          weeklyLogs: [
            WeeklyGoalLog(
              weekId: weekId,
              dailyFeedback: [
                DailyFeedback(
                  weekId: weekId,
                  feedbackDay: yesterday,
                  feedbackCount: '1',
                  feedbackText: 'Day 1 feedback',
                ),
                DailyFeedback(
                  weekId: weekId,
                  feedbackDay: now,
                  feedbackCount: '2',
                  feedbackText: 'Day 2 feedback',
                ),
              ],
            ),
          ],
        ),
        indicators: baseGoal.indicators.copyWith(
          weeklyPlans: [
            WeeklyPlan(weekId: weekId, weeklyGoal: 'Goal 1', mood: 'good', isCompleted: false),
          ],
        ),
      );

      final eval = consistentGoal.evaluateGoal(now: now);
      expect(eval['consistency_score'], greaterThan(0));
    });
  });
}

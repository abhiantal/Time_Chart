import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/reward_tags/reward_manager.dart';
import 'package:the_time_chart/features/personal/diary_model/models/diary_entry_model.dart';

void main() {
  group('RewardManager Bug Fix Tests', () {
    test('Bug 2: Day Task Adaptive Penalty', () {
      // 0 progress, not complete -> Points should be 0 (no tier earned)
      final p0 = RewardManager.forDayTask(
        feedbackCount: 0,
        hasText: false,
        isComplete: false,
        isOverdue: false,
        timelineHours: 1,
      );
      expect(p0.points, 0);

      // High progress, not complete -> Should earn Spark tier (10 points)
      // progress = 90. penaltyMultiplier = 0.1 -> penalty = 5. Points = 20 (potential).
      // reductionFactor = 0.95. Actual progress = 86.
      // 86 >= 60 -> Spark Tier earned!
      final p90 = RewardManager.forDayTask(
        feedbackCount: 5,
        hasText: false,
        isComplete: false,
        isOverdue: false,
        timelineHours: 1,
      );
      expect(p90.earned, true);
      expect(p90.tier, RewardTier.spark);
      expect(p90.points, 10); // Spark awards 10 points
    });

    test('Bug 3: Week Task Summary Averaging', () {
      final dailyProgress = [
        _MockDailyProgress(100, 5.0, true, 2),
        _MockDailyProgress(100, 5.0, true, 2),
        _MockDailyProgress(100, 5.0, true, 2),
        _MockDailyProgress(0, 0.0, false, 0),
        _MockDailyProgress(0, 0.0, false, 0),
        _MockDailyProgress(0, 0.0, false, 0),
        _MockDailyProgress(0, 0.0, false, 0),
      ];

      final summary = RewardManager.forWeekTaskSummary(
        dailyProgress: dailyProgress,
        totalScheduledDays: 7,
        taskStack: 1,
        isOverdue: false,
      );

      // 3/3 active days = 100% progress.
      // Highest tier for 3 completed days is Ember (level 3).
      // (Blaze needs 14 days or stack >= 3)
      expect(summary.earned, true);
      expect(summary.tier.level, greaterThanOrEqualTo(3));
    });

    test('Bug 4: Long Goal Consistency Override', () {
      // Consistent: 21 completed days, 90% consistency -> Crystal (level 5)
      final consistentTier = RewardManager.calculate(
        progress: 96,
        rating: 4.6,
        pointsEarned: 80,
        completedDays: 21,
        totalDays: 21,
        hoursPerDay: 4,
        taskStack: 3,
        source: RewardSource.longGoal,
        onTimeCompletion: true,
        consistencyOverride: 90.0,
      );

      // Inconsistent: 21 completed days, 28% consistency -> Blaze (level 4)
      final inconsistentTier = RewardManager.calculate(
        progress: 96,
        rating: 4.6,
        pointsEarned: 80,
        completedDays: 21,
        totalDays: 21,
        hoursPerDay: 4,
        taskStack: 3,
        source: RewardSource.longGoal,
        onTimeCompletion: true,
        consistencyOverride: 28.0,
      );

      expect(consistentTier.tier.level, greaterThan(inconsistentTier.tier.level));
    });

    test('Bug 5: Bucket Tier Gating (hoursPerDay: 0)', () {
      final bucketReward = RewardManager.calculate(
        progress: 96,
        rating: 4.6,
        pointsEarned: 80,
        completedDays: 30,
        totalDays: 30,
        hoursPerDay: 0,
        taskStack: 0,
        source: RewardSource.bucket,
        onTimeCompletion: true,
      );

      expect(bucketReward.tier, RewardTier.prism);
    });
  });

  group('DiaryEntryModel Bug Fix Tests', () {
    test('Bug 1: Diary Progress Calculation', () {
      final progress = DiaryEntryModel.calculateProgress(
        hasContent: true,
        wordCount: 800,
        hasAttachments: true,
        attachmentCount: 12, // To reach 100 points
        linkedItemsCount: 0,
        sentimentScore: 0.9,
        consistencyScore: 1.0,
        isOverdue: false,
      );

      expect(progress, 4200);
    });
  });
}

class _MockDailyProgress {
  final DayMetrics dailyMetrics;
  final List feedbacks;
  final bool isComplete;
  final String taskDate = '2026-03-13';

  _MockDailyProgress(int progress, double rating, this.isComplete, int feedbackCount)
      : dailyMetrics = DayMetrics(progress: progress, rating: rating, pointsEarned: progress),
        feedbacks = List.filled(feedbackCount, 'fake');
  
  DayMetrics get metrics => dailyMetrics;
}

class DayMetrics {
  final int progress;
  final double rating;
  final int pointsEarned;
  DayMetrics({required this.progress, required this.rating, required this.pointsEarned});
}



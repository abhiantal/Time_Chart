import 'package:flutter_test/flutter_test.dart';
import 'package:the_time_chart/features/personal/bucket_model/models/bucket_model.dart';

void main() {
  group('BucketModel Scoring Logic', () {
    test('recalculateRewards handles base points correctly', () {
      final now = DateTime.now();
      final bucket = BucketModel(
        id: 'b1',
        userId: 'u1',
        title: 'Test Bucket',
        details: BucketDetails(description: 'Desc', motivation: 'Mot', outCome: 'Out'),
        checklist: [
          ChecklistItem(
            id: 'c1',
            task: 'Task 1',
            done: true,
            feedbacks: [
              ChecklistFeedback(
                id: 'f1',
                text: 'Completed this task with great success and many words here to test count.',
                mediaUrls: ['url1', 'url2'],
                timestamp: now,
              ),
            ],
          ),
        ],
        timeline: BucketTimeline(
          isUnspecified: false,
          addedDate: now,
          startDate: now.subtract(const Duration(days: 1)),
          dueDate: now.add(const Duration(days: 1)),
        ),
        metadata: BucketMetadata(priority: 'high'),
        createdAt: now,
        updatedAt: now,
      );

      final recalculated = bucket.recalculateRewards();
      
      // Breakdown:
      // Feedback count (1) * 5 = 5
      // Media count (2) * 5 = 10
      // Word count (13) * 8 = 104
      // Checklist item completion (1) * 50 = 50
      // Priority bonus (high) = 15
      // On-time bonus = 200
      // Total = 5 + 10 + 104 + 50 + 15 + 200 = 384.
      
      expect(recalculated.metadata.totalPointsEarned, 384);
    });

    test('recalculateRewards applies overdue penalty', () {
      final now = DateTime.now();
      final dueDate = now.subtract(const Duration(days: 2));
      final completeDate = now; // 2 days late
      
      final bucket = BucketModel(
        id: 'b1',
        userId: 'u1',
        title: 'Overdue Bucket',
        details: BucketDetails(description: 'Desc', motivation: 'Mot', outCome: 'Out'),
        checklist: [
          ChecklistItem(
            id: 'c1',
            task: 'Task 1',
            done: true,
            feedbacks: [
              ChecklistFeedback(
                id: 'f1',
                text: 'Done late',
                mediaUrls: [],
                timestamp: now,
              ),
            ],
          ),
        ],
        timeline: BucketTimeline(
          isUnspecified: false,
          addedDate: now.subtract(const Duration(days: 10)),
          dueDate: dueDate,
          completeDate: completeDate,
        ),
        metadata: BucketMetadata(priority: 'low'),
        createdAt: now,
        updatedAt: now,
      );

      final recalculated = bucket.recalculateRewards();
      
      // Points:
      // Feedback (1) * 5 = 5
      // Media (0) * 5 = 0
      // Words (2) * 8 = 16
      // Item completion (1) * 50 = 50
      // Priority (low) = 5
      // Total Positive = 76
      
      // Penalties:
      // Overdue: 2 days * 20 = 40
      
      expect(recalculated.metadata.totalPointsEarned, 76 - 40);
    });
  });
}

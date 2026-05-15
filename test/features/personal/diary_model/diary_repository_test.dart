import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/personal/diary_model/models/diary_entry_model.dart';
import 'package:the_time_chart/features/personal/diary_model/repositories/diary_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class MockPowerSyncService extends Mock implements PowerSyncService {}

void main() {
  group('DiaryEntryModel Tests', () {
    test('calculateProgress should return 50 for a basic entry', () {
      final points = DiaryEntryModel.calculateProgress(
        hasContent: true,
        wordCount: 0,
        hasAttachments: false,
        attachmentCount: 0,
        linkedItemsCount: 0,
        sentimentScore: 0.0,
        consistencyScore: 1.0,
        isOverdue: false,
      );
      
      expect(points, 50);
    });

    test('calculateProgress should factor in word count', () {
      final points = DiaryEntryModel.calculateProgress(
        hasContent: true,
        wordCount: 10,
        hasAttachments: false,
        attachmentCount: 0,
        linkedItemsCount: 0,
        sentimentScore: 0.0,
        consistencyScore: 1.0,
        isOverdue: false,
      );
      
      // 50 (base) + 10 * 5 (words) = 100
      expect(points, 100);
    });

    test('calculateProgress should apply consistency multiplier', () {
      final points = DiaryEntryModel.calculateProgress(
        hasContent: true,
        wordCount: 0,
        hasAttachments: false,
        attachmentCount: 0,
        linkedItemsCount: 0,
        sentimentScore: 0.0,
        consistencyScore: 0.5,
        isOverdue: false,
      );
      
      // 50 (base) * 0.5 = 25
      expect(points, 25);
    });
  });

  group('DiaryRepository Tests', () {
    // Tests for diary repository
  });
}

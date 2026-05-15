import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/personal/category_model/models/category_model.dart';
import 'package:the_time_chart/features/personal/category_model/repositories/category_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/services/supabase_service.dart';

class MockPowerSyncService extends Mock implements PowerSyncService {}
class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late CategoryRepository repository;
  late MockPowerSyncService mockPowerSync;
  late MockSupabaseService mockSupabase;

  setUp(() {
    mockPowerSync = MockPowerSyncService();
    mockSupabase = MockSupabaseService();
    // In production code, CategoryRepository instantiates PowerSyncService in its constructor,
    // which causes issues in unit tests due to missing platform channels (Connectivity).
    // For now, we focus on model tests or use a mockable repository if needed.
  });

  group('Category Model Tests', () {
    test('fromJson should create a valid Category object', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'category_for': 'day_task',
        'category_type': 'Work',
        'sub_types': ['Coding', 'Meetings'],
        'description': 'Work tasks',
        'color': '#FF0000',
        'icon': '💼',
        'is_global': 0,
        'created_at': '2026-05-01T10:00:00Z',
        'updated_at': '2026-05-01T10:00:00Z',
      };

      final category = Category.fromJson(json);

      expect(category.id, '1');
      expect(category.userId, 'user123');
      expect(category.categoryType, 'Work');
      expect(category.subTypes, contains('Coding'));
      expect(category.isGlobal, false);
    });

    test('toJson should return a valid map', () {
      final category = Category(
        id: '1',
        userId: 'user123',
        categoryFor: 'day_task',
        categoryType: 'Work',
        subTypes: ['Coding'],
        color: '#FF0000',
        icon: '💼',
      );

      final json = category.toJson();

      expect(json['id'], '1');
      expect(json['category_type'], 'Work');
      expect(json['sub_types']['items'], contains('Coding'));
    });
  });

  group('CategoryRepository Tests', () {
    // Tests for repository methods would go here, mocking _powerSync.executeQuery etc.
    // Example:
    /*
    test('getUserCategories returns list of categories', () async {
      when(mockSupabase.currentUserId).thenReturn('user123');
      when(mockPowerSync.executeQuery(any, parameters: anyNamed('parameters')))
          .thenAnswer((_) async => [
                {'id': '1', 'category_type': 'Test', 'is_global': 0}
              ]);

      final categories = await repository.getUserCategories();
      expect(categories, isNotEmpty);
      expect(categories.first.categoryType, 'Test');
    });
    */
  });
}

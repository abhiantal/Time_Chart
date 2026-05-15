import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/personal/task_model/long_goal/repositories/long_goals_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class MockPowerSyncService extends Mock implements PowerSyncService {}

void main() {
  late LongGoalsRepository repository;
  late MockPowerSyncService mockPowerSync;

  setUp(() {
    mockPowerSync = MockPowerSyncService();
    repository = LongGoalsRepository(
      currentUserId: 'user_1',
      powerSync: mockPowerSync,
    );
  });

  group('LongGoalsRepository CRUD', () {
    test('getUserGoals should return empty list on error', () async {
      // Setup mock to throw an exception
      when(() => mockPowerSync.executeQuery(
            any(),
            parameters: any(named: 'parameters'),
          )).thenThrow(Exception('DB Error'));

      final results = await repository.getUserGoals(userId: 'user_1');
      
      expect(results, isEmpty);
    });

    test('getGoalById should return null if not found', () async {
      // Mock exclusion check
      when(() => mockPowerSync.executeQuery(
            any(),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => []);

      // Mock getById returning null
      when(() => mockPowerSync.getById(any(), any()))
          .thenAnswer((_) async => null);

      final result = await repository.getGoalById(id: 'goal_123');
      
      expect(result, isNull);
    });
  });
}

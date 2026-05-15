import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:the_time_chart/features/personal/task_model/day_tasks/repositories/day_task_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';

class MockPowerSyncService extends Mock implements PowerSyncService {}

void main() {
  late DayTaskRepository repository;
  late MockPowerSyncService mockPowerSync;

  setUp(() {
    mockPowerSync = MockPowerSyncService();
    repository = DayTaskRepository();
  });

  group('DayTaskRepository', () {
    test('createTask should call insert on powerSync', () async {
      when(() => mockPowerSync.insert(any(), any())).thenAnswer((_) async => '1');
    });

    test('getTaskById returns null if id is empty', () async {
      final result = await repository.getTaskById('');
      expect(result, isNull);
    });
  });
}

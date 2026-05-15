import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/features/chats/repositories/chat_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class MockPowerSyncService extends Mock implements PowerSyncService {}
class MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _value;
  FakePostgrestFilterBuilder(this._value);

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future.value(onValue(_value));
  }
}

void main() {
  late ChatRepository chatRepository;
  late MockPowerSyncService mockPowerSyncService;
  late MockPowerSyncDatabase mockPowerSyncDb;
  late MockSupabaseClient mockSupabase;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockPowerSyncService = MockPowerSyncService();
    mockPowerSyncDb = MockPowerSyncDatabase();
    mockSupabase = MockSupabaseClient();

    when(() => mockPowerSyncService.db).thenReturn(mockPowerSyncDb);
    when(() => mockPowerSyncService.isReady).thenReturn(true);
    
    // Corrected: Use thenAnswer for anything that matches Future
    when(() => mockSupabase.rpc(any(), params: any(named: 'params')))
        .thenAnswer((_) => FakePostgrestFilterBuilder(null));

    chatRepository = ChatRepository(
      supabase: mockSupabase,
      powerSync: mockPowerSyncService,
    );
    chatRepository.setCurrentUserId('test-user');
  });

  group('ChatRepository Actions', () {
    test('markAsRead performs local and remote updates', () async {
      const chatId = 'chat-1';
      
      final emptyResultSet = sqlite.ResultSet([], [], []);
      when(() => mockPowerSyncDb.execute(any(), any())).thenAnswer((_) async => emptyResultSet);

      await chatRepository.markAsRead(chatId);

      verify(() => mockPowerSyncDb.execute(
        any(that: contains('UPDATE chat_members SET unread_count = 0')),
        any(),
      )).called(1);

      verify(() => mockSupabase.rpc('mark_chat_as_read', params: any(named: 'params'))).called(1);
    });

    test('deleteChat invokes local delete and remote RPC', () async {
      const chatId = 'chat-1';
      
      final emptyResultSet = sqlite.ResultSet([], [], []);
      when(() => mockPowerSyncDb.execute(any(), any())).thenAnswer((_) async => emptyResultSet);

      await chatRepository.deleteChat(chatId);

      verify(() => mockPowerSyncDb.execute(
        any(that: contains('DELETE FROM chats')),
        any(),
      )).called(1);

      verify(() => mockSupabase.rpc('delete_chat', params: any(named: 'params'))).called(1);
    });
  });
}

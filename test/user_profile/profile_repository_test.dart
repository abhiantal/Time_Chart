import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/user_profile/create_edit_profile/profile_repository.dart';
import 'package:the_time_chart/services/powersync_service.dart';
import 'package:the_time_chart/services/supabase_service.dart';
import 'package:the_time_chart/media_utility/universal_media_service.dart';

class MockPowerSyncService extends Mock implements PowerSyncService {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockMediaService extends Mock implements UniversalMediaService {}

void main() {
  late MockPowerSyncService mockPowerSync;
  late MockSupabaseService mockSupabase;
  late MockMediaService mockMedia;
  late ProfileRepository repo;

  setUp(() {
    mockPowerSync = MockPowerSyncService();
    mockSupabase = MockSupabaseService();
    mockMedia = MockMediaService();
    
    repo = ProfileRepository.withDependencies(
      powerSync: mockPowerSync,
      supabase: mockSupabase,
      mediaService: mockMedia,
    );
    
    when(() => mockSupabase.currentUserId).thenReturn('test-user-id');
    when(() => mockSupabase.currentUser).thenReturn(
      User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'test@example.com',
      ),
    );
    
    // Mock getMyProfile to return null (profile doesn't exist yet)
    // ProfileRepository.getMyProfile calls _powerSync.getById
    when(() => mockPowerSync.getById(any(), any())).thenAnswer((_) async => null);
    
    // Mock put
    when(() => mockPowerSync.put(any(), any())).thenAnswer((_) async => {});
  });

  group('ProfileRepository Tests', () {
    test('createProfileFromData builds correct UserProfile object', () async {
      final data = {
        'username': 'testuser',
        'display_name': 'Test User',
        'email': 'test@example.com',
      };
      
      final profile = await repo.createProfileFromData(data);
      expect(profile.username, 'testuser');
      expect(profile.displayName, 'Test User');
      expect(profile.email, 'test@example.com');
    });

    test('createProfileFromData handles missing optional fields', () async {
       final data = {
         'email': 'onlyemail@example.com',
       };
       
       final profile = await repo.createProfileFromData(data);
       expect(profile.email, 'test@example.com');
       expect(profile.username, 'test'); // Defaulted from session email
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_time_chart/user_settings/providers/settings_provider.dart';
import 'package:the_time_chart/user_settings/repositories/settings_repository.dart';
import 'package:the_time_chart/core/Mode/navigation_bar_type.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SettingsProvider Tests', () {
    late SettingsProvider provider;
    late MockSettingsRepository mockRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsProvider.reset();
      mockRepository = MockSettingsRepository();
      provider = SettingsProvider();
      provider.repository = mockRepository;
    });

    test('Initial state is correct', () {
      expect(provider.isInitialized, false);
      expect(provider.isLoading, false);
      expect(provider.settings, isNull);
    });

    test('loadLocalPreferences loads default navigation mode', () async {
      await provider.loadLocalPreferences();
      expect(provider.navigationBarType, NavigationBarType.personal);
    });

    test('setNavigationBarType updates local storage and provider state', () async {
      final success = await provider.setNavigationBarType(NavigationBarType.social);
      expect(success, true);
      expect(provider.navigationBarType, NavigationBarType.social);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('navigationMode'), NavigationBarType.social.name);
    });
  });
}

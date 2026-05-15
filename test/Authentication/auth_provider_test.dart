import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockAuthResponse extends Mock implements AuthResponse {}
void main() {
  group('AuthProvider Tests', () {
    test('isValidEmail returns true for valid email', () {
      expect(AuthProvider.isValidEmail('test@example.com'), isTrue);
      expect(AuthProvider.isValidEmail('user.name+tag@domain.co'), isTrue);
    });

    test('isValidEmail returns false for invalid email', () {
      expect(AuthProvider.isValidEmail('test@'), isFalse);
      expect(AuthProvider.isValidEmail('test@example'), isFalse);
      expect(AuthProvider.isValidEmail('test'), isFalse);
    });

    test('validatePassword returns true for valid length', () {
      expect(AuthProvider.validatePassword('123456'), isTrue);
    });

    test('validatePassword returns false for short length', () {
      expect(AuthProvider.validatePassword('12345'), isFalse);
    });
  });
}

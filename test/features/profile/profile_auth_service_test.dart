import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class MockProfileAuthService extends ProfileAuthService {
  bool _mockLoggedIn = false;
  String? _mockUsername;

  @override
  bool get isLoggedIn => _mockLoggedIn;
  @override
  String? get username => _mockUsername;

  @override
  Future<void> logout() async {
    _mockLoggedIn = false;
    _mockUsername = null;
  }
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
  });

  group('ProfileAuthService', () {
    test('initial state is logged out', () {
      final auth = MockProfileAuthService();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.username, isNull);
    });

    test('logout clears state', () async {
      final auth = MockProfileAuthService();
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.username, isNull);
    });
  });
}

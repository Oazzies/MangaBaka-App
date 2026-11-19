import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:drift/native.dart';

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
}

void main() {
  late LibraryService service;
  late MockProfileAuthService mockAuth;

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<AppDatabase>(AppDatabase.forTesting(NativeDatabase.memory()));
    
    mockAuth = MockProfileAuthService();
    service = LibraryService(auth: mockAuth);
  });

  tearDown(() async {
    await getIt<AppDatabase>().close();
    await resetServiceLocator();
  });

  group('LibraryService', () {
    test('initial sync status is idle', () {
      expect(service.syncStatus.value.isSyncing, isFalse);
      expect(service.syncStatus.value.error, isNull);
    });

    test('cancelSync resets status', () {
      service.syncStatus.value = service.syncStatus.value.copyWith(isSyncing: true);
      
      service.cancelSync();
      
      expect(service.syncStatus.value.isSyncing, isFalse);
    });
  });
}

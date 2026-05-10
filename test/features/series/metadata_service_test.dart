import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
  });

  group('MetadataService', () {
    test('getGenreLabel formats fallback correctly', () {
      final service = MetadataService();
      expect(service.getGenreLabel('action_adventure'), 'Action Adventure');
      expect(service.getGenreLabel('slice_of_life'), 'Slice Of Life');
    });

    test('initial state is not initialized', () {
      final service = MetadataService();
      expect(service.isInitialized, isFalse);
    });
  });
}

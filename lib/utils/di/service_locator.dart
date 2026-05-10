import 'package:get_it/get_it.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

import 'package:mangabaka_app/features/news/services/news_service.dart';

final getIt = GetIt.instance;

/// Configures all service dependencies using GetIt
void setupServiceLocator() {
  // Logging Service (singleton)
  getIt.registerSingleton<LoggingService>(LoggingService());

  // Database (singleton)
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  // Authentication Service (singleton)
  getIt.registerSingleton<ProfileAuthService>(ProfileAuthService());

  // Metadata Service (singleton)
  getIt.registerSingleton<MetadataService>(MetadataService());

  // Snapshot Service (singleton for activity caching)
  getIt.registerSingleton<SnapshotService>(
    SnapshotService(auth: getIt<ProfileAuthService>()),
  );

  // Series Services (lazy singletons - created on first use)
  getIt.registerLazySingleton<SeriesSearchService>(() => SeriesSearchService());

  // Library Service (singleton to maintain state)
  getIt.registerSingleton<LibraryService>(
    LibraryService(auth: getIt<ProfileAuthService>()),
  );

  // News Service (singleton)
  getIt.registerLazySingleton<NewsService>(() => NewsService());
}

/// Resets all service instances (useful for testing)
void resetServiceLocator() {
  getIt.reset();
}

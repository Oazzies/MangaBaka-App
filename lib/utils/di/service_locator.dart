import 'package:get_it/get_it.dart';
import 'package:mangabaka_app/database/database.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/series_id_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<LoggingService>(LoggingService());

  getIt.registerSingleton<AppDatabase>(AppDatabase());

  getIt.registerSingleton<ProfileAuthService>(ProfileAuthService());

  getIt.registerSingleton<MetadataService>(MetadataService());

  getIt.registerSingleton<SnapshotService>(
    SnapshotService(auth: getIt<ProfileAuthService>()),
  );

  getIt.registerLazySingleton<SeriesService>(() => SeriesService());
  getIt.registerLazySingleton<SeriesSearchService>(() => SeriesSearchService());

  getIt.registerSingleton<LibraryService>(
    LibraryService(auth: getIt<ProfileAuthService>()),
  );

  getIt.registerLazySingleton<NewsService>(() => NewsService());
  getIt.registerLazySingleton<PublisherSearchService>(() => PublisherSearchService());
  getIt.registerLazySingleton<MixService>(() => MixService());

}

Future<void> resetServiceLocator() async {
  await getIt.reset();
}

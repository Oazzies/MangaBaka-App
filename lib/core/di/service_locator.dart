import 'package:get_it/get_it.dart';
import 'package:mangabaka_app/features/collections/services/collection_service.dart';
import 'package:mangabaka_app/core/database/database.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/backend_health_service.dart';

import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';
import 'package:mangabaka_app/features/browse/services/book_lookup_service.dart';
import 'package:mangabaka_app/features/updates/services/update_service.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<LoggingService>(LoggingService());

  getIt.registerSingleton<BackendHealthService>(
    BackendHealthService(),
    dispose: (service) => service.dispose(),
  );

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
  getIt.registerLazySingleton<CollectionService>(() => CollectionService());
  getIt.registerLazySingleton<MixService>(() => MixService());
  getIt.registerLazySingleton<BookLookupService>(() => BookLookupService());

  getIt.registerLazySingleton<UpdateService>(() => UpdateService());

  getIt.registerSingleton<DeepLinkService>(
    DeepLinkService(),
    dispose: (service) => service.dispose(),
  );

}

Future<void> resetServiceLocator() async {
  await getIt.reset();
}

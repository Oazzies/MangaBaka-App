import 'package:flutter/foundation.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

typedef SeriesPrefetch = void Function(String seriesId);

@immutable
class SeriesListDeps {
  final ProfileAuthService auth;
  final LibraryService library;
  final SeriesPrefetch prefetch;

  const SeriesListDeps({
    required this.auth,
    required this.library,
    required this.prefetch,
  });

  /// Route-level widgets only: everything below them takes the instance through its constructor.
  factory SeriesListDeps.fromLocator() => SeriesListDeps(
    auth: getIt<ProfileAuthService>(),
    library: getIt<LibraryService>(),
    prefetch: getIt<SeriesService>().fetchSeries,
  );
}

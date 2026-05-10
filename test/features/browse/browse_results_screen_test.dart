import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/browse/widgets/browse_results_body.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/services/series_search_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';

class MockSeriesSearchService extends Fake implements SeriesSearchService {
  @override
  Future<List<Series>> searchSeriesByName(String query, {String? sortBy, String? type, Map<String, dynamic>? extraParams}) async {
    return [
      Series(
        id: '1',
        title: 'Result 1',
        state: '',
        nativeTitle: '',
        romanizedTitle: '',
        secondaryTitles: [],
        coverUrl: '',
        rawCoverUrl: '',
        authors: [],
        artists: [],
        description: '',
        year: '',
        status: '',
        isLicensed: '',
        hasAnime: '',
        contentRating: '',
        type: '',
        rating: '',
        finalVolume: '',
        totalChapters: '',
        links: [],
        publishers: [],
        genres: [],
        tags: [],
        lastUpdated: '',
      )
    ];
  }
}

class MockProfileAuthService extends Fake implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<SeriesSearchService>(MockSeriesSearchService());
    getIt.registerSingleton<ProfileAuthService>(MockProfileAuthService());
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: BrowseResultsScreen(
        sortType: 'Most Popular',
        sortBy: 'popularity_desc',
      ),
    );
  }

  testWidgets('BrowseResultsScreen renders title and results', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Most Popular'), findsOneWidget);
    expect(find.byType(BrowseResultsBody), findsOneWidget);
    expect(find.text('Result 1'), findsOneWidget);
  });
}

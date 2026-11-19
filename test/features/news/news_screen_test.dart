import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/exceptions/error_messages.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockNewsService extends Fake implements NewsService {
  @override
  Future<List<News>> getCachedNews() async => [];
  
  @override
  Future<List<News>> fetchNews({int page = 1, int limit = 10}) async {
    return [
      News(
        id: '1',
        title: 'Mock News Title',
        url: 'http://test.com',
        author: 'Author',
        source: 'Mock Source',
        publishedAt: '2021-01-01',
        series: [],
      )
    ];
  }
}

class _FailingNewsService extends Fake implements NewsService {
  final error = ApiException(message: 'Internal Server Error', statusCode: 500);

  @override
  Future<List<News>> getCachedNews() async => [];

  @override
  Future<List<News>> fetchNews({int page = 1, int limit = 10}) async =>
      throw error;
}

void main() {
  setUp(() async {
    await resetServiceLocator();
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<NewsService>(MockNewsService());
    getIt.registerLazySingleton<SeriesService>(SeriesService.new);
  });

  testWidgets('NewsScreen renders news items from service', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NewsScreen(),
    ));

    await tester.pump(); // initState trigger
    await tester.pump(); // first fetch trigger

    expect(find.text('Mock News Title'), findsOneWidget);
    expect(find.textContaining('MOCK SOURCE'), findsOneWidget);
  });

  testWidgets('a failed load shows the mapped error, not the exception', (
    WidgetTester tester,
  ) async {
    final service = _FailingNewsService();
    getIt.unregister<NewsService>();
    getIt.registerSingleton<NewsService>(service);

    await tester.pumpWidget(const MaterialApp(home: NewsScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.text(ErrorMessages.describe(service.error)), findsOneWidget);
    expect(find.textContaining('Internal Server Error'), findsNothing);
  });
}

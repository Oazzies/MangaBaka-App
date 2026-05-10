import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/news/screens/news_screen.dart';
import 'package:mangabaka_app/features/news/services/news_service.dart';
import 'package:mangabaka_app/features/news/models/news.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

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

void main() {
  setUp(() {
    resetServiceLocator();
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<LoggingService>(LoggingService());
    getIt.registerSingleton<NewsService>(MockNewsService());
  });

  testWidgets('NewsScreen renders news items from service', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NewsScreen(),
    ));

    // Wait for fetch to complete
    await tester.pump(); // initState trigger
    await tester.pump(); // first fetch trigger

    expect(find.text('Mock News Title'), findsOneWidget);
    expect(find.textContaining('Mock Source'), findsOneWidget);
  });
}

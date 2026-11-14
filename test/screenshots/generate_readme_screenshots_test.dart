import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/presets/theme_presets.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_service.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';
import 'package:mangabaka_app/features/profile/services/snapshot_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';

import '../responsive/support/fake_backend.dart';
import '../responsive/support/fake_services.dart';
import '../responsive/support/test_app.dart';

const _phoneLogicalSize = Size(430, 932);
const _phoneDpr = 2.5;
const _coverAsset = 'assets/series_222_cover.jpg';

class _ScreenshotBackend extends FakeBackend {
  @override
  (int, Object?) respond(Uri uri) {
    final path = uri.path;
    if (path.endsWith('/series/3397')) {
      return (200, {'data': _featuredSeriesPayload()});
    }
    if (path.endsWith('/news')) {
      final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      if (page != 1) return (200, {'data': [], 'total': 0});
      return (
        200,
        {
          'data': [
            {
              'id': 'news-1',
              'title':
                  'Dead Rock Manga Goes on Short Hiatus, Returns Next Month',
              'url': 'https://example.com/news/1',
              'author': 'Rafael Antonio Pineda',
              'source_name': 'Anime News Network',
              'published_at': '2026-10-18T12:00:00Z',
              'series': [_seriesPayload(0, 'DEAD ROCK')],
            },
            {
              'id': 'news-2',
              'title':
                  'Frieren: Beyond Journey\'s End Resumes Serialization This Fall',
              'url': 'https://example.com/news/2',
              'author': 'Crystalyn Hodgkins',
              'source_name': 'Anime News Network',
              'published_at': '2026-10-15T09:30:00Z',
              'series': [_seriesPayload(1, 'Frieren: Beyond Journey\'s End')],
            },
            {
              'id': 'news-3',
              'title': 'Solo Leveling: Ragnarok Reveals New Key Visual',
              'url': 'https://example.com/news/3',
              'author': '',
              'source_name': 'MangaBaka News',
              'published_at': '2026-10-12T16:00:00Z',
              'series': [_seriesPayload(2, 'Solo Leveling')],
            },
          ],
          'total': 3,
        },
      );
    }
    return super.respond(uri);
  }
}

Map<String, dynamic> _seriesPayload(int index, String title) => {
  'id': '${2000 + index}',
  'state': 'active',
  'title': title,
  'titles': [
    {'title': title, 'language': 'en', 'is_primary': true},
  ],
  'native_title': '',
  'type': index.isEven ? 'manga' : 'manhwa',
  'status': index % 3 == 0 ? 'releasing' : 'completed',
  'is_licensed': true,
  'has_anime': index % 2 == 0,
  'content_rating': 'safe',
  'year': 2018 + (index % 7),
  'rating': '86.3',
  'cover': {'x350': _coverAsset, 'raw': _coverAsset},
  'genres': ['Action', 'Adventure', 'Fantasy', 'Drama', 'Shounen'],
  'genres_v2': [
    {'name': 'Action'},
    {'name': 'Adventure'},
    {'name': 'Fantasy'},
    {'name': 'Drama'},
    {'name': 'Shounen'},
  ],
  'tags': ['Dungeon', 'Magic', 'Overpowered Protagonist'],
  'authors': ['Chugong'],
  'artists': ['DUBU (REDICE STUDIO)'],
  'description':
      'In a world where awakened beings called "Hunters" must battle deadly '
      'monsters to protect humanity, Sung Jinwoo, nicknamed "the weakest '
      'hunter of all mankind," finds himself in a constant struggle for '
      'survival. One day, after a brutal encounter in an overpowered dungeon '
      'wipes out his party and threatens to end his life, a mysterious System '
      'chooses him as its sole player.',
  'total_chapters': '201',
  'final_volume': '15',
  'publishers': [
    {'name': 'D&C Media'},
  ],
  'links': [],
};

List<LibraryEntry> _sampleLibrary() {
  const titles = [
    'Solo Leveling',
    'Frieren: Beyond Journey\'s End',
    'The Apothecary Diaries',
    'Nano Machine',
    'The Novel\'s Extra',
    'Alya Sometimes Hides Her Feelings',
    'Vagabond',
    'One Punch-Man',
    'Kaguya-sama: Love Is War',
    'Oyasumi Punpun',
    'Chainsaw Man',
    'Dandadan',
  ];
  return [
    for (var i = 0; i < titles.length; i++)
      LibraryEntry(
        id: 'lib-$i',
        state: 'reading',
        progressChapter: 12 + i * 7,
        progressVolume: 2 + (i % 5),
        rating: 85 + (i % 14),
        updatedAt: '2026-10-20T12:00:00Z',
        createdAt: '2025-04-01T12:00:00Z',
        series: Series.fromJson(_seriesPayload(i, titles[i])),
      ),
  ];
}

Map<String, dynamic> _featuredSeriesPayload() => {
  'id': '3397',
  'state': 'active',
  'title': 'The Apothecary Diaries',
  'titles': [
    {'title': 'The Apothecary Diaries', 'language': 'en', 'is_primary': true},
    {
      'title': 'Kusuriya no Hitorigoto',
      'language': 'ja-Latn',
      'is_primary': false,
    },
  ],
  'native_title': '',
  'type': 'manga',
  'status': 'releasing',
  'is_licensed': true,
  'has_anime': true,
  'content_rating': 'safe',
  'year': 2017,
  'rating': '89.4',
  'cover': {'x350': _coverAsset, 'raw': _coverAsset},
  'genres': ['Drama', 'Historical', 'Mystery', 'Slice of Life'],
  'genres_v2': [
    {'name': 'Drama'},
    {'name': 'Historical'},
    {'name': 'Mystery'},
    {'name': 'Slice of Life'},
  ],
  'tags': ['Medicine', 'Palace Intrigue', 'Smart Protagonist'],
  'authors': ['Natsu Hyuuga'],
  'artists': ['Nekokurage'],
  'description':
      'Maomao, an apothecary\'s daughter, has been plucked from her peaceful '
      'life and sold to the lowest echelons of the imperial court. Now merely '
      'a maid, Maomao settles into her new mundane life and hides her '
      'extensive knowledge of medicine in order to avoid any unwanted '
      'attention. When the emperor\'s infant children fall mysteriously ill, '
      'she cannot resist stepping in to solve the mystery.',
  'total_chapters': '80',
  'final_volume': '14',
  'publishers': [
    {'name': 'Square Enix'},
  ],
  'links': [],
};

Series _featuredSeries() => Series.fromJson(_featuredSeriesPayload());

Future<void> _captureBoundary(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String filename,
  bool writeFiles,
  String outputDir,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  if (!writeFiles) return;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _phoneDpr);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(outputDir)..createSync(recursive: true);
    File('${dir.path}/$filename').writeAsBytesSync(
      byteData!.buffer.asUint8List(),
    );
  });
}

void main() {
  final writeFiles = Platform.environment['GENERATE_SCREENSHOTS'] == '1';
  final outputDir =
      Platform.environment['SCREENSHOT_OUTPUT_DIR'] ??
      'build/readme-screenshots';

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() async {
    await setUpEnvironment(const Environment());
    await SettingsManager().setDefaultStartPage(AppStartPage.library);

    final library = _sampleLibrary();
    await getIt.unregister<LibraryService>();
    await getIt.unregister<SnapshotService>();
    getIt
      ..registerSingleton<LibraryService>(FakeLibrary(library))
      ..registerSingleton<SnapshotService>(FakeSnapshots(library));

    HttpOverrides.global = _ScreenshotBackend();
  });

  tearDown(() async {
    await tearDownEnvironment();
  });

  testWidgets('renders README preview screens at phone viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = _phoneDpr;
    tester.view.physicalSize = _phoneLogicalSize * _phoneDpr;
    tester.view.padding = const FakeViewPadding(
      top: 30 * _phoneDpr,
      bottom: 24 * _phoneDpr,
    );
    addTearDown(tester.view.reset);

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(inkPalette, showTooltips: false),
          home: MainScreen(),
        ),
      ),
    );
    await settle(tester);

    // 1. Library tab
    MainScreen.setTabIndex(NavTabs.library);
    await settle(tester);
    await _captureBoundary(
      tester,
      boundaryKey,
      '01_library.png',
      writeFiles,
      outputDir,
    );

    // 2. Browse tab
    MainScreen.setTabIndex(NavTabs.browse);
    await settle(tester);
    await _captureBoundary(
      tester,
      boundaryKey,
      '02_browse.png',
      writeFiles,
      outputDir,
    );

    // 3. News tab
    MainScreen.setTabIndex(NavTabs.news);
    await settle(tester);
    await _captureBoundary(
      tester,
      boundaryKey,
      '04_news.png',
      writeFiles,
      outputDir,
    );

    // 4. Series Detail screen (separate test so MainScreen disposes cleanly)
    await disposeApp(tester);
  });

  testWidgets('renders SeriesDetailScreen at phone viewport', (tester) async {
    tester.view.devicePixelRatio = _phoneDpr;
    tester.view.physicalSize = _phoneLogicalSize * _phoneDpr;
    tester.view.padding = const FakeViewPadding(
      top: 30 * _phoneDpr,
      bottom: 24 * _phoneDpr,
    );
    addTearDown(tester.view.reset);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(inkPalette, showTooltips: false),
          home: SeriesDetailScreen(series: _featuredSeries()),
        ),
      ),
    );
    await settle(tester);
    await _captureBoundary(
      tester,
      boundaryKey,
      '03_series_detail.png',
      writeFiles,
      outputDir,
    );

    await disposeApp(tester);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_titles.dart';
import 'package:mangabaka_app/features/series/services/series_title_enricher.dart';

/// A series as a v2 list sends it: no `title`, only the per-language list.
Series _guessed(int id, String englishUnofficial) => Series.fromJson({
  'id': id,
  'original_language': 'ja',
  'titles': [
    {'language': 'en', 'traits': <String>[], 'title': englishUnofficial},
    {
      'language': 'ja-Latn',
      'traits': ['native'],
      'title': 'Romaji $id',
    },
  ],
  'cover': {'raw': '', 'x350': ''},
});

void main() {
  late List<http.Request> requests;
  late DateTime clock;
  late http.Response Function(http.Request) handler;

  http.Response canonical(http.Request r) {
    final ids = r.url.queryParametersAll['id']!;
    return http.Response(
      jsonEncode({
        'data': [
          for (final id in ids) {'id': int.parse(id), 'title': 'Canonical $id'},
        ],
      }),
      200,
    );
  }

  SeriesTitleEnricher make() => SeriesTitleEnricher(
    api: ApiClient(
      client: MockClient((r) async {
        requests.add(r);
        return handler(r);
      }),
      // Mirrors production: the enricher handles 429s itself.
      maxRateLimitRetries: 0,
    ),
    window: Duration.zero,
    batchGap: Duration.zero,
    now: () => clock,
  );

  setUp(() {
    SeriesTitles.clearRemembered();
    requests = [];
    clock = DateTime(2026, 1, 1);
    handler = canonical;
  });

  test('replaces guessed titles with the canonical v1 ones', () async {
    final list = [_guessed(1, 'Fan Name'), _guessed(2, 'Other Fan Name')];
    // The guess is what a v2 list would show.
    expect(list.first.title, 'Romaji 1');

    final out = await make().canonicalize(list);

    expect(out.map((s) => s.title), ['Canonical 1', 'Canonical 2']);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/v1/series/batch');
    expect(requests.single.url.queryParametersAll['id'], ['1', '2']);
    // Everything but the titles is untouched.
    expect(out.first.coverUrl, list.first.coverUrl);
  });

  test('asks only for series whose canonical title is unknown', () async {
    SeriesTitles.remember(
      '1',
      const SeriesTitles(main: 'Known', canonical: true),
    );

    final out = await make().canonicalize([_guessed(1, 'x'), _guessed(2, 'y')]);

    expect(requests.single.url.queryParametersAll['id'], ['2']);
    expect(out.map((s) => s.title), ['Known', 'Canonical 2']);
  });

  test('makes no request at all when every title is already known', () async {
    final e = make();
    await e.canonicalize([_guessed(1, 'x')]);
    requests.clear();

    await e.canonicalize([_guessed(1, 'x')]);

    expect(requests, isEmpty);
  });

  test(
    'callers in the same moment share one request, ids not repeated',
    () async {
      final e = make();

      final results = await Future.wait([
        e.canonicalize([_guessed(1, 'a'), _guessed(2, 'a')]),
        e.canonicalize([_guessed(2, 'a'), _guessed(3, 'a')]),
        e.canonicalize([_guessed(3, 'a'), _guessed(4, 'a')]),
      ]);

      expect(requests, hasLength(1));
      expect(requests.single.url.queryParametersAll['id'], [
        '1',
        '2',
        '3',
        '4',
      ]);
      expect(results[1].map((s) => s.title), ['Canonical 2', 'Canonical 3']);
    },
  );

  test('more than 50 ids are split into batches of 50', () async {
    final list = [for (var i = 1; i <= 120; i++) _guessed(i, 'a')];

    await make().canonicalize(list);

    expect(requests.map((r) => r.url.queryParametersAll['id']!.length), [
      50,
      50,
      20,
    ]);
  });

  test('ids the server does not return are not asked for again', () async {
    handler = (r) => http.Response(jsonEncode({'data': []}), 200);
    final e = make();

    final out = await e.canonicalize([_guessed(9, 'a')]);
    expect(out.single.title, 'Romaji 9'); // keeps its guess
    requests.clear();

    await e.canonicalize([_guessed(9, 'a')]);
    expect(requests, isEmpty);
  });

  test(
    'a failure keeps the guesses, never throws, and pauses with backoff',
    () async {
      handler = (r) => http.Response('rate limited', 429);
      final e = make();

      final out = await e.canonicalize([_guessed(1, 'a')]);
      expect(out.single.title, 'Romaji 1');
      expect(requests, hasLength(1));

      // Still paused: the next list does not touch the API.
      requests.clear();
      await e.canonicalize([_guessed(2, 'a')]);
      expect(requests, isEmpty);

      // After the pause it tries again, and recovers.
      clock = clock.add(const Duration(seconds: 31));
      handler = canonical;
      final recovered = await e.canonicalize([_guessed(3, 'a')]);
      expect(requests, hasLength(1));
      expect(recovered.single.title, 'Canonical 3');
    },
  );

  test('the pause grows after repeated failures', () async {
    handler = (r) => http.Response('', 500);
    final e = make();

    await e.canonicalize([_guessed(1, 'a')]); // 30 s pause
    clock = clock.add(const Duration(seconds: 31));
    await e.canonicalize([_guessed(2, 'a')]); // 60 s pause
    requests.clear();

    clock = clock.add(const Duration(seconds: 45));
    await e.canonicalize([_guessed(3, 'a')]);
    expect(requests, isEmpty, reason: 'second pause is 60 s, not 30 s');
  });

  test('the disabled enricher never makes a request', () async {
    final list = [_guessed(1, 'a')];
    final out = await SeriesTitleEnricher.disabled().canonicalize(list);
    expect(out, same(list));
    expect(requests, isEmpty);
  });
}

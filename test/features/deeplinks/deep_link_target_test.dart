import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/deeplinks/deep_link_target.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

DeepLinkTarget? parse(String url) => DeepLinkTarget.parse(Uri.parse(url));

void main() {
  group('series', () {
    test('web format/id/slug', () {
      final t = parse('https://mangabaka.org/manga/20776/Gambling-Apocalypse');
      expect(t, isA<SeriesTarget>());
      expect((t as SeriesTarget).id, '20776');
    });

    test('every format reaches a series', () {
      for (final f in ['manga', 'novel', 'manhwa', 'manhua', 'oel', 'other']) {
        expect(parse('https://mangabaka.org/$f/5/x'), isA<SeriesTarget>());
      }
    });

    test('www host and no slug', () {
      final t = parse('https://www.mangabaka.org/novel/85316');
      expect((t as SeriesTarget).id, '85316');
    });

    test('custom scheme and legacy /series/<id>', () {
      expect((parse('mangabaka://manga/12') as SeriesTarget).id, '12');
      expect((parse('mangabaka://series/12') as SeriesTarget).id, '12');
      expect((parse('https://mangabaka.org/series/12') as SeriesTarget).id,
          '12');
    });

    test('a format index is a typed search, not a series', () {
      final t = parse('https://mangabaka.org/manhwa') as SearchTarget;
      expect(t.filters.type, ['manhwa']);
    });
  });

  group('search', () {
    test('repeated tags and a sort', () {
      final t = parse(
        'https://mangabaka.org/search?tag=94&tag=126&sort_by=random',
      ) as SearchTarget;
      expect(t.filters.tag, ['94', '126']);
      expect(t.filters.sortBy, 'random');
      expect(t.query, '');
    });

    test('query and genre', () {
      final t = parse('mangabaka://search?q=berserk&genre=action')
          as SearchTarget;
      expect(t.query, 'berserk');
      expect(t.filters.genre, ['action']);
    });

    test('popular and highest-rated carry a sort', () {
      expect((parse('https://mangabaka.org/popular') as SearchTarget)
          .filters
          .sortBy, 'popularity_desc');
      expect((parse('https://mangabaka.org/highest-rated') as SearchTarget)
          .filters
          .sortBy, 'score_desc');
    });
  });

  group('screens and tabs', () {
    test('publisher by id and the list', () {
      expect((parse('https://mangabaka.org/publisher/42') as PublisherTarget)
          .id, '42');
      expect(parse('https://mangabaka.org/publisher'),
          isA<PublisherListTarget>());
    });

    test('tabs', () {
      int tab(String u) => (parse(u) as TabTarget).index;
      expect(tab('https://mangabaka.org/'), NavTabs.home);
      expect(tab('https://mangabaka.org/my/library'), NavTabs.library);
      expect(tab('https://mangabaka.org/news'), NavTabs.news);
      expect(tab('https://mangabaka.org/my/news'), NavTabs.news);
      expect(tab('mangabaka://library'), NavTabs.library);
    });

    test('other pages', () {
      expect(parse('https://mangabaka.org/discover'), isA<DiscoverTarget>());
      expect(parse('https://mangabaka.org/my/discover'),
          isA<DiscoverTarget>());
      expect(parse('https://mangabaka.org/mix'), isA<MixTarget>());
      expect(parse('https://mangabaka.org/my/stats'), isA<StatsTarget>());
      expect(parse('https://mangabaka.org/stacks'), isA<CollectionsTarget>());
    });
  });

  test('pages the app has no screen for are null', () {
    expect(parse('https://mangabaka.org/forum'), isNull);
    expect(parse('https://mangabaka.org/about/terms'), isNull);
    expect(parse('https://mangabaka.org/my/library/import/mal'), isA<TabTarget>());
    expect(parse('https://mangabaka.org/my/settings'), isNull);
  });
}

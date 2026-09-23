import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/services/autocomplete_cache.dart';

AutocompleteSeriesResult _result(String title) => AutocompleteSeriesResult(
      id: title.hashCode,
      title: title,
      thumbnailUrl: '',
      allTitles: [title],
    );

List<AutocompleteSeriesResult> _results(List<String> titles) =>
    titles.map(_result).toList();

void main() {
  group('AutocompleteCache exact hits', () {
    test('returns a stored entry', () {
      final cache = AutocompleteCache();
      cache.put('attack', _results(['Attack on Titan']));

      final hit = cache.get('attack');
      expect(hit, isNotNull);
      expect(hit!.single.title, 'Attack on Titan');
    });

    test('returns null for a query never stored', () {
      expect(AutocompleteCache().get('attack'), isNull);
    });

    test('evicts the least recently used entry past maxEntries', () {
      final cache = AutocompleteCache(maxEntries: 2);
      cache.put('a', _results(['A']));
      cache.put('b', _results(['B']));
      // Touching 'a' makes 'b' the oldest.
      cache.get('a');
      cache.put('c', _results(['C']));

      expect(cache.length, 2);
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
    });
  });

  group('AutocompleteCache prefix matching', () {
    test('keeps a result matching only an alternate title', () {
      final cache = AutocompleteCache();
      cache.put('so', [
        const AutocompleteSeriesResult(
          id: 1,
          title: "Frieren: Beyond Journey's End",
          thumbnailUrl: '',
          allTitles: ["Frieren: Beyond Journey's End", 'Sousou no Frieren'],
        ),
      ]);

      final hit = cache.findPrefixMatch('sousou');

      expect(hit, isNotNull);
      expect(hit!.results.single.id, 1);
    });

    test('matches words out of order within a title', () {
      final cache = AutocompleteCache();
      cache.put('fr', _results(['Sousou no Frieren']));

      final hit = cache.findPrefixMatch('frieren sousou');

      expect(hit!.results, hasLength(1));
    });

    test('filters a longer cached query down for a backspace', () {
      final cache = AutocompleteCache(pageLimit: 6);
      cache.put('attack on titan', _results(['Attack on Titan']));

      final hit = cache.findPrefixMatch('attack on');
      expect(hit, isNotNull);
      expect(hit!.results.single.title, 'Attack on Titan');
      // Derived from a narrower query, so it cannot speak for the broader one.
      expect(hit.couldHaveMore, isTrue);
    });

    test('a short page for a prefix proves the extension is exhausted', () {
      final cache = AutocompleteCache(pageLimit: 6);
      // Fewer than pageLimit results means the server had no more to give.
      cache.put('attack', _results(['Attack on Titan', 'Attack No. 1']));

      final hit = cache.findPrefixMatch('attack on');
      expect(hit, isNotNull);
      expect(hit!.results.single.title, 'Attack on Titan');
      expect(hit.couldHaveMore, isFalse);
    });

    test('a full page for a prefix leaves room for better matches', () {
      final cache = AutocompleteCache(pageLimit: 2);
      cache.put('attack', _results(['Attack on Titan', 'Attack No. 1']));

      final hit = cache.findPrefixMatch('attack on');
      expect(hit, isNotNull);
      expect(hit!.couldHaveMore, isTrue);
    });

    test('an exhausted prefix with no local matches proves emptiness', () {
      final cache = AutocompleteCache(pageLimit: 6);
      cache.put('attack', _results(['Attack on Titan']));

      final hit = cache.findPrefixMatch('attack zzz');
      expect(hit, isNotNull);
      expect(hit!.results, isEmpty);
      expect(hit.couldHaveMore, isFalse);
    });

    test('says nothing when no cached query is a prefix either way', () {
      final cache = AutocompleteCache();
      cache.put('berserk', _results(['Berserk']));

      expect(cache.findPrefixMatch('attack'), isNull);
    });

    test('caps derived results at the page limit', () {
      final cache = AutocompleteCache(pageLimit: 2);
      cache.put(
        'attack on titan',
        _results(['Attack A', 'Attack B', 'Attack C']),
      );

      final hit = cache.findPrefixMatch('attack');
      expect(hit!.results, hasLength(2));
    });

    test('clear empties the cache', () {
      final cache = AutocompleteCache();
      cache.put('a', _results(['A']));
      cache.clear();
      expect(cache.length, 0);
      expect(cache.get('a'), isNull);
    });
  });
}

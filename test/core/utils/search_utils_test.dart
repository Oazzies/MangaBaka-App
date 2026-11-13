import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/utils/search_utils.dart';

void main() {
  group('SearchUtils.normalize', () {
    test('strips straight and curly apostrophes without inserting spaces', () {
      expect(SearchUtils.normalize("Can't Stop"), 'cant stop');
      expect(SearchUtils.normalize('Can’t Stop'), 'cant stop');
      expect(SearchUtils.normalize('Can‘t Stop'), 'cant stop');
      expect(SearchUtils.normalize('Can`t Stop'), 'cant stop');
      expect(SearchUtils.normalize("Kaguya's"), 'kaguyas');
    });

    test('replaces hyphens, colons, and punctuation with collapsed spaces', () {
      expect(SearchUtils.normalize('Kaguya-sama: Love Is War'), 'kaguya sama love is war');
      expect(SearchUtils.normalize('Re:Zero'), 're zero');
      expect(SearchUtils.normalize('Steins;Gate'), 'steins gate');
      expect(SearchUtils.normalize('SPY×FAMILY'), 'spy family');
      expect(SearchUtils.normalize('  One   Piece!!  '), 'one piece');
    });

    test('folds Latin diacritics, macrons, and combining marks', () {
      expect(SearchUtils.normalize('Yū Yū Hakusho'), 'yu yu hakusho');
      expect(SearchUtils.normalize('Pokémon'), 'pokemon');
      expect(SearchUtils.normalize('Tōkyō'), 'tokyo');
      // NFD decomposed: o + combining macron (U+0304)
      expect(SearchUtils.normalize('To\u0304kyo\u0304'), 'tokyo');
      expect(SearchUtils.normalize('naïve café'), 'naive cafe');
    });

    test('folds full-width ASCII and ideographic spaces', () {
      expect(SearchUtils.normalize('Ｏｎｅ　Ｐｉｅｃｅ！'), 'one piece');
    });

    test('preserves CJK, kana, and hangul characters', () {
      expect(SearchUtils.normalize('チェンソーマン'), 'チェンソーマン');
      expect(SearchUtils.normalize('進撃の巨人'), '進撃の巨人');
    });
  });

  group('PreparedQuery', () {
    test('matches apostrophe variations', () {
      final cant = SearchUtils.prepare('cant');
      expect(cant.matches("Komi Can't Communicate"), isTrue);
      expect(cant.matches('Komi Can’t Communicate'), isTrue);
      expect(cant.matches('Cant Stop'), isTrue);

      final withApostrophe = SearchUtils.prepare("can't");
      expect(withApostrophe.matches("Can't Stop"), isTrue);
      expect(withApostrophe.matches('Can’t Stop'), isTrue);
      expect(withApostrophe.matches('Cant Stop'), isFalse);
      expect(withApostrophe.matches('Canticle'), isFalse);

      final trailingApostrophe = SearchUtils.prepare(" Can' ");
      expect(trailingApostrophe.matches("Komi Can't Communicate"), isTrue);
      expect(trailingApostrophe.matches('Komi Can’t Communicate'), isTrue);
      expect(trailingApostrophe.matches('American'), isFalse);
      expect(trailingApostrophe.matches('Candy'), isFalse);
      expect(trailingApostrophe.matches('Scandal'), isFalse);
      expect(trailingApostrophe.matches('Cant Stop'), isFalse);
    });

    test('matches hyphenated and punctuated titles with spaces or compacted', () {
      expect(SearchUtils.prepare('kaguya sama').matches('Kaguya-sama: Love Is War'), isTrue);
      expect(SearchUtils.prepare('kaguyasama').matches('Kaguya-sama: Love Is War'), isTrue);
      expect(SearchUtils.prepare('re zero').matches('Re:Zero'), isTrue);
      expect(SearchUtils.prepare('rezero').matches('Re:Zero'), isTrue);
      expect(SearchUtils.prepare('scifi').matches('Sci-Fi'), isTrue);
      expect(SearchUtils.prepare('boys love').matches("Boys' Love"), isTrue);
    });

    test('matches multi-word queries out of order', () {
      final q = SearchUtils.prepare('komi communicate');
      expect(q.matches("Komi Can't Communicate"), isTrue);
      expect(q.matches('Komi-san'), isFalse);
    });

    test('startsWith and exactMatch handle normalized titles', () {
      final q = SearchUtils.prepare('cant stop');
      expect(q.startsWith("Can't Stop Now"), isTrue);
      expect(q.exactMatch("Can't Stop"), isTrue);
      expect(q.exactMatch("Can't Stop Now"), isFalse);
    });

    test('falls back to raw lowercase for punctuation-only queries', () {
      final q = SearchUtils.prepare('!!!');
      expect(q.matches('Yotsuba&!!!'), isTrue);
      expect(q.matches('One Piece'), isFalse);
    });

    test('empty query matches everything, non-empty never matches empty', () {
      expect(SearchUtils.prepare('   ').isEmpty, isTrue);
      expect(SearchUtils.prepare('').matches('Anything'), isTrue);
      expect(SearchUtils.prepare('a').matches(''), isFalse);
    });
  });
}

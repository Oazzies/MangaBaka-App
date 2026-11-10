import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/series_titles.dart';

Map<String, dynamic> _entry(
  String language,
  String title, [
  List<String> traits = const [],
]) => {
  'language': language,
  'traits': traits,
  'title': title,
  'is_primary': true, // the v2 API flags every entry primary
};

Map<String, dynamic> _v2({
  required String id,
  required String originalLanguage,
  required List<Map<String, dynamic>> titles,
}) => {
  'id': id,
  'original_language': originalLanguage,
  'titles': titles,
  'cover': {'raw': '', 'x150': '', 'x250': '', 'x350': ''},
};

void main() {
  setUp(SeriesTitles.clearRemembered);

  group('v2 titles[] derivation', () {
    test('official English wins; native and romanized are found', () {
      final s = Series.fromJson(
        _v2(
          id: '1',
          originalLanguage: 'ko',
          titles: [
            _entry('ko', '다이스', ['native']),
            _entry('es', 'DADO : El cubo que cambia todo'),
            _entry('en', 'DICE', ['official']),
            _entry('ko-Latn', 'Daiseu', ['native']),
          ],
        ),
      );
      expect(s.title, 'DICE');
      expect(s.nativeTitle, '다이스');
      expect(s.romanizedTitle, 'Daiseu');
    });

    test('without an official English title the romanization is the main '
        'title, not an unofficial English one', () {
      // id 344 on the live API: v1 says "Yankee Akuyaku Reijou: ...".
      final s = Series.fromJson(
        _v2(
          id: '344',
          originalLanguage: 'ja',
          titles: [
            _entry('en', 'Motorcycle Gang Leader Reborn As A Villainess'),
            _entry('ja-Latn', 'Yankee Akuyaku Reijou', ['native']),
            _entry('ja', 'ヤンキー悪役令嬢', ['native']),
          ],
        ),
      );
      expect(s.title, 'Yankee Akuyaku Reijou');
      expect(s.nativeTitle, 'ヤンキー悪役令嬢');
      expect(
        s.secondaryTitles,
        contains('Motorcycle Gang Leader Reborn As A Villainess'),
      );
    });

    test('translations into CJK languages are not the native title', () {
      final s = Series.fromJson(
        _v2(
          id: '106',
          originalLanguage: 'ja',
          titles: [
            _entry('ko', '늑대님의 한결같은 폭애'),
            _entry('en', 'Mr. Wolf', ['official']),
            _entry('ja', 'オオカミ様の一途な暴愛', ['native']),
            _entry('zh', '狼大人专情的霸道之爱'),
          ],
        ),
      );
      expect(s.nativeTitle, 'オオカミ様の一途な暴愛');
    });

    test('a Chinese series with zh-Hans-CN original language', () {
      final s = Series.fromJson(
        _v2(
          id: '183',
          originalLanguage: 'zh-Hans-CN',
          titles: [
            _entry('ko', '나는 절망과 함께 자란다'),
            _entry('en', 'Rising with the Monsters', ['official']),
            _entry('zh-Latn', 'Wo Yu Zaie', ['native']),
            _entry('zh', '我与灾厄一同升级', ['native']),
          ],
        ),
      );
      expect(s.nativeTitle, '我与灾厄一同升级');
      expect(s.romanizedTitle, 'Wo Yu Zaie');
    });

    test('never yields an empty main title when any title exists', () {
      final s = Series.fromJson(
        _v2(
          id: '9',
          originalLanguage: 'th',
          titles: [
            _entry('th', 'ไม่อยากจะห่างรัก', ['native']),
          ],
        ),
      );
      expect(s.title, 'ไม่อยากจะห่างรัก');
    });
  });

  group('canonical v1 titles', () {
    Map<String, dynamic> v1() => {
      'id': '337',
      'title': "My Sister's Best Friend",
      'native_title': '姉のともだち',
      'romanized_title': 'Ane no Tomodachi',
      'cover': {
        'raw': {'url': ''},
      },
    };

    test('the server title is used verbatim', () {
      final s = Series.fromJson(v1());
      expect(s.title, "My Sister's Best Friend");
      expect(s.nativeTitle, '姉のともだち');
      expect(s.romanizedTitle, 'Ane no Tomodachi');
    });

    test('a later v2 payload for the same series agrees with it', () {
      Series.fromJson(v1()); // e.g. the library sync or the detail page

      final fromRail = Series.fromJson(
        _v2(
          id: '337',
          originalLanguage: 'ja',
          titles: [
            _entry('ko', '누나의 친구', ['official']),
            _entry('en', 'The cutest girl closest to me.', ['alternative']),
            _entry('ja-Latn', 'Ane no Tomodachi', ['native']),
            _entry('ja', '姉のともだち', ['native']),
          ],
        ),
      );
      expect(fromRail.title, "My Sister's Best Friend");
    });

    test('a different series is not affected by what was remembered', () {
      Series.fromJson(v1());
      final other = Series.fromJson(
        _v2(
          id: '338',
          originalLanguage: 'ja',
          titles: [
            _entry('en', 'Other', ['official']),
          ],
        ),
      );
      expect(other.title, 'Other');
    });

    test("v1's map-of-lists secondary_titles is flattened to plain titles", () {
      final s = Series.fromJson({
        ...v1(),
        'secondary_titles': {
          'unknown': [
            {'type': 'unknown', 'title': 'Alt One', 'note': null},
            {'type': 'unknown', 'title': 'Alt Two', 'note': null},
            {
              'type': 'unknown',
              'title': "My Sister's Best Friend",
              'note': null,
            },
          ],
        },
      });
      expect(s.secondaryTitles, ['Alt One', 'Alt Two']);
    });
  });

  group('display', () {
    const titles = SeriesTitles(
      main: 'DICE',
      native: '다이스',
      romanized: 'Daiseu',
      canonical: true,
    );

    test('each preference shows its own kind', () {
      expect(titles.display(TitleLanguage.defaultLang), 'DICE');
      expect(titles.display(TitleLanguage.native), '다이스');
      expect(titles.display(TitleLanguage.romanized), 'Daiseu');
    });

    test('falls back across kinds instead of showing nothing', () {
      const onlyNative = SeriesTitles(native: '다이스');
      for (final p in TitleLanguage.values) {
        expect(onlyNative.display(p), '다이스');
      }
      const noNative = SeriesTitles(main: 'DICE');
      expect(noNative.display(TitleLanguage.native), 'DICE');
      expect(noNative.display(TitleLanguage.romanized), 'DICE');
    });

    test('an empty main title falls back to the romanized one', () {
      const t = SeriesTitles(romanized: 'Daiseu', native: '다이스');
      expect(t.display(TitleLanguage.defaultLang), 'Daiseu');
    });

    test('alternatives drop the shown title, ignoring case and spacing', () {
      const t = SeriesTitles(main: 'DICE', native: '다이스', romanized: ' dice ');
      expect(t.alternatives(TitleLanguage.defaultLang), ['다이스']);
      expect(t.alternatives(TitleLanguage.native), ['DICE']);
    });

    test('Series.getDisplayTitle agrees with SeriesTitles.display', () {
      final s = Series.fromJson({
        'id': '1',
        'title': 'DICE',
        'native_title': '다이스',
        'romanized_title': 'Daiseu',
      });
      for (final p in TitleLanguage.values) {
        expect(s.getDisplayTitle(p), s.titles.display(p));
      }
    });
  });
}

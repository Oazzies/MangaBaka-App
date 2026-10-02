import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';

void main() {
  group('PublisherAlias', () {
    test('fromJson parses fields', () {
      final a = PublisherAlias.fromJson({
        'language': 'ja',
        'type': 'native',
        'title': '集英社',
        'note': 'primary',
      });
      expect(a.language, 'ja');
      expect(a.type, 'native');
      expect(a.title, '集英社');
      expect(a.note, 'primary');
    });

    test('fromJson defaults missing fields', () {
      final a = PublisherAlias.fromJson({});
      expect(a.language, '');
      expect(a.type, '');
      expect(a.title, '');
      expect(a.note, isNull);
    });

    test('toJson roundtrips fields', () {
      final a = PublisherAlias(language: 'en', type: 'romanized', title: 'Shueisha');
      final json = a.toJson();
      expect(json['language'], 'en');
      expect(json['type'], 'romanized');
      expect(json['title'], 'Shueisha');
      expect(json['note'], isNull);
    });
  });

  group('PublisherLink', () {
    test('fromJson + toJson roundtrip', () {
      final json = {'type': 'official', 'link': 'https://x.example', 'language': 'en'};
      final link = PublisherLink.fromJson(json);
      expect(link.type, 'official');
      expect(link.link, 'https://x.example');
      expect(link.language, 'en');
      expect(link.toJson(), json);
    });
  });

  group('Publisher', () {
    test('reads years sent as strings, blanks or numbers', () {
      final p = Publisher.fromJson({
        'id': 1,
        'name': 'X',
        'founded': '1990',
        'closed': '',
      });
      expect(p.founded, 1990);
      expect(p.closed, isNull);
      expect(Publisher.fromJson({'id': 1, 'name': 'X', 'founded': 1990.0}).founded, 1990);
    });

    test('fromJson parses minimal payload', () {
      final p = Publisher.fromJson({'id': 1, 'name': 'Shueisha'});
      expect(p.id, '1');
      expect(p.name, 'Shueisha');
      expect(p.aliases, isEmpty);
      expect(p.links, isEmpty);
      expect(p.imprints, isEmpty);
      expect(p.parent, isNull);
    });

    test('fromJson parses nested parent and imprints recursively', () {
      final p = Publisher.fromJson({
        'id': 1,
        'name': 'Imprint',
        'parent': {'id': 99, 'name': 'Parent Co'},
        'imprints': [
          {'id': 2, 'name': 'Sub A'},
          {'id': 3, 'name': 'Sub B'},
        ],
      });
      expect(p.parent?.id, '99');
      expect(p.parent?.name, 'Parent Co');
      expect(p.imprints.map((i) => i.name).toList(), ['Sub A', 'Sub B']);
    });

    test('toJson preserves nested structure', () {
      final p = Publisher(
        id: '1',
        type: 'company',
        subType: '',
        aliases: [PublisherAlias(language: 'en', type: 'romanized', title: 'X')],
        name: 'X Co',
        links: [PublisherLink(type: 'web', link: 'https://x', language: 'en')],
      );
      final json = p.toJson();
      expect(json['id'], '1');
      expect((json['aliases'] as List).first['title'], 'X');
      expect((json['links'] as List).first['link'], 'https://x');
      expect(json['parent'], isNull);
    });
  });

  group('Publisher (v2 fields)', () {
    test('reads ISO-date founded/closed as years', () {
      final p = Publisher.fromJson({
        'id': 35,
        'name': 'Shueisha',
        'founded': '1926-08-08',
        'closed': '2001-01-01',
      });
      expect(p.founded, 1926);
      expect(p.closed, 2001);
    });

    test('parses list-item fields without sub_type or aliases', () {
      final p = Publisher.fromJson({
        'id': 35,
        'name': 'Shueisha',
        'type': 'publisher',
        'canonical_url': 'https://mangabaka.org/publisher/35/Shueisha',
        'languages': ['ja'],
        'country_of_origin': 'JP',
        'logo': {'raw': 'r', 'x150': 'a', 'x250': 'b'},
        'series_count': 12380,
        'top_media_type': 'manga',
      });
      expect(p.subType, '');
      expect(p.canonicalUrl, contains('/publisher/35/'));
      expect(p.languages, ['ja']);
      expect(p.countryOfOrigin, 'JP');
      expect(p.seriesCount, 12380);
      expect(p.topMediaType, 'manga');
      expect(p.logo?.forSize(48), 'a');
      expect(p.logo?.forSize(100), 'b');
      expect(p.logo?.forSize(300), 'r');
    });

    test('a null or empty logo is no logo', () {
      expect(Publisher.fromJson({'id': 1, 'name': 'X', 'logo': null}).logo, isNull);
      expect(Publisher.fromJson({'id': 1, 'name': 'X', 'logo': {'raw': ''}}).logo, isNull);
    });

    test('imprints parse from the lightweight v2 shape', () {
      final p = Publisher.fromJson({
        'id': 35,
        'name': 'Shueisha',
        'imprints': [
          {'id': 36, 'name': 'MANGA Plus', 'canonical_url': 'https://x'},
        ],
      });
      expect(p.imprints.single.id, '36');
      expect(p.imprints.single.canonicalUrl, 'https://x');
    });

    test('toJson carries the v2 fields', () {
      final p = Publisher.fromJson({
        'id': 1,
        'name': 'X',
        'country_of_origin': 'JP',
        'series_count': 3,
        'logo': {'x150': 'a'},
      });
      final json = p.toJson();
      expect(json['country_of_origin'], 'JP');
      expect(json['series_count'], 3);
      expect((json['logo'] as Map)['x150'], 'a');
    });
  });
}

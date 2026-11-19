import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/browse/utils/staff_aggregator.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

Series _series({
  String id = '1',
  List<String> authors = const [],
  List<String> artists = const [],
}) {
  return Series.fromJson({
    'id': id,
    'title': 'Series $id',
    'authors': authors,
    'artists': artists,
  });
}

void main() {
  group('StaffAggregator.fromSeries', () {
    test('collects authors and artists', () {
      final staff = StaffAggregator.fromSeries(
        [
          _series(authors: ['Kentaro Miura'], artists: ['Studio Gaga']),
        ],
        '',
      );

      expect(staff.map((s) => s.name), containsAll(['Kentaro Miura', 'Studio Gaga']));
      expect(
        staff.firstWhere((s) => s.name == 'Kentaro Miura').role,
        'Author',
      );
      expect(
        staff.firstWhere((s) => s.name == 'Studio Gaga').role,
        'Artist',
      );
    });

    test('promotes someone credited both ways to Author / Artist', () {
      final staff = StaffAggregator.fromSeries(
        [
          _series(authors: ['Naoki Urasawa'], artists: ['Naoki Urasawa']),
        ],
        '',
      );

      expect(staff, hasLength(1));
      expect(staff.single.role, StaffAggregator.bothRoles);
    });

    test('folds one person across several series into one entry', () {
      final staff = StaffAggregator.fromSeries(
        [
          _series(id: '1', authors: ['Kentaro Miura']),
          _series(id: '2', authors: ['Kentaro Miura']),
        ],
        '',
      );

      expect(staff, hasLength(1));
      expect(staff.single.name, 'Kentaro Miura');
    });

    test('filters collaborators the query did not ask for', () {
      // A staff search returns everyone credited, not just who was searched for.
      final staff = StaffAggregator.fromSeries(
        [
          _series(authors: ['Kentaro Miura'], artists: ['Studio Gaga']),
        ],
        'miura',
      );

      expect(staff, hasLength(1));
      expect(staff.single.name, 'Kentaro Miura');
    });

    test('gives the same person a stable id across pages', () {
      final first = StaffAggregator.fromSeries(
        [_series(authors: ['Kentaro Miura'])],
        '',
      );
      final second = StaffAggregator.fromSeries(
        [_series(id: '2', authors: ['Kentaro Miura'])],
        '',
      );

      expect(first.single.id, second.single.id);
    });
  });

  group('StaffAggregator.merge', () {
    test('appends people not seen before', () {
      final existing = <Staff>[
        Staff(id: 1, name: 'A', role: 'Author', seriesCount: null),
      ];
      StaffAggregator.merge(existing, [
        Staff(id: 2, name: 'B', role: 'Artist', seriesCount: null),
      ]);

      expect(existing.map((s) => s.name), ['A', 'B']);
    });

    test('promotes a role when a later page reveals the other credit', () {
      final existing = <Staff>[
        Staff(id: 1, name: 'A', role: 'Author', seriesCount: null),
      ];
      StaffAggregator.merge(existing, [
        Staff(id: 1, name: 'A', role: 'Artist', seriesCount: null),
      ]);

      expect(existing, hasLength(1));
      expect(existing.single.role, StaffAggregator.bothRoles);
    });

    test('leaves a matching role untouched', () {
      final existing = <Staff>[
        Staff(id: 1, name: 'A', role: 'Author', seriesCount: null),
      ];
      StaffAggregator.merge(existing, [
        Staff(id: 1, name: 'A', role: 'Author', seriesCount: null),
      ]);

      expect(existing.single.role, 'Author');
    });
  });
}

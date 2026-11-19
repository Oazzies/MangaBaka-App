import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/series/models/tag_group.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class _FakeMetadata implements MetadataService {
  final Map<String, String> paths;

  _FakeMetadata(this.paths);

  @override
  String? getTagPath(String tagName) => paths[tagName];

  @override
  String? getTagId(String tagName) => 'id-$tagName';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TagGrouping.resolve', () {
    test('groups by the first path segment', () {
      final groups = TagGrouping.resolve(
        ['Historical', 'Magic'],
        _FakeMetadata({
          'Historical': 'Genre > Setting > Historical',
          'Magic': 'Genre > Theme > Magic',
        }),
      );

      expect(groups, hasLength(1));
      expect(groups.single.header, 'Genre');
      expect(groups.single.subGroups.keys, containsAll(['Setting', 'Theme']));
    });

    test('labels a chip with only the segments past the subheader', () {
      final groups = TagGrouping.resolve(
        ['Historical'],
        _FakeMetadata({'Historical': 'Genre > Setting > Historical'}),
      );

      expect(groups.single.subGroups['Setting']!.single.labelParts,
          ['Historical']);
    });

    test('a two-segment path has no subheader and labels with the leaf', () {
      final groups = TagGrouping.resolve(
        ['Action'],
        _FakeMetadata({'Action': 'Genre > Action'}),
      );

      expect(groups.single.header, 'Genre');
      expect(groups.single.subGroups.keys, ['']);
      expect(groups.single.subGroups['']!.single.labelParts, ['Action']);
    });

    test('a tag with no path lands under Other and labels with its own name',
        () {
      final groups = TagGrouping.resolve(['Weird'], _FakeMetadata({}));

      expect(groups.single.header, TagGrouping.fallbackHeader);
      expect(groups.single.subGroups['']!.single.labelParts, ['Weird']);
    });

    test('sorts headers so the card order is stable between opens', () {
      final groups = TagGrouping.resolve(
        ['Z', 'A'],
        _FakeMetadata({'Z': 'Zeta > Z', 'A': 'Alpha > A'}),
      );

      expect(groups.map((g) => g.header), ['Alpha', 'Zeta']);
    });

    test('carries the resolved tag id onto the chip', () {
      final groups = TagGrouping.resolve(
        ['Action'],
        _FakeMetadata({'Action': 'Genre > Action'}),
      );

      expect(groups.single.subGroups['']!.single.tagId, 'id-Action');
    });
  });

  group('TagGrouping.trimTo', () {
    List<TagGroup> build() => TagGrouping.resolve(
          ['A', 'B', 'C', 'D'],
          _FakeMetadata({
            'A': 'One > A',
            'B': 'One > B',
            'C': 'Two > C',
            'D': 'Two > D',
          }),
        );

    int chipCount(List<TagGroup> groups) => groups.fold(
          0,
          (sum, g) => sum + g.subGroups.values.fold(0, (s, v) => s + v.length),
        );

    test('keeps everything when the budget is not exceeded', () {
      expect(chipCount(TagGrouping.trimTo(build(), 10)), 4);
    });

    test('stops at the budget', () {
      expect(chipCount(TagGrouping.trimTo(build(), 3)), 3);
    });

    test('a zero budget yields nothing', () {
      expect(chipCount(TagGrouping.trimTo(build(), 0)), 0);
    });

    test('trims from the tail, keeping the leading groups intact', () {
      final trimmed = TagGrouping.trimTo(build(), 2);
      expect(trimmed.first.header, 'One');
      expect(chipCount(trimmed), 2);
    });
  });
}

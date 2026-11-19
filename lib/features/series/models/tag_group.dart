import 'package:mangabaka_app/features/series/models/tag_chip_data.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

class TagGroup {
  final String header;
  final Map<String, List<TagChipData>> subGroups;

  const TagGroup(this.header, this.subGroups);
}

class TagGrouping {
  TagGrouping._();

  static const String pathSeparator = ' > ';

  static const String fallbackHeader = 'Other';

  static List<TagGroup> resolve(List<String> tags, MetadataService metadata) {
    final grouped = <String, Map<String, List<TagChipData>>>{};

    for (final tag in tags) {
      final path = metadata.getTagPath(tag) ?? tag;
      final parts = path.split(pathSeparator);

      final header = parts.length >= 2 ? parts[0] : fallbackHeader;
      final subheader = parts.length >= 3 ? parts[1] : '';

      grouped
          .putIfAbsent(header, () => {})
          .putIfAbsent(subheader, () => [])
          .add(
            TagChipData(
              tag: tag,
              tagId: metadata.getTagId(tag) ?? tag,
              labelParts: _labelParts(tag, parts),
            ),
          );
    }

    final headers = grouped.keys.toList()..sort();
    return [for (final header in headers) TagGroup(header, grouped[header]!)];
  }

  static List<String> _labelParts(String tag, List<String> parts) {
    if (parts.length == 2) return [parts[1]];
    if (parts.length >= 3) return parts.sublist(2);
    return [tag];
  }

  /// Bounds the collapsed card's build: a 250-tag series used to build every chip to show about 35.
  static List<TagGroup> trimTo(List<TagGroup> groups, int budget) {
    final trimmed = <TagGroup>[];
    var remaining = budget;

    for (final group in groups) {
      if (remaining <= 0) break;
      final subGroups = <String, List<TagChipData>>{};
      for (final entry in group.subGroups.entries) {
        if (remaining <= 0) break;
        final chips = entry.value.length <= remaining
            ? entry.value
            : entry.value.sublist(0, remaining);
        subGroups[entry.key] = chips;
        remaining -= chips.length;
      }
      trimmed.add(TagGroup(group.header, subGroups));
    }
    return trimmed;
  }
}

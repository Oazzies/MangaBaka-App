import 'package:mangabaka_app/features/series/models/tag_chip_data.dart';
import 'package:mangabaka_app/features/series/services/metadata_service.dart';

/// One resolved tag header, with its tags bucketed by subheader.
class TagGroup {
  final String header;
  final Map<String, List<TagChipData>> subGroups;

  const TagGroup(this.header, this.subGroups);
}

/// Turns a series' raw tag names into the grouped, labelled chips the tags
/// card renders.
///
/// Every tag is resolved through [MetadataService] exactly once: its path
/// drives both the grouping and the chip's display label, and its id drives
/// the selected state. A well-tagged series carries a couple of hundred tags,
/// so redoing any of that per rebuild is what made opening a series stall.
///
/// Pure apart from the metadata lookup, and separate from the widget so the
/// path parsing and the collapse budget can be tested directly.
class TagGrouping {
  TagGrouping._();

  /// Separator the API uses between path segments, e.g.
  /// `Genre > Setting > Historical`.
  static const String pathSeparator = ' > ';

  /// Header for a tag with no path — an uncategorised tag still has to land
  /// somewhere.
  static const String fallbackHeader = 'Other';

  /// Groups [tags] by the first two segments of each one's path.
  ///
  /// Headers come back sorted so the card's order is stable between opens
  /// rather than following whatever order the API listed the tags in.
  static List<TagGroup> resolve(List<String> tags, MetadataService metadata) {
    final grouped = <String, Map<String, List<TagChipData>>>{};

    for (final tag in tags) {
      final path = metadata.getTagPath(tag) ?? tag;
      final parts = path.split(pathSeparator);

      // `A` -> Other / (none); `A > B` -> A / (none); `A > B > C…` -> A / B.
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

  /// What the chip actually reads.
  ///
  /// The segments already shown as the header and subheader are dropped, so a
  /// chip under "Genre / Setting" says "Historical" rather than repeating its
  /// whole path. A tag with no path falls back to its own name.
  static List<String> _labelParts(String tag, List<String> parts) {
    if (parts.length == 2) return [parts[1]];
    if (parts.length >= 3) return parts.sublist(2);
    return [tag];
  }

  /// The leading [budget] chips' worth of [groups], for the collapsed card.
  ///
  /// Collapsed, the card clips to a fixed height — roughly three or four dozen
  /// chips. Everything past that was still being built, laid out and measured
  /// only to be thrown away behind the clip: a series with 250 tags paid for
  /// 250 chips to show about 35. Trimming here bounds the cost of opening a
  /// series no matter how heavily tagged it is; expanding builds the rest.
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

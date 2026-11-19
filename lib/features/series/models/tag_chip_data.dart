class TagChipData {
  final String tag;

  /// Falls back to [tag] when the id is unknown.
  final String tagId;

  final List<String> labelParts;

  const TagChipData({
    required this.tag,
    required this.tagId,
    required this.labelParts,
  });
}

/// The shapes of list the importer understands.
enum ImportFormat {
  /// Work out the format from the text itself.
  auto,

  /// One title per line.
  plain,

  /// Rows with a title column, and optionally a status column.
  csv,

  /// A JSON array of titles or of objects carrying one.
  json,

  /// A MyAnimeList manga export (`<myanimelist><manga>…`).
  myAnimeList,

  /// A Manga-Updates JSON list export.
  mangaUpdates,

  /// A MangaBaka JSON backup file.
  mangaBaka,
}

/// One title read from an import source, with the state its source gave it, if
/// any.
class ImportEntry {
  final String title;

  /// A MangaBaka library state (`reading`, `completed`, …), or null when the
  /// source did not say or said something unrecognisable.
  final String? state;

  const ImportEntry(this.title, {this.state});

  @override
  bool operator ==(Object other) =>
      other is ImportEntry && other.title == title && other.state == state;

  @override
  int get hashCode => Object.hash(title, state);

  @override
  String toString() => 'ImportEntry($title, $state)';
}

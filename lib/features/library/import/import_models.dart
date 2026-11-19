enum ImportFormat {
  auto,

  plain,

  csv,

  json,

  myAnimeList,

  mangaUpdates,

  mangaBaka,
}

class ImportEntry {
  final String title;

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

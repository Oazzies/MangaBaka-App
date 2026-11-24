import 'package:mangabaka_app/features/lists/models/library_list.dart';

enum LibraryListSort {
  nameAsc('lists_sort_name_asc'),
  nameDesc('lists_sort_name_desc'),
  mostSeries('lists_sort_most_series'),
  fewestSeries('lists_sort_fewest_series'),
  newest('lists_sort_newest'),
  oldest('lists_sort_oldest'),
  publicFirst('lists_sort_public_first'),
  privateFirst('lists_sort_private_first');

  final String labelKey;

  const LibraryListSort(this.labelKey);

  static LibraryListSort fromName(String? name) => values.firstWhere(
    (s) => s.name == name,
    orElse: () => LibraryListSort.nameAsc,
  );

  /// Ties break by name, then id, so the order never jumps between rebuilds.
  int compare(LibraryList a, LibraryList b, int Function(LibraryList) countOf) {
    int byName() {
      final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    // Ids grow with creation, so they stand in for a missing created_at.
    int byAge() {
      final ad = a.createdAt, bd = b.createdAt;
      final c = (ad != null && bd != null) ? ad.compareTo(bd) : 0;
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    int tieBreak(int c) => c != 0 ? c : byName();
    return switch (this) {
      nameAsc => byName(),
      nameDesc => -byName(),
      mostSeries => tieBreak(countOf(b).compareTo(countOf(a))),
      fewestSeries => tieBreak(countOf(a).compareTo(countOf(b))),
      newest => -byAge(),
      oldest => byAge(),
      publicFirst => tieBreak(_flag(a.isPrivate).compareTo(_flag(b.isPrivate))),
      privateFirst => tieBreak(
        _flag(b.isPrivate).compareTo(_flag(a.isPrivate)),
      ),
    };
  }

  static int _flag(bool v) => v ? 1 : 0;
}

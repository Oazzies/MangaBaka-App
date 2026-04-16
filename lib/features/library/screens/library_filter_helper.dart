import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:bakahyou/features/library/services/state_normalizer.dart';

class LibraryFilterHelper {
  final List<LibraryEntry> allEntries;
  final String query;

  LibraryFilterHelper({
    required this.allEntries,
    required this.query,
  });

  List<LibraryEntry> getFilteredByQuery() {
    if (query.isEmpty) return allEntries;

    return allEntries
        .where((entry) =>
            entry.series.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<LibraryEntry> getByTab(String tabKey) {
    final filtered = getFilteredByQuery();

    return filtered.where((entry) {
      var state = StateNormalizer.normalize(entry.state);
      if (!LibraryScreenConstants.knownStates.contains(state)) {
        state = 'reading';
      }
      return state == tabKey;
    }).toList();
  }
}
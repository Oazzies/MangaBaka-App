import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/screens/library_screen_constants.dart';
import 'package:bakahyou/features/library/services/state_normalizer.dart';

class LibraryFilterHelper {
  final List<LibraryEntry> allEntries;
  final String query;
  final List<String> contentPreferences;

  LibraryFilterHelper({required this.allEntries, required this.query, required this.contentPreferences});

  List<LibraryEntry> getFilteredByQuery() {
    if (query.isEmpty && contentPreferences.isEmpty) return allEntries;

    return allEntries
        .where((entry) {
          final matchesQuery = query.isEmpty ||
              entry.series.title.toLowerCase().contains(query.toLowerCase());
          final matchesRating = contentPreferences.isEmpty ||
              contentPreferences.contains(entry.series.contentRating.toLowerCase());
          return matchesQuery && matchesRating;
        })
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

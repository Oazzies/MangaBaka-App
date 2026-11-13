import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// Builds the Staff results, which the API does not serve directly.
///
/// There is no staff endpoint: the tab searches series by staff name and
/// derives the people from the credits on the results. The same person turns
/// up once per series they worked on, and separately as author and as artist,
/// so they have to be folded together — both within a page and across the
/// pages already loaded.
///
/// Pure and stateless, so the merge rules can be tested without a controller.
class StaffAggregator {
  StaffAggregator._();

  /// The role given to someone credited both ways on the same body of work.
  static const String bothRoles = 'Author / Artist';

  /// Collapses the credits across [series] into one entry per person.
  ///
  /// [query] filters by name: the search matched whole *series*, so a result
  /// brings in every collaborator on it, most of whom the user did not ask
  /// for. An empty query keeps everyone.
  static List<Staff> fromSeries(List<Series> series, String query) {
    final byName = <String, Staff>{};
    final needle = SearchUtils.prepare(query);

    void upsert(String name, String role) {
      if (!needle.isEmpty && !needle.matches(name)) return;
      final existing = byName[name];
      byName[name] = Staff(
        // Names are the identity here — there is no staff id in the payload —
        // so the hash keeps it stable across pages.
        id: existing?.id ?? name.hashCode,
        name: name,
        role: _mergeRoles(existing?.role, role),
        seriesCount: null,
      );
    }

    for (final entry in series) {
      for (final author in entry.authors) {
        upsert(author, 'Author');
      }
      for (final artist in entry.artists) {
        upsert(artist, 'Artist');
      }
    }

    return byName.values.toList()
      ..sort((a, b) => (b.seriesCount ?? 0).compareTo(a.seriesCount ?? 0));
  }

  /// Adds [incoming] to [existing] in place, promoting the role of anyone who
  /// turns out to be credited both ways once a later page reveals it.
  static void merge(List<Staff> existing, List<Staff> incoming) {
    for (final staff in incoming) {
      final index = existing.indexWhere((s) => s.name == staff.name);
      if (index == -1) {
        existing.add(staff);
        continue;
      }
      final current = existing[index];
      if (current.role == staff.role) continue;
      existing[index] = Staff(
        id: current.id,
        name: current.name,
        role: bothRoles,
        seriesCount: null,
      );
    }
  }

  static String _mergeRoles(String? existing, String incoming) {
    if (existing == null) return incoming;
    return existing == incoming ? existing : bothRoles;
  }
}

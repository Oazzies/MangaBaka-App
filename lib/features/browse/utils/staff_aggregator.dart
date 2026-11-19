import 'package:mangabaka_app/core/utils/search_utils.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

/// No staff endpoint exists: people come from series credits, folded across series and roles.
class StaffAggregator {
  StaffAggregator._();

  /// [query] filters by name: a matched series brings in every collaborator on it.
  static List<Staff> fromSeries(List<Series> series, String query) {
    final byName = <String, Staff>{};
    final needle = SearchUtils.prepare(query);

    void upsert(String name, StaffRole role) {
      if (!needle.isEmpty && !needle.matches(name)) return;
      final existing = byName[name];
      byName[name] = Staff(
        // The payload has no staff id, so the name hash keeps identity stable across pages.
        id: existing?.id ?? name.hashCode,
        name: name,
        role: existing?.role?.mergedWith(role) ?? role,
        seriesCount: null,
      );
    }

    for (final entry in series) {
      for (final author in entry.authors) {
        upsert(author, StaffRole.author);
      }
      for (final artist in entry.artists) {
        upsert(artist, StaffRole.artist);
      }
    }

    return byName.values.toList()
      ..sort((a, b) => (b.seriesCount ?? 0).compareTo(a.seriesCount ?? 0));
  }

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
        role: StaffRole.authorAndArtist,
        seriesCount: null,
      );
    }
  }
}

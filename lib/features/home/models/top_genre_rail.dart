import 'package:mangabaka_app/features/series/models/series.dart';

/// [tagId] is what `/v2/series/search?tag=` takes; [affinity] only orders genres, higher first.
class TopGenre {
  final int tagId;
  final String name;
  final double affinity;

  const TopGenre({
    required this.tagId,
    required this.name,
    required this.affinity,
  });

  static TopGenre? tryParse(Object? item) {
    if (item is! Map) return null;
    final id = item['tag_id'];
    final name = item['tag_name']?.toString() ?? '';
    if (id is! num || name.isEmpty) return null;
    return TopGenre(
      tagId: id.toInt(),
      name: name,
      affinity: (item['affinity_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TopGenreRail {
  final TopGenre genre;
  final List<Series> series;

  const TopGenreRail(this.genre, this.series);
}

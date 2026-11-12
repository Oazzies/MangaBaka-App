import 'package:mangabaka_app/features/series/models/series.dart';

/// A related series entry returned by `/v1/series/{id}/relationships`.
class RelatedSeries {
  final String relationType;
  final Series series;
  final String? note;

  const RelatedSeries({
    required this.relationType,
    required this.series,
    this.note,
  });

  static RelatedSeries? fromJson(Map<String, dynamic> json) {
    final nested = json['series'];
    if (nested is! Map) return null;
    final relationType = json['relation_type']?.toString().trim() ?? '';
    final note = json['note']?.toString().trim();
    return RelatedSeries(
      relationType: relationType,
      series: Series.fromJson(nested.cast<String, dynamic>()),
      note: (note != null && note.isNotEmpty) ? note : null,
    );
  }
}

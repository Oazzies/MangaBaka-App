import 'package:mangabaka_app/features/series/models/series.dart';

class LibraryEntry {
  final String id;
  final String state;
  final String? note;
  final int? progressChapter;
  final int? progressVolume;
  final int? numberOfRereads;
  final int? rating;
  final String? updatedAt;
  final String? createdAt;
  final Series series;

  LibraryEntry({
    required this.id,
    required this.state,
    this.note,
    this.progressChapter,
    this.progressVolume,
    this.numberOfRereads,
    this.rating,
    this.updatedAt,
    this.createdAt,
    required this.series,
  });

  factory LibraryEntry.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['Series'] ?? json['series'];
    if (rawSeries is! Map) {
      throw FormatException('Library entry missing Series payload');
    }

    // The id is the local primary key; a throw makes the sync skip it and not prune a partial list.
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw FormatException('Library entry has no id');
    }
    final series = Series.fromJson(rawSeries.cast<String, dynamic>());
    if (series.id.isEmpty) {
      throw FormatException('Library entry series has no id');
    }

    return LibraryEntry(
      id: id,
      state: json['state']?.toString() ?? '',
      note: json['note']?.toString(),
      progressChapter: _asInt(json['progress_chapter']),
      progressVolume: _asInt(json['progress_volume']),
      numberOfRereads: _asInt(json['number_of_rereads']),
      rating: _asInt(json['rating']),
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      series: series,
    );
  }

  /// Lenient: a throw drops the entry, and a full import would then prune it as if deleted.
  static int? _asInt(Object? raw) => switch (raw) {
    final num n => n.toInt(),
    final String s => num.tryParse(s)?.toInt(),
    _ => null,
  };
}

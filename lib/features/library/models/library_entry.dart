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
    if (rawSeries is! Map<String, dynamic>) {
      throw FormatException('Library entry missing Series payload');
    }

    return LibraryEntry(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      note: json['note']?.toString(),
      progressChapter: _asInt(json['progress_chapter']),
      progressVolume: _asInt(json['progress_volume']),
      numberOfRereads: _asInt(json['number_of_rereads']),
      rating: _asInt(json['rating']),
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      series: Series.fromJson(rawSeries),
    );
  }

  /// Numbers that arrive as strings (`"12"`, `"12.5"`) are read rather than
  /// thrown on: a throw drops the whole entry, and the full import then
  /// prunes that entry from the local library as if it had been deleted.
  static int? _asInt(Object? raw) => switch (raw) {
        final num n => n.toInt(),
        final String s => num.tryParse(s)?.toInt(),
        _ => null,
      };
}

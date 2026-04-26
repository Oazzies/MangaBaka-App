import 'package:bakahyou/features/series/models/series.dart';

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
      throw Exception('Library entry missing Series payload');
    }

    return LibraryEntry(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      note: json['note']?.toString(),
      progressChapter: (json['progress_chapter'] as num?)?.toInt(),
      progressVolume: (json['progress_volume'] as num?)?.toInt(),
      numberOfRereads: (json['number_of_rereads'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      series: Series.fromJson(rawSeries),
    );
  }
}

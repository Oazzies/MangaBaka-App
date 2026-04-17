import 'package:bakahyou/features/series/models/series.dart';

class LibraryEntry {
  final String id;
  final String state;
  final String? note;
  final int? progressChapter;
  final int? progressVolume;
  final int? numberOfRereads;
  final int? rating;
  final Series series;

  LibraryEntry({
    required this.id,
    required this.state,
    this.note,
    this.progressChapter,
    this.progressVolume,
    this.numberOfRereads,
    this.rating,
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
      series: Series.fromJson(rawSeries),
    );
  }
}
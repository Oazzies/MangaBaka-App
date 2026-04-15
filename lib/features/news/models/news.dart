import 'package:mangabaka_app/features/series/models/series.dart';

class News {
  final String id;
  final String title;
  final String url;
  final String author;
  final String source;
  final String publishedAt;
  final List<Series> series;

  News({
    required this.id,
    required this.title,
    required this.url,
    required this.author,
    required this.source,
    required this.publishedAt,
    required this.series,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    var seriesList =
        (json['series'] as List<dynamic>?)
            ?.map((item) => Series.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return News(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      series: seriesList,
    );
  }
}

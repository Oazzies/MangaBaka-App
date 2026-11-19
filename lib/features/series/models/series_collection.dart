class SeriesCollection {
  final String id;

  /// Empty when the response omitted it.
  final String seriesId;
  final String title;
  final String format;
  final String type;
  final String status;
  final String medium;
  final String publisherName;

  final String publisherId;
  final String editionName;
  final String languageName;
  final int countMain;

  SeriesCollection({
    required this.id,
    this.seriesId = '',
    required this.title,
    required this.format,
    required this.type,
    required this.status,
    required this.medium,
    required this.publisherName,
    this.publisherId = '',
    required this.editionName,
    this.languageName = '',
    required this.countMain,
  });

  factory SeriesCollection.fromJson(Map<String, dynamic> json) {
    return SeriesCollection(
      id: json['id']?.toString() ?? '',
      seriesId: json['series_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
      publisherName: json['publisher']?['name']?.toString() ?? '',
      publisherId: json['publisher']?['id']?.toString() ?? '',
      editionName: json['edition']?['name']?.toString() ?? '',
      languageName: json['language']?['language']?.toString() ?? '',
      countMain: (json['count_main'] as num?)?.toInt() ?? 0,
    );
  }
}

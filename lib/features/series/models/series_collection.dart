class SeriesCollection {
  final String id;
  final String title;
  final String format;
  final String type;
  final String status;
  final String medium;
  final String publisherName;
  final String editionName;
  final int countMain;

  SeriesCollection({
    required this.id,
    required this.title,
    required this.format,
    required this.type,
    required this.status,
    required this.medium,
    required this.publisherName,
    required this.editionName,
    required this.countMain,
  });

  factory SeriesCollection.fromJson(Map<String, dynamic> json) {
    return SeriesCollection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
      publisherName: json['publisher']?['name']?.toString() ?? '',
      editionName: json['edition']?['name']?.toString() ?? '',
      countMain: (json['count_main'] as num?)?.toInt() ?? 0,
    );
  }
}

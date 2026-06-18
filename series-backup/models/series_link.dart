class SeriesLink {
  final String id;
  final String url;
  final String name;
  final String nameDisplay;
  final String type;
  final String? language;

  SeriesLink({
    required this.id,
    required this.url,
    required this.name,
    required this.nameDisplay,
    required this.type,
    this.language,
  });

  factory SeriesLink.fromJson(Map<String, dynamic> json) {
    return SeriesLink(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      name: json['name'] ?? '',
      nameDisplay: json['name_display'] ?? '',
      type: json['type'] ?? '',
      language: json['language'],
    );
  }
}

class Genre {
  final String label;
  final String value;

  Genre({required this.label, required this.value});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}
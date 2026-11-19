class SeriesPublisher {
  final String id;
  final String name;
  final String? canonicalUrl;

  final String? language;

  /// e.g. `Original` or `English`.
  final String? role;

  const SeriesPublisher({
    required this.id,
    required this.name,
    this.canonicalUrl,
    this.language,
    this.role,
  });

  static SeriesPublisher? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = json['name']?.toString() ?? '';
    if (name.isEmpty) return null;
    String? read(String key) {
      final v = json[key]?.toString();
      return (v == null || v.isEmpty) ? null : v;
    }

    return SeriesPublisher(
      id: json['id']?.toString() ?? '',
      name: name,
      canonicalUrl: read('canonical_url'),
      language: read('language'),
      role: read('type'),
    );
  }
}

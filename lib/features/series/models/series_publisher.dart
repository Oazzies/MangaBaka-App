/// A publisher as embedded in a series: enough to link through to the
/// publisher page by id and to tell regional editions apart.
class SeriesPublisher {
  final String id;
  final String name;
  final String? canonicalUrl;

  /// Language of this publisher's edition (`en`, `ko`, ...).
  final String? language;

  /// Role on this series, e.g. `Original` or `English`.
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

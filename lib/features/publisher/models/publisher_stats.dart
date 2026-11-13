/// One bucket of a [PublisherStats] distribution (`media_type`, `status`, ...).
class StatBucket {
  final String key;
  final int count;

  const StatBucket({required this.key, required this.count});
}

/// A named entry in the `known_for` / `genres` / `audience` lists.
class StatTag {
  final String id;
  final String name;
  final int count;
  final double share;
  final double catalogShare;

  const StatTag({
    required this.id,
    required this.name,
    required this.count,
    required this.share,
    required this.catalogShare,
  });

  double get lift => catalogShare > 0 ? share / catalogShare : 0;
}

/// A publisher that shares series with the one the stats belong to.
class SharedPublisher {
  final String id;
  final String name;
  final int sharedCount;

  const SharedPublisher({
    required this.id,
    required this.name,
    required this.sharedCount,
  });
}

/// Catalog statistics from `/publishers/{id}/stats`.
class PublisherStats {
  final int seriesCount;
  final int taggedCount;
  final int hasAnime;
  final double? averageScore;
  final int? firstYear;
  final int? lastYear;
  final List<StatBucket> mediaTypes;
  final List<StatBucket> statuses;
  final List<StatBucket> contentRatings;
  final List<StatBucket> decades;
  final List<StatTag> knownFor;
  final List<StatTag> genres;
  final List<StatTag> audience;
  final List<SharedPublisher> sharesWith;

  const PublisherStats({
    this.seriesCount = 0,
    this.taggedCount = 0,
    this.hasAnime = 0,
    this.averageScore,
    this.firstYear,
    this.lastYear,
    this.mediaTypes = const [],
    this.statuses = const [],
    this.contentRatings = const [],
    this.decades = const [],
    this.knownFor = const [],
    this.genres = const [],
    this.audience = const [],
    this.sharesWith = const [],
  });

  static List<StatBucket> _buckets(Object? raw, String keyField) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map)
          StatBucket(
            key: e[keyField]?.toString() ?? '',
            count: (e['count'] as num?)?.toInt() ?? 0,
          ),
  ];

  static List<StatTag> _tags(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map)
          StatTag(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            count: (e['count'] as num?)?.toInt() ?? 0,
            share: (e['share'] as num?)?.toDouble() ?? 0,
            catalogShare: (e['catalog_share'] as num?)?.toDouble() ?? 0,
          ),
  ];

  factory PublisherStats.fromJson(Map<String, dynamic> json) {
    final years = json['years'];
    final score = json['score'];
    final shares = json['shares_with'];
    return PublisherStats(
      seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
      taggedCount: (json['tagged_count'] as num?)?.toInt() ?? 0,
      hasAnime: (json['has_anime'] as num?)?.toInt() ?? 0,
      averageScore: score is Map
          ? (score['average'] as num?)?.toDouble()
          : null,
      firstYear: years is Map ? (years['first'] as num?)?.toInt() : null,
      lastYear: years is Map ? (years['last'] as num?)?.toInt() : null,
      mediaTypes: _buckets(json['media_type'], 'key'),
      statuses: _buckets(json['status'], 'key'),
      contentRatings: _buckets(json['content_rating'], 'key'),
      decades: _buckets(json['decades'], 'decade'),
      knownFor: _tags(json['known_for']),
      genres: _tags(json['genres']),
      audience: _tags(json['audience']),
      sharesWith: [
        if (shares is List)
          for (final e in shares)
            if (e is Map)
              SharedPublisher(
                id: e['id']?.toString() ?? '',
                name: e['name']?.toString() ?? '',
                sharedCount: (e['shared_count'] as num?)?.toInt() ?? 0,
              ),
      ],
    );
  }
}

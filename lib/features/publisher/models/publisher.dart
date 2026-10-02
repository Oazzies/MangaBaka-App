import 'dart:convert';

/// Logo variants served by the v2 publisher endpoints. Any of them may be
/// missing, and the whole object is null for publishers without artwork.
class PublisherLogo {
  final String? raw;
  final String? x150;
  final String? x250;

  const PublisherLogo({this.raw, this.x150, this.x250});

  static PublisherLogo? fromJson(Object? json) {
    if (json is! Map) return null;
    String? read(String key) {
      final value = json[key]?.toString();
      return (value == null || value.isEmpty) ? null : value;
    }

    final logo = PublisherLogo(raw: read('raw'), x150: read('x150'), x250: read('x250'));
    return logo.best == null ? null : logo;
  }

  String? get best => x250 ?? x150 ?? raw;

  static bool _isSvg(String url) =>
      (Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.svg');

  /// SVG logos are served as-is for every size, and parsing them on the UI
  /// thread janks scrolling. The image CDN renders any source URL to a webp at
  /// a given size (`plain/<size>/<base64url of the source>.webp`), so SVGs are
  /// requested that way and take the ordinary raster path.
  static String _rasterised(String url, String size) {
    if (!_isSvg(url)) return url;
    final encoded = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    return 'https://cdn.mangabaka.dev/imgproxy/plain/$size/$encoded.webp';
  }

  /// Best variant for a thumbnail of roughly [size] logical pixels.
  String? forSize(double size) {
    final String? url;
    final String proxy;
    if (size <= 75) {
      url = x150 ?? x250 ?? raw;
      proxy = 'x150@2';
    } else {
      url = (size <= 125 ? (x250 ?? x150 ?? raw) : (raw ?? x250 ?? x150));
      proxy = 'x250@2';
    }
    return url == null ? null : _rasterised(url, proxy);
  }


  Map<String, dynamic> toJson() => {'raw': raw, 'x150': x150, 'x250': x250};
}

class Publisher {
  final String id;
  final String type;
  final String subType;
  final List<PublisherAlias> aliases;
  final String? parentId;
  final String name;
  final List<PublisherLink> links;
  final Publisher? parent;
  final List<Publisher> imprints;
  final int? founded;
  final int? closed;
  final String? description;
  final String? note;

  /// v2 fields.
  final String? canonicalUrl;
  final PublisherLogo? logo;
  final List<String> languages;
  final String? countryOfOrigin;
  final int? seriesCount;
  final String? topMediaType;

  Publisher({
    required this.id,
    this.type = '',
    this.subType = '',
    this.aliases = const [],
    this.parentId,
    required this.name,
    this.links = const [],
    this.parent,
    this.imprints = const [],
    this.founded,
    this.closed,
    this.description,
    this.note,
    this.canonicalUrl,
    this.logo,
    this.languages = const [],
    this.countryOfOrigin,
    this.seriesCount,
    this.topMediaType,
  });

  static final RegExp _isoYear = RegExp(r'^(\d{4})-');

  /// The API sends years as numbers, as strings ("1990"), as ISO dates
  /// ("1926-08-08", v2) and sometimes as an empty string for "unknown";
  /// anything unreadable is null.
  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final text = value.trim();
      final match = _isoYear.firstMatch(text);
      return int.tryParse(match?.group(1) ?? text);
    }
    return null;
  }

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ];
  }

  factory Publisher.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'];
    return Publisher(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      subType: json['sub_type']?.toString() ?? '',
      aliases: _list(json['aliases'], PublisherAlias.fromJson),
      parentId: json['parent_id']?.toString(),
      name: json['name']?.toString() ?? '',
      links: _list(json['links'], PublisherLink.fromJson),
      parent: parent is Map ? Publisher.fromJson(Map<String, dynamic>.from(parent)) : null,
      imprints: _list(json['imprints'], Publisher.fromJson),
      founded: _asInt(json['founded']),
      closed: _asInt(json['closed']),
      description: json['description']?.toString(),
      note: json['note']?.toString(),
      canonicalUrl: json['canonical_url']?.toString(),
      logo: PublisherLogo.fromJson(json['logo']),
      languages: [
        for (final l in (json['languages'] as List? ?? const [])) l.toString(),
      ],
      countryOfOrigin: json['country_of_origin']?.toString(),
      seriesCount: _asInt(json['series_count']),
      topMediaType: json['top_media_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'sub_type': subType,
      'aliases': aliases.map((a) => a.toJson()).toList(),
      'parent_id': parentId,
      'name': name,
      'links': links.map((l) => l.toJson()).toList(),
      'parent': parent?.toJson(),
      'imprints': imprints.map((i) => i.toJson()).toList(),
      'founded': founded,
      'closed': closed,
      'description': description,
      'note': note,
      'canonical_url': canonicalUrl,
      'logo': logo?.toJson(),
      'languages': languages,
      'country_of_origin': countryOfOrigin,
      'series_count': seriesCount,
      'top_media_type': topMediaType,
    };
  }
}

class PublisherLink {
  final String type;
  final String link;
  final String language;

  PublisherLink({
    required this.type,
    required this.link,
    required this.language,
  });

  factory PublisherLink.fromJson(Map<String, dynamic> json) {
    return PublisherLink(
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      language: json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'link': link,
      'language': language,
    };
  }
}

class PublisherAlias {
  final String language;
  final String type;
  final String title;
  final String? note;

  PublisherAlias({
    required this.language,
    required this.type,
    required this.title,
    this.note,
  });

  factory PublisherAlias.fromJson(Map<String, dynamic> json) {
    return PublisherAlias(
      language: json['language'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'type': type,
      'title': title,
      'note': note,
    };
  }
}

/// A publisher suggested by `/publishers/{id}/similar`.
class SimilarPublisher {
  final String id;
  final String name;
  final String? canonicalUrl;
  final int hits;
  final double score;

  const SimilarPublisher({
    required this.id,
    required this.name,
    this.canonicalUrl,
    this.hits = 0,
    this.score = 0,
  });

  factory SimilarPublisher.fromJson(Map<String, dynamic> json) => SimilarPublisher(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        canonicalUrl: json['canonical_url']?.toString(),
        hits: (json['hits'] as num?)?.toInt() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0,
      );
}

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

  /// Fraction of the publisher's catalog carrying this tag.
  final double share;

  /// Fraction of the whole site catalog carrying it.
  final double catalogShare;

  const StatTag({
    required this.id,
    required this.name,
    required this.count,
    required this.share,
    required this.catalogShare,
  });

  /// How over-represented the tag is for this publisher versus the site.
  double get lift => catalogShare > 0 ? share / catalogShare : 0;
}

/// A publisher that shares series with the one the stats belong to.
class SharedPublisher {
  final String id;
  final String name;
  final int sharedCount;

  const SharedPublisher({required this.id, required this.name, required this.sharedCount});
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
      averageScore: score is Map ? (score['average'] as num?)?.toDouble() : null,
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

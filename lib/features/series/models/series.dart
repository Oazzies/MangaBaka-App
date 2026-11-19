import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/series/models/series_publisher.dart';
import 'package:mangabaka_app/features/series/models/series_titles.dart';

export 'package:mangabaka_app/features/series/models/series_publisher.dart';

class Series {
  final String id;
  final String state;
  final String? mergedWith;
  final String title;
  final String nativeTitle;
  final String romanizedTitle;
  final List<String> secondaryTitles;
  final String coverUrl;
  final String rawCoverUrl;
  final List<String> authors;
  final List<String> artists;
  final String description;
  final String year;
  final Map<String, dynamic>? published;
  final String status;
  final String isLicensed;
  final String hasAnime;
  final Map<String, dynamic>? anime;
  final String contentRating;
  final String type;
  final String rating;
  final String finalVolume;
  final String totalChapters;
  final List<dynamic> links;
  final List<String> publishers;

  /// Not persisted locally, so empty for series rebuilt from the library cache.
  final List<SeriesPublisher> publisherRefs;
  final List<String> genres;
  final List<String> tags;
  final String lastUpdated;
  final Map<String, dynamic>? relationships;
  final Map<String, dynamic>? source;

  Series({
    required this.id,
    required this.state,
    this.mergedWith,
    required this.title,
    required this.nativeTitle,
    required this.romanizedTitle,
    required this.secondaryTitles,
    required this.coverUrl,
    required this.rawCoverUrl,
    required this.authors,
    required this.artists,
    required this.description,
    required this.year,
    this.published,
    required this.status,
    required this.isLicensed,
    required this.hasAnime,
    this.anime,
    required this.contentRating,
    required this.type,
    required this.rating,
    required this.finalVolume,
    required this.totalChapters,
    required this.links,
    required this.publishers,
    this.publisherRefs = const [],
    required this.genres,
    required this.tags,
    required this.lastUpdated,
    this.relationships,
    this.source,
  });

  Series copyWithTitles(SeriesTitles t) => Series(
    id: id,
    state: state,
    mergedWith: mergedWith,
    title: t.main,
    nativeTitle: t.native,
    romanizedTitle: t.romanized,
    secondaryTitles: t.secondary,
    coverUrl: coverUrl,
    rawCoverUrl: rawCoverUrl,
    authors: authors,
    artists: artists,
    description: description,
    year: year,
    published: published,
    status: status,
    isLicensed: isLicensed,
    hasAnime: hasAnime,
    anime: anime,
    contentRating: contentRating,
    type: type,
    rating: rating,
    finalVolume: finalVolume,
    totalChapters: totalChapters,
    links: links,
    publishers: publishers,
    publisherRefs: publisherRefs,
    genres: genres,
    tags: tags,
    lastUpdated: lastUpdated,
    relationships: relationships,
    source: source,
  );

  SeriesTitles get titles => SeriesTitles.stored(
    main: title,
    native: nativeTitle,
    romanized: romanizedTitle,
    secondary: secondaryTitles,
  );

  String getDisplayTitle(TitleLanguage lang) {
    final t = SeriesTitles.choose(
      lang,
      main: title,
      native: nativeTitle,
      romanized: romanizedTitle,
    );
    if (t.isNotEmpty) return t;
    return secondaryTitles.isNotEmpty ? secondaryTitles.first : '';
  }

  String get displayTitle =>
      getDisplayTitle(SettingsManager().defaultTitleLanguage);

  factory Series.fromSimilarJson(Map<String, dynamic> json) {
    // /similar sends genres_v2, tags_v2, links_v2 and titles[] instead of the flat fields.
    final patched = Map<String, dynamic>.from(json);

    if (patched['genres_v2'] != null) {
      patched['genres'] = _namesOf(patched['genres_v2']);
    }

    if (patched['tags_v2'] != null) {
      patched['tags'] = _namesOf(patched['tags_v2']);
    }

    if (patched['links'] == null) {
      patched['links'] = patched['links_v2'] ?? [];
    }

    return Series.fromJson(patched);
  }

  factory Series.fromRecommendationJson(Map<String, dynamic> json) {
    final patched = Map<String, dynamic>.from(json);
    if (patched['cover'] == null && patched['cover_image'] != null) {
      patched['cover'] = patched['cover_image'];
    }
    if (patched['type'] == null && patched['media_type'] != null) {
      patched['type'] = patched['media_type'];
    }
    if ((patched['rating'] == null || patched['rating'] == '') &&
        patched['score'] != null) {
      patched['rating'] = patched['score'].toString();
    }
    if (patched['year'] == null && patched['published_year'] != null) {
      patched['year'] = patched['published_year'].toString();
    }
    if (patched['tags'] == null && patched['reason'] is Map) {
      final reason = patched['reason'] as Map;
      final topTags = reason['top_tags'];
      if (topTags is List) {
        patched['tags'] = topTags
            .map((t) => t is Map ? (t['name'] ?? '').toString() : t.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return Series.fromSimilarJson(patched);
  }

  static List<String> _namesOf(Object? raw) {
    if (raw is! List) return <String>[];
    return [
      for (final item in raw)
        if ((item is Map ? item['name']?.toString() : item?.toString())
            case final String name when name.isNotEmpty)
          name,
    ];
  }

  factory Series.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] as Map?)?.cast<String, dynamic>();

    String rating = json['rating']?.toString() ?? '';
    if (source != null && source.isNotEmpty) {
      final normalizedRatings = source.values
          .map(JsonUtils.normalizedRating)
          .whereType<double>()
          .toList();
      if (normalizedRatings.isNotEmpty) {
        final avg =
            normalizedRatings.reduce((a, b) => a + b) /
            normalizedRatings.length;
        rating = avg.toStringAsFixed(1);
      }
    }

    final titles = SeriesTitles.fromJson(json);

    return Series(
      id: json['id']?.toString() ?? '',
      state: JsonUtils.stringOr(json['state']),
      mergedWith: json['merged_with']?.toString(),
      title: titles.main,
      nativeTitle: titles.native,
      romanizedTitle: titles.romanized,
      secondaryTitles: titles.secondary,
      coverUrl: JsonUtils.getCover(json),
      rawCoverUrl: JsonUtils.getRawCover(json),
      authors: JsonUtils.stringList(json['authors']),
      artists: JsonUtils.stringList(json['artists']),
      description: MarkdownUtils.normalizeDescription(
        json['description']?.toString() ?? '',
      ),
      year: json['year']?.toString() ?? '',
      published: (json['published'] as Map?)?.cast<String, dynamic>(),
      status: JsonUtils.stringOr(json['status']),
      isLicensed: json['is_licensed']?.toString() ?? '',
      hasAnime: json['has_anime']?.toString() ?? '',
      anime: (json['anime'] as Map?)?.cast<String, dynamic>(),
      contentRating: JsonUtils.stringOr(json['content_rating']),
      type: JsonUtils.stringOr(json['type']),
      rating: rating,
      finalVolume: json['final_volume']?.toString() ?? '',
      totalChapters: json['total_chapters']?.toString() ?? '',
      links: (json['links'] as List?) ?? [],
      publishers: _namesOf(json['publishers']),
      publisherRefs: [
        for (final p
            in (json['publishers'] is List
                ? json['publishers'] as List
                : const []))
          if (SeriesPublisher.tryParse(p) case final ref?) ref,
      ],
      genres: JsonUtils.stringList(json['genres']),
      tags: JsonUtils.stringList(json['tags']),
      lastUpdated: JsonUtils.stringOr(json['last_updated_at']),
      relationships: (json['relationships'] as Map?)?.cast<String, dynamic>(),
      source: source,
    );
  }

  double? get combinedAverage {
    if (source == null || source!.isEmpty) return null;
    final normalizedRatings = source!.values
        .map(JsonUtils.normalizedRating)
        .whereType<double>()
        .toList();
    if (normalizedRatings.isEmpty) return null;
    return normalizedRatings.reduce((a, b) => a + b) / normalizedRatings.length;
  }
}

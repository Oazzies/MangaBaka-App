import 'package:mangabaka_app/core/utils/json_utils.dart';
import 'package:mangabaka_app/core/utils/markdown_utils.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';


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

  /// Publishers with ids, from the API. Not persisted in the local database,
  /// so empty for series rebuilt from the library cache.
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

  String getDisplayTitle(TitleLanguage lang) {
    switch (lang) {
      case TitleLanguage.native:
        return nativeTitle.isNotEmpty ? nativeTitle : title;
      case TitleLanguage.romanized:
        return romanizedTitle.isNotEmpty ? romanizedTitle : title;
      case TitleLanguage.defaultLang:
        return title;
    }
  }


  factory Series.fromSimilarJson(Map<String, dynamic> json) {
    // The /similar endpoint uses genres_v2, tags_v2, links_v2, and a titles array
    // instead of the flat title/native_title/romanized_title fields.
    final patched = Map<String, dynamic>.from(json);

    // Genres
    if (patched['genres_v2'] != null) {
      patched['genres'] = _namesOf(patched['genres_v2']);
    }

    // Tags
    if (patched['tags_v2'] != null) {
      patched['tags'] = _namesOf(patched['tags_v2']);
    }

    // Links
    if (patched['links'] == null) {
      patched['links'] = patched['links_v2'] ?? [];
    }

    return Series.fromJson(patched);
  }

  /// Parses an item from `/my/series/recommendations` (`results` array).
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

  /// The non-empty `name`s in a list of `{name: …}` objects (or bare strings),
  /// skipping anything else instead of throwing on it.
  static List<String> _namesOf(Object? raw) {
    if (raw is! List) return <String>[];
    return [
      for (final item in raw)
        if ((item is Map ? item['name']?.toString() : item?.toString())
            case final String name when name.isNotEmpty)
          name,
    ];
  }

  //Thanks GPT4.1
  factory Series.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] as Map?)?.cast<String, dynamic>();
    
    // Calculate combined average if source data is available
    String rating = json['rating']?.toString() ?? '';
    if (source != null && source.isNotEmpty) {
      final normalizedRatings = source.values
          .map(JsonUtils.normalizedRating)
          .whereType<double>()
          .toList();
      if (normalizedRatings.isNotEmpty) {
        final avg = normalizedRatings.reduce((a, b) => a + b) / normalizedRatings.length;
        rating = avg.toStringAsFixed(1);
      }
    }

    String title = JsonUtils.stringOr(json['title']);
    String nativeTitle = JsonUtils.stringOr(json['native_title']);
    String romanizedTitle = JsonUtils.stringOr(json['romanized_title']);
    List<String> secondaryTitlesList = [];

    final secTitlesRaw = json['secondary_titles'];
    if (secTitlesRaw is Map) {
      secondaryTitlesList = secTitlesRaw.values.map((e) => e.toString()).toList();
    } else if (secTitlesRaw is List) {
      secondaryTitlesList = secTitlesRaw.map((e) => e.toString()).toList();
    }

    final titlesList = json['titles'] as List?;
    if (titlesList != null && titlesList.isNotEmpty) {
      String langOf(dynamic t) =>
          (t is Map ? t['language']?.toString() : null)?.toLowerCase() ?? '';

      bool isRomanized(dynamic t) {
        if (t is! Map) return false;
        final l = langOf(t);
        final traits = JsonUtils.stringList(t['traits']);
        return l.endsWith('-latn') ||
            l.endsWith('-ro') ||
            l.contains('hepburn') ||
            l.contains('romaji') ||
            traits.contains('romanized');
      }

      Map<String, dynamic>? pick(bool Function(dynamic) test) {
        for (final t in titlesList) {
          if (t is Map && test(t)) return t.cast<String, dynamic>();
        }
        return null;
      }

      // 1. Determine main display title: prefer English, then any romanized, then any primary, then first available.
      final chosen = pick((t) => langOf(t) == 'en') ??
          pick(isRomanized) ??
          pick((t) => t is Map && t['is_primary'] == true) ??
          (titlesList.first is Map
              ? (titlesList.first as Map).cast<String, dynamic>()
              : null);

      if (chosen != null) {
        title = chosen['title']?.toString() ?? '';
      }

      // 2. Determine native title: prefer ja, ko, zh/zh-* without romanized trait
      final nativeChosen = pick((t) {
        final l = langOf(t);
        final traits = JsonUtils.stringList(t['traits']);
        return (l == 'ja' || l == 'ko' || l == 'zh' || l.startsWith('zh-')) &&
            !traits.contains('romanized');
      });
      if (nativeChosen != null) {
        nativeTitle = nativeChosen['title']?.toString() ?? '';
      }

      // 3. Determine romanized title
      final romanizedChosen = pick(isRomanized);
      if (romanizedChosen != null) {
        romanizedTitle = romanizedChosen['title']?.toString() ?? '';
      }

      // 4. Secondary titles: all other titles in the list that aren't the main chosen title
      final List<String> extractedSecondary = [];
      for (final t in titlesList) {
        if (t is Map && t['title'] != null) {
          final tStr = t['title'].toString();
          if (tStr.isNotEmpty && tStr != title) {
            extractedSecondary.add(tStr);
          }
        }
      }
      if (extractedSecondary.isNotEmpty) {
        secondaryTitlesList = extractedSecondary.toSet().toList();
      }
    }

    return Series(
      id: json['id']?.toString() ?? '',
      state: JsonUtils.stringOr(json['state']),
      mergedWith: json['merged_with']?.toString(),
      title: title,
      nativeTitle: nativeTitle,
      romanizedTitle: romanizedTitle,
      secondaryTitles: secondaryTitlesList,
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
        for (final p in (json['publishers'] is List
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

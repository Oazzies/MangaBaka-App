import 'package:bakahyou/utils/json_utils.dart';

class Series {
  final String id;
  final String state;
  final String? mergedWith;
  final String title;
  final String nativeTitle;
  final String romanizedTitle;
  final List<String> secondaryTitles;
  final String coverUrl;
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
    required this.genres,
    required this.tags,
    required this.lastUpdated,
    this.relationships,
    this.source,
  });

  //Thanks GPT4.1
  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id']?.toString() ?? '',
      state: json['state'] ?? '',
      mergedWith: json['merged_with']?.toString(),
      title: json['title'] ?? '',
      nativeTitle: json['native_title'] ?? '',
      romanizedTitle: json['romanized_title'] ?? '',
      secondaryTitles: (json['secondary_titles'] as Map?)?.values.map((e) => e.toString()).toList() ?? [],
      coverUrl: JsonUtils.getCover(json),
      authors: (json['authors'] as List?)?.cast<String>() ?? [],
      artists: (json['artists'] as List?)?.cast<String>() ?? [],
      description: (json['description'] ?? '').replaceAll('<br>', '\n').replaceAll(RegExp(r'<.*?>'), ''),
      year: json['year']?.toString() ?? '',
      published: (json['published'] as Map?)?.cast<String, dynamic>(),
      status: json['status'] ?? '',
      isLicensed: json['is_licensed']?.toString() ?? '',
      hasAnime: json['has_anime']?.toString() ?? '',
      anime: (json['anime'] as Map?)?.cast<String, dynamic>(),
      contentRating: json['content_rating'] ?? '',
      type: json['type'] ?? '',
      rating: json['rating']?.toString() ?? '',
      finalVolume: json['final_volume']?.toString() ?? '',
      totalChapters: json['total_chapters']?.toString() ?? '',
      links: (json['links'] as List?) ?? [],
      publishers: (json['publishers'] as List?)?.map((p) => p['name']?.toString() ?? '').where((e) => e.isNotEmpty).toList() ?? [],
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      lastUpdated: json['last_updated_at'] ?? '',
      relationships: (json['relationships'] as Map?)?.cast<String, dynamic>(),
      source: (json['source'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
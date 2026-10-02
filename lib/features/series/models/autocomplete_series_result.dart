import 'package:mangabaka_app/core/utils/json_utils.dart';

/// Lightweight model for autocomplete search results.
/// Only parses the fields needed for the dropdown display (thumbnail + title),
/// keeping it separate from the full [Series] model to avoid unnecessary parsing.
class AutocompleteSeriesResult {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String type;
  final int? year;
  final List<String> genres;
  final List<String> allTitles;

  const AutocompleteSeriesResult({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.type = '',
    this.year,
    this.genres = const [],
    this.allTitles = const [],
  });

  factory AutocompleteSeriesResult.fromJson(Map<String, dynamic> json) {
    String displayTitle = '';
    final List<String> allTitlesList = [];

    // Handle 'titles' array if present
    final titles = json['titles'];
    if (titles is List && titles.isNotEmpty) {
      for (var t in titles) {
        if (t is Map && t['title'] != null) {
          allTitlesList.add(t['title'].toString());
        }
      }
      
      // Try to find an English one in the array, then any primary, then first
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
        for (final t in titles) {
          if (t is Map && test(t)) return t.cast<String, dynamic>();
        }
        return null;
      }
      
      final chosen = pick((t) => langOf(t) == 'en') ??
          pick(isRomanized) ??
          pick((t) => t is Map && t['is_primary'] == true) ??
          (titles.first is Map
              ? (titles.first as Map).cast<String, dynamic>()
              : null);
              
      if (chosen != null) {
        displayTitle = chosen['title']?.toString() ?? '';
      }
    }

    if (displayTitle.isEmpty) {
      displayTitle = json['title']?.toString() ?? '';
    }

    if (displayTitle.isNotEmpty && !allTitlesList.contains(displayTitle)) {
      allTitlesList.insert(0, displayTitle);
    }
    if (json['native_title'] != null) {
      final nativeTitle = json['native_title'].toString();
      if (nativeTitle.isNotEmpty && !allTitlesList.contains(nativeTitle)) {
        allTitlesList.add(nativeTitle);
      }
    }
    if (json['romanized_title'] != null) {
      final romanizedTitle = json['romanized_title'].toString();
      if (romanizedTitle.isNotEmpty && !allTitlesList.contains(romanizedTitle)) {
        allTitlesList.add(romanizedTitle);
      }
    }
    
    // Handle 'secondary_titles' map if present
    final secondaryTitles = json['secondary_titles'];
    if (secondaryTitles is Map) {
      secondaryTitles.forEach((key, value) {
        if (value is List) {
          for (var item in value) {
            if (item is Map && item['title'] != null) {
              allTitlesList.add(item['title'].toString());
            }
          }
        }
      });
    }
    
    if (displayTitle.isEmpty) {
      displayTitle = json['title']?.toString() ?? 'Unknown Title';
    }

    // Extract thumbnail: use x150 cover variant for small display
    String thumbnail = '';
    final cover = json['cover'];
    if (cover is Map) {
      final x150 = cover['x150'];
      if (x150 is Map && x150['x1'] is String) {
        thumbnail = x150['x1'];
      }
      // Fallback to x350 if x150 is not available
      if (thumbnail.isEmpty) {
        final x350 = cover['x350'];
        if (x350 is Map && x350['x1'] is String) {
          thumbnail = x350['x1'];
        }
      }
    }

    // Extract genres from genres list (legacy field), max 3
    final genresList = <String>[];
    final genres = json['genres'];
    if (genres is List) {
      for (final g in genres.take(3)) {
        if (g is String) genresList.add(g);
      }
    }

    // Extract year from published field
    int? year;
    final published = json['published'];
    if (published is Map) {
      final startDate = published['start_date']?.toString() ?? '';
      if (startDate.length >= 4) {
        year = int.tryParse(startDate.substring(0, 4));
      }
    }
    year ??= json['year'] is int ? json['year'] as int : null;

    return AutocompleteSeriesResult(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: displayTitle,
      thumbnailUrl: thumbnail,
      type: json['type']?.toString() ?? '',
      year: year,
      genres: genresList,
      allTitles: allTitlesList.where((t) => t.isNotEmpty).toSet().toList(), // Deduplicate
    );
  }

  /// Create from a LibraryEntry-like data structure for local search
  factory AutocompleteSeriesResult.fromLibraryData({
    required int id,
    required String title,
    required String thumbnailUrl,
    String type = '',
    int? year,
    List<String> genres = const [],
    List<String> allTitles = const [],
  }) {
    return AutocompleteSeriesResult(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      type: type,
      year: year,
      genres: genres,
      allTitles: allTitles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutocompleteSeriesResult && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AutocompleteSeriesResult(id: $id, title: $title)';
}

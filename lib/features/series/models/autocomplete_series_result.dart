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
    // Extract display title: prefer `title` field first as it's the API's primary display title
    String displayTitle = json['title']?.toString() ?? '';
    final List<String> allTitlesList = [];
    
    if (displayTitle.isNotEmpty) allTitlesList.add(displayTitle);
    if (json['native_title'] != null) allTitlesList.add(json['native_title'].toString());
    if (json['romanized_title'] != null) allTitlesList.add(json['romanized_title'].toString());

    // Handle 'titles' array if present (legacy or specific API structure)
    final titles = json['titles'];
    if (titles is List && titles.isNotEmpty) {
      for (var t in titles) {
        if (t is Map && t['title'] != null) {
          allTitlesList.add(t['title'].toString());
        }
      }
      
      // If we don't have a display title yet, try to find an English one in the array
      if (displayTitle.isEmpty) {
        final enTitle = titles.firstWhere(
          (t) => t is Map && t['language'] == 'en',
          orElse: () => titles.first,
        );
        if (enTitle is Map) {
          displayTitle = enTitle['title']?.toString() ?? '';
        }
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

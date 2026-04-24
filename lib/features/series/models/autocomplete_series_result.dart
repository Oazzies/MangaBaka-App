/// Lightweight model for autocomplete search results.
/// Only parses the fields needed for the dropdown display (thumbnail + title),
/// keeping it separate from the full [Series] model to avoid unnecessary parsing.
class AutocompleteSeriesResult {
  final int id;
  final String title;
  final String thumbnailUrl;

  const AutocompleteSeriesResult({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  factory AutocompleteSeriesResult.fromJson(Map<String, dynamic> json) {
    // Extract display title: prefer `titles` list with 'en' language,
    // fall back to the legacy `title` field.
    String displayTitle = '';
    final titles = json['titles'];
    if (titles is List && titles.isNotEmpty) {
      // Prefer English title, otherwise take the first available
      final enTitle = titles.firstWhere(
        (t) => t is Map && t['language'] == 'en',
        orElse: () => titles.first,
      );
      if (enTitle is Map) {
        displayTitle = enTitle['title']?.toString() ?? '';
      }
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

    return AutocompleteSeriesResult(
      id: (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: displayTitle,
      thumbnailUrl: thumbnail,
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

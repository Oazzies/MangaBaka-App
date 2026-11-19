import 'package:mangabaka_app/features/series/models/series.dart';

/// A stale server `content_rating` filter can leak hidden ratings, and the backend
/// does not filter on the combined score the app displays, so both are re-checked here.
class SeriesSearchFilter {
  final List<String> contentPreferences;

  /// Inclusive, on the app's 0–100 scale.
  final double? ratingLower;
  final double? ratingUpper;

  /// Sorting by score drops unrated (0) series, which otherwise pile up at one end and read as a bug.
  final String? sortBy;

  const SeriesSearchFilter({
    this.contentPreferences = const [],
    this.ratingLower,
    this.ratingUpper,
    this.sortBy,
  });

  bool get _hasRatingBounds => ratingLower != null || ratingUpper != null;

  bool get _sortsByScore => sortBy != null && sortBy!.startsWith('score_');

  bool allows(Series series) {
    if (contentPreferences.isNotEmpty &&
        !contentPreferences.contains(series.contentRating.toLowerCase())) {
      return false;
    }

    if (_hasRatingBounds) {
      final rating = normalizedRating(series);
      if (ratingLower != null && rating < ratingLower!) return false;
      if (ratingUpper != null && rating > ratingUpper!) return false;
      return true;
    }

    if (_sortsByScore && normalizedRating(series) == 0) return false;

    return true;
  }

  /// The API has returned both 0–10 and 0–100 scores over time; anything at or below 10 is scaled up.
  static double normalizedRating(Series series) {
    final raw = double.tryParse(series.rating) ?? 0.0;
    return raw <= 10.0 ? raw * 10 : raw;
  }
}

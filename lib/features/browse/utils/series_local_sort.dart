import 'package:mangabaka_app/features/series/models/series.dart';

/// Applies the user's chosen sort to a page of results on the client.
///
/// The search endpoint prioritises relevance whenever a text query is present
/// and quietly ignores `sort_by`. Sorting each page as it arrives is what
/// keeps the user's chosen order honoured — it cannot reorder across page
/// boundaries, but within a page the order is right, which is what reads as
/// correct while scrolling.
///
/// Pulled out of `BrowseController` so the comparator is testable without a
/// controller and a network round trip.
class SeriesLocalSort {
  SeriesLocalSort._();

  /// Whether [sortBy] is one this can apply locally.
  ///
  /// `popularity_` and the trending sorts are derived from data the series
  /// payload does not carry, so they are left in API order rather than sorted
  /// against a field that would be zero for everything.
  static bool canApply(String? sortBy) =>
      sortBy != null &&
      (sortBy.startsWith('score_') ||
          sortBy.startsWith('name_') ||
          sortBy.startsWith('chapters_'));

  /// Sorts [results] in place by [sortBy]. A sort this cannot apply leaves the
  /// list untouched.
  static void apply(List<Series> results, String? sortBy) {
    if (!canApply(sortBy)) return;
    results.sort((a, b) => _compare(a, b, sortBy!));
  }

  static int _compare(Series a, Series b, String sortBy) {
    final descending = sortBy.endsWith('_desc');

    if (sortBy.startsWith('score_')) {
      final ratingA = double.tryParse(a.rating) ?? 0.0;
      final ratingB = double.tryParse(b.rating) ?? 0.0;
      return descending
          ? ratingB.compareTo(ratingA)
          : ratingA.compareTo(ratingB);
    }
    if (sortBy.startsWith('name_')) {
      return descending
          ? b.title.compareTo(a.title)
          : a.title.compareTo(b.title);
    }
    // chapters_
    final chaptersA = int.tryParse(a.totalChapters) ?? 0;
    final chaptersB = int.tryParse(b.totalChapters) ?? 0;
    return descending
        ? chaptersB.compareTo(chaptersA)
        : chaptersA.compareTo(chaptersB);
  }
}

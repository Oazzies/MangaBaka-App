import 'package:mangabaka_app/features/series/models/series.dart';

/// With a query the API ignores `sort_by`, so each page is sorted here; never across pages.
class SeriesLocalSort {
  SeriesLocalSort._();

  /// `popularity_` and trending sorts use data the payload lacks, so they keep API order.
  static bool canApply(String? sortBy) =>
      sortBy != null &&
      (sortBy.startsWith('score_') ||
          sortBy.startsWith('name_') ||
          sortBy.startsWith('chapters_'));

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
    final chaptersA = int.tryParse(a.totalChapters) ?? 0;
    final chaptersB = int.tryParse(b.totalChapters) ?? 0;
    return descending
        ? chaptersB.compareTo(chaptersA)
        : chaptersA.compareTo(chaptersB);
  }
}

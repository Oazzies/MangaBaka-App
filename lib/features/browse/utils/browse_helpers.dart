import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class BrowseHelpers {
  static String cleanTitle(String title) {
    final regex = RegExp(
      r'(?:\s*[,-]?\s*(?:Vol\.|Volume|Part|Book)\s*\d+.*)|(?:\s*\(?(?:Deluxe Edition|Omnibus|Box Set|Manga)\b.*)',
      caseSensitive: false,
    );
    final cleaned = title.replaceAll(regex, '').trim();
    return cleaned.replaceAll(RegExp(r'[\-:]$'), '').trim();
  }

  static Series convertAutocompleteToSeries(AutocompleteSeriesResult result) {
    return Series(
      id: result.id.toString(),
      state: '',
      title: result.title,
      nativeTitle: '',
      romanizedTitle: '',
      secondaryTitles: [],
      coverUrl: result.thumbnailUrl,
      rawCoverUrl: result.thumbnailUrl,
      authors: [],
      artists: [],
      description: '',
      year: '',
      status: '',
      isLicensed: '',
      hasAnime: '',
      contentRating: '',
      type: '',
      rating: '',
      finalVolume: '',
      totalChapters: '',
      links: [],
      publishers: [],
      genres: [],
      tags: [],
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
}

import 'package:mangabaka_app/core/localization/localization_service.dart';

/// The series types and publication statuses the filters offer, in display
/// order. Shared by the phone filter sheet and the desktop filter panel.
const List<String> filterSeriesTypes = [
  'manga',
  'manhwa',
  'manhua',
  'novel',
  'oel',
];

const List<String> filterPublicationStatuses = [
  'ongoing',
  'releasing',
  'completed',
  'hiatus',
  'cancelled',
];

/// Sort keys and their labels, in menu order.
///
/// [library] swaps the network-only popularity sorts for the library-only
/// unread-count ones: the library is sorted locally, where popularity is not
/// known but progress is.
Map<String, String> searchSortOptions(
  LocalizationService l10n, {
  bool library = false,
}) {
  return {
    'name_asc': l10n.translate('title_asc'),
    'name_desc': l10n.translate('title_desc'),
    if (!library) ...{
      'popularity_asc': l10n.translate('popularity_asc'),
      'popularity_desc': l10n.translate('popularity_desc'),
    },
    'score_desc': l10n.translate('rating_desc'),
    'score_asc': l10n.translate('rating_asc'),
    'chapters_desc': l10n.translate('chapters_desc'),
    'chapters_asc': l10n.translate('chapters_asc'),
    if (!library) ...{
      'trending_7d': l10n.translate('trending_7d'),
      'trending_30d': l10n.translate('trending_30d'),
      'published_start_date_desc': l10n.translate('published_start_desc'),
      'published_start_date_asc': l10n.translate('published_start_asc'),
      'published_end_date_desc': l10n.translate('published_end_desc'),
      'published_end_date_asc': l10n.translate('published_end_asc'),
    },
    if (library) ...{
      'unread_desc': l10n.translate('unread_desc'),
      'unread_asc': l10n.translate('unread_asc'),
    },
    'random': l10n.translate('random_sort'),
  };
}

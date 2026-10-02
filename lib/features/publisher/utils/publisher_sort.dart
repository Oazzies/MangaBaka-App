import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';

/// The orders the Publishers tab offers, as (sort_by value, label). A null
/// value is the default: most series first while browsing, the API's relevance
/// order while searching.
List<(String?, String)> publisherSortOptions(LocalizationService l10n) => [
      (null, l10n.translate('publisher_sort_popular')),
      (PublisherSearchService.sortNameAsc, l10n.translate('publisher_sort_az')),
      (PublisherSearchService.sortNameDesc, l10n.translate('publisher_sort_za')),
      (PublisherSearchService.sortNewest, l10n.translate('publisher_sort_newest')),
    ];

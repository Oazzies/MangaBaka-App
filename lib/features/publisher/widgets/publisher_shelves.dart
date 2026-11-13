import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_carousel.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_cover_card.dart';
import 'package:mangabaka_app/features/browse/screens/browse_results_screen.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/publisher/models/publisher.dart';
import 'package:mangabaka_app/features/publisher/services/publisher_search_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';

typedef PublisherShelfDef = (PublisherShelf shelf, String title, String? sort);

List<PublisherShelfDef> publisherShelfDefs(LocalizationService l10n) => [
  (
    PublisherShelf.newest,
    l10n.translate('publisher_shelf_newest'),
    'published_start_date_desc',
  ),
  (
    PublisherShelf.popular,
    l10n.translate('publisher_shelf_popular'),
    'popularity_asc',
  ),
  (
    PublisherShelf.highestRated,
    l10n.translate('publisher_shelf_highest_rated'),
    'score_desc',
  ),
  (PublisherShelf.trending, l10n.translate('trending'), 'trending_7d'),
  (PublisherShelf.hiddenGems, l10n.translate('hidden_gems'), null),
];

void _openShelfBrowse(
  BuildContext context,
  Publisher publisher,
  String title,
  String sort,
) {
  Navigator.of(context).push(
    AppTransitions.slideRight(
      BrowseResultsScreen(
        sortType: title,
        sortBy: sort,
        publisher: publisher.name,
        publisherId: publisher.id,
        refineLabel: title,
      ),
    ),
  );
}

class PublisherDesktopShelf extends StatelessWidget {
  final Publisher publisher;
  final PublisherShelf shelf;
  final String title;
  final String? sort;
  final Future<List<Series>> future;

  const PublisherDesktopShelf({
    super.key,
    required this.publisher,
    required this.shelf,
    required this.title,
    required this.sort,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Series>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final series = snapshot.data ?? const <Series>[];
        final loading = !snapshot.hasData;
        if (!loading && series.isEmpty) return const SizedBox.shrink();
        final textArea = DesktopCoverCard.textAreaHeight(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: DesktopTokens.sectionGap),
          child: DesktopCarousel(
            title: title,
            loading: loading,
            itemCount: series.length,
            itemWidth: 156,
            stretch: true,
            itemHeight: (width) => width * 1.5 + textArea,
            onViewAll: sort == null
                ? null
                : () => _openShelfBrowse(context, publisher, title, sort!),
            itemBuilder: (context, i) => DesktopCoverCard(
              series: series[i],
              heroTag: 'publisher_${publisher.id}_${shelf.name}_$i',
              showRating: false,
            ),
          ),
        );
      },
    );
  }
}

class PublisherMobileShelvesBlock extends StatelessWidget {
  final Publisher publisher;
  final LocalizationService l10n;
  final bool loading;
  final Future<void> shelvesReady;
  final Map<PublisherShelf, Future<List<Series>>> shelves;

  const PublisherMobileShelvesBlock({
    super.key,
    required this.publisher,
    required this.l10n,
    required this.loading,
    required this.shelvesReady,
    required this.shelves,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: shelvesReady,
      builder: (context, snapshot) {
        if (loading || snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: MbSpinner(size: 20, strokeWidth: 2)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (shelf, title, sort) in publisherShelfDefs(l10n))
              FutureBuilder<List<Series>>(
                future: shelves[shelf],
                builder: (context, snap) {
                  if (snap.hasError) return const SizedBox.shrink();
                  return HomeRail(
                    title: title,
                    heroScopeId: 'publisher_${publisher.id}_${shelf.name}',
                    series: snap.data ?? const [],
                    loading: !snap.hasData,
                    onViewAll: sort == null
                        ? null
                        : () =>
                              _openShelfBrowse(context, publisher, title, sort),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

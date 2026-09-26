import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/series/models/series_collection.dart';
import 'package:mangabaka_app/features/series/widgets/series_section_header.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/collections/screens/collection_detail_screen.dart';
import 'package:mangabaka_app/features/collections/widgets/collection_card.dart';
import 'package:mangabaka_app/shared/transitions/app_transitions.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_spinner.dart';

class SeriesCollectionsTab extends StatelessWidget {
  final List<SeriesCollection>? collections;
  final double horizontalPadding;

  const SeriesCollectionsTab({
    super.key,
    this.collections,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (collections == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: MbSpinner(),
        ),
      );
    }
    final l10n = LocalizationService();
    if (collections!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(l10n.translate('no_collections_available')),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListenableBuilder(
        listenable: SettingsManager(),
        builder: (context, _) {
          final settings = SettingsManager();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SeriesSectionHeader(
                      title: l10n.translate('tab_collections'),
                      bottomPadding: 0,
                    ),
                  ),
                  if (MediaQuery.of(context).orientation ==
                      Orientation.landscape)
                    _buildColumnSwitch(context, settings),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      MediaQuery.of(context).orientation ==
                      Orientation.landscape;
                  final prefColumns = settings.collectionsListColumns;

                  // Double column support is only for landscape mode.
                  // In portrait, we always use 1 column.
                  // In landscape, we use 2 unless the user specifically chose 1.
                  final columns = isLandscape ? (prefColumns == 1 ? 1 : 2) : 1;

                  final spacing = 12.0;
                  final itemWidth = columns > 1
                      ? (constraints.maxWidth - (spacing * (columns - 1))) /
                            columns
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: collections!
                        .map(
                          (col) => SizedBox(
                            width: itemWidth,
                            child: CollectionCard(
                              collection: col,
                              onTap: () => Navigator.of(context).push(
                                AppTransitions.slideRight(
                                  CollectionDetailScreen(collection: col),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColumnSwitch(BuildContext context, SettingsManager settings) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final prefColumns = settings.collectionsListColumns;
    final activeColumns = prefColumns == 0
        ? (isLandscape ? 2 : 1)
        : prefColumns;
    final l10n = LocalizationService();

    return WidgetUtils.tooltip(
      message: l10n.translate('toggle_layout'),
      child: IconButton(
        icon: Icon(
          activeColumns == 2
              ? Icons.view_agenda_outlined
              : Icons.grid_view_rounded,
          color: context.colors.text,
        ),
        onPressed: () {
          settings.setCollectionsListColumns(activeColumns == 1 ? 2 : 1);
        },
      ),
    );
  }
}

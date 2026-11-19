import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_series_filter_panel.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/controllers/series_filter_drawer_controller.dart';
import 'package:mangabaka_app/features/series/screens/series_detail_screen.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_body.dart';
import 'package:mangabaka_app/features/series/widgets/series_detail_fab.dart';
import 'package:mangabaka_app/features/series/widgets/series_filter_drawer.dart';

class SeriesDetailScaffold extends StatelessWidget {
  final SeriesDetailScreenState state;
  final SeriesFilterDrawerController filterDrawer;
  final Stream<LibraryEntry?>? entryStream;
  final bool embedded;
  final Widget? rightRail;
  final bool isAdding;
  final VoidCallback onRetry;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onAuthorTap;
  final ValueChanged<String> onPublisherTap;
  final ValueChanged<SearchFilters> onSearch;
  final VoidCallback onAdd;

  const SeriesDetailScaffold({
    super.key,
    required this.state,
    required this.filterDrawer,
    required this.entryStream,
    required this.embedded,
    required this.rightRail,
    required this.isAdding,
    required this.onRetry,
    required this.onTabChanged,
    required this.onAuthorTap,
    required this.onPublisherTap,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !filterDrawer.isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (filterDrawer.isOpen) filterDrawer.close();
      },
      // Page constraints, as the body uses, so the FAB and the body agree on which layout shows.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth > SeriesDetailBody.wideBreakpoint;
          return Scaffold(
            backgroundColor: context.colors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SeriesDetailBody(
                    state: state,
                    entryStream: entryStream,
                    settings: SettingsManager(),
                    l10n: LocalizationService(),
                    embedded: embedded,
                    rightRail: rightRail,
                    onRetry: onRetry,
                    onTabChanged: onTabChanged,
                    onAuthorTap: onAuthorTap,
                    onPublisherTap: onPublisherTap,
                  ),
                ),
                // Must stay Positioned: a non-positioned child sizes the Stack to itself, collapsing the page.
                if (filterDrawer.isOpen)
                  Positioned.fill(
                    child: DesktopLayout.isActive(context)
                        ? DesktopSeriesFilterPanel(
                            controller: filterDrawer,
                            onSearch: onSearch,
                          )
                        : SeriesFilterDrawer(
                            controller: filterDrawer,
                            onSearch: onSearch,
                          ),
                  ),
              ],
            ),
            floatingActionButton: (isWide || embedded)
                ? null
                : SeriesDetailFAB(
                    entryStream: entryStream,
                    isAdding: isAdding,
                    onAdd: onAdd,
                  ),
          );
        },
      ),
    );
  }
}

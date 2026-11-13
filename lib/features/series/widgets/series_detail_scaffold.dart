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

/// Responsive scaffold + filter drawer overlay for [SeriesDetailScreen].
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
      // Back closes the filter drawer before it leaves the page.
      canPop: !filterDrawer.isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (filterDrawer.isOpen) filterDrawer.close();
      },
      // The wide layout carries its own add button in the sidebar; the FAB
      // is the phone/tablet-portrait affordance only. Measured from the
      // page's own constraints, as the body does, so the two always agree
      // on which layout is showing (the desktop sidebar takes width too).
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
                // Positioned, like the body: a non-positioned child would
                // make the Stack size itself to that child instead of to the
                // incoming constraints, collapsing the page.
                if (filterDrawer.isOpen)
                  Positioned.fill(
                    // A pointer gets a panel docked beside the page; a
                    // thumb gets the bottom sheet.
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

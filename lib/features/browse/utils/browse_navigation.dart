import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';

/// Hands a search to the Browse tab and takes the user there.
///
/// Three screens each had their own copy of this three-step dance — seed the
/// live [BrowseScreen] state, switch to its tab, unwind back to the root — and
/// a missed step showed up as the tab opening on stale results.
///
/// The Browse screen may not be mounted (its tab has never been visited), in
/// which case seeding is skipped: the navigation still happens, and Browse
/// starts from its own default state rather than crashing.
class BrowseNavigation {
  BrowseNavigation._();

  /// Index of the Browse tab in [MainScreen]'s bottom navigation.
  static const int browseTabIndex = 2;

  static void searchByTags(BuildContext context, List<String> tagIds) {
    _go(context, (controller) => controller.startTagSearch(tagIds));
  }

  static void searchByGenre(BuildContext context, String genreKey) {
    _go(context, (controller) => controller.startGenreSearch(genreKey));
  }

  static void searchWithFilters(BuildContext context, SearchFilters filters) {
    _go(context, (controller) => controller.startSearchWithFilters(filters));
  }

  /// A text query with filters, as arrives from a `/search?...` link.
  static void search(
    BuildContext context,
    String query,
    SearchFilters filters,
  ) {
    _go(context, (controller) => controller.startQuerySearch(query, filters));
  }

  /// The Browse tab on its Publishers list.
  static void showPublishers(BuildContext context) {
    _go(context, (controller) => controller.setType(BrowseType.publishers));
  }

  static void _go(BuildContext context, void Function(BrowseController controller) seed) {
    // Whichever Browse is mounted — the phone screen or the desktop page.
    final controller = BrowseScreen.browseScreenKey.currentState?.controller ??
        DesktopBrowseScreen.stateKey.currentState?.controller;
    if (controller != null) seed(controller);

    MainScreen.setTabIndex(browseTabIndex);

    // Pop back to the tab shell; the caller may be several pushes deep.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/screens/browse_screen.dart';
import 'package:mangabaka_app/desktop/screens/browse/desktop_browse_screen.dart';
import 'package:mangabaka_app/features/navigation/screens/main_screen.dart';

class BrowseNavigation {
  BrowseNavigation._();

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

  static void search(
    BuildContext context,
    String query,
    SearchFilters filters,
  ) {
    _go(context, (controller) => controller.startQuerySearch(query, filters));
  }

  static void showPublishers(BuildContext context) {
    _go(context, (controller) => controller.setType(BrowseType.publishers));
  }

  static void _go(
    BuildContext context,
    void Function(BrowseController controller) seed,
  ) {
    final controller =
        BrowseScreen.browseScreenKey.currentState?.controller ??
        DesktopBrowseScreen.stateKey.currentState?.controller;
    if (controller != null) seed(controller);

    MainScreen.setTabIndex(browseTabIndex);

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

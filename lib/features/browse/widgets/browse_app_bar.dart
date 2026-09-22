import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/browse/controllers/browse_controller.dart';
import 'package:mangabaka_app/features/browse/models/browse_type.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The Browse screen's app bar, in its two states: the title with its actions,
/// and the search field that replaces them.
class BrowseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final BrowseController controller;
  final FocusNode searchFocusNode;

  final VoidCallback onEnterSearch;
  final VoidCallback onExitSearch;
  final VoidCallback onScanTap;
  final ValueChanged<AutocompleteSeriesResult> onResultSelected;

  /// Caps the search field on a wide window; a full-width field over a centred
  /// list looks detached from it.
  static const double _maxSearchWidth = 800;

  const BrowseAppBar({
    super.key,
    required this.isSearching,
    required this.controller,
    required this.searchFocusNode,
    required this.onEnterSearch,
    required this.onExitSearch,
    required this.onScanTap,
    required this.onResultSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return isSearching ? _buildSearching() : _buildTitle(context);
  }

  Widget _buildSearching() {
    return AppBar(
      // The search bar carries its own back button, which also clears the
      // query — an implied leading arrow would do neither.
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxSearchWidth),
        child: MBSearchBar(
          focusNode: searchFocusNode,
          controller: controller.searchController,
          initialFilters: controller.currentFilters,
          suggestionsAllowed: controller.currentType == BrowseType.series,
          onScanTap: onScanTap,
          onResultSelected: onResultSelected,
          onChanged: controller.updateSearchQuery,
          onSubmitted: (_) => controller.searchSeries(),
          onFilterApplied: controller.updateFilters,
          onBackTap: onExitSearch,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.search, color: context.colors.text),
        onPressed: onEnterSearch,
      ),
      title: Text(
        LocalizationService().translate('browse').toUpperCase(),
        style: AppTypography.display(color: context.colors.text, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => SettingsScreen.show(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// The "142+ series" line above the results.
class BrowseResultCount extends StatelessWidget {
  final int total;

  /// True when [total] is a floor rather than a count, rendered as a trailing
  /// "+".
  final bool isCapped;

  /// The result type's name, translated — "series", "publishers", "staff".
  final String typeLabel;

  const BrowseResultCount({
    super.key,
    required this.total,
    required this.isCapped,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            size: 14,
            color: context.colors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            '$total${isCapped ? '+' : ''} $typeLabel',
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

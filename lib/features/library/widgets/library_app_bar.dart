import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/library/import/import_export_screen.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/widgets/library_search_bar.dart';
import 'package:mangabaka_app/features/profile/screens/settings_screen.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The library's app bar, in its two states: the title with its actions, and
/// the search field that replaces them.
///
/// Both keep the same [bottom], so switching into search does not make the
/// tabs jump.
class LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final bool isLandscape;

  final FocusNode searchFocusNode;
  final Stream<List<LibraryEntry>>? entriesStream;
  final SearchFilters filters;

  final VoidCallback onEnterSearch;
  final VoidCallback onExitSearch;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SearchFilters> onFiltersChanged;
  final ValueChanged<AutocompleteSeriesResult> onResultSelected;

  /// The tab bar, shared by both states.
  final PreferredSizeWidget bottom;

  /// Caps the search field on a wide window; a full-width field over a centred
  /// list looks detached from it.
  static const double _maxSearchWidth = 800;

  const LibraryAppBar({
    super.key,
    required this.isSearching,
    required this.isLandscape,
    required this.searchFocusNode,
    required this.entriesStream,
    required this.filters,
    required this.onEnterSearch,
    required this.onExitSearch,
    required this.onQueryChanged,
    required this.onFiltersChanged,
    required this.onResultSelected,
    required this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + bottom.preferredSize.height);

  @override
  Widget build(BuildContext context) {
    return isSearching ? _buildSearching(context) : _buildTitle(context);
  }

  Widget _buildSearching(BuildContext context) {
    return AppBar(
      // The search bar carries its own back button, which also clears the
      // query — an implied leading arrow would do neither.
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxSearchWidth),
        child: LibrarySearchBar(
          focusNode: searchFocusNode,
          entriesStream: entriesStream,
          onResultSelected: onResultSelected,
          onChanged: onQueryChanged,
          initialFilters: filters,
          onFilterApplied: onFiltersChanged,
          onBackTap: onExitSearch,
        ),
      ),
      bottom: bottom,
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    final style = settings.resolvedLibraryListStyle;

    return AppBar(
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.search, color: context.colors.text),
        onPressed: onEnterSearch,
      ),
      title: Text(
        l10n.translate('library').toUpperCase(),
        style: AppTypography.display(color: context.colors.text, fontSize: 20),
      ),
      actions: [
        // Landscape has the width for a layout toggle; in portrait the same
        // control lives in settings rather than crowding the bar.
        if (isLandscape) ...[
          WidgetUtils.tooltip(
            message: l10n.translate('toggle_layout'),
            child: IconButton(
              icon: Icon(style.icon, color: context.colors.text),
              onPressed: () => _cycleStyle(settings, style),
            ),
          ),
          const SizedBox(width: 8),
        ],
        WidgetUtils.tooltip(
          message: l10n.translate('import_export_title'),
          child: IconButton(
            icon: const Icon(Icons.import_export_rounded),
            onPressed: () => ImportExportScreen.open(context),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => SettingsScreen.show(context),
        ),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }

  /// Advances to the next list style, writing to whichever setting the library
  /// is currently reading from.
  void _cycleStyle(SettingsManager settings, AppListStyle current) {
    final next = current.next;
    if (settings.separateListStyles) {
      settings.setLibraryListStyle(next);
    } else {
      settings.setListStyle(next);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_shell.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';

export 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final SeriesPrefetch prefetch;
  final ValueChanged<String>? onSubmitted;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onScanTap;
  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;
  final VoidCallback? onBackTap;
  final bool showFilterButton;
  final VoidCallback? onFilterTapOverride;

  final bool suggestionsAllowed;

  const MBSearchBar({
    super.key,
    required this.onChanged,
    required this.prefetch,
    this.onSubmitted,
    this.initialFilters,
    this.onFilterApplied,
    this.controller,
    this.focusNode,
    this.onScanTap,
    this.onResultSelected,
    this.onBackTap,
    this.showFilterButton = true,
    this.onFilterTapOverride,
    this.suggestionsAllowed = true,
  });

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  final SeriesAutocompleteService _service = SeriesAutocompleteService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Null for a plain controller: the field still works, it just cannot show a ghost.
  GhostTextEditingController? get _ghostController =>
      widget.controller is GhostTextEditingController
      ? widget.controller as GhostTextEditingController
      : null;

  void _requestSuggestions(
    String query,
    ValueChanged<List<AutocompleteSeriesResult>> onResults,
  ) {
    // Answer short queries with nothing so the overlay closes instead of showing stale results.
    if (query.trim().length < SeriesAutocompleteService.minQueryLength) {
      onResults(const []);
      return;
    }
    _service.search(
      query,
      onResults: (results) {
        AutocompleteRanking.sort(results, query);
        onResults(results);
      },
      // The service already reports errors, and the suggestions on screen stay put.
      onError: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SearchBarShell(
      controller: _ghostController,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onResultSelected: widget.onResultSelected,
      onResultHovered: (result) => widget.prefetch(result.id.toString()),
      onBackTap: widget.onBackTap,
      onScanTap: widget.onScanTap,
      initialFilters: widget.initialFilters,
      onFilterApplied: widget.onFilterApplied,
      showFilterButton: widget.showFilterButton,
      onFilterTapOverride: widget.onFilterTapOverride,
      requestSuggestions: _requestSuggestions,
      suggestionsEnabled: () =>
          widget.suggestionsAllowed && SettingsManager().autoSuggestBrowse,
      rebuildOn: SettingsManager(),
    );
  }
}

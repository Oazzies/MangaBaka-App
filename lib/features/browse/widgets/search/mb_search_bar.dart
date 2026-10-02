import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_shell.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/services/series_service.dart';

export 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';

/// The Browse search field.
///
/// Everything the field *does* — inline completion, arrow-key navigation, the
/// suggestion overlay, the filter sheet — lives in [SearchBarShell], which the
/// Library field shares. What this adds is the Browse-specific source:
/// suggestions from the network, gated behind the "auto-suggest" setting, with
/// a hover prefetch of the detail page.
class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
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

  /// False while the field searches something autocomplete cannot suggest —
  /// staff and publishers. Suggestions here are series titles, so offering them
  /// for a staff search would be noise.
  final bool suggestionsAllowed;

  const MBSearchBar({
    super.key,
    required this.onChanged,
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

  /// The shell needs a [GhostTextEditingController] to paint the inline
  /// completion. A caller that passes a plain controller gets a fresh one
  /// instead — the field still works, it just cannot show a ghost.
  GhostTextEditingController? get _ghostController =>
      widget.controller is GhostTextEditingController
          ? widget.controller as GhostTextEditingController
          : null;

  void _requestSuggestions(
    String query,
    ValueChanged<List<AutocompleteSeriesResult>> onResults,
  ) {
    // Below the service's minimum the request would be refused anyway; answer
    // with nothing so the overlay closes immediately rather than lingering on
    // the previous query's results.
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
      // Rate limiting and transport errors are reported to the caller by the
      // service and are not worth an error state in a search field: the
      // suggestions already on screen stay put.
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
      // Warm the detail page while the pointer is still on the row, so opening
      // it lands on content instead of a skeleton.
      onResultHovered: (result) =>
          getIt<SeriesService>().fetchSeries(result.id.toString()),
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

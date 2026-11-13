import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_text_field.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_filter_sheet_launcher.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_suggestions_panel.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

export 'package:mangabaka_app/features/browse/widgets/search/search_bar_controller.dart'
    show SuggestionRequest;

/// The search field shared by Browse and Library.
///
/// Both screens used to carry their own copy — ~1150 lines between them,
/// differing only in where suggestions come from and a handful of flags.
/// Everything fiddly was duplicated: the inline ghost completion, arrow-key
/// navigation, the suppress-after-backspace rule, the overlay lifecycle and
/// the filter sheet. They had already drifted apart on ranking and on what
/// submitting does.
///
/// This widget is the presentation; [SearchBarController] holds the rules.
/// What stays screen-specific is passed in: [requestSuggestions] supplies the
/// results, [suggestionsEnabled] gates them behind a setting, and the
/// remaining flags control the scan button and the filter sheet's contents.
class SearchBarShell extends StatefulWidget {
  /// The field's controller. When null the shell owns (and disposes) one; when
  /// provided, the caller keeps ownership.
  final GhostTextEditingController? controller;
  final FocusNode? focusNode;

  /// Fires on every keystroke, on clear with an empty string, and when a
  /// suggestion is chosen.
  final ValueChanged<String> onChanged;

  /// Fires when the field is submitted without a suggestion being chosen.
  /// Falls back to [onChanged] when null.
  final ValueChanged<String>? onSubmitted;

  /// Fires when a suggestion is chosen — by tap, by Enter on a highlighted
  /// row, or by accepting the inline completion.
  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

  /// Fires as a suggestion is hovered, for prefetching its detail page.
  final ValueChanged<AutocompleteSeriesResult>? onResultHovered;

  /// Replaces the leading search glyph with a back button that also clears the
  /// field. Null leaves the glyph.
  final VoidCallback? onBackTap;

  /// Adds a barcode-scan button to the trailing controls.
  final VoidCallback? onScanTap;

  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;

  /// Adds the library-only sort options to the filter sheet.
  final bool showLibrarySorts;

  /// Whether the trailing filter button (which opens the filter sheet) is
  /// shown. Desktop layouts turn it off: their filters sit in a permanent
  /// panel beside the results instead.
  final bool showFilterButton;

  /// Replaces the filter sheet the filter button opens — for result types with
  /// their own options (publishers' sort), which the series filters don't fit.
  final VoidCallback? onFilterTapOverride;

  final SuggestionRequest requestSuggestions;

  /// Null means suggestions are always enabled.
  final bool Function()? suggestionsEnabled;

  /// Rebuilt alongside [LocalizationService] — pass the setting that
  /// [suggestionsEnabled] reads, so toggling it takes effect immediately.
  final Listenable? rebuildOn;

  const SearchBarShell({
    super.key,
    required this.onChanged,
    required this.requestSuggestions,
    this.controller,
    this.focusNode,
    this.onSubmitted,
    this.onResultSelected,
    this.onResultHovered,
    this.onBackTap,
    this.onScanTap,
    this.initialFilters,
    this.onFilterApplied,
    this.showLibrarySorts = false,
    this.showFilterButton = true,
    this.onFilterTapOverride,
    this.suggestionsEnabled,
    this.rebuildOn,
  });

  @override
  State<SearchBarShell> createState() => _SearchBarShellState();
}

class _SearchBarShellState extends State<SearchBarShell> {
  /// Gap between the field and the overlay panel.
  static const double _overlayGap = 6.0;

  late final GhostTextEditingController _text;
  late final FocusNode _focusNode;
  late final SearchBarController _controller;
  late SearchFilters _filters;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _text = widget.controller ?? GhostTextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _filters = widget.initialFilters ?? SearchFilters();

    _controller = SearchBarController(
      text: _text,
      focusNode: _focusNode,
      requestSuggestions: widget.requestSuggestions,
      suggestionsEnabled: widget.suggestionsEnabled,
      onQueryChanged: widget.onChanged,
      onResultSelected: widget.onResultSelected,
    );

    _controller.addListener(_onStateChanged);
    // The field's own text is part of what it renders (the clear button
    // appears with it), so every controller change repaints.
    _text.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(SearchBarShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters &&
        widget.initialFilters != null) {
      setState(() => _filters = widget.initialFilters!);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _text.removeListener(_onStateChanged);
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    if (widget.controller == null) _text.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    _updateOverlay();
  }

  // ─── Overlay ─────────────────────────────────────────────────────────────

  void _updateOverlay() {
    if (!_controller.isOverlayVisible) {
      _hideOverlay();
      return;
    }
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final size = (context.findRenderObject() as RenderBox).size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + _overlayGap),
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            child: SearchSuggestionsPanel(
              results: _controller.results,
              onResultTapped: _controller.selectResult,
              showSuggestions: true,
              selectedIndex: _controller.selectedIndex,
              onResultHovered: widget.onResultHovered,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rebuildOn = widget.rebuildOn;
    return ListenableBuilder(
      listenable: rebuildOn == null
          ? LocalizationService()
          : Listenable.merge([LocalizationService(), rebuildOn]),
      builder: (context, _) => CompositedTransformTarget(
        link: _layerLink,
        child: _buildTextField(context),
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return SearchBarTextField(
      textController: _text,
      focusNode: _focusNode,
      controller: _controller,
      filters: _filters,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      onBackTap: widget.onBackTap,
      onScanTap: widget.onScanTap,
      onFilterTap: widget.showFilterButton
          ? (widget.onFilterTapOverride ?? _openFilterSheet)
          : null,
    );
  }

  void _openFilterSheet() {
    SearchFilterSheetLauncher.show(
      context,
      initialFilters: _filters,
      showLibrarySorts: widget.showLibrarySorts,
      onApply: (filters) {
        setState(() => _filters = filters);
        widget.onFilterApplied?.call(filters);
      },
    );
  }
}

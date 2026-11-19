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

class SearchBarShell extends StatefulWidget {
  /// Null: the shell owns and disposes one; otherwise the caller keeps ownership.
  final GhostTextEditingController? controller;
  final FocusNode? focusNode;

  final ValueChanged<String> onChanged;

  /// Falls back to [onChanged] when null.
  final ValueChanged<String>? onSubmitted;

  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

  final ValueChanged<AutocompleteSeriesResult>? onResultHovered;

  final VoidCallback? onBackTap;

  final VoidCallback? onScanTap;

  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;

  final bool showLibrarySorts;

  final bool showFilterButton;

  final VoidCallback? onFilterTapOverride;

  final SuggestionRequest requestSuggestions;

  /// Null means suggestions are always enabled.
  final bool Function()? suggestionsEnabled;

  /// Pass the setting [suggestionsEnabled] reads, so toggling it takes effect immediately.
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
    // The clear button follows the text, so every text change repaints.
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

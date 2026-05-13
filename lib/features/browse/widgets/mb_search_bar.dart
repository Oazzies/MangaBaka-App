import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_bottom_sheet.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/services/series_autocomplete_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';
import 'package:mangabaka_app/features/browse/widgets/search_suggestions_panel.dart';

import 'package:mangabaka_app/features/browse/widgets/mb_search_bar_suffix.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onScanTap;
  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

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
  });

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final SeriesAutocompleteService _service = SeriesAutocompleteService();
  late SearchFilters _currentFilters;

  List<AutocompleteSeriesResult> _results = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(MBSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters && widget.initialFilters != null) {
      setState(() {
        _currentFilters = widget.initialFilters!;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _service.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onChanged(query);
    if (!SettingsManager().autoSuggestBrowse) {
      _setSuggestions([]);
      return;
    }
    if (query.trim().length < SeriesAutocompleteService.minQueryLength) {
      _setSuggestions([]);
      return;
    }
    _service.search(
      query,
      onResults: (results) {
        if (!mounted) return;
        _setSuggestions(results);
      },
      onError: (_) {
        if (!mounted) return;
        _setSuggestions([]);
      },
    );
  }

  void _setSuggestions(List<AutocompleteSeriesResult> results) {
    setState(() {
      _results = results;
      _showSuggestions = results.isNotEmpty && _focusNode.hasFocus;
    });
  }

  void _onResultTapped(AutocompleteSeriesResult result) {
    _controller.text = result.title;
    _setSuggestions([]);
    _focusNode.unfocus();
    widget.onResultSelected?.call(result);
  }

  void _clear() {
    _controller.clear();
    _setSuggestions([]);
    widget.onChanged('');
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    } else if (_results.isNotEmpty && SettingsManager().autoSuggestBrowse) {
      setState(() => _showSuggestions = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsManager(), LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final autoSuggest = SettingsManager().autoSuggestBrowse;
        final effectiveShowSuggestions = _showSuggestions && autoSuggest;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(effectiveShowSuggestions),
            SearchSuggestionsPanel(
              results: _results,
              onResultTapped: _onResultTapped,
              showSuggestions: effectiveShowSuggestions,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(bool showSuggestions) {
    final bottomRadius = showSuggestions ? 0.0 : 40.0;
    final l10n = LocalizationService();

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: l10n.translate('search_hint'),
        hintStyle: TextStyle(color: AppConstants.textMutedColor),
        prefixIcon: Icon(Icons.search, color: AppConstants.textColor),
        suffixIcon: MBSearchBarSuffix(
          controllerText: _controller.text,
          onClear: _clear,
          onScanTap: widget.onScanTap,
          onFilterTap: _openFilterSheet,
          currentFilters: _currentFilters,
        ),
        filled: true,
        fillColor: AppConstants.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(40),
            bottom: Radius.circular(bottomRadius),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(40),
            bottom: Radius.circular(bottomRadius),
          ),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(40),
            bottom: Radius.circular(bottomRadius),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      style: TextStyle(color: AppConstants.textColor),
      onChanged: _onSearchChanged,
      onSubmitted: (text) {
        _setSuggestions([]);
        widget.onSubmitted?.call(text);
      },
      textInputAction: TextInputAction.search,
    );
  }

  void _openFilterSheet() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SearchFilterBottomSheet(
              isDialog: true,
              initialFilters: _currentFilters,
              onApply: (filters) {
                setState(() => _currentFilters = filters);
                widget.onFilterApplied?.call(filters);
              },
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppConstants.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SearchFilterBottomSheet(
          initialFilters: _currentFilters,
          onApply: (filters) {
            setState(() => _currentFilters = filters);
            widget.onFilterApplied?.call(filters);
          },
        );
      },
    );
  }
}

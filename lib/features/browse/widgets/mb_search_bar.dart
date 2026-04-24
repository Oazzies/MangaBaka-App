import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/browse/models/search_filters.dart';
import 'package:bakahyou/features/browse/widgets/search_filter_bottom_sheet.dart';
import 'package:bakahyou/features/series/models/autocomplete_series_result.dart';
import 'package:bakahyou/features/series/services/series_autocomplete_service.dart';

class MBSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final TextEditingController? controller;
  final VoidCallback? onScanTap;
  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

  const MBSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.initialFilters,
    this.onFilterApplied,
    this.controller,
    this.onScanTap,
    this.onResultSelected,
  });

  @override
  State<MBSearchBar> createState() => _MBSearchBarState();
}

class _MBSearchBarState extends State<MBSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final SeriesAutocompleteService _service = SeriesAutocompleteService();
  late SearchFilters _currentFilters;

  List<AutocompleteSeriesResult> _results = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _service.dispose();
    super.dispose();
  }

  // ─── Search logic ──────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    widget.onChanged(query);

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
      // Small delay so taps on suggestions register before we hide
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    } else if (_results.isNotEmpty) {
      setState(() => _showSuggestions = true);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(),
        _buildSuggestionsPanel(),
      ],
    );
  }

  Widget _buildTextField() {
    // When suggestions are visible, flatten the bottom corners so the
    // suggestions panel visually continues from the search bar.
    final bottomRadius = _showSuggestions ? 0.0 : 40.0;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search for something',
        hintStyle: TextStyle(color: AppConstants.textMutedColor),
        prefixIcon: Icon(Icons.search, color: AppConstants.textColor),
        suffixIcon: _buildSuffixIcons(),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
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

  Widget _buildSuffixIcons() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_controller.text.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.clear, color: AppConstants.textColor),
              onPressed: _clear,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
          if (widget.onScanTap != null) ...[
            IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: AppConstants.textColor,
              ),
              onPressed: widget.onScanTap,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _currentFilters.toMap().isNotEmpty
                  ? AppConstants.accentColor
                  : AppConstants.textColor,
            ),
            onPressed: _openFilterSheet,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Suggestions panel (in-tree, not an overlay) ───────────────────

  Widget _buildSuggestionsPanel() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _showSuggestions ? _buildSuggestionsList() : const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.secondaryBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtle separator between search field and suggestions
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppConstants.borderColor.withValues(alpha: 0.4),
            indent: 16,
            endIndent: 16,
          ),
          // Suggestion items
          ...List.generate(_results.length, (index) {
            final result = _results[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultTile(result),
                if (index < _results.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppConstants.borderColor.withValues(alpha: 0.2),
                    indent: 68,
                    endIndent: 16,
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultTile(AutocompleteSeriesResult result) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onResultTapped(result),
        splashColor: AppConstants.accentColor.withValues(alpha: 0.08),
        highlightColor: AppConstants.accentColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 36,
                  height: 50,
                  child: result.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          result.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildThumbnailPlaceholder(),
                        )
                      : _buildThumbnailPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  result.title,
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: AppConstants.textMutedColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: AppConstants.tertiaryBackground,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppConstants.textMutedColor,
        size: 18,
      ),
    );
  }

  // ─── Filter sheet ──────────────────────────────────────────────────

  void _openFilterSheet() {
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
            setState(() {
              _currentFilters = filters;
            });
            widget.onFilterApplied?.call(filters);
          },
        );
      },
    );
  }
}

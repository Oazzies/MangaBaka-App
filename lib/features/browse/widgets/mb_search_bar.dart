import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final GhostTextEditingController _controller;
  late final FocusNode _focusNode;
  final SeriesAutocompleteService _service = SeriesAutocompleteService();
  late SearchFilters _currentFilters;

  List<AutocompleteSeriesResult> _results = [];
  bool _showSuggestions = false;
  String _ghostSuffix = '';
  int _selectedIndex = -1;
  String _originalQuery = '';
  bool _isNavigatingWithArrows = false;
  
  bool _isAutocompleteSuppressed = false;
  String _suppressedQuery = '';
  
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller is GhostTextEditingController 
        ? widget.controller as GhostTextEditingController 
        : GhostTextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final query = _controller.text;
    final hasSuggestions = _results.isNotEmpty && _showSuggestions;

    // 1. Navigation (Up/Down) - now fills the search bar
    if (hasSuggestions) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _isNavigatingWithArrows = true;
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _results.length;
          _controller.text = _results[_selectedIndex].title;
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          _ghostSuffix = '';
          _controller.ghostSuffix = '';
        });
        _updateOverlay();
        _isNavigatingWithArrows = false;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _isNavigatingWithArrows = true;
        setState(() {
          if (_selectedIndex <= 0) {
            _selectedIndex = -1;
            _controller.text = _originalQuery;
          } else {
            _selectedIndex--;
            _controller.text = _results[_selectedIndex].title;
          }
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          _ghostSuffix = '';
          _controller.ghostSuffix = '';
        });
        _updateOverlay();
        _isNavigatingWithArrows = false;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _isNavigatingWithArrows = true;
        setState(() {
          _showSuggestions = false;
          _selectedIndex = -1;
          _controller.value = _controller.value.copyWith(
            text: _originalQuery,
            selection: TextSelection.collapsed(offset: _originalQuery.length),
          );
        });
        _updateOverlay();
        _isNavigatingWithArrows = false;
        return KeyEventResult.handled;
      }
    }

    // 2. Selection (Enter) - handled by onSubmitted
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      // If we have a selection, we'll let onSubmitted handle it using the current text
      return KeyEventResult.ignored; 
    }

    // 3. Rejection (Backspace)
    if (event.logicalKey == LogicalKeyboardKey.backspace && (_ghostSuffix.isNotEmpty || _selectedIndex != -1)) {
      setState(() {
        _isAutocompleteSuppressed = true;
        _suppressedQuery = _originalQuery;
        _ghostSuffix = '';
        _controller.ghostSuffix = '';
        _selectedIndex = -1;
        _showSuggestions = false;
        _controller.value = _controller.value.copyWith(
          text: _originalQuery,
          selection: TextSelection.collapsed(offset: _originalQuery.length),
        );
      });
      _updateOverlay();
      return KeyEventResult.handled;
    }

    // 4. Ghost text acceptance (Tab/ArrowRight)
    if (_ghostSuffix.isNotEmpty && _selectedIndex == -1) {
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              _controller.selection.baseOffset == query.length)) {
        _acceptGhostText();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(MBSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters && widget.initialFilters != null) {
      setState(() => _currentFilters = widget.initialFilters!);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _updateGhostText(List<AutocompleteSeriesResult> results) {
    if (_isAutocompleteSuppressed || _selectedIndex != -1) {
      _ghostSuffix = '';
      _controller.ghostSuffix = '';
      return;
    }
    final query = _controller.text;
    if (results.isEmpty || query.isEmpty || query == _suppressedQuery) {
      _ghostSuffix = '';
      _controller.ghostSuffix = '';
      return;
    }
    
    String? bestGhost;
    for (var result in results) {
      for (var t in result.allTitles) {
        final tLower = t.toLowerCase();
        final qLower = query.toLowerCase();
        if (tLower.startsWith(qLower) && t.length > query.length) {
          bestGhost = t.substring(query.length);
          break;
        }
      }
      if (bestGhost != null) break;
    }

    _ghostSuffix = bestGhost ?? '';
    _controller.ghostSuffix = bestGhost ?? '';
    _controller.ghostColor = AppConstants.textMutedColor.withValues(alpha: 0.5);
  }

  void _onSearchChanged(String query) {
    if (_isNavigatingWithArrows) return;

    _originalQuery = query;
    widget.onChanged(query);
    
    if (query.isEmpty) {
      _isAutocompleteSuppressed = false;
      _suppressedQuery = '';
      _selectedIndex = -1;
    }
    
    if (!_suppressedQuery.startsWith(query)) {
      _suppressedQuery = '';
    }

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
        
        final queryLower = query.toLowerCase();
        results.sort((a, b) {
          final aLower = a.title.toLowerCase();
          final bLower = b.title.toLowerCase();
          
          bool aExact = aLower == queryLower;
          bool bExact = bLower == queryLower;
          if (aExact && !bExact) return -1;
          if (!aExact && bExact) return 1;
          
          bool aStarts = aLower.startsWith(queryLower);
          bool bStarts = bLower.startsWith(queryLower);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;
          
          return a.title.length.compareTo(b.title.length);
        });

        _setSuggestions(results);
      },
      onError: (_) {},
    );
  }

  void _setSuggestions(List<AutocompleteSeriesResult> results) {
    setState(() {
      _results = results;
      _showSuggestions = results.isNotEmpty && _focusNode.hasFocus;
      _selectedIndex = -1;
      _updateGhostText(results);
    });
    _updateOverlay();
  }

  void _updateOverlay() {
    if (_showSuggestions && _originalQuery != _suppressedQuery) {
      if (_overlayEntry == null) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    } else {
      _hideOverlay();
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 6.0),
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            child: SearchSuggestionsPanel(
              results: _results,
              onResultTapped: _onResultTapped,
              showSuggestions: true,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
      ),
    );
  }

  void _onResultTapped(AutocompleteSeriesResult result) {
    _isNavigatingWithArrows = true;
    _controller.text = result.title;
    _originalQuery = result.title;
    _ghostSuffix = '';
    _controller.ghostSuffix = '';
    _setSuggestions([]);
    _focusNode.unfocus();
    _isNavigatingWithArrows = false;
    widget.onResultSelected?.call(result);
  }

  void _acceptGhostText() {
    if (_ghostSuffix.isEmpty || _results.isEmpty) return;
    
    AutocompleteSeriesResult? matchedResult;
    String? matchedTitle;
    
    final query = _controller.text;
    for (var result in _results) {
      for (var t in result.allTitles) {
        if (t.toLowerCase().startsWith(query.toLowerCase()) && t.substring(query.length) == _ghostSuffix) {
          matchedResult = result;
          matchedTitle = t;
          break;
        }
      }
      if (matchedResult != null) break;
    }

    if (matchedTitle != null) {
      _isNavigatingWithArrows = true;
      _controller.value = _controller.value.copyWith(
        text: matchedTitle,
        selection: TextSelection.collapsed(offset: matchedTitle.length),
      );
      _originalQuery = matchedTitle;
      _ghostSuffix = '';
      _controller.ghostSuffix = '';
      _setSuggestions([]);
      _isNavigatingWithArrows = false;
    }
  }

  void _clear() {
    _isNavigatingWithArrows = true;
    _controller.clear();
    _originalQuery = '';
    _setSuggestions([]);
    _suppressedQuery = '';
    _isAutocompleteSuppressed = false;
    _selectedIndex = -1;
    _isNavigatingWithArrows = false;
    widget.onChanged('');
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() {
            _showSuggestions = false;
            _ghostSuffix = '';
            _controller.ghostSuffix = '';
            _selectedIndex = -1;
          });
          _updateOverlay();
        }
      });
    } else if (_results.isNotEmpty && SettingsManager().autoSuggestBrowse) {
      setState(() {
        _isAutocompleteSuppressed = false;
        _showSuggestions = true;
      });
      _updateOverlay();
    } else {
      setState(() => _isAutocompleteSuppressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsManager(), LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        final autoSuggest = SettingsManager().autoSuggestBrowse;
        final effectiveShowSuggestions = _showSuggestions && autoSuggest;

        return CompositedTransformTarget(
          link: _layerLink,
          child: _buildTextField(effectiveShowSuggestions, autoSuggest),
        );
      },
    );
  }

  Widget _buildTextField(bool showSuggestions, bool autoSuggest) {
    final l10n = LocalizationService();

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppConstants.textColor,
      fontSize: 16,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.disable('kern')],
    ) ?? TextStyle(
      color: AppConstants.textColor, 
      fontSize: 16, 
      letterSpacing: 0,
      fontFeatures: const [FontFeature.disable('kern')],
    );

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: l10n.translate('search_hint'),
        hintStyle: TextStyle(color: AppConstants.textMutedColor, fontSize: 16),
        prefixIcon: Icon(Icons.search, color: AppConstants.textColor),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      style: baseStyle,
      onChanged: _onSearchChanged,
      onSubmitted: (text) {
        final ghostResult = _getMatchedResultForGhost();
        if (ghostResult != null) {
          _onResultTapped(ghostResult);
          return;
        }

        if (_selectedIndex != -1 && _results.isNotEmpty) {
          _onResultTapped(_results[_selectedIndex]);
          return;
        }

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

  AutocompleteSeriesResult? _getMatchedResultForGhost() {
    if (_ghostSuffix.isEmpty || _results.isEmpty) return null;
    final query = _controller.text;
    for (var result in _results) {
      for (var t in result.allTitles) {
        if (t.toLowerCase().startsWith(query.toLowerCase()) &&
            t.substring(query.length) == _ghostSuffix) {
          return result;
        }
      }
    }
    return null;
  }
}

class GhostTextEditingController extends TextEditingController {
  String ghostSuffix = '';
  Color? ghostColor;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (ghostSuffix.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    return TextSpan(
      style: style,
      children: [
        TextSpan(text: text),
        TextSpan(
          text: ghostSuffix,
          style: style?.copyWith(color: ghostColor),
        ),
      ],
    );
  }
}

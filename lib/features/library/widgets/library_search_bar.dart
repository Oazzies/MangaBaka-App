import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search_filter_bottom_sheet.dart';
import 'package:mangabaka_app/features/browse/widgets/search_suggestions_panel.dart';
import 'package:mangabaka_app/features/browse/widgets/mb_search_bar_suffix.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';

class LibrarySearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final FocusNode? focusNode;
  final Stream<List<LibraryEntry>>? entriesStream;
  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

  const LibrarySearchBar({
    super.key,
    required this.onChanged,
    this.initialFilters,
    this.onFilterApplied,
    this.focusNode,
    this.entriesStream,
    this.onResultSelected,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final GhostTextEditingController _controller = GhostTextEditingController();
  late final FocusNode _focusNode;
  final LibraryAutocompleteService _autocomplete = LibraryAutocompleteService();
  late SearchFilters _currentFilters;

  List<LibraryEntry> _allEntries = [];
  List<AutocompleteSeriesResult> _suggestions = [];
  bool _showSuggestions = false;
  String _ghostSuffix = '';
  int _selectedIndex = -1;
  String _originalQuery = '';
  bool _isNavigatingWithArrows = false;
  
  String _suppressedQuery = '';
  bool _isAutocompleteSuppressed = false;
  
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _currentFilters = widget.initialFilters ?? SearchFilters();
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChange);
    _focusNode.onKeyEvent = _handleKeyEvent;

    widget.entriesStream?.listen((entries) {
      if (mounted) _allEntries = entries;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final query = _controller.text;
    final hasSuggestions = _suggestions.isNotEmpty && _showSuggestions;

    // 1. Navigation
    if (hasSuggestions) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _isNavigatingWithArrows = true;
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
          _controller.text = _suggestions[_selectedIndex].title;
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
            _controller.text = _suggestions[_selectedIndex].title;
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

    // 2. Selection handled by onSubmitted
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
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

    // 4. Ghost text
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
  void didUpdateWidget(LibrarySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters && widget.initialFilters != null) {
      setState(() => _currentFilters = widget.initialFilters!);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onTextChanged(String query) {
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
    _updateSuggestions(query);
  }

  void _updateSuggestions(String query) {
    if (query.trim().isEmpty || query == _suppressedQuery) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _ghostSuffix = '';
        _controller.ghostSuffix = '';
        _selectedIndex = -1;
      });
      _updateOverlay();
      return;
    }

    final results = _autocomplete.search(query, _allEntries);
    
    final queryLower = query.toLowerCase();
    results.sort((a, b) {
      final aLower = a.title.toLowerCase();
      final bLower = b.title.toLowerCase();
      
      bool aExact = aLower == queryLower;
      bool bExact = bLower == queryLower;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      return a.title.length.compareTo(b.title.length);
    });

    String? ghost;
    if (results.isNotEmpty && !_isAutocompleteSuppressed) {
      for (var result in results) {
        for (var t in result.allTitles) {
          final tLower = t.toLowerCase();
          final qLower = query.toLowerCase();
          if (tLower.startsWith(qLower) && t.length > query.length) {
            ghost = t.substring(query.length);
            break;
          }
        }
        if (ghost != null) break;
      }
    }

    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty && _focusNode.hasFocus;
      _ghostSuffix = ghost ?? '';
      _controller.ghostSuffix = ghost ?? '';
      _controller.ghostColor = AppConstants.textMutedColor.withValues(alpha: 0.5);
      _selectedIndex = -1;
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
              results: _suggestions,
              onResultTapped: _onSuggestionTapped,
              showSuggestions: true,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
      ),
    );
  }

  void _onSuggestionTapped(AutocompleteSeriesResult result) {
    _isNavigatingWithArrows = true;
    _controller.text = result.title;
    _originalQuery = result.title;
    _ghostSuffix = '';
    _controller.ghostSuffix = '';
    widget.onChanged(result.title);
    _isNavigatingWithArrows = false;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _selectedIndex = -1;
    });
    _updateOverlay();
    _focusNode.unfocus();
    widget.onResultSelected?.call(result);
  }

  void _acceptGhostText() {
    if (_ghostSuffix.isEmpty || _suggestions.isEmpty) return;
    
    AutocompleteSeriesResult? matchedResult;
    String? matchedTitle;
    
    final query = _controller.text;
    for (var result in _suggestions) {
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
      _isNavigatingWithArrows = false;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedIndex = -1;
      });
      _updateOverlay();
    }
  }

  void _clear() {
    _isNavigatingWithArrows = true;
    _controller.clear();
    _originalQuery = '';
    _suppressedQuery = '';
    _isAutocompleteSuppressed = false;
    _selectedIndex = -1;
    _isNavigatingWithArrows = false;
    widget.onChanged('');
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _ghostSuffix = '';
      _controller.ghostSuffix = '';
    });
    _updateOverlay();
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
    } else if (_suggestions.isNotEmpty) {
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
      listenable: Listenable.merge([LocalizationService(), ThemeManager()]),
      builder: (context, _) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: _buildTextField(),
        );
      },
    );
  }

  Widget _buildTextField() {
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
          onScanTap: null,
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
      onChanged: _onTextChanged,
      onSubmitted: (text) {
        final ghostResult = _getMatchedResultForGhost();
        if (ghostResult != null) {
          _onSuggestionTapped(ghostResult);
          return;
        }

        if (_selectedIndex != -1 && _suggestions.isNotEmpty) {
          _onSuggestionTapped(_suggestions[_selectedIndex]);
          return;
        }

        setState(() => _showSuggestions = false);
        _updateOverlay();
        widget.onChanged(text);
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
              showLibrarySorts: true,
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
          showLibrarySorts: true,
          onApply: (filters) {
            setState(() => _currentFilters = filters);
            widget.onFilterApplied?.call(filters);
          },
        );
      },
    );
  }

  AutocompleteSeriesResult? _getMatchedResultForGhost() {
    if (_ghostSuffix.isEmpty || _suggestions.isEmpty) return null;
    final query = _controller.text;
    for (var result in _suggestions) {
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

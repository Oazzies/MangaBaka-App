import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

part 'search_bar_navigation_part.dart';

/// Not a Future: Browse may answer twice or never, while Library answers synchronously.
typedef SuggestionRequest =
    void Function(
      String query,
      ValueChanged<List<AutocompleteSeriesResult>> onResults,
    );

class SearchBarController extends ChangeNotifier {
  /// Lets a tap on a suggestion land before the blur that precedes it hides the overlay.
  static const Duration blurDismissDelay = Duration(milliseconds: 150);

  final GhostTextEditingController text;
  final FocusNode focusNode;

  final SuggestionRequest requestSuggestions;

  final bool Function() suggestionsEnabled;

  final ValueChanged<String> onQueryChanged;

  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;

  SearchBarController({
    required this.text,
    required this.focusNode,
    required this.requestSuggestions,
    required this.onQueryChanged,
    this.onResultSelected,
    bool Function()? suggestionsEnabled,
  }) : suggestionsEnabled = suggestionsEnabled ?? _alwaysEnabled {
    focusNode.addListener(_onFocusChange);
    focusNode.onKeyEvent = handleKeyEvent;
  }

  static bool _alwaysEnabled() => true;

  List<AutocompleteSeriesResult> _results = const [];
  bool _showSuggestions = false;
  String _ghostSuffix = '';
  int _selectedIndex = -1;
  String _originalQuery = '';
  bool _isProgrammaticEdit = false;
  bool _isSuppressed = false;
  String _suppressedQuery = '';
  bool _disposed = false;
  Timer? _blurTimer;

  List<AutocompleteSeriesResult> get results => _results;

  int get selectedIndex => _selectedIndex;

  bool get isOverlayVisible =>
      _showSuggestions && _originalQuery != _suppressedQuery;

  @override
  void dispose() {
    _disposed = true;
    _blurTimer?.cancel();
    focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void onTextChanged(String query) {
    if (_isProgrammaticEdit) return;

    _originalQuery = query;
    onQueryChanged(query);

    if (query.isEmpty) {
      _isSuppressed = false;
      _suppressedQuery = '';
      _selectedIndex = -1;
    }
    // Suppression covers the rejected query and what it grows into; diverging lifts it.
    if (!_suppressedQuery.startsWith(query)) _suppressedQuery = '';

    if (!suggestionsEnabled()) {
      setResults(const []);
      return;
    }

    requestSuggestions(query, (results) {
      if (_disposed) return;
      setResults(results);
    });
  }

  void setResults(List<AutocompleteSeriesResult> results) {
    _results = results;
    _showSuggestions = results.isNotEmpty && focusNode.hasFocus;
    _selectedIndex = -1;
    _applyGhost(results);
    _notify();
  }

  /// No ghost while a row is highlighted: the field already holds that row's title.
  void _applyGhost(List<AutocompleteSeriesResult> results) {
    final query = text.text;
    final blocked =
        _isSuppressed ||
        _selectedIndex != -1 ||
        query.isEmpty ||
        query == _suppressedQuery;

    _ghostSuffix = blocked
        ? ''
        : AutocompleteRanking.ghostSuffix(results, query);
    text.ghostSuffix = _ghostSuffix;
  }

  void _clearGhost() {
    _ghostSuffix = '';
    text.clearGhost();
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_results.isNotEmpty && _showSuggestions) {
      final handled = _handleNavigationKey(event);
      if (handled != null) return handled;
    }

    // Falls through to the field's onSubmitted, which knows whether a row is highlighted.
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        (_ghostSuffix.isNotEmpty || _selectedIndex != -1)) {
      _rejectSuggestion();
      return KeyEventResult.handled;
    }

    if (_ghostSuffix.isNotEmpty && _selectedIndex == -1) {
      final atEndOfLine = text.selection.baseOffset == text.text.length;
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          (event.logicalKey == LogicalKeyboardKey.arrowRight && atEndOfLine)) {
        acceptGhostText();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult? _handleNavigationKey(KeyEvent event) =>
      _handleNavigationKeyImpl(this, event);

  void _setFieldText(String value) => _setFieldTextImpl(this, value);

  void _rejectSuggestion() => _rejectSuggestionImpl(this);

  void acceptGhostText() {
    final match = AutocompleteRanking.matchForGhost(
      _results,
      text.text,
      _ghostSuffix,
    );
    if (match == null) return;
    _commit(match.title);
  }

  void selectResult(AutocompleteSeriesResult result) {
    _commit(result.title);
    focusNode.unfocus();
    onResultSelected?.call(result);
  }

  void _commit(String title) {
    _isProgrammaticEdit = true;
    _setFieldText(title);
    _originalQuery = title;
    _clearGhost();
    _isProgrammaticEdit = false;

    setResults(const []);
    onQueryChanged(title);
  }

  void clear() {
    _isProgrammaticEdit = true;
    text.clear();
    _originalQuery = '';
    _suppressedQuery = '';
    _isSuppressed = false;
    _selectedIndex = -1;
    _clearGhost();
    _isProgrammaticEdit = false;

    setResults(const []);
    onQueryChanged('');
  }

  /// Null means the caller should run the query itself.
  AutocompleteSeriesResult? resolveSubmission() {
    final match = AutocompleteRanking.matchForGhost(
      _results,
      text.text,
      _ghostSuffix,
    );
    if (match != null) {
      selectResult(match.result);
      return match.result;
    }
    if (_selectedIndex != -1 && _selectedIndex < _results.length) {
      final result = _results[_selectedIndex];
      selectResult(result);
      return result;
    }
    setResults(const []);
    return null;
  }

  void _onFocusChange() {
    _blurTimer?.cancel();
    if (focusNode.hasFocus) {
      _isSuppressed = false;
      if (_results.isNotEmpty && suggestionsEnabled()) _showSuggestions = true;
      _notify();
      return;
    }

    _blurTimer = Timer(blurDismissDelay, () {
      if (focusNode.hasFocus) return;
      _showSuggestions = false;
      _clearGhost();
      _selectedIndex = -1;
      _notify();
    });
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}

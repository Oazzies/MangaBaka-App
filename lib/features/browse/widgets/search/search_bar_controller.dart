import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

/// Asks for suggestions for [query] and delivers them to [onResults].
///
/// Deliberately callback-shaped rather than a `Future`: the Browse source is
/// debounced and cancellable and may answer more than once or not at all,
/// while the Library source answers synchronously from memory.
typedef SuggestionRequest = void Function(
  String query,
  ValueChanged<List<AutocompleteSeriesResult>> onResults,
);

/// The state machine behind the search field: what suggestions exist, which
/// one is highlighted, what the inline completion is, and when suggestions are
/// suppressed.
///
/// Separate from the widget because none of it is layout — it is a small set
/// of rules about typing that were previously duplicated between the Browse
/// and Library fields and had drifted apart. Notifies listeners on every
/// change; the widget rebuilds and repositions its overlay from that.
class SearchBarController extends ChangeNotifier {
  /// How long the overlay lingers after focus is lost, so a tap *on* a
  /// suggestion is not cancelled by the blur that precedes it.
  static const Duration blurDismissDelay = Duration(milliseconds: 150);

  final GhostTextEditingController text;
  final FocusNode focusNode;

  /// Where suggestions come from.
  final SuggestionRequest requestSuggestions;

  /// Consulted before every request and before re-showing on focus, so a user
  /// who has turned suggestions off never sees them.
  final bool Function() suggestionsEnabled;

  /// Fires on every keystroke, on clear with an empty string, and when a
  /// suggestion is chosen.
  final ValueChanged<String> onQueryChanged;

  /// Fires when a suggestion is chosen by any means.
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

  List<AutocompleteSeriesResult> get results => _results;

  /// Index of the row highlighted by the arrow keys, or -1 for none.
  int get selectedIndex => _selectedIndex;

  /// True when the overlay should be on screen. A query the user has rejected
  /// keeps it closed even while results for it are still held.
  bool get isOverlayVisible =>
      _showSuggestions && _originalQuery != _suppressedQuery;

  @override
  void dispose() {
    _disposed = true;
    focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  // ─── Query flow ──────────────────────────────────────────────────────────

  void onTextChanged(String query) {
    // Arrow-key navigation and completion write to the field; that is not the
    // user typing and must not trigger a new search.
    if (_isProgrammaticEdit) return;

    _originalQuery = query;
    onQueryChanged(query);

    if (query.isEmpty) {
      _isSuppressed = false;
      _suppressedQuery = '';
      _selectedIndex = -1;
    }
    // The suppression covers the rejected query and what it grows into;
    // typing something that diverges from it lifts the block.
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

  /// Recomputes the inline completion. Suppressed while the user has rejected
  /// one, and while a row is highlighted — the field already holds that row's
  /// title, so there is nothing left to complete.
  void _applyGhost(List<AutocompleteSeriesResult> results) {
    final query = text.text;
    final blocked = _isSuppressed ||
        _selectedIndex != -1 ||
        query.isEmpty ||
        query == _suppressedQuery;

    _ghostSuffix =
        blocked ? '' : AutocompleteRanking.ghostSuffix(results, query);
    text.ghostSuffix = _ghostSuffix;
  }

  void _clearGhost() {
    _ghostSuffix = '';
    text.clearGhost();
  }

  // ─── Keyboard ────────────────────────────────────────────────────────────

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_results.isNotEmpty && _showSuggestions) {
      final handled = _handleNavigationKey(event);
      if (handled != null) return handled;
    }

    // Enter falls through to the field's own onSubmitted, which knows whether
    // a row is highlighted.
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

  /// Down/Up move through the overlay and write the highlighted title into the
  /// field; Escape abandons the walk and restores what was typed. Returns null
  /// for any other key.
  KeyEventResult? _handleNavigationKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return _navigate(() {
        _selectedIndex = (_selectedIndex + 1) % _results.length;
        _setFieldText(_results[_selectedIndex].title);
      });
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return _navigate(() {
        // Walking up past the first row returns to the typed query.
        if (_selectedIndex <= 0) {
          _selectedIndex = -1;
          _setFieldText(_originalQuery);
        } else {
          _selectedIndex--;
          _setFieldText(_results[_selectedIndex].title);
        }
      });
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return _navigate(() {
        _showSuggestions = false;
        _selectedIndex = -1;
        _setFieldText(_originalQuery);
      });
    }
    return null;
  }

  /// Runs a programmatic field edit with the typing guard raised, so the
  /// resulting change is not reported as user input.
  KeyEventResult _navigate(VoidCallback change) {
    _isProgrammaticEdit = true;
    change();
    _clearGhost();
    _isProgrammaticEdit = false;
    _notify();
    return KeyEventResult.handled;
  }

  void _setFieldText(String value) {
    text.value = text.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  /// Backspace over a completion: restore the typed query and stop suggesting
  /// for it until the user types something that diverges.
  void _rejectSuggestion() {
    _isProgrammaticEdit = true;
    _isSuppressed = true;
    _suppressedQuery = _originalQuery;
    _clearGhost();
    _selectedIndex = -1;
    _showSuggestions = false;
    _setFieldText(_originalQuery);
    _isProgrammaticEdit = false;
    _notify();
  }

  void acceptGhostText() {
    final match =
        AutocompleteRanking.matchForGhost(_results, text.text, _ghostSuffix);
    if (match == null) return;
    _commit(match.title);
  }

  void selectResult(AutocompleteSeriesResult result) {
    _commit(result.title);
    focusNode.unfocus();
    onResultSelected?.call(result);
  }

  /// Puts [title] in the field as the settled query and closes the overlay.
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

  /// Resolves what submitting the field means: accept the inline completion,
  /// take the highlighted row, or fall through to a plain search.
  ///
  /// Returns the chosen result, or null when the caller should run the query
  /// itself.
  AutocompleteSeriesResult? resolveSubmission() {
    final match =
        AutocompleteRanking.matchForGhost(_results, text.text, _ghostSuffix);
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
    if (focusNode.hasFocus) {
      // Refocusing is a fresh start: whatever was rejected before no longer
      // applies.
      _isSuppressed = false;
      if (_results.isNotEmpty && suggestionsEnabled()) _showSuggestions = true;
      _notify();
      return;
    }

    Future.delayed(blurDismissDelay, () {
      // Focus may have returned during the delay.
      if (_disposed || focusNode.hasFocus) return;
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

part of 'search_bar_controller.dart';

KeyEventResult? _handleNavigationKeyImpl(
  SearchBarController self,
  KeyEvent event,
) {
  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
    return _navigateImpl(self, () {
      self._selectedIndex = (self._selectedIndex + 1) % self._results.length;
      _setFieldTextImpl(self, self._results[self._selectedIndex].title);
    });
  }
  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
    return _navigateImpl(self, () {
      if (self._selectedIndex <= 0) {
        self._selectedIndex = -1;
        _setFieldTextImpl(self, self._originalQuery);
      } else {
        self._selectedIndex--;
        _setFieldTextImpl(self, self._results[self._selectedIndex].title);
      }
    });
  }
  if (event.logicalKey == LogicalKeyboardKey.escape) {
    return _navigateImpl(self, () {
      self._showSuggestions = false;
      self._selectedIndex = -1;
      _setFieldTextImpl(self, self._originalQuery);
    });
  }
  return null;
}

KeyEventResult _navigateImpl(SearchBarController self, VoidCallback change) {
  self._isProgrammaticEdit = true;
  change();
  self._clearGhost();
  self._isProgrammaticEdit = false;
  self._notify();
  return KeyEventResult.handled;
}

void _setFieldTextImpl(SearchBarController self, String value) {
  self.text.value = self.text.value.copyWith(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
    composing: TextRange.empty,
  );
}

void _rejectSuggestionImpl(SearchBarController self) {
  self._isProgrammaticEdit = true;
  self._isSuppressed = true;
  self._suppressedQuery = self._originalQuery;
  self._clearGhost();
  self._selectedIndex = -1;
  self._showSuggestions = false;
  _setFieldTextImpl(self, self._originalQuery);
  self._isProgrammaticEdit = false;
  self._notify();
}

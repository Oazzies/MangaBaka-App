import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search/autocomplete_ranking.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_shell.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/library/services/library_autocomplete_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class LibrarySearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final SearchFilters? initialFilters;
  final ValueChanged<SearchFilters>? onFilterApplied;
  final FocusNode? focusNode;

  final Stream<List<LibraryEntry>>? entriesStream;

  final ValueChanged<AutocompleteSeriesResult>? onResultSelected;
  final VoidCallback? onBackTap;
  final bool showFilterButton;

  const LibrarySearchBar({
    super.key,
    required this.onChanged,
    this.initialFilters,
    this.onFilterApplied,
    this.focusNode,
    this.entriesStream,
    this.onResultSelected,
    this.onBackTap,
    this.showFilterButton = true,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final LibraryAutocompleteService _autocomplete = LibraryAutocompleteService();

  StreamSubscription<List<LibraryEntry>>? _entriesSubscription;
  List<LibraryEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(LibrarySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entriesStream != oldWidget.entriesStream) _subscribe();
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _entriesSubscription?.cancel();
    _entriesSubscription = widget.entriesStream?.listen((entries) {
      if (mounted) _entries = entries;
    });
  }

  void _requestSuggestions(
    String query,
    ValueChanged<List<AutocompleteSeriesResult>> onResults,
  ) {
    if (query.trim().isEmpty) {
      onResults(const []);
      return;
    }
    final results = _autocomplete.search(query, _entries);
    // The library matcher already scores prefixes; re-ranking on them would fight its order.
    AutocompleteRanking.sort(results, query, preferPrefixMatches: false);
    onResults(results);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBarShell(
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onResultSelected: widget.onResultSelected,
      onBackTap: widget.onBackTap,
      initialFilters: widget.initialFilters,
      onFilterApplied: widget.onFilterApplied,
      showLibrarySorts: true,
      showFilterButton: widget.showFilterButton,
      requestSuggestions: _requestSuggestions,
      suggestionsEnabled: () => SettingsManager().autoSuggestLibrary,
      rebuildOn: SettingsManager(),
    );
  }
}

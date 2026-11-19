import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/library/constants/library_screen_constants.dart';
import 'package:mangabaka_app/features/library/helpers/library_filter_helper.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';

/// Counts and tab choice share one filtered set, so a tab's badge matches what opening it shows.
class LibraryTabCoordinator {
  static final _logger = LoggingService.logger;

  final TabController controller;

  LibraryTabCoordinator({required this.controller});

  String _query = '';
  SearchFilters _filters = SearchFilters();

  List<LibraryEntry> _entries = const [];

  void setEntries(List<LibraryEntry> entries) => _entries = entries;

  void setQuery(String query) => _query = query;

  void setFilters(SearchFilters filters) => _filters = filters;

  void reset() {
    _query = '';
    _filters = SearchFilters();
  }

  LibraryFilterHelper filterFor(List<LibraryEntry> entries) =>
      LibraryFilterHelper(
        allEntries: entries,
        query: _query,
        contentPreferences: SettingsManager().contentPreferences,
        filters: _filters,
      );

  Map<String, int> countsFor(List<LibraryEntry> entries) {
    final counts = <String, int>{};
    for (final entry in filterFor(entries).getFilteredAndSorted()) {
      counts[entry.state] = (counts[entry.state] ?? 0) + 1;
    }
    return counts;
  }

  void autoSwitch() {
    if (_query.isEmpty && _filters.isEmpty) return;
    // Mid-swipe the index is in flux; moving it again would fight the gesture.
    if (controller.indexIsChanging) return;

    final helper = filterFor(_entries);
    final tabs = LibraryScreenConstants.tabs;
    final currentKey = tabs[controller.index].key;
    if (helper.getByTab(currentKey).isNotEmpty) return;

    _logger.info(
      'Current tab ($currentKey) is empty while searching. '
      'Looking for other tabs...',
    );
    for (var i = 0; i < tabs.length; i++) {
      if (helper.getByTab(tabs[i].key).isEmpty) continue;
      _logger.info('Auto-switching to tab: ${tabs[i].key} (index $i)');
      controller.animateTo(i);
      return;
    }
  }
}

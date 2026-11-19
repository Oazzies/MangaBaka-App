import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';

enum ListScopeTab {
  library,
  browse,
  stacks;

  bool get isLibrary => this == ListScopeTab.library;
}

/// Style and column-count separation are independent switches; resolve them here, never inline.
class ListCustomizationScope {
  final SettingsManager settings;
  final ListScopeTab tab;

  const ListCustomizationScope({required this.settings, required this.tab});

  bool get hasAnySeparation =>
      settings.separateListStyles || settings.separateGridColumnCounts;

  AppListStyle get style {
    if (!settings.separateListStyles) return settings.currentListStyle;
    return switch (tab) {
      ListScopeTab.library => settings.libraryListStyle,
      ListScopeTab.browse => settings.browseListStyle,
      ListScopeTab.stacks => settings.stacksListStyle,
    };
  }

  void setStyle(AppListStyle style) {
    if (!settings.separateListStyles) {
      settings.setListStyle(style);
    } else {
      switch (tab) {
        case ListScopeTab.library:
          settings.setLibraryListStyle(style);
        case ListScopeTab.browse:
          settings.setBrowseListStyle(style);
        case ListScopeTab.stacks:
          settings.setStacksListStyle(style);
      }
    }
  }

  String styleLabel(LocalizationService l10n) {
    if (!settings.separateListStyles) return l10n.translate('list_style');
    return l10n.translate(switch (tab) {
      ListScopeTab.library => 'library_list_style',
      ListScopeTab.browse => 'browse_list_style',
      ListScopeTab.stacks => 'stacks_list_style',
    });
  }

  /// 0 means auto: fit as many columns as the width allows.
  int get gridColumns {
    if (!settings.separateGridColumnCounts) return settings.gridColumnCount;
    return switch (tab) {
      ListScopeTab.library => settings.libraryGridColumnCount,
      ListScopeTab.browse => settings.browseGridColumnCount,
      ListScopeTab.stacks => settings.stacksGridColumnCount,
    };
  }

  void setGridColumns(int count) {
    if (!settings.separateGridColumnCounts) {
      settings.setGridColumnCount(count);
    } else {
      switch (tab) {
        case ListScopeTab.library:
          settings.setLibraryGridColumnCount(count);
        case ListScopeTab.browse:
          settings.setBrowseGridColumnCount(count);
        case ListScopeTab.stacks:
          settings.setStacksGridColumnCount(count);
      }
    }
  }

  String gridColumnsLabel(LocalizationService l10n) {
    if (!settings.separateGridColumnCounts) {
      return l10n.translate('grid_columns');
    }
    return l10n.translate(switch (tab) {
      ListScopeTab.library => 'library_grid_columns',
      ListScopeTab.browse => 'browse_grid_columns',
      ListScopeTab.stacks => 'stacks_grid_columns',
    });
  }

  bool get showsGridColumns =>
      style == AppListStyle.coverOnlyGrid || style == AppListStyle.compactGrid;

  /// Seeds or adopts the current style so the toggle itself never changes how anything looks.
  void setSeparateStyles(bool separate) {
    if (separate) {
      final shared = settings.currentListStyle;
      settings.setLibraryListStyle(shared);
      settings.setBrowseListStyle(shared);
      settings.setStacksListStyle(shared);
    } else {
      settings.setListStyle(style);
    }
    settings.setSeparateListStyles(separate);
  }

  void setSeparateGridColumns(bool separate) {
    if (separate) {
      final shared = settings.gridColumnCount;
      settings.setLibraryGridColumnCount(shared);
      settings.setBrowseGridColumnCount(shared);
      settings.setStacksGridColumnCount(shared);
    } else {
      settings.setGridColumnCount(gridColumns);
    }
    settings.setSeparateGridColumnCounts(separate);
  }

  void copyToOtherTabs() {
    final style = this.style;
    final columns = gridColumns;
    for (final other in ListScopeTab.values) {
      if (other == tab) continue;
      final target = ListCustomizationScope(settings: settings, tab: other);
      if (settings.separateListStyles) target.setStyle(style);
      if (settings.separateGridColumnCounts) target.setGridColumns(columns);
    }
  }
}

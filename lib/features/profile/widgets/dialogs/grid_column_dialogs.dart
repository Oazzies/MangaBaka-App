import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'selection_bottom_sheet.dart';

class GridColumnDialogs {
  static String getGridColumnLabel(int val) {
    final l10n = LocalizationService();
    return val == 0 ? l10n.translate('grid_columns_auto') : val.toString();
  }

  static void showGridColumnCountPortraitDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('grid_columns_portrait'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      currentValue: settings.gridColumnCountPortrait,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setGridColumnCountPortrait(val),
    );
  }

  static void showGridColumnCountLandscapeDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('grid_columns_landscape'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.gridColumnCountLandscape,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setGridColumnCountLandscape(val),
    );
  }

  static void showLibraryGridColumnCountPortraitDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('library_grid_columns_portrait'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      currentValue: settings.libraryGridColumnCountPortrait,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setLibraryGridColumnCountPortrait(val),
    );
  }

  static void showLibraryGridColumnCountLandscapeDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('library_grid_columns_landscape'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.libraryGridColumnCountLandscape,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setLibraryGridColumnCountLandscape(val),
    );
  }

  static void showBrowseGridColumnCountPortraitDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('browse_grid_columns_portrait'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      currentValue: settings.browseGridColumnCountPortrait,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setBrowseGridColumnCountPortrait(val),
    );
  }

  static void showBrowseGridColumnCountLandscapeDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('browse_grid_columns_landscape'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.browseGridColumnCountLandscape,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setBrowseGridColumnCountLandscape(val),
    );
  }
}

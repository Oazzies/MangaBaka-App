import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'selection_bottom_sheet.dart';

class GridColumnDialogs {
  static String getGridColumnLabel(int val) {
    final l10n = LocalizationService();
    return val == 0 ? l10n.translate('grid_columns_auto') : val.toString();
  }

  static void showGridColumnCountDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('grid_columns'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.gridColumnCount,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setGridColumnCount(val),
    );
  }

  static void showLibraryGridColumnCountDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('library_grid_columns'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.libraryGridColumnCount,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setLibraryGridColumnCount(val),
    );
  }

  static void showBrowseGridColumnCountDialog(BuildContext context) {
    final l10n = LocalizationService();
    final settings = SettingsManager();
    SelectionBottomSheet.showSelectionBottomSheet<int>(
      context: context,
      title: l10n.translate('browse_grid_columns'),
      subtitle: l10n.translate('grid_columns_subtitle'),
      options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      currentValue: settings.browseGridColumnCount,
      getLabel: getGridColumnLabel,
      onSelected: (val) => settings.setBrowseGridColumnCount(val),
    );
  }
}

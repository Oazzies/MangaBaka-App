import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/widgets/sort_selection_dialog.dart';
import 'package:mangabaka_app/features/browse/widgets/licensed_status_dialog.dart';

class SearchFilterDialogs {
  static void showSortSelectionDialog({
    required BuildContext context,
    required LocalizationService l10n,
    required Map<String, String> sortOptions,
    required SearchFilters currentFilters,
    required ValueChanged<String?> onSortSelected,
  }) {
    SortSelectionDialog.show(
      context: context,
      l10n: l10n,
      sortOptions: sortOptions,
      currentFilters: currentFilters,
      onSortSelected: onSortSelected,
    );
  }

  static void showLicensedStatusDialog({
    required BuildContext context,
    required LocalizationService l10n,
    required SearchFilters currentFilters,
    required ValueChanged<bool?> onStatusSelected,
  }) {
    LicensedStatusDialog.show(
      context: context,
      l10n: l10n,
      currentFilters: currentFilters,
      onStatusSelected: onStatusSelected,
    );
  }
}

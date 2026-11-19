import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_bottom_sheet.dart';

class SearchFilterSheetLauncher {
  SearchFilterSheetLauncher._();

  static void show(
    BuildContext context, {
    required SearchFilters initialFilters,
    required ValueChanged<SearchFilters> onApply,
    bool showLibrarySorts = false,
  }) {
    showAdaptiveSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.largeRadius),
        ),
      ),
      builder: (_) => SearchFilterBottomSheet(
        initialFilters: initialFilters,
        showLibrarySorts: showLibrarySorts,
        onApply: onApply,
      ),
    );
  }
}

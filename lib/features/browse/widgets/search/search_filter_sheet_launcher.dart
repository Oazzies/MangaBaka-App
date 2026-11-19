import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_bottom_sheet.dart';

/// Landscape uses a dialog: a sheet on a short, wide window becomes a letterbox strip.
class SearchFilterSheetLauncher {
  SearchFilterSheetLauncher._();

  /// Past this the filter rows stretch into unreadably long lines.
  static const double _maxDialogWidth = 600;

  static void show(
    BuildContext context, {
    required SearchFilters initialFilters,
    required ValueChanged<SearchFilters> onApply,
    bool showLibrarySorts = false,
  }) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
            child: SearchFilterBottomSheet(
              isDialog: true,
              showLibrarySorts: showLibrarySorts,
              initialFilters: initialFilters,
              onApply: onApply,
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
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

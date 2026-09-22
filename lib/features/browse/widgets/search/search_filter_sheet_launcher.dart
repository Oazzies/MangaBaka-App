import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_bottom_sheet.dart';

/// Presents [SearchFilterBottomSheet] the way the current layout calls for.
///
/// Portrait raises it as a bottom sheet. Landscape shows the same content in a
/// centred dialog instead: a sheet on a short, wide window ends up a letterbox
/// strip with almost no room for the filters themselves.
class SearchFilterSheetLauncher {
  SearchFilterSheetLauncher._();

  /// Widest the landscape dialog grows. Past this the filter rows stretch into
  /// unreadably long lines.
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

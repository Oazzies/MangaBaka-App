import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class MBSearchBarSuffix extends StatelessWidget {
  final String controllerText;
  final VoidCallback onClear;
  final VoidCallback? onScanTap;

  /// Null hides the filter button.
  final VoidCallback? onFilterTap;
  final SearchFilters currentFilters;

  const MBSearchBarSuffix({
    super.key,
    required this.controllerText,
    required this.onClear,
    this.onScanTap,
    this.onFilterTap,
    required this.currentFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (controllerText.isNotEmpty) ...[
            WidgetUtils.tooltip(
              message: LocalizationService().translate('reset'),
              child: IconButton(
                icon: Icon(Icons.clear, color: context.colors.text),
                onPressed: onClear,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (onScanTap != null) ...[
            WidgetUtils.tooltip(
              message: LocalizationService().translate('scan_isbn_barcode'),
              child: IconButton(
                icon: Icon(Icons.qr_code_scanner, color: context.colors.text),
                onPressed: onScanTap,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (onFilterTap != null)
            WidgetUtils.tooltip(
              message: LocalizationService().translate('filters'),
              child: IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: currentFilters.toMap().isNotEmpty
                      ? context.colors.accent
                      : context.colors.text,
                ),
                onPressed: onFilterTap,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }
}

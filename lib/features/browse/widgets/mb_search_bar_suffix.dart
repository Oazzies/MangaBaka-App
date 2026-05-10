import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';

class MBSearchBarSuffix extends StatelessWidget {
  final String controllerText;
  final VoidCallback onClear;
  final VoidCallback? onScanTap;
  final VoidCallback onFilterTap;
  final SearchFilters currentFilters;

  const MBSearchBarSuffix({
    super.key,
    required this.controllerText,
    required this.onClear,
    this.onScanTap,
    required this.onFilterTap,
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
            IconButton(
              icon: Icon(Icons.clear, color: AppConstants.textColor),
              onPressed: onClear,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
          if (onScanTap != null) ...[
            IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: AppConstants.textColor,
              ),
              onPressed: onScanTap,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: currentFilters.toMap().isNotEmpty
                  ? AppConstants.accentColor
                  : AppConstants.textColor,
            ),
            onPressed: onFilterTap,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/design/mb_dropdown.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

/// Sort and spoiler filter controls for [StacksPagedView].
class StacksPagedFilterBar extends StatelessWidget {
  final LocalizationService l10n;
  final StackSort sort;
  final StackSpoilerFilter spoilers;
  final ValueChanged<StackSort> onSortChanged;
  final ValueChanged<StackSpoilerFilter> onSpoilersChanged;

  const StacksPagedFilterBar({
    super.key,
    required this.l10n,
    required this.sort,
    required this.spoilers,
    required this.onSortChanged,
    required this.onSpoilersChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Side by side on a phone, each taking half; wrapping chips on desktop.
    final phone =
        MediaQuery.sizeOf(context).width < 600 &&
        !DesktopLayout.isActive(context);
    final dropdowns = [
      MbDropdown<StackSort>(
        expand: phone,
        label: l10n.translate('sort_by'),
        icon: Icons.sort_rounded,
        value: sort,
        options: [
          for (final s in StackSort.values) (s, l10n.translate(s.labelKey)),
        ],
        onChanged: onSortChanged,
      ),
      MbDropdown<StackSpoilerFilter>(
        expand: phone,
        label: l10n.translate('stacks_spoilers'),
        icon: Icons.visibility_off_outlined,
        value: spoilers,
        options: [
          for (final s in StackSpoilerFilter.values)
            (s, l10n.translate(s.labelKey)),
        ],
        onChanged: onSpoilersChanged,
      ),
    ];
    if (phone) {
      return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 400
            ? Column(
                children: [
                  dropdowns[0],
                  const SizedBox(height: 8),
                  dropdowns[1],
                ],
              )
            : Row(
                children: [
                  Expanded(child: dropdowns[0]),
                  const SizedBox(width: 8),
                  Expanded(child: dropdowns[1]),
                ],
              ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: dropdowns,
      ),
    );
  }
}

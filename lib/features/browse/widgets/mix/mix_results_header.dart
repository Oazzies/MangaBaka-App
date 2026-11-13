import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_section_header.dart';

class MixResultsHeader extends StatelessWidget {
  final LocalizationService l10n;
  final int resultCount;

  const MixResultsHeader({
    super.key,
    required this.l10n,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final header = MixSectionHeader(
      icon: Icons.auto_awesome_rounded,
      title: l10n.translate('mix_results'),
      trailing: '$resultCount',
      trailingFontSize: 16,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      // The same list-style toggle Browse carries, so a mix can be read as a
      // grid or a list without a trip to settings. It writes the Browse style,
      // which is what the results below already follow.
      child: DesktopLayout.isActive(context)
          ? Row(
              children: [
                Expanded(child: header),
                const DesktopListStyleToggle(scope: DesktopListScope.browse),
              ],
            )
          : header,
    );
  }
}

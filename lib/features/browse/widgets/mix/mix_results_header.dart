import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/desktop/desktop_layout.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_list_controls.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_section_header.dart';

class MixResultsHeader extends StatelessWidget {
  final LocalizationService l10n;
  final int resultCount;
  final bool loading;

  const MixResultsHeader({
    super.key,
    required this.l10n,
    required this.resultCount,
    required this.loading,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Writes the Browse list style, which the mix results below already follow.
          if (DesktopLayout.isActive(context))
            Row(
              children: [
                Expanded(child: header),
                const DesktopListStyleToggle(scope: DesktopListScope.browse),
              ],
            )
          else
            header,
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              height: 2,
              child: loading
                  ? LinearProgressIndicator(
                      minHeight: 2,
                      color: context.colors.accent,
                      backgroundColor: Colors.transparent,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

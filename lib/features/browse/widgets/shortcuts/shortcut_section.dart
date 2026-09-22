import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcuts/shortcut_button.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';

import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Describes a custom button entry for [ShortcutSection.customButtons].
class ShortcutButtonEntry {
  final String label;
  final VoidCallback onPressed;

  const ShortcutButtonEntry({required this.label, required this.onPressed});
}

class ShortcutSection extends StatelessWidget {
  final String header;
  final VoidCallback? onMostPopular;
  final VoidCallback? onTopRated;
  final VoidCallback? onRandom;

  /// When provided, overrides the default Most Popular / Top Rated / Random buttons.
  /// Use this to render any custom set of buttons (e.g. a single "Mix" button).
  final List<ShortcutButtonEntry>? customButtons;

  const ShortcutSection({
    required this.header,
    this.onMostPopular,
    this.onTopRated,
    this.onRandom,
    this.customButtons,
    super.key,
  }) : assert(
         customButtons != null || onMostPopular != null,
         'Either customButtons or onMostPopular must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();

        // Build the list of buttons to display
        final List<ShortcutButton> buttons;
        if (customButtons != null) {
          buttons = customButtons!
              .map(
                (e) => ShortcutButton(label: e.label, onPressed: e.onPressed),
              )
              .toList();
        } else {
          buttons = [
            ShortcutButton(
              label: l10n.translate('most_popular'),
              onPressed: onMostPopular!,
            ),
            if (onTopRated != null)
              ShortcutButton(
                label: l10n.translate('top_rated'),
                onPressed: onTopRated!,
              ),
            if (onRandom != null)
              ShortcutButton(
                label: l10n.translate('random'),
                onPressed: onRandom!,
              ),
          ];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header.toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 22,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 3;
                  if (constraints.maxWidth < 450) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 750) {
                    crossAxisCount = 2;
                  }

                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 64,
                    ),
                    children: [
                      for (var i = 0; i < buttons.length; i++)
                        MbEntrance(index: i, child: buttons[i]),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

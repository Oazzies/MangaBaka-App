import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcut_button.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';

/// Describes a custom button entry for [ShortcutSection.customButtons].
class ShortcutButtonEntry {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ShortcutButtonEntry({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
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
              .map((e) => ShortcutButton(
                    icon: e.icon,
                    label: e.label,
                    onPressed: e.onPressed,
                  ))
              .toList();
        } else {
          buttons = [
            ShortcutButton(
              icon: Icons.trending_up_rounded,
              label: l10n.translate('most_popular'),
              onPressed: onMostPopular!,
            ),
            if (onTopRated != null)
              ShortcutButton(
                icon: Icons.star_outline,
                label: l10n.translate('top_rated'),
                onPressed: onTopRated!,
              ),
            if (onRandom != null)
              ShortcutButton(
                icon: Icons.casino_outlined,
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
                header,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  height: 1.15,
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
                    children: buttons,
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


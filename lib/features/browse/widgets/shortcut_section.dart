import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/widgets/shortcut_button.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';

import 'package:mangabaka_app/utils/localization/localization_service.dart';

class ShortcutSection extends StatelessWidget {
  final String header;
  final VoidCallback onMostPopular;
  final VoidCallback? onTopRated;
  final VoidCallback onRandom;

  const ShortcutSection({
    required this.header,
    required this.onMostPopular,
    this.onTopRated,
    required this.onRandom,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final l10n = LocalizationService();
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
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
                    children: [
                      ShortcutButton(
                        icon: Icons.trending_up_rounded,
                        label: l10n.translate('most_popular'),
                        onPressed: onMostPopular,
                      ),
                      if (onTopRated != null)
                        ShortcutButton(
                          icon: Icons.star_outline,
                          label: l10n.translate('top_rated'),
                          onPressed: onTopRated!,
                        ),
                      ShortcutButton(
                        icon: Icons.casino_outlined,
                        label: l10n.translate('random'),
                        onPressed: onRandom,
                      ),
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

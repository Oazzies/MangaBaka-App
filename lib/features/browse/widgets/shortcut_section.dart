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
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3.0),
                      child: ShortcutButton(
                        icon: Icons.trending_up_rounded,
                        label: l10n.translate('most_popular'),
                        onPressed: onMostPopular,
                      ),
                    ),
                  ),
                  if (onTopRated != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: ShortcutButton(
                          icon: Icons.star_outline,
                          label: l10n.translate('top_rated'),
                          onPressed: onTopRated!,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3.0),
                      child: ShortcutButton(
                        icon: Icons.casino_outlined,
                        label: l10n.translate('random'),
                        onPressed: onRandom,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

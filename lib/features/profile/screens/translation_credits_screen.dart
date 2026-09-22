import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class TranslationCreditsScreen extends StatelessWidget {
  const TranslationCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final languages = l10n.getLanguages();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('translation_credits').toUpperCase(),
          style: AppTypography.display(
            color: context.colors.text,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: WidgetUtils.responsiveConstraint(
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final translators = lang['translators'] as List<String>;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          lang['name'],
                          style: AppTypography.display(
                            color: context.colors.text,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${lang['code']})',
                          style: AppTypography.sans(
                            color: context.colors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.transparent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: translators.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            t,
                            style: AppTypography.sans(
                              color: context.colors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

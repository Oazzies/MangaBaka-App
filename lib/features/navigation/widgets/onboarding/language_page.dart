import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final localizationService = LocalizationService();
        final languages = localizationService.getLanguages();
        final currentLang = localizationService.currentLanguage;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      localizationService
                          .translate('onboarding_language_title')
                          .toUpperCase(),
                      style: AppTypography.display(
                        fontSize: 26,
                        color: context.colors.text,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizationService.translate(
                        'onboarding_language_subtitle',
                      ),
                      style: AppTypography.sans(
                        fontSize: 16,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lang = languages[index];
                  final isSelected = lang['code'] == currentLang;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      onTap: () =>
                          localizationService.setLanguage(lang['code']),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.accent
                              : context.colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.accent
                                : context.colors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang['native_name'] ?? lang['name'],
                                style: AppTypography.sans(
                                  fontSize: 15.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? context.colors.onAccent
                                      : context.colors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: languages.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

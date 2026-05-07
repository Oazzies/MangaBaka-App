import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService()]),
      builder: (context, _) {
        final localizationService = LocalizationService();
        final languages = localizationService.getLanguages();
        final currentLang = localizationService.currentLanguage;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                localizationService.translate('onboarding_language_title'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizationService.translate('onboarding_language_subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textMutedColor,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: languages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final isSelected = lang['code'] == currentLang;

                    return InkWell(
                      onTap: () => localizationService.setLanguage(lang['code']),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppConstants.accentColor.withValues(alpha: 0.1)
                              : AppConstants.secondaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? AppConstants.accentColor 
                                : AppConstants.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang['native_name'] ?? lang['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppConstants.accentColor : AppConstants.textColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppConstants.accentColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

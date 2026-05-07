import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class ContentPreferencesPage extends StatelessWidget {
  final List<String> contentOptions;

  const ContentPreferencesPage({super.key, required this.contentOptions});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final localization = LocalizationService();
        final options = ['safe', 'suggestive', 'erotica', 'pornographic'];
        
        final labels = {
          'safe': localization.translate('safe'),
          'suggestive': localization.translate('suggestive'),
          'erotica': localization.translate('erotica'),
          'pornographic': localization.translate('pornographic'),
        };

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                localization.translate('onboarding_content_title'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localization.translate('onboarding_content_subtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textMutedColor,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: options.map((option) {
                    final currentPrefs = SettingsManager().contentPreferences;
                    final isSelected = currentPrefs.contains(option);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          final newPrefs = List<String>.from(currentPrefs);
                          if (isSelected) {
                            if (newPrefs.length > 1) {
                              newPrefs.remove(option);
                            }
                          } else {
                            newPrefs.add(option);
                          }
                          SettingsManager().setContentPreferences(newPrefs);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                  labels[option]!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppConstants.accentColor : AppConstants.textColor,
                                  ),
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                activeColor: AppConstants.accentColor,
                                onChanged: (val) {
                                  final newPrefs = List<String>.from(currentPrefs);
                                  if (isSelected) {
                                    if (newPrefs.length > 1) {
                                      newPrefs.remove(option);
                                    }
                                  } else {
                                    newPrefs.add(option);
                                  }
                                  SettingsManager().setContentPreferences(newPrefs);
                                },
                              ),
                            ],
                          ),
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
    );
  }
}

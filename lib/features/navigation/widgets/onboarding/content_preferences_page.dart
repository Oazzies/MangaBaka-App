import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/utils/theme/theme_manager.dart';

/// Ordered content-rating options, from least to most explicit.
const _kContentOptions = ['safe', 'suggestive', 'erotica', 'pornographic'];

class ContentPreferencesPage extends StatelessWidget {
  const ContentPreferencesPage({super.key});

  /// Toggles [option] in the user's preferences, enforcing a minimum of one
  /// selection so the content filter is never fully empty.
  void _toggleOption(String option, List<String> currentPrefs) {
    final updated = List<String>.from(currentPrefs);
    if (currentPrefs.contains(option)) {
      if (updated.length > 1) updated.remove(option);
    } else {
      updated.add(option);
    }
    SettingsManager().setContentPreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeManager(), LocalizationService(), SettingsManager()]),
      builder: (context, _) {
        final localization = LocalizationService();
        final labels = {
          'safe': localization.translate('safe'),
          'suggestive': localization.translate('suggestive'),
          'erotica': localization.translate('erotica'),
          'pornographic': localization.translate('pornographic'),
        };

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
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final option = _kContentOptions[index];
                    final currentPrefs = SettingsManager().contentPreferences;
                    final isSelected = currentPrefs.contains(option);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _toggleOption(option, currentPrefs),
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
                                onChanged: (_) => _toggleOption(option, currentPrefs),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _kContentOptions.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

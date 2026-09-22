import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

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
      listenable: Listenable.merge([LocalizationService(), SettingsManager()]),
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
                      localization
                          .translate('onboarding_content_title')
                          .toUpperCase(),
                      style: AppTypography.display(
                        fontSize: 26,
                        color: context.colors.text,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.translate('onboarding_content_subtitle'),
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
                  final option = _kContentOptions[index];
                  final currentPrefs = SettingsManager().contentPreferences;
                  final isSelected = currentPrefs.contains(option);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _toggleOption(option, currentPrefs),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.accent.withValues(alpha: 0.1)
                              : context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.accent
                                : context.colors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                labels[option]!,
                                style: AppTypography.sans(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? context.colors.accent
                                      : context.colors.text,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: context.colors.accent,
                              onChanged: (_) =>
                                  _toggleOption(option, currentPrefs),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: _kContentOptions.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/content_preferences_dialog.dart';

/// Ordered content-rating options, from least to most explicit.
const _kContentOptions = ['safe', 'suggestive', 'erotica', 'pornographic'];

class ContentPreferencesPage extends StatelessWidget {
  const ContentPreferencesPage({super.key});

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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final option = _kContentOptions[index];
                  return ContentRatingRow(
                    option: option,
                    label: labels[option]!,
                    showBottomBorder: index < _kContentOptions.length - 1,
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

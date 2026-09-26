import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_gallery.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_mode_selector.dart';

/// Onboarding step: pick light/dark/system and a theme. Deliberately just the
/// presets — accents and custom themes live in Settings › Appearance.
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final controller = ThemeController();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mode = controller.mode;
        return LayoutBuilder(
          builder: (context, box) {
            // Always a wrapping grid (2-3 columns on a phone) rather than a
            // single horizontally scrolling strip — with a dozen-plus themes
            // a strip hides most of them off-screen.
            const layout = ThemeGalleryLayout.grid;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.translate('onboarding_theme_title').toUpperCase(),
                    style: AppTypography.display(
                      fontSize: 26,
                      color: context.colors.text,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('onboarding_theme_subtitle'),
                    style: AppTypography.sans(
                      fontSize: 16,
                      color: context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const ThemeModeSelector(),
                  const SizedBox(height: 28),
                  if (mode != AppThemeMode.light) ...[
                    _Label(l10n.translate('dark_themes')),
                    ThemeGallery(
                      brightness: Brightness.dark,
                      layout: layout,
                      alignment: WrapAlignment.center,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (mode != AppThemeMode.dark) ...[
                    _Label(l10n.translate('light_themes')),
                    ThemeGallery(
                      brightness: Brightness.light,
                      layout: layout,
                      alignment: WrapAlignment.center,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: AppTypography.monoLabel(
        color: context.colors.textMuted,
        fontSize: 11.5,
      ),
    ),
  );
}

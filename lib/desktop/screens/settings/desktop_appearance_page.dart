import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/appearance/screens/appearance_settings.dart';
import 'package:mangabaka_app/features/appearance/widgets/accent_picker.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_gallery.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_live_preview.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_mode_selector.dart';

/// Appearance settings for the desktop shell: theme grids and controls on the
/// left, a live preview of the active theme on the right.
///
/// Built from the same widgets as the touch page ([ThemeGallery],
/// [AccentPicker], [CustomThemesSection]); only the arrangement and the
/// desktop controls (segmented mode switch, compact buttons) differ.
class DesktopAppearancePage extends StatelessWidget {
  /// Pane width at which the preview moves beside the controls.
  static const double _splitWidth = 900;
  static const double _gap = 24;

  const DesktopAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final controller = ThemeController();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DerivedLayoutBuilder<bool>(
        derive: (box) => box.maxWidth < _splitWidth,
        builder: (context, narrow) {
          final controls = _controls(context, l10n, controller);
          final preview = _preview(context, l10n);
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                preview,
                const SizedBox(height: _gap),
                controls,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 13, child: controls),
              const SizedBox(width: _gap),
              Expanded(flex: 7, child: preview),
            ],
          );
        },
      ),
    );
  }

  Widget _controls(
    BuildContext context,
    LocalizationService l10n,
    ThemeController controller,
  ) {
    final mode = controller.mode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopCard(
          showBorder: false,
          child: DesktopSettingRow(
            icon: mode.icon,
            title: l10n.translate('theme_mode'),
            subtitle: mode == AppThemeMode.system
                ? l10n.translate('theme_mode_system_hint')
                : l10n.translate('appearance_subtitle'),
            control: DesktopSegmented<AppThemeMode>(
              segments: [
                for (final m in AppThemeMode.values) (m, m.label(l10n), m.icon),
              ],
              value: mode,
              onChanged: controller.setMode,
            ),
          ),
        ),
        const SizedBox(height: _gap),
        if (mode != AppThemeMode.light) ...[
          DesktopSectionTitle(title: l10n.translate('dark_themes')),
          const ThemeGallery(
            brightness: Brightness.dark,
            layout: ThemeGalleryLayout.grid,
            cardWidth: 128,
          ),
          const SizedBox(height: 28),
        ],
        if (mode != AppThemeMode.dark) ...[
          DesktopSectionTitle(title: l10n.translate('light_themes')),
          const ThemeGallery(
            brightness: Brightness.light,
            layout: ThemeGalleryLayout.grid,
            cardWidth: 128,
          ),
          const SizedBox(height: 28),
        ],
        DesktopCard(
          showBorder: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('accent_color').toUpperCase(),
                style: AppTypography.display(
                  color: context.colors.text,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.translate('accent_color_subtitle'),
                style: AppTypography.sans(
                  color: context.colors.textMuted,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              const AccentPicker(swatchSize: 34),
            ],
          ),
        ),
        const SizedBox(height: 28),
        DesktopSectionTitle(title: l10n.translate('my_themes')),
        const CustomThemesSection(compactButtons: true),
      ],
    );
  }

  Widget _preview(BuildContext context, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopSectionTitle(
          title: l10n.translate('theme_preview'),
          fontSize: 14,
        ),
        ThemeLivePreview(palette: context.colors),
      ],
    );
  }
}

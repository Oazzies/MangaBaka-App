import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/features/appearance/theme_actions.dart';
import 'package:mangabaka_app/features/appearance/widgets/accent_picker.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_gallery.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_mode_selector.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_components.dart';

class AppearanceSettings extends StatelessWidget {
  static const double gridBreakpoint = 560;

  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final controller = ThemeController();
    return LayoutBuilder(
      builder: (context, box) {
        final grid = box.maxWidth >= gridBreakpoint;
        final layout = grid
            ? ThemeGalleryLayout.grid
            : ThemeGalleryLayout.strip;
        final cardWidth = grid ? 120.0 : 104.0;
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final mode = controller.mode;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsSectionHeader(title: l10n.translate('theme_mode')),
                const ThemeModeSelector(),
                const SizedBox(height: 20),
                if (mode != AppThemeMode.light) ...[
                  SettingsSectionHeader(title: l10n.translate('dark_themes')),
                  ThemeGallery(
                    brightness: Brightness.dark,
                    layout: layout,
                    cardWidth: cardWidth,
                  ),
                  const SizedBox(height: 20),
                ],
                if (mode != AppThemeMode.dark) ...[
                  SettingsSectionHeader(title: l10n.translate('light_themes')),
                  ThemeGallery(
                    brightness: Brightness.light,
                    layout: layout,
                    cardWidth: cardWidth,
                  ),
                  const SizedBox(height: 20),
                ],
                SettingsSectionHeader(title: l10n.translate('accent_color')),
                const AccentPicker(),
                const SizedBox(height: 28),
                SettingsSectionHeader(title: l10n.translate('my_themes')),
                const CustomThemesSection(),
              ],
            );
          },
        );
      },
    );
  }
}

class CustomThemesSection extends StatelessWidget {
  final bool compactButtons;

  const CustomThemesSection({super.key, this.compactButtons = false});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final controller = ThemeController();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final custom = controller.customThemes;
        final c = context.colors;
        final create = MbPrimaryButton(
          label: l10n.translate('theme_create'),
          icon: Icons.add_rounded,
          expand: !compactButtons,
          onPressed: () => ThemeActions.create(context),
        );
        final import = MbSecondaryButton(
          label: l10n.translate('theme_import'),
          icon: Icons.file_download_rounded,
          expand: !compactButtons,
          onPressed: () => ThemeActions.import(context),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (custom.isEmpty)
              _EmptyText(l10n.translate('my_themes_empty'))
            else
              SettingsGroup(
                children: [
                  for (var i = 0; i < custom.length; i++) ...[
                    if (i > 0) const SettingsDivider(),
                    SettingsItem(
                      icon: Icons.palette_outlined,
                      title: custom[i].name,
                      subtitle: l10n.translate(
                        custom[i].brightness == Brightness.dark
                            ? 'theme_mode_dark'
                            : 'theme_mode_light',
                      ),
                      isFirst: i == 0,
                      isLast: i == custom.length - 1,
                      onTap: () => ThemeActions.edit(context, custom[i]),
                      trailing: Builder(
                        builder: (btnContext) => IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: c.textMuted,
                          ),
                          onPressed: () {
                            final box =
                                btnContext.findRenderObject()! as RenderBox;
                            ThemeActions.showCustomMenu(
                              context,
                              custom[i],
                              box.localToGlobal(box.size.center(Offset.zero)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 14),
            if (compactButtons)
              // Wrap, not Row: the Mb buttons' Flexible labels need a bounded width.
              Wrap(spacing: 10, runSpacing: 10, children: [create, import])
            else
              Row(
                children: [
                  Expanded(child: create),
                  const SizedBox(width: 10),
                  Expanded(child: import),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 13,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';

/// Label and icon for each mode, shared by the touch selector here and the
/// desktop segmented control.
extension AppThemeModeLabels on AppThemeMode {
  String label(LocalizationService l10n) => l10n.translate(switch (this) {
    AppThemeMode.system => 'theme_mode_system',
    AppThemeMode.light => 'theme_mode_light',
    AppThemeMode.dark => 'theme_mode_dark',
  });

  IconData get icon => switch (this) {
    AppThemeMode.system => Icons.brightness_auto_rounded,
    AppThemeMode.light => Icons.light_mode_rounded,
    AppThemeMode.dark => Icons.dark_mode_rounded,
  };
}

/// System / Light / Dark as three equal pills — the touch-sized control.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController();
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Row(
        children: [
          for (final m in AppThemeMode.values) ...[
            if (m.index > 0) const SizedBox(width: 8),
            Expanded(
              child: MbPill(
                label: m.label(l10n),
                icon: m.icon,
                selected: controller.mode == m,
                onTap: () => controller.setMode(m),
                expand: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

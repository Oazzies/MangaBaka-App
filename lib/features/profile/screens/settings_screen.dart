import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/desktop/shell/desktop_shell.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_dialog.dart';
import 'package:mangabaka_app/features/profile/screens/settings/settings_root_groups.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Settings, full-screen.
///
/// [show] is the entry point everything else uses: landscape gets
/// [SettingsDialog] instead, which keeps the app visible behind it and holds
/// its own page stack. The rows themselves come from [buildSettingsGroups] so
/// both presentations list the same categories.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    // Desktop has settings as a page in its sidebar, not a pushed screen.
    final desktop = DesktopShell.current;
    if (desktop != null) {
      desktop.openSettings();
      return;
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (isLandscape) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => const SettingsDialog(),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SettingsManager(),
        LocalizationService(),
        getIt<ProfileAuthService>(),
      ]),
      builder: (context, _) {
        final l10n = LocalizationService();
        final auth = getIt<ProfileAuthService>();

        return Scaffold(
          backgroundColor: context.colors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.translate('settings').toUpperCase(),
              style: AppTypography.display(
                color: context.colors.text,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: WidgetUtils.responsiveConstraint(
            ListView(
              padding: EdgeInsets.only(
                left: AppConstants.horizontalPadding,
                right: AppConstants.horizontalPadding,
                top: 8,
                // Clears the bottom navigation bar.
                bottom: 80,
              ),
              children: [
                const _BrandHeader(),
                ...staggered(buildSettingsGroups(context, l10n, auth)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// App icon, name and version.
///
/// A horizontal lockup rather than a centred stack, so the eye starts at the
/// same left edge as every settings row beneath it.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return MbEntrance(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Image.asset(
                'assets/mangabaka512.png',
                width: 44,
                height: 44,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.appName.toUpperCase(),
                  style: AppTypography.display(
                    color: context.colors.text,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${AppConstants.appVersion}',
                  style: AppTypography.sans(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

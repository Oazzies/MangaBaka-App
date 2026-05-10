import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/screens/translation_credits_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

class InformationSettingsGroup extends StatelessWidget {
  final LocalizationService l10n;

  const InformationSettingsGroup({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.discord,
          title: l10n.translate('discord'),
          onTap: () => launchUrl(
            Uri.parse('https://mangabaka.org/discord'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
          isFirst: true,
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.code,
          title: l10n.translate('github'),
          onTap: () => launchUrl(
            Uri.parse('https://github.com/Oazzies/MangaBaka-App'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.info_outline,
          title: l10n.translate('version'),
          subtitle: AppConstants.appVersion,
          onTap: null,
          trailing: const SizedBox.shrink(),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.person_outline,
          title: l10n.translate('developed_by'),
          subtitle: 'Oazzies',
          onTap: () => launchUrl(
            Uri.parse('https://github.com/Oazzies'),
            mode: LaunchMode.externalApplication,
          ),
          trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.translate,
          title: l10n.translate('translation_credits'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TranslationCreditsScreen(),
              ),
            );
          },
        ),
        const SettingsDivider(),
        SettingsItem(
          icon: Icons.open_in_browser_outlined,
          title: l10n.translate('open_links'),
          subtitle: l10n.translate('open_links_subtitle'),
          onTap: () async {
            if (Platform.isAndroid) {
              final intent = AndroidIntent(
                action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
                data: 'package:dev.oazzies.mangabaka_app',
              );
              await intent.launch();
            } else {
              await openAppSettings();
            }
          },
          trailing: Icon(Icons.open_in_new, color: AppConstants.textMutedColor, size: 20),
          isLast: true,
        ),
      ],
    );
  }
}

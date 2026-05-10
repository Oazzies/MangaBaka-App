import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/profile/widgets/settings_components.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';

class ListSettingsGroup extends StatelessWidget {
  final LocalizationService l10n;

  const ListSettingsGroup({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsItem(
          icon: Icons.translate_outlined,
          title: l10n.translate('title_language'),
          subtitle: GeneralSettingsDialogs.getTitleLanguageName(
            SettingsManager().defaultTitleLanguage,
          ),
          onTap: () => GeneralSettingsDialogs.showTitleLanguageSelectionDialog(context),
          isFirst: true,
        ),
        const SettingsDivider(),
        SettingsSwitchItem(
          icon: Icons.call_split_outlined,
          title: l10n.translate('separate_list'),
          subtitle: l10n.translate('separate_list_subtext'),
          value: SettingsManager().separateListStyles,
          onChanged: (value) => SettingsManager().setSeparateListStyles(value),
          isLast: !SettingsManager().separateListStyles,
        ),
        if (SettingsManager().separateListStyles) ...[
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.view_list_outlined,
            title: l10n.translate('library_list_style'),
            subtitle: ListStyleDialogs.getListStyleName(
              SettingsManager().libraryListStyle,
            ),
            onTap: () => ListStyleDialogs.showLibraryListStyleSelectionDialog(context),
          ),
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.grid_view_outlined,
            title: l10n.translate('browse_list_style'),
            subtitle: ListStyleDialogs.getListStyleName(
              SettingsManager().browseListStyle,
            ),
            onTap: () => ListStyleDialogs.showBrowseListStyleSelectionDialog(context),
            isLast: true,
          ),
        ] else ...[
          const SettingsDivider(),
          SettingsItem(
            icon: Icons.view_list_outlined,
            title: l10n.translate('list_style'),
            subtitle: ListStyleDialogs.getListStyleName(
              SettingsManager().currentListStyle,
            ),
            onTap: () => ListStyleDialogs.showListStyleSelectionDialog(context),
            isLast: true,
          ),
        ],
      ],
    );
  }
}

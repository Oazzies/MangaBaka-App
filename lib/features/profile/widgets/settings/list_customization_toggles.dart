import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_scope.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_divider.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_group.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_item.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_switch_item.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The two switches that decide whether Library and Browse are configured
/// together or apart.
class ListSeparationSwitches extends StatelessWidget {
  final ListCustomizationScope scope;
  final LocalizationService l10n;

  /// Called after a switch turns off and nothing is configured separately any
  /// more, so the panel can return to the Library tab — the selector it was
  /// using has just disappeared.
  final VoidCallback onSeparationEnded;

  const ListSeparationSwitches({
    super.key,
    required this.scope,
    required this.l10n,
    required this.onSeparationEnded,
  });

  @override
  Widget build(BuildContext context) {
    final settings = scope.settings;

    return SettingsGroup(
      children: [
        SettingsSwitchItem(
          icon: Icons.splitscreen_outlined,
          title: l10n.translate('separate_list_styles'),
          subtitle: l10n.translate('separate_list_styles_subtitle'),
          value: settings.separateListStyles,
          onChanged: (value) {
            scope.setSeparateStyles(value);
            if (!value && !settings.separateGridColumnCounts) {
              onSeparationEnded();
            }
          },
          isFirst: true,
        ),
        const SettingsDivider(),
        SettingsSwitchItem(
          icon: Icons.grid_on_outlined,
          title: l10n.translate('separate_grid_columns'),
          subtitle: l10n.translate('separate_grid_columns_subtitle'),
          value: settings.separateGridColumnCounts,
          onChanged: (value) {
            scope.setSeparateGridColumns(value);
            if (!value && !settings.separateListStyles) {
              onSeparationEnded();
            }
          },
          isLast: true,
        ),
      ],
    );
  }
}

/// The progress-tracking group. These apply to both lists, so they sit outside
/// [ListCustomizationScope].
class ProgressTrackingSwitches extends StatelessWidget {
  final SettingsManager settings;
  final LocalizationService l10n;

  const ProgressTrackingSwitches({
    super.key,
    required this.settings,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsSwitchItem(
          icon: Icons.analytics_outlined,
          title: l10n.translate('show_library_progress'),
          subtitle: l10n.translate('show_library_progress_subtitle'),
          value: settings.showLibraryProgress,
          onChanged: settings.setShowLibraryProgress,
          isFirst: true,
        ),
        // The progress-type row only applies when progress is shown, so it
        // collapses in and out rather than sitting there inert.
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.showLibraryProgress) ...[
                  const SettingsDivider(),
                  SettingsItem(
                    icon: Icons.menu_book_outlined,
                    title: l10n.translate('library_progress_type'),
                    subtitle: GeneralSettingsDialogs.getLibraryProgressTypeName(
                      settings.libraryProgressType,
                    ),
                    onTap: () =>
                        GeneralSettingsDialogs.showLibraryProgressTypeSelectionDialog(
                          context,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsSwitchItem(
          icon: Icons.hourglass_empty,
          title: l10n.translate('show_remaining_progress'),
          subtitle: l10n.translate('show_remaining_progress_subtitle'),
          value: settings.showRemainingProgress,
          onChanged: settings.setShowRemainingProgress,
        ),
        const SettingsDivider(),
        SettingsSwitchItem(
          icon: Icons.add_circle_outline,
          title: l10n.translate('show_quick_progress'),
          subtitle: l10n.translate('show_quick_progress_subtitle'),
          value: settings.showQuickProgress,
          onChanged: settings.setShowQuickProgress,
          isLast: true,
        ),
      ],
    );
  }
}

/// Copies the active tab's independently-configured settings onto the other
/// list. Only meaningful while at least one of the two is separate.
class CopyToOtherListButton extends StatelessWidget {
  final ListCustomizationScope scope;
  final LocalizationService l10n;

  const CopyToOtherListButton({
    super.key,
    required this.scope,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final toBrowse = scope.tab.isLibrary;

    return OutlinedButton.icon(
      onPressed: () {
        scope.copyToOtherTab();
        AppSnackBar.show(
          context,
          l10n.translate(toBrowse ? 'copied_to_browse' : 'copied_to_library'),
        );
      },
      icon: const Icon(Icons.copy_all_outlined),
      label: Text(
        l10n.translate(toBrowse ? 'copy_to_browse' : 'copy_to_library'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.accent,
        side: BorderSide(color: context.colors.accent.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

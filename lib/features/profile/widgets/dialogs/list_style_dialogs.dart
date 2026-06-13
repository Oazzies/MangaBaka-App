import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_preview_item.dart';

class ListStyleDialogs {
  static String getListStyleName(AppListStyle style) {
    final l10n = LocalizationService();
    switch (style) {
      case AppListStyle.comfortable:
        return l10n.translate('list_style_comfortable');
      case AppListStyle.compact:
        return l10n.translate('list_style_compact');
      case AppListStyle.minimalList:
        return l10n.translate('list_style_minimal_list');
      case AppListStyle.coverOnlyGrid:
        return l10n.translate('list_style_cover_only_grid');
      case AppListStyle.compactGrid:
        return l10n.translate('list_style_compact_grid');
    }
  }

  static void showListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showListStyleSelectionBottomSheet(
      context: context,
      title: l10n.translate('list_style'),
      subtitle: l10n.translate('list_style_subtitle'),
      currentValueGetter: () => SettingsManager().currentListStyle,
      onSelected: (style) => SettingsManager().setListStyle(style),
    );
  }

  static void showLibraryListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showListStyleSelectionBottomSheet(
      context: context,
      title: l10n.translate('library_list_style'),
      subtitle: l10n.translate('library_list_style_subtitle'),
      currentValueGetter: () => SettingsManager().libraryListStyle,
      onSelected: (style) => SettingsManager().setLibraryListStyle(style),
    );
  }

  static void showBrowseListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showListStyleSelectionBottomSheet(
      context: context,
      title: l10n.translate('browse_list_style'),
      subtitle: l10n.translate('browse_list_style_subtitle'),
      currentValueGetter: () => SettingsManager().browseListStyle,
      onSelected: (style) => SettingsManager().setBrowseListStyle(style),
    );
  }

  static void showSimilarListStyleSelectionDialog(BuildContext context) {
    final l10n = LocalizationService();
    _showListStyleSelectionBottomSheet(
      context: context,
      title: l10n.translate('list_style'),
      subtitle: l10n.translate('list_style_subtitle'),
      currentValueGetter: () => SettingsManager().similarListStyle,
      onSelected: (style) => SettingsManager().setSimilarListStyle(style),
    );
  }

  static void _showListStyleSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required AppListStyle Function() currentValueGetter,
    required void Function(AppListStyle) onSelected,
  }) {
    final settingsManager = SettingsManager();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return ListenableBuilder(
          listenable: settingsManager,
          builder: (context, _) {
            final currentValue = currentValueGetter();

            return Container(
              decoration: BoxDecoration(
                color: AppConstants.secondaryBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.largeRadius),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppConstants.borderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppConstants.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: AppConstants.textMutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: AppListStyle.values.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final style = AppListStyle.values[index];
                        final isSelected = currentValue == style;

                        return ListStylePreviewItem(
                          style: style,
                          isSelected: isSelected,
                          label: getListStyleName(style),
                          onTap: () {
                            onSelected(style);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

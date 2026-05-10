import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';


class ContentPreferencesDialogs {
  static String getContentPreferencesText(List<String> prefs) {
    final l10n = LocalizationService();
    if (prefs.isEmpty) return l10n.translate('no_results');
    if (prefs.length == 4) return l10n.translate('all_ratings_hint'); // I might need a key for this
    return prefs.map((s) => l10n.translate(s)).join(', ');
  }
  static void showContentPreferencesDialog(BuildContext context) {
    final l10n = LocalizationService();
    final options = ['safe', 'suggestive', 'erotica', 'pornographic'];
    final labels = {
      'safe': l10n.translate('safe'),
      'suggestive': l10n.translate('suggestive'),
      'erotica': l10n.translate('erotica'),
      'pornographic': l10n.translate('pornographic'),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return ListenableBuilder(
          listenable: SettingsManager(),
          builder: (context, _) {
            final currentPrefs = SettingsManager().contentPreferences;

            return Container(
              decoration: BoxDecoration(
                color: AppConstants.secondaryBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
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
                  Text(
                    l10n.translate('content_preferences'),
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('content_preferences_subtitle'),
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((option) {
                    final isSelected = currentPrefs.contains(option);
                    final label = labels[option]!;

                    return GestureDetector(
                      onTap: () {
                        final newPrefs = List<String>.from(currentPrefs);
                        if (isSelected) {
                          newPrefs.remove(option);
                        } else {
                          newPrefs.add(option);
                        }
                        SettingsManager().setContentPreferences(newPrefs);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppConstants.borderColor.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppConstants.textColor
                                    : AppConstants.textMutedColor,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      key: const ValueKey('checked'),
                                      color: AppConstants.accentColor,
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      key: const ValueKey('unchecked'),
                                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                                      size: 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

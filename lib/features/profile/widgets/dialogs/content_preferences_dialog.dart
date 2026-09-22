import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class ContentPreferencesDialogs {
  static String getContentPreferencesText(List<String> prefs) {
    final l10n = LocalizationService();
    if (prefs.isEmpty) {
      return l10n.translate('no_results');
    }
    if (prefs.length == 4) {
      return l10n.translate('all_ratings_hint');
    }
    return prefs.map((s) => l10n.translate(s)).join(', ');
  }

  /// Toggles [option] in [currentPrefs], enforcing a minimum of one selection.
  static List<String> _toggleOption(String option, List<String> currentPrefs) {
    final updated = List<String>.from(currentPrefs);
    if (currentPrefs.contains(option)) {
      // Always keep at least one rating selected.
      if (updated.length > 1) updated.remove(option);
    } else {
      updated.add(option);
    }
    return updated;
  }

  static void showContentPreferencesDialog(BuildContext context) {
    final l10n = LocalizationService();
    const options = ['safe', 'suggestive', 'erotica', 'pornographic'];
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
                color: context.colors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.largeRadius),
                ),
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
                        color: context.colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.translate('content_preferences').toUpperCase(),
                    style: AppTypography.display(
                      color: context.colors.text,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('content_preferences_subtitle'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.map((option) {
                    final isSelected = currentPrefs.contains(option);
                    final isBlurred = SettingsManager().blurredContentRatings
                        .contains(option);
                    final label = labels[option]!;

                    return Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.colors.surfaceRaised,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                SettingsManager().setContentPreferences(
                                  _toggleOption(option, currentPrefs),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Text(
                                    label,
                                    style: AppTypography.sans(
                                      color: isSelected
                                          ? context.colors.text
                                          : context.colors.textMuted,
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
                                            color: context.colors.accent,
                                            size: 24,
                                          )
                                        : Icon(
                                            Icons.circle_outlined,
                                            key: const ValueKey('unchecked'),
                                            color: context.colors.border
                                                .withValues(alpha: 0.3),
                                            size: 24,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 24,
                              color: context.colors.border,
                            ),
                            const SizedBox(width: 16),
                            WidgetUtils.tooltip(
                              message: l10n.translate('blur_covers'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isBlurred ? Icons.blur_on : Icons.blur_off,
                                    size: 18,
                                    color: isBlurred
                                        ? context.colors.accent
                                        : context.colors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isBlurred,
                                      onChanged: (val) {
                                        final newBlurred = List<String>.from(
                                          SettingsManager()
                                              .blurredContentRatings,
                                        );
                                        if (val) {
                                          newBlurred.add(option);
                                        } else {
                                          newBlurred.remove(option);
                                        }
                                        SettingsManager()
                                            .setBlurredContentRatings(
                                              newBlurred,
                                            );
                                      },
                                      activeThumbColor: context.colors.accent,
                                      activeTrackColor: context.colors.accent
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

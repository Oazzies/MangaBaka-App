import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class SettingsDialogs {
  static String getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  static String getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.defaultTheme: return 'Default';
      case AppTheme.dynamic: return 'Dynamic';
      case AppTheme.catppuccin: return 'Catppuccin';
      case AppTheme.greenApple: return 'Green Apple';
      case AppTheme.lavender: return 'Lavender';
      case AppTheme.midnightDusk: return 'Midnight Dusk';
      case AppTheme.nord: return 'Nord';
      case AppTheme.strawberryDaiquiri: return 'Strawberry Daiquiri';
      case AppTheme.tako: return 'Tako';
      case AppTheme.tealTurquoise: return 'Teal & Turquoise';
      case AppTheme.tidalWave: return 'Tidal Wave';
      case AppTheme.yinYang: return 'Yin & Yang';
      case AppTheme.yotsuba: return 'Yotsuba';
      case AppTheme.monochrome: return 'Monochrome';
    }
  }

  static void showThemeModeSelectionDialog(BuildContext context) {
    final currentMode = ThemeManager().currentThemeMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Theme Mode',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...ThemeMode.values.map((mode) {
                return ListTile(
                  title: Text(
                    getThemeModeName(mode),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: mode == currentMode
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    ThemeManager().setThemeMode(mode);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void showThemeSelectionDialog(BuildContext context) {
    final currentTheme = ThemeManager().currentTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select App Theme',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: AppTheme.values.length,
                    itemBuilder: (context, index) {
                      final theme = AppTheme.values[index];
                      return ListTile(
                        title: Text(
                          getThemeName(theme),
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                        trailing: theme == currentTheme
                            ? Icon(Icons.check, color: AppConstants.accentColor)
                            : null,
                        onTap: () {
                          ThemeManager().setTheme(theme);
                          Navigator.pop(dialogContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String getListStyleName(AppListStyle style) {
    switch (style) {
      case AppListStyle.comfortable:
        return 'Comfortable';
      case AppListStyle.compact:
        return 'Compact';
      case AppListStyle.minimalList:
        return 'Minimal List';
      case AppListStyle.grid:
        return 'Grid';
    }
  }

  static void showListStyleSelectionDialog(BuildContext context) {
    final currentStyle = SettingsManager().currentListStyle;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.tertiaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.cardRadius),
        ),
      ),
      builder: (BuildContext dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select List Style',
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...AppListStyle.values.map((style) {
                return ListTile(
                  title: Text(
                    getListStyleName(style),
                    style: TextStyle(color: AppConstants.textColor),
                  ),
                  trailing: style == currentStyle
                      ? Icon(Icons.check, color: AppConstants.accentColor)
                      : null,
                  onTap: () {
                    SettingsManager().setListStyle(style);
                    Navigator.pop(dialogContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static String getContentPreferencesText(List<String> prefs) {
    if (prefs.isEmpty) return 'None selected';
    if (prefs.length == 4) return 'All ratings';
    return prefs.map((s) => s[0].toUpperCase() + s.substring(1)).join(', ');
  }

  static void showContentPreferencesDialog(BuildContext context) {
    final currentPrefs = List<String>.from(SettingsManager().contentPreferences);
    final options = ['safe', 'suggestive', 'erotica', 'pornographic'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppConstants.secondaryBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              title: Text(
                'Content Preferences',
                style: TextStyle(color: AppConstants.textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  final isSelected = currentPrefs.contains(option);
                  final label = option[0].toUpperCase() + option.substring(1);
                  return CheckboxListTile(
                    title: Text(label, style: TextStyle(color: AppConstants.textColor)),
                    value: isSelected,
                    activeColor: AppConstants.accentColor,
                    checkColor: AppConstants.primaryBackground,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          currentPrefs.add(option);
                        } else {
                          currentPrefs.remove(option);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: AppConstants.textMutedColor)),
                ),
                TextButton(
                  onPressed: () {
                    SettingsManager().setContentPreferences(currentPrefs);
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Save', style: TextStyle(color: AppConstants.accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

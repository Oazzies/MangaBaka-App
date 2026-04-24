import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class ContentPreferencesPage extends StatelessWidget {
  final List<String> contentOptions;

  const ContentPreferencesPage({super.key, required this.contentOptions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 80,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Content Preferences',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What type of content would you like to see?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textMutedColor,
            ),
          ),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: SettingsManager(),
            builder: (context, _) {
              final currentPrefs = SettingsManager().contentPreferences;
              return Column(
                children: contentOptions.map((option) {
                  final isSelected = currentPrefs.contains(option);
                  final label = option[0].toUpperCase() + option.substring(1);
                  return CheckboxListTile(
                    title: Text(label, style: TextStyle(color: AppConstants.textColor)),
                    value: isSelected,
                    activeColor: AppConstants.accentColor,
                    checkColor: AppConstants.primaryBackground,
                    onChanged: (bool? value) {
                      final newPrefs = List<String>.from(currentPrefs);
                      if (value == true) {
                        newPrefs.add(option);
                      } else {
                        newPrefs.remove(option);
                      }
                      SettingsManager().setContentPreferences(newPrefs);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

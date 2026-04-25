import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/settings/settings_manager.dart';

class ContentPreferencesPage extends StatelessWidget {
  final List<String> contentOptions;

  const ContentPreferencesPage({super.key, required this.contentOptions});

  @override
  Widget build(BuildContext context) {
    final options = ['safe', 'suggestive', 'erotica', 'pornographic'];
    final labels = {
      'safe': 'Safe Content',
      'suggestive': 'Suggestive',
      'erotica': 'Erotica',
      'pornographic': 'Pornographic',
    };

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Text(
              'Content Filter',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select what content ratings you want to see. This can be changed later in settings.',
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.textMutedColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            ListenableBuilder(
              listenable: SettingsManager(),
              builder: (context, _) {
                final currentPrefs = SettingsManager().contentPreferences;
                return Column(
                  children: options.map((option) {
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
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppConstants.borderColor.withValues(alpha: 0.1),
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
                                fontSize: 18,
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
                                      size: 28,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      key: const ValueKey('unchecked'),
                                      color: AppConstants.borderColor.withValues(alpha: 0.3),
                                      size: 28,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

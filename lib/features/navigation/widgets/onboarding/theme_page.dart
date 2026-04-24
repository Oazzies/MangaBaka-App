import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/utils/theme/theme_manager.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }

  String _getThemeName(AppTheme theme) {
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

  Color _getThemeAccentColor(AppTheme theme, bool isDark) {
    switch (theme) {
      case AppTheme.defaultTheme:
      case AppTheme.dynamic:
        return isDark ? const Color(0xFF1b9f70) : const Color(0xFF10b981);
      case AppTheme.monochrome:
        return isDark ? const Color(0xFFE5E5E5) : const Color(0xFF171717);
      case AppTheme.catppuccin:
        return isDark ? const Color(0xFFcba6f7) : const Color(0xFF8839ef);
      case AppTheme.greenApple:
        return isDark ? const Color(0xFF84CC16) : const Color(0xFF65A30D);
      case AppTheme.lavender:
        return isDark ? const Color(0xFFB4A1E5) : const Color(0xFF8E75D3);
      case AppTheme.midnightDusk:
        return isDark ? const Color(0xFFF03A47) : const Color(0xFFD81E2B);
      case AppTheme.nord:
        return isDark ? const Color(0xFF88C0D0) : const Color(0xFF5E81AC);
      case AppTheme.strawberryDaiquiri:
        return isDark ? const Color(0xFFE0315B) : const Color(0xFFC92A52);
      case AppTheme.tako:
        return isDark ? const Color(0xFFF3B61F) : const Color(0xFFD49A00);
      case AppTheme.tealTurquoise:
        return isDark ? const Color(0xFF20C997) : const Color(0xFF0CA678);
      case AppTheme.tidalWave:
        return isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0284C7);
      case AppTheme.yinYang:
        return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
      case AppTheme.yotsuba:
        return isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.color_lens_rounded,
            size: 64,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Choose Your Style',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Personalize your experience. You can always change this later in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppConstants.textMutedColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ListenableBuilder(
            listenable: ThemeManager(),
            builder: (context, _) {
              final currentMode = ThemeManager().currentThemeMode;
              final currentTheme = ThemeManager().currentTheme;
              
              bool isActuallyDark = false;
              if (currentMode == ThemeMode.system) {
                isActuallyDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
              } else {
                isActuallyDark = currentMode == ThemeMode.dark;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MODE',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ThemeMode.values.map((mode) {
                      final isSelected = mode == currentMode;
                      IconData modeIcon;
                      if (mode == ThemeMode.light) modeIcon = Icons.wb_sunny_rounded;
                      else if (mode == ThemeMode.dark) modeIcon = Icons.nightlight_round;
                      else modeIcon = Icons.brightness_auto_rounded;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () => ThemeManager().setThemeMode(mode),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: AppConstants.shortAnimationDuration,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppConstants.accentColor.withValues(alpha: 0.15) : AppConstants.secondaryBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppConstants.accentColor : AppConstants.borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    modeIcon,
                                    color: isSelected ? AppConstants.accentColor : AppConstants.textMutedColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getThemeModeName(mode),
                                    style: TextStyle(
                                      color: isSelected ? AppConstants.accentColor : AppConstants.textColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'COLOR THEME',
                    style: TextStyle(
                      color: AppConstants.textMutedColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppTheme.values.map((theme) {
                      final isSelected = theme == currentTheme;
                      final accent = _getThemeAccentColor(theme, isActuallyDark);

                      return InkWell(
                        onTap: () => ThemeManager().setTheme(theme),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: AppConstants.shortAnimationDuration,
                          width: (MediaQuery.of(context).size.width - 48 - 12) / 2, // 2 columns
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withValues(alpha: 0.1) : AppConstants.secondaryBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? accent : AppConstants.borderColor.withValues(alpha: 0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  border: isSelected && (theme == AppTheme.yinYang || theme == AppTheme.monochrome)
                                    ? Border.all(color: AppConstants.borderColor, width: 1)
                                    : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getThemeName(theme),
                                  style: TextStyle(
                                    color: isSelected ? AppConstants.textColor : AppConstants.textMutedColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

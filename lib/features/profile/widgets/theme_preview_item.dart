import 'package:flutter/material.dart';
import 'package:bakahyou/utils/theme/app_theme_colors.dart';

class ThemePreviewItem extends StatelessWidget {
  final AppTheme theme;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;
  final double scale;

  const ThemePreviewItem({
    super.key,
    required this.theme,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
    required this.label,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.getPalette(theme, isDark);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100 * scale,
              height: 160 * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Container(
                  width: 100,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: palette.primaryBackground,
                          child: Column(
                            children: [
                              // Mock App Bar
                              Container(
                                height: 24,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                color: palette.secondaryBackground,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: palette.text.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: palette.accent,
                                      ),
                                  ],
                                ),
                              ),
                              // Mock Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: palette.tertiaryBackground,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: palette.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                width: 20,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: palette.text.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 50,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: palette.text.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 30,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: palette.text.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Mock Bottom Bar
                              Container(
                                height: 20,
                                color: palette.secondaryBackground,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    3,
                                    (index) => Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: index == 0 ? palette.accent : palette.text.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? palette.accent : palette.border.withValues(alpha: 0.5),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? palette.text : palette.text.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

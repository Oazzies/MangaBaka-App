import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class SeriesSegmentedControl extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  const SeriesSegmentedControl({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'value': 'Information', 'icon': Icons.info_outline},
      {'value': 'Covers', 'icon': Icons.image_outlined},
      {'value': 'Related', 'icon': Icons.auto_stories_outlined},
      {'value': 'News', 'icon': Icons.newspaper_outlined},
      {'value': 'Collections', 'icon': Icons.collections_bookmark_outlined},
      {'value': 'Works', 'icon': Icons.work_outline},
    ];

    final selectedIndex = tabs.indexWhere((t) => t['value'] == selectedTab);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppConstants.tertiaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          return Stack(
            children: [
              // Sliding background pill (Flat M3 style)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                left: selectedIndex * tabWidth + 4,
                top: 4,
                width: tabWidth - 8,
                height: constraints.maxHeight - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Tab Icons
              Row(
                children: tabs.asMap().entries.map((entry) {
                  final tab = entry.value;
                  final isSelected = selectedTab == tab['value'];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (selectedTab != tab['value']) {
                          onTabChanged(tab['value'] as String);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.15 : 1.0,
                          child: Icon(
                            tab['icon'] as IconData,
                            color: isSelected ? AppConstants.primaryBackground : AppConstants.textMutedColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

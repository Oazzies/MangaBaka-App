import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';

class SeriesSegmentedControl extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final double horizontalPadding;

  const SeriesSegmentedControl({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.horizontalPadding = 16.0,
  });

  static const _tabs = [
    'Info',
    'Covers',
    'Related',
    'News',
    'Collections',
    'Works',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Left padding aligns the first tab's text with badges; right adds end breathing room.
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: Row(
          children: _tabs.map((label) {
            final isSelected = selectedTab == label;
            return _TabItem(
              label: label,
              isSelected: isSelected,
              onTap: () {
                if (!isSelected) onTabChanged(label);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // No left padding — the scroll view's left padding handles the first item.
        // Right padding creates the visual gap between tabs.
        padding: const EdgeInsets.only(right: 24),
        child: IntrinsicWidth(
          child: SizedBox(
            height: 44,
            child: Stack(
              children: [
                Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected
                          ? AppConstants.accentColor
                          : AppConstants.textMutedColor,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    child: Text(label),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.accentColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

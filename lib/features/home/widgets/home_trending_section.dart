import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The Trending block on Home: the "Rising the fastest" rail plus the content
/// -type and time-window controls the web `/discover` page carries.
class HomeTrendingSection extends StatelessWidget {
  final List<Series> series;
  final bool loading;

  /// API `type` value, or null for every type.
  final String? selectedType;

  /// Trending window in days — 7 or 30.
  final int window;

  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int> onWindowChanged;
  final VoidCallback? onViewAll;

  const HomeTrendingSection({
    super.key,
    required this.series,
    required this.loading,
    required this.selectedType,
    required this.window,
    required this.onTypeChanged,
    required this.onWindowChanged,
    this.onViewAll,
  });

  /// (API value, l10n key) — null value is the "all types" chip.
  static const List<(String?, String)> _types = [
    (null, 'any'),
    ('manga', 'type_manga'),
    ('manhwa', 'type_manhwa'),
    ('manhua', 'type_manhua'),
    ('novel', 'type_novel'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbSectionHeader(title: l10n.translate('trending'), onAction: onViewAll),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            children: [
              for (final (value, key) in _types) ...[
                _Pill(
                  label: l10n.translate(key),
                  selected: selectedType == value,
                  onTap: () => onTypeChanged(value),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.fromLTRB(2, 8, 10, 8),
                color: context.colors.border,
              ),
              _Pill(
                label: '7d',
                selected: window == 7,
                onTap: () => onWindowChanged(7),
              ),
              const SizedBox(width: 8),
              _Pill(
                label: '30d',
                selected: window == 30,
                onTap: () => onWindowChanged(30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HomeRail(
          title: '',
          showHeader: false,
          series: series,
          loading: loading,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? context.colors.accent : context.colors.surface,
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
        ),
        child: Text(
          label,
          style: AppTypography.sans(
            color: selected
                ? context.colors.onAccent
                : context.colors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

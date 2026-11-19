import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/features/home/widgets/home_rail.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

class HomeTrendingSection extends StatelessWidget {
  final List<Series> series;
  final bool loading;

  final String? selectedType;

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

  static const List<({String? value, String labelKey})> _types = [
    (value: null, labelKey: 'any'),
    (value: 'manga', labelKey: 'type_manga'),
    (value: 'manhwa', labelKey: 'type_manhwa'),
    (value: 'manhua', labelKey: 'type_manhua'),
    (value: 'novel', labelKey: 'type_novel'),
  ];

  static const List<int> _windows = [7, 30];

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
              for (final type in _types) ...[
                _Pill(
                  label: l10n.translate(type.labelKey),
                  selected: selectedType == type.value,
                  onTap: () => onTypeChanged(type.value),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.fromLTRB(2, 8, 10, 8),
                color: context.colors.border,
              ),
              for (final days in _windows) ...[
                if (days != _windows.first) const SizedBox(width: 8),
                _Pill(
                  label: l10n
                      .translate('trending_window_days')
                      .replaceAll('{days}', '$days'),
                  selected: window == days,
                  onTap: () => onWindowChanged(days),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
            vertical: 5,
          ),
          child: SizedBox(
            height: 2,
            child: loading && series.isNotEmpty
                ? LinearProgressIndicator(
                    minHeight: 2,
                    color: context.colors.accent,
                    backgroundColor: Colors.transparent,
                  )
                : null,
          ),
        ),
        if (!loading && series.isEmpty)
          _EmptyRail(message: l10n.translate('no_results'))
        else
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

class _EmptyRail extends StatelessWidget {
  final String message;

  const _EmptyRail({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        height: HomeRail.heightFor(HomeRail.defaultCoverWidth),
        child: Center(
          child: Text(
            message,
            style: AppTypography.sans(
              color: context.colors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ),
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

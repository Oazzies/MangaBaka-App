import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Single key/value metadata row in [SeriesInformationCard].
class SeriesInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool isSelected;

  const SeriesInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? context.colors.accent
        : (valueColor ?? context.colors.text);
    final textWeight = isSelected ? FontWeight.bold : FontWeight.w500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.monoLabel(
                color: context.colors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.sans(
                color: textColor,
                fontSize: 14,
                fontWeight: textWeight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comma-separated tappable items row in [SeriesInformationCard].
class SeriesInfoLinkedRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Function(String)? onTap;
  final bool Function(String)? isSelected;

  const SeriesInfoLinkedRow({
    super.key,
    required this.label,
    required this.items,
    this.onTap,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            runSpacing: 2,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                GestureDetector(
                  onTap: onTap != null ? () => onTap!(items[i]) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Builder(
                    builder: (context) {
                      final selected = isSelected?.call(items[i]) ?? false;
                      return Text(
                        items[i],
                        style: AppTypography.sans(
                          color: selected
                              ? context.colors.accent
                              : context.colors.text,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
                if (i < items.length - 1)
                  Text(
                    ', ',
                    style: AppTypography.sans(
                      color: context.colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Publishers as one tappable block each — the name, with the edition's
/// language and role (e.g. "EN · English") beneath it so regional editions of
/// the same series can be told apart.
class SeriesInfoPublisherRefsRow extends StatelessWidget {
  final String label;
  final List<SeriesPublisher> publishers;
  final void Function(SeriesPublisher) onTap;
  final bool Function(String) isSelected;

  const SeriesInfoPublisherRefsRow({
    super.key,
    required this.label,
    required this.publishers,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel(
              color: context.colors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          for (final p in publishers)
            GestureDetector(
              onTap: () => onTap(p),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.sans(
                        color: isSelected(p.name)
                            ? context.colors.accent
                            : context.colors.text,
                        fontSize: 14,
                        fontWeight: isSelected(p.name)
                            ? FontWeight.bold
                            : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    if (_detail(p) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          _detail(p)!,
                          style: AppTypography.monoLabel(
                            color: context.colors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String? _detail(SeriesPublisher p) {
    final parts = [
      if (p.language != null) p.language!.toUpperCase(),
      if (p.role != null) p.role!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

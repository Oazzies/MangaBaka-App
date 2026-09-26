import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_section_header.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The "DNA" readout: which traits the recommendations were actually drawn
/// from, weighted.
///
/// The top few get a labelled bar; the rest are listed as plain chips, because
/// past the leading traits the exact weight stops being informative and the
/// bars just add visual noise.
class MixDnaSection extends StatelessWidget {
  /// Weight-descending. [MixService] sorts on the way in, so this widget does
  /// no sorting of its own — it used to copy and re-sort the whole list on
  /// every rebuild, which a settings change or a keystroke was enough to
  /// trigger.
  final List<MixDnaTag> dna;
  final LocalizationService l10n;

  /// How many traits get a weighted bar before the rest become chips.
  static const int _barCount = 5;

  /// Cap on the chip tail — a long DNA list would otherwise push the results
  /// off the first screen.
  static const int _chipCount = 10;

  const MixDnaSection({super.key, required this.dna, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (dna.isEmpty) return const SizedBox.shrink();

    // Bars are drawn relative to the strongest trait, so the leading bar is
    // always full and the rest read as a share of it.
    final maxWeight = dna.first.weight;
    final tail = dna.skip(_barCount).take(_chipCount).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MixSectionHeader(
            icon: Icons.biotech_rounded,
            title: l10n.translate('mix_dna'),
            trailing: l10n.translate('mix_dna_subtitle'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tag in dna.take(_barCount))
                  _DnaBar(
                    tag: tag,
                    fraction: maxWeight > 0 ? tag.weight / maxWeight : 0.0,
                  ),
                if (tail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.colors.border,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('mix_dna_additional'),
                    style: AppTypography.sans(
                      color: context.colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in tail) _DnaChip(name: tag.name),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DnaBar extends StatelessWidget {
  final MixDnaTag tag;

  /// This trait's weight as a share of the strongest one, 0–1.
  final double fraction;

  const _DnaBar({required this.tag, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag.name,
                style: AppTypography.sans(
                  color: context.colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: AppTypography.sans(
                  color: context.colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: context.colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                // Floor of 2% so a very weak trait is still a visible sliver
                // rather than an empty track.
                widthFactor: fraction.clamp(0.02, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DnaChip extends StatelessWidget {
  final String name;

  const _DnaChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: AppTypography.sans(
          color: context.colors.text.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

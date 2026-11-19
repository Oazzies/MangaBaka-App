import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_section_header.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_chip.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_search_field.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_suggestions.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

class MixSeedSection extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;

  final TextEditingController searchController;
  final FocusNode searchFocus;

  /// Owned by the screen: they follow the field's focus lifecycle.
  final List<AutocompleteSeriesResult> suggestions;
  final bool showSuggestions;

  final ValueChanged<Series> onSeedTap;
  final ValueChanged<Series> onSeedRemove;
  final ValueChanged<AutocompleteSeriesResult> onSuggestionSelected;
  final ValueChanged<AutocompleteSeriesResult> onSuggestedSeedAdded;
  final VoidCallback onClearSearch;

  const MixSeedSection({
    super.key,
    required this.controller,
    required this.l10n,
    required this.searchController,
    required this.searchFocus,
    required this.suggestions,
    required this.showSuggestions,
    required this.onSeedTap,
    required this.onSeedRemove,
    required this.onSuggestionSelected,
    required this.onSuggestedSeedAdded,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MixSectionHeader(
              icon: Icons.grass_rounded,
              title: l10n.translate('mix_seeds'),
            ),
          ),
          if (controller.seeds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final seed in controller.seeds)
                      MixSeedChip(
                        key: ValueKey('mix_seed_${seed.id}'),
                        seed: seed,
                        onTap: () => onSeedTap(seed),
                        onRemove: () => onSeedRemove(seed),
                      ),
                  ],
                ),
              ),
            ),
          MixSeedSearchField(
            controller: searchController,
            focusNode: searchFocus,
            hintText: l10n.translate('mix_add_seed'),
            suggestions: suggestions,
            showSuggestions: showSuggestions,
            onSuggestionSelected: onSuggestionSelected,
            onClear: onClearSearch,
          ),
          // The API can only suggest further seeds once two are chosen.
          if (controller.seeds.length >= 2) ...[
            const SizedBox(height: 12),
            MixSeedSuggestions(
              controller: controller,
              l10n: l10n,
              onSeedAdded: onSuggestedSeedAdded,
            ),
          ],
        ],
      ),
    );
  }
}

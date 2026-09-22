import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/browse/controllers/mix_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_section_header.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_chip.dart';
import 'package:mangabaka_app/features/browse/widgets/mix/mix_seed_suggestions.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_suggestions_panel.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The seed picker: current seeds, the search field that adds more, and the
/// two kinds of suggestion below it (typed autocomplete, and the API's own
/// "you might also seed with…" row once there are two seeds to work from).
class MixSeedSection extends StatelessWidget {
  final MixController controller;
  final LocalizationService l10n;

  final TextEditingController searchController;
  final FocusNode searchFocus;

  /// Typed-autocomplete results and whether the panel is currently open. Owned
  /// by the screen because they are tied to the field's focus lifecycle.
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
          _SeedSearchField(
            controller: searchController,
            focusNode: searchFocus,
            hintText: l10n.translate('mix_add_seed'),
            onClear: onClearSearch,
          ),
          if (showSuggestions && suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            SearchSuggestionsPanel(
              results: suggestions,
              onResultTapped: onSuggestionSelected,
              showSuggestions: true,
            ),
          ],
          // The API only has enough signal to suggest further seeds once two
          // are already chosen.
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

class _SeedSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback onClear;

  const _SeedSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onClear,
  });

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppConstants.pillRadius),
    borderSide: BorderSide.none,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: AppTypography.sans(color: context.colors.text, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.search, color: context.colors.text, size: 22),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close,
                  color: context.colors.textMuted,
                  size: 18,
                ),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: context.colors.surfaceRaised,
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/search/ghost_text_editing_controller.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_bar_controller.dart';
import 'package:mangabaka_app/features/browse/widgets/search/mb_search_bar_suffix.dart';

class SearchBarTextField extends StatelessWidget {
  final GhostTextEditingController textController;
  final FocusNode focusNode;
  final SearchBarController controller;
  final SearchFilters filters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback? onBackTap;
  final VoidCallback? onScanTap;
  final VoidCallback? onFilterTap;

  const SearchBarTextField({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.controller,
    required this.filters,
    required this.onSubmitted,
    required this.onChanged,
    required this.onBackTap,
    required this.onScanTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    // Kerning is disabled so the ghost span lines up exactly with the typed
    // text; with it on, the completion visibly shifts as it is accepted.
    const features = [FontFeature.disable('kern')];
    final baseStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: context.colors.text,
          fontSize: 16,
          letterSpacing: 0,
          fontFeatures: features,
        ) ??
        TextStyle(
          color: context.colors.text,
          fontSize: 16,
          letterSpacing: 0,
          fontFeatures: features,
        );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: textController,
      focusNode: focusNode,
      style: baseStyle,
      textInputAction: TextInputAction.search,
      onChanged: controller.onTextChanged,
      onSubmitted: (text) {
        if (controller.resolveSubmission() != null) return;
        (onSubmitted ?? onChanged)(text);
      },
      decoration: InputDecoration(
        hintText: l10n.translate('search_hint'),
        hintStyle: AppTypography.sans(
          color: context.colors.textMuted,
          fontSize: 16,
        ),
        prefixIcon: onBackTap == null
            ? Icon(Icons.search, color: context.colors.text)
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: context.colors.text,
                ),
                onPressed: () {
                  controller.clear();
                  onBackTap!();
                },
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: MBSearchBarSuffix(
          controllerText: textController.text,
          onClear: controller.clear,
          onScanTap: onScanTap,
          onFilterTap: onFilterTap,
          currentFilters: filters,
        ),
        filled: true,
        fillColor: context.colors.surfaceRaised,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.pillRadius),
          borderSide: BorderSide(color: context.colors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),
      ),
    );
  }
}

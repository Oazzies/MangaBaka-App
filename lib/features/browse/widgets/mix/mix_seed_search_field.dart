import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/browse/widgets/search/search_suggestions_panel.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';

class MixSeedSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final List<AutocompleteSeriesResult> suggestions;
  final bool showSuggestions;
  final ValueChanged<AutocompleteSeriesResult> onSuggestionSelected;
  final VoidCallback onClear;

  const MixSeedSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.suggestions,
    required this.showSuggestions,
    required this.onSuggestionSelected,
    required this.onClear,
  });

  @override
  State<MixSeedSearchField> createState() => _MixSeedSearchFieldState();
}

class _MixSeedSearchFieldState extends State<MixSeedSearchField> {
  static const double _panelGap = 6;
  static const double _keyboardMargin = 8;

  // show() asserts outside build, so the portal stays shown and its builder decides visibility.
  final OverlayPortalController _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: _buildPanel,
      child: _SeedTextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        hintText: widget.hintText,
        onClear: widget.onClear,
      ),
    );
  }

  Widget _buildPanel(BuildContext context, OverlayChildLayoutInfo info) {
    if (!widget.showSuggestions || widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final top = anchor.bottom + _panelGap;
    // The Scaffold strips the keyboard inset from its body's MediaQuery, so read the view.
    final view = View.of(context);
    final keyboard = view.viewInsets.bottom / view.devicePixelRatio;
    final maxHeight = math.max(
      0.0,
      info.overlaySize.height - keyboard - top - _keyboardMargin,
    );

    return Stack(
      children: [
        Positioned(
          left: anchor.left,
          top: top,
          width: anchor.width,
          child: TextFieldTapRegion(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Material(
                type: MaterialType.transparency,
                child: SingleChildScrollView(
                  child: SearchSuggestionsPanel(
                    results: widget.suggestions,
                    onResultTapped: widget.onSuggestionSelected,
                    showSuggestions: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeedTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback onClear;

  const _SeedTextField({
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
                  Icons.close_rounded,
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

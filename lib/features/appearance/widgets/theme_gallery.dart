import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/theme_controller.dart';
import 'package:mangabaka_app/features/appearance/theme_actions.dart';
import 'package:mangabaka_app/features/appearance/widgets/theme_preview_card.dart';

/// How a [ThemeGallery] lays its cards out.
enum ThemeGalleryLayout {
  /// One horizontally scrolling row — phones, where vertical space is the
  /// scarce thing.
  strip,

  /// Wrapping grid — tablets, landscape dialogs and desktop.
  grid,
}

/// Every theme available for one brightness slot, as preview cards.
///
/// Tapping a card selects it for that slot and, unless the app follows the
/// system, switches the pinned mode to match — picking a light theme while in
/// dark mode should visibly do something. Custom themes get a menu (long
/// press / right click) for edit, duplicate, share and delete.
class ThemeGallery extends StatefulWidget {
  final Brightness brightness;
  final ThemeGalleryLayout layout;
  final double cardWidth;

  const ThemeGallery({
    super.key,
    required this.brightness,
    this.layout = ThemeGalleryLayout.strip,
    this.cardWidth = 112,
  });

  @override
  State<ThemeGallery> createState() => _ThemeGalleryState();
}

class _ThemeGalleryState extends State<ThemeGallery> {
  static const double _gap = 12;
  final ScrollController _scroll = ScrollController();

  ThemeController get _controller => ThemeController();

  String get _selectedId => widget.brightness == Brightness.dark
      ? _controller.darkThemeId
      : _controller.lightThemeId;

  @override
  void initState() {
    super.initState();
    if (widget.layout == ThemeGalleryLayout.strip) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centreSelected(animated: false),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the selected card to the middle of the strip, so the current
  /// choice is visible rather than scrolled off to one side.
  void _centreSelected({bool animated = true}) {
    if (!mounted || !_scroll.hasClients) return;
    final choices = _controller.choicesFor(widget.brightness);
    final index = choices.indexWhere((c) => c.id == _selectedId);
    if (index < 0) return;
    final viewport = _scroll.position.viewportDimension;
    final target =
        (index * (widget.cardWidth + _gap) -
                viewport / 2 +
                widget.cardWidth / 2)
            .clamp(0.0, _scroll.position.maxScrollExtent);
    if (animated) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final choices = _controller.choicesFor(widget.brightness);
        final selectedId = _selectedId;
        final cards = [
          for (final choice in choices)
            ThemePreviewCard(
              key: ValueKey(choice.id),
              palette: choice.palette,
              label: choice.customName ?? l10n.translate(choice.nameKey!),
              selected: choice.id == selectedId,
              width: widget.cardWidth,
              badge: choice.isCustom ? Icons.edit_rounded : null,
              onTap: () {
                _controller.apply(choice.id, widget.brightness);
                if (widget.layout == ThemeGalleryLayout.strip) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _centreSelected(),
                  );
                }
              },
              onMenu: choice.isCustom
                  ? (pos) => ThemeActions.showCustomMenu(
                      context,
                      _controller.customById(choice.id)!,
                      pos,
                    )
                  : null,
            ),
        ];

        if (widget.layout == ThemeGalleryLayout.grid) {
          return Wrap(spacing: _gap, runSpacing: 16, children: cards);
        }

        return SizedBox(
          // Card, gap, one line of label.
          height: widget.cardWidth * ThemePreviewCard.aspect + 30,
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (_, i) => cards[i],
            ),
          ),
        );
      },
    );
  }
}

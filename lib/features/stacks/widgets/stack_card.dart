import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/motion/app_motion.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';
import 'package:mangabaka_app/features/stacks/models/stack_summary.dart';
import 'package:mangabaka_app/features/stacks/screens/stack_detail_screen.dart';
import 'package:mangabaka_app/features/stacks/utils/stack_format.dart';
import 'package:mangabaka_app/features/stacks/widgets/stack_cover_fan.dart';

/// A stack in a grid or rail: its fanned covers, title, author and counts.
///
/// Fills its parent's width. [showVisibility] adds the owner's view of the
/// stack (draft / unlisted) for the user's own stacks.
class StackCard extends StatefulWidget {
  final StackSummary stack;
  final VoidCallback? onTap;
  final bool showVisibility;

  const StackCard({
    super.key,
    required this.stack,
    this.onTap,
    this.showVisibility = false,
  });

  /// Space under the fan taken by the text, at the current text scale.
  static double textHeight(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) * 64 + 10;

  /// The card's full height at [width].
  static double heightFor(BuildContext context, double width) =>
      StackCoverFan.heightFor(width) + textHeight(context);

  @override
  State<StackCard> createState() => _StackCardState();
}

class _StackCardState extends State<StackCard> {
  /// How far the covers grow while hovered.
  static const double _hoverScale = 1.03;

  bool _hovered = false;

  // The grown covers are drawn in the app's overlay, following the card, so
  // they sit over neighbours, headers and clipped rails instead of being cut
  // off behind them. The in-place covers are hidden while the copy shows.
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _fanKey = GlobalKey();
  Size _fanSize = Size.zero;
  bool _lifted = false;

  StackSummary get stack => widget.stack;

  void _enter() {
    final box = _fanKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) _fanSize = box.size;
    setState(() {
      _hovered = true;
      _lifted = _fanSize != Size.zero;
    });
    if (_lifted) _portal.show();
  }

  void _exit() => setState(() => _hovered = false);

  Widget _covers() => Stack(
    children: [
      StackCoverFan(covers: stack.covers, contentRating: stack.contentRating),
      Positioned(
        left: 6,
        top: 6,
        child: _Badges(stack: stack, showVisibility: widget.showVisibility),
      ),
    ],
  );

  Widget _overlayCovers(BuildContext context) {
    return CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _hovered ? _hoverScale : 1),
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            onEnd: () {
              if (!_hovered && mounted) {
                _portal.hide();
                setState(() => _lifted = false);
              }
            },
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: SizedBox(
              width: _fanSize.width,
              height: _fanSize.height,
              child: _covers(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final meta = [
      if (stack.owner.display.isNotEmpty)
        l10n.translate('stacks_by').replaceAll('{name}', stack.owner.display),
      stackCount('entries', stack.entryCount, l10n),
      stackCount('votes', stack.voteCount, l10n),
    ].join(' · ');

    return Semantics(
      button: true,
      label: stack.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _enter(),
        onExit: (_) => _exit(),
        child: MbTappable(
          pressedScale: 0.97,
          onTap:
              widget.onTap ??
              () => StackDetailScreen.open(
                context,
                id: stack.id,
                initial: stack,
                asOwner: widget.showVisibility,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              OverlayPortal(
                controller: _portal,
                overlayChildBuilder: _overlayCovers,
                child: CompositedTransformTarget(
                  link: _link,
                  child: Opacity(
                    key: _fanKey,
                    opacity: _lifted ? 0 : 1,
                    child: _covers(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: AppTypography.sans(
                  color: _hovered ? c.accent : c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                child: Text(stack.title),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sans(color: c.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The little flags over the covers: staff pick, official, spoilers, and the
/// owner's visibility.
class _Badges extends StatelessWidget {
  final StackSummary stack;
  final bool showVisibility;

  const _Badges({required this.stack, required this.showVisibility});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final c = context.colors;
    final badges = <(IconData, String, Color)>[
      if (stack.isFeatured)
        (Icons.star_rounded, l10n.translate('stacks_badge_featured'), c.star),
      if (stack.kind == StackKind.official)
        (
          Icons.verified_rounded,
          l10n.translate('stacks_badge_official'),
          c.accent,
        ),
      if (stack.isSpoiler)
        (
          Icons.visibility_off_rounded,
          l10n.translate('stacks_badge_spoiler'),
          c.warning,
        ),
      if (showVisibility && stack.visibility != StackVisibility.public)
        (
          stack.visibility == StackVisibility.draft
              ? Icons.edit_note_rounded
              : Icons.link_rounded,
          l10n.translate(stack.visibility.labelKey),
          c.info,
        ),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final (icon, label, color) in badges)
          StackBadge(icon: icon, label: label, color: color),
      ],
    );
  }
}

/// One small pill-shaped flag: an icon and a label on a dark well.
class StackBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StackBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.sans(
              color: c.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

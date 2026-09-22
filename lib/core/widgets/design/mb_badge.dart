import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// Small uppercase badge — the reference's amber "TOP" tag.
///
/// [MbBadge.accent] is the loud amber-on-ink variant; the default constructor
/// is the quiet dark-well variant used for neutral metadata (type, status).
class MbBadge extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;
  final bool _accent;

  const MbBadge({
    super.key,
    required this.label,
    this.background,
    this.foreground,
  }) : _accent = false;

  const MbBadge.accent({super.key, required this.label})
    : background = null,
      foreground = null,
      _accent = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = background ?? (_accent ? c.accent : c.surfaceRaised);
    final fg = foreground ?? (_accent ? c.onAccent : c.text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.display(color: fg, fontSize: 10),
      ),
    );
  }
}

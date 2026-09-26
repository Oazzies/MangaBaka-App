import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// A realistic slice of the app — a series card, actions, pills, a toggle and
/// a progress bar — painted in [palette].
///
/// Built from plain containers rather than the real widgets on purpose: the
/// real ones read `context.colors`, i.e. the *active* theme, and this has to
/// show a theme that is not active yet (the editor's draft).
class ThemeLivePreview extends StatelessWidget {
  final MbPalette palette;

  const ThemeLivePreview({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final l10n = LocalizationService();
    TextStyle sans(Color c, double size, [FontWeight w = FontWeight.w400]) =>
        AppTypography.sans(color: c, fontSize: size, fontWeight: w);

    Widget pill(String text, bool on) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: on ? p.accent : p.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.pillRadius),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.display(
          color: on ? p.onAccent : p.text,
          fontSize: 11,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.translate('library').toUpperCase(),
            style: AppTypography.display(color: p.text, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              pill(l10n.translate('reading'), true),
              pill(l10n.translate('completed'), false),
              pill(l10n.translate('paused'), false),
            ],
          ),
          const SizedBox(height: 14),
          // Series card.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppConstants.denseRadius),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 74,
                  decoration: BoxDecoration(
                    color: p.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: p.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('theme_preview_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(p.text, 15, FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.translate('theme_preview_subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(p.textMuted, 12.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < 5; i++)
                            Icon(
                              i < 4
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: i < 4 ? p.star : p.textMuted,
                            ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: 0.62,
                          minHeight: 5,
                          color: p.accent,
                          backgroundColor: p.surfaceRaised,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(
                      AppConstants.pillRadius,
                    ),
                  ),
                  child: Text(
                    l10n.translate('theme_preview_primary').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(color: p.onAccent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppConstants.pillRadius,
                    ),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    l10n.translate('theme_preview_secondary').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(color: p.text, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final t in [p.success, p.warning, p.error, p.info]) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: t, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              _FakeSwitch(palette: p),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeSwitch extends StatelessWidget {
  final MbPalette palette;
  const _FakeSwitch({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(3),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: palette.onAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

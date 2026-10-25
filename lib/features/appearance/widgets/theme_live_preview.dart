import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_theme.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/widgets/design/mb_button.dart';
import 'package:mangabaka_app/core/widgets/design/mb_pill.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_live_preview.dart';
import 'package:mangabaka_app/features/series/widgets/chip.dart';

/// A slice of the Library screen — header, status pills, a real series item in
/// the user's own list style, genre chips, buttons and a switch — painted in
/// [palette].
///
/// Built from the app's own widgets. They read `context.colors` from the theme
/// above them, so the slice is wrapped in a theme carrying [palette] instead of
/// the active one; that is how it can show a theme that is not active yet (the
/// editor's draft) without a second, hand-painted copy of the components that
/// would drift from the real ones.
class ThemeLivePreview extends StatefulWidget {
  final MbPalette palette;

  const ThemeLivePreview({super.key, required this.palette});

  @override
  State<ThemeLivePreview> createState() => _ThemeLivePreviewState();
}

class _ThemeLivePreviewState extends State<ThemeLivePreview> {
  late ThemeData _theme = _buildTheme();
  bool _switchOn = true;
  int _pill = 0;
  int _chip = 0;

  ThemeData _buildTheme() => AppTheme.build(
    widget.palette,
    showTooltips: SettingsManager().showTooltips,
  );

  @override
  void didUpdateWidget(ThemeLivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ThemeData is costly to build, and the editor republishes the same palette
    // on every unrelated rebuild.
    if (oldWidget.palette != widget.palette) _theme = _buildTheme();
  }

  @override
  Widget build(BuildContext context) {
    // The frame follows the active theme so it stays legible whatever the
    // previewed palette is; everything inside follows the previewed one.
    final frameBorder = context.colors.border;
    return AnimatedTheme(
      data: _theme,
      duration: const Duration(milliseconds: 220),
      child: Builder(
        builder: (context) {
          final p = context.colors;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: frameBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _content(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    final p = context.colors;
    final l10n = LocalizationService();
    final settings = SettingsManager();
    final pills = [
      l10n.translate('reading'),
      l10n.translate('completed'),
      l10n.translate('paused'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.translate('library').toUpperCase(),
          style: AppTypography.display(color: p.text, fontSize: 20),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                MbPill(
                  label: pills[i],
                  selected: _pill == i,
                  onTap: () => setState(() => _pill = i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListStyleLivePreview(
          style: settings.resolvedLibraryListStyle,
          showLibraryProgress: settings.showLibraryProgress,
          showRemainingProgress: settings.showRemainingProgress,
          progressType: settings.libraryProgressType,
          gridColumnCount: settings.resolvedLibraryGridColumnCount,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 3; i++)
              ChipBase(
                label: Text(
                  _title(mockSeries222.genres[i]),
                  style: AppTypography.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: _chip == i ? p.onAccent : p.text,
                  ),
                ),
                borderRadius: AppConstants.pillRadius,
                backgroundColor: _chip == i ? p.accent : p.surface,
                borderColor: _chip == i ? p.accent : p.border,
                onTap: () => setState(() => _chip = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MbPrimaryButton(
                label: l10n.translate('theme_preview_primary'),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MbSecondaryButton(
                label: l10n.translate('theme_preview_secondary'),
                onPressed: () {},
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
            Switch(
              value: _switchOn,
              onChanged: (v) => setState(() => _switchOn = v),
            ),
          ],
        ),
      ],
    );
  }

  static String _title(String key) => key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

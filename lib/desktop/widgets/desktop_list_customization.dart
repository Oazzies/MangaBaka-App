import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/widgets/app_snack_bar.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_scope.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_live_preview.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

/// The "List customization" settings page, laid out for a wide pane.
///
/// The phone's version is one long column — preview, a sideways-scrolling style
/// picker, then every toggle. Stretched across a desktop pane that leaves a
/// narrow strip of content in a sea of empty space, so here the pane is split:
/// what the list looks like (preview and style) on the left, how it behaves
/// (columns, separation, progress) on the right. Below [_splitWidth] the two
/// stack.
///
/// Reads and writes through the same [ListCustomizationScope] the phone
/// version uses, so which list a control edits is resolved in one place.
class DesktopListCustomization extends StatefulWidget {
  final LocalizationService l10n;

  const DesktopListCustomization({super.key, required this.l10n});

  @override
  State<DesktopListCustomization> createState() =>
      _DesktopListCustomizationState();
}

class _DesktopListCustomizationState extends State<DesktopListCustomization> {
  /// Pane width at which the two columns sit side by side.
  static const double _splitWidth = 860;

  static const double _columnGap = 24;

  ListScopeTab _tab = ListScopeTab.library;

  LocalizationService get _l10n => widget.l10n;

  ListCustomizationScope get _scope =>
      ListCustomizationScope(settings: SettingsManager(), tab: _tab);

  @override
  Widget build(BuildContext context) {
    final scope = _scope;

    return LayoutBuilder(
      builder: (context, constraints) {
        final appearance = _appearance(scope);
        final behaviour = _behaviour(scope);

        if (constraints.maxWidth < _splitWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              appearance,
              const SizedBox(height: _columnGap),
              behaviour,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: appearance),
            const SizedBox(width: _columnGap),
            Expanded(flex: 9, child: behaviour),
          ],
        );
      },
    );
  }

  // ─── Left: what the list looks like ──────────────────────────────────────

  Widget _appearance(ListCustomizationScope scope) {
    final settings = scope.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hidden while both lists share their style and column count: every
        // control would then be identical on either tab.
        if (scope.hasAnySeparation)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DesktopSegmented<ListScopeTab>(
                value: _tab,
                segments: [
                  (
                    ListScopeTab.library,
                    _l10n.translate('start_page_library'),
                    null,
                  ),
                  (
                    ListScopeTab.browse,
                    _l10n.translate('start_page_browse'),
                    null,
                  ),
                ],
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
          ),
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTitle(_l10n.translate('preview')),
              const SizedBox(height: 14),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: ListStyleLivePreview(
                      // Every input that changes the sample is in the key, so
                      // the switcher cross-fades on any of them.
                      key: ValueKey(
                        '${scope.style.name}_${settings.showLibraryProgress}_'
                        '${settings.showRemainingProgress}_'
                        '${settings.libraryProgressType.name}_'
                        '${scope.gridColumns}_${settings.compactGridTitleRows}_'
                        '${settings.showQuickProgress}',
                      ),
                      style: scope.style,
                      showLibraryProgress: settings.showLibraryProgress,
                      showRemainingProgress: settings.showRemainingProgress,
                      progressType: settings.libraryProgressType,
                      gridColumnCount: scope.gridColumns,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTitle(scope.styleLabel(_l10n)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final style in AppListStyle.values) ...[
                    if (style != AppListStyle.values.first)
                      const SizedBox(width: 10),
                    Expanded(
                      child: _StyleTile(
                        style: style,
                        label: ListStyleDialogs.getListStyleName(style),
                        selected: scope.style == style,
                        onTap: () => scope.setStyle(style),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (scope.showsGridColumns) ...[
          const SizedBox(height: 16),
          DesktopCard(
            showBorder: false,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _StepperRow(
                  icon: Icons.view_column_outlined,
                  label: scope.gridColumnsLabel(_l10n),
                  value: scope.gridColumns,
                  max: 12,
                  minLabel: _l10n.translate('grid_columns_auto'),
                  onChanged: scope.setGridColumns,
                ),
                if (scope.style == AppListStyle.compactGrid) ...[
                  const Divider(height: 24),
                  _StepperRow(
                    icon: Icons.short_text_rounded,
                    label: _l10n.translate('compact_grid_title_rows'),
                    value: settings.compactGridTitleRows,
                    min: 1,
                    onChanged: settings.setCompactGridTitleRows,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Right: how it behaves ───────────────────────────────────────────────

  Widget _behaviour(ListCustomizationScope scope) {
    final settings = scope.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DesktopSettingRow(
                icon: Icons.splitscreen_outlined,
                title: _l10n.translate('separate_list_styles'),
                subtitle: _l10n.translate('separate_list_styles_subtitle'),
                control: Switch(
                  value: settings.separateListStyles,
                  onChanged: (value) {
                    scope.setSeparateStyles(value);
                    if (!value && !settings.separateGridColumnCounts) {
                      setState(() => _tab = ListScopeTab.library);
                    }
                  },
                ),
              ),
              const Divider(height: 24),
              DesktopSettingRow(
                icon: Icons.grid_on_outlined,
                title: _l10n.translate('separate_grid_columns'),
                subtitle: _l10n.translate('separate_grid_columns_subtitle'),
                control: Switch(
                  value: settings.separateGridColumnCounts,
                  onChanged: (value) {
                    scope.setSeparateGridColumns(value);
                    if (!value && !settings.separateListStyles) {
                      setState(() => _tab = ListScopeTab.library);
                    }
                  },
                ),
              ),
              if (scope.hasAnySeparation) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DesktopPillButton(
                    label: _l10n.translate(
                      scope.tab.isLibrary
                          ? 'copy_to_browse'
                          : 'copy_to_library',
                    ),
                    icon: Icons.copy_all_outlined,
                    onPressed: () {
                      scope.copyToOtherTab();
                      AppSnackBar.show(
                        context,
                        _l10n.translate(
                          scope.tab.isLibrary
                              ? 'copied_to_browse'
                              : 'copied_to_library',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardTitle(_l10n.translate('progress_tracking')),
              const SizedBox(height: 16),
              DesktopSettingRow(
                icon: Icons.analytics_outlined,
                title: _l10n.translate('show_library_progress'),
                subtitle: _l10n.translate('show_library_progress_subtitle'),
                control: Switch(
                  value: settings.showLibraryProgress,
                  onChanged: settings.setShowLibraryProgress,
                ),
              ),
              // Only applies while progress is shown, so it folds in and out
              // rather than sitting there inert.
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: settings.showLibraryProgress
                      ? Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: DesktopSettingRow(
                            icon: Icons.menu_book_outlined,
                            title: _l10n.translate('library_progress_type'),
                            subtitle: _l10n.translate(
                              'library_progress_type_subtitle',
                            ),
                            control: DesktopMenuButton<LibraryProgressType>(
                              valueLabel:
                                  GeneralSettingsDialogs.getLibraryProgressTypeName(
                                    settings.libraryProgressType,
                                  ),
                              items: [
                                for (final t in LibraryProgressType.values)
                                  (
                                    t,
                                    GeneralSettingsDialogs.getLibraryProgressTypeName(
                                      t,
                                    ),
                                  ),
                              ],
                              selected: settings.libraryProgressType,
                              onSelected: settings.setLibraryProgressType,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
              const Divider(height: 24),
              DesktopSettingRow(
                icon: Icons.hourglass_empty,
                title: _l10n.translate('show_remaining_progress'),
                subtitle: _l10n.translate('show_remaining_progress_subtitle'),
                control: Switch(
                  value: settings.showRemainingProgress,
                  onChanged: settings.setShowRemainingProgress,
                ),
              ),
              const Divider(height: 24),
              DesktopSettingRow(
                icon: Icons.add_circle_outline,
                title: _l10n.translate('show_quick_progress'),
                subtitle: _l10n.translate('show_quick_progress_subtitle'),
                control: Switch(
                  value: settings.showQuickProgress,
                  onChanged: settings.setShowQuickProgress,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DesktopCard(
          showBorder: false,
          padding: const EdgeInsets.all(20),
          child: DesktopSettingRow(
            icon: Icons.tag,
            title: _l10n.translate('show_library_tab_counts'),
            subtitle: _l10n.translate('show_library_tab_counts_subtitle'),
            control: Switch(
              value: settings.showLibraryTabCounts,
              onChanged: settings.setShowLibraryTabCounts,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardTitle(String title) => Text(
    title.toUpperCase(),
    style: AppTypography.display(color: context.colors.text, fontSize: 15),
  );
}

/// One list style as a tile: its icon over its name.
class _StyleTile extends StatelessWidget {
  final AppListStyle style;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleTile({
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopHoverSurface(
      onTap: onTap,
      selected: selected,
      selectedColor: context.colors.accent.withValues(alpha: 0.14),
      idleColor: context.colors.surfaceRaised,
      hoverColor: context.colors.border,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Column(
        children: [
          Icon(
            style.icon,
            size: 26,
            color: selected ? context.colors.accent : context.colors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sans(
              color: selected ? context.colors.text : context.colors.textMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled -/+ counter for a bounded integer setting.
class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;

  /// Shown in place of [min] when the value is at the minimum — the grid's
  /// "auto" column count, where 0 is not a number worth reading.
  final String? minLabel;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.minLabel,
  });

  @override
  Widget build(BuildContext context) {
    final display = (minLabel != null && value == min)
        ? minLabel!
        : value.toString();

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Icon(icon, color: context.colors.textMuted, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.display(
              color: context.colors.text,
              fontSize: 14,
            ),
          ),
        ),
        DesktopIconButton(
          icon: Icons.remove_rounded,
          filled: true,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Container(
          // Fixed width so the row does not shift between 9, 10 and "Auto".
          constraints: const BoxConstraints(minWidth: 64),
          alignment: Alignment.center,
          child: Text(
            display,
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DesktopIconButton(
          icon: Icons.add_rounded,
          filled: true,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

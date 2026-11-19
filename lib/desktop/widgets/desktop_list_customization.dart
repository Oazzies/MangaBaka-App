import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/widgets/derived_layout_builder.dart';
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
import 'package:mangabaka_app/features/series/services/series_list_deps.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

part 'desktop_list_customization_widgets_part.dart';

class DesktopListCustomization extends StatefulWidget {
  final LocalizationService l10n;
  final SeriesListDeps deps;

  const DesktopListCustomization({
    super.key,
    required this.l10n,
    required this.deps,
  });

  @override
  State<DesktopListCustomization> createState() =>
      _DesktopListCustomizationState();
}

class _DesktopListCustomizationState extends State<DesktopListCustomization> {
  static const double _splitWidth = 860;

  static const double _columnGap = 24;

  ListScopeTab _tab = ListScopeTab.library;

  LocalizationService get _l10n => widget.l10n;

  ListCustomizationScope get _scope =>
      ListCustomizationScope(settings: SettingsManager(), tab: _tab);

  @override
  Widget build(BuildContext context) {
    final scope = _scope;

    return DerivedLayoutBuilder<bool>(
      derive: (constraints) => constraints.maxWidth < _splitWidth,
      builder: (context, narrow) {
        final appearance = _appearance(scope);
        final behaviour = _behaviour(scope);

        if (narrow) {
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

  Widget _appearance(ListCustomizationScope scope) {
    final settings = scope.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hidden while both lists share style and columns: the tabs would show identical controls.
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
                  (ListScopeTab.stacks, _l10n.translate('stacks'), null),
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
                      // Every sample-changing input is in the key, so any of them cross-fades.
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
                      deps: widget.deps,
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
                    label: _l10n.translate('copy_to_other_lists'),
                    icon: Icons.copy_all_rounded,
                    onPressed: () {
                      scope.copyToOtherTabs();
                      AppSnackBar.show(
                        context,
                        _l10n.translate('copied_to_other_lists'),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ProgressTrackingCards(settings: settings, l10n: _l10n),
      ],
    );
  }

  Widget _cardTitle(String title) => Text(
    title.toUpperCase(),
    style: AppTypography.display(color: context.colors.text, fontSize: 15),
  );
}

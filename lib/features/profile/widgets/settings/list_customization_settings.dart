import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_scope.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_toggles.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_scope_tab_selector.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_live_preview.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_preview_item.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_group.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_section_header.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_stepper_row.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_switch_item.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';

export 'package:mangabaka_app/features/profile/widgets/settings/list_style_live_preview.dart';

/// The "List customization" settings category.
///
/// Library and Browse can be configured together or apart;
/// [ListCustomizationScope] resolves which of the two the visible controls are
/// editing, so nothing here has to re-derive it.
class ListCustomizationSettings extends StatefulWidget {
  final LocalizationService l10n;

  const ListCustomizationSettings({super.key, required this.l10n});

  @override
  State<ListCustomizationSettings> createState() =>
      _ListCustomizationSettingsState();
}

class _ListCustomizationSettingsState extends State<ListCustomizationSettings>
    with SingleTickerProviderStateMixin {
  /// Width of one style card plus its separator, used to centre the selected
  /// card in the horizontal picker.
  static const double _styleCardWidth = 108.0;
  static const double _styleCardStride = 116.0;

  static const Duration _panelSlide = Duration(milliseconds: 320);

  ListScopeTab _tab = ListScopeTab.library;

  late final ScrollController _scrollController;

  /// Drives the horizontal slide of the whole panel below the tab selector.
  /// Sits at 1.0 when settled; [_switchTab] restarts it from 0.0 so the new
  /// tab's content slides in from [_slideSign] * panel width.
  late final AnimationController _slideController;
  double _slideSign = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _slideController = AnimationController(
      vsync: this,
      duration: _panelSlide,
      value: 1.0,
    );
    // The picker can only be scrolled once it has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animated: false);
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ListCustomizationScope get _scope =>
      ListCustomizationScope(settings: SettingsManager(), tab: _tab);

  /// Switches to [tab] and plays the slide-in. No-op if already there.
  void _switchTab(ListScopeTab tab) {
    if (tab == _tab) return;
    setState(() {
      // Slide in from the side the new tab sits on.
      _slideSign = tab == ListScopeTab.browse ? 1.0 : -1.0;
      _tab = tab;
    });
    _slideController.forward(from: 0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animated: false);
    });
  }

  /// Brings the selected style card to the centre of the picker, so the
  /// current choice is visible rather than scrolled off to one side.
  void _scrollToSelected({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final index = AppListStyle.values.indexOf(_scope.style);
    if (index == -1) return;

    final target =
        ((index * _styleCardStride) -
                (MediaQuery.sizeOf(context).width / 2) +
                (_styleCardWidth / 2))
            .clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The tab selector is hidden while both lists share their style and
        // column count, since every control below would then be identical on
        // either tab.
        if (scope.hasAnySeparation)
          ListScopeTabSelector(
            active: _tab,
            libraryLabel: widget.l10n.translate('start_page_library'),
            browseLabel: widget.l10n.translate('start_page_browse'),
            onChanged: _switchTab,
          ),

        // Everything below the tab selector slides in horizontally whenever
        // the active tab changes, so it reads as a different list even when
        // Library and Browse are configured to look identical.
        ClipRect(
          child: AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_slideController.value);
              return Opacity(
                opacity: t,
                child: FractionalTranslation(
                  translation: Offset(_slideSign * (1.0 - t), 0.0),
                  child: child,
                ),
              );
            },
            child: _buildTabContent(context, scope),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, ListCustomizationScope scope) {
    final settings = scope.settings;
    final l10n = widget.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPreview(scope),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            scope.styleLabel(l10n),
            style: AppTypography.sans(
              color: context.colors.text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildStylePicker(scope),
        if (scope.showsGridColumns) ...[
          const SizedBox(height: 16),
          SettingsStepperRow(
            label: scope.gridColumnsLabel(l10n),
            value: scope.gridColumns,
            max: 12,
            minLabel: l10n.translate('grid_columns_auto'),
            onChanged: scope.setGridColumns,
          ),
          if (scope.style == AppListStyle.compactGrid) ...[
            const SizedBox(height: 16),
            SettingsStepperRow(
              label: l10n.translate('compact_grid_title_rows'),
              value: settings.compactGridTitleRows,
              min: 1,
              onChanged: settings.setCompactGridTitleRows,
            ),
          ],
        ],
        const SizedBox(height: 16),
        ListSeparationSwitches(
          scope: scope,
          l10n: l10n,
          onSeparationEnded: () => _switchTab(ListScopeTab.library),
        ),
        const SizedBox(height: 16),
        SettingsSectionHeader(title: l10n.translate('progress_tracking')),
        ProgressTrackingSwitches(settings: settings, l10n: l10n),
        if (scope.hasAnySeparation) ...[
          const SizedBox(height: 16),
          CopyToOtherListButton(scope: scope, l10n: l10n),
        ],
        const SizedBox(height: 16),
        SettingsGroup(
          children: [
            SettingsSwitchItem(
              icon: Icons.tag,
              title: l10n.translate('show_library_tab_counts'),
              subtitle: l10n.translate('show_library_tab_counts_subtitle'),
              value: settings.showLibraryTabCounts,
              onChanged: settings.setShowLibraryTabCounts,
              isFirst: true,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Cross-fades when the style or a progress toggle changes within a tab; the
  /// panel-level slide handles tab switches, so this one deliberately does not
  /// move horizontally.
  Widget _buildPreview(ListCustomizationScope scope) {
    final settings = scope.settings;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: ListStyleLivePreview(
            // Every input that changes what the preview looks like is in the
            // key, so the switcher animates on any of them.
            key: ValueKey(
              '${scope.style.name}_${settings.showLibraryProgress}_'
              '${settings.showRemainingProgress}_'
              '${settings.libraryProgressType.name}_${scope.gridColumns}_'
              '${settings.compactGridTitleRows}',
            ),
            style: scope.style,
            showLibraryProgress: settings.showLibraryProgress,
            showRemainingProgress: settings.showRemainingProgress,
            progressType: settings.libraryProgressType,
            gridColumnCount: scope.gridColumns,
          ),
        ),
      ),
    );
  }

  Widget _buildStylePicker(ListCustomizationScope scope) {
    return SizedBox(
      height: 200,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: AppListStyle.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final style = AppListStyle.values[index];
            return ListStylePreviewItem(
              style: style,
              isSelected: scope.style == style,
              label: ListStyleDialogs.getListStyleName(style),
              onTap: () {
                scope.setStyle(style);
                // Re-centre after the change has been applied and laid out.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToSelected(animated: true);
                });
              },
            );
          },
        ),
      ),
    );
  }

  /// Copies the active tab's independent settings onto the other list. Only
  /// meaningful while at least one of the two is configured separately.
}

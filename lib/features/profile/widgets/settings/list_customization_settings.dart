import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_group.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_switch_item.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_divider.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_style_preview_item.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/list_style_dialogs.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/entry_list_item.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_section_header.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/settings_item.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';

class ListStyleLivePreview extends StatelessWidget {
  final AppListStyle style;
  final bool showLibraryProgress;
  final bool showRemainingProgress;
  final LibraryProgressType progressType;
  final int gridColumnCount;

  const ListStyleLivePreview({
    super.key,
    required this.style,
    required this.showLibraryProgress,
    required this.showRemainingProgress,
    required this.progressType,
    required this.gridColumnCount,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPreviewContent(context);
  }

  Widget _buildPreviewContent(BuildContext context) {
    final mockLibraryEntry222 = LibraryEntry(
      id: '222',
      state: 'reading',
      progressChapter: 5,
      progressVolume: 1,
      series: mockSeries222,
    );

    if (style.isGrid) {
      final columns = gridColumnCount;
      final gridDelegate = columns > 0
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: style.childAspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            );

      final itemCount = columns > 0 ? columns : 3;

      Widget grid = GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        gridDelegate: gridDelegate,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return EntryListItem(
            series: mockSeries222,
            isLibrary: true,
            listStyle: style,
            heroTagPrefix: 'preview_${style.name}_$index',
            previewEntry: mockLibraryEntry222,
          );
        },
      );

      if (columns > 0) {
        final expectedWidth = columns * 160.0 + (columns - 1) * 10.0 + 24.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: expectedWidth),
            child: grid,
          ),
        );
      }

      return grid;
    }

    return EntryListItem(
      series: mockSeries222,
      isLibrary: true,
      listStyle: style,
      heroTagPrefix: 'preview_${style.name}',
      previewEntry: mockLibraryEntry222,
    );
  }
}

class ListCustomizationSettings extends StatefulWidget {
  final LocalizationService l10n;

  const ListCustomizationSettings({super.key, required this.l10n});

  @override
  State<ListCustomizationSettings> createState() =>
      _ListCustomizationSettingsState();
}

class _ListCustomizationSettingsState extends State<ListCustomizationSettings> {
  int _activeTab = 0; // 0 = Library, 1 = Browse
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animated: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final settings = SettingsManager();
    final activeStyle = _activeTab == 0
        ? settings.libraryListStyle
        : settings.browseListStyle;
    final selectedIndex = AppListStyle.values.indexOf(activeStyle);
    if (selectedIndex == -1) return;

    final itemWidth = 116.0; // 108 width + 8 spacing
    final screenWidth = MediaQuery.of(context).size.width;
    double targetOffset = (selectedIndex * itemWidth) - (screenWidth / 2) + (108.0 / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    if (animated) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  Widget _buildTabSelector(SettingsManager settings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tabWidth = width / 2;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 38,
          decoration: BoxDecoration(
            color: AppConstants.secondaryBackground,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppConstants.borderColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: _activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _activeTab = 0);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelected(animated: true);
                        });
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _activeTab == 0
                                ? AppConstants.primaryBackground
                                : AppConstants.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: Text(
                            widget.l10n.translate('start_page_library'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _activeTab = 1);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelected(animated: true);
                        });
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _activeTab == 1
                                ? AppConstants.primaryBackground
                                : AppConstants.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: Text(
                            widget.l10n.translate('start_page_browse'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnCounter({
    required String label,
    required int currentValue,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: currentValue > 0
                    ? () => onChanged(currentValue - 1)
                    : null,
                color: AppConstants.accentColor,
                disabledColor: AppConstants.textMutedColor.withValues(alpha: 0.3),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                alignment: Alignment.center,
                child: Text(
                  currentValue == 0
                      ? widget.l10n.translate('grid_columns_auto')
                      : currentValue.toString(),
                  style: TextStyle(
                    color: AppConstants.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: currentValue < 12
                    ? () => onChanged(currentValue + 1)
                    : null,
                color: AppConstants.accentColor,
                disabledColor: AppConstants.textMutedColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsManager();

    final activeStyle = _activeTab == 0
        ? settings.libraryListStyle
        : settings.browseListStyle;

    final showColumns = activeStyle == AppListStyle.coverOnlyGrid ||
        activeStyle == AppListStyle.compactGrid;

    final gridColumnsLabel = settings.separateGridColumnCounts
        ? (_activeTab == 0
            ? widget.l10n.translate('library_grid_columns')
            : widget.l10n.translate('browse_grid_columns'))
        : widget.l10n.translate('grid_columns');

    final gridColumnsValue = settings.separateGridColumnCounts
        ? (_activeTab == 0
            ? settings.libraryGridColumnCount
            : settings.browseGridColumnCount)
        : settings.gridColumnCount;

    final isSmallDevice = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Library/Browse Tab Selector
        _buildTabSelector(settings),
        
        // 2. List Preview
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: ListStyleLivePreview(
              key: ValueKey('${activeStyle.name}_${settings.showLibraryProgress}_${settings.showRemainingProgress}_${settings.libraryProgressType.name}_$gridColumnsValue'),
              style: activeStyle,
              showLibraryProgress: settings.showLibraryProgress,
              showRemainingProgress: settings.showRemainingProgress,
              progressType: settings.libraryProgressType,
              gridColumnCount: gridColumnsValue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 3. List Style Select (including column counts settings)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.l10n.translate('list_style'),
            style: TextStyle(
              color: AppConstants.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: AppListStyle.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final style = AppListStyle.values[index];
              final isSelected = activeStyle == style;

              return ListStylePreviewItem(
                style: style,
                isSelected: isSelected,
                label: ListStyleDialogs.getListStyleName(style),
                onTap: () {
                  if (_activeTab == 0) {
                    settings.setLibraryListStyle(style);
                  } else {
                    settings.setBrowseListStyle(style);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToSelected(animated: true);
                  });
                },
              );
            },
          ),
        ),
        if (showColumns) ...[
          const SizedBox(height: 16),
          _buildColumnCounter(
            label: gridColumnsLabel,
            currentValue: gridColumnsValue,
            onChanged: (val) {
              if (settings.separateGridColumnCounts) {
                if (_activeTab == 0) {
                  settings.setLibraryGridColumnCount(val);
                } else {
                  settings.setBrowseGridColumnCount(val);
                }
              } else {
                settings.setGridColumnCount(val);
              }
            },
          ),
        ],
        if (!isSmallDevice) ...[
          const SizedBox(height: 16),
          SettingsGroup(
            children: [
              SettingsSwitchItem(
                icon: Icons.grid_on_outlined,
                title: widget.l10n.translate('separate_grid_columns'),
                subtitle: widget.l10n.translate('separate_grid_columns_subtitle'),
                value: settings.separateGridColumnCounts,
                onChanged: (val) {
                  settings.setSeparateGridColumnCounts(val);
                  if (!val) {
                    setState(() => _activeTab = 0);
                  }
                },
                isFirst: true,
                isLast: true,
              ),
            ],
          ),
        ],
        
        // 4. Progress Tracking section
        const SizedBox(height: 16),
        SettingsSectionHeader(title: widget.l10n.translate('progress_tracking')),
        SettingsGroup(
          children: [
            SettingsSwitchItem(
              icon: Icons.analytics_outlined,
              title: widget.l10n.translate('show_library_progress'),
              subtitle: widget.l10n.translate('show_library_progress_subtitle'),
              value: settings.showLibraryProgress,
              onChanged: (val) => settings.setShowLibraryProgress(val),
              isFirst: true,
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (settings.showLibraryProgress) ...[
                      const SettingsDivider(),
                      SettingsItem(
                        icon: Icons.menu_book_outlined,
                        title: widget.l10n.translate('library_progress_type'),
                        subtitle: GeneralSettingsDialogs.getLibraryProgressTypeName(
                          settings.libraryProgressType,
                        ),
                        onTap: () => GeneralSettingsDialogs
                            .showLibraryProgressTypeSelectionDialog(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SettingsDivider(),
            SettingsSwitchItem(
              icon: Icons.hourglass_empty,
              title: widget.l10n.translate('show_remaining_progress'),
              subtitle: widget.l10n.translate('show_remaining_progress_subtitle'),
              value: settings.showRemainingProgress,
              onChanged: (val) => settings.setShowRemainingProgress(val),
            ),
            const SettingsDivider(),
            SettingsSwitchItem(
              icon: Icons.add_circle_outline,
              title: widget.l10n.translate('show_quick_progress'),
              subtitle: widget.l10n.translate('show_quick_progress_subtitle'),
              value: settings.showQuickProgress,
              onChanged: (val) => settings.setShowQuickProgress(val),
              isLast: true,
            ),
          ],
        ),

        // 5. Copy settings helper button
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            if (_activeTab == 0) {
              settings.setBrowseListStyle(settings.libraryListStyle);
              settings.setBrowseGridColumnCount(settings.libraryGridColumnCount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.l10n.translate('copied_to_browse'),
                  ),
                ),
              );
            } else {
              settings.setLibraryListStyle(settings.browseListStyle);
              settings.setLibraryGridColumnCount(settings.browseGridColumnCount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.l10n.translate('copied_to_library'),
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_all_outlined),
          label: Text(
            _activeTab == 0
                ? widget.l10n.translate('copy_to_browse')
                : widget.l10n.translate('copy_to_library'),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.accentColor,
            side: BorderSide(color: AppConstants.accentColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // 6. Show Tab counts setting (isolated)
        const SizedBox(height: 16),
        SettingsGroup(
          children: [
            SettingsSwitchItem(
              icon: Icons.tag,
              title: widget.l10n.translate('show_library_tab_counts'),
              subtitle: widget.l10n.translate('show_library_tab_counts_subtitle'),
              value: settings.showLibraryTabCounts,
              onChanged: (val) => settings.setShowLibraryTabCounts(val),
              isFirst: true,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

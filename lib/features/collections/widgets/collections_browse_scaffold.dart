import 'package:flutter/material.dart';
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/theme/app_typography.dart';
import 'package:mangabaka_app/core/theme/theme_context.dart';
import 'package:mangabaka_app/core/utils/widget_utils.dart';
import 'package:mangabaka_app/core/widgets/design/mb_screen_header.dart';
import 'package:mangabaka_app/desktop/widgets/desktop_surfaces.dart';
import 'package:mangabaka_app/features/collections/widgets/collections_browse_rows.dart';

class CollectionsDesktopScaffold extends StatelessWidget {
  final LocalizationService l10n;
  final String? publisherName;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final Widget collectionsTab;
  final Widget editionsTab;

  const CollectionsDesktopScaffold({
    super.key,
    required this.l10n,
    required this.publisherName,
    required this.activeTab,
    required this.onTabChanged,
    required this.collectionsTab,
    required this.editionsTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPageHeader(
            leading: DesktopIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: l10n.translate('collections_and_editions'),
            subtitle: publisherName,
            actions: [
              DesktopSegmented<int>(
                value: activeTab,
                segments: [
                  (
                    0,
                    l10n.translate('tab_collections'),
                    Icons.collections_bookmark_rounded,
                  ),
                  (1, l10n.translate('editions'), Icons.auto_stories_rounded),
                ],
                onChanged: onTabChanged,
              ),
            ],
          ),
          Expanded(
            child: WidgetUtils.responsiveConstraint(
              maxWidth: 960,
              Stack(
                children: [
                  for (final (index, tab) in [
                    collectionsTab,
                    editionsTab,
                  ].indexed)
                    Positioned.fill(
                      child: CollectionsDesktopTabLayer(
                        active: activeTab == index,
                        child: tab,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionsMobileScaffold extends StatelessWidget {
  final LocalizationService l10n;
  final TabController tabs;
  final Widget collectionsTab;
  final Widget editionsTab;

  const CollectionsMobileScaffold({
    super.key,
    required this.l10n,
    required this.tabs,
    required this.collectionsTab,
    required this.editionsTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: mbScreenAppBar(
        title: l10n.translate('collections_and_editions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppConstants.pillRadius),
              ),
              child: TabBar(
                controller: tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: context.colors.accent,
                  borderRadius: BorderRadius.circular(AppConstants.pillRadius),
                ),
                indicatorPadding: EdgeInsets.zero,
                labelColor: context.colors.onAccent,
                unselectedLabelColor: context.colors.textMuted,
                labelStyle: AppTypography.display(fontSize: 12),
                unselectedLabelStyle: AppTypography.display(fontSize: 12),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.collections_bookmark_rounded,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.translate('tab_collections').toUpperCase()),
                      ],
                    ),
                  ),
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.translate('editions').toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: WidgetUtils.responsiveConstraint(
        maxWidth: 900,
        TabBarView(controller: tabs, children: [collectionsTab, editionsTab]),
      ),
    );
  }
}

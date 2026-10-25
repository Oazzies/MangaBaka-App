import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/profile/widgets/settings/list_customization_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsManager settings;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    settings = SettingsManager();
    await settings.init();
  });

  ListCustomizationScope scope(ListScopeTab tab) =>
      ListCustomizationScope(settings: settings, tab: tab);

  group('shared styles', () {
    test('both tabs read the one shared style', () async {
      await settings.setSeparateListStyles(false);
      await settings.setListStyle(AppListStyle.comfortable);

      expect(scope(ListScopeTab.library).style, AppListStyle.comfortable);
      expect(scope(ListScopeTab.browse).style, AppListStyle.comfortable);
    });

    test('writing from either tab writes the shared style', () async {
      await settings.setSeparateListStyles(false);
      scope(ListScopeTab.browse).setStyle(AppListStyle.coverOnlyGrid);

      expect(settings.currentListStyle, AppListStyle.coverOnlyGrid);
      expect(scope(ListScopeTab.library).style, AppListStyle.coverOnlyGrid);
    });
  });

  group('separate styles', () {
    setUp(() => settings.setSeparateListStyles(true));

    test('each tab reads its own style', () async {
      await settings.setLibraryListStyle(AppListStyle.comfortable);
      await settings.setBrowseListStyle(AppListStyle.coverOnlyGrid);

      expect(scope(ListScopeTab.library).style, AppListStyle.comfortable);
      expect(scope(ListScopeTab.browse).style, AppListStyle.coverOnlyGrid);
    });

    test('writing from one tab leaves the other alone', () async {
      await settings.setLibraryListStyle(AppListStyle.comfortable);
      scope(ListScopeTab.browse).setStyle(AppListStyle.coverOnlyGrid);

      expect(settings.libraryListStyle, AppListStyle.comfortable);
      expect(settings.browseListStyle, AppListStyle.coverOnlyGrid);
    });
  });

  group('grid columns follow their own switch', () {
    test('separate styles do not imply separate column counts', () async {
      await settings.setSeparateListStyles(true);
      await settings.setSeparateGridColumnCounts(false);
      await settings.setGridColumnCount(4);

      expect(scope(ListScopeTab.library).gridColumns, 4);
      expect(scope(ListScopeTab.browse).gridColumns, 4);
    });

    test('separated counts are read per tab', () async {
      await settings.setSeparateGridColumnCounts(true);
      await settings.setLibraryGridColumnCount(2);
      await settings.setBrowseGridColumnCount(5);

      expect(scope(ListScopeTab.library).gridColumns, 2);
      expect(scope(ListScopeTab.browse).gridColumns, 5);
    });
  });

  group('turning separation on and off never changes the look', () {
    test('turning styles on seeds both lists from the shared style', () async {
      await settings.setSeparateListStyles(false);
      await settings.setListStyle(AppListStyle.comfortable);

      scope(ListScopeTab.library).setSeparateStyles(true);

      expect(settings.libraryListStyle, AppListStyle.comfortable);
      expect(settings.browseListStyle, AppListStyle.comfortable);
    });

    test('turning styles off adopts the active tab’s style', () async {
      await settings.setSeparateListStyles(true);
      await settings.setLibraryListStyle(AppListStyle.comfortable);
      await settings.setBrowseListStyle(AppListStyle.coverOnlyGrid);

      scope(ListScopeTab.browse).setSeparateStyles(false);

      expect(settings.currentListStyle, AppListStyle.coverOnlyGrid);
    });

    test('turning columns on seeds both lists from the shared count', () async {
      await settings.setSeparateGridColumnCounts(false);
      await settings.setGridColumnCount(3);

      scope(ListScopeTab.library).setSeparateGridColumns(true);

      expect(settings.libraryGridColumnCount, 3);
      expect(settings.browseGridColumnCount, 3);
    });
  });

  group('copyToOtherTab', () {
    test('copies the active tab onto the other one', () async {
      await settings.setSeparateListStyles(true);
      await settings.setLibraryListStyle(AppListStyle.comfortable);
      await settings.setBrowseListStyle(AppListStyle.coverOnlyGrid);

      scope(ListScopeTab.library).copyToOtherTabs();

      expect(settings.browseListStyle, AppListStyle.comfortable);
    });

    test('leaves shared settings alone — there is nothing to copy', () async {
      await settings.setSeparateListStyles(false);
      await settings.setListStyle(AppListStyle.comfortable);

      scope(ListScopeTab.library).copyToOtherTabs();

      expect(settings.currentListStyle, AppListStyle.comfortable);
    });
  });

  test('the stacks tab edits its own style once styles are separate', () async {
    await settings.setSeparateListStyles(true);
    await settings.setBrowseListStyle(AppListStyle.compact);

    scope(ListScopeTab.stacks).setStyle(AppListStyle.coverOnlyGrid);

    expect(settings.stacksListStyle, AppListStyle.coverOnlyGrid);
    expect(settings.resolvedStacksListStyle, AppListStyle.coverOnlyGrid);
    expect(settings.browseListStyle, AppListStyle.compact);
  });

  test('hasAnySeparation is true when either switch is on', () async {
    await settings.setSeparateListStyles(false);
    await settings.setSeparateGridColumnCounts(false);
    expect(scope(ListScopeTab.library).hasAnySeparation, isFalse);

    await settings.setSeparateGridColumnCounts(true);
    expect(scope(ListScopeTab.library).hasAnySeparation, isTrue);
  });
}

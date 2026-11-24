import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/features/lists/controllers/library_list_detail_controller.dart';
import 'package:mangabaka_app/features/lists/controllers/library_lists_controller.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list_sort.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../responsive/support/fixtures.dart';
import 'lists_fakes.dart';

void main() {
  late FakeListsService service;
  late FakeEntriesLibrary library;
  late LibraryListsController lists;

  // Fixture ratings cycle safe, suggestive, erotica, safe; ids are 1000 + i.
  final entries = Fixtures.library(8);

  setUp(() async {
    await resetServiceLocator();
    getIt.registerSingleton<LoggingService>(LoggingService());
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await SettingsManager().setContentPreferences(['safe', 'suggestive']);
    service = FakeListsService(
      lists: [
        const LibraryList(id: 1, name: 'Favourites', isPrivate: false),
        const LibraryList(id: 2, name: 'Read on the train', isPrivate: true),
        const LibraryList(id: 3, name: 'Archive', isPrivate: false),
      ],
      members: {
        1: {'1000', '1001', '1002', '1003'},
        2: {'1004'},
      },
    );
    library = FakeEntriesLibrary(entries);
    lists = LibraryListsController(service: service, library: library);
    await pumpEventQueue();
  });

  tearDown(() async {
    lists.dispose();
    SettingsManager.resetForTesting();
    await resetServiceLocator();
  });

  test('counts only library series the content settings allow', () {
    // 1002 is erotica, hidden by the settings.
    expect(lists.countOf(1), 3);
    expect(lists.countOf(2), 1);
    expect(lists.countOf(3), 0);
    expect(lists.entriesOn(1).map((e) => e.series.id).toSet(), {
      '1000',
      '1001',
      '1003',
    });
  });

  test('search ignores case and spacing; sort orders the rest', () {
    lists.setQuery('readon');
    expect(lists.visible.map((l) => l.id), [2]);
    lists.setQuery('');
    lists.setSort(LibraryListSort.mostSeries);
    expect(lists.visible.map((l) => l.id), [1, 2, 3]);
    lists.setSort(LibraryListSort.nameAsc);
    expect(lists.visible.map((l) => l.id), [3, 1, 2]);
  });

  test('a clashing name is refused before any request', () async {
    final (created, error) = await lists.create(' favourites ');
    expect(created, isNull);
    expect(error, 'lists_error_name_taken');
    expect(service.calls, isEmpty);
  });

  test('edit sends only what changed, and nothing when nothing did', () async {
    expect(await lists.edit(1, 'Favourites', isPrivate: false), isNull);
    expect(service.calls, isEmpty);
    expect(await lists.edit(1, 'Favourites', isPrivate: true), isNull);
    expect(service.calls.single, 'edit 1 - true');
  });

  test('a failed write maps to a message key', () async {
    service.failNext = apiError(404);
    expect(await lists.delete(1), 'lists_error_gone');
    service.failNext = apiError(400);
    expect(
      await lists.setMembership('1005', 3, member: true),
      'lists_error_too_many_lists',
    );
  });

  test('a series outside the library joins it before the list', () async {
    expect(
      await lists.addToLibraryAndList('1040', 3, state: 'reading'),
      isNull,
    );
    expect(library.created, ['1040 reading']);
    expect(service.calls, ['add 1040 3']);
  });

  test('a failed library add leaves the list alone', () async {
    library.failCreate = apiError(500);
    expect(
      await lists.addToLibraryAndList('1040', 3, state: 'reading'),
      'failed_to_add',
    );
    expect(service.calls, isEmpty);
  });

  test('a 31st list for one series is refused locally', () async {
    service.lists = [
      for (var i = 1; i <= 31; i++)
        LibraryList(id: i, name: 'L$i', isPrivate: false),
    ];
    service.members = {
      for (var i = 1; i <= 30; i++) i: {'1000'},
    };
    service.emit();
    await pumpEventQueue();
    expect(
      await lists.setMembership('1000', 31, member: true),
      'lists_error_too_many_lists',
    );
    expect(service.calls, isEmpty);
  });

  test('batch actions use the selection and clear it', () async {
    lists.toggleSelected(1);
    lists.toggleSelected(3);
    expect(await lists.setSelectedPrivate(isPrivate: true), isNull);
    expect(service.calls.single, 'privacy [1, 3] true');
    expect(lists.isSelecting, isFalse);

    lists.selectAll([2, 3]);
    expect(await lists.deleteSelected(), isNull);
    await pumpEventQueue();
    expect(lists.all.map((l) => l.id), [1]);
  });

  test('a deleted list drops out of the selection', () async {
    lists.selectAll([1, 2]);
    await service.delete(2);
    await pumpEventQueue();
    expect(lists.selected, {1});
  });

  group('detail', () {
    test('lists, searches and removes the series on one list', () async {
      final detail = LibraryListDetailController(lists: lists, listId: 1);
      expect(detail.items, hasLength(3));
      expect(detail.total, 3);

      detail.toggle('1000');
      detail.toggle('1001');
      expect(await detail.removeSelected(), isNull);
      await pumpEventQueue();
      expect(service.calls, ['remove 1000 1', 'remove 1001 1']);
      expect(detail.items.map((e) => e.series.id), ['1003']);
      expect(detail.isSelecting, isFalse);
      detail.dispose();
    });
  });
}

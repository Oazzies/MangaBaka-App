import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/features/lists/models/library_list.dart';
import 'package:mangabaka_app/features/lists/models/library_list_sort.dart';
import 'package:mangabaka_app/features/lists/services/library_list_errors.dart';

LibraryList list(int id, String name, {bool private = false, DateTime? at}) =>
    LibraryList(id: id, name: name, isPrivate: private, createdAt: at);

void main() {
  group('LibraryList.fromJson', () {
    test('reads the v2 shape', () {
      final l = LibraryList.fromJson({
        'id': 10059,
        'name': 'Favourites',
        'is_private': true,
        'series_count': 3,
        'created_at': '2026-11-14T12:00:00.000Z',
        'updated_at': null,
      });
      expect(l.id, 10059);
      expect(l.name, 'Favourites');
      expect(l.isPrivate, isTrue);
      expect(l.createdAt, DateTime.utc(2026, 11, 14, 12));
      expect(l.updatedAt, isNull);
    });

    test('a row without id or name is refused', () {
      expect(() => LibraryList.fromJson({'name': 'x'}), throwsFormatException);
      expect(() => LibraryList.fromJson({'id': 1}), throwsFormatException);
    });
  });

  group('LibraryListRules', () {
    final existing = [list(1, 'Favourites'), list(2, 'Read on the train')];

    test('whitespace runs collapse and the ends trim', () {
      expect(
        LibraryListRules.normalize('  Read \t on\n the   train '),
        'Read on the train',
      );
    });

    test('names clash ignoring case and spacing', () {
      expect(
        LibraryListRules.validate('favourites', existing),
        'lists_error_name_taken',
      );
      expect(
        LibraryListRules.validate(' read  ON the train', existing),
        'lists_error_name_taken',
      );
      expect(LibraryListRules.validate('Favourites 2', existing), isNull);
    });

    test('renaming a list onto its own name is fine', () {
      expect(
        LibraryListRules.validate('FAVOURITES', existing, editingId: 1),
        isNull,
      );
    });

    test('empty and overlong names are refused', () {
      expect(
        LibraryListRules.validate('   ', existing),
        'lists_error_name_empty',
      );
      expect(
        LibraryListRules.validate('x' * 256, existing),
        'lists_error_name_long',
      );
      expect(LibraryListRules.validate('x' * 255, existing), isNull);
    });
  });

  group('LibraryListSort', () {
    final a = list(1, 'banana', at: DateTime(2026, 1, 1));
    final b = list(2, 'Apple', private: true, at: DateTime(2026, 3, 1));
    final c = list(3, 'cherry', at: DateTime(2026, 2, 1));
    final counts = {1: 5, 2: 5, 3: 9};

    List<int> sorted(LibraryListSort s) =>
        ([a, b, c]..sort((x, y) => s.compare(x, y, (l) => counts[l.id]!)))
            .map((l) => l.id)
            .toList();

    test('orders by name, count, age and visibility', () {
      expect(sorted(LibraryListSort.nameAsc), [2, 1, 3]);
      expect(sorted(LibraryListSort.nameDesc), [3, 1, 2]);
      expect(sorted(LibraryListSort.mostSeries), [3, 2, 1]);
      expect(sorted(LibraryListSort.fewestSeries), [2, 1, 3]);
      expect(sorted(LibraryListSort.newest), [2, 3, 1]);
      expect(sorted(LibraryListSort.oldest), [1, 3, 2]);
      expect(sorted(LibraryListSort.publicFirst), [1, 3, 2]);
      expect(sorted(LibraryListSort.privateFirst), [2, 1, 3]);
    });

    test('ids stand in for a missing created_at', () {
      final x = list(7, 'x');
      final y = list(9, 'y');
      expect(LibraryListSort.newest.compare(x, y, (_) => 0), greaterThan(0));
    });
  });

  group('listErrorKey', () {
    ApiException api(int status) =>
        ApiException(message: 'Failed', statusCode: status);

    test('a 400 names the rule the operation could break', () {
      expect(
        listErrorKey(api(400), ListOp.create),
        'lists_error_name_rejected',
      );
      expect(
        listErrorKey(api(400), ListOp.rename),
        'lists_error_name_rejected',
      );
      expect(
        listErrorKey(api(400), ListOp.addSeries),
        'lists_error_too_many_lists',
      );
      expect(listErrorKey(api(400), ListOp.batch), 'lists_error_gone');
    });

    test('a 404 is a missing series or a missing list', () {
      expect(
        listErrorKey(api(404), ListOp.removeSeries),
        'lists_error_not_in_library',
      );
      expect(listErrorKey(api(404), ListOp.rename), 'lists_error_gone');
    });

    test('everything else falls back to the shared messages', () {
      expect(listErrorKey(api(503), ListOp.create), 'error_server');
      expect(
        listErrorKey(NetworkException(message: 'x'), ListOp.load),
        'error_network',
      );
    });
  });
}

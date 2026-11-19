import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/features/staff/models/staff.dart';

void main() {
  group('Staff', () {
    test('fromJson parses all fields', () {
      final s = Staff.fromJson({
        'id': 7,
        'name': 'Akira Toriyama',
        'native_name': '鳥山 明',
        'role': 'artist',
        'image': 'https://example/img.png',
        'series_count': 14,
        'notes': 'Author',
      });
      expect(s.id, 7);
      expect(s.name, 'Akira Toriyama');
      expect(s.nativeName, '鳥山 明');
      expect(s.role, StaffRole.artist);
      expect(s.image, 'https://example/img.png');
      expect(s.seriesCount, 14);
      expect(s.notes, 'Author');
    });

    test('fromJson handles optional fields being null', () {
      final s = Staff.fromJson({'id': 1, 'name': 'X'});
      expect(s.id, 1);
      expect(s.name, 'X');
      expect(s.nativeName, isNull);
      expect(s.role, isNull);
      expect(s.image, isNull);
      expect(s.seriesCount, isNull);
      expect(s.notes, isNull);
    });

    test('toJson includes nulls for optionals', () {
      final s = Staff(id: 1, name: 'X');
      final json = s.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'X');
      expect(json['native_name'], isNull);
      expect(json['series_count'], isNull);
    });

    test('fromJson leaves an unknown role null', () {
      final s = Staff.fromJson({'id': 1, 'name': 'X', 'role': 'mangaka'});
      expect(s.role, isNull);
    });

    test('role survives a JSON round trip', () {
      final s = Staff(id: 1, name: 'X', role: StaffRole.authorAndArtist);
      expect(Staff.fromJson(s.toJson()).role, StaffRole.authorAndArtist);
    });
  });
}

import 'package:flutter/foundation.dart';

@immutable
class LibraryList {
  final int id;
  final String name;
  final bool isPrivate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LibraryList({
    required this.id,
    required this.name,
    required this.isPrivate,
    this.createdAt,
    this.updatedAt,
  });

  factory LibraryList.fromJson(Map<String, dynamic> json) {
    final id = switch (json['id']) {
      final num n => n.toInt(),
      final String s => int.tryParse(s),
      _ => null,
    };
    final name = json['name'];
    if (id == null || name is! String) {
      throw const FormatException('library list without id or name');
    }
    return LibraryList(
      id: id,
      name: name,
      isPrivate: json['is_private'] == true,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  LibraryList copyWith({String? name, bool? isPrivate}) => LibraryList(
    id: id,
    name: name ?? this.name,
    isPrivate: isPrivate ?? this.isPrivate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is LibraryList &&
      other.id == id &&
      other.name == name &&
      other.isPrivate == isPrivate &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, isPrivate, createdAt, updatedAt);
}

/// Mirrors the server's rules so a clash is caught before the request.
abstract final class LibraryListRules {
  static const int nameMax = 255;
  static const int listsPerSeriesMax = 30;
  static const int batchMax = 100;

  static final RegExp _whitespace = RegExp(r'[ \t\n\r\f\v ]+');

  static String normalize(String raw) =>
      raw.trim().replaceAll(_whitespace, ' ');

  static String key(String raw) => normalize(raw).toLowerCase();

  /// Null when [raw] is acceptable, otherwise an l10n key.
  static String? validate(
    String raw,
    Iterable<LibraryList> existing, {
    int? editingId,
  }) {
    final name = normalize(raw);
    if (name.isEmpty) return 'lists_error_name_empty';
    if (name.length > nameMax) return 'lists_error_name_long';
    final k = name.toLowerCase();
    final clash = existing.any((l) => l.id != editingId && key(l.name) == k);
    return clash ? 'lists_error_name_taken' : null;
  }
}

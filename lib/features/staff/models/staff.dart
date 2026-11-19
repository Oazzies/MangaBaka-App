enum StaffRole {
  author('staff_role_author'),
  artist('staff_role_artist'),
  authorAndArtist('staff_role_author_artist');

  final String labelKey;

  const StaffRole(this.labelKey);

  static StaffRole? tryParse(String? value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    return null;
  }

  StaffRole mergedWith(StaffRole other) =>
      this == other ? this : StaffRole.authorAndArtist;
}

class Staff {
  final int id;
  final String name;
  final String? nativeName;
  final StaffRole? role;
  final String? image;
  final int? seriesCount;
  final String? notes;

  Staff({
    required this.id,
    required this.name,
    this.nativeName,
    this.role,
    this.image,
    this.seriesCount,
    this.notes,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      nativeName: json['native_name']?.toString(),
      role: StaffRole.tryParse(json['role']?.toString()),
      image: json['image']?.toString(),
      seriesCount: json['series_count'] is num
          ? (json['series_count'] as num).toInt()
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'native_name': nativeName,
      'role': role?.name,
      'image': image,
      'series_count': seriesCount,
      'notes': notes,
    };
  }
}

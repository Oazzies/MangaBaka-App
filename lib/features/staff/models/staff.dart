class Staff {
  final int id;
  final String name;
  final String? nativeName;
  final String? role;
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
      id: json['id'] as int,
      name: json['name'] as String,
      nativeName: json['native_name'] as String?,
      role: json['role'] as String?,
      image: json['image'] as String?,
      seriesCount: json['series_count'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'native_name': nativeName,
      'role': role,
      'image': image,
      'series_count': seriesCount,
      'notes': notes,
    };
  }
}

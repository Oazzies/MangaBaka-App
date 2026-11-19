class Edition {
  final String id;
  final String name;
  final String description;

  const Edition({required this.id, required this.name, this.description = ''});

  factory Edition.fromJson(Map<String, dynamic> json) => Edition(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
  );
}

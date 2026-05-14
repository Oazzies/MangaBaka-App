class Publisher {
  final String id;
  final String type;
  final String subType;
  final List<PublisherAlias> aliases;
  final String? parentId;
  final String name;
  final List<PublisherLink> links;
  final Publisher? parent;
  final List<Publisher> imprints;
  final int? founded;
  final int? closed;
  final String? description;
  final String? note;

  Publisher({
    required this.id,
    required this.type,
    required this.subType,
    required this.aliases,
    this.parentId,
    required this.name,
    this.links = const [],
    this.parent,
    this.imprints = const [],
    this.founded,
    this.closed,
    this.description,
    this.note,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) {
    return Publisher(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      subType: json['sub_type'] ?? '',
      aliases: (json['aliases'] as List?)
              ?.map((a) => PublisherAlias.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      parentId: json['parent_id']?.toString(),
      name: json['name'] ?? '',
      links: (json['links'] as List?)
              ?.map((l) => PublisherLink.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      parent: json['parent'] != null ? Publisher.fromJson(json['parent'] as Map<String, dynamic>) : null,
      imprints: (json['imprints'] as List?)
              ?.map((i) => Publisher.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      founded: json['founded'] as int?,
      closed: json['closed'] as int?,
      description: json['description']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'sub_type': subType,
      'aliases': aliases.map((a) => a.toJson()).toList(),
      'parent_id': parentId,
      'name': name,
      'links': links.map((l) => l.toJson()).toList(),
      'parent': parent?.toJson(),
      'imprints': imprints.map((i) => i.toJson()).toList(),
      'founded': founded,
      'closed': closed,
      'description': description,
      'note': note,
    };
  }
}

class PublisherLink {
  final String type;
  final String link;
  final String language;

  PublisherLink({
    required this.type,
    required this.link,
    required this.language,
  });

  factory PublisherLink.fromJson(Map<String, dynamic> json) {
    return PublisherLink(
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      language: json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'link': link,
      'language': language,
    };
  }
}

class PublisherAlias {
  final String language;
  final String type;
  final String title;
  final String? note;

  PublisherAlias({
    required this.language,
    required this.type,
    required this.title,
    this.note,
  });

  factory PublisherAlias.fromJson(Map<String, dynamic> json) {
    return PublisherAlias(
      language: json['language'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'type': type,
      'title': title,
      'note': note,
    };
  }
}

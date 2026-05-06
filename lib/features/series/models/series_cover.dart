class SeriesCover {
  final String? type;
  final String? language;
  final String? note;
  final String? index;
  final String? url;
  final String? urlX150;
  final String? urlX250;
  final String? urlX350;

  SeriesCover({
    this.type,
    this.language,
    this.note,
    this.index,
    this.url,
    this.urlX150,
    this.urlX250,
    this.urlX350,
  });

  factory SeriesCover.fromJson(Map<String, dynamic> json) {
    return SeriesCover(
      type: json['type']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      note: json['note']?.toString(),
      index: json['index']?.toString() ?? '',
      url: json['image']?['raw']?['url']?.toString(),
      urlX150: json['image']?['x150']?['x1']?.toString(),
      urlX250: json['image']?['x250']?['x1']?.toString(),
      urlX350: json['image']?['x350']?['x1']?.toString(),
    );
  }
}

class SeriesWork {
  final String id;
  final int? seriesId;
  final String? seriesTitle;
  final String subTitle;
  final String countType;
  final String releaseDate;
  final String sequenceString;
  final int pages;
  final String? imageUrl;
  final String? priceString;

  SeriesWork({
    required this.id,
    this.seriesId,
    this.seriesTitle,
    required this.subTitle,
    required this.countType,
    required this.releaseDate,
    required this.sequenceString,
    required this.pages,
    this.imageUrl,
    this.priceString,
  });

  factory SeriesWork.fromJson(Map<String, dynamic> json) {
    String? img;
    final images = json['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final firstImg = images[0]['image'];
      img =
          firstImg?['x250']?['x1'] ??
          firstImg?['x150']?['x1'] ??
          firstImg?['raw']?['url'];
    }

    String? price;
    final prices = json['price'] as List?;
    if (prices != null && prices.isNotEmpty) {
      final p = prices[0];
      price = '${p['value']} ${p['iso_code']?.toString().toUpperCase()}';
    }

    String? seriesTitle;
    final collections = json['collections'] as List?;
    if (collections != null && collections.isNotEmpty) {
      seriesTitle = collections[0]['title']?.toString();
    }

    final sid = json['series_id'];
    final int? seriesId = sid is num
        ? sid.toInt()
        : (sid is String ? int.tryParse(sid) : null);

    return SeriesWork(
      id: json['id']?.toString() ?? '',
      seriesId: seriesId,
      seriesTitle: seriesTitle,
      subTitle: json['sub_title']?.toString() ?? '',
      countType: json['count_type']?.toString() ?? '',
      releaseDate: json['release_date']?.toString() ?? '',
      sequenceString: json['sequence_string']?.toString() ?? '',
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      imageUrl: img,
      priceString: price,
    );
  }
}

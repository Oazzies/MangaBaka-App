class SearchFilters {
  final List<String> type;
  final List<String> typeNot;
  final List<String> status;
  final List<String> statusNot;
  final List<String> genre;
  final List<String> genreNot;
  final List<String> tag;
  final List<String> tagNot;
  final String? sortBy;
  final double ratingLower;
  final double ratingUpper;
  final int? publishedYearLower;
  final int? publishedYearUpper;
  final bool? isLicensed;
  final String tagMode;

  SearchFilters({
    this.type = const [],
    this.typeNot = const [],
    this.status = const [],
    this.statusNot = const [],
    this.genre = const [],
    this.genreNot = const [],
    this.tag = const [],
    this.tagNot = const [],
    this.sortBy,
    this.ratingLower = 0,
    this.ratingUpper = 100,
    this.publishedYearLower,
    this.publishedYearUpper,
    this.isLicensed,
    this.tagMode = 'and',
  });

  SearchFilters copyWith({
    List<String>? type,
    List<String>? typeNot,
    List<String>? status,
    List<String>? statusNot,
    List<String>? genre,
    List<String>? genreNot,
    List<String>? tag,
    List<String>? tagNot,
    String? sortBy,
    double? ratingLower,
    double? ratingUpper,
    int? publishedYearLower,
    int? publishedYearUpper,
    bool? isLicensed,
    String? tagMode,
  }) {
    return SearchFilters(
      type: type ?? this.type,
      typeNot: typeNot ?? this.typeNot,
      status: status ?? this.status,
      statusNot: statusNot ?? this.statusNot,
      genre: genre ?? this.genre,
      genreNot: genreNot ?? this.genreNot,
      tag: tag ?? this.tag,
      tagNot: tagNot ?? this.tagNot,
      sortBy: sortBy ?? this.sortBy,
      ratingLower: ratingLower ?? this.ratingLower,
      ratingUpper: ratingUpper ?? this.ratingUpper,
      publishedYearLower: publishedYearLower ?? this.publishedYearLower,
      publishedYearUpper: publishedYearUpper ?? this.publishedYearUpper,
      isLicensed: isLicensed != null
          ? (isLicensed ? true : (this.isLicensed == false ? false : null))
          : this.isLicensed,
      tagMode: tagMode ?? this.tagMode,
    );
  }

  SearchFilters copyWithIsLicensed(bool? isLicensed) {
    return SearchFilters(
      type: type,
      typeNot: typeNot,
      status: status,
      statusNot: statusNot,
      genre: genre,
      genreNot: genreNot,
      tag: tag,
      tagNot: tagNot,
      sortBy: sortBy,
      ratingLower: ratingLower,
      ratingUpper: ratingUpper,
      publishedYearLower: publishedYearLower,
      publishedYearUpper: publishedYearUpper,
      isLicensed: isLicensed,
      tagMode: tagMode,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (type.isNotEmpty) map['type'] = type;
    if (typeNot.isNotEmpty) map['type_not'] = typeNot;
    if (status.isNotEmpty) map['status'] = status;
    if (statusNot.isNotEmpty) map['status_not'] = statusNot;
    if (genre.isNotEmpty) map['genre'] = genre;
    if (genreNot.isNotEmpty) map['genre_not'] = genreNot;
    if (tag.isNotEmpty) map['tag'] = tag;
    if (tagNot.isNotEmpty) map['tag_not'] = tagNot;

    if (sortBy != null && sortBy!.isNotEmpty) map['sort_by'] = sortBy;
    if (ratingLower > 0) map['rating_lower'] = ratingLower.toInt();
    if (ratingUpper < 100) map['rating_upper'] = ratingUpper.toInt();

    if (publishedYearLower != null) {
      map['published_start_date_lower'] = publishedYearLower.toString();
    }
    if (publishedYearUpper != null) {
      map['published_start_date_upper'] = publishedYearUpper.toString();
    }

    if (isLicensed != null) map['is_licensed'] = isLicensed;
    if (tagMode != 'and') map['tag_mode'] = tagMode;

    return map;
  }
}

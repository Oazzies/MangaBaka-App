// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mergedWithMeta = const VerificationMeta(
    'mergedWith',
  );
  @override
  late final GeneratedColumn<String> mergedWith = GeneratedColumn<String>(
    'merged_with',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nativeTitleMeta = const VerificationMeta(
    'nativeTitle',
  );
  @override
  late final GeneratedColumn<String> nativeTitle = GeneratedColumn<String>(
    'native_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _romanizedTitleMeta = const VerificationMeta(
    'romanizedTitle',
  );
  @override
  late final GeneratedColumn<String> romanizedTitle = GeneratedColumn<String>(
    'romanized_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryTitlesMeta = const VerificationMeta(
    'secondaryTitles',
  );
  @override
  late final GeneratedColumn<String> secondaryTitles = GeneratedColumn<String>(
    'secondary_titles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorsMeta = const VerificationMeta(
    'authors',
  );
  @override
  late final GeneratedColumn<String> authors = GeneratedColumn<String>(
    'authors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _artistsMeta = const VerificationMeta(
    'artists',
  );
  @override
  late final GeneratedColumn<String> artists = GeneratedColumn<String>(
    'artists',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedMeta = const VerificationMeta(
    'published',
  );
  @override
  late final GeneratedColumn<String> published = GeneratedColumn<String>(
    'published',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLicensedMeta = const VerificationMeta(
    'isLicensed',
  );
  @override
  late final GeneratedColumn<String> isLicensed = GeneratedColumn<String>(
    'is_licensed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasAnimeMeta = const VerificationMeta(
    'hasAnime',
  );
  @override
  late final GeneratedColumn<String> hasAnime = GeneratedColumn<String>(
    'has_anime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animeMeta = const VerificationMeta('anime');
  @override
  late final GeneratedColumn<String> anime = GeneratedColumn<String>(
    'anime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentRatingMeta = const VerificationMeta(
    'contentRating',
  );
  @override
  late final GeneratedColumn<String> contentRating = GeneratedColumn<String>(
    'content_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalVolumeMeta = const VerificationMeta(
    'finalVolume',
  );
  @override
  late final GeneratedColumn<String> finalVolume = GeneratedColumn<String>(
    'final_volume',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  @override
  late final GeneratedColumn<String> totalChapters = GeneratedColumn<String>(
    'total_chapters',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linksMeta = const VerificationMeta('links');
  @override
  late final GeneratedColumn<String> links = GeneratedColumn<String>(
    'links',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _publishersMeta = const VerificationMeta(
    'publishers',
  );
  @override
  late final GeneratedColumn<String> publishers = GeneratedColumn<String>(
    'publishers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relationshipsMeta = const VerificationMeta(
    'relationships',
  );
  @override
  late final GeneratedColumn<String> relationships = GeneratedColumn<String>(
    'relationships',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    state,
    mergedWith,
    title,
    nativeTitle,
    romanizedTitle,
    secondaryTitles,
    coverUrl,
    authors,
    artists,
    description,
    year,
    published,
    status,
    isLicensed,
    hasAnime,
    anime,
    contentRating,
    type,
    rating,
    finalVolume,
    totalChapters,
    links,
    publishers,
    genres,
    tags,
    lastUpdated,
    relationships,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('merged_with')) {
      context.handle(
        _mergedWithMeta,
        mergedWith.isAcceptableOrUnknown(data['merged_with']!, _mergedWithMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('native_title')) {
      context.handle(
        _nativeTitleMeta,
        nativeTitle.isAcceptableOrUnknown(
          data['native_title']!,
          _nativeTitleMeta,
        ),
      );
    }
    if (data.containsKey('romanized_title')) {
      context.handle(
        _romanizedTitleMeta,
        romanizedTitle.isAcceptableOrUnknown(
          data['romanized_title']!,
          _romanizedTitleMeta,
        ),
      );
    }
    if (data.containsKey('secondary_titles')) {
      context.handle(
        _secondaryTitlesMeta,
        secondaryTitles.isAcceptableOrUnknown(
          data['secondary_titles']!,
          _secondaryTitlesMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('authors')) {
      context.handle(
        _authorsMeta,
        authors.isAcceptableOrUnknown(data['authors']!, _authorsMeta),
      );
    }
    if (data.containsKey('artists')) {
      context.handle(
        _artistsMeta,
        artists.isAcceptableOrUnknown(data['artists']!, _artistsMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('published')) {
      context.handle(
        _publishedMeta,
        published.isAcceptableOrUnknown(data['published']!, _publishedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('is_licensed')) {
      context.handle(
        _isLicensedMeta,
        isLicensed.isAcceptableOrUnknown(data['is_licensed']!, _isLicensedMeta),
      );
    }
    if (data.containsKey('has_anime')) {
      context.handle(
        _hasAnimeMeta,
        hasAnime.isAcceptableOrUnknown(data['has_anime']!, _hasAnimeMeta),
      );
    }
    if (data.containsKey('anime')) {
      context.handle(
        _animeMeta,
        anime.isAcceptableOrUnknown(data['anime']!, _animeMeta),
      );
    }
    if (data.containsKey('content_rating')) {
      context.handle(
        _contentRatingMeta,
        contentRating.isAcceptableOrUnknown(
          data['content_rating']!,
          _contentRatingMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('final_volume')) {
      context.handle(
        _finalVolumeMeta,
        finalVolume.isAcceptableOrUnknown(
          data['final_volume']!,
          _finalVolumeMeta,
        ),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('links')) {
      context.handle(
        _linksMeta,
        links.isAcceptableOrUnknown(data['links']!, _linksMeta),
      );
    }
    if (data.containsKey('publishers')) {
      context.handle(
        _publishersMeta,
        publishers.isAcceptableOrUnknown(data['publishers']!, _publishersMeta),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('relationships')) {
      context.handle(
        _relationshipsMeta,
        relationships.isAcceptableOrUnknown(
          data['relationships']!,
          _relationshipsMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      mergedWith: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_with'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      nativeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_title'],
      ),
      romanizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}romanized_title'],
      ),
      secondaryTitles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_titles'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      )!,
      authors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authors'],
      )!,
      artists: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artists'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      published: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      isLicensed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}is_licensed'],
      ),
      hasAnime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}has_anime'],
      ),
      anime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime'],
      ),
      contentRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_rating'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      finalVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_volume'],
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total_chapters'],
      ),
      links: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}links'],
      )!,
      publishers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publishers'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      ),
      relationships: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationships'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesTableData extends DataClass implements Insertable<SeriesTableData> {
  final String id;
  final String? state;
  final String? mergedWith;
  final String title;
  final String? nativeTitle;
  final String? romanizedTitle;
  final String secondaryTitles;
  final String coverUrl;
  final String authors;
  final String artists;
  final String description;
  final String? year;
  final String? published;
  final String? status;
  final String? isLicensed;
  final String? hasAnime;
  final String? anime;
  final String? contentRating;
  final String? type;
  final String? rating;
  final String? finalVolume;
  final String? totalChapters;
  final String links;
  final String publishers;
  final String genres;
  final String tags;
  final String? lastUpdated;
  final String? relationships;
  final String? source;
  const SeriesTableData({
    required this.id,
    this.state,
    this.mergedWith,
    required this.title,
    this.nativeTitle,
    this.romanizedTitle,
    required this.secondaryTitles,
    required this.coverUrl,
    required this.authors,
    required this.artists,
    required this.description,
    this.year,
    this.published,
    this.status,
    this.isLicensed,
    this.hasAnime,
    this.anime,
    this.contentRating,
    this.type,
    this.rating,
    this.finalVolume,
    this.totalChapters,
    required this.links,
    required this.publishers,
    required this.genres,
    required this.tags,
    this.lastUpdated,
    this.relationships,
    this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || mergedWith != null) {
      map['merged_with'] = Variable<String>(mergedWith);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || nativeTitle != null) {
      map['native_title'] = Variable<String>(nativeTitle);
    }
    if (!nullToAbsent || romanizedTitle != null) {
      map['romanized_title'] = Variable<String>(romanizedTitle);
    }
    map['secondary_titles'] = Variable<String>(secondaryTitles);
    map['cover_url'] = Variable<String>(coverUrl);
    map['authors'] = Variable<String>(authors);
    map['artists'] = Variable<String>(artists);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || published != null) {
      map['published'] = Variable<String>(published);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || isLicensed != null) {
      map['is_licensed'] = Variable<String>(isLicensed);
    }
    if (!nullToAbsent || hasAnime != null) {
      map['has_anime'] = Variable<String>(hasAnime);
    }
    if (!nullToAbsent || anime != null) {
      map['anime'] = Variable<String>(anime);
    }
    if (!nullToAbsent || contentRating != null) {
      map['content_rating'] = Variable<String>(contentRating);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || finalVolume != null) {
      map['final_volume'] = Variable<String>(finalVolume);
    }
    if (!nullToAbsent || totalChapters != null) {
      map['total_chapters'] = Variable<String>(totalChapters);
    }
    map['links'] = Variable<String>(links);
    map['publishers'] = Variable<String>(publishers);
    map['genres'] = Variable<String>(genres);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<String>(lastUpdated);
    }
    if (!nullToAbsent || relationships != null) {
      map['relationships'] = Variable<String>(relationships);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      mergedWith: mergedWith == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedWith),
      title: Value(title),
      nativeTitle: nativeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(nativeTitle),
      romanizedTitle: romanizedTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(romanizedTitle),
      secondaryTitles: Value(secondaryTitles),
      coverUrl: Value(coverUrl),
      authors: Value(authors),
      artists: Value(artists),
      description: Value(description),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      published: published == null && nullToAbsent
          ? const Value.absent()
          : Value(published),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      isLicensed: isLicensed == null && nullToAbsent
          ? const Value.absent()
          : Value(isLicensed),
      hasAnime: hasAnime == null && nullToAbsent
          ? const Value.absent()
          : Value(hasAnime),
      anime: anime == null && nullToAbsent
          ? const Value.absent()
          : Value(anime),
      contentRating: contentRating == null && nullToAbsent
          ? const Value.absent()
          : Value(contentRating),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      finalVolume: finalVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(finalVolume),
      totalChapters: totalChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalChapters),
      links: Value(links),
      publishers: Value(publishers),
      genres: Value(genres),
      tags: Value(tags),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
      relationships: relationships == null && nullToAbsent
          ? const Value.absent()
          : Value(relationships),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
    );
  }

  factory SeriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesTableData(
      id: serializer.fromJson<String>(json['id']),
      state: serializer.fromJson<String?>(json['state']),
      mergedWith: serializer.fromJson<String?>(json['mergedWith']),
      title: serializer.fromJson<String>(json['title']),
      nativeTitle: serializer.fromJson<String?>(json['nativeTitle']),
      romanizedTitle: serializer.fromJson<String?>(json['romanizedTitle']),
      secondaryTitles: serializer.fromJson<String>(json['secondaryTitles']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      authors: serializer.fromJson<String>(json['authors']),
      artists: serializer.fromJson<String>(json['artists']),
      description: serializer.fromJson<String>(json['description']),
      year: serializer.fromJson<String?>(json['year']),
      published: serializer.fromJson<String?>(json['published']),
      status: serializer.fromJson<String?>(json['status']),
      isLicensed: serializer.fromJson<String?>(json['isLicensed']),
      hasAnime: serializer.fromJson<String?>(json['hasAnime']),
      anime: serializer.fromJson<String?>(json['anime']),
      contentRating: serializer.fromJson<String?>(json['contentRating']),
      type: serializer.fromJson<String?>(json['type']),
      rating: serializer.fromJson<String?>(json['rating']),
      finalVolume: serializer.fromJson<String?>(json['finalVolume']),
      totalChapters: serializer.fromJson<String?>(json['totalChapters']),
      links: serializer.fromJson<String>(json['links']),
      publishers: serializer.fromJson<String>(json['publishers']),
      genres: serializer.fromJson<String>(json['genres']),
      tags: serializer.fromJson<String>(json['tags']),
      lastUpdated: serializer.fromJson<String?>(json['lastUpdated']),
      relationships: serializer.fromJson<String?>(json['relationships']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'state': serializer.toJson<String?>(state),
      'mergedWith': serializer.toJson<String?>(mergedWith),
      'title': serializer.toJson<String>(title),
      'nativeTitle': serializer.toJson<String?>(nativeTitle),
      'romanizedTitle': serializer.toJson<String?>(romanizedTitle),
      'secondaryTitles': serializer.toJson<String>(secondaryTitles),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'authors': serializer.toJson<String>(authors),
      'artists': serializer.toJson<String>(artists),
      'description': serializer.toJson<String>(description),
      'year': serializer.toJson<String?>(year),
      'published': serializer.toJson<String?>(published),
      'status': serializer.toJson<String?>(status),
      'isLicensed': serializer.toJson<String?>(isLicensed),
      'hasAnime': serializer.toJson<String?>(hasAnime),
      'anime': serializer.toJson<String?>(anime),
      'contentRating': serializer.toJson<String?>(contentRating),
      'type': serializer.toJson<String?>(type),
      'rating': serializer.toJson<String?>(rating),
      'finalVolume': serializer.toJson<String?>(finalVolume),
      'totalChapters': serializer.toJson<String?>(totalChapters),
      'links': serializer.toJson<String>(links),
      'publishers': serializer.toJson<String>(publishers),
      'genres': serializer.toJson<String>(genres),
      'tags': serializer.toJson<String>(tags),
      'lastUpdated': serializer.toJson<String?>(lastUpdated),
      'relationships': serializer.toJson<String?>(relationships),
      'source': serializer.toJson<String?>(source),
    };
  }

  SeriesTableData copyWith({
    String? id,
    Value<String?> state = const Value.absent(),
    Value<String?> mergedWith = const Value.absent(),
    String? title,
    Value<String?> nativeTitle = const Value.absent(),
    Value<String?> romanizedTitle = const Value.absent(),
    String? secondaryTitles,
    String? coverUrl,
    String? authors,
    String? artists,
    String? description,
    Value<String?> year = const Value.absent(),
    Value<String?> published = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> isLicensed = const Value.absent(),
    Value<String?> hasAnime = const Value.absent(),
    Value<String?> anime = const Value.absent(),
    Value<String?> contentRating = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<String?> finalVolume = const Value.absent(),
    Value<String?> totalChapters = const Value.absent(),
    String? links,
    String? publishers,
    String? genres,
    String? tags,
    Value<String?> lastUpdated = const Value.absent(),
    Value<String?> relationships = const Value.absent(),
    Value<String?> source = const Value.absent(),
  }) => SeriesTableData(
    id: id ?? this.id,
    state: state.present ? state.value : this.state,
    mergedWith: mergedWith.present ? mergedWith.value : this.mergedWith,
    title: title ?? this.title,
    nativeTitle: nativeTitle.present ? nativeTitle.value : this.nativeTitle,
    romanizedTitle: romanizedTitle.present
        ? romanizedTitle.value
        : this.romanizedTitle,
    secondaryTitles: secondaryTitles ?? this.secondaryTitles,
    coverUrl: coverUrl ?? this.coverUrl,
    authors: authors ?? this.authors,
    artists: artists ?? this.artists,
    description: description ?? this.description,
    year: year.present ? year.value : this.year,
    published: published.present ? published.value : this.published,
    status: status.present ? status.value : this.status,
    isLicensed: isLicensed.present ? isLicensed.value : this.isLicensed,
    hasAnime: hasAnime.present ? hasAnime.value : this.hasAnime,
    anime: anime.present ? anime.value : this.anime,
    contentRating: contentRating.present
        ? contentRating.value
        : this.contentRating,
    type: type.present ? type.value : this.type,
    rating: rating.present ? rating.value : this.rating,
    finalVolume: finalVolume.present ? finalVolume.value : this.finalVolume,
    totalChapters: totalChapters.present
        ? totalChapters.value
        : this.totalChapters,
    links: links ?? this.links,
    publishers: publishers ?? this.publishers,
    genres: genres ?? this.genres,
    tags: tags ?? this.tags,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
    relationships: relationships.present
        ? relationships.value
        : this.relationships,
    source: source.present ? source.value : this.source,
  );
  SeriesTableData copyWithCompanion(SeriesTableCompanion data) {
    return SeriesTableData(
      id: data.id.present ? data.id.value : this.id,
      state: data.state.present ? data.state.value : this.state,
      mergedWith: data.mergedWith.present
          ? data.mergedWith.value
          : this.mergedWith,
      title: data.title.present ? data.title.value : this.title,
      nativeTitle: data.nativeTitle.present
          ? data.nativeTitle.value
          : this.nativeTitle,
      romanizedTitle: data.romanizedTitle.present
          ? data.romanizedTitle.value
          : this.romanizedTitle,
      secondaryTitles: data.secondaryTitles.present
          ? data.secondaryTitles.value
          : this.secondaryTitles,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      authors: data.authors.present ? data.authors.value : this.authors,
      artists: data.artists.present ? data.artists.value : this.artists,
      description: data.description.present
          ? data.description.value
          : this.description,
      year: data.year.present ? data.year.value : this.year,
      published: data.published.present ? data.published.value : this.published,
      status: data.status.present ? data.status.value : this.status,
      isLicensed: data.isLicensed.present
          ? data.isLicensed.value
          : this.isLicensed,
      hasAnime: data.hasAnime.present ? data.hasAnime.value : this.hasAnime,
      anime: data.anime.present ? data.anime.value : this.anime,
      contentRating: data.contentRating.present
          ? data.contentRating.value
          : this.contentRating,
      type: data.type.present ? data.type.value : this.type,
      rating: data.rating.present ? data.rating.value : this.rating,
      finalVolume: data.finalVolume.present
          ? data.finalVolume.value
          : this.finalVolume,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      links: data.links.present ? data.links.value : this.links,
      publishers: data.publishers.present
          ? data.publishers.value
          : this.publishers,
      genres: data.genres.present ? data.genres.value : this.genres,
      tags: data.tags.present ? data.tags.value : this.tags,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      relationships: data.relationships.present
          ? data.relationships.value
          : this.relationships,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableData(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('mergedWith: $mergedWith, ')
          ..write('title: $title, ')
          ..write('nativeTitle: $nativeTitle, ')
          ..write('romanizedTitle: $romanizedTitle, ')
          ..write('secondaryTitles: $secondaryTitles, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('authors: $authors, ')
          ..write('artists: $artists, ')
          ..write('description: $description, ')
          ..write('year: $year, ')
          ..write('published: $published, ')
          ..write('status: $status, ')
          ..write('isLicensed: $isLicensed, ')
          ..write('hasAnime: $hasAnime, ')
          ..write('anime: $anime, ')
          ..write('contentRating: $contentRating, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('finalVolume: $finalVolume, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('links: $links, ')
          ..write('publishers: $publishers, ')
          ..write('genres: $genres, ')
          ..write('tags: $tags, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('relationships: $relationships, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    state,
    mergedWith,
    title,
    nativeTitle,
    romanizedTitle,
    secondaryTitles,
    coverUrl,
    authors,
    artists,
    description,
    year,
    published,
    status,
    isLicensed,
    hasAnime,
    anime,
    contentRating,
    type,
    rating,
    finalVolume,
    totalChapters,
    links,
    publishers,
    genres,
    tags,
    lastUpdated,
    relationships,
    source,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesTableData &&
          other.id == this.id &&
          other.state == this.state &&
          other.mergedWith == this.mergedWith &&
          other.title == this.title &&
          other.nativeTitle == this.nativeTitle &&
          other.romanizedTitle == this.romanizedTitle &&
          other.secondaryTitles == this.secondaryTitles &&
          other.coverUrl == this.coverUrl &&
          other.authors == this.authors &&
          other.artists == this.artists &&
          other.description == this.description &&
          other.year == this.year &&
          other.published == this.published &&
          other.status == this.status &&
          other.isLicensed == this.isLicensed &&
          other.hasAnime == this.hasAnime &&
          other.anime == this.anime &&
          other.contentRating == this.contentRating &&
          other.type == this.type &&
          other.rating == this.rating &&
          other.finalVolume == this.finalVolume &&
          other.totalChapters == this.totalChapters &&
          other.links == this.links &&
          other.publishers == this.publishers &&
          other.genres == this.genres &&
          other.tags == this.tags &&
          other.lastUpdated == this.lastUpdated &&
          other.relationships == this.relationships &&
          other.source == this.source);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesTableData> {
  final Value<String> id;
  final Value<String?> state;
  final Value<String?> mergedWith;
  final Value<String> title;
  final Value<String?> nativeTitle;
  final Value<String?> romanizedTitle;
  final Value<String> secondaryTitles;
  final Value<String> coverUrl;
  final Value<String> authors;
  final Value<String> artists;
  final Value<String> description;
  final Value<String?> year;
  final Value<String?> published;
  final Value<String?> status;
  final Value<String?> isLicensed;
  final Value<String?> hasAnime;
  final Value<String?> anime;
  final Value<String?> contentRating;
  final Value<String?> type;
  final Value<String?> rating;
  final Value<String?> finalVolume;
  final Value<String?> totalChapters;
  final Value<String> links;
  final Value<String> publishers;
  final Value<String> genres;
  final Value<String> tags;
  final Value<String?> lastUpdated;
  final Value<String?> relationships;
  final Value<String?> source;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.state = const Value.absent(),
    this.mergedWith = const Value.absent(),
    this.title = const Value.absent(),
    this.nativeTitle = const Value.absent(),
    this.romanizedTitle = const Value.absent(),
    this.secondaryTitles = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.authors = const Value.absent(),
    this.artists = const Value.absent(),
    this.description = const Value.absent(),
    this.year = const Value.absent(),
    this.published = const Value.absent(),
    this.status = const Value.absent(),
    this.isLicensed = const Value.absent(),
    this.hasAnime = const Value.absent(),
    this.anime = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.type = const Value.absent(),
    this.rating = const Value.absent(),
    this.finalVolume = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.links = const Value.absent(),
    this.publishers = const Value.absent(),
    this.genres = const Value.absent(),
    this.tags = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.relationships = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String id,
    this.state = const Value.absent(),
    this.mergedWith = const Value.absent(),
    required String title,
    this.nativeTitle = const Value.absent(),
    this.romanizedTitle = const Value.absent(),
    this.secondaryTitles = const Value.absent(),
    required String coverUrl,
    this.authors = const Value.absent(),
    this.artists = const Value.absent(),
    required String description,
    this.year = const Value.absent(),
    this.published = const Value.absent(),
    this.status = const Value.absent(),
    this.isLicensed = const Value.absent(),
    this.hasAnime = const Value.absent(),
    this.anime = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.type = const Value.absent(),
    this.rating = const Value.absent(),
    this.finalVolume = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.links = const Value.absent(),
    this.publishers = const Value.absent(),
    this.genres = const Value.absent(),
    this.tags = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.relationships = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       coverUrl = Value(coverUrl),
       description = Value(description);
  static Insertable<SeriesTableData> custom({
    Expression<String>? id,
    Expression<String>? state,
    Expression<String>? mergedWith,
    Expression<String>? title,
    Expression<String>? nativeTitle,
    Expression<String>? romanizedTitle,
    Expression<String>? secondaryTitles,
    Expression<String>? coverUrl,
    Expression<String>? authors,
    Expression<String>? artists,
    Expression<String>? description,
    Expression<String>? year,
    Expression<String>? published,
    Expression<String>? status,
    Expression<String>? isLicensed,
    Expression<String>? hasAnime,
    Expression<String>? anime,
    Expression<String>? contentRating,
    Expression<String>? type,
    Expression<String>? rating,
    Expression<String>? finalVolume,
    Expression<String>? totalChapters,
    Expression<String>? links,
    Expression<String>? publishers,
    Expression<String>? genres,
    Expression<String>? tags,
    Expression<String>? lastUpdated,
    Expression<String>? relationships,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (state != null) 'state': state,
      if (mergedWith != null) 'merged_with': mergedWith,
      if (title != null) 'title': title,
      if (nativeTitle != null) 'native_title': nativeTitle,
      if (romanizedTitle != null) 'romanized_title': romanizedTitle,
      if (secondaryTitles != null) 'secondary_titles': secondaryTitles,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (authors != null) 'authors': authors,
      if (artists != null) 'artists': artists,
      if (description != null) 'description': description,
      if (year != null) 'year': year,
      if (published != null) 'published': published,
      if (status != null) 'status': status,
      if (isLicensed != null) 'is_licensed': isLicensed,
      if (hasAnime != null) 'has_anime': hasAnime,
      if (anime != null) 'anime': anime,
      if (contentRating != null) 'content_rating': contentRating,
      if (type != null) 'type': type,
      if (rating != null) 'rating': rating,
      if (finalVolume != null) 'final_volume': finalVolume,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (links != null) 'links': links,
      if (publishers != null) 'publishers': publishers,
      if (genres != null) 'genres': genres,
      if (tags != null) 'tags': tags,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (relationships != null) 'relationships': relationships,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? state,
    Value<String?>? mergedWith,
    Value<String>? title,
    Value<String?>? nativeTitle,
    Value<String?>? romanizedTitle,
    Value<String>? secondaryTitles,
    Value<String>? coverUrl,
    Value<String>? authors,
    Value<String>? artists,
    Value<String>? description,
    Value<String?>? year,
    Value<String?>? published,
    Value<String?>? status,
    Value<String?>? isLicensed,
    Value<String?>? hasAnime,
    Value<String?>? anime,
    Value<String?>? contentRating,
    Value<String?>? type,
    Value<String?>? rating,
    Value<String?>? finalVolume,
    Value<String?>? totalChapters,
    Value<String>? links,
    Value<String>? publishers,
    Value<String>? genres,
    Value<String>? tags,
    Value<String?>? lastUpdated,
    Value<String?>? relationships,
    Value<String?>? source,
    Value<int>? rowid,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      state: state ?? this.state,
      mergedWith: mergedWith ?? this.mergedWith,
      title: title ?? this.title,
      nativeTitle: nativeTitle ?? this.nativeTitle,
      romanizedTitle: romanizedTitle ?? this.romanizedTitle,
      secondaryTitles: secondaryTitles ?? this.secondaryTitles,
      coverUrl: coverUrl ?? this.coverUrl,
      authors: authors ?? this.authors,
      artists: artists ?? this.artists,
      description: description ?? this.description,
      year: year ?? this.year,
      published: published ?? this.published,
      status: status ?? this.status,
      isLicensed: isLicensed ?? this.isLicensed,
      hasAnime: hasAnime ?? this.hasAnime,
      anime: anime ?? this.anime,
      contentRating: contentRating ?? this.contentRating,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      finalVolume: finalVolume ?? this.finalVolume,
      totalChapters: totalChapters ?? this.totalChapters,
      links: links ?? this.links,
      publishers: publishers ?? this.publishers,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      relationships: relationships ?? this.relationships,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (mergedWith.present) {
      map['merged_with'] = Variable<String>(mergedWith.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (nativeTitle.present) {
      map['native_title'] = Variable<String>(nativeTitle.value);
    }
    if (romanizedTitle.present) {
      map['romanized_title'] = Variable<String>(romanizedTitle.value);
    }
    if (secondaryTitles.present) {
      map['secondary_titles'] = Variable<String>(secondaryTitles.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(authors.value);
    }
    if (artists.present) {
      map['artists'] = Variable<String>(artists.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (published.present) {
      map['published'] = Variable<String>(published.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isLicensed.present) {
      map['is_licensed'] = Variable<String>(isLicensed.value);
    }
    if (hasAnime.present) {
      map['has_anime'] = Variable<String>(hasAnime.value);
    }
    if (anime.present) {
      map['anime'] = Variable<String>(anime.value);
    }
    if (contentRating.present) {
      map['content_rating'] = Variable<String>(contentRating.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (finalVolume.present) {
      map['final_volume'] = Variable<String>(finalVolume.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<String>(totalChapters.value);
    }
    if (links.present) {
      map['links'] = Variable<String>(links.value);
    }
    if (publishers.present) {
      map['publishers'] = Variable<String>(publishers.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (relationships.present) {
      map['relationships'] = Variable<String>(relationships.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('mergedWith: $mergedWith, ')
          ..write('title: $title, ')
          ..write('nativeTitle: $nativeTitle, ')
          ..write('romanizedTitle: $romanizedTitle, ')
          ..write('secondaryTitles: $secondaryTitles, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('authors: $authors, ')
          ..write('artists: $artists, ')
          ..write('description: $description, ')
          ..write('year: $year, ')
          ..write('published: $published, ')
          ..write('status: $status, ')
          ..write('isLicensed: $isLicensed, ')
          ..write('hasAnime: $hasAnime, ')
          ..write('anime: $anime, ')
          ..write('contentRating: $contentRating, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('finalVolume: $finalVolume, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('links: $links, ')
          ..write('publishers: $publishers, ')
          ..write('genres: $genres, ')
          ..write('tags: $tags, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('relationships: $relationships, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryEntriesTableTable extends LibraryEntriesTable
    with TableInfo<$LibraryEntriesTableTable, LibraryEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressChapterMeta = const VerificationMeta(
    'progressChapter',
  );
  @override
  late final GeneratedColumn<int> progressChapter = GeneratedColumn<int>(
    'progress_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressVolumeMeta = const VerificationMeta(
    'progressVolume',
  );
  @override
  late final GeneratedColumn<int> progressVolume = GeneratedColumn<int>(
    'progress_volume',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfRereadsMeta = const VerificationMeta(
    'numberOfRereads',
  );
  @override
  late final GeneratedColumn<int> numberOfRereads = GeneratedColumn<int>(
    'number_of_rereads',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES series_table (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    state,
    note,
    progressChapter,
    progressVolume,
    numberOfRereads,
    rating,
    seriesId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('progress_chapter')) {
      context.handle(
        _progressChapterMeta,
        progressChapter.isAcceptableOrUnknown(
          data['progress_chapter']!,
          _progressChapterMeta,
        ),
      );
    }
    if (data.containsKey('progress_volume')) {
      context.handle(
        _progressVolumeMeta,
        progressVolume.isAcceptableOrUnknown(
          data['progress_volume']!,
          _progressVolumeMeta,
        ),
      );
    }
    if (data.containsKey('number_of_rereads')) {
      context.handle(
        _numberOfRereadsMeta,
        numberOfRereads.isAcceptableOrUnknown(
          data['number_of_rereads']!,
          _numberOfRereadsMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      progressChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_chapter'],
      ),
      progressVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress_volume'],
      ),
      numberOfRereads: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_rereads'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
    );
  }

  @override
  $LibraryEntriesTableTable createAlias(String alias) {
    return $LibraryEntriesTableTable(attachedDatabase, alias);
  }
}

class LibraryEntriesTableData extends DataClass
    implements Insertable<LibraryEntriesTableData> {
  final String id;
  final String state;
  final String? note;
  final int? progressChapter;
  final int? progressVolume;
  final int? numberOfRereads;
  final int? rating;
  final String seriesId;
  const LibraryEntriesTableData({
    required this.id,
    required this.state,
    this.note,
    this.progressChapter,
    this.progressVolume,
    this.numberOfRereads,
    this.rating,
    required this.seriesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || progressChapter != null) {
      map['progress_chapter'] = Variable<int>(progressChapter);
    }
    if (!nullToAbsent || progressVolume != null) {
      map['progress_volume'] = Variable<int>(progressVolume);
    }
    if (!nullToAbsent || numberOfRereads != null) {
      map['number_of_rereads'] = Variable<int>(numberOfRereads);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['series_id'] = Variable<String>(seriesId);
    return map;
  }

  LibraryEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesTableCompanion(
      id: Value(id),
      state: Value(state),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      progressChapter: progressChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(progressChapter),
      progressVolume: progressVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(progressVolume),
      numberOfRereads: numberOfRereads == null && nullToAbsent
          ? const Value.absent()
          : Value(numberOfRereads),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      seriesId: Value(seriesId),
    );
  }

  factory LibraryEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      state: serializer.fromJson<String>(json['state']),
      note: serializer.fromJson<String?>(json['note']),
      progressChapter: serializer.fromJson<int?>(json['progressChapter']),
      progressVolume: serializer.fromJson<int?>(json['progressVolume']),
      numberOfRereads: serializer.fromJson<int?>(json['numberOfRereads']),
      rating: serializer.fromJson<int?>(json['rating']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'state': serializer.toJson<String>(state),
      'note': serializer.toJson<String?>(note),
      'progressChapter': serializer.toJson<int?>(progressChapter),
      'progressVolume': serializer.toJson<int?>(progressVolume),
      'numberOfRereads': serializer.toJson<int?>(numberOfRereads),
      'rating': serializer.toJson<int?>(rating),
      'seriesId': serializer.toJson<String>(seriesId),
    };
  }

  LibraryEntriesTableData copyWith({
    String? id,
    String? state,
    Value<String?> note = const Value.absent(),
    Value<int?> progressChapter = const Value.absent(),
    Value<int?> progressVolume = const Value.absent(),
    Value<int?> numberOfRereads = const Value.absent(),
    Value<int?> rating = const Value.absent(),
    String? seriesId,
  }) => LibraryEntriesTableData(
    id: id ?? this.id,
    state: state ?? this.state,
    note: note.present ? note.value : this.note,
    progressChapter: progressChapter.present
        ? progressChapter.value
        : this.progressChapter,
    progressVolume: progressVolume.present
        ? progressVolume.value
        : this.progressVolume,
    numberOfRereads: numberOfRereads.present
        ? numberOfRereads.value
        : this.numberOfRereads,
    rating: rating.present ? rating.value : this.rating,
    seriesId: seriesId ?? this.seriesId,
  );
  LibraryEntriesTableData copyWithCompanion(LibraryEntriesTableCompanion data) {
    return LibraryEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      state: data.state.present ? data.state.value : this.state,
      note: data.note.present ? data.note.value : this.note,
      progressChapter: data.progressChapter.present
          ? data.progressChapter.value
          : this.progressChapter,
      progressVolume: data.progressVolume.present
          ? data.progressVolume.value
          : this.progressVolume,
      numberOfRereads: data.numberOfRereads.present
          ? data.numberOfRereads.value
          : this.numberOfRereads,
      rating: data.rating.present ? data.rating.value : this.rating,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesTableData(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('note: $note, ')
          ..write('progressChapter: $progressChapter, ')
          ..write('progressVolume: $progressVolume, ')
          ..write('numberOfRereads: $numberOfRereads, ')
          ..write('rating: $rating, ')
          ..write('seriesId: $seriesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    state,
    note,
    progressChapter,
    progressVolume,
    numberOfRereads,
    rating,
    seriesId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntriesTableData &&
          other.id == this.id &&
          other.state == this.state &&
          other.note == this.note &&
          other.progressChapter == this.progressChapter &&
          other.progressVolume == this.progressVolume &&
          other.numberOfRereads == this.numberOfRereads &&
          other.rating == this.rating &&
          other.seriesId == this.seriesId);
}

class LibraryEntriesTableCompanion
    extends UpdateCompanion<LibraryEntriesTableData> {
  final Value<String> id;
  final Value<String> state;
  final Value<String?> note;
  final Value<int?> progressChapter;
  final Value<int?> progressVolume;
  final Value<int?> numberOfRereads;
  final Value<int?> rating;
  final Value<String> seriesId;
  final Value<int> rowid;
  const LibraryEntriesTableCompanion({
    this.id = const Value.absent(),
    this.state = const Value.absent(),
    this.note = const Value.absent(),
    this.progressChapter = const Value.absent(),
    this.progressVolume = const Value.absent(),
    this.numberOfRereads = const Value.absent(),
    this.rating = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryEntriesTableCompanion.insert({
    required String id,
    required String state,
    this.note = const Value.absent(),
    this.progressChapter = const Value.absent(),
    this.progressVolume = const Value.absent(),
    this.numberOfRereads = const Value.absent(),
    this.rating = const Value.absent(),
    required String seriesId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       state = Value(state),
       seriesId = Value(seriesId);
  static Insertable<LibraryEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? state,
    Expression<String>? note,
    Expression<int>? progressChapter,
    Expression<int>? progressVolume,
    Expression<int>? numberOfRereads,
    Expression<int>? rating,
    Expression<String>? seriesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (state != null) 'state': state,
      if (note != null) 'note': note,
      if (progressChapter != null) 'progress_chapter': progressChapter,
      if (progressVolume != null) 'progress_volume': progressVolume,
      if (numberOfRereads != null) 'number_of_rereads': numberOfRereads,
      if (rating != null) 'rating': rating,
      if (seriesId != null) 'series_id': seriesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? state,
    Value<String?>? note,
    Value<int?>? progressChapter,
    Value<int?>? progressVolume,
    Value<int?>? numberOfRereads,
    Value<int?>? rating,
    Value<String>? seriesId,
    Value<int>? rowid,
  }) {
    return LibraryEntriesTableCompanion(
      id: id ?? this.id,
      state: state ?? this.state,
      note: note ?? this.note,
      progressChapter: progressChapter ?? this.progressChapter,
      progressVolume: progressVolume ?? this.progressVolume,
      numberOfRereads: numberOfRereads ?? this.numberOfRereads,
      rating: rating ?? this.rating,
      seriesId: seriesId ?? this.seriesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (progressChapter.present) {
      map['progress_chapter'] = Variable<int>(progressChapter.value);
    }
    if (progressVolume.present) {
      map['progress_volume'] = Variable<int>(progressVolume.value);
    }
    if (numberOfRereads.present) {
      map['number_of_rereads'] = Variable<int>(numberOfRereads.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('note: $note, ')
          ..write('progressChapter: $progressChapter, ')
          ..write('progressVolume: $progressVolume, ')
          ..write('numberOfRereads: $numberOfRereads, ')
          ..write('rating: $rating, ')
          ..write('seriesId: $seriesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryListsTableTable extends LibraryListsTable
    with TableInfo<$LibraryListsTableTable, LibraryListsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryListsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrivateMeta = const VerificationMeta(
    'isPrivate',
  );
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
    'is_private',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_private" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isPrivate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_lists_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryListsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_private')) {
      context.handle(
        _isPrivateMeta,
        isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryListsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryListsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isPrivate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_private'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LibraryListsTableTable createAlias(String alias) {
    return $LibraryListsTableTable(attachedDatabase, alias);
  }
}

class LibraryListsTableData extends DataClass
    implements Insertable<LibraryListsTableData> {
  final int id;
  final String name;
  final bool isPrivate;
  final String? createdAt;
  final String? updatedAt;
  const LibraryListsTableData({
    required this.id,
    required this.name,
    required this.isPrivate,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_private'] = Variable<bool>(isPrivate);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  LibraryListsTableCompanion toCompanion(bool nullToAbsent) {
    return LibraryListsTableCompanion(
      id: Value(id),
      name: Value(name),
      isPrivate: Value(isPrivate),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LibraryListsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryListsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  LibraryListsTableData copyWith({
    int? id,
    String? name,
    bool? isPrivate,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => LibraryListsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    isPrivate: isPrivate ?? this.isPrivate,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LibraryListsTableData copyWithCompanion(LibraryListsTableCompanion data) {
    return LibraryListsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryListsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isPrivate, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryListsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.isPrivate == this.isPrivate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LibraryListsTableCompanion
    extends UpdateCompanion<LibraryListsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isPrivate;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  const LibraryListsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LibraryListsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isPrivate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LibraryListsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isPrivate,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isPrivate != null) 'is_private': isPrivate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LibraryListsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isPrivate,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
  }) {
    return LibraryListsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryListsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LibraryListEntriesTableTable extends LibraryListEntriesTable
    with TableInfo<$LibraryListEntriesTableTable, LibraryListEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryListEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<int> listId = GeneratedColumn<int>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [listId, seriesId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_list_entries_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryListEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listId, seriesId};
  @override
  LibraryListEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryListEntriesTableData(
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}list_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
    );
  }

  @override
  $LibraryListEntriesTableTable createAlias(String alias) {
    return $LibraryListEntriesTableTable(attachedDatabase, alias);
  }
}

class LibraryListEntriesTableData extends DataClass
    implements Insertable<LibraryListEntriesTableData> {
  final int listId;
  final String seriesId;
  const LibraryListEntriesTableData({
    required this.listId,
    required this.seriesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_id'] = Variable<int>(listId);
    map['series_id'] = Variable<String>(seriesId);
    return map;
  }

  LibraryListEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return LibraryListEntriesTableCompanion(
      listId: Value(listId),
      seriesId: Value(seriesId),
    );
  }

  factory LibraryListEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryListEntriesTableData(
      listId: serializer.fromJson<int>(json['listId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listId': serializer.toJson<int>(listId),
      'seriesId': serializer.toJson<String>(seriesId),
    };
  }

  LibraryListEntriesTableData copyWith({int? listId, String? seriesId}) =>
      LibraryListEntriesTableData(
        listId: listId ?? this.listId,
        seriesId: seriesId ?? this.seriesId,
      );
  LibraryListEntriesTableData copyWithCompanion(
    LibraryListEntriesTableCompanion data,
  ) {
    return LibraryListEntriesTableData(
      listId: data.listId.present ? data.listId.value : this.listId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryListEntriesTableData(')
          ..write('listId: $listId, ')
          ..write('seriesId: $seriesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listId, seriesId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryListEntriesTableData &&
          other.listId == this.listId &&
          other.seriesId == this.seriesId);
}

class LibraryListEntriesTableCompanion
    extends UpdateCompanion<LibraryListEntriesTableData> {
  final Value<int> listId;
  final Value<String> seriesId;
  final Value<int> rowid;
  const LibraryListEntriesTableCompanion({
    this.listId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryListEntriesTableCompanion.insert({
    required int listId,
    required String seriesId,
    this.rowid = const Value.absent(),
  }) : listId = Value(listId),
       seriesId = Value(seriesId);
  static Insertable<LibraryListEntriesTableData> custom({
    Expression<int>? listId,
    Expression<String>? seriesId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listId != null) 'list_id': listId,
      if (seriesId != null) 'series_id': seriesId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryListEntriesTableCompanion copyWith({
    Value<int>? listId,
    Value<String>? seriesId,
    Value<int>? rowid,
  }) {
    return LibraryListEntriesTableCompanion(
      listId: listId ?? this.listId,
      seriesId: seriesId ?? this.seriesId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listId.present) {
      map['list_id'] = Variable<int>(listId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryListEntriesTableCompanion(')
          ..write('listId: $listId, ')
          ..write('seriesId: $seriesId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $LibraryEntriesTableTable libraryEntriesTable =
      $LibraryEntriesTableTable(this);
  late final $LibraryListsTableTable libraryListsTable =
      $LibraryListsTableTable(this);
  late final $LibraryListEntriesTableTable libraryListEntriesTable =
      $LibraryListEntriesTableTable(this);
  late final SeriesDao seriesDao = SeriesDao(this as AppDatabase);
  late final LibraryEntriesDao libraryEntriesDao = LibraryEntriesDao(
    this as AppDatabase,
  );
  late final LibraryListsDao libraryListsDao = LibraryListsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    seriesTable,
    libraryEntriesTable,
    libraryListsTable,
    libraryListEntriesTable,
  ];
}

typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      required String id,
      Value<String?> state,
      Value<String?> mergedWith,
      required String title,
      Value<String?> nativeTitle,
      Value<String?> romanizedTitle,
      Value<String> secondaryTitles,
      required String coverUrl,
      Value<String> authors,
      Value<String> artists,
      required String description,
      Value<String?> year,
      Value<String?> published,
      Value<String?> status,
      Value<String?> isLicensed,
      Value<String?> hasAnime,
      Value<String?> anime,
      Value<String?> contentRating,
      Value<String?> type,
      Value<String?> rating,
      Value<String?> finalVolume,
      Value<String?> totalChapters,
      Value<String> links,
      Value<String> publishers,
      Value<String> genres,
      Value<String> tags,
      Value<String?> lastUpdated,
      Value<String?> relationships,
      Value<String?> source,
      Value<int> rowid,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<String> id,
      Value<String?> state,
      Value<String?> mergedWith,
      Value<String> title,
      Value<String?> nativeTitle,
      Value<String?> romanizedTitle,
      Value<String> secondaryTitles,
      Value<String> coverUrl,
      Value<String> authors,
      Value<String> artists,
      Value<String> description,
      Value<String?> year,
      Value<String?> published,
      Value<String?> status,
      Value<String?> isLicensed,
      Value<String?> hasAnime,
      Value<String?> anime,
      Value<String?> contentRating,
      Value<String?> type,
      Value<String?> rating,
      Value<String?> finalVolume,
      Value<String?> totalChapters,
      Value<String> links,
      Value<String> publishers,
      Value<String> genres,
      Value<String> tags,
      Value<String?> lastUpdated,
      Value<String?> relationships,
      Value<String?> source,
      Value<int> rowid,
    });

final class $$SeriesTableTableReferences
    extends BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesTableData> {
  $$SeriesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $LibraryEntriesTableTable,
    List<LibraryEntriesTableData>
  >
  _libraryEntriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.libraryEntriesTable,
        aliasName: 'series_table__id__library_entries_table__series_id',
      );

  $$LibraryEntriesTableTableProcessedTableManager get libraryEntriesTableRefs {
    final manager = $$LibraryEntriesTableTableTableManager(
      $_db,
      $_db.libraryEntriesTable,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _libraryEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mergedWith => $composableBuilder(
    column: $table.mergedWith,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeTitle => $composableBuilder(
    column: $table.nativeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romanizedTitle => $composableBuilder(
    column: $table.romanizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryTitles => $composableBuilder(
    column: $table.secondaryTitles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get published => $composableBuilder(
    column: $table.published,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isLicensed => $composableBuilder(
    column: $table.isLicensed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hasAnime => $composableBuilder(
    column: $table.hasAnime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anime => $composableBuilder(
    column: $table.anime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalVolume => $composableBuilder(
    column: $table.finalVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get links => $composableBuilder(
    column: $table.links,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationships => $composableBuilder(
    column: $table.relationships,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> libraryEntriesTableRefs(
    Expression<bool> Function($$LibraryEntriesTableTableFilterComposer f) f,
  ) {
    final $$LibraryEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryEntriesTable,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mergedWith => $composableBuilder(
    column: $table.mergedWith,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeTitle => $composableBuilder(
    column: $table.nativeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romanizedTitle => $composableBuilder(
    column: $table.romanizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryTitles => $composableBuilder(
    column: $table.secondaryTitles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artists => $composableBuilder(
    column: $table.artists,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get published => $composableBuilder(
    column: $table.published,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isLicensed => $composableBuilder(
    column: $table.isLicensed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hasAnime => $composableBuilder(
    column: $table.hasAnime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anime => $composableBuilder(
    column: $table.anime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalVolume => $composableBuilder(
    column: $table.finalVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get links => $composableBuilder(
    column: $table.links,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationships => $composableBuilder(
    column: $table.relationships,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get mergedWith => $composableBuilder(
    column: $table.mergedWith,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get nativeTitle => $composableBuilder(
    column: $table.nativeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get romanizedTitle => $composableBuilder(
    column: $table.romanizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryTitles => $composableBuilder(
    column: $table.secondaryTitles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<String> get artists =>
      $composableBuilder(column: $table.artists, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get published =>
      $composableBuilder(column: $table.published, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get isLicensed => $composableBuilder(
    column: $table.isLicensed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hasAnime =>
      $composableBuilder(column: $table.hasAnime, builder: (column) => column);

  GeneratedColumn<String> get anime =>
      $composableBuilder(column: $table.anime, builder: (column) => column);

  GeneratedColumn<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get finalVolume => $composableBuilder(
    column: $table.finalVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get links =>
      $composableBuilder(column: $table.links, builder: (column) => column);

  GeneratedColumn<String> get publishers => $composableBuilder(
    column: $table.publishers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationships => $composableBuilder(
    column: $table.relationships,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> libraryEntriesTableRefs<T extends Object>(
    Expression<T> Function($$LibraryEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$LibraryEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.libraryEntriesTable,
          getReferencedColumn: (t) => t.seriesId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LibraryEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.libraryEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          SeriesTableData,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (SeriesTableData, $$SeriesTableTableReferences),
          SeriesTableData,
          PrefetchHooks Function({bool libraryEntriesTableRefs})
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<String?> mergedWith = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> nativeTitle = const Value.absent(),
                Value<String?> romanizedTitle = const Value.absent(),
                Value<String> secondaryTitles = const Value.absent(),
                Value<String> coverUrl = const Value.absent(),
                Value<String> authors = const Value.absent(),
                Value<String> artists = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> published = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> isLicensed = const Value.absent(),
                Value<String?> hasAnime = const Value.absent(),
                Value<String?> anime = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> finalVolume = const Value.absent(),
                Value<String?> totalChapters = const Value.absent(),
                Value<String> links = const Value.absent(),
                Value<String> publishers = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> lastUpdated = const Value.absent(),
                Value<String?> relationships = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                state: state,
                mergedWith: mergedWith,
                title: title,
                nativeTitle: nativeTitle,
                romanizedTitle: romanizedTitle,
                secondaryTitles: secondaryTitles,
                coverUrl: coverUrl,
                authors: authors,
                artists: artists,
                description: description,
                year: year,
                published: published,
                status: status,
                isLicensed: isLicensed,
                hasAnime: hasAnime,
                anime: anime,
                contentRating: contentRating,
                type: type,
                rating: rating,
                finalVolume: finalVolume,
                totalChapters: totalChapters,
                links: links,
                publishers: publishers,
                genres: genres,
                tags: tags,
                lastUpdated: lastUpdated,
                relationships: relationships,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> state = const Value.absent(),
                Value<String?> mergedWith = const Value.absent(),
                required String title,
                Value<String?> nativeTitle = const Value.absent(),
                Value<String?> romanizedTitle = const Value.absent(),
                Value<String> secondaryTitles = const Value.absent(),
                required String coverUrl,
                Value<String> authors = const Value.absent(),
                Value<String> artists = const Value.absent(),
                required String description,
                Value<String?> year = const Value.absent(),
                Value<String?> published = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> isLicensed = const Value.absent(),
                Value<String?> hasAnime = const Value.absent(),
                Value<String?> anime = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> finalVolume = const Value.absent(),
                Value<String?> totalChapters = const Value.absent(),
                Value<String> links = const Value.absent(),
                Value<String> publishers = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> lastUpdated = const Value.absent(),
                Value<String?> relationships = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                id: id,
                state: state,
                mergedWith: mergedWith,
                title: title,
                nativeTitle: nativeTitle,
                romanizedTitle: romanizedTitle,
                secondaryTitles: secondaryTitles,
                coverUrl: coverUrl,
                authors: authors,
                artists: artists,
                description: description,
                year: year,
                published: published,
                status: status,
                isLicensed: isLicensed,
                hasAnime: hasAnime,
                anime: anime,
                contentRating: contentRating,
                type: type,
                rating: rating,
                finalVolume: finalVolume,
                totalChapters: totalChapters,
                links: links,
                publishers: publishers,
                genres: genres,
                tags: tags,
                lastUpdated: lastUpdated,
                relationships: relationships,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({libraryEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (libraryEntriesTableRefs) db.libraryEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (libraryEntriesTableRefs)
                    await $_getPrefetchedData<
                      SeriesTableData,
                      $SeriesTableTable,
                      LibraryEntriesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SeriesTableTableReferences
                          ._libraryEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SeriesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).libraryEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.seriesId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      SeriesTableData,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (SeriesTableData, $$SeriesTableTableReferences),
      SeriesTableData,
      PrefetchHooks Function({bool libraryEntriesTableRefs})
    >;
typedef $$LibraryEntriesTableTableCreateCompanionBuilder =
    LibraryEntriesTableCompanion Function({
      required String id,
      required String state,
      Value<String?> note,
      Value<int?> progressChapter,
      Value<int?> progressVolume,
      Value<int?> numberOfRereads,
      Value<int?> rating,
      required String seriesId,
      Value<int> rowid,
    });
typedef $$LibraryEntriesTableTableUpdateCompanionBuilder =
    LibraryEntriesTableCompanion Function({
      Value<String> id,
      Value<String> state,
      Value<String?> note,
      Value<int?> progressChapter,
      Value<int?> progressVolume,
      Value<int?> numberOfRereads,
      Value<int?> rating,
      Value<String> seriesId,
      Value<int> rowid,
    });

final class $$LibraryEntriesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LibraryEntriesTableTable,
          LibraryEntriesTableData
        > {
  $$LibraryEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SeriesTableTable _seriesIdTable(_$AppDatabase db) => db.seriesTable
      .createAlias('library_entries_table__series_id__series_table__id');

  $$SeriesTableTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<String>('series_id')!;

    final manager = $$SeriesTableTableTableManager(
      $_db,
      $_db.seriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LibraryEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTableTable> {
  $$LibraryEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressChapter => $composableBuilder(
    column: $table.progressChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progressVolume => $composableBuilder(
    column: $table.progressVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfRereads => $composableBuilder(
    column: $table.numberOfRereads,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  $$SeriesTableTableFilterComposer get seriesId {
    final $$SeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTableTable> {
  $$LibraryEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressChapter => $composableBuilder(
    column: $table.progressChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progressVolume => $composableBuilder(
    column: $table.progressVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfRereads => $composableBuilder(
    column: $table.numberOfRereads,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  $$SeriesTableTableOrderingComposer get seriesId {
    final $$SeriesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableOrderingComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTableTable> {
  $$LibraryEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get progressChapter => $composableBuilder(
    column: $table.progressChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progressVolume => $composableBuilder(
    column: $table.progressVolume,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numberOfRereads => $composableBuilder(
    column: $table.numberOfRereads,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  $$SeriesTableTableAnnotationComposer get seriesId {
    final $$SeriesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryEntriesTableTable,
          LibraryEntriesTableData,
          $$LibraryEntriesTableTableFilterComposer,
          $$LibraryEntriesTableTableOrderingComposer,
          $$LibraryEntriesTableTableAnnotationComposer,
          $$LibraryEntriesTableTableCreateCompanionBuilder,
          $$LibraryEntriesTableTableUpdateCompanionBuilder,
          (LibraryEntriesTableData, $$LibraryEntriesTableTableReferences),
          LibraryEntriesTableData,
          PrefetchHooks Function({bool seriesId})
        > {
  $$LibraryEntriesTableTableTableManager(
    _$AppDatabase db,
    $LibraryEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> progressChapter = const Value.absent(),
                Value<int?> progressVolume = const Value.absent(),
                Value<int?> numberOfRereads = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesTableCompanion(
                id: id,
                state: state,
                note: note,
                progressChapter: progressChapter,
                progressVolume: progressVolume,
                numberOfRereads: numberOfRereads,
                rating: rating,
                seriesId: seriesId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String state,
                Value<String?> note = const Value.absent(),
                Value<int?> progressChapter = const Value.absent(),
                Value<int?> progressVolume = const Value.absent(),
                Value<int?> numberOfRereads = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                required String seriesId,
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesTableCompanion.insert(
                id: id,
                state: state,
                note: note,
                progressChapter: progressChapter,
                progressVolume: progressVolume,
                numberOfRereads: numberOfRereads,
                rating: rating,
                seriesId: seriesId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (seriesId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seriesId,
                                referencedTable:
                                    $$LibraryEntriesTableTableReferences
                                        ._seriesIdTable(db),
                                referencedColumn:
                                    $$LibraryEntriesTableTableReferences
                                        ._seriesIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LibraryEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryEntriesTableTable,
      LibraryEntriesTableData,
      $$LibraryEntriesTableTableFilterComposer,
      $$LibraryEntriesTableTableOrderingComposer,
      $$LibraryEntriesTableTableAnnotationComposer,
      $$LibraryEntriesTableTableCreateCompanionBuilder,
      $$LibraryEntriesTableTableUpdateCompanionBuilder,
      (LibraryEntriesTableData, $$LibraryEntriesTableTableReferences),
      LibraryEntriesTableData,
      PrefetchHooks Function({bool seriesId})
    >;
typedef $$LibraryListsTableTableCreateCompanionBuilder =
    LibraryListsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isPrivate,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });
typedef $$LibraryListsTableTableUpdateCompanionBuilder =
    LibraryListsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isPrivate,
      Value<String?> createdAt,
      Value<String?> updatedAt,
    });

class $$LibraryListsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryListsTableTable> {
  $$LibraryListsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryListsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryListsTableTable> {
  $$LibraryListsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
    column: $table.isPrivate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryListsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryListsTableTable> {
  $$LibraryListsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LibraryListsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryListsTableTable,
          LibraryListsTableData,
          $$LibraryListsTableTableFilterComposer,
          $$LibraryListsTableTableOrderingComposer,
          $$LibraryListsTableTableAnnotationComposer,
          $$LibraryListsTableTableCreateCompanionBuilder,
          $$LibraryListsTableTableUpdateCompanionBuilder,
          (
            LibraryListsTableData,
            BaseReferences<
              _$AppDatabase,
              $LibraryListsTableTable,
              LibraryListsTableData
            >,
          ),
          LibraryListsTableData,
          PrefetchHooks Function()
        > {
  $$LibraryListsTableTableTableManager(
    _$AppDatabase db,
    $LibraryListsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryListsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryListsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryListsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isPrivate = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => LibraryListsTableCompanion(
                id: id,
                name: name,
                isPrivate: isPrivate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isPrivate = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => LibraryListsTableCompanion.insert(
                id: id,
                name: name,
                isPrivate: isPrivate,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryListsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryListsTableTable,
      LibraryListsTableData,
      $$LibraryListsTableTableFilterComposer,
      $$LibraryListsTableTableOrderingComposer,
      $$LibraryListsTableTableAnnotationComposer,
      $$LibraryListsTableTableCreateCompanionBuilder,
      $$LibraryListsTableTableUpdateCompanionBuilder,
      (
        LibraryListsTableData,
        BaseReferences<
          _$AppDatabase,
          $LibraryListsTableTable,
          LibraryListsTableData
        >,
      ),
      LibraryListsTableData,
      PrefetchHooks Function()
    >;
typedef $$LibraryListEntriesTableTableCreateCompanionBuilder =
    LibraryListEntriesTableCompanion Function({
      required int listId,
      required String seriesId,
      Value<int> rowid,
    });
typedef $$LibraryListEntriesTableTableUpdateCompanionBuilder =
    LibraryListEntriesTableCompanion Function({
      Value<int> listId,
      Value<String> seriesId,
      Value<int> rowid,
    });

class $$LibraryListEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryListEntriesTableTable> {
  $$LibraryListEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryListEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryListEntriesTableTable> {
  $$LibraryListEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryListEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryListEntriesTableTable> {
  $$LibraryListEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);
}

class $$LibraryListEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryListEntriesTableTable,
          LibraryListEntriesTableData,
          $$LibraryListEntriesTableTableFilterComposer,
          $$LibraryListEntriesTableTableOrderingComposer,
          $$LibraryListEntriesTableTableAnnotationComposer,
          $$LibraryListEntriesTableTableCreateCompanionBuilder,
          $$LibraryListEntriesTableTableUpdateCompanionBuilder,
          (
            LibraryListEntriesTableData,
            BaseReferences<
              _$AppDatabase,
              $LibraryListEntriesTableTable,
              LibraryListEntriesTableData
            >,
          ),
          LibraryListEntriesTableData,
          PrefetchHooks Function()
        > {
  $$LibraryListEntriesTableTableTableManager(
    _$AppDatabase db,
    $LibraryListEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryListEntriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LibraryListEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LibraryListEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> listId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryListEntriesTableCompanion(
                listId: listId,
                seriesId: seriesId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int listId,
                required String seriesId,
                Value<int> rowid = const Value.absent(),
              }) => LibraryListEntriesTableCompanion.insert(
                listId: listId,
                seriesId: seriesId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryListEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryListEntriesTableTable,
      LibraryListEntriesTableData,
      $$LibraryListEntriesTableTableFilterComposer,
      $$LibraryListEntriesTableTableOrderingComposer,
      $$LibraryListEntriesTableTableAnnotationComposer,
      $$LibraryListEntriesTableTableCreateCompanionBuilder,
      $$LibraryListEntriesTableTableUpdateCompanionBuilder,
      (
        LibraryListEntriesTableData,
        BaseReferences<
          _$AppDatabase,
          $LibraryListEntriesTableTable,
          LibraryListEntriesTableData
        >,
      ),
      LibraryListEntriesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$LibraryEntriesTableTableTableManager get libraryEntriesTable =>
      $$LibraryEntriesTableTableTableManager(_db, _db.libraryEntriesTable);
  $$LibraryListsTableTableTableManager get libraryListsTable =>
      $$LibraryListsTableTableTableManager(_db, _db.libraryListsTable);
  $$LibraryListEntriesTableTableTableManager get libraryListEntriesTable =>
      $$LibraryListEntriesTableTableTableManager(
        _db,
        _db.libraryListEntriesTable,
      );
}

mixin _$SeriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SeriesTableTable get seriesTable => attachedDatabase.seriesTable;
  SeriesDaoManager get managers => SeriesDaoManager(this);
}

class SeriesDaoManager {
  final _$SeriesDaoMixin _db;
  SeriesDaoManager(this._db);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db.attachedDatabase, _db.seriesTable);
}

mixin _$LibraryEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SeriesTableTable get seriesTable => attachedDatabase.seriesTable;
  $LibraryEntriesTableTable get libraryEntriesTable =>
      attachedDatabase.libraryEntriesTable;
  LibraryEntriesDaoManager get managers => LibraryEntriesDaoManager(this);
}

class LibraryEntriesDaoManager {
  final _$LibraryEntriesDaoMixin _db;
  LibraryEntriesDaoManager(this._db);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db.attachedDatabase, _db.seriesTable);
  $$LibraryEntriesTableTableTableManager get libraryEntriesTable =>
      $$LibraryEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.libraryEntriesTable,
      );
}

mixin _$LibraryListsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LibraryListsTableTable get libraryListsTable =>
      attachedDatabase.libraryListsTable;
  $LibraryListEntriesTableTable get libraryListEntriesTable =>
      attachedDatabase.libraryListEntriesTable;
  $SeriesTableTable get seriesTable => attachedDatabase.seriesTable;
  $LibraryEntriesTableTable get libraryEntriesTable =>
      attachedDatabase.libraryEntriesTable;
  LibraryListsDaoManager get managers => LibraryListsDaoManager(this);
}

class LibraryListsDaoManager {
  final _$LibraryListsDaoMixin _db;
  LibraryListsDaoManager(this._db);
  $$LibraryListsTableTableTableManager get libraryListsTable =>
      $$LibraryListsTableTableTableManager(
        _db.attachedDatabase,
        _db.libraryListsTable,
      );
  $$LibraryListEntriesTableTableTableManager get libraryListEntriesTable =>
      $$LibraryListEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.libraryListEntriesTable,
      );
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db.attachedDatabase, _db.seriesTable);
  $$LibraryEntriesTableTableTableManager get libraryEntriesTable =>
      $$LibraryEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.libraryEntriesTable,
      );
}

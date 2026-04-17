// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    state,
    title,
    nativeTitle,
    romanizedTitle,
    coverUrl,
    description,
    year,
    status,
    contentRating,
    type,
    rating,
    finalVolume,
    totalChapters,
    lastUpdated,
    genres,
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
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
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
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
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
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
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
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      ),
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
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
  final String title;
  final String? nativeTitle;
  final String? romanizedTitle;
  final String coverUrl;
  final String description;
  final String? year;
  final String? status;
  final String? contentRating;
  final String? type;
  final String? rating;
  final String? finalVolume;
  final String? totalChapters;
  final String? lastUpdated;
  final String genres;
  const SeriesTableData({
    required this.id,
    this.state,
    required this.title,
    this.nativeTitle,
    this.romanizedTitle,
    required this.coverUrl,
    required this.description,
    this.year,
    this.status,
    this.contentRating,
    this.type,
    this.rating,
    this.finalVolume,
    this.totalChapters,
    this.lastUpdated,
    required this.genres,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || nativeTitle != null) {
      map['native_title'] = Variable<String>(nativeTitle);
    }
    if (!nullToAbsent || romanizedTitle != null) {
      map['romanized_title'] = Variable<String>(romanizedTitle);
    }
    map['cover_url'] = Variable<String>(coverUrl);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
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
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<String>(lastUpdated);
    }
    map['genres'] = Variable<String>(genres);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      title: Value(title),
      nativeTitle: nativeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(nativeTitle),
      romanizedTitle: romanizedTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(romanizedTitle),
      coverUrl: Value(coverUrl),
      description: Value(description),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
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
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
      genres: Value(genres),
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
      title: serializer.fromJson<String>(json['title']),
      nativeTitle: serializer.fromJson<String?>(json['nativeTitle']),
      romanizedTitle: serializer.fromJson<String?>(json['romanizedTitle']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      description: serializer.fromJson<String>(json['description']),
      year: serializer.fromJson<String?>(json['year']),
      status: serializer.fromJson<String?>(json['status']),
      contentRating: serializer.fromJson<String?>(json['contentRating']),
      type: serializer.fromJson<String?>(json['type']),
      rating: serializer.fromJson<String?>(json['rating']),
      finalVolume: serializer.fromJson<String?>(json['finalVolume']),
      totalChapters: serializer.fromJson<String?>(json['totalChapters']),
      lastUpdated: serializer.fromJson<String?>(json['lastUpdated']),
      genres: serializer.fromJson<String>(json['genres']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'state': serializer.toJson<String?>(state),
      'title': serializer.toJson<String>(title),
      'nativeTitle': serializer.toJson<String?>(nativeTitle),
      'romanizedTitle': serializer.toJson<String?>(romanizedTitle),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'description': serializer.toJson<String>(description),
      'year': serializer.toJson<String?>(year),
      'status': serializer.toJson<String?>(status),
      'contentRating': serializer.toJson<String?>(contentRating),
      'type': serializer.toJson<String?>(type),
      'rating': serializer.toJson<String?>(rating),
      'finalVolume': serializer.toJson<String?>(finalVolume),
      'totalChapters': serializer.toJson<String?>(totalChapters),
      'lastUpdated': serializer.toJson<String?>(lastUpdated),
      'genres': serializer.toJson<String>(genres),
    };
  }

  SeriesTableData copyWith({
    String? id,
    Value<String?> state = const Value.absent(),
    String? title,
    Value<String?> nativeTitle = const Value.absent(),
    Value<String?> romanizedTitle = const Value.absent(),
    String? coverUrl,
    String? description,
    Value<String?> year = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> contentRating = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<String?> finalVolume = const Value.absent(),
    Value<String?> totalChapters = const Value.absent(),
    Value<String?> lastUpdated = const Value.absent(),
    String? genres,
  }) => SeriesTableData(
    id: id ?? this.id,
    state: state.present ? state.value : this.state,
    title: title ?? this.title,
    nativeTitle: nativeTitle.present ? nativeTitle.value : this.nativeTitle,
    romanizedTitle: romanizedTitle.present
        ? romanizedTitle.value
        : this.romanizedTitle,
    coverUrl: coverUrl ?? this.coverUrl,
    description: description ?? this.description,
    year: year.present ? year.value : this.year,
    status: status.present ? status.value : this.status,
    contentRating: contentRating.present
        ? contentRating.value
        : this.contentRating,
    type: type.present ? type.value : this.type,
    rating: rating.present ? rating.value : this.rating,
    finalVolume: finalVolume.present ? finalVolume.value : this.finalVolume,
    totalChapters: totalChapters.present
        ? totalChapters.value
        : this.totalChapters,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
    genres: genres ?? this.genres,
  );
  SeriesTableData copyWithCompanion(SeriesTableCompanion data) {
    return SeriesTableData(
      id: data.id.present ? data.id.value : this.id,
      state: data.state.present ? data.state.value : this.state,
      title: data.title.present ? data.title.value : this.title,
      nativeTitle: data.nativeTitle.present
          ? data.nativeTitle.value
          : this.nativeTitle,
      romanizedTitle: data.romanizedTitle.present
          ? data.romanizedTitle.value
          : this.romanizedTitle,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      year: data.year.present ? data.year.value : this.year,
      status: data.status.present ? data.status.value : this.status,
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
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      genres: data.genres.present ? data.genres.value : this.genres,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableData(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('title: $title, ')
          ..write('nativeTitle: $nativeTitle, ')
          ..write('romanizedTitle: $romanizedTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('year: $year, ')
          ..write('status: $status, ')
          ..write('contentRating: $contentRating, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('finalVolume: $finalVolume, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('genres: $genres')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    state,
    title,
    nativeTitle,
    romanizedTitle,
    coverUrl,
    description,
    year,
    status,
    contentRating,
    type,
    rating,
    finalVolume,
    totalChapters,
    lastUpdated,
    genres,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesTableData &&
          other.id == this.id &&
          other.state == this.state &&
          other.title == this.title &&
          other.nativeTitle == this.nativeTitle &&
          other.romanizedTitle == this.romanizedTitle &&
          other.coverUrl == this.coverUrl &&
          other.description == this.description &&
          other.year == this.year &&
          other.status == this.status &&
          other.contentRating == this.contentRating &&
          other.type == this.type &&
          other.rating == this.rating &&
          other.finalVolume == this.finalVolume &&
          other.totalChapters == this.totalChapters &&
          other.lastUpdated == this.lastUpdated &&
          other.genres == this.genres);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesTableData> {
  final Value<String> id;
  final Value<String?> state;
  final Value<String> title;
  final Value<String?> nativeTitle;
  final Value<String?> romanizedTitle;
  final Value<String> coverUrl;
  final Value<String> description;
  final Value<String?> year;
  final Value<String?> status;
  final Value<String?> contentRating;
  final Value<String?> type;
  final Value<String?> rating;
  final Value<String?> finalVolume;
  final Value<String?> totalChapters;
  final Value<String?> lastUpdated;
  final Value<String> genres;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.state = const Value.absent(),
    this.title = const Value.absent(),
    this.nativeTitle = const Value.absent(),
    this.romanizedTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.year = const Value.absent(),
    this.status = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.type = const Value.absent(),
    this.rating = const Value.absent(),
    this.finalVolume = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.genres = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String id,
    this.state = const Value.absent(),
    required String title,
    this.nativeTitle = const Value.absent(),
    this.romanizedTitle = const Value.absent(),
    required String coverUrl,
    required String description,
    this.year = const Value.absent(),
    this.status = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.type = const Value.absent(),
    this.rating = const Value.absent(),
    this.finalVolume = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.genres = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       coverUrl = Value(coverUrl),
       description = Value(description);
  static Insertable<SeriesTableData> custom({
    Expression<String>? id,
    Expression<String>? state,
    Expression<String>? title,
    Expression<String>? nativeTitle,
    Expression<String>? romanizedTitle,
    Expression<String>? coverUrl,
    Expression<String>? description,
    Expression<String>? year,
    Expression<String>? status,
    Expression<String>? contentRating,
    Expression<String>? type,
    Expression<String>? rating,
    Expression<String>? finalVolume,
    Expression<String>? totalChapters,
    Expression<String>? lastUpdated,
    Expression<String>? genres,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (state != null) 'state': state,
      if (title != null) 'title': title,
      if (nativeTitle != null) 'native_title': nativeTitle,
      if (romanizedTitle != null) 'romanized_title': romanizedTitle,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (description != null) 'description': description,
      if (year != null) 'year': year,
      if (status != null) 'status': status,
      if (contentRating != null) 'content_rating': contentRating,
      if (type != null) 'type': type,
      if (rating != null) 'rating': rating,
      if (finalVolume != null) 'final_volume': finalVolume,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (genres != null) 'genres': genres,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? state,
    Value<String>? title,
    Value<String?>? nativeTitle,
    Value<String?>? romanizedTitle,
    Value<String>? coverUrl,
    Value<String>? description,
    Value<String?>? year,
    Value<String?>? status,
    Value<String?>? contentRating,
    Value<String?>? type,
    Value<String?>? rating,
    Value<String?>? finalVolume,
    Value<String?>? totalChapters,
    Value<String?>? lastUpdated,
    Value<String>? genres,
    Value<int>? rowid,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      state: state ?? this.state,
      title: title ?? this.title,
      nativeTitle: nativeTitle ?? this.nativeTitle,
      romanizedTitle: romanizedTitle ?? this.romanizedTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      year: year ?? this.year,
      status: status ?? this.status,
      contentRating: contentRating ?? this.contentRating,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      finalVolume: finalVolume ?? this.finalVolume,
      totalChapters: totalChapters ?? this.totalChapters,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      genres: genres ?? this.genres,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (nativeTitle.present) {
      map['native_title'] = Variable<String>(nativeTitle.value);
    }
    if (romanizedTitle.present) {
      map['romanized_title'] = Variable<String>(romanizedTitle.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
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
          ..write('title: $title, ')
          ..write('nativeTitle: $nativeTitle, ')
          ..write('romanizedTitle: $romanizedTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('year: $year, ')
          ..write('status: $status, ')
          ..write('contentRating: $contentRating, ')
          ..write('type: $type, ')
          ..write('rating: $rating, ')
          ..write('finalVolume: $finalVolume, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('genres: $genres, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $LibraryEntriesTableTable libraryEntriesTable =
      $LibraryEntriesTableTable(this);
  late final SeriesDao seriesDao = SeriesDao(this as AppDatabase);
  late final LibraryEntriesDao libraryEntriesDao = LibraryEntriesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    seriesTable,
    libraryEntriesTable,
  ];
}

typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      required String id,
      Value<String?> state,
      required String title,
      Value<String?> nativeTitle,
      Value<String?> romanizedTitle,
      required String coverUrl,
      required String description,
      Value<String?> year,
      Value<String?> status,
      Value<String?> contentRating,
      Value<String?> type,
      Value<String?> rating,
      Value<String?> finalVolume,
      Value<String?> totalChapters,
      Value<String?> lastUpdated,
      Value<String> genres,
      Value<int> rowid,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<String> id,
      Value<String?> state,
      Value<String> title,
      Value<String?> nativeTitle,
      Value<String?> romanizedTitle,
      Value<String> coverUrl,
      Value<String> description,
      Value<String?> year,
      Value<String?> status,
      Value<String?> contentRating,
      Value<String?> type,
      Value<String?> rating,
      Value<String?> finalVolume,
      Value<String?> totalChapters,
      Value<String?> lastUpdated,
      Value<String> genres,
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
        aliasName: $_aliasNameGenerator(
          db.seriesTable.id,
          db.libraryEntriesTable.seriesId,
        ),
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

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
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

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
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

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
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

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

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

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

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
                Value<String> title = const Value.absent(),
                Value<String?> nativeTitle = const Value.absent(),
                Value<String?> romanizedTitle = const Value.absent(),
                Value<String> coverUrl = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> finalVolume = const Value.absent(),
                Value<String?> totalChapters = const Value.absent(),
                Value<String?> lastUpdated = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                state: state,
                title: title,
                nativeTitle: nativeTitle,
                romanizedTitle: romanizedTitle,
                coverUrl: coverUrl,
                description: description,
                year: year,
                status: status,
                contentRating: contentRating,
                type: type,
                rating: rating,
                finalVolume: finalVolume,
                totalChapters: totalChapters,
                lastUpdated: lastUpdated,
                genres: genres,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> state = const Value.absent(),
                required String title,
                Value<String?> nativeTitle = const Value.absent(),
                Value<String?> romanizedTitle = const Value.absent(),
                required String coverUrl,
                required String description,
                Value<String?> year = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> finalVolume = const Value.absent(),
                Value<String?> totalChapters = const Value.absent(),
                Value<String?> lastUpdated = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                id: id,
                state: state,
                title: title,
                nativeTitle: nativeTitle,
                romanizedTitle: romanizedTitle,
                coverUrl: coverUrl,
                description: description,
                year: year,
                status: status,
                contentRating: contentRating,
                type: type,
                rating: rating,
                finalVolume: finalVolume,
                totalChapters: totalChapters,
                lastUpdated: lastUpdated,
                genres: genres,
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

  static $SeriesTableTable _seriesIdTable(_$AppDatabase db) =>
      db.seriesTable.createAlias(
        $_aliasNameGenerator(
          db.libraryEntriesTable.seriesId,
          db.seriesTable.id,
        ),
      );

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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$LibraryEntriesTableTableTableManager get libraryEntriesTable =>
      $$LibraryEntriesTableTableTableManager(_db, _db.libraryEntriesTable);
}

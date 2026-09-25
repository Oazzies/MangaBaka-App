import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/profile/models/mb_profile.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Worst-case content for the responsive sweeps.
///
/// Every shape the real API can plausibly send is represented: very long and
/// unbreakable titles, non-Latin titles, empty fields, many genres, long
/// descriptions, every type/status/rating. Covers are deliberately absent —
/// image loading needs platform plugins the test host lacks, and a missing
/// cover takes the same fixed-size box as a loaded one.
abstract final class Fixtures {
  static const _titles = [
    'Frieren',
    'The Apothecary Diaries',
    'A Very Long Series Title That Keeps Going Well Past Where Any Card '
        'Could Possibly Fit It On One Line, Or Two, Or Even Three',
    'Supercalifragilisticexpialidociousandthensomewithoutanybreakpoints',
    '葬送のフリーレン 〜魔法使いの旅路と勇者一行のその後の物語〜',
    'X',
    'Kaguya-sama wa Kokurasetai: Tensai-tachi no Ren\'ai Zunousen',
    'ONE PUNCH-MAN',
    'Solo Leveling: Ragnarok — The Second Awakening of the Shadow Monarch',
    'Übermäßig Lange Deutsche Überschriften Für Wirklich Jeden Fall',
    'Vagabond',
    'Oyasumi Punpun',
  ];

  static const _genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Psychological',
    'Slice of Life',
    'Supernatural',
    'Science Fiction',
    'Martial Arts',
    'Historical',
    'Mystery',
  ];

  static const _types = ['manga', 'manhwa', 'manhua', 'novel', 'one_shot', ''];
  static const _statuses = [
    'releasing',
    'completed',
    'hiatus',
    'cancelled',
    'upcoming',
    '',
  ];
  static const _ratings = ['safe', 'suggestive', 'erotica', 'safe'];

  static const _longDescription =
      '**A sprawling synopsis.** It goes on for a long while, describing the '
      'setting, the cast, the premise and several of the arcs in more detail '
      'than any card has room for — which is exactly the point, because the '
      'layout has to fade or clip it rather than grow. '
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
      'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim '
      'veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea '
      'commodo consequat. Duis aute irure dolor in reprehenderit in voluptate '
      'velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '
      'occaecat cupidatat non proident, sunt in culpa qui officia deserunt '
      'mollit anim id est laborum. '
      'Sed ut perspiciatis unde omnis iste natus error sit voluptatem '
      'accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae '
      'ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt '
      'explicabo.';

  /// A series in the API's lean v2 shape (what the discovery rails return).
  static Map<String, dynamic> seriesJson(int i) {
    final title = _titles[i % _titles.length];
    final genreCount = switch (i % 4) {
      0 => 12,
      1 => 0,
      2 => 1,
      _ => 4,
    };
    return {
      'id': '${1000 + i}',
      'state': 'active',
      'title': title,
      'titles': [
        {'title': title, 'language': 'en', 'is_primary': true},
      ],
      'native_title': i.isEven ? '葬送のフリーレン' : '',
      'type': _types[i % _types.length],
      'status': _statuses[i % _statuses.length],
      'content_rating': _ratings[i % _ratings.length],
      'year': i % 5 == 0 ? null : 1990 + (i * 7) % 36,
      'rating': switch (i % 3) {
        0 => '87.5',
        1 => null,
        _ => '100',
      },
      'genres': _genres.take(genreCount).toList(),
      'genres_v2': [
        for (final g in _genres.take(genreCount)) {'name': g},
      ],
      'tags': _genres.reversed.take(genreCount).toList(),
      'authors': i.isEven ? ['An Author With A Rather Long Pen Name'] : [],
      'artists': ['Artist'],
      'description': switch (i % 3) {
        0 => _longDescription,
        1 => '',
        _ => 'Short and sweet.',
      },
      'total_chapters': i.isEven ? '1234' : '',
      'final_volume': i % 3 == 0 ? '42' : '',
      'publishers': [
        {'name': 'A Publisher Whose Name Does Not End Quickly'},
      ],
      'links': [],
    };
  }

  static List<Map<String, dynamic>> seriesList(int count, {int offset = 0}) => [
    for (var i = 0; i < count; i++) seriesJson(i + offset),
  ];

  static Series series(int i) => Series.fromSimilarJson(seriesJson(i));

  /// An upcoming work, several sharing a release date so grouping is hit.
  static Map<String, dynamic> workJson(int i) {
    final date = DateTime(2026, 9, 25).add(Duration(days: i ~/ 3));
    return {
      'id': 'w$i',
      'series_id': 1000 + i,
      'sub_title': i % 4 == 0
          ? 'A Special Deluxe Collector\'s Edition Volume With An Extremely '
                'Long Subtitle That Never Seems To End'
          : 'Volume ${i + 1}',
      'count_type': i.isEven ? 'volume' : 'chapter',
      'release_date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      'sequence_string': '${i + 1}',
      'pages': 200 + i,
      'collections': [
        {'title': _titles[i % _titles.length]},
      ],
      if (i % 2 == 0)
        'price': [
          {'value': 12.99 + i, 'iso_code': 'usd'},
        ],
    };
  }

  static List<Map<String, dynamic>> workList(int count) => [
    for (var i = 0; i < count; i++) workJson(i),
  ];

  static Map<String, dynamic> newsJson(int i) => {
    'id': 'n$i',
    'title': i % 3 == 0
        ? 'An Exceptionally Long News Headline Announcing Several Adaptations, '
              'A Hiatus, A Return From Hiatus, And A Crossover All At Once'
        : 'Short headline $i',
    'url': 'https://example.com/news/$i',
    'author': i.isEven ? 'A Reporter With A Very Long Byline Name' : '',
    'source_name': ['ann', 'mal', 'anidb', 'Some Other Source'][i % 4],
    'published_at': DateTime(2026, 9, 25 - i).toIso8601String(),
    'series': [for (var j = 0; j < i % 7; j++) seriesJson(i * 3 + j)],
  };

  static List<Map<String, dynamic>> newsList(int count) => [
    for (var i = 0; i < count; i++) newsJson(i),
  ];

  static const _states = [
    'reading',
    'completed',
    'plan_to_read',
    'on_hold',
    'dropped',
    'rereading',
  ];

  static LibraryEntry libraryEntry(int i) => LibraryEntry(
    id: 'e$i',
    state: _states[i % _states.length],
    note: i % 5 == 0 ? 'A note that is long enough to wrap somewhere.' : null,
    progressChapter: i.isEven ? 1234 + i : null,
    progressVolume: i % 3 == 0 ? 42 : null,
    numberOfRereads: i % 4,
    rating: i % 3 == 0 ? null : 50 + (i * 13) % 51,
    updatedAt: DateTime(2026, 9, 1 + i % 25).toIso8601String(),
    createdAt: DateTime(2025, 1, 1 + i % 28).toIso8601String(),
    series: Series.fromJson(seriesJson(i)),
  );

  static List<LibraryEntry> library(int count) => [
    for (var i = 0; i < count; i++) libraryEntry(i),
  ];

  static MbProfile profile() => MbProfile.fromJson({
    'id': 'u1',
    'role': 'user',
    'scopes': ['library'],
    'nickname': 'A Reader Whose Display Name Is Unreasonably Long For A Header',
    'preferred_username': 'reader_with_a_long_username_too',
  });
}

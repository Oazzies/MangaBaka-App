/// Stack payloads shaped like the live `/v2/stacks` responses.
library;

Map<String, dynamic> _cover(int seriesId) => {
  'series_id': seriesId,
  'cover': {
    'raw': 'https://images.example/$seriesId',
    'x150': 'https://cdn.example/x150/$seriesId',
    'x250': 'https://cdn.example/x250/$seriesId',
    'x350': 'https://cdn.example/x350/$seriesId',
    'blurhash': null,
    'width': 400,
    'height': 600,
  },
};

Map<String, dynamic> stackSummaryJson({
  int id = 35,
  String visibility = 'public',
  int entryCount = 6,
}) => {
  'id': id,
  'title': 'Stack $id',
  'canonical_url': 'https://mangabaka.org/stacks/$id-stack-$id',
  'kind': 'personal',
  'visibility': visibility,
  'content_rating': 'safe',
  'is_spoiler': false,
  'is_featured': false,
  'owner': {'username': 'angelmastiff', 'name': 'angelmastiff'},
  'entry_count': entryCount,
  'vote_count': 2,
  'save_count': 0,
  'first_published_at': '2026-10-16T11:49:34.123Z',
  'updated_at': '2026-10-16T11:49:34.132Z',
  'covers': [_cover(5072), _cover(217)],
};

Map<String, dynamic> seriesJson(int id, String title) => {
  'id': id,
  'state': 'active',
  'merged_with': null,
  'canonical_url': 'https://mangabaka.org/manga/$id/x',
  'titles': [
    {'language': 'en', 'title': title, 'is_primary': true},
  ],
  'cover': _cover(id)['cover'],
  'authors': ['Author'],
  'artists': ['Artist'],
  'description': 'About $title',
  'content_rating': 'safe',
  'type': 'manga',
  'status': 'releasing',
  'rating': 80,
  'source': <String, dynamic>{},
};

Map<String, dynamic> stackDetailJson({int id = 18}) => {
  ...stackSummaryJson(id: id, entryCount: 3),
  'description': '# Strong or Interesting Lead\nYes.',
  'is_comments_enabled': true,
  'entries': [
    {'kind': 'deleted', 'rank': 3},
    {'kind': 'merged', 'rank': 2},
    {
      'kind': 'series',
      'rank': 1,
      'note': 'Return by death',
      'series': seriesJson(217, 'Mushoku Tensei'),
    },
  ],
};

Map<String, dynamic> ownerStackDetailJson({int id = 7}) => {
  ...stackSummaryJson(id: id, visibility: 'draft', entryCount: 2),
  'description': null,
  'is_comments_enabled': true,
  'is_delisted': false,
  'is_hidden': false,
  'min_content_rating': 'suggestive',
  'is_spoiler_locked': true,
  'token': 'tok-1',
  'entries': [
    {
      'rank': 1,
      'note': 'Hi',
      'series_id': 217,
      'issue': null,
      'series': seriesJson(217, 'Mushoku Tensei'),
    },
    {
      'rank': 2,
      'note': null,
      'series_id': 42,
      'issue': {'state': 'merged', 'merged_with': 999},
      'series': seriesJson(42, 'Old Entry'),
    },
  ],
};

Map<String, dynamic> statusJson(int id, {bool voted = false}) => {
  'id': id,
  'has_voted': voted,
  'has_saved': false,
  'has_followed': false,
  'library_count': 1,
  'vote_count': voted ? 3 : 2,
  'save_count': 0,
  'follow_count': 0,
};

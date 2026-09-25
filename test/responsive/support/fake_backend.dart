import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'fixtures.dart';

/// A canned MangaBaka API for the responsive sweeps, installed through
/// [HttpOverrides] so every `http.Client` the app creates — including the
/// ones services construct for themselves — talks to it instead of the
/// network.
///
/// [populated] serves worst-case fixture data from every endpoint the desktop
/// pages read; when false, every endpoint answers with an empty list, which
/// sweeps the empty states instead.
class FakeBackend extends HttpOverrides {
  final bool populated;

  /// Every URL requested, for diagnosing a sweep that rendered nothing.
  final List<Uri> requests = [];

  FakeBackend({this.populated = true});

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(this);

  (int, Object?) respond(Uri uri) {
    requests.add(uri);
    final path = uri.path;
    if (!populated) return (200, {'data': [], 'total': 0, 'results': []});

    if (path.endsWith('/series/search') || path.contains('/series/discover/')) {
      if (path.endsWith('/top-genres')) {
        return (
          200,
          {
            'results': [
              {'tag_id': 1, 'tag_name': 'Psychological', 'affinity_score': 3},
              {'tag_id': 2, 'tag_name': 'Slice of Life', 'affinity_score': 2},
              {'tag_id': 3, 'tag_name': 'Science Fiction', 'affinity_score': 1},
            ],
          },
        );
      }
      final offset = uri.queryParameters['sort_by']?.length ?? 0;
      return (
        200,
        {'data': Fixtures.seriesList(20, offset: offset), 'total': 20},
      );
    }
    if (path.endsWith('/recommendations/status')) {
      return (
        200,
        {
          'data': {
            'cold_start': false,
            'profile_stale': false,
            'library_count': 60,
          },
        },
      );
    }
    if (path.endsWith('/recommendations')) {
      return (200, {'results': Fixtures.seriesList(20, offset: 5)});
    }
    if (path.endsWith('/works/upcoming')) {
      return (200, {'data': Fixtures.workList(40), 'total': 40});
    }
    if (path.endsWith('/news')) {
      final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      return (
        200,
        {'data': page == 1 ? Fixtures.newsList(10) : [], 'total': 10},
      );
    }
    final single = RegExp(r'/series/(\d+)$').firstMatch(path);
    if (single != null) {
      final i = int.parse(single.group(1)!) - 1000;
      return (200, {'data': Fixtures.seriesJson(i < 0 ? 0 : i)});
    }
    return (200, {'data': [], 'total': 0, 'results': []});
  }
}

class _FakeHttpClient implements HttpClient {
  final FakeBackend _backend;

  _FakeHttpClient(this._backend);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeRequest(_backend, url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRequest implements HttpClientRequest {
  final FakeBackend _backend;
  final Uri _url;
  final _FakeHeaders _headers = _FakeHeaders();

  _FakeRequest(this._backend, this._url);

  @override
  HttpHeaders get headers => _headers;

  @override
  Uri get uri => _url;

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async {
    final (status, body) = _backend.respond(_url);
    return _FakeResponse(status, utf8.encode(jsonEncode(body)));
  }

  @override
  Future<HttpClientResponse> get done => close();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final int _status;
  final List<int> _bytes;
  final _FakeHeaders _headers = _FakeHeaders()
    ..set('content-type', 'application/json; charset=utf-8');

  _FakeResponse(this._status, this._bytes);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  int get statusCode => _status;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => _status == 200 ? 'OK' : 'Error';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name.toLowerCase()] ??= []).add(value.toString());
  }

  @override
  String? value(String name) => _values[name.toLowerCase()]?.join(',');

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

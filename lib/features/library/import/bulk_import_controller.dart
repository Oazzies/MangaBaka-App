import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mangabaka_app/core/constants/app_constants.dart';
import 'package:mangabaka_app/core/logging/logging_service.dart';
import 'package:mangabaka_app/core/network/api_client.dart';
import 'package:mangabaka_app/core/network/api_envelope.dart';
import 'package:mangabaka_app/features/library/import/import_parser.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

/// Uses the strict /v2/series/match: an unmatched line beats a wrong series silently added.
class SeriesMatchService {
  final ApiClient _api;

  SeriesMatchService({http.Client? client, ApiClient? api})
    : _api = api ?? ApiClient(healthContext: 'series-match', client: client);

  /// Not filtered by content preference: dropping a title the user named looks like a bug.
  Future<List<Series>> match(String title, {int limit = 5}) {
    return _api.getJson(
      ApiClient.uri('${AppConstants.baseApiUrlV2}/series/match', {
        'q': title,
        'limit': limit,
      }),
      operation: 'match series',
      parse: (json) => parseDataList(
        json,
        Series.fromSimilarJson,
      ).where((s) => s.state.isEmpty || s.state == 'active').toList(),
    );
  }

  void dispose() => _api.close();
}

enum ImportRowStatus {
  pending,

  matched,

  notFound,

  /// Left alone: adding it again would overwrite its library state.
  inLibrary,

  failed,
}

class ImportRow {
  final String query;

  final String? sourceState;
  ImportRowStatus status = ImportRowStatus.pending;
  List<Series> candidates = const [];
  int chosen = 0;
  bool selected = false;

  ImportRow(this.query, {this.sourceState});

  Series? get match => candidates.isEmpty ? null : candidates[chosen];

  bool get canSelect => status == ImportRowStatus.matched;
}

class BulkImportController extends ChangeNotifier {
  static final _logger = LoggingService.logger;

  static const int maxTitles = ImportParser.maxTitles;

  /// Kept low to stay under the API's rate limit.
  static const int _concurrency = 4;

  final Future<List<Series>> Function(String title) _match;
  final Future<bool> Function(String seriesId) _isInLibrary;
  final Future<int> Function(List<String> seriesIds, String state) _addBatch;

  BulkImportController({
    required Future<List<Series>> Function(String title) match,
    required Future<bool> Function(String seriesId) isInLibrary,
    required Future<int> Function(List<String> seriesIds, String state)
    addBatch,
    String state = 'plan_to_read',
  }) : _match = match,
       _isInLibrary = isInLibrary,
       _addBatch = addBatch,
       _state = state;

  List<ImportRow> _rows = [];
  String _state;
  bool _matching = false;
  bool _adding = false;
  int _matchedCount = 0;
  bool _disposed = false;

  List<ImportRow> get rows => _rows;
  String get state => _state;
  bool get isMatching => _matching;
  bool get isAdding => _adding;
  bool get hasRows => _rows.isNotEmpty;

  double get progress => _rows.isEmpty ? 0 : _matchedCount / _rows.length;

  int get selectedCount => _rows.where((r) => r.selected).length;
  int get notFoundCount =>
      _rows.where((r) => r.status == ImportRowStatus.notFound).length;

  void setTargetState(String state) {
    _state = state;
    _notify();
  }

  static List<String> parseTitles(String text) => [
    for (final e in ImportParser.parse(text, format: ImportFormat.plain))
      e.title,
  ];

  Future<void> start(
    String text, {
    ImportFormat format = ImportFormat.auto,
    bool useStates = true,
    String? fileName,
  }) async {
    final entries = ImportParser.parse(
      text,
      format: format,
      useStates: useStates,
      fileName: fileName,
    );
    _rows = [for (final e in entries) ImportRow(e.title, sourceState: e.state)];
    _matchedCount = 0;
    _matching = entries.isNotEmpty;
    _notify();
    if (entries.isEmpty) return;

    final rows = _rows;
    // After a later start() or reset(), stale workers would overrun progress and clear _matching.
    bool superseded() => _disposed || !identical(_rows, rows);
    var next = 0;
    Future<void> worker() async {
      while (!superseded()) {
        final i = next++;
        if (i >= rows.length) return;
        await _resolve(rows[i]);
        if (superseded()) return;
        _matchedCount++;
        _notify();
      }
    }

    await Future.wait([
      for (var i = 0; i < min(_concurrency, rows.length); i++) worker(),
    ]);
    if (superseded()) return;
    _matching = false;
    _notify();
  }

  void reset() {
    _rows = [];
    _matching = false;
    _matchedCount = 0;
    _notify();
  }

  Future<void> _resolve(ImportRow row) async {
    try {
      final found = await _match(row.query);
      if (found.isEmpty) {
        row.status = ImportRowStatus.notFound;
        return;
      }
      row.candidates = found;
      if (await _isInLibrary(found.first.id)) {
        row.status = ImportRowStatus.inLibrary;
      } else {
        row.status = ImportRowStatus.matched;
        row.selected = true;
      }
    } catch (e) {
      _logger.warning('Import match failed for "${row.query}": $e');
      row.status = ImportRowStatus.failed;
    }
  }

  void toggle(ImportRow row) {
    if (!row.canSelect) return;
    row.selected = !row.selected;
    _notify();
  }

  void selectAll(bool value) {
    for (final row in _rows) {
      if (row.canSelect) row.selected = value;
    }
    _notify();
  }

  Future<void> choose(ImportRow row, int index) async {
    if (index < 0 || index >= row.candidates.length) return;
    row.chosen = index;
    final bool inLibrary;
    try {
      inLibrary = await _isInLibrary(row.candidates[index].id);
    } catch (e) {
      // Tap handler, so never throw; fail closed rather than risk overwriting an entry's state.
      _logger.warning('Library check failed for "${row.query}": $e');
      if (row.chosen != index) return;
      row.status = ImportRowStatus.failed;
      row.selected = false;
      _notify();
      return;
    }
    if (row.chosen != index) return;
    row.status = inLibrary
        ? ImportRowStatus.inLibrary
        : ImportRowStatus.matched;
    row.selected = !inLibrary;
    _notify();
  }

  Future<int> addSelected() async {
    // A double tap would resend every batch, patching the entries just created.
    if (_adding) return 0;
    final byState = <String, List<String>>{};
    // Duplicate ids make the batch patch the entry or fail its atomic chunk; first row wins.
    final seen = <String>{};
    for (final row in _rows) {
      final match = row.match;
      if (!row.selected || match == null) continue;
      if (!seen.add(match.id)) continue;
      byState.putIfAbsent(row.sourceState ?? _state, () => []).add(match.id);
    }
    if (byState.isEmpty) return 0;

    _adding = true;
    _notify();
    try {
      var created = 0;
      for (final entry in byState.entries) {
        created += await _addBatch(entry.value, entry.key);
      }
      return created;
    } finally {
      _adding = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

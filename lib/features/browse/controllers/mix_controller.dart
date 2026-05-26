import 'package:flutter/material.dart';
import 'package:mangabaka_app/features/browse/models/mix_result.dart';
import 'package:mangabaka_app/features/browse/services/mix_service.dart';
import 'package:mangabaka_app/features/series/models/autocomplete_series_result.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/utils/di/service_locator.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';
import 'package:mangabaka_app/utils/settings/settings_manager.dart';


class MixController extends ChangeNotifier {
  static final _logger = LoggingService.logger;
  final MixService _mixService = getIt<MixService>();

  // ─── Seeds ───────────────────────────────────────────────────────────────
  final List<Series> _seeds = [];
  List<Series> get seeds => List.unmodifiable(_seeds);

  // ─── Results ─────────────────────────────────────────────────────────────
  List<Series> _results = [];
  List<Series> get results => _results;

  List<MixDnaTag> _dna = [];
  List<MixDnaTag> get dna => _dna;

  // ─── Seed Suggestions ────────────────────────────────────────────────────
  List<AutocompleteSeriesResult> _seedSuggestions = [];
  List<AutocompleteSeriesResult> get seedSuggestions => _seedSuggestions;

  // ─── Options ─────────────────────────────────────────────────────────────
  bool _strictMode = false;
  bool get strictMode => _strictMode;
  void setStrictMode(bool v) {
    _strictMode = v;
    notifyListeners();
    if (hasSeeds) _fetchMix();
  }

  bool _blendUser = false;
  bool get blendUser => _blendUser;
  void setBlendUser(bool v) {
    _blendUser = v;
    notifyListeners();
    if (hasSeeds) _fetchMix();
  }

  bool _excludeLibrary = false;
  bool get excludeLibrary => _excludeLibrary;
  void setExcludeLibrary(bool v) {
    _excludeLibrary = v;
    notifyListeners();
    if (hasSeeds) _fetchMix();
  }

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSuggestionsLoading = false;
  bool get isSuggestionsLoading => _isSuggestionsLoading;

  String? _error;
  String? get error => _error;

  bool get hasSeeds => _seeds.isNotEmpty;


  // ─── Seed Management ─────────────────────────────────────────────────────

  bool isSeed(int seriesId) => _seeds.any((s) => s.id == seriesId.toString());

  void addSeed(Series series) {
    if (isSeed(int.tryParse(series.id) ?? -1)) return;
    _seeds.add(series);
    _logger.info('MixController: added seed "${series.title}" (id=${series.id})');
    notifyListeners();
    _fetchMix();
    if (_seeds.length >= 2) {
      _fetchSeedSuggestions();
    }
  }

  void removeSeed(Series series) {
    _seeds.removeWhere((s) => s.id == series.id);
    _logger.info('MixController: removed seed "${series.title}"');
    notifyListeners();
    if (_seeds.isEmpty) {
      _results = [];
      _dna = [];
      _error = null;
      _seedSuggestions = [];
      notifyListeners();
    } else {
      _fetchMix();
      if (_seeds.length >= 2) {
        _fetchSeedSuggestions();
      } else {
        _seedSuggestions = [];
        notifyListeners();
      }
    }
  }

  void clearSeeds() {
    _seeds.clear();
    _results = [];
    _dna = [];
    _error = null;
    _seedSuggestions = [];
    notifyListeners();
  }

  // ─── Fetch Mix ───────────────────────────────────────────────────────────

  Future<void> _fetchMix() async {
    if (_seeds.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ids = _seeds.map((s) => int.tryParse(s.id) ?? 0).where((id) => id > 0).toList();
      final contentPrefs = SettingsManager().contentPreferences;
      final auth = getIt<ProfileAuthService>();
      final userId = auth.isLoggedIn ? (auth.cachedProfile?.id ?? '') : '';

      final result = await _mixService.fetchMix(
        seriesIds: ids,
        limit: 24,
        contentRating: contentPrefs.isNotEmpty ? contentPrefs : null,
        strict: _strictMode,
        blendUserId: (_blendUser && userId.isNotEmpty) ? userId : null,
        excludeUserLibrary: (_excludeLibrary && userId.isNotEmpty) ? userId : null,
      );

      _results = result.series;
      _dna = result.dna;
      _logger.info('MixController: got ${_results.length} recommendations');
    } catch (e) {
      _logger.severe('MixController._fetchMix error: $e');
      _error = e.toString();
      _results = [];
      _dna = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _fetchMix();

  // ─── Fetch Seed Suggestions ──────────────────────────────────────────────

  Future<void> _fetchSeedSuggestions() async {
    if (_seeds.length < 2) return;

    _isSuggestionsLoading = true;
    notifyListeners();

    try {
      final ids = _seeds.map((s) => int.tryParse(s.id) ?? 0).where((id) => id > 0).toList();
      final suggestions = await _mixService.fetchSeedSuggestions(ids);

      // Filter out series already added as seeds
      _seedSuggestions = suggestions
          .where((sug) => !isSeed(sug.id))
          .toList();
      _logger.info('MixController: got ${_seedSuggestions.length} seed suggestions');
    } catch (e) {
      _logger.warning('MixController._fetchSeedSuggestions error: $e');
      _seedSuggestions = [];
    } finally {
      _isSuggestionsLoading = false;
      notifyListeners();
    }
  }
}

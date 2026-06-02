import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/utils/services/logging_service.dart';

class MetadataService {
  final _logger = LoggingService.logger;
  Map<String, String> _genreMap = {};
  Map<String, Map<String, dynamic>> _tagMap = {};
  
  List<Map<String, dynamic>> _genresList = [];
  List<Map<String, dynamic>> _tagsList = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _logger.info('Initializing MetadataService...');
    
    // Load from cache first
    await _loadFromCache();
    
    try {
      // Fetch fresh data in background
      _isInitialized = true;
      _logger.info('MetadataService initialized (cached)');
      
      // Still fetch fresh data to ensure we have the latest
      Future.wait([
        fetchGenres(),
        fetchTags(),
      ]).then((_) => _logger.info('MetadataService fresh data fetch complete'));
    } catch (e, st) {
      _logger.severe('Failed to initialize MetadataService: $e\n$st');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final genresJson = prefs.getString('cached_genres');
      final tagsJson = prefs.getString('cached_tags');

      if (genresJson != null) {
        final json = jsonDecode(genresJson);
        _genresList = List<Map<String, dynamic>>.from(json);
        _genreMap = {
          for (var item in _genresList)
            item['value'].toString(): item['label'].toString()
        };
        _logger.fine('Loaded ${_genresList.length} genres from cache');
      }

      if (tagsJson != null) {
        final json = jsonDecode(tagsJson);
        _tagsList = List<Map<String, dynamic>>.from(json);
        _tagMap = {
          for (var item in _tagsList)
            item['name'].toString(): item
        };
        _logger.fine('Loaded ${_tagsList.length} tags from cache');
      }
    } catch (e) {
      _logger.warning('Failed to load metadata from cache: $e');
    }
  }

  Future<void> fetchGenres() async {
    final url = Uri.parse('${AppConstants.baseApiUrl}/genres');
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final newList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        
        // Only update and save if data changed
        if (newList.length != _genresList.length) {
          _genresList = newList;
          _genreMap = {
            for (var item in _genresList)
              item['value'].toString(): item['label'].toString()
          };
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_genres', jsonEncode(_genresList));
          _logger.info('Successfully updated and cached ${_genresList.length} genres');
        }
      }
    } catch (e) {
      _logger.warning('Exception occurred while fetching genres: $e');
    }
  }

  Future<void> fetchTags() async {
    final url = Uri.parse('${AppConstants.baseApiUrl}/tags');
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final newList = List<Map<String, dynamic>>.from(json['data'] ?? []);

        if (newList.length != _tagsList.length) {
          _tagsList = newList;
          _tagMap = {
            for (var item in _tagsList)
              item['name'].toString(): item
          };
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_tags', jsonEncode(_tagsList));
          _logger.info('Successfully updated and cached ${_tagsList.length} tags');
        }
      }
    } catch (e) {
      _logger.warning('Exception occurred while fetching tags: $e');
    }
  }

  String getGenreLabel(String value) {
    if (_genreMap.containsKey(value)) {
      return _genreMap[value]!;
    }
    // Fallback to title case for each word
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }

  String? getTagPath(String tagName) {
    return _tagMap[tagName]?['name_path']?.toString();
  }

  String getTagName(int id) {
    try {
      final tag = _tagsList.firstWhere(
        (t) => int.parse(t['id'].toString()) == id,
      );
      return tag['name'].toString();
    } catch (e) {
      return 'Tag $id';
    }
  }

  List<Map<String, dynamic>> get genres => _genresList;
  List<Map<String, dynamic>> get tags => _tagsList;
  
  bool get isInitialized => _isInitialized;
}

import 'dart:convert';
import 'package:http/http.dart' as http;
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
    try {
      await Future.wait([
        fetchGenres(),
        fetchTags(),
      ]);
      _isInitialized = true;
      _logger.info('MetadataService initialized successfully');
    } catch (e, st) {
      _logger.severe('Failed to initialize MetadataService: $e\n$st');
    }
  }

  Future<void> fetchGenres() async {
    final url = Uri.parse('${AppConstants.baseApiUrl}/genres');
    _logger.info('Fetching genres from: $url');
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('Genres fetch status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _genresList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        _genreMap = {
          for (var item in _genresList)
            item['value'].toString(): item['label'].toString()
        };
        _logger.info('Successfully fetched ${_genresList.length} genres');
      } else {
        _logger.warning('Failed to fetch genres. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, st) {
      _logger.warning('Exception occurred while fetching genres: $e\n$st');
    }
  }

  Future<void> fetchTags() async {
    final url = Uri.parse('${AppConstants.baseApiUrl}/tags');
    _logger.info('Fetching tags from: $url');
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': AppConstants.userAgent},
      ).timeout(Duration(seconds: AppConstants.networkTimeoutSeconds));

      _logger.fine('Tags fetch status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        _tagsList = List<Map<String, dynamic>>.from(json['data'] ?? []);
        _tagMap = {
          for (var item in _tagsList)
            item['name'].toString(): item
        };
        _logger.info('Successfully fetched ${_tagsList.length} tags');
      } else {
        _logger.warning('Failed to fetch tags. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, st) {
      _logger.warning('Exception occurred while fetching tags: $e\n$st');
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

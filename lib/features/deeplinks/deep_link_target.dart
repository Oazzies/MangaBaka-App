import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/navigation/models/nav_destinations.dart';

sealed class DeepLinkTarget {
  const DeepLinkTarget();

  static const _seriesTypeSegments = {
    'manga',
    'manhwa',
    'manhua',
    'novel',
    'oel',
    'other',
  };

  static const _sortedSearches = {
    'popular': 'popularity_desc',
    'highest-rated': 'score_desc',
  };

  /// In the custom scheme the host is the first segment: mangabaka://manga/123.
  static DeepLinkTarget? parse(Uri uri) {
    final segments = [
      if (uri.scheme == 'mangabaka' && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];

    if (segments.isEmpty) return const TabTarget(NavTabs.home);

    final first = segments[0].toLowerCase();
    final second = segments.length > 1 ? segments[1] : null;

    // /manga/<id>[/slug] — also the older /series/<id>.
    if (_seriesTypeSegments.contains(first) || first == 'series') {
      if (second != null && _isId(second)) return SeriesTarget(second);
      if (first == 'series' || first == 'other') {
        return const TabTarget(NavTabs.browse);
      }
      return SearchTarget(filters: SearchFilters(type: [first]));
    }

    switch (first) {
      case 'publisher':
        if (second != null && second.isNotEmpty) return PublisherTarget(second);
        return const PublisherListTarget();
      case 'search':
        return _searchFrom(uri);
      case 'popular':
      case 'highest-rated':
        return SearchTarget(
          filters: SearchFilters(sortBy: _sortedSearches[first]),
        );
      case 'discover':
        return const DiscoverTarget();
      case 'mix':
        return const MixTarget();
      case 'stacks':
        return _parseStacks(second);
      case 'news':
        return const TabTarget(NavTabs.news);
      case 'library':
        return const TabTarget(NavTabs.library);
      case 'profile':
        return const TabTarget(NavTabs.profile);
      case 'my':
        return _parseMy(second);
    }
    return null;
  }

  static DeepLinkTarget? _parseMy(String? section) {
    switch (section) {
      case 'library':
        return const TabTarget(NavTabs.library);
      case 'news':
        return const TabTarget(NavTabs.news);
      case 'stats':
        return const StatsTarget();
      case 'discover':
        return const DiscoverTarget();
      case 'stacks':
        return const MyStacksTarget();
      case 'lists':
        return const MyListsTarget();
    }
    return null;
  }

  static DeepLinkTarget _parseStacks(String? section) {
    if (section == null || section.isEmpty) return const StackHubTarget();
    if (section.toLowerCase() == 'new') return const StackListTarget();
    final id = int.tryParse(RegExp(r'^\d+').stringMatch(section) ?? '');
    return id == null ? const StackHubTarget() : StackTarget(id);
  }

  static SearchTarget _searchFrom(Uri uri) {
    final q = uri.queryParametersAll;
    List<String> all(String key) =>
        (q[key] ?? const []).where((v) => v.isNotEmpty).toList();
    final sort = uri.queryParameters['sort_by'];
    return SearchTarget(
      query: uri.queryParameters['q'] ?? uri.queryParameters['query'] ?? '',
      filters: SearchFilters(
        type: all('type'),
        status: all('status'),
        genre: all('genre'),
        tag: all('tag'),
        staff: all('staff'),
        publisher: all('publisher'),
        sortBy: sort == null || sort.isEmpty ? null : sort,
      ),
    );
  }

  static bool _isId(String s) => RegExp(r'^\d+$').hasMatch(s);
}

class SeriesTarget extends DeepLinkTarget {
  final String id;
  const SeriesTarget(this.id);
}

class PublisherTarget extends DeepLinkTarget {
  final String id;
  const PublisherTarget(this.id);
}

class PublisherListTarget extends DeepLinkTarget {
  const PublisherListTarget();
}

class TabTarget extends DeepLinkTarget {
  final int index;
  const TabTarget(this.index);
}

class SearchTarget extends DeepLinkTarget {
  final String query;
  final SearchFilters filters;
  const SearchTarget({this.query = '', required this.filters});
}

class DiscoverTarget extends DeepLinkTarget {
  const DiscoverTarget();
}

class MixTarget extends DeepLinkTarget {
  const MixTarget();
}

class StatsTarget extends DeepLinkTarget {
  const StatsTarget();
}

class StackHubTarget extends DeepLinkTarget {
  const StackHubTarget();
}

class StackListTarget extends DeepLinkTarget {
  const StackListTarget();
}

class StackTarget extends DeepLinkTarget {
  final int id;
  const StackTarget(this.id);
}

class MyStacksTarget extends DeepLinkTarget {
  const MyStacksTarget();
}

class MyListsTarget extends DeepLinkTarget {
  const MyListsTarget();
}

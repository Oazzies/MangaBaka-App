import 'package:flutter/material.dart';
import 'package:mangabaka_app/utils/constants/app_constants.dart';
import 'package:mangabaka_app/features/series/models/series.dart';
import 'package:mangabaka_app/utils/localization/localization_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalRatingsSection extends StatelessWidget {
  final Series series;

  const ExternalRatingsSection({
    super.key,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final sources = series.source;
    if (sources == null || sources.isEmpty) return const SizedBox.shrink();

    final ratingSources = sources.entries
        .where((e) => e.value['rating_normalized'] != null)
        .toList()
      ..sort((a, b) {
        final rA = (a.value['rating_normalized'] as num).toDouble();
        final rB = (b.value['rating_normalized'] as num).toDouble();
        return rB.compareTo(rA);
      });

    if (ratingSources.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildItems(context, ratingSources),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context, List<MapEntry<String, dynamic>> sources) {
    final items = <Widget>[];
    for (int i = 0; i < sources.length; i++) {
      final entry = sources[i];
      items.add(_buildRatingItem(entry.key, entry.value));
      if (i < sources.length - 1) {
        items.add(Text(
          '•',
          style: TextStyle(
            color: AppConstants.textMutedColor.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ));
      }
    }
    return items;
  }

  Widget _buildRatingItem(String key, dynamic data) {
    final rating = data['rating_normalized'];
    final url = _getUrl(key, data);
    
    return InkWell(
      onTap: url != null && url.isNotEmpty 
          ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
          : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getFavicon(key),
            const SizedBox(width: 8),
            Text(
              rating.toString(),
              style: TextStyle(
                color: AppConstants.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getUrl(String key, dynamic data) {
    if (data['url'] != null) return data['url'].toString();
    
    final id = data['id']?.toString();
    if (id != null && id.isNotEmpty) {
      switch (key) {
        case 'anilist': return 'https://anilist.co/manga/$id';
        case 'my_anime_list': return 'https://myanimelist.net/manga/$id';
        case 'kitsu': return 'https://kitsu.io/manga/$id';
        case 'anime_planet': return 'https://www.anime-planet.com/manga/$id';
        case 'shikimori': return 'https://shikimori.one/mangas/$id';
        case 'manga_updates': return 'https://www.mangaupdates.com/series.html?id=$id';
      }
    }

    // Fallback to series links
    final domain = _getDomain(key);
    if (domain.isNotEmpty) {
      for (var link in series.links) {
        String linkUrl = '';
        if (link is String) {
          linkUrl = link;
        } else if (link is Map && link['url'] != null) {
          linkUrl = link['url'].toString();
        }
        
        if (linkUrl.contains(domain)) {
          return linkUrl;
        }
      }
    }
    
    return null;
  }

  String _getDomain(String key) {
    switch (key) {
      case 'anilist': return 'anilist.co';
      case 'my_anime_list': return 'myanimelist.net';
      case 'kitsu': return 'kitsu.io';
      case 'anime_planet': return 'anime-planet.com';
      case 'shikimori': return 'shikimori.one';
      case 'manga_updates': return 'mangaupdates.com';
      case 'anime_news_network': return 'animenewsnetwork.com';
      default: return '';
    }
  }

  Widget _getFavicon(String key) {
    final domain = _getDomain(key);

    if (domain.isEmpty) return Icon(Icons.star_rounded, size: 16, color: AppConstants.accentColor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        'https://www.google.com/s2/favicons?sz=64&domain=$domain',
        width: 18,
        height: 18,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.star_rounded, size: 16, color: AppConstants.accentColor),
      ),
    );
  }
}

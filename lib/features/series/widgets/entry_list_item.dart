import 'package:flutter/material.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class EntryListItem extends StatelessWidget {
  final Series series;
  final int? ranking;

  const EntryListItem({super.key, required this.series, this.ranking});

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          color: AppConstants.secondaryBackground,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: series.coverUrl.isNotEmpty
                      ? Image.network(
                          series.coverUrl,
                          width: 80,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: double.infinity,
                              color: AppConstants.secondaryBackground,
                              child: Icon(
                                Icons.broken_image,
                                color: AppConstants.textMutedColor,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: double.infinity,
                          color: AppConstants.secondaryBackground,
                          child: Icon(
                            Icons.broken_image,
                            color: AppConstants.textMutedColor,
                            size: 40,
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textColor,
                                fontSize: 16,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${capitalize(series.type)} - ${capitalize(series.status)} - ${series.year}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppConstants.textMutedColor, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: series.genres.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final genre = series.genres[index];
                              final genreLabel = genre.isNotEmpty
                                  ? genre[0].toUpperCase() + genre.substring(1)
                                  : genre;
                              return Chip(
                                label: Text(
                                  genreLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppConstants.textColor,
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: AppConstants.textMutedColor,
                                  width: 0.8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ranking != null)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.warningColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '$ranking',
                style: TextStyle(
                  color: AppConstants.primaryBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

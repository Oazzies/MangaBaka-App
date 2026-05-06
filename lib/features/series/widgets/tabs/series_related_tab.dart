import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';
import 'package:bakahyou/features/series/widgets/series_section_header.dart';

class SeriesRelatedTab extends StatelessWidget {
  final List<Series>? related;
  final LocalizationService l10n;
  final double horizontalPadding;

  const SeriesRelatedTab({
    super.key, 
    this.related, 
    required this.l10n,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (related == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }
    if (related!.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No related series.')));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SeriesSectionHeader(title: 'Related Series'),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: related!.length,
            itemBuilder: (context, index) {
              return EntryListItem(
                series: related![index],
              );
            },
          ),
        ],
      ),
    );
  }
}

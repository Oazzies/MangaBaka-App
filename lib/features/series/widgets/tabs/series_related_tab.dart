import 'package:flutter/material.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';
import 'package:bakahyou/features/series/models/series.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';
import 'package:bakahyou/utils/localization/localization_service.dart';

class SeriesRelatedTab extends StatelessWidget {
  final List<Series>? related;
  final LocalizationService l10n;

  const SeriesRelatedTab({super.key, this.related, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (related == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    }
    if (related!.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No related series.')));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Related Series'),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.textColor, letterSpacing: 0.5)),
    );
  }
}

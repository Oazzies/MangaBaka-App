import 'package:mangabaka_app/features/series/models/series.dart';

/// Result from /v1/series/mix endpoint
class MixResult {
  final List<Series> series;
  final List<MixDnaTag> dna;
  final int seedCount;

  const MixResult({
    required this.series,
    required this.dna,
    required this.seedCount,
  });
}

/// A single weighted tag from the DNA array in the mix response
class MixDnaTag {
  final int tagId;
  final String name;
  final double weight;

  const MixDnaTag({
    required this.tagId,
    required this.name,
    required this.weight,
  });

  factory MixDnaTag.fromJson(Map<String, dynamic> json) {
    return MixDnaTag(
      tagId: (json['tag_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

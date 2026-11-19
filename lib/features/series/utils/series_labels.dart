import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/series/models/series.dart';

abstract final class SeriesLabels {
  static String type(String raw) => _label('type', raw);

  static String status(String raw) => _label('status', raw);

  /// Type · status · year, skipping whatever the API left empty.
  static String summary(Series series, {String separator = ' · '}) => [
    type(series.type),
    status(series.status),
    if (series.year != 'null') series.year,
  ].where((part) => part.isNotEmpty).join(separator);

  static String _label(String prefix, String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return '';
    return LocalizationService().translateOr(
      '${prefix}_${value.toLowerCase()}',
      _humanize(value),
    );
  }

  static String _humanize(String value) {
    final words = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}

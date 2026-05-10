import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._(); 

  static String extractYear(String date) {
    if (date.isEmpty) return '';
    return date.length >= 4 ? date.substring(0, 4) : date;
  }

  static String formatFullDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return date;
    }
  }
}

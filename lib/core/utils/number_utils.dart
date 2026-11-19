class NumberUtils {
  static String formatCount(int count) {
    if (count < 1000) return count.toString();

    if (count < 1000000) {
      final kCount = count / 1000.0;
      if (kCount.round() >= 10) {
        return '${kCount.round()}k';
      }
      if (count % 1000 == 0) return '${(count ~/ 1000)}k';

      return '${kCount.toStringAsFixed(1)}k';
    }

    final mCount = count / 1000000.0;
    if (mCount.round() >= 10) {
      return '${mCount.round()}M';
    }
    if (count % 1000000 == 0) return '${(count ~/ 1000000)}M';

    return '${mCount.toStringAsFixed(1)}M';
  }
}

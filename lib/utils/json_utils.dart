class JsonUtils {
  static T? getField<T>(Map? map, List<String> path) {
    dynamic value = map;
    for (final key in path) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value as T?;
  }

  static String getCover(Map<String, dynamic> map) {
    final cover = map['cover'];
    if (cover is Map && cover['x350'] is Map && cover['x350']['x1'] is String) {
      return cover['x350']['x1'];
    }
    return '';
  }
}
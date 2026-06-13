class UriUtils {
  /// Normalizes a map of dynamic query values into the shape accepted by
  /// [Uri.replace]'s `queryParameters`, where each value must be a `String`
  /// or an `Iterable<String>`.
  ///
  /// `List` values are preserved as repeated query parameters (each element
  /// stringified); any other value is converted with `toString()`.
  static Map<String, dynamic> encodeQueryParameters(
    Map<String, dynamic> params,
  ) {
    return params.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((e) => e.toString()).toList());
      }
      return MapEntry(key, value.toString());
    });
  }
}

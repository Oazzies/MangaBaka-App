class UriUtils {
  /// `Uri.replace` queryParameters only take `String` or `Iterable<String>`; lists become repeated params.
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

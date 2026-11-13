/// A response that passed the status check, ready to be decoded.
class ApiResult {
  final int statusCode;
  final String body;

  const ApiResult({required this.statusCode, required this.body});
}

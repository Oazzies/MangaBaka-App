abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    if (code != null) buffer.write(' (Code: $code)');
    if (originalError != null) buffer.write('\nOriginal: $originalError');
    return buffer.toString();
  }
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class ApiException extends AppException {
  final int statusCode;
  final String? responseBody;

  ApiException({
    required super.message,
    required this.statusCode,
    this.responseBody,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class ParseException extends AppException {
  ParseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class AuthCancelledException extends AppException {
  AuthCancelledException({
    super.message = 'Login cancelled',
    super.code = 'CANCELLED',
  });
}

class AppError extends AppException {
  AppError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

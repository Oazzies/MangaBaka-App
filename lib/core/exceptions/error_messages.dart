import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

/// Deliberately coarse: offline, sign in again, wait, server broken are all a user can act on.
abstract final class ErrorMessages {
  static String keyFor(Object error) => switch (error) {
    SessionExpiredException() => 'error_session_expired',
    NetworkException(code: 'TIMEOUT') => 'error_timeout',
    NetworkException() => 'error_network',
    ApiException(statusCode: 429) => 'error_rate_limited',
    ApiException(:final statusCode) when statusCode >= 500 => 'error_server',
    ApiException(statusCode: 404) => 'error_not_found',
    _ => 'error_generic',
  };

  static String describe(Object error, [LocalizationService? l10n]) =>
      (l10n ?? LocalizationService()).translate(keyFor(error));
}

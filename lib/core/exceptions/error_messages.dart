import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

/// Turns any caught error into wording a user can act on.
///
/// Raw `toString()` output ("ApiException: Failed to fetch ... Original:
/// SocketException: ...") used to reach snackbars and error states. It reads
/// as a crash, can echo URLs and server bodies, and is never translated. The
/// detail belongs in the log, which every caller writes before showing this.
///
/// The mapping is deliberately coarse: users can do something different about
/// "you're offline", "sign in again", "wait a moment" and "the server is
/// broken" — beyond that, finer distinctions are noise.
abstract final class ErrorMessages {
  /// The localization key describing [error].
  static String keyFor(Object error) => switch (error) {
    SessionExpiredException() => 'error_session_expired',
    NetworkException(code: 'TIMEOUT') => 'error_timeout',
    NetworkException() => 'error_network',
    ApiException(statusCode: 429) => 'error_rate_limited',
    ApiException(:final statusCode) when statusCode >= 500 => 'error_server',
    ApiException(statusCode: 404) => 'error_not_found',
    _ => 'error_generic',
  };

  /// [keyFor] translated through [l10n] (the app-wide instance by default).
  static String describe(Object error, [LocalizationService? l10n]) =>
      (l10n ?? LocalizationService()).translate(keyFor(error));
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/exceptions/error_messages.dart';

ApiException _status(int code) =>
    ApiException(message: 'x', statusCode: code, code: 'REQUEST_FAILED');

void main() {
  test('maps each failure kind to its key', () {
    expect(
      ErrorMessages.keyFor(SessionExpiredException()),
      'error_session_expired',
    );
    expect(
      ErrorMessages.keyFor(NetworkException(message: 'x', code: 'TIMEOUT')),
      'error_timeout',
    );
    expect(
      ErrorMessages.keyFor(
        NetworkException(message: 'x', code: 'NETWORK_ERROR'),
      ),
      'error_network',
    );
    expect(ErrorMessages.keyFor(_status(429)), 'error_rate_limited');
    expect(ErrorMessages.keyFor(_status(503)), 'error_server');
    expect(ErrorMessages.keyFor(_status(404)), 'error_not_found');
    expect(ErrorMessages.keyFor(_status(400)), 'error_generic');
  });

  test('anything unrecognised is generic, never its toString()', () {
    expect(ErrorMessages.keyFor(StateError('boom')), 'error_generic');
    expect(ErrorMessages.keyFor(Exception('secret detail')), 'error_generic');
    expect(
      ErrorMessages.describe(Exception('secret detail')),
      isNot(contains('secret detail')),
    );
  });
}

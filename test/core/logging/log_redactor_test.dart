import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/logging/log_redactor.dart';

void main() {
  String r(String s) => LogRedactor.redact(s);

  test('leaves ordinary lines untouched', () {
    const line = 'search series: GET https://api.mangabaka.org/v1/series?q=one';
    expect(r(line), line);
  });

  test('masks bearer tokens but keeps the scheme', () {
    expect(
      r('Authorization: Bearer abc.DEF-123_x'),
      isNot(contains('abc.DEF')),
    );
    expect(r('header Bearer abc123'), 'header Bearer [REDACTED]');
  });

  test('masks keyed secrets in JSON, maps and query strings', () {
    final out = r(
      '{"access_token": "aaa", "refresh_token":"bbb"} '
      'client_secret=ccc&x=1 {password: ddd}',
    );
    for (final secret in ['aaa', 'bbb', 'ccc', 'ddd']) {
      expect(out, isNot(contains(secret)));
    }
    expect(out, contains('x=1'));
  });

  test('masks the OAuth code only as a query parameter', () {
    expect(
      r('redirect mangabaka://cb?code=SECRET&state=s'),
      'redirect mangabaka://cb?code=[REDACTED]&state=s',
    );
    const appCode = 'ApiException: Failed (Code: TIMEOUT)';
    expect(r(appCode), appCode);
  });

  test('masks bare JWTs and emails', () {
    final out = r('jwt eyJhbGciOi.eyJzdWIiOi.sig_part user me@example.com');
    expect(out, isNot(contains('eyJ')));
    expect(out, isNot(contains('me@example.com')));
  });
}

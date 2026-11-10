/// Strips credentials and personal data from log lines before they are kept.
///
/// The log is exported and shared by users when they report a bug, so it must
/// record *what* failed without leaking *who* or *with what key*. Redaction
/// runs over the fully formatted line — message, error and stack trace — so a
/// secret embedded in an exception's `toString()` is caught as well.
abstract final class LogRedactor {
  /// Replacement for any removed value.
  static const String mask = '[REDACTED]';

  // `Authorization: Bearer abc.def` — the scheme is kept so the line still
  // shows an authenticated request was made.
  static final RegExp _bearer = RegExp(
    r'\b(Bearer)\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  // A JWT is three base64url segments, the first always starting `eyJ`
  // (base64 of `{"`). Catches tokens that appear without a key name.
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]*',
  );

  // Sensitive names in JSON (`"access_token": "x"`), Dart map literals
  // (`access_token: x`) and query/form strings (`access_token=x`). Bare
  // `code` is excluded here — the app's own error codes use that word.
  static final RegExp _keyedSecret = RegExp(
    r'''(["']?\b(?:access_token|refresh_token|id_token|token|client_secret|'''
    r'''code_verifier|password|authorization|api_key|apikey)\b["']?'''
    r'''\s*[:=]\s*["']?)[^"'&\s,}]+''',
    caseSensitive: false,
  );

  // The OAuth authorization `code` only travels as a query parameter on the
  // redirect URI, so it is matched there and nowhere else.
  static final RegExp _oauthCode = RegExp(r'([?&]code=)[^&\s#]+');

  // Deliberately loose: a false positive costs a masked word, a miss leaks
  // an address.
  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  /// Returns [input] with every recognised secret replaced by [mask].
  static String redact(String input) {
    // Cheap bail-out: the vast majority of lines contain none of the markers,
    // and this runs on every log record.
    if (!_mightContainSecret(input)) return input;
    return input
        .replaceAllMapped(_bearer, (m) => '${m[1]} $mask')
        .replaceAll(_jwt, mask)
        .replaceAllMapped(_keyedSecret, (m) => '${m[1]}$mask')
        .replaceAllMapped(_oauthCode, (m) => '${m[1]}$mask')
        .replaceAll(_email, mask);
  }

  static bool _mightContainSecret(String s) {
    final lower = s.toLowerCase();
    return s.contains('@') ||
        s.contains('eyJ') ||
        lower.contains('bearer') ||
        lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('authorization') ||
        lower.contains('api_key') ||
        lower.contains('apikey') ||
        lower.contains('code=') ||
        lower.contains('code_verifier');
  }
}

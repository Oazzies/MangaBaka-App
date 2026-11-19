/// Runs over the fully formatted line, so a secret inside an exception's toString() is caught too.
abstract final class LogRedactor {
  static const String mask = '[REDACTED]';

  // The scheme is kept so the line still shows the request was authenticated.
  static final RegExp _bearer = RegExp(
    r'\b(Bearer)\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  // Catches unkeyed JWTs: three base64url segments, the first starting `eyJ` (base64 of `{"`).
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]*',
  );

  // Bare `code` is excluded: the app's own error codes use that word.
  static final RegExp _keyedSecret = RegExp(
    r'''(["']?\b(?:access_token|refresh_token|id_token|token|client_secret|'''
    r'''code_verifier|password|authorization|api_key|apikey)\b["']?'''
    r'''\s*[:=]\s*["']?)[^"'&\s,}]+''',
    caseSensitive: false,
  );

  // The OAuth `code` only travels as a redirect URI query parameter, so it is matched only there.
  static final RegExp _oauthCode = RegExp(r'([?&]code=)[^&\s#]+');

  // Deliberately loose: a false positive masks a word, a miss leaks an address.
  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  );

  static String redact(String input) {
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

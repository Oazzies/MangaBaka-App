import 'dart:convert';

import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/features/stacks/models/stack_enums.dart';

/// A stack endpoint refused the request.
///
/// [code] carries the API's machine-readable reason (see [StackErrorCode])
/// when it gave one; [serverMessage] is its human-readable `message`, which
/// the API documents as safe to show.
class StackApiException extends ApiException {
  final String? serverMessage;

  StackApiException({
    required super.message,
    required super.statusCode,
    super.responseBody,
    super.code,
    this.serverMessage,
    super.originalError,
    super.stackTrace,
  });

  /// Reads the `code` and `message` out of an error body.
  factory StackApiException.fromResponse(
    int statusCode,
    String body, {
    required String operation,
  }) {
    String? code;
    String? message;
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        code = json['code']?.toString();
        message = json['message']?.toString();
      }
    } catch (_) {}
    return StackApiException(
      message: 'Failed to $operation',
      statusCode: statusCode,
      responseBody: body,
      code: (code == null || code.isEmpty) ? null : code,
      serverMessage: (message == null || message.isEmpty) ? null : message,
    );
  }

  factory StackApiException.fromApi(ApiException e) => e is StackApiException
      ? e
      : StackApiException.fromResponse(
          e.statusCode,
          e.responseBody ?? '',
          operation: e.message.replaceFirst('Failed to ', ''),
        );

  bool get isStaleToken => code == StackErrorCode.staleToken;
  bool get isNotFound => statusCode == 404;

  /// A 403 with no rule named: the session lacks the stack scopes.
  bool get isMissingScope => statusCode == 403 && code == null;
}

/// The message to show the user for [error] from a stack operation.
String stackErrorMessage(Object error, LocalizationService l10n) {
  if (error is StackApiException) {
    final code = error.code;
    if (code != null && StackErrorCode.known.contains(code)) {
      return l10n.translate('stacks_error_$code');
    }
    if (error.isMissingScope) return l10n.translate('stacks_reconnect_body');
    if (error.isNotFound) return l10n.translate('stacks_error_not_found');
    final server = error.serverMessage;
    if (server != null) return server;
  }
  if (error is SessionExpiredException) {
    return l10n.translate('stacks_error_session_expired');
  }
  if (error is NetworkException) return l10n.translate('stacks_error_network');
  return l10n.translate('stacks_error_generic');
}

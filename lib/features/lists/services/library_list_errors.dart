import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';
import 'package:mangabaka_app/core/exceptions/error_messages.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';

enum ListOp {
  load,
  create,
  rename,
  privacy,
  delete,
  batch,
  addSeries,
  removeSeries,
}

/// The API names no rule for list 400s, so the operation says which rule refused it.
String listErrorKey(Object error, ListOp op) {
  if (error is ApiException) {
    final status = error.statusCode;
    if (status == 400) {
      return switch (op) {
        ListOp.create || ListOp.rename => 'lists_error_name_rejected',
        ListOp.addSeries => 'lists_error_too_many_lists',
        ListOp.batch || ListOp.delete => 'lists_error_gone',
        _ => 'error_generic',
      };
    }
    if (status == 404) {
      return switch (op) {
        ListOp.addSeries || ListOp.removeSeries => 'lists_error_not_in_library',
        _ => 'lists_error_gone',
      };
    }
  }
  return ErrorMessages.keyFor(error);
}

String listErrorMessage(Object error, ListOp op, [LocalizationService? l10n]) =>
    (l10n ?? LocalizationService()).translate(listErrorKey(error, op));

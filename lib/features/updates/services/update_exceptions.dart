import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

abstract class UpdateException extends AppException {
  final String l10nKey;

  UpdateException({
    required this.l10nKey,
    required super.message,
    super.code,
  });
}

class UpdateIntegrityException extends UpdateException {
  UpdateIntegrityException()
    : super(
        l10nKey: 'update_error_checksum_mismatch',
        message: 'The downloaded update failed its integrity check.',
        code: 'CHECKSUM_MISMATCH',
      );

  UpdateIntegrityException.unverifiable()
    : super(
        l10nKey: 'update_error_checksum_missing',
        message:
            'This update has no published checksum, so it cannot be '
            'installed from inside the app.',
        code: 'CHECKSUM_MISSING',
      );
}

class InstallPermissionException extends UpdateException {
  InstallPermissionException()
    : super(
        l10nKey: 'update_error_install_permission',
        message: 'Install permission was denied.',
      );
}

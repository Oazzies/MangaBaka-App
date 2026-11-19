import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

class UpdateIntegrityException extends AppException {
  UpdateIntegrityException()
    : super(
        message: 'The downloaded update failed its integrity check.',
        code: 'CHECKSUM_MISMATCH',
      );

  UpdateIntegrityException.unverifiable()
    : super(
        message:
            'This update has no published checksum, so it cannot be '
            'installed from inside the app.',
        code: 'CHECKSUM_MISSING',
      );
}

class InstallPermissionException extends AppException {
  InstallPermissionException()
    : super(message: 'Install permission was denied.');
}

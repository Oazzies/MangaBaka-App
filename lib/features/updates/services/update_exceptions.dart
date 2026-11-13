import 'package:mangabaka_app/core/exceptions/app_exceptions.dart';

/// Thrown when a downloaded update does not match the checksum GitHub
/// published for it (the file has already been deleted), or when no checksum
/// was published at all and the update was not downloaded.
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

/// Thrown when the user denies the "install unknown apps" permission required
/// to apply an Android update.
class InstallPermissionException extends AppException {
  InstallPermissionException()
    : super(message: 'Install permission was denied.');
}

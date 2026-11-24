import 'package:mangabaka_app/core/constants/app_constants.dart';

class LibraryConstants {
  LibraryConstants._();

  static final String baseUrl = '${AppConstants.baseApiUrl}/my/library';
  static const int pageLimit = AppConstants.libraryPageLimit;
  static String get userAgent => AppConstants.userAgent;
}

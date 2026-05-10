import 'package:mangabaka_app/utils/constants/app_constants.dart';

class LibraryConstants {
  LibraryConstants._(); 

  static final String baseUrl = '${AppConstants.baseApiUrl}/my/library';
  static const int pageLimit = AppConstants.libraryPageLimit;
  static const String userAgent = AppConstants.userAgent;
}
